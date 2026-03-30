-- ============================================
-- Migration: Tenant-Scoped Products with Branch Inventory
-- Description: Convert products from branch-scoped to tenant-scoped
--              and create separate branch_inventory table
-- Created: 2026-02-23
-- ============================================

-- ============================================
-- STEP 1: Create branch_inventory table
-- ============================================

CREATE TABLE IF NOT EXISTS branch_inventory (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,

    -- Stock management
    stock_quantity INTEGER NOT NULL DEFAULT 0 CHECK (stock_quantity >= 0),
    low_stock_threshold INTEGER DEFAULT 10 CHECK (low_stock_threshold >= 0),

    -- Expiry tracking (for perishable items)
    expiry_date DATE,
    expiry_alert_days INTEGER DEFAULT 30 CHECK (expiry_alert_days >= 0),

    -- Metadata
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Sync fields
    _sync_version BIGINT DEFAULT 1,
    _sync_modified_at TIMESTAMPTZ DEFAULT NOW(),
    _sync_client_id UUID,
    _sync_is_deleted BOOLEAN DEFAULT FALSE,

    -- Ensure one inventory record per product per branch
    UNIQUE(branch_id, product_id)
);

-- Indexes for branch_inventory
CREATE INDEX IF NOT EXISTS idx_branch_inventory_tenant ON branch_inventory(tenant_id);
CREATE INDEX IF NOT EXISTS idx_branch_inventory_branch ON branch_inventory(branch_id);
CREATE INDEX IF NOT EXISTS idx_branch_inventory_product ON branch_inventory(product_id);
CREATE INDEX IF NOT EXISTS idx_branch_inventory_low_stock ON branch_inventory(branch_id)
    WHERE stock_quantity <= low_stock_threshold AND is_active = true;
CREATE INDEX IF NOT EXISTS idx_branch_inventory_expiry ON branch_inventory(branch_id, expiry_date)
    WHERE expiry_date IS NOT NULL AND is_active = true;

-- RLS for branch_inventory
ALTER TABLE branch_inventory ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view inventory in their tenant" ON branch_inventory;
CREATE POLICY "Users can view inventory in their tenant"
    ON branch_inventory FOR SELECT
    USING (tenant_id IN (SELECT tenant_id FROM users WHERE id = auth.uid()));

DROP POLICY IF EXISTS "Tenant admins can manage all inventory" ON branch_inventory;
CREATE POLICY "Tenant admins can manage all inventory"
    ON branch_inventory FOR ALL
    USING (
        tenant_id IN (
            SELECT tenant_id FROM users
            WHERE id = auth.uid()
            AND role = 'tenant_admin'
        )
    );

DROP POLICY IF EXISTS "Branch managers can manage their branch inventory" ON branch_inventory;
CREATE POLICY "Branch managers can manage their branch inventory"
    ON branch_inventory FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid()
            AND role = 'branch_manager'
            AND tenant_id = branch_inventory.tenant_id
            AND branch_id = branch_inventory.branch_id
        )
    );

DROP POLICY IF EXISTS "Staff can update inventory in their branch" ON branch_inventory;
CREATE POLICY "Staff can update inventory in their branch"
    ON branch_inventory FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid()
            AND role = 'cashier'
            AND tenant_id = branch_inventory.tenant_id
            AND branch_id = branch_inventory.branch_id
        )
    );

-- Trigger to update updated_at
DROP TRIGGER IF EXISTS set_updated_at ON branch_inventory;
CREATE TRIGGER set_updated_at
    BEFORE UPDATE ON branch_inventory
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();

COMMENT ON TABLE branch_inventory IS 'Branch-specific inventory levels for tenant products. Branch managers can manage stock_quantity, low_stock_threshold, expiry_date, and expiry_alert_days for their branch.';
COMMENT ON COLUMN branch_inventory.stock_quantity IS 'Current stock level at this branch (managed by branch manager)';
COMMENT ON COLUMN branch_inventory.low_stock_threshold IS 'Alert threshold for low stock (configurable by branch manager)';
COMMENT ON COLUMN branch_inventory.expiry_date IS 'Product expiry date at this branch (managed by branch manager)';
COMMENT ON COLUMN branch_inventory.expiry_alert_days IS 'Days before expiry to trigger alert (configurable by branch manager)';

-- ============================================
-- STEP 2: Migrate existing data
-- ============================================

-- First, create a temporary mapping table to track product merging
CREATE TEMP TABLE product_migration_map (
    old_product_id UUID,
    new_product_id UUID,
    branch_id UUID,
    stock_quantity INTEGER,
    low_stock_threshold INTEGER,
    expiry_date DATE,
    expiry_alert_days INTEGER
);

-- Find duplicate products across branches (same SKU/name for same tenant)
-- and decide which product to keep as the "master" tenant product
INSERT INTO product_migration_map (old_product_id, new_product_id, branch_id, stock_quantity, low_stock_threshold, expiry_date, expiry_alert_days)
SELECT
    p.id as old_product_id,
    COALESCE(
        -- If there's a product with same SKU/name in same tenant, use first one
        (SELECT id FROM products p2
         WHERE p2.tenant_id = p.tenant_id
         AND (
            (p2.sku IS NOT NULL AND p2.sku = p.sku) OR
            (p2.sku IS NULL AND p2.name = p.name AND p2.category = p.category)
         )
         ORDER BY p2.created_at ASC
         LIMIT 1),
        p.id
    ) as new_product_id,
    p.branch_id,
    p.stock_quantity,
    p.low_stock_threshold,
    p.expiry_date,
    p.expiry_alert_days
FROM products p
WHERE p.branch_id IS NOT NULL;

-- Create branch_inventory records from existing products
INSERT INTO branch_inventory (
    tenant_id,
    branch_id,
    product_id,
    stock_quantity,
    low_stock_threshold,
    expiry_date,
    expiry_alert_days,
    is_active,
    created_at,
    updated_at,
    _sync_version,
    _sync_modified_at,
    _sync_client_id,
    _sync_is_deleted
)
SELECT DISTINCT
    p.tenant_id,
    pmm.branch_id,
    pmm.new_product_id,
    pmm.stock_quantity,
    pmm.low_stock_threshold,
    pmm.expiry_date,
    pmm.expiry_alert_days,
    p.is_active,
    p.created_at,
    p.updated_at,
    p._sync_version,
    p._sync_modified_at,
    p._sync_client_id,
    p._sync_is_deleted
FROM product_migration_map pmm
JOIN products p ON p.id = pmm.old_product_id
ON CONFLICT (branch_id, product_id) DO UPDATE SET
    stock_quantity = EXCLUDED.stock_quantity + branch_inventory.stock_quantity,
    updated_at = NOW();

-- Update inventory_transactions to reference branch_inventory
-- Add branch_inventory_id if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'inventory_transactions' AND column_name = 'branch_inventory_id'
    ) THEN
        ALTER TABLE inventory_transactions
        ADD COLUMN branch_inventory_id UUID REFERENCES branch_inventory(id) ON DELETE CASCADE;

        -- Populate branch_inventory_id
        UPDATE inventory_transactions it
        SET branch_inventory_id = bi.id
        FROM branch_inventory bi
        WHERE bi.branch_id = it.branch_id
        AND bi.product_id = it.product_id;

        -- Create index
        CREATE INDEX idx_inventory_transactions_branch_inventory
        ON inventory_transactions(branch_inventory_id);
    END IF;
END $$;

-- Update sale_items to reference the correct merged product
UPDATE sale_items si
SET product_id = pmm.new_product_id
FROM product_migration_map pmm
WHERE si.product_id = pmm.old_product_id
AND pmm.old_product_id != pmm.new_product_id;

-- Update transfer_items to reference the correct merged product
UPDATE transfer_items ti
SET product_id = pmm.new_product_id
FROM product_migration_map pmm
WHERE ti.product_id = pmm.old_product_id
AND pmm.old_product_id != pmm.new_product_id;

-- Update order_items if it exists
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'order_items') THEN
        UPDATE order_items oi
        SET product_id = pmm.new_product_id
        FROM product_migration_map pmm
        WHERE oi.product_id = pmm.old_product_id
        AND pmm.old_product_id != pmm.new_product_id;
    END IF;
END $$;

-- ============================================
-- STEP 3: Clean up duplicate products
-- ============================================

-- Delete duplicate products (keep only the master tenant product)
DELETE FROM products p
WHERE EXISTS (
    SELECT 1 FROM product_migration_map pmm
    WHERE pmm.old_product_id = p.id
    AND pmm.old_product_id != pmm.new_product_id
);

-- ============================================
-- STEP 4: Drop dependent views
-- ============================================

-- Drop ecommerce_products view that depends on products.branch_id
DROP VIEW IF EXISTS ecommerce_products CASCADE;

-- Drop all variations of get_ecommerce_products function
-- Note: There may be multiple overloaded versions with different signatures
-- 1. Original function with 7 parameters (from 024_ecommerce_enhancements.sql):
--    get_ecommerce_products(tenant_id, category, branch_id, latitude, longitude, max_distance_km, in_stock_only)
-- 2. New function with 5 parameters (from this migration):
--    get_ecommerce_products(tenant_id, category, search, min_price, max_price)

-- Use dynamic SQL to drop all variations to avoid "function name is not unique" error
DO $$
DECLARE
    func_record RECORD;
BEGIN
    FOR func_record IN
        SELECT oid::regprocedure::text as func_signature
        FROM pg_proc
        WHERE proname = 'get_ecommerce_products'
    LOOP
        EXECUTE 'DROP FUNCTION IF EXISTS ' || func_record.func_signature || ' CASCADE';
        RAISE NOTICE 'Dropped function: %', func_record.func_signature;
    END LOOP;
END $$;

-- ============================================
-- STEP 5: Drop indexes that depend on columns being removed
-- ============================================

-- Drop indexes that reference branch_id, stock_quantity, expiry_date, or low_stock_threshold
DROP INDEX IF EXISTS idx_products_tenant_branch CASCADE;
DROP INDEX IF EXISTS idx_products_low_stock CASCADE;
DROP INDEX IF EXISTS idx_products_expiry CASCADE;

-- ============================================
-- STEP 5.1: Remove branch_id from products table
-- ============================================

-- Drop the branch_id column and related constraints
ALTER TABLE products DROP COLUMN IF EXISTS branch_id;
ALTER TABLE products DROP COLUMN IF EXISTS stock_quantity;
ALTER TABLE products DROP COLUMN IF EXISTS low_stock_threshold;
ALTER TABLE products DROP COLUMN IF EXISTS expiry_date;
ALTER TABLE products DROP COLUMN IF EXISTS expiry_alert_days;

COMMENT ON TABLE products IS 'Tenant-scoped product catalog. Stock levels tracked in branch_inventory.';

-- ============================================
-- STEP 6: Update RLS policies for products
-- ============================================

-- Drop old policies
DROP POLICY IF EXISTS "Users can view products in their branch" ON products;
DROP POLICY IF EXISTS "Staff can view products" ON products;

-- Create new tenant-scoped policies
DROP POLICY IF EXISTS "Users can view products in their tenant" ON products;
CREATE POLICY "Users can view products in their tenant"
    ON products FOR SELECT
    USING (tenant_id IN (SELECT tenant_id FROM users WHERE id = auth.uid()));

DROP POLICY IF EXISTS "Managers can manage products" ON products;
CREATE POLICY "Managers can manage products"
    ON products FOR ALL
    USING (
        tenant_id IN (
            SELECT tenant_id FROM users
            WHERE id = auth.uid()
            AND role IN ('tenant_admin', 'branch_manager')
        )
    );

-- ============================================
-- STEP 7: Create helper views
-- ============================================

-- View to join products with branch inventory
CREATE OR REPLACE VIEW v_branch_products AS
SELECT
    p.*,
    bi.branch_id,
    bi.stock_quantity,
    bi.low_stock_threshold,
    bi.expiry_date,
    bi.expiry_alert_days,
    bi.is_active as inventory_active,
    
    -- Healthcare & Laboratory expansions
    p.unit_of_measure,
    p.product_type,
    p.generic_name,
    p.strength,
    p.dosage_form,
    p.manufacturer,
    p.test_name,
    p.sample_type,

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

COMMENT ON VIEW v_branch_products IS 'Convenient view joining products with branch inventory';

-- Recreate ecommerce_products view with new schema
CREATE OR REPLACE VIEW ecommerce_products AS
SELECT
    p.id,
    p.tenant_id,
    p.name,
    p.description,
    p.category,
    p.unit_price,
    p.image_url,
    p.is_active,

    -- Aggregate stock across all branches
    COALESCE(SUM(bi.stock_quantity), 0) as total_stock,

    -- Count how many branches have this product
    COUNT(DISTINCT bi.branch_id) as branch_count,

    -- Collect branch information
    COALESCE(
        jsonb_agg(
            jsonb_build_object(
                'branch_id', b.id,
                'branch_name', b.name,
                'branch_address', b.address,
                'branch_phone', b.phone,
                'latitude', b.latitude,
                'longitude', b.longitude,
                'stock_quantity', bi.stock_quantity,
                'in_stock', bi.stock_quantity > 0
            ) ORDER BY b.name
        ) FILTER (WHERE bi.id IS NOT NULL),
        '[]'::jsonb
    ) as branches,

    -- Min and max price (using product price)
    p.unit_price as min_price,
    p.unit_price as max_price,

    p.created_at,
    p.updated_at,
    
    -- Healthcare & Laboratory expansions
    p.unit_of_measure,
    p.product_type,
    p.generic_name,
    p.strength,
    p.dosage_form,
    p.manufacturer,
    p.test_name,
    p.sample_type
FROM products p
LEFT JOIN branch_inventory bi ON bi.product_id = p.id AND bi.is_active = true
LEFT JOIN branches b ON bi.branch_id = b.id AND b.deleted_at IS NULL
WHERE p._sync_is_deleted = false
  AND p.is_active = TRUE
GROUP BY
    p.id,
    p.tenant_id,
    p.name,
    p.description,
    p.category,
    p.unit_price,
    p.image_url,
    p.is_active,
    p.created_at,
    p.updated_at,
    
    -- Essential group by fields
    p.unit_of_measure,
    p.product_type,
    p.generic_name,
    p.strength,
    p.dosage_form,
    p.manufacturer,
    p.test_name,
    p.sample_type;

COMMENT ON VIEW ecommerce_products IS
'Aggregated product view for e-commerce storefront. Shows tenant products across all branches with stock and location information.';

-- Recreate get_ecommerce_products function
CREATE OR REPLACE FUNCTION get_ecommerce_products(
    p_tenant_id UUID,
    p_category VARCHAR DEFAULT NULL,
    p_search VARCHAR DEFAULT NULL,
    p_min_price DECIMAL DEFAULT NULL,
    p_max_price DECIMAL DEFAULT NULL
)
RETURNS TABLE (
    id UUID,
    tenant_id UUID,
    name VARCHAR,
    description TEXT,
    category VARCHAR,
    unit_price DECIMAL,
    image_url TEXT,
    is_active BOOLEAN,
    total_stock BIGINT,
    branch_count BIGINT,
    branches JSONB,
    min_price DECIMAL,
    max_price DECIMAL,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        ep.id,
        ep.tenant_id,
        ep.name,
        ep.description,
        ep.category,
        ep.unit_price,
        ep.image_url,
        ep.is_active,
        ep.total_stock,
        ep.branch_count,
        ep.branches,
        ep.min_price,
        ep.max_price,
        ep.created_at,
        ep.updated_at
    FROM ecommerce_products ep
    WHERE ep.tenant_id = p_tenant_id
      AND ep.is_active = TRUE
      AND (p_category IS NULL OR ep.category = p_category)
      AND (p_search IS NULL OR ep.name ILIKE '%' || p_search || '%' OR ep.description ILIKE '%' || p_search || '%')
      AND (p_min_price IS NULL OR ep.unit_price >= p_min_price)
      AND (p_max_price IS NULL OR ep.unit_price <= p_max_price)
    ORDER BY ep.name;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_ecommerce_products IS 'Get products for e-commerce storefront with optional filters';

-- ============================================
-- STEP 8: Update inventory transaction trigger
-- ============================================

-- Create/update trigger to maintain branch_inventory stock levels
CREATE OR REPLACE FUNCTION update_branch_inventory_stock()
RETURNS TRIGGER AS $$
BEGIN
    -- Update the branch inventory stock quantity
    UPDATE branch_inventory
    SET stock_quantity = NEW.new_quantity,
        updated_at = NOW()
    WHERE branch_id = NEW.branch_id
    AND product_id = NEW.product_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_update_branch_inventory_stock ON inventory_transactions;
CREATE TRIGGER trg_update_branch_inventory_stock
    AFTER INSERT ON inventory_transactions
    FOR EACH ROW
    EXECUTE FUNCTION update_branch_inventory_stock();

COMMENT ON FUNCTION update_branch_inventory_stock() IS 'Updates branch inventory stock after inventory transaction';

-- ============================================
-- STEP 9: Add product image URL to products (if not exists)
-- ============================================

-- Ensure image_url exists (will be removed from UI but kept in schema for future use)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'products' AND column_name = 'image_url'
    ) THEN
        ALTER TABLE products ADD COLUMN image_url TEXT;
        COMMENT ON COLUMN products.image_url IS 'Product image URL (not displayed in POS for performance)';
    END IF;
END $$;
