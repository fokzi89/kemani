-- ============================================================
-- Migration: Update checkout_storefront_order with Payment Reference
-- Description: Updates the RPC to accept a payment reference and set status to paid.
-- ============================================================

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
    p_items JSONB, -- Array of { product_id, product_name, quantity, unit_price, subtotal }
    p_service_charge DECIMAL DEFAULT 0,
    p_payment_reference TEXT DEFAULT NULL
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
    -- Validate totals (including service charge)
    IF p_total_amount != (p_subtotal + p_delivery_fee + p_tax_amount + p_service_charge) THEN
        RAISE EXCEPTION 'Total amount does not match subtotal + fees + tax + service charge';
    END IF;

    -- Create the order header
    INSERT INTO orders (
        tenant_id, branch_id, order_number, customer_id,
        order_type, order_status, payment_status, payment_method, payment_reference,
        subtotal, delivery_fee, tax_amount, service_charge, total_amount,
        fulfillment_type, delivery_address_id, special_instructions
    ) VALUES (
        p_tenant_id,
        p_branch_id,
        'ORD-' || FLOOR(EXTRACT(EPOCH FROM NOW()))::TEXT || '-' || SUBSTRING(MD5(RANDOM()::TEXT) FROM 1 FOR 4),
        p_customer_id,
        p_order_type,
        'pending'::order_status,
        CASE WHEN p_payment_reference IS NOT NULL THEN 'paid'::payment_status ELSE 'unpaid'::payment_status END,
        'card'::payment_method, -- Default to card if payment reference is provided
        p_payment_reference,
        p_subtotal, p_delivery_fee, p_tax_amount, p_service_charge, p_total_amount,
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

        -- FIFO batch allocation
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

            IF v_primary_batch_id IS NULL THEN
                v_primary_batch_id := v_batch.id;
            END IF;

            v_allocations := v_allocations || jsonb_build_object(
                'batch_id', v_batch.id,
                'quantity', v_allocated_qty
            );

            v_req_qty := v_req_qty - v_allocated_qty;
        END LOOP;

        IF v_req_qty > 0 THEN
            RAISE EXCEPTION 'Insufficient stock for product: % (short by %)', v_item.product_name, v_req_qty;
        END IF;

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
