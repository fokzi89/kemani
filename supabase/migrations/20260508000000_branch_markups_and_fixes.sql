-- ============================================================
-- Migration: Branch Markups and PO Fixes
-- ============================================================
-- Description: Adds markup configuration to branches and 
--              ensures PO receiving always pulls product details.
-- ============================================================

-- 1. Add markup columns to branches
ALTER TABLE public.branches 
ADD COLUMN IF NOT EXISTS drug_markup DECIMAL(5,2) DEFAULT 30, -- 30% default
ADD COLUMN IF NOT EXISTS supermarket_markup DECIMAL(5,2) DEFAULT 20; -- 20% default

-- 2. Update receiving RPC to be more robust for names and prices
CREATE OR REPLACE FUNCTION public.receive_purchase_order(
    p_po_id UUID,
    p_received_items JSONB,
    p_notes TEXT DEFAULT NULL
)
RETURNS purchase_orders
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_po purchase_orders;
    v_received_item RECORD;
    v_po_item RECORD;
    v_total_preorder_qty INTEGER;
    v_to_fulfill INTEGER;
    v_remaining_received INTEGER;
    v_batch_id UUID;
    v_staff_id UUID;
    v_receipt_id UUID;
    v_old_qty INTEGER;
BEGIN
    v_staff_id := auth.uid();
    SELECT * INTO v_po FROM purchase_orders WHERE id = p_po_id;
    
    IF v_po.id IS NULL THEN RAISE EXCEPTION 'Purchase Order not found'; END IF;
    
    -- 1. Create the Receipt Group
    INSERT INTO purchase_order_receipts (tenant_id, po_id, staff_id, notes)
    VALUES (v_po.tenant_id, v_po.id, v_staff_id, p_notes)
    RETURNING id INTO v_receipt_id;

    -- 2. Process each received item
    FOR v_received_item IN SELECT * FROM jsonb_to_recordset(p_received_items) AS x(
        product_id UUID, received_qty INTEGER, batch_no TEXT, expiry_date DATE, unit_cost DECIMAL, unit_price DECIMAL, is_received BOOLEAN
    )
    LOOP
        -- Robust retrieval of product details (Fallback to products catalog if PO snapshot is missing)
        SELECT 
            COALESCE(poi.product_name, p.name) as product_name, 
            COALESCE(poi.strength, p.strength) as strength, 
            p.barcode as sku, 
            p.product_type, 
            p.image_url,
            p.unit_of_measure
        INTO v_po_item
        FROM products p
        LEFT JOIN purchase_order_items poi ON poi.product_id = p.id AND poi.po_id = p_po_id
        WHERE p.id = v_received_item.product_id;

        -- A. Record in receipt history
        INSERT INTO purchase_order_receipt_items (
            receipt_id, product_id, quantity, unit_cost, batch_no, expiry_date, is_received
        ) VALUES (
            v_receipt_id, v_received_item.product_id, v_received_item.received_qty, 
            v_received_item.unit_cost, v_received_item.batch_no, v_received_item.expiry_date,
            COALESCE(v_received_item.is_received, TRUE)
        );

        -- B. Handle Preorders
        SELECT SUM(preorder_quantity) INTO v_total_preorder_qty
        FROM branch_inventory
        WHERE branch_id = v_po.branch_id AND product_id = v_received_item.product_id;
        v_total_preorder_qty := COALESCE(v_total_preorder_qty, 0);
        
        v_to_fulfill := LEAST(v_received_item.received_qty, v_total_preorder_qty);
        v_remaining_received := v_received_item.received_qty - v_to_fulfill;

        IF v_to_fulfill > 0 THEN
            WITH fulfilled AS (
                SELECT id, LEAST(preorder_quantity, v_to_fulfill) as current_fulfill
                FROM branch_inventory
                WHERE branch_id = v_po.branch_id AND product_id = v_received_item.product_id AND preorder_quantity > 0
                ORDER BY created_at ASC
            )
            UPDATE branch_inventory bi
            SET preorder_quantity = bi.preorder_quantity - f.current_fulfill, updated_at = NOW()
            FROM fulfilled f WHERE bi.id = f.id;
        END IF;

        -- C. Update or Create Branch Inventory
        SELECT id, stock_quantity INTO v_batch_id, v_old_qty
        FROM branch_inventory
        WHERE branch_id = v_po.branch_id AND product_id = v_received_item.product_id
        ORDER BY created_at DESC
        LIMIT 1;

        IF v_batch_id IS NOT NULL THEN
            UPDATE branch_inventory
            SET stock_quantity = stock_quantity + v_remaining_received,
                batch_no = COALESCE(v_received_item.batch_no, batch_no),
                expiry_date = COALESCE(v_received_item.expiry_date, expiry_date),
                cost_price = v_received_item.unit_cost,
                selling_price = COALESCE(v_received_item.unit_price, selling_price),
                purchase_invoice = v_po.po_number,
                -- Snapshot details
                product_name = COALESCE(v_po_item.product_name, product_name),
                strength = COALESCE(v_po_item.strength, strength),
                sku = COALESCE(v_po_item.sku, sku),
                product_type = COALESCE(v_po_item.product_type, product_type),
                image_url = COALESCE(v_po_item.image_url, image_url),
                unit_of_measure = COALESCE(unit_of_measure, v_po_item.unit_of_measure),
                updated_at = NOW()
            WHERE id = v_batch_id;
        ELSE
            v_old_qty := 0;
            INSERT INTO branch_inventory (
                tenant_id, branch_id, product_id, stock_quantity, 
                batch_no, expiry_date, cost_price, selling_price, 
                purchase_invoice, purchase_code, added_by, is_active,
                product_name, strength, sku, product_type, image_url, unit_of_measure
            ) VALUES (
                v_po.tenant_id, v_po.branch_id, v_received_item.product_id, v_remaining_received,
                v_received_item.batch_no, v_received_item.expiry_date, v_received_item.unit_cost, v_received_item.unit_price,
                v_po.po_number, v_po.po_number, v_staff_id::text, TRUE,
                v_po_item.product_name, v_po_item.strength, v_po_item.sku, v_po_item.product_type, v_po_item.image_url, v_po_item.unit_of_measure
            ) RETURNING id INTO v_batch_id;
        END IF;

        -- D. Record Transaction
        INSERT INTO inventory_transactions (
            tenant_id, branch_id, product_id, branch_inventory_id,
            transaction_type, quantity_delta, previous_quantity, new_quantity,
            unit_cost, reference_id, reference_type, staff_id
        ) VALUES (
            v_po.tenant_id, v_po.branch_id, v_received_item.product_id, v_batch_id,
            'restock'::transaction_type, v_remaining_received, v_old_qty, v_old_qty + v_remaining_received,
            v_received_item.unit_cost, v_po.id, 'purchase_order', v_staff_id
        );
    END LOOP;

    SELECT * INTO v_po FROM purchase_orders WHERE id = p_po_id;
    RETURN v_po;
END;
$$;
