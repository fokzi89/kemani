-- ============================================================
-- Migration: Add PO Quantity Sync Function
-- ============================================================
-- Description: Adds a function to recalculate received_qty 
--              from the actual receipt history to fix data
--              inconsistencies.
-- ============================================================

CREATE OR REPLACE FUNCTION public.sync_purchase_order_quantities(p_po_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Reset all received_qty for this PO to 0 first
    UPDATE purchase_order_items
    SET received_qty = 0,
        updated_at = NOW()
    WHERE po_id = p_po_id;

    -- Recalculate from receipt items
    WITH actual_received AS (
        SELECT 
            ri.product_id,
            SUM(ri.quantity) as total_qty
        FROM purchase_order_receipt_items ri
        JOIN purchase_order_receipts r ON ri.receipt_id = r.id
        WHERE r.po_id = p_po_id
        GROUP BY ri.product_id
    )
    UPDATE purchase_order_items poi
    SET received_qty = ar.total_qty,
        updated_at = NOW()
    FROM actual_received ar
    WHERE poi.po_id = p_po_id 
    AND poi.product_id = ar.product_id;

    -- Update PO status based on new quantities
    IF NOT EXISTS (
        SELECT 1 FROM purchase_order_items 
        WHERE po_id = p_po_id AND received_qty < expected_qty
    ) THEN
        UPDATE purchase_orders SET status = 'completed', updated_at = NOW() WHERE id = p_po_id;
    ELSIF EXISTS (
        SELECT 1 FROM purchase_order_items 
        WHERE po_id = p_po_id AND received_qty > 0
    ) THEN
        UPDATE purchase_orders SET status = 'partially_received', updated_at = NOW() WHERE id = p_po_id;
    ELSE
        UPDATE purchase_orders SET status = 'pending', updated_at = NOW() WHERE id = p_po_id;
    END IF;
END;
$$;
