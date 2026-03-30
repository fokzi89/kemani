-- ============================================================
-- Migration: Batch Number and Multi-Inventory Lot Support
-- ============================================================
-- Description: Adds batch_no support and allows multiple inventory 
--              records per product per branch (to track lots).
-- ============================================================

-- 1. Add batch_no column if it doesn't exist
ALTER TABLE branch_inventory
ADD COLUMN IF NOT EXISTS batch_no VARCHAR(100);

-- 2. Refactor unique constraints to allow lot-based tracking
-- Drop the legacy one-record-per-product constraint
ALTER TABLE branch_inventory 
DROP CONSTRAINT IF EXISTS branch_inventory_branch_id_product_id_key;

-- Drop any previous attempts at this constraint
ALTER TABLE branch_inventory
DROP CONSTRAINT IF EXISTS branch_inventory_branch_product_batch_unique;

-- Add new composite unique constraint including batch_no
-- Note: PostgreSQL allows multiple NULLs in UNIQUE constraints, 
-- but we'll use empty string as default to ensure predictability if needed.
ALTER TABLE branch_inventory
ADD CONSTRAINT branch_inventory_branch_product_batch_unique 
UNIQUE (branch_id, product_id, batch_no);

COMMENT ON COLUMN branch_inventory.batch_no IS 'Batch or Lot identifying number for this specific stock entry';
