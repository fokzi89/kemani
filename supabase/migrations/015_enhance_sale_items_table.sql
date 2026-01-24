-- ============================================
-- Migration: Enhance Sale Items Table for Analytics
-- Description: Add analytics columns to existing sale_items table
-- Created: 2026-01-23
-- ============================================

-- Add tenant_id column for RLS (critical for multi-tenant isolation)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'sale_items' AND column_name = 'tenant_id'
    ) THEN
        ALTER TABLE sale_items ADD COLUMN tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE;
        COMMENT ON COLUMN sale_items.tenant_id IS 'Tenant ID for multi-tenant RLS isolation';

        -- Populate tenant_id from sales table for existing records
        UPDATE sale_items si
        SET tenant_id = s.tenant_id
        FROM sales s
        WHERE si.sale_id = s.id
        AND si.tenant_id IS NULL;

        -- Make tenant_id NOT NULL after populating
        ALTER TABLE sale_items ALTER COLUMN tenant_id SET NOT NULL;

        -- Create index for RLS queries
        CREATE INDEX idx_sale_items_tenant ON sale_items(tenant_id);
    END IF;
END $$;

-- Add product snapshot columns
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'sale_items' AND column_name = 'product_name'
    ) THEN
        ALTER TABLE sale_items ADD COLUMN product_name VARCHAR(255);
        COMMENT ON COLUMN sale_items.product_name IS 'Product name snapshot at time of sale';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'sale_items' AND column_name = 'product_sku'
    ) THEN
        ALTER TABLE sale_items ADD COLUMN product_sku VARCHAR(100);
        COMMENT ON COLUMN sale_items.product_sku IS 'Product SKU snapshot at time of sale';
    END IF;
END $$;

-- Add brand tracking columns
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'sale_items' AND column_name = 'brand_id'
    ) THEN
        ALTER TABLE sale_items ADD COLUMN brand_id UUID REFERENCES brands(id) ON DELETE SET NULL;
        COMMENT ON COLUMN sale_items.brand_id IS 'Brand ID for brand comparison analytics';

        -- Create index for brand queries
        CREATE INDEX idx_sale_items_brand ON sale_items(brand_id, created_at DESC) WHERE brand_id IS NOT NULL;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'sale_items' AND column_name = 'brand_name'
    ) THEN
        ALTER TABLE sale_items ADD COLUMN brand_name VARCHAR(255);
        COMMENT ON COLUMN sale_items.brand_name IS 'Brand name snapshot at time of sale';
    END IF;
END $$;

-- Add category tracking columns
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'sale_items' AND column_name = 'category_id'
    ) THEN
        ALTER TABLE sale_items ADD COLUMN category_id UUID REFERENCES categories(id) ON DELETE SET NULL;
        COMMENT ON COLUMN sale_items.category_id IS 'Category ID for category analytics';

        -- Create index for category queries
        CREATE INDEX idx_sale_items_category ON sale_items(category_id, created_at DESC) WHERE category_id IS NOT NULL;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'sale_items' AND column_name = 'category_name'
    ) THEN
        ALTER TABLE sale_items ADD COLUMN category_name VARCHAR(255);
        COMMENT ON COLUMN sale_items.category_name IS 'Category name snapshot at time of sale';
    END IF;
END $$;

-- Add unit of measure
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'sale_items' AND column_name = 'unit_of_measure'
    ) THEN
        ALTER TABLE sale_items ADD COLUMN unit_of_measure VARCHAR(20) DEFAULT 'piece';
        COMMENT ON COLUMN sale_items.unit_of_measure IS 'Unit of measure: piece, kg, liter, meter, etc.';
    END IF;
END $$;

-- Add pricing detail columns
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'sale_items' AND column_name = 'original_price'
    ) THEN
        ALTER TABLE sale_items ADD COLUMN original_price DECIMAL(15,2);
        COMMENT ON COLUMN sale_items.original_price IS 'Original price before discount';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'sale_items' AND column_name = 'discount_percentage'
    ) THEN
        ALTER TABLE sale_items ADD COLUMN discount_percentage DECIMAL(5,2) DEFAULT 0;
        COMMENT ON COLUMN sale_items.discount_percentage IS 'Discount percentage applied';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'sale_items' AND column_name = 'discount_amount'
    ) THEN
        ALTER TABLE sale_items ADD COLUMN discount_amount DECIMAL(15,2) DEFAULT 0;
        COMMENT ON COLUMN sale_items.discount_amount IS 'Discount amount in currency';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'sale_items' AND column_name = 'tax_percentage'
    ) THEN
        ALTER TABLE sale_items ADD COLUMN tax_percentage DECIMAL(5,2) DEFAULT 0;
        COMMENT ON COLUMN sale_items.tax_percentage IS 'Tax percentage applied';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'sale_items' AND column_name = 'tax_amount'
    ) THEN
        ALTER TABLE sale_items ADD COLUMN tax_amount DECIMAL(15,2) DEFAULT 0;
        COMMENT ON COLUMN sale_items.tax_amount IS 'Tax amount in currency';
    END IF;
END $$;

-- Add cost and profit tracking columns
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'sale_items' AND column_name = 'unit_cost'
    ) THEN
        ALTER TABLE sale_items ADD COLUMN unit_cost DECIMAL(15,2);
        COMMENT ON COLUMN sale_items.unit_cost IS 'Cost of goods sold per unit';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'sale_items' AND column_name = 'total_cost'
    ) THEN
        ALTER TABLE sale_items ADD COLUMN total_cost DECIMAL(15,2);
        COMMENT ON COLUMN sale_items.total_cost IS 'Total cost (unit_cost * quantity)';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'sale_items' AND column_name = 'gross_profit'
    ) THEN
        ALTER TABLE sale_items ADD COLUMN gross_profit DECIMAL(15,2);
        COMMENT ON COLUMN sale_items.gross_profit IS 'Gross profit (line_total - total_cost)';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'sale_items' AND column_name = 'profit_margin'
    ) THEN
        ALTER TABLE sale_items ADD COLUMN profit_margin DECIMAL(5,2);
        COMMENT ON COLUMN sale_items.profit_margin IS 'Profit margin percentage';
    END IF;
END $$;

-- Add discount tracking columns
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'sale_items' AND column_name = 'discount_type'
    ) THEN
        ALTER TABLE sale_items ADD COLUMN discount_type VARCHAR(50);
        COMMENT ON COLUMN sale_items.discount_type IS 'Discount type: percentage, fixed_amount, promo_code, loyalty_points, bulk_discount';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'sale_items' AND column_name = 'discount_code'
    ) THEN
        ALTER TABLE sale_items ADD COLUMN discount_code VARCHAR(50);
        COMMENT ON COLUMN sale_items.discount_code IS 'Promo/discount code applied';
    END IF;
END $$;

-- Create/update trigger to auto-populate sale item details
CREATE OR REPLACE FUNCTION populate_sale_item_details()
RETURNS TRIGGER AS $$
DECLARE
    v_product RECORD;
    v_sale RECORD;
BEGIN
    -- Get tenant_id from sales table if not set
    IF NEW.tenant_id IS NULL THEN
        SELECT tenant_id INTO NEW.tenant_id
        FROM sales
        WHERE id = NEW.sale_id;
    END IF;

    -- Get product details if not already set
    IF NEW.product_name IS NULL OR NEW.product_sku IS NULL THEN
        SELECT
            p.name,
            p.sku,
            p.brand_id,
            b.name as brand_name,
            p.category_id,
            c.name as category_name,
            p.cost_price,
            p.unit_of_measure
        INTO v_product
        FROM products p
        LEFT JOIN brands b ON b.id = p.brand_id
        LEFT JOIN categories c ON c.id = p.category_id
        WHERE p.id = NEW.product_id;

        -- Populate snapshot fields
        NEW.product_name := COALESCE(NEW.product_name, v_product.name);
        NEW.product_sku := COALESCE(NEW.product_sku, v_product.sku);
        NEW.brand_id := COALESCE(NEW.brand_id, v_product.brand_id);
        NEW.brand_name := COALESCE(NEW.brand_name, v_product.brand_name);
        NEW.category_id := COALESCE(NEW.category_id, v_product.category_id);
        NEW.category_name := COALESCE(NEW.category_name, v_product.category_name);
        NEW.unit_of_measure := COALESCE(NEW.unit_of_measure, v_product.unit_of_measure, 'piece');

        -- Calculate cost and profit if unit_cost provided
        IF NEW.unit_cost IS NOT NULL THEN
            NEW.total_cost := NEW.unit_cost * NEW.quantity;
            NEW.gross_profit := NEW.line_total - NEW.total_cost;
            IF NEW.line_total > 0 THEN
                NEW.profit_margin := (NEW.gross_profit / NEW.line_total) * 100;
            END IF;
        ELSIF v_product.cost_price IS NOT NULL THEN
            NEW.unit_cost := v_product.cost_price;
            NEW.total_cost := v_product.cost_price * NEW.quantity;
            NEW.gross_profit := NEW.line_total - NEW.total_cost;
            IF NEW.line_total > 0 THEN
                NEW.profit_margin := (NEW.gross_profit / NEW.line_total) * 100;
            END IF;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop trigger if exists and recreate
DROP TRIGGER IF EXISTS trg_populate_sale_item_details ON sale_items;
CREATE TRIGGER trg_populate_sale_item_details
    BEFORE INSERT OR UPDATE ON sale_items
    FOR EACH ROW
    EXECUTE FUNCTION populate_sale_item_details();

COMMENT ON TRIGGER trg_populate_sale_item_details ON sale_items IS 'Auto-populates product snapshot details and calculates profit';
