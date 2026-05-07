-- ============================================================
-- Migration: Patch Inventory Functions for Preorders (Fixed Schema)
-- ============================================================
-- Description: Updates checkout and POS triggers to handle
-- preorder_quantity when stock is insufficient.
-- Corrected for schema where tenant-specific product details (price, allow_preorder)
-- reside in branch_inventory.
-- ============================================================

-- 1. Update checkout_storefront_order to support preorders
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
    p_payment_reference TEXT DEFAULT NULL,
    p_billing_address TEXT DEFAULT NULL,
    p_shipping_address TEXT DEFAULT NULL
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
    v_preorders_enabled BOOLEAN;
    v_allow_preorder BOOLEAN;
BEGIN
    -- Check if preorders are enabled for the tenant
    SELECT preorders_enabled INTO v_preorders_enabled FROM tenants WHERE id = p_tenant_id;

    -- Validate totals
    IF p_total_amount != (p_subtotal + p_delivery_fee + p_tax_amount + p_service_charge) THEN
        RAISE EXCEPTION 'Total amount does not match subtotal + fees + tax + service charge';
    END IF;

    -- Create the order header
    INSERT INTO orders (
        tenant_id, branch_id, order_number, customer_id,
        order_type, order_status, payment_status, payment_method, payment_reference,
        subtotal, delivery_fee, tax_amount, service_charge, total_amount,
        fulfillment_type, delivery_address_id, special_instructions,
        billing_address, shipping_address
    ) VALUES (
        p_tenant_id,
        p_branch_id,
        'ORD-' || FLOOR(EXTRACT(EPOCH FROM NOW()))::TEXT || '-' || SUBSTRING(MD5(RANDOM()::TEXT) FROM 1 FOR 4),
        p_customer_id,
        p_order_type,
        'pending'::order_status,
        CASE WHEN p_payment_reference IS NOT NULL THEN 'paid'::payment_status ELSE 'unpaid'::payment_status END,
        'card'::payment_method,
        p_payment_reference,
        p_subtotal, p_delivery_fee, p_tax_amount, p_service_charge, p_total_amount,
        p_fulfillment_type,
        p_delivery_address_id,
        p_special_instructions,
        p_billing_address,
        p_shipping_address
    ) RETURNING id INTO v_order_id;

    -- Process each item
    FOR v_item IN SELECT * FROM jsonb_to_recordset(p_items) AS x(
        product_id UUID, product_name TEXT, quantity INTEGER, unit_price DECIMAL, subtotal DECIMAL
    )
    LOOP
        v_req_qty := v_item.quantity;
        v_allocations := '[]'::jsonb;
        v_primary_batch_id := NULL;

        -- 1. Try to allocate from stock (FIFO)
        FOR v_batch IN 
            SELECT id, (stock_quantity - COALESCE(reserved_quantity, 0)) AS available_balance, allow_preorder
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

            UPDATE branch_inventory
            SET reserved_quantity = COALESCE(reserved_quantity, 0) + v_allocated_qty,
                updated_at = NOW()
            WHERE id = v_batch.id;

            IF v_primary_batch_id IS NULL THEN
                v_primary_batch_id := v_batch.id;
            END IF;

            v_allocations := v_allocations || jsonb_build_object(
                'batch_id', v_batch.id,
                'quantity', v_allocated_qty,
                'is_preorder', false
            );

            v_req_qty := v_req_qty - v_allocated_qty;
        END LOOP;

        -- 2. Handle remaining as preorder if enabled
        IF v_req_qty > 0 THEN
            -- Check allow_preorder from any branch_inventory record for this product/tenant
            SELECT allow_preorder INTO v_allow_preorder 
            FROM branch_inventory 
            WHERE branch_id = p_branch_id AND product_id = v_item.product_id 
            LIMIT 1;
            
            IF COALESCE(v_preorders_enabled, false) AND COALESCE(v_allow_preorder, false) THEN
                -- Find or create a branch_inventory record to hold the preorder count
                SELECT id INTO v_primary_batch_id 
                FROM branch_inventory 
                WHERE branch_id = p_branch_id AND product_id = v_item.product_id 
                LIMIT 1 FOR UPDATE;

                IF v_primary_batch_id IS NULL THEN
                    INSERT INTO branch_inventory (
                        tenant_id, branch_id, product_id, stock_quantity, preorder_quantity, cost_price
                    ) VALUES (
                        p_tenant_id, p_branch_id, v_item.product_id, 0, v_req_qty, 0
                    ) RETURNING id INTO v_primary_batch_id;
                ELSE
                    UPDATE branch_inventory 
                    SET preorder_quantity = COALESCE(preorder_quantity, 0) + v_req_qty,
                        updated_at = NOW()
                    WHERE id = v_primary_batch_id;
                END IF;

                v_allocations := v_allocations || jsonb_build_object(
                    'batch_id', v_primary_batch_id,
                    'quantity', v_req_qty,
                    'is_preorder', true
                );
                v_req_qty := 0;
            ELSE
                RAISE EXCEPTION 'Insufficient stock for product: % (short by %)', v_item.product_name, v_req_qty;
            END IF;
        END IF;

        INSERT INTO public.sale_items (
            tenant_id, order_id, branch_id, inventory_id,
            product_id, product_name, quantity, unit_price, subtotal,
            discount_amount, batch_allocations
        ) VALUES (
            p_tenant_id, v_order_id, p_branch_id, v_primary_batch_id,
            v_item.product_id, v_item.product_name, v_item.quantity, v_item.unit_price, v_item.subtotal,
            0, v_allocations
        );
    END LOOP;

    RETURN v_order_id;
END;
$$;

-- 2. Update trigger_sync_inventory_on_sale for POS preorders
CREATE OR REPLACE FUNCTION trigger_sync_inventory_on_sale()
RETURNS TRIGGER AS $$
DECLARE
    v_item RECORD;
    v_batch RECORD;
    v_req_qty INTEGER;
    v_available INTEGER;
    v_deducted INTEGER;
    v_preorders_enabled BOOLEAN;
    v_allow_preorder BOOLEAN;
BEGIN
    IF NEW.sale_status = 'completed' THEN
        SELECT preorders_enabled INTO v_preorders_enabled FROM tenants WHERE id = NEW.tenant_id;

        FOR v_item IN
            SELECT product_id, quantity
            FROM sale_items
            WHERE sale_id = NEW.id
        LOOP
            v_req_qty := v_item.quantity;

            -- 1. Deduct from available stock batches first
            FOR v_batch IN 
                SELECT id, stock_quantity 
                FROM branch_inventory 
                WHERE branch_id = NEW.branch_id AND product_id = v_item.product_id AND stock_quantity > 0
                ORDER BY created_at ASC 
                FOR UPDATE
            LOOP
                IF v_req_qty <= 0 THEN EXIT; END IF;
                v_deducted := LEAST(v_batch.stock_quantity, v_req_qty);
                
                UPDATE branch_inventory 
                SET stock_quantity = stock_quantity - v_deducted,
                    updated_at = NOW()
                WHERE id = v_batch.id;
                
                v_req_qty := v_req_qty - v_deducted;
            END LOOP;

            -- 2. Handle remainder as preorder if enabled
            IF v_req_qty > 0 THEN
                SELECT allow_preorder INTO v_allow_preorder 
                FROM branch_inventory 
                WHERE branch_id = NEW.branch_id AND product_id = v_item.product_id 
                LIMIT 1;
                
                IF COALESCE(v_preorders_enabled, false) AND COALESCE(v_allow_preorder, false) THEN
                    -- Update preorder_quantity on any branch record (or create one)
                    UPDATE branch_inventory 
                    SET preorder_quantity = COALESCE(preorder_quantity, 0) + v_req_qty,
                        updated_at = NOW()
                    WHERE id = (SELECT id FROM branch_inventory WHERE branch_id = NEW.branch_id AND product_id = v_item.product_id LIMIT 1 FOR UPDATE);
                    
                    IF NOT FOUND THEN
                        INSERT INTO branch_inventory (
                            tenant_id, branch_id, product_id, stock_quantity, preorder_quantity, cost_price
                        ) VALUES (
                            NEW.tenant_id, NEW.branch_id, v_item.product_id, 0, v_req_qty, 0
                        );
                    END IF;
                ELSE
                    RAISE WARNING 'Insufficient stock for product % in sale %. Stock is 0 and preorders disabled.',
                        v_item.product_id, NEW.id;
                END IF;
            END IF;
        END LOOP;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 3. Update complete_sale_transaction to support preorders
CREATE OR REPLACE FUNCTION complete_sale_transaction(
    p_tenant_id UUID,
    p_branch_id UUID,
    p_cashier_id UUID,
    p_customer_id UUID,
    p_cart_items JSONB,
    p_subtotal DECIMAL,
    p_tax_amount DECIMAL,
    p_discount_amount DECIMAL,
    p_total_amount DECIMAL,
    p_payment_method payment_method,
    p_payment_reference TEXT DEFAULT NULL
)
RETURNS TABLE (
    sale_id UUID,
    sale_number VARCHAR,
    success BOOLEAN,
    error_message TEXT
) AS $$
DECLARE
    v_sale_id UUID;
    v_sale_number VARCHAR;
    v_item JSONB;
    v_product_id UUID;
    v_quantity INTEGER;
    v_available_stock INTEGER;
    v_preorders_enabled BOOLEAN;
    v_allow_preorder BOOLEAN;
    v_req_qty INTEGER;
    v_deducted INTEGER;
    v_batch RECORD;
BEGIN
    -- Check if preorders are enabled for the tenant
    SELECT preorders_enabled INTO v_preorders_enabled FROM tenants WHERE id = p_tenant_id;

    -- Start transaction
    BEGIN
        -- Verify stock availability (unless preorder is allowed)
        FOR v_item IN SELECT * FROM jsonb_array_elements(p_cart_items)
        LOOP
            v_product_id := (v_item->>'product_id')::UUID;
            v_quantity := (v_item->>'quantity')::INTEGER;

            SELECT (stock_quantity - reserved_quantity), allow_preorder 
            INTO v_available_stock, v_allow_preorder
            FROM branch_inventory
            WHERE branch_id = p_branch_id AND product_id = v_product_id;

            IF (v_available_stock IS NULL OR v_available_stock < v_quantity) 
               AND NOT (COALESCE(v_preorders_enabled, false) AND COALESCE(v_allow_preorder, false)) THEN
                RETURN QUERY SELECT
                    NULL::UUID as sale_id,
                    NULL::VARCHAR as sale_number,
                    FALSE as success,
                    'Insufficient stock for product: ' || (v_item->>'product_name') as error_message;
                RETURN;
            END IF;
        END LOOP;

        -- Create sale record
        INSERT INTO sales (
            tenant_id, branch_id, cashier_id, customer_id,
            subtotal, tax_amount, discount_amount, total_amount,
            payment_method, payment_reference, status
        ) VALUES (
            p_tenant_id, p_branch_id, p_cashier_id, p_customer_id,
            p_subtotal, p_tax_amount, p_discount_amount, p_total_amount,
            p_payment_method, p_payment_reference, 'completed'
        )
        RETURNING id, sale_number INTO v_sale_id, v_sale_number;

        -- Insert sale items
        INSERT INTO sale_items (
            sale_id, tenant_id, product_id, product_name, quantity, unit_price, discount_amount, subtotal
        )
        SELECT
            v_sale_id, p_tenant_id, (item->>'product_id')::UUID, item->>'product_name',
            (item->>'quantity')::INTEGER, (item->>'unit_price')::DECIMAL,
            COALESCE((item->>'discount_amount')::DECIMAL, 0), (item->>'subtotal')::DECIMAL
        FROM jsonb_array_elements(p_cart_items) AS item;

        -- Deduct stock / Increment preorders
        FOR v_item IN SELECT * FROM jsonb_array_elements(p_cart_items)
        LOOP
            v_product_id := (v_item->>'product_id')::UUID;
            v_req_qty := (v_item->>'quantity')::INTEGER;

            -- Deduct from available stock batches first
            FOR v_batch IN 
                SELECT id, stock_quantity 
                FROM branch_inventory 
                WHERE branch_id = p_branch_id AND product_id = v_product_id AND stock_quantity > 0
                ORDER BY created_at ASC 
                FOR UPDATE
            LOOP
                IF v_req_qty <= 0 THEN EXIT; END IF;
                v_deducted := LEAST(v_batch.stock_quantity, v_req_qty);
                
                UPDATE branch_inventory 
                SET stock_quantity = stock_quantity - v_deducted,
                    updated_at = NOW()
                WHERE id = v_batch.id;

                -- Create inventory transaction
                INSERT INTO inventory_transactions (
                    tenant_id, branch_id, product_id, branch_inventory_id,
                    transaction_type, quantity_delta, previous_quantity, new_quantity,
                    reference_id, reference_type, staff_id
                ) VALUES (
                    p_tenant_id, p_branch_id, v_product_id, v_batch.id,
                    'sale'::transaction_type, -v_deducted, v_batch.stock_quantity, v_batch.stock_quantity - v_deducted,
                    v_sale_id, 'sale', p_cashier_id
                );
                
                v_req_qty := v_req_qty - v_deducted;
            END LOOP;

            -- Handle remainder as preorder
            IF v_req_qty > 0 THEN
                UPDATE branch_inventory 
                SET preorder_quantity = COALESCE(preorder_quantity, 0) + v_req_qty,
                    updated_at = NOW()
                WHERE id = (SELECT id FROM branch_inventory WHERE branch_id = p_branch_id AND product_id = v_product_id LIMIT 1 FOR UPDATE);
                
                IF NOT FOUND THEN
                    INSERT INTO branch_inventory (
                        tenant_id, branch_id, product_id, stock_quantity, preorder_quantity, cost_price
                    ) VALUES (
                        p_tenant_id, p_branch_id, v_product_id, 0, v_req_qty, 0
                    );
                END IF;

                -- Create inventory transaction for preorder part
                INSERT INTO inventory_transactions (
                    tenant_id, branch_id, product_id,
                    transaction_type, quantity_delta, previous_quantity, new_quantity,
                    reference_id, reference_type, notes, staff_id
                ) VALUES (
                    p_tenant_id, p_branch_id, v_product_id,
                    'sale'::transaction_type, -v_req_qty, 0, 0,
                    v_sale_id, 'sale', 'Preorder recorded', p_cashier_id
                );
            END IF;
        END LOOP;

        RETURN QUERY SELECT v_sale_id, v_sale_number, TRUE, NULL::TEXT;
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT NULL::UUID, NULL::VARCHAR, FALSE, SQLERRM;
    END;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Update search_products_for_pos to include out-of-stock items that allow preorder
CREATE OR REPLACE FUNCTION search_products_for_pos(
    p_tenant_id UUID,
    p_branch_id UUID,
    p_search_term TEXT,
    p_limit INTEGER DEFAULT 20
)
RETURNS TABLE (
    product_id UUID,
    product_name VARCHAR,
    sku VARCHAR,
    barcode VARCHAR,
    category VARCHAR,
    unit_price DECIMAL,
    cost_price DECIMAL,
    image_url TEXT,
    stock_quantity INTEGER,
    reserved_quantity INTEGER,
    available_quantity INTEGER,
    low_stock_threshold INTEGER,
    allow_preorder BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        bi.product_id,
        bi.product_name,
        bi.sku,
        bi.barcode,
        p.category,
        bi.selling_price as unit_price,
        bi.cost_price,
        bi.image_url,
        bi.stock_quantity,
        bi.reserved_quantity,
        (bi.stock_quantity - bi.reserved_quantity) as available_quantity,
        bi.low_stock_threshold,
        bi.allow_preorder
    FROM branch_inventory bi
    JOIN products p ON p.id = bi.product_id
    WHERE bi.tenant_id = p_tenant_id
        AND bi.branch_id = p_branch_id
        AND p.is_active = TRUE
        AND bi.is_active = TRUE
        AND p.deleted_at IS NULL
        AND (
            (bi.stock_quantity - bi.reserved_quantity) > 0
            OR (bi.allow_preorder = TRUE)
        )
        AND (
            bi.product_name ILIKE '%' || p_search_term || '%'
            OR bi.sku ILIKE '%' || p_search_term || '%'
            OR bi.barcode = p_search_term
        )
    ORDER BY bi.product_name
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. Update marketplace_products_with_stock view
-- Using INNER JOIN because we only want products actually listed in a tenant's branch_inventory
CREATE OR REPLACE VIEW marketplace_products_with_stock AS
SELECT
    bi.product_id as id,
    bi.tenant_id,
    bi.product_name as name,
    p.description,
    bi.sku,
    bi.barcode,
    p.category,
    bi.selling_price AS price,
    bi.image_url,
    COALESCE(SUM(bi.stock_quantity - bi.reserved_quantity), 0)::INTEGER AS stock_quantity,
    (COALESCE(SUM(bi.stock_quantity - bi.reserved_quantity), 0) > 0 OR bi.allow_preorder = TRUE) AS is_available,
    bi.allow_preorder,
    p.created_at,
    p.updated_at
FROM branch_inventory bi
JOIN products p ON p.id = bi.product_id
WHERE p.is_active = TRUE
  AND bi.is_active = TRUE
  AND p.deleted_at IS NULL
GROUP BY bi.product_id, bi.tenant_id, bi.product_name, p.description, bi.sku, bi.barcode,
         p.category, bi.selling_price, bi.image_url, bi.allow_preorder, p.created_at, p.updated_at;
