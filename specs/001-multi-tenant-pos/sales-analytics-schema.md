# Sales Analytics Database Schema Design

**Feature**: Comprehensive Sales Analytics & Reporting
**Created**: 2026-01-22
**Purpose**: Support in-depth sales analysis across multiple dimensions (product, brand, time, staff, customer segments)

---

## Design Philosophy

### Hybrid Approach: OLTP + OLAP

1. **Transactional Layer (OLTP)**: Real-time sales capture in normalized tables
2. **Analytics Layer (OLAP)**: Pre-aggregated metrics in dimensional model for fast queries
3. **ETL Process**: Periodic aggregation from transactional to analytics tables

### Key Design Principles

- **Multi-tenancy**: All tables scoped by `tenant_id` with Row Level Security
- **Scalability**: Partitioned fact tables by time for performance
- **Flexibility**: Star schema for easy dimensional slicing
- **Performance**: Materialized views for common queries
- **Historical Tracking**: Slowly Changing Dimensions (SCD Type 2) for products/prices

---

## Core Schema

### 1. Transactional Layer (Real-time Capture)

These tables capture every sale as it happens:

```sql
-- ============================================
-- SALES TRANSACTIONS (Existing, Enhanced)
-- ============================================

-- Main sale record
CREATE TABLE sales (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE CASCADE,

    -- Transaction identifiers
    sale_number VARCHAR(50) NOT NULL, -- Human-readable: S-2024-001234
    receipt_number VARCHAR(50),

    -- Customer information
    customer_id UUID REFERENCES customers(id) ON DELETE SET NULL,
    customer_type VARCHAR(20) DEFAULT 'walk-in', -- walk-in, registered, marketplace

    -- Staff information
    cashier_id UUID NOT NULL REFERENCES users(id), -- Who processed the sale
    sales_attendant_id UUID REFERENCES users(id), -- Who assisted/sold (for commission)

    -- Financial details
    subtotal DECIMAL(15,2) NOT NULL,
    discount_amount DECIMAL(15,2) DEFAULT 0,
    tax_amount DECIMAL(15,2) DEFAULT 0,
    delivery_fee DECIMAL(15,2) DEFAULT 0,
    total_amount DECIMAL(15,2) NOT NULL,
    amount_paid DECIMAL(15,2) NOT NULL,
    change_amount DECIMAL(15,2) DEFAULT 0,

    -- Payment details
    payment_method VARCHAR(50) NOT NULL, -- cash, card, transfer, mobile_money, split
    payment_status VARCHAR(20) DEFAULT 'completed', -- pending, completed, refunded, partial_refund
    payment_reference VARCHAR(100), -- External payment gateway reference

    -- Sale metadata
    sale_type VARCHAR(20) DEFAULT 'pos', -- pos, online, marketplace, delivery
    channel VARCHAR(20) DEFAULT 'in-store', -- in-store, online, mobile-app, whatsapp
    sale_status VARCHAR(20) DEFAULT 'completed', -- pending, completed, void, refunded
    void_reason TEXT,
    voided_by UUID REFERENCES users(id),
    voided_at TIMESTAMPTZ,

    -- Time tracking
    sale_date DATE NOT NULL, -- For easy date-based queries
    sale_time TIME NOT NULL,
    completed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Sync metadata
    _sync_version BIGINT DEFAULT 0,
    _sync_modified_at TIMESTAMPTZ DEFAULT NOW(),
    _sync_client_id UUID,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(tenant_id, sale_number)
);

-- Individual items in a sale
CREATE TABLE sale_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sale_id UUID NOT NULL REFERENCES sales(id) ON DELETE CASCADE,
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,

    -- Product identification
    product_id UUID NOT NULL REFERENCES products(id),
    product_variant_id UUID REFERENCES product_variants(id),

    -- Product snapshot (at time of sale)
    product_name VARCHAR(255) NOT NULL,
    product_sku VARCHAR(100),
    brand_id UUID REFERENCES brands(id),
    brand_name VARCHAR(255),
    category_id UUID REFERENCES categories(id),
    category_name VARCHAR(255),

    -- Quantity and pricing
    quantity DECIMAL(10,3) NOT NULL, -- Support fractional quantities (e.g., 2.5kg)
    unit_of_measure VARCHAR(20) DEFAULT 'piece', -- piece, kg, liter, meter, etc.

    unit_price DECIMAL(15,2) NOT NULL, -- Price per unit at time of sale
    original_price DECIMAL(15,2), -- Original price before discount
    discount_percentage DECIMAL(5,2) DEFAULT 0,
    discount_amount DECIMAL(15,2) DEFAULT 0,
    tax_percentage DECIMAL(5,2) DEFAULT 0,
    tax_amount DECIMAL(15,2) DEFAULT 0,
    line_total DECIMAL(15,2) NOT NULL, -- (quantity * unit_price) - discount + tax

    -- Cost tracking (for profit calculation)
    unit_cost DECIMAL(15,2), -- Cost of goods sold per unit
    total_cost DECIMAL(15,2), -- unit_cost * quantity
    gross_profit DECIMAL(15,2), -- line_total - total_cost
    profit_margin DECIMAL(5,2), -- (gross_profit / line_total) * 100

    -- Discount tracking
    discount_type VARCHAR(50), -- percentage, fixed_amount, promo_code, loyalty_points, bulk_discount
    discount_code VARCHAR(50), -- If promo code applied

    -- Notes
    notes TEXT,

    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- PRODUCT DIMENSION (Enhanced for Analytics)
-- ============================================

-- Brands (for brand comparison)
CREATE TABLE brands (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,

    name VARCHAR(255) NOT NULL,
    code VARCHAR(50), -- Brand code for reporting
    description TEXT,
    logo_url TEXT,

    -- Brand classification
    tier VARCHAR(20), -- premium, mid-range, budget
    is_house_brand BOOLEAN DEFAULT false, -- Store's own brand

    -- Metadata
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(tenant_id, name)
);

-- Product categories (hierarchical)
CREATE TABLE categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,

    name VARCHAR(255) NOT NULL,
    code VARCHAR(50),
    parent_category_id UUID REFERENCES categories(id), -- For hierarchical categories

    -- Category hierarchy level (for rollups)
    level INTEGER DEFAULT 1, -- 1=main, 2=sub, 3=sub-sub
    path TEXT, -- Materialized path: /Electronics/Phones/Smartphones/

    description TEXT,
    sort_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(tenant_id, name, parent_category_id)
);

-- Products (enhanced with history tracking)
CREATE TABLE products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    branch_id UUID REFERENCES branches(id), -- NULL = available to all branches

    -- Product identification
    name VARCHAR(255) NOT NULL,
    sku VARCHAR(100) NOT NULL, -- Stock Keeping Unit
    barcode VARCHAR(100),

    -- Classification
    brand_id UUID REFERENCES brands(id),
    category_id UUID REFERENCES categories(id),

    -- Pricing
    cost_price DECIMAL(15,2), -- What business paid
    selling_price DECIMAL(15,2) NOT NULL, -- Current selling price

    -- Stock
    quantity DECIMAL(10,3) DEFAULT 0,
    unit_of_measure VARCHAR(20) DEFAULT 'piece',
    reorder_level DECIMAL(10,3) DEFAULT 0,

    -- Product attributes
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    is_taxable BOOLEAN DEFAULT true,

    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(tenant_id, sku)
);

-- Product price history (for historical analysis)
CREATE TABLE product_price_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,

    cost_price DECIMAL(15,2),
    selling_price DECIMAL(15,2) NOT NULL,

    -- Price change tracking
    price_change_reason VARCHAR(100), -- promotion, cost_increase, seasonal, competitive
    changed_by UUID REFERENCES users(id),

    -- Validity period (SCD Type 2)
    valid_from TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    valid_to TIMESTAMPTZ, -- NULL = current price
    is_current BOOLEAN DEFAULT true,

    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- TIME DIMENSION (Pre-populated Calendar)
-- ============================================

CREATE TABLE dim_date (
    date_key INTEGER PRIMARY KEY, -- YYYYMMDD format: 20240122
    date_value DATE NOT NULL UNIQUE,

    -- Date components
    day INTEGER NOT NULL, -- 1-31
    day_of_week INTEGER NOT NULL, -- 1=Monday, 7=Sunday
    day_of_week_name VARCHAR(10) NOT NULL, -- Monday, Tuesday, etc.
    day_of_year INTEGER NOT NULL, -- 1-366

    -- Week
    week_of_year INTEGER NOT NULL, -- 1-53
    week_start_date DATE NOT NULL,
    week_end_date DATE NOT NULL,

    -- Month
    month INTEGER NOT NULL, -- 1-12
    month_name VARCHAR(10) NOT NULL, -- January, February, etc.
    month_abbr VARCHAR(3) NOT NULL, -- Jan, Feb, etc.
    month_start_date DATE NOT NULL,
    month_end_date DATE NOT NULL,

    -- Quarter
    quarter INTEGER NOT NULL, -- 1-4
    quarter_name VARCHAR(10) NOT NULL, -- Q1, Q2, Q3, Q4
    quarter_start_date DATE NOT NULL,
    quarter_end_date DATE NOT NULL,

    -- Year
    year INTEGER NOT NULL,
    year_start_date DATE NOT NULL,
    year_end_date DATE NOT NULL,

    -- Fiscal periods (if different from calendar)
    fiscal_year INTEGER,
    fiscal_quarter INTEGER,
    fiscal_month INTEGER,

    -- Business flags
    is_weekend BOOLEAN NOT NULL,
    is_holiday BOOLEAN DEFAULT false,
    holiday_name VARCHAR(100),
    is_business_day BOOLEAN NOT NULL,

    -- Prior period references (for easy comparison queries)
    prior_day_key INTEGER,
    prior_week_key INTEGER,
    prior_month_key INTEGER,
    prior_quarter_key INTEGER,
    prior_year_key INTEGER,

    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- TIME DIMENSION (Pre-populated Time)
-- ============================================

CREATE TABLE dim_time (
    time_key INTEGER PRIMARY KEY, -- HHMMSS format: 143045 (14:30:45)
    time_value TIME NOT NULL UNIQUE,

    -- Time components
    hour INTEGER NOT NULL, -- 0-23
    hour_12 INTEGER NOT NULL, -- 1-12
    am_pm VARCHAR(2) NOT NULL, -- AM, PM
    minute INTEGER NOT NULL, -- 0-59
    second INTEGER NOT NULL, -- 0-59

    -- Time periods
    time_period VARCHAR(20) NOT NULL, -- morning, afternoon, evening, night
    business_hour VARCHAR(20) NOT NULL, -- pre-open, business, lunch, post-close

    -- Analytics groupings
    hour_bucket INTEGER NOT NULL, -- 0, 1, 2, ... 23 (for hourly aggregation)
    minute_bucket INTEGER NOT NULL, -- 0, 15, 30, 45 (for 15-min aggregation)

    is_peak_hour BOOLEAN DEFAULT false, -- Configurable peak hours

    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- ANALYTICS LAYER (Aggregated Metrics)
-- ============================================

-- Daily sales summary (partitioned by date)
CREATE TABLE fact_daily_sales (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    branch_id UUID NOT NULL REFERENCES branches(id),

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

    -- Created timestamp
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(tenant_id, branch_id, date_key)
) PARTITION BY RANGE (sale_date);

-- Product sales summary (daily aggregation)
CREATE TABLE fact_product_sales (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    branch_id UUID NOT NULL REFERENCES branches(id),

    -- Dimensions
    date_key INTEGER NOT NULL REFERENCES dim_date(date_key),
    sale_date DATE NOT NULL,
    product_id UUID NOT NULL REFERENCES products(id),
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
    transaction_count INTEGER DEFAULT 0, -- Number of sales containing this product

    -- Discount metrics
    total_discount_amount DECIMAL(15,2) DEFAULT 0,
    average_discount_percentage DECIMAL(5,2) DEFAULT 0,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(tenant_id, branch_id, date_key, product_id)
) PARTITION BY RANGE (sale_date);

-- Staff sales performance (daily aggregation)
CREATE TABLE fact_staff_sales (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    branch_id UUID NOT NULL REFERENCES branches(id),

    -- Dimensions
    date_key INTEGER NOT NULL REFERENCES dim_date(date_key),
    sale_date DATE NOT NULL,
    staff_id UUID NOT NULL REFERENCES users(id),
    staff_role VARCHAR(50), -- cashier, sales_attendant, both

    -- Staff info snapshot
    staff_name VARCHAR(255) NOT NULL,

    -- Aggregated metrics
    total_transactions INTEGER DEFAULT 0,
    total_items_sold DECIMAL(15,3) DEFAULT 0,
    total_revenue DECIMAL(15,2) DEFAULT 0,
    total_profit DECIMAL(15,2) DEFAULT 0,
    average_transaction_value DECIMAL(15,2) DEFAULT 0,

    -- Performance metrics
    average_transaction_time INTERVAL, -- Average time to complete sale
    transactions_per_hour DECIMAL(5,2) DEFAULT 0,

    -- Commission calculation
    commission_eligible_sales DECIMAL(15,2) DEFAULT 0,
    commission_amount DECIMAL(15,2) DEFAULT 0,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(tenant_id, branch_id, date_key, staff_id, staff_role)
) PARTITION BY RANGE (sale_date);

-- Brand performance comparison (daily aggregation)
CREATE TABLE fact_brand_sales (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    branch_id UUID NOT NULL REFERENCES branches(id),

    -- Dimensions
    date_key INTEGER NOT NULL REFERENCES dim_date(date_key),
    sale_date DATE NOT NULL,
    brand_id UUID NOT NULL REFERENCES brands(id),
    category_id UUID REFERENCES categories(id), -- Brand performance within category

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

    UNIQUE(tenant_id, branch_id, date_key, brand_id, category_id)
) PARTITION BY RANGE (sale_date);

-- Hourly sales pattern (for peak hour analysis)
CREATE TABLE fact_hourly_sales (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    branch_id UUID NOT NULL REFERENCES branches(id),

    -- Dimensions
    date_key INTEGER NOT NULL REFERENCES dim_date(date_key),
    time_key INTEGER NOT NULL REFERENCES dim_time(time_key),
    sale_date DATE NOT NULL,
    hour INTEGER NOT NULL, -- 0-23

    -- Aggregated metrics
    total_transactions INTEGER DEFAULT 0,
    total_revenue DECIMAL(15,2) DEFAULT 0,
    average_transaction_value DECIMAL(15,2) DEFAULT 0,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(tenant_id, branch_id, date_key, time_key)
) PARTITION BY RANGE (sale_date);
```

---

## Indexes for Performance

```sql
-- ============================================
-- INDEXES FOR TRANSACTIONAL QUERIES
-- ============================================

-- Sales table indexes
CREATE INDEX idx_sales_tenant_date ON sales(tenant_id, sale_date DESC);
CREATE INDEX idx_sales_branch_date ON sales(branch_id, sale_date DESC);
CREATE INDEX idx_sales_customer ON sales(customer_id, completed_at DESC);
CREATE INDEX idx_sales_cashier ON sales(cashier_id, sale_date DESC);
CREATE INDEX idx_sales_attendant ON sales(sales_attendant_id, sale_date DESC);
CREATE INDEX idx_sales_status ON sales(sale_status, tenant_id);
CREATE INDEX idx_sales_completed ON sales(completed_at DESC);

-- Sale items indexes
CREATE INDEX idx_sale_items_sale ON sale_items(sale_id);
CREATE INDEX idx_sale_items_product ON sale_items(product_id, created_at DESC);
CREATE INDEX idx_sale_items_brand ON sale_items(brand_id, created_at DESC);
CREATE INDEX idx_sale_items_category ON sale_items(category_id, created_at DESC);
CREATE INDEX idx_sale_items_tenant ON sale_items(tenant_id, created_at DESC);

-- Product indexes
CREATE INDEX idx_products_tenant ON products(tenant_id);
CREATE INDEX idx_products_brand ON products(brand_id);
CREATE INDEX idx_products_category ON products(category_id);
CREATE INDEX idx_products_sku ON products(tenant_id, sku);
CREATE INDEX idx_products_barcode ON products(barcode) WHERE barcode IS NOT NULL;
CREATE INDEX idx_products_active ON products(is_active, tenant_id);

-- Brand indexes
CREATE INDEX idx_brands_tenant ON brands(tenant_id);
CREATE INDEX idx_brands_active ON brands(is_active, tenant_id);

-- Category indexes
CREATE INDEX idx_categories_tenant ON categories(tenant_id);
CREATE INDEX idx_categories_parent ON categories(parent_category_id);
CREATE INDEX idx_categories_path ON categories(path) USING gin(path gin_trgm_ops);

-- ============================================
-- INDEXES FOR ANALYTICS QUERIES
-- ============================================

-- Date dimension indexes
CREATE INDEX idx_dim_date_value ON dim_date(date_value);
CREATE INDEX idx_dim_date_month ON dim_date(year, month);
CREATE INDEX idx_dim_date_quarter ON dim_date(year, quarter);
CREATE INDEX idx_dim_date_year ON dim_date(year);
CREATE INDEX idx_dim_date_day_of_week ON dim_date(day_of_week);
CREATE INDEX idx_dim_date_is_business_day ON dim_date(is_business_day);

-- Daily sales fact indexes
CREATE INDEX idx_fact_daily_sales_tenant ON fact_daily_sales(tenant_id, date_key DESC);
CREATE INDEX idx_fact_daily_sales_branch ON fact_daily_sales(branch_id, date_key DESC);

-- Product sales fact indexes
CREATE INDEX idx_fact_product_sales_tenant ON fact_product_sales(tenant_id, date_key DESC);
CREATE INDEX idx_fact_product_sales_product ON fact_product_sales(product_id, date_key DESC);
CREATE INDEX idx_fact_product_sales_brand ON fact_product_sales(brand_id, date_key DESC);
CREATE INDEX idx_fact_product_sales_category ON fact_product_sales(category_id, date_key DESC);

-- Staff sales fact indexes
CREATE INDEX idx_fact_staff_sales_tenant ON fact_staff_sales(tenant_id, date_key DESC);
CREATE INDEX idx_fact_staff_sales_staff ON fact_staff_sales(staff_id, date_key DESC);

-- Brand sales fact indexes
CREATE INDEX idx_fact_brand_sales_tenant ON fact_brand_sales(tenant_id, date_key DESC);
CREATE INDEX idx_fact_brand_sales_brand ON fact_brand_sales(brand_id, date_key DESC);

-- Hourly sales fact indexes
CREATE INDEX idx_fact_hourly_sales_tenant ON fact_hourly_sales(tenant_id, date_key DESC);
CREATE INDEX idx_fact_hourly_sales_hour ON fact_hourly_sales(hour, date_key DESC);
```

---

## Partition Setup (PostgreSQL 12+)

```sql
-- ============================================
-- PARTITION TABLES BY DATE RANGE
-- ============================================

-- Create partitions for fact_daily_sales (monthly partitions)
CREATE TABLE fact_daily_sales_2024_01 PARTITION OF fact_daily_sales
    FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');

CREATE TABLE fact_daily_sales_2024_02 PARTITION OF fact_daily_sales
    FOR VALUES FROM ('2024-02-01') TO ('2024-03-01');

-- ... create partitions for each month/quarter as needed

-- Auto-create partitions using pg_partman extension (recommended)
-- Or use a maintenance job to create future partitions

-- Similar partitions for other fact tables
CREATE TABLE fact_product_sales_2024_01 PARTITION OF fact_product_sales
    FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');

CREATE TABLE fact_staff_sales_2024_01 PARTITION OF fact_staff_sales
    FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');

CREATE TABLE fact_brand_sales_2024_01 PARTITION OF fact_brand_sales
    FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');

CREATE TABLE fact_hourly_sales_2024_01 PARTITION OF fact_hourly_sales
    FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');
```

---

## Materialized Views for Common Queries

```sql
-- ============================================
-- MATERIALIZED VIEWS FOR FAST QUERIES
-- ============================================

-- Top selling products (all-time)
CREATE MATERIALIZED VIEW mv_top_products AS
SELECT
    fps.tenant_id,
    fps.product_id,
    fps.product_name,
    fps.brand_name,
    fps.category_name,
    SUM(fps.quantity_sold) as total_quantity_sold,
    SUM(fps.total_revenue) as total_revenue,
    SUM(fps.total_profit) as total_profit,
    AVG(fps.average_profit_margin) as avg_profit_margin,
    SUM(fps.transaction_count) as total_transactions
FROM fact_product_sales fps
GROUP BY
    fps.tenant_id,
    fps.product_id,
    fps.product_name,
    fps.brand_name,
    fps.category_name;

CREATE UNIQUE INDEX idx_mv_top_products ON mv_top_products(tenant_id, product_id);

-- Brand comparison (all-time)
CREATE MATERIALIZED VIEW mv_brand_comparison AS
SELECT
    fbs.tenant_id,
    fbs.brand_id,
    fbs.brand_name,
    SUM(fbs.quantity_sold) as total_quantity_sold,
    SUM(fbs.total_revenue) as total_revenue,
    SUM(fbs.total_profit) as total_profit,
    AVG(fbs.average_profit_margin) as avg_profit_margin,
    SUM(fbs.transaction_count) as total_transactions,
    COUNT(DISTINCT fbs.category_id) as category_count
FROM fact_brand_sales fbs
GROUP BY
    fbs.tenant_id,
    fbs.brand_id,
    fbs.brand_name;

CREATE UNIQUE INDEX idx_mv_brand_comparison ON mv_brand_comparison(tenant_id, brand_id);

-- Staff performance leaderboard
CREATE MATERIALIZED VIEW mv_staff_leaderboard AS
SELECT
    fss.tenant_id,
    fss.staff_id,
    fss.staff_name,
    SUM(fss.total_transactions) as total_transactions,
    SUM(fss.total_revenue) as total_revenue,
    SUM(fss.total_profit) as total_profit,
    AVG(fss.average_transaction_value) as avg_transaction_value,
    SUM(fss.commission_amount) as total_commission
FROM fact_staff_sales fss
GROUP BY
    fss.tenant_id,
    fss.staff_id,
    fss.staff_name;

CREATE UNIQUE INDEX idx_mv_staff_leaderboard ON mv_staff_leaderboard(tenant_id, staff_id);

-- Refresh materialized views (run daily via cron job)
REFRESH MATERIALIZED VIEW CONCURRENTLY mv_top_products;
REFRESH MATERIALIZED VIEW CONCURRENTLY mv_brand_comparison;
REFRESH MATERIALIZED VIEW CONCURRENTLY mv_staff_leaderboard;
```

---

## ETL Process (Aggregate Transactional Data)

```sql
-- ============================================
-- ETL FUNCTION: Aggregate Daily Sales
-- ============================================

CREATE OR REPLACE FUNCTION aggregate_daily_sales(p_date DATE)
RETURNS void AS $$
DECLARE
    v_date_key INTEGER;
BEGIN
    -- Get date key
    SELECT date_key INTO v_date_key
    FROM dim_date
    WHERE date_value = p_date;

    -- Aggregate to fact_daily_sales
    INSERT INTO fact_daily_sales (
        tenant_id, branch_id, date_key, sale_date,
        total_transactions, total_items_sold, total_revenue,
        total_cost, total_profit, average_transaction_value,
        average_profit_margin, unique_customers, new_customers,
        cash_transactions, cash_revenue, card_transactions, card_revenue,
        transfer_transactions, transfer_revenue, void_transactions,
        void_amount, refund_transactions, refund_amount
    )
    SELECT
        s.tenant_id,
        s.branch_id,
        v_date_key,
        p_date,
        COUNT(DISTINCT s.id) as total_transactions,
        SUM(si.quantity) as total_items_sold,
        SUM(s.total_amount) as total_revenue,
        SUM(si.total_cost) as total_cost,
        SUM(si.gross_profit) as total_profit,
        AVG(s.total_amount) as average_transaction_value,
        AVG(si.profit_margin) as average_profit_margin,
        COUNT(DISTINCT s.customer_id) FILTER (WHERE s.customer_id IS NOT NULL) as unique_customers,
        COUNT(DISTINCT s.customer_id) FILTER (WHERE s.customer_type = 'new') as new_customers,
        COUNT(*) FILTER (WHERE s.payment_method = 'cash') as cash_transactions,
        SUM(s.total_amount) FILTER (WHERE s.payment_method = 'cash') as cash_revenue,
        COUNT(*) FILTER (WHERE s.payment_method = 'card') as card_transactions,
        SUM(s.total_amount) FILTER (WHERE s.payment_method = 'card') as card_revenue,
        COUNT(*) FILTER (WHERE s.payment_method = 'transfer') as transfer_transactions,
        SUM(s.total_amount) FILTER (WHERE s.payment_method = 'transfer') as transfer_revenue,
        COUNT(*) FILTER (WHERE s.sale_status = 'void') as void_transactions,
        SUM(s.total_amount) FILTER (WHERE s.sale_status = 'void') as void_amount,
        COUNT(*) FILTER (WHERE s.sale_status = 'refunded') as refund_transactions,
        SUM(s.total_amount) FILTER (WHERE s.sale_status = 'refunded') as refund_amount
    FROM sales s
    LEFT JOIN sale_items si ON si.sale_id = s.id
    WHERE s.sale_date = p_date
    GROUP BY s.tenant_id, s.branch_id
    ON CONFLICT (tenant_id, branch_id, date_key)
    DO UPDATE SET
        total_transactions = EXCLUDED.total_transactions,
        total_items_sold = EXCLUDED.total_items_sold,
        total_revenue = EXCLUDED.total_revenue,
        total_cost = EXCLUDED.total_cost,
        total_profit = EXCLUDED.total_profit,
        updated_at = NOW();

    -- Aggregate to fact_product_sales
    INSERT INTO fact_product_sales (
        tenant_id, branch_id, date_key, sale_date,
        product_id, brand_id, category_id,
        product_name, product_sku, brand_name, category_name,
        quantity_sold, total_revenue, total_cost, total_profit,
        average_unit_price, average_profit_margin, transaction_count,
        total_discount_amount, average_discount_percentage
    )
    SELECT
        si.tenant_id,
        s.branch_id,
        v_date_key,
        p_date,
        si.product_id,
        si.brand_id,
        si.category_id,
        si.product_name,
        si.product_sku,
        si.brand_name,
        si.category_name,
        SUM(si.quantity) as quantity_sold,
        SUM(si.line_total) as total_revenue,
        SUM(si.total_cost) as total_cost,
        SUM(si.gross_profit) as total_profit,
        AVG(si.unit_price) as average_unit_price,
        AVG(si.profit_margin) as average_profit_margin,
        COUNT(DISTINCT s.id) as transaction_count,
        SUM(si.discount_amount) as total_discount_amount,
        AVG(si.discount_percentage) as average_discount_percentage
    FROM sale_items si
    JOIN sales s ON s.id = si.sale_id
    WHERE s.sale_date = p_date
    GROUP BY
        si.tenant_id, s.branch_id, si.product_id,
        si.brand_id, si.category_id,
        si.product_name, si.product_sku,
        si.brand_name, si.category_name
    ON CONFLICT (tenant_id, branch_id, date_key, product_id)
    DO UPDATE SET
        quantity_sold = EXCLUDED.quantity_sold,
        total_revenue = EXCLUDED.total_revenue,
        updated_at = NOW();

    -- Similar aggregation for fact_staff_sales, fact_brand_sales, fact_hourly_sales
    -- ... (implement similar logic)

END;
$$ LANGUAGE plpgsql;

-- Schedule to run daily (or every hour for real-time analytics)
-- Using pg_cron extension:
-- SELECT cron.schedule('aggregate-daily-sales', '0 1 * * *',
--   $$SELECT aggregate_daily_sales(CURRENT_DATE - 1)$$);
```

---

## Example Analytical Queries

```sql
-- ============================================
-- QUERY 1: Product Sales History
-- ============================================

-- Get sales history for a specific product over last 30 days
SELECT
    dd.date_value,
    dd.day_of_week_name,
    fps.quantity_sold,
    fps.total_revenue,
    fps.total_profit,
    fps.average_profit_margin,
    fps.transaction_count
FROM fact_product_sales fps
JOIN dim_date dd ON dd.date_key = fps.date_key
WHERE
    fps.tenant_id = 'xxx-xxx-xxx'
    AND fps.product_id = 'yyy-yyy-yyy'
    AND fps.sale_date >= CURRENT_DATE - INTERVAL '30 days'
ORDER BY dd.date_value DESC;

-- ============================================
-- QUERY 2: Brand Comparison (Same Product)
-- ============================================

-- Compare sales of similar products across different brands
SELECT
    fps.brand_name,
    fps.product_name,
    SUM(fps.quantity_sold) as total_quantity,
    SUM(fps.total_revenue) as total_revenue,
    SUM(fps.total_profit) as total_profit,
    AVG(fps.average_unit_price) as avg_price,
    SUM(fps.transaction_count) as times_purchased
FROM fact_product_sales fps
WHERE
    fps.tenant_id = 'xxx-xxx-xxx'
    AND fps.category_id = 'zzz-zzz-zzz' -- e.g., "Smartphones"
    AND fps.sale_date >= CURRENT_DATE - INTERVAL '90 days'
GROUP BY fps.brand_name, fps.product_name
ORDER BY total_revenue DESC;

-- ============================================
-- QUERY 3: Sales by Staff Attendant
-- ============================================

-- Staff performance for current month
SELECT
    fss.staff_name,
    SUM(fss.total_transactions) as total_sales,
    SUM(fss.total_revenue) as revenue,
    SUM(fss.total_profit) as profit,
    AVG(fss.average_transaction_value) as avg_ticket_size,
    SUM(fss.commission_amount) as commission_earned
FROM fact_staff_sales fss
JOIN dim_date dd ON dd.date_key = fss.date_key
WHERE
    fss.tenant_id = 'xxx-xxx-xxx'
    AND dd.year = EXTRACT(YEAR FROM CURRENT_DATE)
    AND dd.month = EXTRACT(MONTH FROM CURRENT_DATE)
GROUP BY fss.staff_name
ORDER BY revenue DESC;

-- ============================================
-- QUERY 4: Month vs Previous Month Comparison
-- ============================================

-- Compare current month to previous month
WITH current_month AS (
    SELECT
        SUM(total_revenue) as revenue,
        SUM(total_profit) as profit,
        SUM(total_transactions) as transactions
    FROM fact_daily_sales fds
    JOIN dim_date dd ON dd.date_key = fds.date_key
    WHERE
        fds.tenant_id = 'xxx-xxx-xxx'
        AND dd.year = EXTRACT(YEAR FROM CURRENT_DATE)
        AND dd.month = EXTRACT(MONTH FROM CURRENT_DATE)
),
previous_month AS (
    SELECT
        SUM(total_revenue) as revenue,
        SUM(total_profit) as profit,
        SUM(total_transactions) as transactions
    FROM fact_daily_sales fds
    JOIN dim_date dd ON dd.date_key = fds.date_key
    WHERE
        fds.tenant_id = 'xxx-xxx-xxx'
        AND dd.year = EXTRACT(YEAR FROM CURRENT_DATE - INTERVAL '1 month')
        AND dd.month = EXTRACT(MONTH FROM CURRENT_DATE - INTERVAL '1 month')
)
SELECT
    cm.revenue as current_month_revenue,
    pm.revenue as previous_month_revenue,
    ((cm.revenue - pm.revenue) / pm.revenue * 100) as revenue_change_pct,
    cm.transactions as current_month_transactions,
    pm.transactions as previous_month_transactions,
    ((cm.transactions - pm.transactions)::DECIMAL / pm.transactions * 100) as transaction_change_pct
FROM current_month cm, previous_month pm;

-- ============================================
-- QUERY 5: Quarter vs Previous Quarter
-- ============================================

-- Compare current quarter to previous quarter
WITH current_quarter AS (
    SELECT
        dd.quarter,
        dd.year,
        SUM(fds.total_revenue) as revenue,
        SUM(fds.total_profit) as profit
    FROM fact_daily_sales fds
    JOIN dim_date dd ON dd.date_key = fds.date_key
    WHERE
        fds.tenant_id = 'xxx-xxx-xxx'
        AND dd.quarter = EXTRACT(QUARTER FROM CURRENT_DATE)
        AND dd.year = EXTRACT(YEAR FROM CURRENT_DATE)
    GROUP BY dd.quarter, dd.year
),
previous_quarter AS (
    SELECT
        dd.quarter,
        dd.year,
        SUM(fds.total_revenue) as revenue,
        SUM(fds.total_profit) as profit
    FROM fact_daily_sales fds
    JOIN dim_date dd ON dd.date_key = fds.date_key
    WHERE
        fds.tenant_id = 'xxx-xxx-xxx'
        AND dd.quarter = EXTRACT(QUARTER FROM CURRENT_DATE - INTERVAL '3 months')
        AND dd.year = EXTRACT(YEAR FROM CURRENT_DATE - INTERVAL '3 months')
    GROUP BY dd.quarter, dd.year
)
SELECT
    cq.year || '-Q' || cq.quarter as current_period,
    cq.revenue as current_revenue,
    pq.year || '-Q' || pq.quarter as previous_period,
    pq.revenue as previous_revenue,
    ((cq.revenue - pq.revenue) / pq.revenue * 100) as growth_percentage
FROM current_quarter cq, previous_quarter pq;

-- ============================================
-- QUERY 6: Year vs Previous Year
-- ============================================

-- Year-over-year comparison
SELECT
    dd.year,
    dd.month_name,
    SUM(fds.total_revenue) as monthly_revenue,
    LAG(SUM(fds.total_revenue), 12) OVER (ORDER BY dd.year, dd.month) as same_month_last_year,
    ((SUM(fds.total_revenue) - LAG(SUM(fds.total_revenue), 12) OVER (ORDER BY dd.year, dd.month))
     / LAG(SUM(fds.total_revenue), 12) OVER (ORDER BY dd.year, dd.month) * 100) as yoy_growth_pct
FROM fact_daily_sales fds
JOIN dim_date dd ON dd.date_key = fds.date_key
WHERE fds.tenant_id = 'xxx-xxx-xxx'
GROUP BY dd.year, dd.month, dd.month_name
ORDER BY dd.year DESC, dd.month DESC;

-- ============================================
-- QUERY 7: Top 10 Products by Revenue (Any Period)
-- ============================================

SELECT
    fps.product_name,
    fps.brand_name,
    SUM(fps.quantity_sold) as units_sold,
    SUM(fps.total_revenue) as revenue,
    SUM(fps.total_profit) as profit,
    ROUND(AVG(fps.average_profit_margin), 2) as avg_margin
FROM fact_product_sales fps
JOIN dim_date dd ON dd.date_key = fps.date_key
WHERE
    fps.tenant_id = 'xxx-xxx-xxx'
    AND dd.year = 2024
    AND dd.quarter = 1
GROUP BY fps.product_name, fps.brand_name
ORDER BY revenue DESC
LIMIT 10;

-- ============================================
-- QUERY 8: Sales Pattern by Hour
-- ============================================

-- Peak sales hours
SELECT
    dt.hour,
    dt.time_period,
    AVG(fhs.total_transactions) as avg_transactions,
    AVG(fhs.total_revenue) as avg_revenue
FROM fact_hourly_sales fhs
JOIN dim_time dt ON dt.time_key = fhs.time_key
JOIN dim_date dd ON dd.date_key = fhs.date_key
WHERE
    fhs.tenant_id = 'xxx-xxx-xxx'
    AND dd.is_business_day = true
    AND dd.sale_date >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY dt.hour, dt.time_period
ORDER BY dt.hour;

-- ============================================
-- QUERY 9: Category Performance Comparison
-- ============================================

-- Compare categories by revenue and margin
SELECT
    fps.category_name,
    COUNT(DISTINCT fps.product_id) as unique_products,
    SUM(fps.quantity_sold) as units_sold,
    SUM(fps.total_revenue) as revenue,
    SUM(fps.total_profit) as profit,
    ROUND(AVG(fps.average_profit_margin), 2) as avg_margin,
    SUM(fps.transaction_count) as transaction_count
FROM fact_product_sales fps
JOIN dim_date dd ON dd.date_key = fps.date_key
WHERE
    fps.tenant_id = 'xxx-xxx-xxx'
    AND dd.month_start_date = DATE_TRUNC('month', CURRENT_DATE)
GROUP BY fps.category_name
ORDER BY revenue DESC;

-- ============================================
-- QUERY 10: Slow-Moving vs Fast-Moving Products
-- ============================================

-- Products by inventory turnover
WITH product_sales AS (
    SELECT
        fps.product_id,
        fps.product_name,
        SUM(fps.quantity_sold) as total_sold,
        AVG(p.quantity) as avg_stock
    FROM fact_product_sales fps
    JOIN products p ON p.id = fps.product_id
    JOIN dim_date dd ON dd.date_key = fps.date_key
    WHERE
        fps.tenant_id = 'xxx-xxx-xxx'
        AND dd.date_value >= CURRENT_DATE - INTERVAL '90 days'
    GROUP BY fps.product_id, fps.product_name
)
SELECT
    product_name,
    total_sold,
    avg_stock,
    CASE
        WHEN avg_stock > 0 THEN ROUND(total_sold / avg_stock, 2)
        ELSE 0
    END as turnover_ratio,
    CASE
        WHEN avg_stock > 0 AND (total_sold / avg_stock) > 4 THEN 'Fast Moving'
        WHEN avg_stock > 0 AND (total_sold / avg_stock) BETWEEN 2 AND 4 THEN 'Medium Moving'
        ELSE 'Slow Moving'
    END as inventory_category
FROM product_sales
ORDER BY turnover_ratio DESC;
```

---

## Maintenance & Best Practices

### 1. Partition Management

```sql
-- Create function to auto-create future partitions
CREATE OR REPLACE FUNCTION create_monthly_partitions(
    p_table_name TEXT,
    p_months_ahead INTEGER DEFAULT 3
)
RETURNS void AS $$
DECLARE
    v_date DATE;
    v_partition_name TEXT;
    v_start_date DATE;
    v_end_date DATE;
BEGIN
    FOR i IN 1..p_months_ahead LOOP
        v_date := DATE_TRUNC('month', CURRENT_DATE) + (i || ' months')::INTERVAL;
        v_partition_name := p_table_name || '_' || TO_CHAR(v_date, 'YYYY_MM');
        v_start_date := DATE_TRUNC('month', v_date);
        v_end_date := v_start_date + INTERVAL '1 month';

        EXECUTE format(
            'CREATE TABLE IF NOT EXISTS %I PARTITION OF %I FOR VALUES FROM (%L) TO (%L)',
            v_partition_name, p_table_name, v_start_date, v_end_date
        );
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Run monthly via cron
SELECT create_monthly_partitions('fact_daily_sales');
SELECT create_monthly_partitions('fact_product_sales');
```

### 2. Data Retention

```sql
-- Drop old partitions after retention period (e.g., 2 years)
CREATE OR REPLACE FUNCTION drop_old_partitions(
    p_table_name TEXT,
    p_retention_months INTEGER DEFAULT 24
)
RETURNS void AS $$
DECLARE
    v_cutoff_date DATE;
    v_partition_name TEXT;
BEGIN
    v_cutoff_date := DATE_TRUNC('month', CURRENT_DATE) - (p_retention_months || ' months')::INTERVAL;

    FOR v_partition_name IN
        SELECT tablename
        FROM pg_tables
        WHERE schemaname = 'public'
        AND tablename LIKE p_table_name || '%'
        AND tablename < p_table_name || '_' || TO_CHAR(v_cutoff_date, 'YYYY_MM')
    LOOP
        EXECUTE 'DROP TABLE IF EXISTS ' || v_partition_name;
    END LOOP;
END;
$$ LANGUAGE plpgsql;
```

### 3. Performance Monitoring

```sql
-- Track fact table sizes
SELECT
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size,
    n_tup_ins as rows_inserted,
    n_tup_upd as rows_updated
FROM pg_stat_user_tables
WHERE tablename LIKE 'fact_%'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
```

---

## Summary

This schema provides:

✅ **Scalability**: Partitioned fact tables handle millions of records
✅ **Flexibility**: Star schema supports any dimensional slicing
✅ **Performance**: Pre-aggregated metrics + materialized views for sub-second queries
✅ **Comparison**: Easy period-over-period analysis (day, week, month, quarter, year)
✅ **Multi-dimensional**: Analyze by product, brand, category, staff, time, customer
✅ **Real-time + Historical**: Transactional tables for real-time, fact tables for analytics
✅ **Multi-tenant**: All tables tenant-scoped with RLS

**Next Steps**:
1. Implement schema in Supabase migrations
2. Create ETL jobs for daily aggregation
3. Build API endpoints for analytics queries
4. Create dashboard UI components
5. Set up partition management cron jobs
