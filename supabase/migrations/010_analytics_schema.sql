-- ============================================
-- Migration: Analytics Schema for Sales Reports
-- Description: Comprehensive analytics tables for in-depth sales analysis
-- Created: 2026-01-22
-- ============================================

-- ============================================
-- 1. BRANDS TABLE (Product Brands)
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

-- RLS for brands
ALTER TABLE brands ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view brands in their tenant"
    ON brands FOR SELECT
    USING (tenant_id IN (SELECT tenant_id FROM users WHERE id = auth.uid()));

CREATE POLICY "Managers can insert brands"
    ON brands FOR INSERT
    WITH CHECK (
        tenant_id IN (
            SELECT tenant_id FROM users
            WHERE id = auth.uid()
            AND role IN ('owner', 'admin', 'manager')
        )
    );

CREATE POLICY "Managers can update brands"
    ON brands FOR UPDATE
    USING (
        tenant_id IN (
            SELECT tenant_id FROM users
            WHERE id = auth.uid()
            AND role IN ('owner', 'admin', 'manager')
        )
    );

-- ============================================
-- 2. CATEGORIES TABLE (Hierarchical)
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

-- RLS for categories
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view categories in their tenant"
    ON categories FOR SELECT
    USING (tenant_id IN (SELECT tenant_id FROM users WHERE id = auth.uid()));

CREATE POLICY "Managers can manage categories"
    ON categories FOR ALL
    USING (
        tenant_id IN (
            SELECT tenant_id FROM users
            WHERE id = auth.uid()
            AND role IN ('owner', 'admin', 'manager')
        )
    );

-- ============================================
-- 3. ENHANCE PRODUCTS TABLE
-- ============================================

-- Add brand_id and category_id to products if not exists
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'products' AND column_name = 'brand_id') THEN
        ALTER TABLE products ADD COLUMN brand_id UUID REFERENCES brands(id) ON DELETE SET NULL;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'products' AND column_name = 'category_id') THEN
        ALTER TABLE products ADD COLUMN category_id UUID REFERENCES categories(id) ON DELETE SET NULL;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'products' AND column_name = 'cost_price') THEN
        ALTER TABLE products ADD COLUMN cost_price DECIMAL(15,2);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'products' AND column_name = 'unit_of_measure') THEN
        ALTER TABLE products ADD COLUMN unit_of_measure VARCHAR(20) DEFAULT 'piece';
    END IF;
END $$;

-- ============================================
-- 4. PRODUCT PRICE HISTORY (SCD Type 2)
-- ============================================

CREATE TABLE IF NOT EXISTS product_price_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,

    cost_price DECIMAL(15,2),
    selling_price DECIMAL(15,2) NOT NULL,

    -- Price change tracking
    price_change_reason VARCHAR(100),
    changed_by UUID REFERENCES users(id),

    -- Validity period (SCD Type 2)
    valid_from TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    valid_to TIMESTAMPTZ,
    is_current BOOLEAN DEFAULT true,

    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS for price history
ALTER TABLE product_price_history ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view price history in their tenant"
    ON product_price_history FOR SELECT
    USING (tenant_id IN (SELECT tenant_id FROM users WHERE id = auth.uid()));

-- ============================================
-- 5. ENHANCE SALES TABLE
-- ============================================

-- Add analytics-friendly columns to sales table
DO $$
BEGIN
    -- Add sales attendant tracking (separate from cashier)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'sales' AND column_name = 'sales_attendant_id') THEN
        ALTER TABLE sales ADD COLUMN sales_attendant_id UUID REFERENCES users(id);
    END IF;

    -- Add customer type for segmentation
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'sales' AND column_name = 'customer_type') THEN
        ALTER TABLE sales ADD COLUMN customer_type VARCHAR(20) DEFAULT 'walk-in';
    END IF;

    -- Add channel tracking
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'sales' AND column_name = 'channel') THEN
        ALTER TABLE sales ADD COLUMN channel VARCHAR(20) DEFAULT 'in-store';
    END IF;

    -- Add sale_date for easy queries (denormalized from completed_at)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'sales' AND column_name = 'sale_date') THEN
        ALTER TABLE sales ADD COLUMN sale_date DATE;
        -- Populate existing records
        UPDATE sales SET sale_date = DATE(completed_at) WHERE sale_date IS NULL;
        ALTER TABLE sales ALTER COLUMN sale_date SET NOT NULL;
    END IF;

    -- Add sale_time for hourly analysis
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'sales' AND column_name = 'sale_time') THEN
        ALTER TABLE sales ADD COLUMN sale_time TIME;
        -- Populate existing records
        UPDATE sales SET sale_time = completed_at::TIME WHERE sale_time IS NULL;
        ALTER TABLE sales ALTER COLUMN sale_time SET NOT NULL;
    END IF;

    -- Add void tracking
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'sales' AND column_name = 'void_reason') THEN
        ALTER TABLE sales ADD COLUMN void_reason TEXT;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'sales' AND column_name = 'voided_by') THEN
        ALTER TABLE sales ADD COLUMN voided_by UUID REFERENCES users(id);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'sales' AND column_name = 'voided_at') THEN
        ALTER TABLE sales ADD COLUMN voided_at TIMESTAMPTZ;
    END IF;
END $$;

-- ============================================
-- 6. ENHANCE SALE ITEMS TABLE
-- ============================================

-- Add analytics columns to sale_items
DO $$
BEGIN
    -- Product snapshot fields
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'sale_items' AND column_name = 'product_name') THEN
        ALTER TABLE sale_items ADD COLUMN product_name VARCHAR(255);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'sale_items' AND column_name = 'product_sku') THEN
        ALTER TABLE sale_items ADD COLUMN product_sku VARCHAR(100);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'sale_items' AND column_name = 'brand_id') THEN
        ALTER TABLE sale_items ADD COLUMN brand_id UUID REFERENCES brands(id);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'sale_items' AND column_name = 'brand_name') THEN
        ALTER TABLE sale_items ADD COLUMN brand_name VARCHAR(255);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'sale_items' AND column_name = 'category_id') THEN
        ALTER TABLE sale_items ADD COLUMN category_id UUID REFERENCES categories(id);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'sale_items' AND column_name = 'category_name') THEN
        ALTER TABLE sale_items ADD COLUMN category_name VARCHAR(255);
    END IF;

    -- Unit of measure
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'sale_items' AND column_name = 'unit_of_measure') THEN
        ALTER TABLE sale_items ADD COLUMN unit_of_measure VARCHAR(20) DEFAULT 'piece';
    END IF;

    -- Pricing details
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'sale_items' AND column_name = 'original_price') THEN
        ALTER TABLE sale_items ADD COLUMN original_price DECIMAL(15,2);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'sale_items' AND column_name = 'discount_percentage') THEN
        ALTER TABLE sale_items ADD COLUMN discount_percentage DECIMAL(5,2) DEFAULT 0;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'sale_items' AND column_name = 'discount_amount') THEN
        ALTER TABLE sale_items ADD COLUMN discount_amount DECIMAL(15,2) DEFAULT 0;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'sale_items' AND column_name = 'tax_percentage') THEN
        ALTER TABLE sale_items ADD COLUMN tax_percentage DECIMAL(5,2) DEFAULT 0;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'sale_items' AND column_name = 'tax_amount') THEN
        ALTER TABLE sale_items ADD COLUMN tax_amount DECIMAL(15,2) DEFAULT 0;
    END IF;

    -- Cost and profit tracking
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'sale_items' AND column_name = 'unit_cost') THEN
        ALTER TABLE sale_items ADD COLUMN unit_cost DECIMAL(15,2);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'sale_items' AND column_name = 'total_cost') THEN
        ALTER TABLE sale_items ADD COLUMN total_cost DECIMAL(15,2);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'sale_items' AND column_name = 'gross_profit') THEN
        ALTER TABLE sale_items ADD COLUMN gross_profit DECIMAL(15,2);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'sale_items' AND column_name = 'profit_margin') THEN
        ALTER TABLE sale_items ADD COLUMN profit_margin DECIMAL(5,2);
    END IF;

    -- Discount tracking
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'sale_items' AND column_name = 'discount_type') THEN
        ALTER TABLE sale_items ADD COLUMN discount_type VARCHAR(50);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'sale_items' AND column_name = 'discount_code') THEN
        ALTER TABLE sale_items ADD COLUMN discount_code VARCHAR(50);
    END IF;
END $$;

-- ============================================
-- 7. TIME DIMENSIONS
-- ============================================

-- Date dimension table
CREATE TABLE IF NOT EXISTS dim_date (
    date_key INTEGER PRIMARY KEY,
    date_value DATE NOT NULL UNIQUE,

    -- Date components
    day INTEGER NOT NULL,
    day_of_week INTEGER NOT NULL,
    day_of_week_name VARCHAR(10) NOT NULL,
    day_of_year INTEGER NOT NULL,

    -- Week
    week_of_year INTEGER NOT NULL,
    week_start_date DATE NOT NULL,
    week_end_date DATE NOT NULL,

    -- Month
    month INTEGER NOT NULL,
    month_name VARCHAR(10) NOT NULL,
    month_abbr VARCHAR(3) NOT NULL,
    month_start_date DATE NOT NULL,
    month_end_date DATE NOT NULL,

    -- Quarter
    quarter INTEGER NOT NULL,
    quarter_name VARCHAR(10) NOT NULL,
    quarter_start_date DATE NOT NULL,
    quarter_end_date DATE NOT NULL,

    -- Year
    year INTEGER NOT NULL,
    year_start_date DATE NOT NULL,
    year_end_date DATE NOT NULL,

    -- Fiscal periods
    fiscal_year INTEGER,
    fiscal_quarter INTEGER,
    fiscal_month INTEGER,

    -- Business flags
    is_weekend BOOLEAN NOT NULL,
    is_holiday BOOLEAN DEFAULT false,
    holiday_name VARCHAR(100),
    is_business_day BOOLEAN NOT NULL,

    -- Prior period references
    prior_day_key INTEGER,
    prior_week_key INTEGER,
    prior_month_key INTEGER,
    prior_quarter_key INTEGER,
    prior_year_key INTEGER,

    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Time dimension table
CREATE TABLE IF NOT EXISTS dim_time (
    time_key INTEGER PRIMARY KEY,
    time_value TIME NOT NULL UNIQUE,

    -- Time components
    hour INTEGER NOT NULL,
    hour_12 INTEGER NOT NULL,
    am_pm VARCHAR(2) NOT NULL,
    minute INTEGER NOT NULL,
    second INTEGER NOT NULL,

    -- Time periods
    time_period VARCHAR(20) NOT NULL,
    business_hour VARCHAR(20) NOT NULL,

    -- Analytics groupings
    hour_bucket INTEGER NOT NULL,
    minute_bucket INTEGER NOT NULL,

    is_peak_hour BOOLEAN DEFAULT false,

    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 8. FACT TABLES (Partitioned)
-- ============================================

-- Daily sales summary
CREATE TABLE IF NOT EXISTS fact_daily_sales (
    id UUID DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE CASCADE,

    -- Date dimension
    date_key INTEGER NOT NULL REFERENCES dim_date(date_key),
    sale_date DATE NOT NULL,

    -- Aggregated metrics
    total_transactions INTEGER DEFAULT 0,
    total_items_sold DECIMAL(15,3) DEFAULT 0,
    total_revenue DECIMAL(15,2) DEFAULT 0,
    total_cost DECIMAL(15,2) DEFAULT 0,
    total_profit DECIMAL(15,2) DEFAULT 0,
    average_transaction_value DECIMAL(15,2) DEFAULT 0,
    average_profit_margin DECIMAL(5,2) DEFAULT 0,

    -- Customer metrics
    unique_customers INTEGER DEFAULT 0,
    new_customers INTEGER DEFAULT 0,
    returning_customers INTEGER DEFAULT 0,

    -- Payment method breakdown
    cash_transactions INTEGER DEFAULT 0,
    cash_revenue DECIMAL(15,2) DEFAULT 0,
    card_transactions INTEGER DEFAULT 0,
    card_revenue DECIMAL(15,2) DEFAULT 0,
    transfer_transactions INTEGER DEFAULT 0,
    transfer_revenue DECIMAL(15,2) DEFAULT 0,

    -- Refund metrics
    void_transactions INTEGER DEFAULT 0,
    void_amount DECIMAL(15,2) DEFAULT 0,
    refund_transactions INTEGER DEFAULT 0,
    refund_amount DECIMAL(15,2) DEFAULT 0,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    PRIMARY KEY (tenant_id, branch_id, date_key, sale_date)
) PARTITION BY RANGE (sale_date);

-- Product sales summary
CREATE TABLE IF NOT EXISTS fact_product_sales (
    id UUID DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE CASCADE,

    -- Dimensions
    date_key INTEGER NOT NULL REFERENCES dim_date(date_key),
    sale_date DATE NOT NULL,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    brand_id UUID REFERENCES brands(id),
    category_id UUID REFERENCES categories(id),

    -- Product snapshot
    product_name VARCHAR(255) NOT NULL,
    product_sku VARCHAR(100),
    brand_name VARCHAR(255),
    category_name VARCHAR(255),

    -- Aggregated metrics
    quantity_sold DECIMAL(15,3) DEFAULT 0,
    total_revenue DECIMAL(15,2) DEFAULT 0,
    total_cost DECIMAL(15,2) DEFAULT 0,
    total_profit DECIMAL(15,2) DEFAULT 0,
    average_unit_price DECIMAL(15,2) DEFAULT 0,
    average_profit_margin DECIMAL(5,2) DEFAULT 0,

    -- Transaction metrics
    transaction_count INTEGER DEFAULT 0,

    -- Discount metrics
    total_discount_amount DECIMAL(15,2) DEFAULT 0,
    average_discount_percentage DECIMAL(5,2) DEFAULT 0,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    PRIMARY KEY (tenant_id, branch_id, date_key, product_id, sale_date)
) PARTITION BY RANGE (sale_date);

-- Staff sales performance
CREATE TABLE IF NOT EXISTS fact_staff_sales (
    id UUID DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE CASCADE,

    -- Dimensions
    date_key INTEGER NOT NULL REFERENCES dim_date(date_key),
    sale_date DATE NOT NULL,
    staff_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    staff_role VARCHAR(50),

    -- Staff info snapshot
    staff_name VARCHAR(255) NOT NULL,

    -- Aggregated metrics
    total_transactions INTEGER DEFAULT 0,
    total_items_sold DECIMAL(15,3) DEFAULT 0,
    total_revenue DECIMAL(15,2) DEFAULT 0,
    total_profit DECIMAL(15,2) DEFAULT 0,
    average_transaction_value DECIMAL(15,2) DEFAULT 0,

    -- Performance metrics
    average_transaction_time INTERVAL,
    transactions_per_hour DECIMAL(5,2) DEFAULT 0,

    -- Commission calculation
    commission_eligible_sales DECIMAL(15,2) DEFAULT 0,
    commission_amount DECIMAL(15,2) DEFAULT 0,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    PRIMARY KEY (tenant_id, branch_id, date_key, staff_id, staff_role, sale_date)
) PARTITION BY RANGE (sale_date);

-- Brand performance comparison
CREATE TABLE IF NOT EXISTS fact_brand_sales (
    id UUID DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE CASCADE,

    -- Dimensions
    date_key INTEGER NOT NULL REFERENCES dim_date(date_key),
    sale_date DATE NOT NULL,
    brand_id UUID NOT NULL REFERENCES brands(id) ON DELETE CASCADE,
    category_id UUID REFERENCES categories(id),

    -- Brand snapshot
    brand_name VARCHAR(255) NOT NULL,
    category_name VARCHAR(255),

    -- Aggregated metrics
    unique_products_sold INTEGER DEFAULT 0,
    quantity_sold DECIMAL(15,3) DEFAULT 0,
    total_revenue DECIMAL(15,2) DEFAULT 0,
    total_cost DECIMAL(15,2) DEFAULT 0,
    total_profit DECIMAL(15,2) DEFAULT 0,
    average_profit_margin DECIMAL(5,2) DEFAULT 0,

    -- Transaction metrics
    transaction_count INTEGER DEFAULT 0,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    PRIMARY KEY (tenant_id, branch_id, date_key, brand_id, sale_date)
) PARTITION BY RANGE (sale_date);

-- Hourly sales pattern
CREATE TABLE IF NOT EXISTS fact_hourly_sales (
    id UUID DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE CASCADE,

    -- Dimensions
    date_key INTEGER NOT NULL REFERENCES dim_date(date_key),
    time_key INTEGER NOT NULL REFERENCES dim_time(time_key),
    sale_date DATE NOT NULL,
    hour INTEGER NOT NULL,

    -- Aggregated metrics
    total_transactions INTEGER DEFAULT 0,
    total_revenue DECIMAL(15,2) DEFAULT 0,
    average_transaction_value DECIMAL(15,2) DEFAULT 0,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    PRIMARY KEY (tenant_id, branch_id, date_key, time_key, sale_date)
) PARTITION BY RANGE (sale_date);

-- RLS for fact tables
ALTER TABLE fact_daily_sales ENABLE ROW LEVEL SECURITY;
ALTER TABLE fact_product_sales ENABLE ROW LEVEL SECURITY;
ALTER TABLE fact_staff_sales ENABLE ROW LEVEL SECURITY;
ALTER TABLE fact_brand_sales ENABLE ROW LEVEL SECURITY;
ALTER TABLE fact_hourly_sales ENABLE ROW LEVEL SECURITY;

-- RLS Policies for fact tables
CREATE POLICY "Users can view daily sales in their tenant"
    ON fact_daily_sales FOR SELECT
    USING (tenant_id IN (SELECT tenant_id FROM users WHERE id = auth.uid()));

CREATE POLICY "Users can view product sales in their tenant"
    ON fact_product_sales FOR SELECT
    USING (tenant_id IN (SELECT tenant_id FROM users WHERE id = auth.uid()));

CREATE POLICY "Users can view staff sales in their tenant"
    ON fact_staff_sales FOR SELECT
    USING (tenant_id IN (SELECT tenant_id FROM users WHERE id = auth.uid()));

CREATE POLICY "Users can view brand sales in their tenant"
    ON fact_brand_sales FOR SELECT
    USING (tenant_id IN (SELECT tenant_id FROM users WHERE id = auth.uid()));

CREATE POLICY "Users can view hourly sales in their tenant"
    ON fact_hourly_sales FOR SELECT
    USING (tenant_id IN (SELECT tenant_id FROM users WHERE id = auth.uid()));

-- ============================================
-- 9. COMMENTS FOR DOCUMENTATION
-- ============================================

COMMENT ON TABLE brands IS 'Product brands for brand comparison analysis';
COMMENT ON TABLE categories IS 'Hierarchical product categories';
COMMENT ON TABLE product_price_history IS 'Tracks product price changes over time (SCD Type 2)';
COMMENT ON TABLE dim_date IS 'Calendar dimension for time-based analysis';
COMMENT ON TABLE dim_time IS 'Time dimension for hourly pattern analysis';
COMMENT ON TABLE fact_daily_sales IS 'Daily aggregated sales metrics by branch';
COMMENT ON TABLE fact_product_sales IS 'Daily product-level sales metrics';
COMMENT ON TABLE fact_staff_sales IS 'Daily staff performance metrics';
COMMENT ON TABLE fact_brand_sales IS 'Daily brand performance metrics';
COMMENT ON TABLE fact_hourly_sales IS 'Hourly sales patterns';
