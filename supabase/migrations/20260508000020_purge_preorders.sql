-- ============================================================
-- Migration: Purge Pre-order Feature
-- ============================================================
-- Description: 
-- 1. Drops preorder-related columns from branch_inventory.
-- 2. Drops preorder-related columns from products.
-- 3. Removes preorder settings from tenants.
-- ============================================================

-- Drop views that depend on preorder columns FIRST to avoid dependency errors
DROP VIEW IF EXISTS marketplace_products_with_stock;
DROP VIEW IF EXISTS product_stock_summary;

DO $$
BEGIN
    -- 1. Remove from branch_inventory
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'branch_inventory' AND column_name = 'preorder_quantity') THEN
        ALTER TABLE branch_inventory DROP COLUMN preorder_quantity;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'branch_inventory' AND column_name = 'allow_preorder') THEN
        ALTER TABLE branch_inventory DROP COLUMN allow_preorder;
    END IF;

    -- 2. Remove from products
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'products' AND column_name = 'allow_preorder') THEN
        ALTER TABLE products DROP COLUMN allow_preorder;
    END IF;

    -- 3. Remove from tenants
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'tenants' AND column_name = 'preorders_enabled') THEN
        ALTER TABLE tenants DROP COLUMN preorders_enabled;
    END IF;
END $$;

-- Recreate v_branch_products view without any preorder columns
CREATE OR REPLACE VIEW v_branch_products AS
SELECT
    p.*,
    bi.branch_id,
    bi.stock_quantity,
    bi.low_stock_threshold,
    bi.expiry_date,
    bi.expiry_alert_days,
    bi.is_active as inventory_active,
    CASE
        WHEN bi.stock_quantity <= bi.low_stock_threshold THEN true
        ELSE false
    END as is_low_stock,
    CASE
        WHEN bi.expiry_date IS NOT NULL
        AND bi.expiry_date <= CURRENT_DATE + (bi.expiry_alert_days || ' days')::INTERVAL
        THEN true
        ELSE false
    END as is_expiring_soon
FROM products p
INNER JOIN branch_inventory bi ON bi.product_id = p.id
WHERE p._sync_is_deleted = false
AND bi._sync_is_deleted = false;


