-- ============================================
-- Migration: Create Brands and Categories Tables
-- Description: Add brands and categories for product classification
-- Created: 2026-01-23
-- ============================================

-- ============================================
-- BRANDS TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS brands (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,

    name VARCHAR(255) NOT NULL,
    code VARCHAR(50),
    description TEXT,
    logo_url TEXT,

    -- Brand classification
    tier VARCHAR(20), -- premium, mid-range, budget
    is_house_brand BOOLEAN DEFAULT false,

    -- Metadata
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(tenant_id, name)
);

-- Indexes for brands
CREATE INDEX IF NOT EXISTS idx_brands_tenant ON brands(tenant_id) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_brands_active ON brands(is_active, tenant_id);
CREATE INDEX IF NOT EXISTS idx_brands_name ON brands(tenant_id, name);

-- RLS for brands
ALTER TABLE brands ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view brands in their tenant" ON brands;
CREATE POLICY "Users can view brands in their tenant"
    ON brands FOR SELECT
    USING (tenant_id IN (SELECT tenant_id FROM users WHERE id = auth.uid()));

DROP POLICY IF EXISTS "Managers can insert brands" ON brands;
CREATE POLICY "Managers can insert brands"
    ON brands FOR INSERT
    WITH CHECK (
        tenant_id IN (
            SELECT tenant_id FROM users
            WHERE id = auth.uid()
            AND role IN ('tenant_admin', 'branch_manager')
        )
    );

DROP POLICY IF EXISTS "Managers can update brands" ON brands;
CREATE POLICY "Managers can update brands"
    ON brands FOR UPDATE
    USING (
        tenant_id IN (
            SELECT tenant_id FROM users
            WHERE id = auth.uid()
            AND role IN ('tenant_admin', 'branch_manager')
        )
    );

DROP POLICY IF EXISTS "Managers can delete brands" ON brands;
CREATE POLICY "Managers can delete brands"
    ON brands FOR DELETE
    USING (
        tenant_id IN (
            SELECT tenant_id FROM users
            WHERE id = auth.uid()
            AND role IN ('tenant_admin', 'branch_manager')
        )
    );

-- Trigger to update updated_at
DROP TRIGGER IF EXISTS set_updated_at ON brands;
CREATE TRIGGER set_updated_at
    BEFORE UPDATE ON brands
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();

COMMENT ON TABLE brands IS 'Product brands for brand comparison analytics';
COMMENT ON COLUMN brands.tier IS 'Brand tier: premium, mid-range, budget';
COMMENT ON COLUMN brands.is_house_brand IS 'True if this is the store''s own brand';

-- ============================================
-- CATEGORIES TABLE (Hierarchical)
-- ============================================

CREATE TABLE IF NOT EXISTS categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,

    name VARCHAR(255) NOT NULL,
    code VARCHAR(50),
    parent_category_id UUID REFERENCES categories(id) ON DELETE SET NULL,

    -- Category hierarchy
    level INTEGER DEFAULT 1, -- 1=main, 2=sub, 3=sub-sub
    path TEXT, -- Materialized path: /Electronics/Phones/Smartphones/

    description TEXT,
    sort_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(tenant_id, name, parent_category_id)
);

-- Indexes for categories
CREATE INDEX IF NOT EXISTS idx_categories_tenant ON categories(tenant_id) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_categories_parent ON categories(parent_category_id) WHERE parent_category_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_categories_level ON categories(tenant_id, level);
CREATE INDEX IF NOT EXISTS idx_categories_active ON categories(is_active, tenant_id);

-- RLS for categories
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view categories in their tenant" ON categories;
CREATE POLICY "Users can view categories in their tenant"
    ON categories FOR SELECT
    USING (tenant_id IN (SELECT tenant_id FROM users WHERE id = auth.uid()));

DROP POLICY IF EXISTS "Managers can manage categories" ON categories;
CREATE POLICY "Managers can manage categories"
    ON categories FOR ALL
    USING (
        tenant_id IN (
            SELECT tenant_id FROM users
            WHERE id = auth.uid()
            AND role IN ('tenant_admin', 'branch_manager')
        )
    );

-- Trigger to update updated_at
DROP TRIGGER IF EXISTS set_updated_at ON categories;
CREATE TRIGGER set_updated_at
    BEFORE UPDATE ON categories
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();

-- Trigger to auto-populate category path
CREATE OR REPLACE FUNCTION update_category_path()
RETURNS TRIGGER AS $$
DECLARE
    v_parent_path TEXT;
BEGIN
    IF NEW.parent_category_id IS NULL THEN
        NEW.path := '/' || NEW.name || '/';
        NEW.level := 1;
    ELSE
        SELECT path, level INTO v_parent_path, NEW.level
        FROM categories
        WHERE id = NEW.parent_category_id;

        NEW.path := v_parent_path || NEW.name || '/';
        NEW.level := NEW.level + 1;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_update_category_path ON categories;
CREATE TRIGGER trg_update_category_path
    BEFORE INSERT OR UPDATE ON categories
    FOR EACH ROW
    EXECUTE FUNCTION update_category_path();

COMMENT ON TABLE categories IS 'Hierarchical product categories';
COMMENT ON COLUMN categories.level IS 'Hierarchy level: 1=main, 2=sub, 3=sub-sub';
COMMENT ON COLUMN categories.path IS 'Materialized path for efficient hierarchy queries';

-- ============================================
-- ENHANCE PRODUCTS TABLE
-- ============================================

-- Add brand_id and category_id to products if not exists
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'products' AND column_name = 'brand_id'
    ) THEN
        ALTER TABLE products ADD COLUMN brand_id UUID REFERENCES brands(id) ON DELETE SET NULL;
        COMMENT ON COLUMN products.brand_id IS 'Brand classification for analytics';

        -- Create index
        CREATE INDEX idx_products_brand ON products(brand_id) WHERE brand_id IS NOT NULL;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'products' AND column_name = 'category_id'
    ) THEN
        ALTER TABLE products ADD COLUMN category_id UUID REFERENCES categories(id) ON DELETE SET NULL;
        COMMENT ON COLUMN products.category_id IS 'Category classification for analytics';

        -- Create index
        CREATE INDEX idx_products_category ON products(category_id) WHERE category_id IS NOT NULL;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'products' AND column_name = 'cost_price'
    ) THEN
        ALTER TABLE products ADD COLUMN cost_price DECIMAL(15,2);
        COMMENT ON COLUMN products.cost_price IS 'Cost of goods sold (for profit calculation)';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'products' AND column_name = 'unit_of_measure'
    ) THEN
        ALTER TABLE products ADD COLUMN unit_of_measure VARCHAR(20) DEFAULT 'piece';
        COMMENT ON COLUMN products.unit_of_measure IS 'Unit of measure: piece, kg, liter, meter, etc.';
    END IF;
END $$;

-- ============================================
-- PRODUCT PRICE HISTORY (SCD Type 2)
-- ============================================

CREATE TABLE IF NOT EXISTS product_price_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,

    cost_price DECIMAL(15,2),
    selling_price DECIMAL(15,2) NOT NULL,

    -- Price change tracking
    price_change_reason VARCHAR(100),
    changed_by UUID REFERENCES users(id) ON DELETE SET NULL,

    -- Validity period (SCD Type 2)
    valid_from TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    valid_to TIMESTAMPTZ,
    is_current BOOLEAN DEFAULT true,

    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for price history
CREATE INDEX IF NOT EXISTS idx_price_history_product ON product_price_history(product_id, valid_from DESC);
CREATE INDEX IF NOT EXISTS idx_price_history_current ON product_price_history(product_id, is_current) WHERE is_current = true;
CREATE INDEX IF NOT EXISTS idx_price_history_tenant ON product_price_history(tenant_id, created_at DESC);

-- RLS for price history
ALTER TABLE product_price_history ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view price history in their tenant" ON product_price_history;
CREATE POLICY "Users can view price history in their tenant"
    ON product_price_history FOR SELECT
    USING (tenant_id IN (SELECT tenant_id FROM users WHERE id = auth.uid()));

DROP POLICY IF EXISTS "Managers can manage price history" ON product_price_history;
CREATE POLICY "Managers can manage price history"
    ON product_price_history FOR ALL
    USING (
        tenant_id IN (
            SELECT tenant_id FROM users
            WHERE id = auth.uid()
            AND role IN ('tenant_admin', 'branch_manager')
        )
    );

-- Trigger to track price changes
CREATE OR REPLACE FUNCTION track_product_price_change()
RETURNS TRIGGER AS $$
BEGIN
    -- If price changed, archive old price and create new history entry
    IF (OLD.selling_price IS DISTINCT FROM NEW.selling_price) OR
       (OLD.cost_price IS DISTINCT FROM NEW.cost_price) THEN

        -- Mark old price as no longer current
        UPDATE product_price_history
        SET is_current = false,
            valid_to = NOW()
        WHERE product_id = NEW.id
          AND is_current = true;

        -- Insert new price history
        INSERT INTO product_price_history (
            product_id,
            tenant_id,
            cost_price,
            selling_price,
            price_change_reason,
            changed_by,
            valid_from,
            is_current
        ) VALUES (
            NEW.id,
            NEW.tenant_id,
            NEW.cost_price,
            NEW.selling_price,
            'price_update',
            auth.uid(),
            NOW(),
            true
        );
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_track_product_price_change ON products;
CREATE TRIGGER trg_track_product_price_change
    AFTER UPDATE ON products
    FOR EACH ROW
    EXECUTE FUNCTION track_product_price_change();

COMMENT ON TABLE product_price_history IS 'Tracks product price changes over time (SCD Type 2)';
COMMENT ON COLUMN product_price_history.is_current IS 'True if this is the current active price';
