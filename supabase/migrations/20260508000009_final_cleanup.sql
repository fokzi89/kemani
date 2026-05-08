-- ============================================================
-- Migration: Final Legacy Function Cleanup
-- ============================================================
-- Description: Removes the last remaining redundant functions 
--              to ensure the new trigger-based architecture 
--              is the sole source of truth.
-- ============================================================

-- 1. Remove manual sync function (Now handled by triggers)
DROP FUNCTION IF EXISTS public.sync_purchase_order_quantities(UUID);

-- 2. Remove legacy inventory detail function (Now handled by the Receiving RPC)
DROP FUNCTION IF EXISTS public.populate_branch_inventory_details();

-- 3. Cleanup: Ensure any old status triggers are also gone
DROP TRIGGER IF EXISTS tr_sync_po_status ON purchase_order_receipt_items;
DROP FUNCTION IF EXISTS public.fn_sync_po_status();

-- 4. Audit Note
COMMENT ON FUNCTION public.receive_purchase_order IS 'Primary RPC for receiving PO stock. Handles batch tracking, markup, UoM, and fulfillment.';
