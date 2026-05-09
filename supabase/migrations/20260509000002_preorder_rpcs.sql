-- ============================================================
-- Migration: Pre-order RPCs
-- ============================================================
-- 1. checkout_storefront_order  — adds p_is_preorder_order mode
-- 2. receive_purchase_order     — auto-fulfils pre-orders on receipt
--                                 + inserts staff_notifications
-- ============================================================

-- ── 1. CHECKOUT (Storefront) — with pre-order support ────────────────────────
-- Must DROP first because we are changing the parameter list
DROP FUNCTION IF EXISTS checkout_storefront_order(
    UUID, UUID, UUID, order_type, fulfillment_type,
    DECIMAL, DECIMAL, DECIMAL, DECIMAL,
    UUID, TEXT, JSONB, DECIMAL, TEXT, TEXT, TEXT
);

CREATE OR REPLACE FUNCTION checkout_storefront_order(
    p_tenant_id             UUID,
    p_branch_id             UUID,
    p_customer_id           UUID,
    p_order_type            order_type,
    p_fulfillment_type      fulfillment_type,
    p_subtotal              DECIMAL,
    p_delivery_fee          DECIMAL,
    p_tax_amount            DECIMAL,
    p_total_amount          DECIMAL,
    p_delivery_address_id   UUID,
    p_special_instructions  TEXT,
    p_items                 JSONB,
    p_service_charge        DECIMAL  DEFAULT 0,
    p_payment_reference     TEXT     DEFAULT NULL,
    p_billing_address       TEXT     DEFAULT NULL,
    p_shipping_address      TEXT     DEFAULT NULL,
    p_is_preorder_order     BOOLEAN  DEFAULT false   -- NEW: true = pre-order checkout
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_order_id          UUID;
    v_item              RECORD;
    v_batch             RECORD;
    v_req_qty           INTEGER;
    v_allocated_qty     INTEGER;
    v_allocations       JSONB;
    v_primary_batch_id  UUID;
    -- pre-order guards
    v_preorders_enabled BOOLEAN;
    v_allow_preorder    BOOLEAN;
    v_preorder_limit    INTEGER;
    v_current_preorder  INTEGER;
    v_bi_id             UUID;
    v_product_name      TEXT;
BEGIN
    -- ── Validate totals ──
    IF p_total_amount != (p_subtotal + p_delivery_fee + p_tax_amount + p_service_charge) THEN
        RAISE EXCEPTION 'Total amount does not match subtotal + fees + tax + service charge';
    END IF;

    -- ── Create order header ──
    INSERT INTO orders (
        tenant_id, branch_id, order_number, customer_id,
        order_type, order_status, payment_status, payment_method, payment_reference,
        subtotal, delivery_fee, tax_amount, service_charge, total_amount,
        fulfillment_type, delivery_address_id, special_instructions,
        billing_address, shipping_address, is_preorder_order
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
        p_shipping_address,
        p_is_preorder_order
    ) RETURNING id INTO v_order_id;

    -- ════════════════════════════════════════════════════════
    -- BRANCH A: Physical stock checkout (normal order)
    -- ════════════════════════════════════════════════════════
    IF NOT p_is_preorder_order THEN

        FOR v_item IN SELECT * FROM jsonb_to_recordset(p_items) AS x(
            product_id UUID, product_name TEXT, quantity INTEGER,
            unit_price DECIMAL, subtotal DECIMAL
        )
        LOOP
            v_req_qty          := v_item.quantity;
            v_allocations      := '[]'::jsonb;
            v_primary_batch_id := NULL;

            -- FIFO allocation by expiry then insertion date
            FOR v_batch IN
                SELECT id, stock_quantity AS available_balance
                FROM branch_inventory
                WHERE branch_id = p_branch_id
                  AND product_id = v_item.product_id
                  AND is_active = true
                  AND stock_quantity > 0
                ORDER BY expiry_date ASC NULLS LAST, created_at ASC
                FOR UPDATE
            LOOP
                IF v_req_qty <= 0 THEN EXIT; END IF;

                v_allocated_qty := LEAST(v_batch.available_balance, v_req_qty);

                IF v_primary_batch_id IS NULL THEN
                    v_primary_batch_id := v_batch.id;
                END IF;

                UPDATE branch_inventory
                   SET stock_quantity = stock_quantity - v_allocated_qty
                 WHERE id = v_batch.id;

                v_allocations := v_allocations || jsonb_build_object(
                    'batch_id',    v_batch.id,
                    'quantity',    v_allocated_qty,
                    'is_preorder', false
                );

                v_req_qty := v_req_qty - v_allocated_qty;
            END LOOP;

            IF v_req_qty > 0 THEN
                RAISE EXCEPTION 'Insufficient stock for product: % (short by %)',
                      v_item.product_name, v_req_qty;
            END IF;

            INSERT INTO public.sale_items (
                tenant_id, order_id, branch_id, inventory_id,
                product_id, product_name, quantity, unit_price, subtotal,
                discount_amount, batch_allocations, is_preorder
            ) VALUES (
                p_tenant_id, v_order_id, p_branch_id, v_primary_batch_id,
                v_item.product_id, v_item.product_name,
                v_item.quantity, v_item.unit_price, v_item.subtotal,
                0, v_allocations, false
            );
        END LOOP;

    -- ════════════════════════════════════════════════════════
    -- BRANCH B: Pre-order checkout
    -- ════════════════════════════════════════════════════════
    ELSE

        -- Load tenant global switch once
        SELECT preorders_enabled INTO v_preorders_enabled
          FROM tenants WHERE id = p_tenant_id;

        IF NOT COALESCE(v_preorders_enabled, false) THEN
            RAISE EXCEPTION 'Pre-orders are not enabled for this store.';
        END IF;

        FOR v_item IN SELECT * FROM jsonb_to_recordset(p_items) AS x(
            product_id UUID, product_name TEXT, quantity INTEGER,
            unit_price DECIMAL, subtotal DECIMAL
        )
        LOOP
            -- Get the inventory row for this product in this branch
            SELECT id, allow_preorder, preorder_quantity, preorder_limit
              INTO v_bi_id, v_allow_preorder, v_current_preorder, v_preorder_limit
              FROM branch_inventory
             WHERE branch_id = p_branch_id AND product_id = v_item.product_id
               AND is_active = true
             LIMIT 1;

            IF v_bi_id IS NULL THEN
                RAISE EXCEPTION 'Product % is not listed in this branch.',
                      v_item.product_name;
            END IF;

            IF NOT COALESCE(v_allow_preorder, false) THEN
                RAISE EXCEPTION 'Pre-order is not enabled for product: %',
                      v_item.product_name;
            END IF;

            -- Enforce preorder_limit if set
            IF v_preorder_limit IS NOT NULL THEN
                IF (v_current_preorder + v_item.quantity) > v_preorder_limit THEN
                    RAISE EXCEPTION
                        'Pre-order limit reached for %: only % more unit(s) can be pre-ordered.',
                        v_item.product_name,
                        GREATEST(v_preorder_limit - v_current_preorder, 0);
                END IF;
            END IF;

            -- Increment demand counter
            UPDATE branch_inventory
               SET preorder_quantity = preorder_quantity + v_item.quantity
             WHERE id = v_bi_id;

            INSERT INTO public.sale_items (
                tenant_id, order_id, branch_id, inventory_id,
                product_id, product_name, quantity, unit_price, subtotal,
                discount_amount, batch_allocations, is_preorder
            ) VALUES (
                p_tenant_id, v_order_id, p_branch_id, v_bi_id,
                v_item.product_id, v_item.product_name,
                v_item.quantity, v_item.unit_price, v_item.subtotal,
                0, '[]'::jsonb, true
            );
        END LOOP;

    END IF;

    RETURN v_order_id;
END;
$$;


-- ── 2. RECEIVE PURCHASE ORDER — with pre-order auto-fulfilment ────────────────
CREATE OR REPLACE FUNCTION public.receive_purchase_order(
    p_po_id         UUID,
    p_received_items JSONB,
    p_notes         TEXT    DEFAULT NULL,
    p_branch_id     UUID    DEFAULT NULL
)
RETURNS purchase_orders
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_po            purchase_orders;
    v_target_branch_id UUID;
    v_received_item RECORD;
    v_po_item       RECORD;
    v_batch_id      UUID;
    v_staff_id      UUID;
    v_receipt_id    UUID;
    v_old_qty       INTEGER;
    -- pre-order fulfilment
    v_preorder_qty  INTEGER;
    v_to_fulfill    INTEGER;
    v_product_name  TEXT;
BEGIN
    v_staff_id := auth.uid();

    SELECT * INTO v_po FROM purchase_orders WHERE id = p_po_id FOR UPDATE;
    IF v_po.id IS NULL THEN
        RAISE EXCEPTION 'Purchase Order not found';
    END IF;

    v_target_branch_id := COALESCE(p_branch_id, v_po.branch_id);

    INSERT INTO purchase_order_receipts (tenant_id, po_id, staff_id, notes, branch_id)
    VALUES (v_po.tenant_id, v_po.id, v_staff_id, p_notes, v_target_branch_id)
    RETURNING id INTO v_receipt_id;

    FOR v_received_item IN SELECT * FROM jsonb_to_recordset(p_received_items) AS x(
        product_id UUID, received_qty INTEGER, batch_no TEXT, expiry_date DATE,
        unit_cost DECIMAL, unit_price DECIMAL, is_received BOOLEAN, unit_of_measure TEXT
    )
    LOOP
        IF COALESCE(v_received_item.received_qty, 0) = 0 THEN CONTINUE; END IF;

        v_batch_id := NULL;
        v_old_qty  := 0;

        -- Fetch product meta from PO items
        SELECT COALESCE(poi.product_name, p.name)       AS product_name,
               COALESCE(poi.strength,     p.strength)   AS strength,
               p.barcode                                AS sku,
               p.product_type,
               p.image_url
          INTO v_po_item
          FROM products p
          LEFT JOIN purchase_order_items poi
            ON poi.product_id = p.id AND poi.po_id = p_po_id
         WHERE p.id = v_received_item.product_id;

        v_product_name := v_po_item.product_name;

        -- Record the receipt line
        INSERT INTO purchase_order_receipt_items (
            receipt_id, product_id, quantity, unit_cost, batch_no,
            expiry_date, is_received
        ) VALUES (
            v_receipt_id, v_received_item.product_id,
            v_received_item.received_qty, v_received_item.unit_cost,
            v_received_item.batch_no, v_received_item.expiry_date,
            COALESCE(v_received_item.is_received, TRUE)
        );

        -- ── Upsert inventory batch ──────────────────────────────────────────
        SELECT id, stock_quantity INTO v_batch_id, v_old_qty
          FROM branch_inventory
         WHERE branch_id = v_target_branch_id
           AND product_id = v_received_item.product_id
           AND COALESCE(batch_no, '') = COALESCE(v_received_item.batch_no, '')
         LIMIT 1;

        IF v_batch_id IS NOT NULL THEN
            UPDATE branch_inventory
               SET stock_quantity = stock_quantity + v_received_item.received_qty,
                   expiry_date    = COALESCE(v_received_item.expiry_date, expiry_date),
                   cost_price     = COALESCE(v_received_item.unit_cost,   cost_price),
                   updated_at     = NOW()
             WHERE id = v_batch_id;
        ELSE
            INSERT INTO branch_inventory (
                tenant_id, branch_id, product_id, stock_quantity, batch_no,
                expiry_date, cost_price, selling_price, purchase_invoice,
                added_by, is_active, product_name, strength, sku,
                product_type, image_url, unit_of_measure
            ) VALUES (
                v_po.tenant_id, v_target_branch_id, v_received_item.product_id,
                v_received_item.received_qty,
                v_received_item.batch_no, v_received_item.expiry_date,
                v_received_item.unit_cost,
                COALESCE(v_received_item.unit_price, v_received_item.unit_cost * 1.3),
                v_po.po_number, v_staff_id::text, TRUE,
                v_po_item.product_name, v_po_item.strength, v_po_item.sku,
                v_po_item.product_type, v_po_item.image_url,
                COALESCE(v_received_item.unit_of_measure, 'unit')
            ) RETURNING id INTO v_batch_id;
        END IF;

        -- ── Log inventory transaction ───────────────────────────────────────
        INSERT INTO inventory_transactions (
            tenant_id, branch_id, product_id, branch_inventory_id,
            transaction_type, quantity_delta, previous_quantity, new_quantity,
            unit_cost, reference_id, reference_type, staff_id
        ) VALUES (
            v_po.tenant_id, v_target_branch_id, v_received_item.product_id, v_batch_id,
            'restock'::transaction_type, v_received_item.received_qty,
            COALESCE(v_old_qty, 0),
            COALESCE(v_old_qty, 0) + v_received_item.received_qty,
            v_received_item.unit_cost, v_po.id, 'purchase_order', v_staff_id
        );

        -- ── Auto-fulfil outstanding pre-orders ─────────────────────────────
        -- Sum ALL pre-order demand for this product in this branch
        SELECT COALESCE(SUM(preorder_quantity), 0) INTO v_preorder_qty
          FROM branch_inventory
         WHERE branch_id = v_target_branch_id
           AND product_id = v_received_item.product_id;

        IF v_preorder_qty > 0 THEN
            v_to_fulfill := LEAST(v_preorder_qty, v_received_item.received_qty);

            -- Decrement demand counter proportionally across rows for this product
            UPDATE branch_inventory
               SET preorder_quantity = GREATEST(
                       preorder_quantity - LEAST(preorder_quantity, v_to_fulfill),
                       0
                   )
             WHERE branch_id = v_target_branch_id
               AND product_id = v_received_item.product_id
               AND preorder_quantity > 0;

            -- Notify staff
            INSERT INTO staff_notifications (
                tenant_id, branch_id, type, title, body, metadata
            ) VALUES (
                v_po.tenant_id,
                v_target_branch_id,
                'preorder_fulfilled',
                'Pre-orders Ready for Collection',
                format(
                    '%s unit(s) of "%s" are now in stock and satisfy outstanding pre-orders. Please contact the customers.',
                    v_to_fulfill,
                    v_product_name
                ),
                jsonb_build_object(
                    'product_id',              v_received_item.product_id,
                    'product_name',            v_product_name,
                    'fulfilled_qty',           v_to_fulfill,
                    'remaining_preorder_qty',  v_preorder_qty - v_to_fulfill,
                    'po_id',                   v_po.id
                )
            );
        END IF;

    END LOOP;

    -- Update PO timestamp
    UPDATE purchase_orders SET updated_at = NOW() WHERE id = p_po_id;
    SELECT * INTO v_po FROM purchase_orders WHERE id = p_po_id;
    RETURN v_po;
END;
$$;
