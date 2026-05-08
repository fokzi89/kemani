-- ============================================================
-- Migration: Remove Redundant Database Functions
-- ============================================================
-- Description: Drops obsolete functions that have been replaced 
--              by direct RPC logic or newer trigger functions.
-- ============================================================

-- 1. Drop the manual sync function (Replaced by real-time triggers)
DROP FUNCTION IF EXISTS public.sync_purchase_order_quantities(UUID);

-- 2. Drop intermediate trigger functions
DROP FUNCTION IF EXISTS public.fn_sync_po_status();
DROP FUNCTION IF EXISTS public.sync_po_item_received_qty();

-- 3. Drop obsolete inventory population function
-- (The trigger was dropped in a previous migration, now we remove the function)
DROP FUNCTION IF EXISTS public.populate_branch_inventory_details();

-- 4. Optional: Clean up any old versions of the receiving RPC 
-- that might have had different signatures (if any existed)
-- (CREATE OR REPLACE already handles the current one)

COMMENT ON TABLE purchase_order_receipts IS 'Audit trail for stock receipts. Quantities are synced via triggers on receipt items.';
