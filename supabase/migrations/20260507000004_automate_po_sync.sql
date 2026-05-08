-- ============================================================
-- Migration: Automate PO Quantity Tracking via Triggers
-- ============================================================
-- Description: Creates a trigger that automatically updates
--              purchase_order_items.received_qty whenever a
--              receipt item is inserted, updated, or deleted.
-- ============================================================

-- 1. Create the Trigger Function
CREATE OR REPLACE FUNCTION public.fn_sync_po_item_received_qty()
RETURNS TRIGGER AS $$
DECLARE
    v_po_id UUID;
    v_product_id UUID;
BEGIN
    -- Determine the PO ID and Product ID to sync
    IF (TG_OP = 'DELETE') THEN
        v_product_id := OLD.product_id;
        SELECT po_id INTO v_po_id FROM purchase_order_receipts WHERE id = OLD.receipt_id;
    ELSE
        v_product_id := NEW.product_id;
        SELECT po_id INTO v_po_id FROM purchase_order_receipts WHERE id = NEW.receipt_id;
    END IF;

    -- Recalculate total received for this specific product in this PO
    UPDATE purchase_order_items
    SET received_qty = COALESCE((
        SELECT SUM(ri.quantity)
        FROM purchase_order_receipt_items ri
        JOIN purchase_order_receipts r ON ri.receipt_id = r.id
        WHERE r.po_id = v_po_id AND ri.product_id = v_product_id
    ), 0),
    updated_at = NOW()
    WHERE po_id = v_po_id AND product_id = v_product_id;

    -- Update PO status based on the new totals
    IF NOT EXISTS (
        SELECT 1 FROM purchase_order_items 
        WHERE po_id = v_po_id AND received_qty < expected_qty
    ) THEN
        UPDATE purchase_orders SET status = 'completed', updated_at = NOW() WHERE id = v_po_id;
    ELSIF EXISTS (
        SELECT 1 FROM purchase_order_items 
        WHERE po_id = v_po_id AND received_qty > 0
    ) THEN
        UPDATE purchase_orders SET status = 'partially_received', updated_at = NOW() WHERE id = v_po_id;
    ELSE
        UPDATE purchase_orders SET status = 'pending', updated_at = NOW() WHERE id = v_po_id;
    END IF;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- 2. Create the Trigger
DROP TRIGGER IF EXISTS tr_sync_po_item_received_qty ON purchase_order_receipt_items;
CREATE TRIGGER tr_sync_po_item_received_qty
AFTER INSERT OR UPDATE OR DELETE ON purchase_order_receipt_items
FOR EACH ROW
EXECUTE FUNCTION public.fn_sync_po_item_received_qty();

-- 3. Cleanup: Remove the manual update from the main RPC to prevent double processing
-- Note: We keep the sync logic in the trigger for absolute accuracy.
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
    v_total_preorder_qty INTEGER;
    v_to_fulfill INTEGER;
    v_remaining_received INTEGER;
    v_batch_id UUID;
    v_staff_id UUID;
    v_receipt_id UUID;
BEGIN
    v_staff_id := auth.uid();
    SELECT * INTO v_po FROM purchase_orders WHERE id = p_po_id;
    
    IF v_po.id IS NULL THEN RAISE EXCEPTION 'Purchase Order not found'; END IF;
    IF v_po.status NOT IN ('pending', 'partially_received') THEN
        RAISE EXCEPTION 'Purchase Order must be pending or partially received to receive stock';
    END IF;

    INSERT INTO purchase_order_receipts (tenant_id, po_id, staff_id, notes)
    VALUES (v_po.tenant_id, v_po.id, v_staff_id, p_notes)
    RETURNING id INTO v_receipt_id;

    FOR v_received_item IN SELECT * FROM jsonb_to_recordset(p_received_items) AS x(
        product_id UUID, received_qty INTEGER, batch_no TEXT, expiry_date DATE, unit_cost DECIMAL, unit_price DECIMAL, is_received BOOLEAN
    )
    LOOP
        -- 1. Create Receipt Item (The trigger will now handle updating purchase_order_items)
        INSERT INTO purchase_order_receipt_items (
            receipt_id, product_id, quantity, unit_cost, batch_no, expiry_date, is_received
        ) VALUES (
            v_receipt_id, v_received_item.product_id, v_received_item.received_qty, 
            v_received_item.unit_cost, v_received_item.batch_no, v_received_item.expiry_date,
            COALESCE(v_received_item.is_received, TRUE)
        );

        -- 2. Calculate total preorder_quantity
        SELECT SUM(preorder_quantity) INTO v_total_preorder_qty
        FROM branch_inventory
        WHERE branch_id = v_po.branch_id AND product_id = v_received_item.product_id;
        v_total_preorder_qty := COALESCE(v_total_preorder_qty, 0);
        
        -- 3. Determine fulfillment
        v_to_fulfill := LEAST(v_received_item.received_qty, v_total_preorder_qty);
        v_remaining_received := v_received_item.received_qty - v_to_fulfill;

        -- 4. Fulfill preorders
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

        -- 5. Create/Update Batch
        INSERT INTO branch_inventory (
            tenant_id, branch_id, product_id, stock_quantity, 
            batch_no, expiry_date, cost_price, selling_price, 
            purchase_invoice, purchase_code, added_by, is_active
        ) VALUES (
            v_po.tenant_id, v_po.branch_id, v_received_item.product_id, v_remaining_received,
            v_received_item.batch_no, v_received_item.expiry_date, v_received_item.unit_cost, v_received_item.unit_price,
            v_po.po_number, v_po.po_number, v_staff_id::text, TRUE
        ) RETURNING id INTO v_batch_id;

        -- 6. Record Inventory Transaction
        INSERT INTO inventory_transactions (
            tenant_id, branch_id, product_id, branch_inventory_id,
            transaction_type, quantity_delta, previous_quantity, new_quantity,
            unit_cost, reference_id, reference_type, staff_id
        ) VALUES (
            v_po.tenant_id, v_po.branch_id, v_received_item.product_id, v_batch_id,
            'restock'::transaction_type, v_received_item.received_qty, 0, v_remaining_received,
            v_received_item.unit_cost, v_po.id, 'purchase_order', v_staff_id
        );

        -- REMOVED: Manual update of purchase_order_items.received_qty
        -- (Now handled automatically by the trigger on purchase_order_receipt_items)
    END LOOP;

    -- PO Status is also handled by the trigger now
    SELECT * INTO v_po FROM purchase_orders WHERE id = p_po_id;
    RETURN v_po;
END;
$$;

-- 4. Run a one-time sync for all existing POs to ensure consistency
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN SELECT id FROM purchase_orders LOOP
        PERFORM sync_purchase_order_quantities(r.id);
    END LOOP;
END$$;
