-- ============================================
-- Migration: Analytics Fact Tables (Partitioned)
-- Description: Create partitioned fact tables for analytics
-- Created: 2026-01-23
-- ============================================

-- ============================================
-- FACT: DAILY SALES SUMMARY
-- ============================================

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

-- RLS for fact_daily_sales
ALTER TABLE fact_daily_sales ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view daily sales in their tenant" ON fact_daily_sales;
CREATE POLICY "Users can view daily sales in their tenant"
    ON fact_daily_sales FOR SELECT
    USING (tenant_id IN (SELECT tenant_id FROM users WHERE id = auth.uid()));

COMMENT ON TABLE fact_daily_sales IS 'Daily aggregated sales metrics by branch';

-- ============================================
-- FACT: PRODUCT SALES SUMMARY
-- ============================================

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

-- RLS for fact_product_sales
ALTER TABLE fact_product_sales ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view product sales in their tenant" ON fact_product_sales;
CREATE POLICY "Users can view product sales in their tenant"
    ON fact_product_sales FOR SELECT
    USING (tenant_id IN (SELECT tenant_id FROM users WHERE id = auth.uid()));

COMMENT ON TABLE fact_product_sales IS 'Daily product-level sales metrics';

-- ============================================
-- FACT: STAFF SALES PERFORMANCE
-- ============================================

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

-- RLS for fact_staff_sales
ALTER TABLE fact_staff_sales ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view staff sales in their tenant" ON fact_staff_sales;
CREATE POLICY "Users can view staff sales in their tenant"
    ON fact_staff_sales FOR SELECT
    USING (tenant_id IN (SELECT tenant_id FROM users WHERE id = auth.uid()));

COMMENT ON TABLE fact_staff_sales IS 'Daily staff performance metrics';

-- ============================================
-- FACT: BRAND SALES PERFORMANCE
-- ============================================

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

-- RLS for fact_brand_sales
ALTER TABLE fact_brand_sales ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view brand sales in their tenant" ON fact_brand_sales;
CREATE POLICY "Users can view brand sales in their tenant"
    ON fact_brand_sales FOR SELECT
    USING (tenant_id IN (SELECT tenant_id FROM users WHERE id = auth.uid()));

COMMENT ON TABLE fact_brand_sales IS 'Daily brand performance metrics';

-- ============================================
-- FACT: HOURLY SALES PATTERN
-- ============================================

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

-- RLS for fact_hourly_sales
ALTER TABLE fact_hourly_sales ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view hourly sales in their tenant" ON fact_hourly_sales;
CREATE POLICY "Users can view hourly sales in their tenant"
    ON fact_hourly_sales FOR SELECT
    USING (tenant_id IN (SELECT tenant_id FROM users WHERE id = auth.uid()));

COMMENT ON TABLE fact_hourly_sales IS 'Hourly sales patterns';
