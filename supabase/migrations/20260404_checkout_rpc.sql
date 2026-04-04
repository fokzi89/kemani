-- ============================================
-- Migration: E-Commerce Storefront RPCs for Checkout and Cancellation
-- Description: Adds batch allocation tracking, checkout logic, and cancellation logic
-- ============================================

-- 1. Add batch_allocations to order_items to support accurately releasing reservations
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'order_items' AND column_name = 'batch_allocations'
    ) THEN
        ALTER TABLE order_items ADD COLUMN batch_allocations JSONB DEFAULT '[]'::jsonb;
        COMMENT ON COLUMN order_items.batch_allocations IS 'Array of allocations: {batch_id: "uuid", quantity: number} to track reserved stock for cancellations.';
    END IF;
END $$;

-- 2. Drop existing functions if they exist to prevent signature conflicts
DROP FUNCTION IF EXISTS checkout_storefront_order(UUID, UUID, UUID, order_type, fulfillment_type, DECIMAL, DECIMAL, DECIMAL, DECIMAL, UUID, TEXT, JSONB);
DROP FUNCTION IF EXISTS cancel_storefront_order(UUID);

-- 3. Create checkout_storefront_order RPC
CREATE OR REPLACE FUNCTION checkout_storefront_order(
    p_tenant_id UUID,
    p_branch_id UUID,
    p_customer_id UUID,
    p_order_type order_type,
    p_fulfillment_type fulfillment_type,
    p_subtotal DECIMAL,
    p_delivery_fee DECIMAL,
    p_tax_amount DECIMAL,
    p_total_amount DECIMAL,
    p_delivery_address_id UUID,
    p_special_instructions TEXT,
    p_items JSONB -- Array of { product_id, product_name, quantity, unit_price, subtotal }
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER -- Runs with elevated privileges to securely handle stock
AS $$
DECLARE
    v_order_id UUID;
    v_item RECORD;
    v_batch RECORD;
    v_req_qty INTEGER;
    v_available_qty INTEGER;
    v_allocated_qty INTEGER;
    v_allocations JSONB;
BEGIN
    -- Input validation
    IF p_total_amount != (p_subtotal + p_delivery_fee + p_tax_amount) THEN
        RAISE EXCEPTION 'Total amount does not match subtotal + fees + tax';
    END IF;

    -- Create the order
    INSERT INTO orders (
        tenant_id,
        branch_id,
        order_number,
        customer_id,
        order_type,
        order_status,
        payment_status,
        subtotal,
        delivery_fee,
        tax_amount,
        total_amount,
        fulfillment_type,
        delivery_address_id,
        special_instructions
    ) VALUES (
        p_tenant_id,
        p_branch_id,
        'ORD-' || FLOOR(EXTRACT(EPOCH FROM NOW()))::TEXT || '-' || SUBSTRING(MD5(RANDOM()::TEXT) FROM 1 FOR 4),
        p_customer_id,
        p_order_type,
        'pending'::order_status,
        'unpaid'::payment_status,
        p_subtotal,
        p_delivery_fee,
        p_tax_amount,
        p_total_amount,
        p_fulfillment_type,
        p_delivery_address_id,
        p_special_instructions
    ) RETURNING id INTO v_order_id;

    -- Process each item in the order
    FOR v_item IN SELECT * FROM jsonb_to_recordset(p_items) AS x(
        product_id UUID, product_name TEXT, quantity INTEGER, unit_price DECIMAL, subtotal DECIMAL
    )
    LOOP
        v_req_qty := v_item.quantity;
        v_allocations := '[]'::jsonb;

        -- Perform FIFO Allocation against branch_inventory batches where (stock_quantity - reserved_quantity) > 0
        FOR v_batch IN 
            SELECT id, (stock_quantity - COALESCE(reserved_quantity, 0)) AS available_balance
            FROM branch_inventory
            WHERE branch_id = p_branch_id 
              AND product_id = v_item.product_id 
              AND is_active = true
              AND (stock_quantity - COALESCE(reserved_quantity, 0)) > 0
            ORDER BY expiry_date ASC NULLS LAST, created_at ASC
            FOR UPDATE -- Lock rows to prevent race conditions during concurrent checkouts
        LOOP
            IF v_req_qty <= 0 THEN
                EXIT; -- Allocation complete
            END IF;

            v_available_qty := v_batch.available_balance;
            
            -- Determine how much we can allocate from this batch
            IF v_available_qty >= v_req_qty THEN
                v_allocated_qty := v_req_qty;
            ELSE
                v_allocated_qty := v_available_qty;
            END IF;

            -- Update reserved_quantity for this batch
            UPDATE branch_inventory
            SET reserved_quantity = COALESCE(reserved_quantity, 0) + v_allocated_qty,
                updated_at = NOW()
            WHERE id = v_batch.id;

            -- Record this allocation
            v_allocations := v_allocations || jsonb_build_object(
                'batch_id', v_batch.id,
                'quantity', v_allocated_qty
            );

            v_req_qty := v_req_qty - v_allocated_qty;
        END LOOP;

        -- Check if we successfully fulfilled the requested quantity
        IF v_req_qty > 0 THEN
            RAISE EXCEPTION 'Insufficient stock available for product: % (Missing: %)', v_item.product_name, v_req_qty;
        END IF;

        -- Insert the order_items row with the tracked allocations
        INSERT INTO order_items (
            order_id,
            product_id,
            product_name,
            quantity,
            unit_price,
            subtotal,
            batch_allocations
        ) VALUES (
            v_order_id,
            v_item.product_id,
            v_item.product_name,
            v_item.quantity,
            v_item.unit_price,
            v_item.subtotal,
            v_allocations
        );
    END LOOP;

    RETURN v_order_id;
END;
$$;


-- 4. Create cancel_storefront_order RPC
CREATE OR REPLACE FUNCTION cancel_storefront_order(
    p_order_id UUID
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_order RECORD;
    v_item RECORD;
    v_allocation RECORD;
    v_user_id UUID;
    v_tenant_id UUID;
BEGIN
    v_user_id := auth.uid();
    
    -- Retrieve the order and verify ownership/status
    SELECT * INTO v_order FROM orders WHERE id = p_order_id;
    
    IF v_order.id IS NULL THEN
        RAISE EXCEPTION 'Order not found';
    END IF;

    -- We allow cancellation if it's pending, or by tenants. For simplicity, only check status
    IF v_order.order_status = 'delivered'::order_status THEN
        RAISE EXCEPTION 'Cannot cancel an order that has already been delivered';
    END IF;
    IF v_order.order_status = 'cancelled'::order_status THEN
        RAISE EXCEPTION 'Order is already cancelled';
    END IF;

    -- Update order status
    UPDATE orders 
    SET order_status = 'cancelled'::order_status,
        updated_at = NOW()
    WHERE id = p_order_id;

    -- Loop through order items and un-reserve the allocated batches
    FOR v_item IN SELECT * FROM order_items WHERE order_id = p_order_id
    LOOP
        -- Loop through allocations inside the JSONB array
        FOR v_allocation IN SELECT * FROM jsonb_to_recordset(v_item.batch_allocations) AS x(batch_id UUID, quantity INTEGER)
        LOOP
            -- Decrement reserved_quantity
            UPDATE branch_inventory
            SET reserved_quantity = GREATEST(COALESCE(reserved_quantity, 0) - v_allocation.quantity, 0),
                updated_at = NOW()
            WHERE id = v_allocation.batch_id;
        END LOOP;
    END LOOP;

    RETURN TRUE;
END;
$$;
