-- ============================================================
-- Migration: Simplified Repair RPC (No Pre-orders)
-- ============================================================

CREATE OR REPLACE FUNCTION public.repair_inventory_levels()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_row RECORD;
    v_actual_in INTEGER;
    v_actual_out INTEGER;
    v_actual_stock INTEGER;
    v_count INTEGER := 0;
BEGIN
    -- Fix Stock Quantity Discrepancies
    FOR v_row IN 
        SELECT id, product_id, branch_id, batch_no, stock_quantity 
        FROM branch_inventory
    LOOP
        -- Calculate Total Received
        SELECT COALESCE(SUM(ri.quantity), 0) INTO v_actual_in
        FROM purchase_order_receipt_items ri
        JOIN purchase_order_receipts r ON ri.receipt_id = r.id
        WHERE r.branch_id = v_row.branch_id 
          AND ri.product_id = v_row.product_id
          AND COALESCE(ri.batch_no, '') = COALESCE(v_row.batch_no, '')
          AND COALESCE(ri.is_received, TRUE) = TRUE;

        -- Calculate Total Sold
        SELECT COALESCE(SUM(si.quantity), 0) INTO v_actual_out
        FROM sale_items si
        JOIN sales s ON si.sale_id = s.id
        WHERE si.inventory_id = v_row.id
          AND s.sale_status = 'completed';

        v_actual_stock := v_actual_in - v_actual_out;
        
        -- Update the row — physical stock only
        UPDATE branch_inventory 
        SET stock_quantity = GREATEST(v_actual_stock, 0),
            updated_at = NOW()
        WHERE id = v_row.id;
        
        v_count := v_count + 1;
    END LOOP;

    RETURN jsonb_build_object('success', true, 'repaired_rows', v_count, 'message', 'Inventory levels recalculated from physical receipts.');
END;
$$;
