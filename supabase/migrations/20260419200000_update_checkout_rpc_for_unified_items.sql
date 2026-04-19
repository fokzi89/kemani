-- ============================================================
-- Migration: Update Checkout RPC for Unified sale_items Table
-- Description: Rewrites checkout_storefront_order and cancel_storefront_order
--              to use the unified sale_items table instead of the dropped order_items.
-- ============================================================

-- 1. Add batch_allocations to sale_items (used by online orders for stock reservation rollback on cancel)
ALTER TABLE public.sale_items
    ADD COLUMN IF NOT EXISTS batch_allocations JSONB DEFAULT '[]'::jsonb;

COMMENT ON COLUMN public.sale_items.batch_allocations IS
    'For online orders: stores FIFO batch reservation details [{batch_id, quantity}] to allow accurate stock release on cancellation.';

-- 2. Drop old RPC signatures to avoid conflicts
DROP FUNCTION IF EXISTS checkout_storefront_order(UUID, UUID, UUID, order_type, fulfillment_type, DECIMAL, DECIMAL, DECIMAL, DECIMAL, UUID, TEXT, JSONB);
DROP FUNCTION IF EXISTS cancel_storefront_order(UUID);

-- 3. Recreate checkout_storefront_order — now inserts into sale_items
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
SECURITY DEFINER
AS $$
DECLARE
    v_order_id UUID;
    v_item RECORD;
    v_batch RECORD;
    v_req_qty INTEGER;
    v_available_qty INTEGER;
    v_allocated_qty INTEGER;
    v_allocations JSONB;
    v_primary_batch_id UUID;
BEGIN
    -- Validate totals
    IF p_total_amount != (p_subtotal + p_delivery_fee + p_tax_amount) THEN
        RAISE EXCEPTION 'Total amount does not match subtotal + fees + tax';
    END IF;

    -- Create the order header
    INSERT INTO orders (
        tenant_id, branch_id, order_number, customer_id,
        order_type, order_status, payment_status,
        subtotal, delivery_fee, tax_amount, total_amount,
        fulfillment_type, delivery_address_id, special_instructions
    ) VALUES (
        p_tenant_id,
        p_branch_id,
        'ORD-' || FLOOR(EXTRACT(EPOCH FROM NOW()))::TEXT || '-' || SUBSTRING(MD5(RANDOM()::TEXT) FROM 1 FOR 4),
        p_customer_id,
        p_order_type,
        'pending'::order_status,
        'unpaid'::payment_status,
        p_subtotal, p_delivery_fee, p_tax_amount, p_total_amount,
        p_fulfillment_type,
        p_delivery_address_id,
        p_special_instructions
    ) RETURNING id INTO v_order_id;

    -- Process each item: FIFO batch allocation + insert into sale_items
    FOR v_item IN SELECT * FROM jsonb_to_recordset(p_items) AS x(
        product_id UUID, product_name TEXT, quantity INTEGER, unit_price DECIMAL, subtotal DECIMAL
    )
    LOOP
        v_req_qty := v_item.quantity;
        v_allocations := '[]'::jsonb;
        v_primary_batch_id := NULL;

        -- FIFO batch allocation (locks rows to prevent race conditions)
        FOR v_batch IN 
            SELECT id, (stock_quantity - COALESCE(reserved_quantity, 0)) AS available_balance
            FROM branch_inventory
            WHERE branch_id = p_branch_id 
              AND product_id = v_item.product_id 
              AND is_active = true
              AND (stock_quantity - COALESCE(reserved_quantity, 0)) > 0
            ORDER BY expiry_date ASC NULLS LAST, created_at ASC
            FOR UPDATE
        LOOP
            IF v_req_qty <= 0 THEN EXIT; END IF;

            v_available_qty := v_batch.available_balance;
            v_allocated_qty := LEAST(v_available_qty, v_req_qty);

            -- Reserve stock in the batch
            UPDATE branch_inventory
            SET reserved_quantity = COALESCE(reserved_quantity, 0) + v_allocated_qty,
                updated_at = NOW()
            WHERE id = v_batch.id;

            -- Track the primary batch (first FIFO batch) for inventory_id
            IF v_primary_batch_id IS NULL THEN
                v_primary_batch_id := v_batch.id;
            END IF;

            v_allocations := v_allocations || jsonb_build_object(
                'batch_id', v_batch.id,
                'quantity', v_allocated_qty
            );

            v_req_qty := v_req_qty - v_allocated_qty;
        END LOOP;

        -- Raise if stock was insufficient
        IF v_req_qty > 0 THEN
            RAISE EXCEPTION 'Insufficient stock for product: % (short by %)', v_item.product_name, v_req_qty;
        END IF;

        -- Insert into unified sale_items (trigger will auto-populate cost/profit/category)
        INSERT INTO public.sale_items (
            tenant_id,
            order_id,
            branch_id,
            inventory_id,
            product_id,
            product_name,
            quantity,
            unit_price,
            subtotal,
            discount_amount,
            batch_allocations
        ) VALUES (
            p_tenant_id,
            v_order_id,
            p_branch_id,
            v_primary_batch_id,
            v_item.product_id,
            v_item.product_name,
            v_item.quantity,
            v_item.unit_price,
            v_item.subtotal,
            0,
            v_allocations
        );
    END LOOP;

    RETURN v_order_id;
END;
$$;


-- 4. Recreate cancel_storefront_order — now reads from sale_items
CREATE OR REPLACE FUNCTION cancel_storefront_order(
    p_order_id UUID
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_order_status order_status;
    v_item RECORD;
    v_allocation RECORD;
BEGIN
    -- Use subquery assignment to avoid SELECT INTO relation confusion
    v_order_status := (SELECT order_status FROM orders WHERE id = p_order_id LIMIT 1);

    IF v_order_status IS NULL THEN
        RAISE EXCEPTION 'Order not found';
    END IF;

    IF v_order_status = 'delivered'::order_status THEN
        RAISE EXCEPTION 'Cannot cancel an order that has already been delivered';
    END IF;

    IF v_order_status = 'cancelled'::order_status THEN
        RAISE EXCEPTION 'Order is already cancelled';
    END IF;

    -- Cancel the order
    UPDATE orders 
    SET order_status = 'cancelled'::order_status, updated_at = NOW()
    WHERE id = p_order_id;

    -- Release reserved stock using batch_allocations from sale_items
    FOR v_item IN SELECT batch_allocations FROM public.sale_items WHERE order_id = p_order_id
    LOOP
        FOR v_allocation IN 
            SELECT * FROM jsonb_to_recordset(v_item.batch_allocations) AS x(batch_id UUID, quantity INTEGER)
        LOOP
            UPDATE branch_inventory
            SET reserved_quantity = GREATEST(COALESCE(reserved_quantity, 0) - v_allocation.quantity, 0),
                updated_at = NOW()
            WHERE id = v_allocation.batch_id;
        END LOOP;
    END LOOP;

    RETURN TRUE;
END;
$$;
