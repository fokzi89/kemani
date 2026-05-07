-- ============================================================
-- Migration: Add Purchase Order Receipt Groups
-- ============================================================
-- Description: Creates tables to group PO receiving events, 
--              enabling better history tracking and reporting.
-- ============================================================

-- 1. Create Receipt Groups
CREATE TABLE IF NOT EXISTS purchase_order_receipts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    po_id UUID NOT NULL REFERENCES purchase_orders(id) ON DELETE CASCADE,
    staff_id UUID NOT NULL REFERENCES users(id),
    received_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. Create Receipt Items
CREATE TABLE IF NOT EXISTS purchase_order_receipt_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    receipt_id UUID NOT NULL REFERENCES purchase_order_receipts(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id),
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    unit_cost DECIMAL(12,2) NOT NULL,
    batch_no VARCHAR(100),
    expiry_date DATE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3. RLS Policies
ALTER TABLE purchase_order_receipts ENABLE ROW LEVEL SECURITY;
ALTER TABLE purchase_order_receipt_items ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view PO receipts in their tenant" ON purchase_order_receipts;
CREATE POLICY "Users can view PO receipts in their tenant"
    ON purchase_order_receipts FOR SELECT
    USING (tenant_id IN (SELECT tenant_id FROM users WHERE id = auth.uid()));

DROP POLICY IF EXISTS "Users can view PO receipt items in their tenant" ON purchase_order_receipt_items;
CREATE POLICY "Users can view PO receipt items in their tenant"
    ON purchase_order_receipt_items FOR SELECT
    USING (receipt_id IN (SELECT id FROM purchase_order_receipts WHERE tenant_id IN (SELECT tenant_id FROM users WHERE id = auth.uid())));

-- 4. Update the Receive RPC to include these tables
CREATE OR REPLACE FUNCTION receive_purchase_order(
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
    v_item RECORD;
    v_received_item RECORD;
    v_total_preorder_qty INTEGER;
    v_to_fulfill INTEGER;
    v_remaining_received INTEGER;
    v_batch_id UUID;
    v_staff_id UUID;
    v_receipt_id UUID;
BEGIN
    -- Get current user ID (staff_id)
    v_staff_id := auth.uid();

    SELECT * INTO v_po FROM purchase_orders WHERE id = p_po_id;
    
    IF v_po.id IS NULL THEN
        RAISE EXCEPTION 'Purchase Order not found';
    END IF;

    IF v_po.status NOT IN ('pending', 'partially_received') THEN
        RAISE EXCEPTION 'Purchase Order must be pending or partially received to receive stock';
    END IF;

    -- A. Create the Receipt Group record
    INSERT INTO purchase_order_receipts (tenant_id, po_id, staff_id, notes)
    VALUES (v_po.tenant_id, v_po.id, v_staff_id, p_notes)
    RETURNING id INTO v_receipt_id;

    -- B. Process each item
    FOR v_received_item IN SELECT * FROM jsonb_to_recordset(p_received_items) AS x(
        product_id UUID, received_qty INTEGER, batch_no TEXT, expiry_date DATE, unit_cost DECIMAL, unit_price DECIMAL
    )
    LOOP
        -- 1. Create Receipt Item record for history
        INSERT INTO purchase_order_receipt_items (
            receipt_id, product_id, quantity, unit_cost, batch_no, expiry_date
        ) VALUES (
            v_receipt_id, v_received_item.product_id, v_received_item.received_qty, 
            v_received_item.unit_cost, v_received_item.batch_no, v_received_item.expiry_date
        );

        -- 2. Calculate total preorder_quantity for this product in this branch
        SELECT SUM(preorder_quantity) INTO v_total_preorder_qty
        FROM branch_inventory
        WHERE branch_id = v_po.branch_id AND product_id = v_received_item.product_id;

        v_total_preorder_qty := COALESCE(v_total_preorder_qty, 0);
        
        -- 3. Determine fulfillment
        v_to_fulfill := LEAST(v_received_item.received_qty, v_total_preorder_qty);
        v_remaining_received := v_received_item.received_qty - v_to_fulfill;

        -- 4. Fulfill preorders (decrement preorder_quantity)
        IF v_to_fulfill > 0 THEN
            WITH fulfilled AS (
                SELECT id, LEAST(preorder_quantity, v_to_fulfill) as current_fulfill
                FROM branch_inventory
                WHERE branch_id = v_po.branch_id AND product_id = v_received_item.product_id AND preorder_quantity > 0
                ORDER BY created_at ASC
            )
            UPDATE branch_inventory bi
            SET preorder_quantity = bi.preorder_quantity - f.current_fulfill,
                updated_at = NOW()
            FROM fulfilled f
            WHERE bi.id = f.id;
        END IF;

        -- 5. Create/Update Batch in branch_inventory
        INSERT INTO branch_inventory (
            tenant_id, branch_id, product_id, stock_quantity, 
            batch_no, expiry_date, cost_price, selling_price, 
            purchase_invoice, purchase_code, added_by, 
            is_active
        ) VALUES (
            v_po.tenant_id, v_po.branch_id, v_received_item.product_id, v_remaining_received,
            v_received_item.batch_no, v_received_item.expiry_date, v_received_item.unit_cost, v_received_item.unit_price,
            v_po.po_number, v_po.po_number, v_staff_id::text,
            TRUE
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

        -- 7. Update purchase_order_items.received_qty
        UPDATE purchase_order_items
        SET received_qty = received_qty + v_received_item.received_qty,
            updated_at = NOW()
        WHERE po_id = p_po_id AND product_id = v_received_item.product_id;

    END LOOP;

    -- 8. Update PO status
    IF NOT EXISTS (
        SELECT 1 FROM purchase_order_items 
        WHERE po_id = p_po_id AND received_qty < expected_qty
    ) THEN
        UPDATE purchase_orders SET status = 'completed', updated_at = NOW() WHERE id = p_po_id;
    ELSE
        UPDATE purchase_orders SET status = 'partially_received', updated_at = NOW() WHERE id = p_po_id;
    END IF;

    SELECT * INTO v_po FROM purchase_orders WHERE id = p_po_id;
    RETURN v_po;
END;
$$;
