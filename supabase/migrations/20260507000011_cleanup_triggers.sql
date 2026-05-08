-- ============================================================
-- Migration: Cleanup Irrelevant Triggers
-- ============================================================
-- Description: Removes redundant snapshot triggers that have 
--              been replaced by direct RPC logic and early
--              PO snapshots.
-- ============================================================

-- 1. Remove the redundant detail population trigger on branch_inventory
-- Reason: This is now handled directly by the receive_purchase_order RPC
-- for accuracy and to prevent overwriting PO-time snapshots.
DROP TRIGGER IF EXISTS trg_populate_branch_inventory_details ON public.branch_inventory;

-- 2. Optional: Clean up the function if it's not used anywhere else
-- (We'll keep it for now in case other modules rely on it, but the trigger is gone)

-- Note: We are KEEPING these essential triggers:
-- - tr_sync_po_item_received_qty (Essential for PO Dashboard sync)
-- - trg_sync_stock_balance (Essential for real-time inventory totals)
-- - trigger_check_reorder_alert (Essential for low stock notifications)
-- - trg_populate_po_item_details (Essential for the new Early Snapshot logic)
