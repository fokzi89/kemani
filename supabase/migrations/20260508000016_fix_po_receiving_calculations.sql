-- ============================================================
-- Migration: Simplified PO Receiving (No Pre-orders)
-- ============================================================
-- Description: 
-- 1. Removes all pre-order fulfillment logic.
-- 2. Strictly increments stock_quantity for received items.
-- 3. Maintains batch tracking for regulatory compliance.
-- ============================================================

-- 1. Update the receiving RPC
DO $$ 
DECLARE 
    r RECORD;
BEGIN
    FOR r IN (SELECT oid::regprocedure as sig FROM pg_proc WHERE proname = 'receive_purchase_order' AND pronamespace = 'public'::regnamespace) LOOP
        EXECUTE 'DROP FUNCTION ' || r.sig || ' CASCADE';
    END LOOP;
END $$;

CREATE OR REPLACE FUNCTION public.receive_purchase_order(
    p_po_id UUID,
    p_received_items JSONB,
    p_notes TEXT DEFAULT NULL,
    p_branch_id UUID DEFAULT NULL
)
RETURNS purchase_orders
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_po purchase_orders;
    v_target_branch_id UUID;
    v_received_item RECORD;
    v_po_item RECORD;
    v_batch_id UUID;
    v_staff_id UUID;
    v_receipt_id UUID;
    v_old_qty INTEGER := 0;
BEGIN
    -- 1. Basic Setup
    v_staff_id := auth.uid();
    SELECT * INTO v_po FROM purchase_orders WHERE id = p_po_id FOR UPDATE;
    IF v_po.id IS NULL THEN RAISE EXCEPTION 'Purchase Order not found'; END IF;
    
    v_target_branch_id := COALESCE(p_branch_id, v_po.branch_id);

    -- 2. Create the Receipt Group record
    INSERT INTO purchase_order_receipts (tenant_id, po_id, staff_id, notes, branch_id)
    VALUES (v_po.tenant_id, v_po.id, v_staff_id, p_notes, v_target_branch_id)
    RETURNING id INTO v_receipt_id;

    -- 3. Process each item
    FOR v_received_item IN SELECT * FROM jsonb_to_recordset(p_received_items) AS x(
        product_id UUID, received_qty INTEGER, batch_no TEXT, expiry_date DATE, 
        unit_cost DECIMAL, unit_price DECIMAL, is_received BOOLEAN, unit_of_measure TEXT
    )
    LOOP
        -- Skip items with zero quantity
        IF COALESCE(v_received_item.received_qty, 0) = 0 THEN
            CONTINUE;
        END IF;

        -- Reset loop variables
        v_batch_id := NULL;
        v_old_qty := 0;
        v_po_item := NULL;

        -- A. Fetch Product/PO Item Details
        SELECT COALESCE(poi.product_name, p.name) as product_name, 
               COALESCE(poi.strength, p.strength) as strength, 
               p.barcode as sku, p.product_type, p.image_url
        INTO v_po_item 
        FROM products p 
        LEFT JOIN purchase_order_items poi ON poi.product_id = p.id AND poi.po_id = p_po_id
        WHERE p.id = v_received_item.product_id;

        -- B. Record Receipt Item
        INSERT INTO purchase_order_receipt_items (
            receipt_id, product_id, quantity, unit_cost, batch_no, expiry_date, is_received
        ) VALUES (
            v_receipt_id, v_received_item.product_id, v_received_item.received_qty, 
            v_received_item.unit_cost, v_received_item.batch_no, v_received_item.expiry_date,
            COALESCE(v_received_item.is_received, TRUE)
        );

        -- C. Upsert Inventory Batch (Direct Stock Update)
        SELECT id, stock_quantity INTO v_batch_id, v_old_qty 
        FROM branch_inventory 
        WHERE branch_id = v_target_branch_id 
          AND product_id = v_received_item.product_id 
          AND COALESCE(batch_no, '') = COALESCE(v_received_item.batch_no, '') 
        LIMIT 1;

        IF v_batch_id IS NOT NULL THEN
            UPDATE branch_inventory 
            SET stock_quantity = stock_quantity + v_received_item.received_qty,
                expiry_date = COALESCE(v_received_item.expiry_date, expiry_date),
                cost_price = COALESCE(v_received_item.unit_cost, cost_price),
                updated_at = NOW()
            WHERE id = v_batch_id;
        ELSE
            INSERT INTO branch_inventory (
                tenant_id, branch_id, product_id, stock_quantity, batch_no, expiry_date, 
                cost_price, selling_price, purchase_invoice, added_by, is_active, 
                product_name, strength, sku, product_type, image_url, unit_of_measure
            ) VALUES (
                v_po.tenant_id, v_target_branch_id, v_received_item.product_id, v_received_item.received_qty, 
                v_received_item.batch_no, v_received_item.expiry_date, v_received_item.unit_cost, 
                COALESCE(v_received_item.unit_price, v_received_item.unit_cost * 1.3), 
                v_po.po_number, v_staff_id::text, TRUE, 
                v_po_item.product_name, v_po_item.strength, v_po_item.sku, v_po_item.product_type, v_po_item.image_url, 
                COALESCE(v_received_item.unit_of_measure, 'unit')
            ) RETURNING id INTO v_batch_id;
        END IF;

        -- D. Record Transaction
        INSERT INTO inventory_transactions (
            tenant_id, branch_id, product_id, branch_inventory_id, transaction_type, 
            quantity_delta, previous_quantity, new_quantity, unit_cost, 
            reference_id, reference_type, staff_id
        ) VALUES (
            v_po.tenant_id, v_target_branch_id, v_received_item.product_id, v_batch_id, 
            'restock'::transaction_type, v_received_item.received_qty, COALESCE(v_old_qty, 0), COALESCE(v_old_qty, 0) + v_received_item.received_qty, 
            v_received_item.unit_cost, v_po.id, 'purchase_order', v_staff_id
        );
    END LOOP;

    -- 4. Sync PO status
    UPDATE purchase_orders SET updated_at = NOW() WHERE id = p_po_id;
    
    SELECT * INTO v_po FROM purchase_orders WHERE id = p_po_id;
    RETURN v_po;
END;
$$;
