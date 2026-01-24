-- ============================================
-- Migration: Analytics Indexes and Partitions
-- Description: Create indexes for performance and initial partitions
-- Created: 2026-01-22
-- ============================================

-- ============================================
-- 1. INDEXES FOR TRANSACTIONAL QUERIES
-- ============================================

-- Sales table indexes
CREATE INDEX IF NOT EXISTS idx_sales_tenant_date ON sales(tenant_id, sale_date DESC);
CREATE INDEX IF NOT EXISTS idx_sales_branch_date ON sales(branch_id, sale_date DESC);
CREATE INDEX IF NOT EXISTS idx_sales_customer ON sales(customer_id, completed_at DESC) WHERE customer_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_sales_cashier ON sales(cashier_id, sale_date DESC);
CREATE INDEX IF NOT EXISTS idx_sales_attendant ON sales(sales_attendant_id, sale_date DESC) WHERE sales_attendant_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_sales_status ON sales(sale_status, tenant_id);
CREATE INDEX IF NOT EXISTS idx_sales_completed ON sales(completed_at DESC);
CREATE INDEX IF NOT EXISTS idx_sales_payment_method ON sales(payment_method, tenant_id);
CREATE INDEX IF NOT EXISTS idx_sales_channel ON sales(channel, tenant_id);

-- Sale items indexes
CREATE INDEX IF NOT EXISTS idx_sale_items_sale ON sale_items(sale_id);
CREATE INDEX IF NOT EXISTS idx_sale_items_product ON sale_items(product_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_sale_items_brand ON sale_items(brand_id, created_at DESC) WHERE brand_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_sale_items_category ON sale_items(category_id, created_at DESC) WHERE category_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_sale_items_tenant ON sale_items(tenant_id, created_at DESC);

-- Product indexes
CREATE INDEX IF NOT EXISTS idx_products_tenant ON products(tenant_id) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_products_brand ON products(brand_id) WHERE brand_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_products_category ON products(category_id) WHERE category_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_products_sku ON products(tenant_id, sku);
CREATE INDEX IF NOT EXISTS idx_products_barcode ON products(barcode) WHERE barcode IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_products_active ON products(is_active, tenant_id);

-- Brand indexes
CREATE INDEX IF NOT EXISTS idx_brands_tenant ON brands(tenant_id);
CREATE INDEX IF NOT EXISTS idx_brands_active ON brands(is_active, tenant_id);
CREATE INDEX IF NOT EXISTS idx_brands_name ON brands(tenant_id, name);

-- Category indexes
CREATE INDEX IF NOT EXISTS idx_categories_tenant ON categories(tenant_id);
CREATE INDEX IF NOT EXISTS idx_categories_parent ON categories(parent_category_id) WHERE parent_category_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_categories_level ON categories(tenant_id, level);
CREATE INDEX IF NOT EXISTS idx_categories_active ON categories(is_active, tenant_id);

-- Product price history indexes
CREATE INDEX IF NOT EXISTS idx_price_history_product ON product_price_history(product_id, valid_from DESC);
CREATE INDEX IF NOT EXISTS idx_price_history_current ON product_price_history(product_id, is_current) WHERE is_current = true;
CREATE INDEX IF NOT EXISTS idx_price_history_tenant ON product_price_history(tenant_id, created_at DESC);

-- ============================================
-- 2. INDEXES FOR ANALYTICS QUERIES
-- ============================================

-- Date dimension indexes
CREATE INDEX IF NOT EXISTS idx_dim_date_value ON dim_date(date_value);
CREATE INDEX IF NOT EXISTS idx_dim_date_month ON dim_date(year, month);
CREATE INDEX IF NOT EXISTS idx_dim_date_quarter ON dim_date(year, quarter);
CREATE INDEX IF NOT EXISTS idx_dim_date_year ON dim_date(year);
CREATE INDEX IF NOT EXISTS idx_dim_date_day_of_week ON dim_date(day_of_week);
CREATE INDEX IF NOT EXISTS idx_dim_date_is_business_day ON dim_date(is_business_day);
CREATE INDEX IF NOT EXISTS idx_dim_date_is_weekend ON dim_date(is_weekend);

-- Time dimension indexes
CREATE INDEX IF NOT EXISTS idx_dim_time_hour ON dim_time(hour);
CREATE INDEX IF NOT EXISTS idx_dim_time_period ON dim_time(time_period);
CREATE INDEX IF NOT EXISTS idx_dim_time_peak ON dim_time(is_peak_hour) WHERE is_peak_hour = true;

-- ============================================
-- 3. CREATE INITIAL PARTITIONS (2024-2026)
-- ============================================

-- Function to create monthly partitions
CREATE OR REPLACE FUNCTION create_monthly_partition(
    p_table_name TEXT,
    p_year INTEGER,
    p_month INTEGER
)
RETURNS void AS $$
DECLARE
    v_partition_name TEXT;
    v_start_date DATE;
    v_end_date DATE;
BEGIN
    v_partition_name := p_table_name || '_' || p_year || '_' || LPAD(p_month::TEXT, 2, '0');
    v_start_date := DATE(p_year || '-' || p_month || '-01');
    v_end_date := v_start_date + INTERVAL '1 month';

    EXECUTE format(
        'CREATE TABLE IF NOT EXISTS %I PARTITION OF %I FOR VALUES FROM (%L) TO (%L)',
        v_partition_name, p_table_name, v_start_date, v_end_date
    );

    RAISE NOTICE 'Created partition: %', v_partition_name;
END;
$$ LANGUAGE plpgsql;

-- Create partitions for 2024
DO $$
DECLARE
    v_year INTEGER;
    v_month INTEGER;
BEGIN
    -- Create partitions for 2024, 2025, 2026
    FOR v_year IN 2024..2026 LOOP
        FOR v_month IN 1..12 LOOP
            PERFORM create_monthly_partition('fact_daily_sales', v_year, v_month);
            PERFORM create_monthly_partition('fact_product_sales', v_year, v_month);
            PERFORM create_monthly_partition('fact_staff_sales', v_year, v_month);
            PERFORM create_monthly_partition('fact_brand_sales', v_year, v_month);
            PERFORM create_monthly_partition('fact_hourly_sales', v_year, v_month);
        END LOOP;
    END LOOP;
END $$;

-- ============================================
-- 4. PARTITION MANAGEMENT FUNCTIONS
-- ============================================

-- Function to auto-create future partitions
CREATE OR REPLACE FUNCTION create_future_partitions(
    p_months_ahead INTEGER DEFAULT 3
)
RETURNS void AS $$
DECLARE
    v_date DATE;
    v_year INTEGER;
    v_month INTEGER;
BEGIN
    FOR i IN 1..p_months_ahead LOOP
        v_date := DATE_TRUNC('month', CURRENT_DATE) + (i || ' months')::INTERVAL;
        v_year := EXTRACT(YEAR FROM v_date);
        v_month := EXTRACT(MONTH FROM v_date);

        PERFORM create_monthly_partition('fact_daily_sales', v_year, v_month);
        PERFORM create_monthly_partition('fact_product_sales', v_year, v_month);
        PERFORM create_monthly_partition('fact_staff_sales', v_year, v_month);
        PERFORM create_monthly_partition('fact_brand_sales', v_year, v_month);
        PERFORM create_monthly_partition('fact_hourly_sales', v_year, v_month);
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Function to drop old partitions (data retention)
CREATE OR REPLACE FUNCTION drop_old_partitions(
    p_retention_months INTEGER DEFAULT 24
)
RETURNS void AS $$
DECLARE
    v_cutoff_date DATE;
    v_partition_name TEXT;
    v_table_name TEXT;
BEGIN
    v_cutoff_date := DATE_TRUNC('month', CURRENT_DATE) - (p_retention_months || ' months')::INTERVAL;

    FOR v_table_name IN SELECT unnest(ARRAY[
        'fact_daily_sales',
        'fact_product_sales',
        'fact_staff_sales',
        'fact_brand_sales',
        'fact_hourly_sales'
    ]) LOOP
        FOR v_partition_name IN
            SELECT tablename
            FROM pg_tables
            WHERE schemaname = 'public'
            AND tablename LIKE v_table_name || '_%'
            AND tablename < v_table_name || '_' || TO_CHAR(v_cutoff_date, 'YYYY_MM')
        LOOP
            EXECUTE 'DROP TABLE IF EXISTS ' || v_partition_name || ' CASCADE';
            RAISE NOTICE 'Dropped old partition: %', v_partition_name;
        END LOOP;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 5. MATERIALIZED VIEWS FOR COMMON QUERIES
-- ============================================

-- Top selling products (all-time)
CREATE MATERIALIZED VIEW IF NOT EXISTS mv_top_products AS
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
    SUM(fps.transaction_count) as total_transactions,
    MAX(fps.sale_date) as last_sale_date
FROM fact_product_sales fps
GROUP BY
    fps.tenant_id,
    fps.product_id,
    fps.product_name,
    fps.brand_name,
    fps.category_name;

CREATE UNIQUE INDEX IF NOT EXISTS idx_mv_top_products ON mv_top_products(tenant_id, product_id);
CREATE INDEX IF NOT EXISTS idx_mv_top_products_revenue ON mv_top_products(tenant_id, total_revenue DESC);

-- Brand comparison (all-time)
CREATE MATERIALIZED VIEW IF NOT EXISTS mv_brand_comparison AS
SELECT
    fbs.tenant_id,
    fbs.brand_id,
    fbs.brand_name,
    SUM(fbs.quantity_sold) as total_quantity_sold,
    SUM(fbs.total_revenue) as total_revenue,
    SUM(fbs.total_profit) as total_profit,
    AVG(fbs.average_profit_margin) as avg_profit_margin,
    SUM(fbs.transaction_count) as total_transactions,
    COUNT(DISTINCT fbs.category_id) as category_count,
    MAX(fbs.sale_date) as last_sale_date
FROM fact_brand_sales fbs
GROUP BY
    fbs.tenant_id,
    fbs.brand_id,
    fbs.brand_name;

CREATE UNIQUE INDEX IF NOT EXISTS idx_mv_brand_comparison ON mv_brand_comparison(tenant_id, brand_id);
CREATE INDEX IF NOT EXISTS idx_mv_brand_revenue ON mv_brand_comparison(tenant_id, total_revenue DESC);

-- Staff performance leaderboard
CREATE MATERIALIZED VIEW IF NOT EXISTS mv_staff_leaderboard AS
SELECT
    fss.tenant_id,
    fss.staff_id,
    fss.staff_name,
    SUM(fss.total_transactions) as total_transactions,
    SUM(fss.total_revenue) as total_revenue,
    SUM(fss.total_profit) as total_profit,
    AVG(fss.average_transaction_value) as avg_transaction_value,
    SUM(fss.commission_amount) as total_commission,
    MAX(fss.sale_date) as last_sale_date
FROM fact_staff_sales fss
GROUP BY
    fss.tenant_id,
    fss.staff_id,
    fss.staff_name;

CREATE UNIQUE INDEX IF NOT EXISTS idx_mv_staff_leaderboard ON mv_staff_leaderboard(tenant_id, staff_id);
CREATE INDEX IF NOT EXISTS idx_mv_staff_revenue ON mv_staff_leaderboard(tenant_id, total_revenue DESC);

-- Category performance
CREATE MATERIALIZED VIEW IF NOT EXISTS mv_category_performance AS
SELECT
    fps.tenant_id,
    fps.category_id,
    fps.category_name,
    COUNT(DISTINCT fps.product_id) as unique_products,
    SUM(fps.quantity_sold) as total_quantity_sold,
    SUM(fps.total_revenue) as total_revenue,
    SUM(fps.total_profit) as total_profit,
    AVG(fps.average_profit_margin) as avg_profit_margin,
    SUM(fps.transaction_count) as total_transactions,
    MAX(fps.sale_date) as last_sale_date
FROM fact_product_sales fps
WHERE fps.category_id IS NOT NULL
GROUP BY
    fps.tenant_id,
    fps.category_id,
    fps.category_name;

CREATE UNIQUE INDEX IF NOT EXISTS idx_mv_category_performance ON mv_category_performance(tenant_id, category_id);
CREATE INDEX IF NOT EXISTS idx_mv_category_revenue ON mv_category_performance(tenant_id, total_revenue DESC);

-- Function to refresh all materialized views
CREATE OR REPLACE FUNCTION refresh_analytics_views()
RETURNS void AS $$
BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY mv_top_products;
    REFRESH MATERIALIZED VIEW CONCURRENTLY mv_brand_comparison;
    REFRESH MATERIALIZED VIEW CONCURRENTLY mv_staff_leaderboard;
    REFRESH MATERIALIZED VIEW CONCURRENTLY mv_category_performance;

    RAISE NOTICE 'All analytics materialized views refreshed at %', NOW();
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 6. PERFORMANCE MONITORING VIEWS
-- ============================================

-- View to monitor fact table sizes
CREATE OR REPLACE VIEW v_fact_table_stats AS
SELECT
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS total_size,
    pg_size_pretty(pg_relation_size(schemaname||'.'||tablename)) AS table_size,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename) - pg_relation_size(schemaname||'.'||tablename)) AS index_size,
    n_tup_ins as rows_inserted,
    n_tup_upd as rows_updated,
    n_tup_del as rows_deleted,
    last_vacuum,
    last_autovacuum,
    last_analyze,
    last_autoanalyze
FROM pg_stat_user_tables
WHERE tablename LIKE 'fact_%'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- View to monitor partition information
CREATE OR REPLACE VIEW v_partition_info AS
SELECT
    nmsp_parent.nspname AS parent_schema,
    parent.relname AS parent_table,
    nmsp_child.nspname AS child_schema,
    child.relname AS child_partition,
    pg_size_pretty(pg_total_relation_size(child.oid)) AS partition_size,
    pg_get_expr(child.relpartbound, child.oid) AS partition_bounds
FROM pg_inherits
JOIN pg_class parent ON pg_inherits.inhparent = parent.oid
JOIN pg_class child ON pg_inherits.inhrelid = child.oid
JOIN pg_namespace nmsp_parent ON nmsp_parent.oid = parent.relnamespace
JOIN pg_namespace nmsp_child ON nmsp_child.oid = child.relnamespace
WHERE parent.relname LIKE 'fact_%'
ORDER BY parent.relname, child.relname;

-- ============================================
-- 7. COMMENTS FOR DOCUMENTATION
-- ============================================

COMMENT ON FUNCTION create_monthly_partition IS 'Creates a monthly partition for a partitioned table';
COMMENT ON FUNCTION create_future_partitions IS 'Automatically creates partitions for future months (run monthly via cron)';
COMMENT ON FUNCTION drop_old_partitions IS 'Drops partitions older than retention period (default 24 months)';
COMMENT ON FUNCTION refresh_analytics_views IS 'Refreshes all analytics materialized views (run daily via cron)';
COMMENT ON VIEW v_fact_table_stats IS 'Monitor fact table sizes and statistics';
COMMENT ON VIEW v_partition_info IS 'View partition information and sizes';
