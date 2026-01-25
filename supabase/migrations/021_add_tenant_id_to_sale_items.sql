-- ============================================
-- Migration 015a: Add tenant_id to sale_items
-- Description: Quick fix to add missing tenant_id column
-- Run this BEFORE migration 020 if you've already run 015
-- ============================================

-- Add tenant_id column for RLS (critical for multi-tenant isolation)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'sale_items' AND column_name = 'tenant_id'
    ) THEN
        -- Add column as nullable first
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
        CREATE INDEX IF NOT EXISTS idx_sale_items_tenant ON sale_items(tenant_id);

        RAISE NOTICE 'Added tenant_id column to sale_items table';
    ELSE
        RAISE NOTICE 'tenant_id column already exists on sale_items table';
    END IF;
END $$;

-- Update trigger to auto-populate tenant_id
CREATE OR REPLACE FUNCTION populate_sale_item_details()
RETURNS TRIGGER AS $$
DECLARE
    v_product RECORD;
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

        -- Calculate cost and profit
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
