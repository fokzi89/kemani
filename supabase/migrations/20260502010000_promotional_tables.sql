-- ============================================
-- Migration: Promotional Product Tables
-- Description: Creates featured_products and sale_products tables
--              to replace boolean flags for curated lists.
-- Created: 2026-05-02
-- ============================================

CREATE TABLE IF NOT EXISTS featured_products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    inventory_id UUID REFERENCES branch_inventory(id) ON DELETE CASCADE,
    display_order INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(tenant_id, product_id)
);

CREATE TABLE IF NOT EXISTS sale_products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    inventory_id UUID REFERENCES branch_inventory(id) ON DELETE CASCADE,
    sale_price DECIMAL(15, 2),
    discount_percentage DECIMAL(5, 2),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(tenant_id, product_id)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_featured_tenant ON featured_products(tenant_id);
CREATE INDEX IF NOT EXISTS idx_sale_tenant ON sale_products(tenant_id);

-- RLS Policies
ALTER TABLE featured_products ENABLE ROW LEVEL SECURITY;
ALTER TABLE sale_products ENABLE ROW LEVEL SECURITY;

-- Featured Products Policies
DROP POLICY IF EXISTS "Anyone can view featured products" ON featured_products;
CREATE POLICY "Anyone can view featured products" ON featured_products
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "Tenants can manage featured products" ON featured_products;
CREATE POLICY "Tenants can manage featured products" ON featured_products
    FOR ALL USING (tenant_id = (SELECT tenant_id FROM users WHERE id = auth.uid()));

-- Sale Products Policies
DROP POLICY IF EXISTS "Anyone can view sale products" ON sale_products;
CREATE POLICY "Anyone can view sale products" ON sale_products
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "Tenants can manage sale products" ON sale_products;
CREATE POLICY "Tenants can manage sale products" ON sale_products
    FOR ALL USING (tenant_id = (SELECT tenant_id FROM users WHERE id = auth.uid()));

-- Migrate data from branch_inventory flags (one-way)
INSERT INTO featured_products (tenant_id, product_id, inventory_id)
SELECT DISTINCT ON (tenant_id, product_id) tenant_id, product_id, id
FROM branch_inventory
WHERE is_featured = true
ON CONFLICT DO NOTHING;

INSERT INTO sale_products (tenant_id, product_id, inventory_id, sale_price)
SELECT DISTINCT ON (tenant_id, product_id) tenant_id, product_id, id, sale_price
FROM branch_inventory
WHERE is_on_sale = true
ON CONFLICT DO NOTHING;

-- Note: We keep the columns on branch_inventory for now to avoid breaking existing code
-- but we update the view to prioritize the new tables.

CREATE OR REPLACE VIEW ecommerce_products AS
SELECT
    p.id,
    bi.tenant_id,
    p.name,
    p.description,
    p.category,
    bi.selling_price,
    COALESCE(sp.sale_price, bi.sale_price) as sale_price,
    p.image_url,
    p.is_active,

    -- Aggregate stock across all branches for this tenant
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
                'in_stock', bi.stock_quantity > 0,
                'is_on_sale', EXISTS (SELECT 1 FROM sale_products sp2 WHERE sp2.product_id = p.id AND sp2.tenant_id = bi.tenant_id),
                'is_featured', EXISTS (SELECT 1 FROM featured_products fp2 WHERE fp2.product_id = p.id AND fp2.tenant_id = bi.tenant_id),
                'is_new_arrival', bi.is_new_arrival,
                'selling_price', bi.selling_price,
                'sale_price', COALESCE(sp.sale_price, bi.sale_price)
            ) ORDER BY b.name
        ) FILTER (WHERE bi.id IS NOT NULL),
        '[]'::jsonb
    ) as branches,

    -- Flags
    EXISTS (SELECT 1 FROM sale_products sp2 WHERE sp2.product_id = p.id AND sp2.tenant_id = bi.tenant_id) as is_on_sale,
    EXISTS (SELECT 1 FROM featured_products fp2 WHERE fp2.product_id = p.id AND fp2.tenant_id = bi.tenant_id) as is_featured,
    bool_or(bi.is_new_arrival) as is_new_arrival,

    -- Min and max price (using branch-specific selling_price)
    MIN(bi.selling_price) as min_price,
    MAX(bi.selling_price) as max_price,

    p.created_at,
    p.updated_at,
    
    -- Healthcare & Laboratory expansions
    p.unit_of_measure,
    p.product_type,
    p.generic_name,
    p.strength,
    p.dosage_form,
    p.manufacturer
FROM products p
JOIN branch_inventory bi ON bi.product_id = p.id AND bi.is_active = true
LEFT JOIN branches b ON bi.branch_id = b.id AND b.deleted_at IS NULL
LEFT JOIN sale_products sp ON sp.product_id = p.id AND sp.tenant_id = bi.tenant_id
WHERE p._sync_is_deleted = false
  AND p.is_active = TRUE
GROUP BY
    p.id,
    bi.tenant_id,
    p.name,
    p.description,
    p.category,
    bi.selling_price,
    bi.sale_price,
    sp.sale_price,
    p.image_url,
    p.is_active,
    p.created_at,
    p.updated_at,
    p.unit_of_measure,
    p.product_type,
    p.generic_name,
    p.strength,
    p.dosage_form,
    p.manufacturer;
