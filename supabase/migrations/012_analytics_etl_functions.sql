-- ============================================
-- Migration: Analytics ETL Functions
-- Description: Functions to aggregate transactional data into analytics tables
-- Created: 2026-01-22
-- ============================================

-- ============================================
-- 1. AGGREGATE DAILY SALES FUNCTION
-- ============================================

CREATE OR REPLACE FUNCTION aggregate_daily_sales(p_date DATE)
RETURNS void AS $$
DECLARE
    v_date_key INTEGER;
    v_rows_affected INTEGER;
BEGIN
    -- Get date key
    SELECT date_key INTO v_date_key
    FROM dim_date
    WHERE date_value = p_date;

    IF v_date_key IS NULL THEN
        RAISE EXCEPTION 'Date % not found in dim_date. Please populate dimension tables first.', p_date;
    END IF;

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
        COALESCE(SUM(si.quantity), 0) as total_items_sold,
        COALESCE(SUM(s.total_amount), 0) as total_revenue,
        COALESCE(SUM(si.total_cost), 0) as total_cost,
        COALESCE(SUM(si.gross_profit), 0) as total_profit,
        COALESCE(AVG(s.total_amount), 0) as average_transaction_value,
        COALESCE(AVG(si.profit_margin), 0) as average_profit_margin,
        COUNT(DISTINCT s.customer_id) FILTER (WHERE s.customer_id IS NOT NULL) as unique_customers,
        COUNT(DISTINCT s.customer_id) FILTER (WHERE s.customer_type = 'new') as new_customers,
        COUNT(*) FILTER (WHERE s.payment_method = 'cash') as cash_transactions,
        COALESCE(SUM(s.total_amount) FILTER (WHERE s.payment_method = 'cash'), 0) as cash_revenue,
        COUNT(*) FILTER (WHERE s.payment_method = 'card') as card_transactions,
        COALESCE(SUM(s.total_amount) FILTER (WHERE s.payment_method = 'card'), 0) as card_revenue,
        COUNT(*) FILTER (WHERE s.payment_method = 'transfer') as transfer_transactions,
        COALESCE(SUM(s.total_amount) FILTER (WHERE s.payment_method = 'transfer'), 0) as transfer_revenue,
        COUNT(*) FILTER (WHERE s.sale_status = 'void') as void_transactions,
        COALESCE(SUM(s.total_amount) FILTER (WHERE s.sale_status = 'void'), 0) as void_amount,
        COUNT(*) FILTER (WHERE s.sale_status = 'refunded') as refund_transactions,
        COALESCE(SUM(s.total_amount) FILTER (WHERE s.sale_status = 'refunded'), 0) as refund_amount
    FROM sales s
    LEFT JOIN sale_items si ON si.sale_id = s.id
    WHERE s.sale_date = p_date
      AND s.sale_status NOT IN ('void', 'refunded')
    GROUP BY s.tenant_id, s.branch_id
    ON CONFLICT (tenant_id, branch_id, date_key, sale_date)
    DO UPDATE SET
        total_transactions = EXCLUDED.total_transactions,
        total_items_sold = EXCLUDED.total_items_sold,
        total_revenue = EXCLUDED.total_revenue,
        total_cost = EXCLUDED.total_cost,
        total_profit = EXCLUDED.total_profit,
        average_transaction_value = EXCLUDED.average_transaction_value,
        average_profit_margin = EXCLUDED.average_profit_margin,
        unique_customers = EXCLUDED.unique_customers,
        new_customers = EXCLUDED.new_customers,
        cash_transactions = EXCLUDED.cash_transactions,
        cash_revenue = EXCLUDED.cash_revenue,
        card_transactions = EXCLUDED.card_transactions,
        card_revenue = EXCLUDED.card_revenue,
        transfer_transactions = EXCLUDED.transfer_transactions,
        transfer_revenue = EXCLUDED.transfer_revenue,
        void_transactions = EXCLUDED.void_transactions,
        void_amount = EXCLUDED.void_amount,
        refund_transactions = EXCLUDED.refund_transactions,
        refund_amount = EXCLUDED.refund_amount,
        updated_at = NOW();

    GET DIAGNOSTICS v_rows_affected = ROW_COUNT;
    RAISE NOTICE 'Aggregated % rows into fact_daily_sales for date %', v_rows_affected, p_date;

END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 2. AGGREGATE PRODUCT SALES FUNCTION
-- ============================================

CREATE OR REPLACE FUNCTION aggregate_product_sales(p_date DATE)
RETURNS void AS $$
DECLARE
    v_date_key INTEGER;
    v_rows_affected INTEGER;
BEGIN
    -- Get date key
    SELECT date_key INTO v_date_key
    FROM dim_date
    WHERE date_value = p_date;

    IF v_date_key IS NULL THEN
        RAISE EXCEPTION 'Date % not found in dim_date', p_date;
    END IF;

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
        MAX(si.product_name) as product_name,
        MAX(si.product_sku) as product_sku,
        MAX(si.brand_name) as brand_name,
        MAX(si.category_name) as category_name,
        COALESCE(SUM(si.quantity), 0) as quantity_sold,
        COALESCE(SUM(si.line_total), 0) as total_revenue,
        COALESCE(SUM(si.total_cost), 0) as total_cost,
        COALESCE(SUM(si.gross_profit), 0) as total_profit,
        COALESCE(AVG(si.unit_price), 0) as average_unit_price,
        COALESCE(AVG(si.profit_margin), 0) as average_profit_margin,
        COUNT(DISTINCT s.id) as transaction_count,
        COALESCE(SUM(si.discount_amount), 0) as total_discount_amount,
        COALESCE(AVG(si.discount_percentage), 0) as average_discount_percentage
    FROM sale_items si
    JOIN sales s ON s.id = si.sale_id
    WHERE s.sale_date = p_date
      AND s.sale_status NOT IN ('void', 'refunded')
    GROUP BY
        si.tenant_id, s.branch_id, si.product_id,
        si.brand_id, si.category_id
    ON CONFLICT (tenant_id, branch_id, date_key, product_id, sale_date)
    DO UPDATE SET
        quantity_sold = EXCLUDED.quantity_sold,
        total_revenue = EXCLUDED.total_revenue,
        total_cost = EXCLUDED.total_cost,
        total_profit = EXCLUDED.total_profit,
        average_unit_price = EXCLUDED.average_unit_price,
        average_profit_margin = EXCLUDED.average_profit_margin,
        transaction_count = EXCLUDED.transaction_count,
        total_discount_amount = EXCLUDED.total_discount_amount,
        average_discount_percentage = EXCLUDED.average_discount_percentage,
        updated_at = NOW();

    GET DIAGNOSTICS v_rows_affected = ROW_COUNT;
    RAISE NOTICE 'Aggregated % rows into fact_product_sales for date %', v_rows_affected, p_date;

END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 3. AGGREGATE STAFF SALES FUNCTION
-- ============================================

CREATE OR REPLACE FUNCTION aggregate_staff_sales(p_date DATE)
RETURNS void AS $$
DECLARE
    v_date_key INTEGER;
    v_rows_affected INTEGER;
BEGIN
    -- Get date key
    SELECT date_key INTO v_date_key
    FROM dim_date
    WHERE date_value = p_date;

    IF v_date_key IS NULL THEN
        RAISE EXCEPTION 'Date % not found in dim_date', p_date;
    END IF;

    -- Aggregate cashier sales
    INSERT INTO fact_staff_sales (
        tenant_id, branch_id, date_key, sale_date,
        staff_id, staff_role, staff_name,
        total_transactions, total_items_sold, total_revenue,
        total_profit, average_transaction_value,
        commission_eligible_sales, commission_amount
    )
    SELECT
        s.tenant_id,
        s.branch_id,
        v_date_key,
        p_date,
        s.cashier_id as staff_id,
        'cashier' as staff_role,
        COALESCE(u.full_name, u.email) as staff_name,
        COUNT(DISTINCT s.id) as total_transactions,
        COALESCE(SUM(si.quantity), 0) as total_items_sold,
        COALESCE(SUM(s.total_amount), 0) as total_revenue,
        COALESCE(SUM(si.gross_profit), 0) as total_profit,
        COALESCE(AVG(s.total_amount), 0) as average_transaction_value,
        0 as commission_eligible_sales,
        0 as commission_amount
    FROM sales s
    LEFT JOIN sale_items si ON si.sale_id = s.id
    LEFT JOIN users u ON u.id = s.cashier_id
    WHERE s.sale_date = p_date
      AND s.sale_status NOT IN ('void', 'refunded')
    GROUP BY s.tenant_id, s.branch_id, s.cashier_id, u.full_name, u.email
    ON CONFLICT (tenant_id, branch_id, date_key, staff_id, staff_role, sale_date)
    DO UPDATE SET
        total_transactions = EXCLUDED.total_transactions,
        total_items_sold = EXCLUDED.total_items_sold,
        total_revenue = EXCLUDED.total_revenue,
        total_profit = EXCLUDED.total_profit,
        average_transaction_value = EXCLUDED.average_transaction_value,
        updated_at = NOW();

    GET DIAGNOSTICS v_rows_affected = ROW_COUNT;
    RAISE NOTICE 'Aggregated % cashier rows into fact_staff_sales for date %', v_rows_affected, p_date;

    -- Aggregate sales attendant sales (if different from cashier)
    INSERT INTO fact_staff_sales (
        tenant_id, branch_id, date_key, sale_date,
        staff_id, staff_role, staff_name,
        total_transactions, total_items_sold, total_revenue,
        total_profit, average_transaction_value,
        commission_eligible_sales, commission_amount
    )
    SELECT
        s.tenant_id,
        s.branch_id,
        v_date_key,
        p_date,
        s.sales_attendant_id as staff_id,
        'sales_attendant' as staff_role,
        COALESCE(u.full_name, u.email) as staff_name,
        COUNT(DISTINCT s.id) as total_transactions,
        COALESCE(SUM(si.quantity), 0) as total_items_sold,
        COALESCE(SUM(s.total_amount), 0) as total_revenue,
        COALESCE(SUM(si.gross_profit), 0) as total_profit,
        COALESCE(AVG(s.total_amount), 0) as average_transaction_value,
        COALESCE(SUM(s.total_amount), 0) as commission_eligible_sales,
        COALESCE(SUM(s.total_amount) * 0.05, 0) as commission_amount -- 5% commission
    FROM sales s
    LEFT JOIN sale_items si ON si.sale_id = s.id
    LEFT JOIN users u ON u.id = s.sales_attendant_id
    WHERE s.sale_date = p_date
      AND s.sales_attendant_id IS NOT NULL
      AND s.sale_status NOT IN ('void', 'refunded')
    GROUP BY s.tenant_id, s.branch_id, s.sales_attendant_id, u.full_name, u.email
    ON CONFLICT (tenant_id, branch_id, date_key, staff_id, staff_role, sale_date)
    DO UPDATE SET
        total_transactions = EXCLUDED.total_transactions,
        total_items_sold = EXCLUDED.total_items_sold,
        total_revenue = EXCLUDED.total_revenue,
        total_profit = EXCLUDED.total_profit,
        average_transaction_value = EXCLUDED.average_transaction_value,
        commission_eligible_sales = EXCLUDED.commission_eligible_sales,
        commission_amount = EXCLUDED.commission_amount,
        updated_at = NOW();

    GET DIAGNOSTICS v_rows_affected = ROW_COUNT;
    RAISE NOTICE 'Aggregated % sales attendant rows into fact_staff_sales for date %', v_rows_affected, p_date;

END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 4. AGGREGATE BRAND SALES FUNCTION
-- ============================================

CREATE OR REPLACE FUNCTION aggregate_brand_sales(p_date DATE)
RETURNS void AS $$
DECLARE
    v_date_key INTEGER;
    v_rows_affected INTEGER;
BEGIN
    -- Get date key
    SELECT date_key INTO v_date_key
    FROM dim_date
    WHERE date_value = p_date;

    IF v_date_key IS NULL THEN
        RAISE EXCEPTION 'Date % not found in dim_date', p_date;
    END IF;

    -- Aggregate to fact_brand_sales
    INSERT INTO fact_brand_sales (
        tenant_id, branch_id, date_key, sale_date,
        brand_id, category_id,
        brand_name, category_name,
        unique_products_sold, quantity_sold,
        total_revenue, total_cost, total_profit,
        average_profit_margin, transaction_count
    )
    SELECT
        si.tenant_id,
        s.branch_id,
        v_date_key,
        p_date,
        si.brand_id,
        si.category_id,
        MAX(si.brand_name) as brand_name,
        MAX(si.category_name) as category_name,
        COUNT(DISTINCT si.product_id) as unique_products_sold,
        COALESCE(SUM(si.quantity), 0) as quantity_sold,
        COALESCE(SUM(si.line_total), 0) as total_revenue,
        COALESCE(SUM(si.total_cost), 0) as total_cost,
        COALESCE(SUM(si.gross_profit), 0) as total_profit,
        COALESCE(AVG(si.profit_margin), 0) as average_profit_margin,
        COUNT(DISTINCT s.id) as transaction_count
    FROM sale_items si
    JOIN sales s ON s.id = si.sale_id
    WHERE s.sale_date = p_date
      AND si.brand_id IS NOT NULL
      AND s.sale_status NOT IN ('void', 'refunded')
    GROUP BY
        si.tenant_id, s.branch_id,
        si.brand_id, si.category_id
    ON CONFLICT (tenant_id, branch_id, date_key, brand_id, sale_date)
    DO UPDATE SET
        unique_products_sold = EXCLUDED.unique_products_sold,
        quantity_sold = EXCLUDED.quantity_sold,
        total_revenue = EXCLUDED.total_revenue,
        total_cost = EXCLUDED.total_cost,
        total_profit = EXCLUDED.total_profit,
        average_profit_margin = EXCLUDED.average_profit_margin,
        transaction_count = EXCLUDED.transaction_count,
        updated_at = NOW();

    GET DIAGNOSTICS v_rows_affected = ROW_COUNT;
    RAISE NOTICE 'Aggregated % rows into fact_brand_sales for date %', v_rows_affected, p_date;

END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 5. AGGREGATE HOURLY SALES FUNCTION
-- ============================================

CREATE OR REPLACE FUNCTION aggregate_hourly_sales(p_date DATE)
RETURNS void AS $$
DECLARE
    v_date_key INTEGER;
    v_rows_affected INTEGER;
BEGIN
    -- Get date key
    SELECT date_key INTO v_date_key
    FROM dim_date
    WHERE date_value = p_date;

    IF v_date_key IS NULL THEN
        RAISE EXCEPTION 'Date % not found in dim_date', p_date;
    END IF;

    -- Aggregate to fact_hourly_sales
    INSERT INTO fact_hourly_sales (
        tenant_id, branch_id, date_key, time_key, sale_date, hour,
        total_transactions, total_revenue, average_transaction_value
    )
    SELECT
        s.tenant_id,
        s.branch_id,
        v_date_key,
        dt.time_key,
        p_date,
        EXTRACT(HOUR FROM s.sale_time)::INTEGER as hour,
        COUNT(DISTINCT s.id) as total_transactions,
        COALESCE(SUM(s.total_amount), 0) as total_revenue,
        COALESCE(AVG(s.total_amount), 0) as average_transaction_value
    FROM sales s
    JOIN dim_time dt ON dt.hour = EXTRACT(HOUR FROM s.sale_time)
                    AND dt.minute = 0
                    AND dt.second = 0
    WHERE s.sale_date = p_date
      AND s.sale_status NOT IN ('void', 'refunded')
    GROUP BY
        s.tenant_id, s.branch_id,
        EXTRACT(HOUR FROM s.sale_time),
        dt.time_key
    ON CONFLICT (tenant_id, branch_id, date_key, time_key, sale_date)
    DO UPDATE SET
        total_transactions = EXCLUDED.total_transactions,
        total_revenue = EXCLUDED.total_revenue,
        average_transaction_value = EXCLUDED.average_transaction_value,
        updated_at = NOW();

    GET DIAGNOSTICS v_rows_affected = ROW_COUNT;
    RAISE NOTICE 'Aggregated % rows into fact_hourly_sales for date %', v_rows_affected, p_date;

END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 6. MASTER AGGREGATION FUNCTION
-- ============================================

CREATE OR REPLACE FUNCTION aggregate_all_analytics(p_date DATE)
RETURNS void AS $$
BEGIN
    RAISE NOTICE 'Starting analytics aggregation for date: %', p_date;

    -- Run all aggregation functions
    PERFORM aggregate_daily_sales(p_date);
    PERFORM aggregate_product_sales(p_date);
    PERFORM aggregate_staff_sales(p_date);
    PERFORM aggregate_brand_sales(p_date);
    PERFORM aggregate_hourly_sales(p_date);

    RAISE NOTICE 'Completed analytics aggregation for date: %', p_date;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 7. BACKFILL FUNCTION (For Historical Data)
-- ============================================

CREATE OR REPLACE FUNCTION backfill_analytics(
    p_start_date DATE,
    p_end_date DATE
)
RETURNS void AS $$
DECLARE
    v_current_date DATE;
BEGIN
    v_current_date := p_start_date;

    WHILE v_current_date <= p_end_date LOOP
        RAISE NOTICE 'Processing date: %', v_current_date;

        -- Run aggregation for this date
        PERFORM aggregate_all_analytics(v_current_date);

        -- Move to next day
        v_current_date := v_current_date + INTERVAL '1 day';
    END LOOP;

    RAISE NOTICE 'Backfill completed from % to %', p_start_date, p_end_date;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 8. TRIGGER TO AUTO-POPULATE SALE ITEM DETAILS
-- ============================================

-- Function to populate sale_item product details on insert
CREATE OR REPLACE FUNCTION populate_sale_item_details()
RETURNS TRIGGER AS $$
DECLARE
    v_product RECORD;
BEGIN
    -- Get product details
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
    NEW.product_name := v_product.name;
    NEW.product_sku := v_product.sku;
    NEW.brand_id := v_product.brand_id;
    NEW.brand_name := v_product.brand_name;
    NEW.category_id := v_product.category_id;
    NEW.category_name := v_product.category_name;
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

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger
DROP TRIGGER IF EXISTS trg_populate_sale_item_details ON sale_items;
CREATE TRIGGER trg_populate_sale_item_details
    BEFORE INSERT ON sale_items
    FOR EACH ROW
    EXECUTE FUNCTION populate_sale_item_details();

-- ============================================
-- 9. TRIGGER TO AUTO-POPULATE SALE DATE/TIME
-- ============================================

-- Function to populate sale date and time on insert
CREATE OR REPLACE FUNCTION populate_sale_datetime()
RETURNS TRIGGER AS $$
BEGIN
    -- Set sale_date and sale_time from completed_at if not provided
    IF NEW.sale_date IS NULL THEN
        NEW.sale_date := DATE(NEW.completed_at);
    END IF;

    IF NEW.sale_time IS NULL THEN
        NEW.sale_time := NEW.completed_at::TIME;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger
DROP TRIGGER IF EXISTS trg_populate_sale_datetime ON sales;
CREATE TRIGGER trg_populate_sale_datetime
    BEFORE INSERT ON sales
    FOR EACH ROW
    EXECUTE FUNCTION populate_sale_datetime();

-- ============================================
-- 10. COMMENTS FOR DOCUMENTATION
-- ============================================

COMMENT ON FUNCTION aggregate_daily_sales IS 'Aggregates sales data into fact_daily_sales for a specific date';
COMMENT ON FUNCTION aggregate_product_sales IS 'Aggregates product-level sales into fact_product_sales for a specific date';
COMMENT ON FUNCTION aggregate_staff_sales IS 'Aggregates staff performance into fact_staff_sales for a specific date';
COMMENT ON FUNCTION aggregate_brand_sales IS 'Aggregates brand performance into fact_brand_sales for a specific date';
COMMENT ON FUNCTION aggregate_hourly_sales IS 'Aggregates hourly sales patterns into fact_hourly_sales for a specific date';
COMMENT ON FUNCTION aggregate_all_analytics IS 'Master function to run all analytics aggregations for a specific date (run daily via cron)';
COMMENT ON FUNCTION backfill_analytics IS 'Backfill analytics data for a date range (useful for historical data)';
COMMENT ON FUNCTION populate_sale_item_details IS 'Trigger function to auto-populate product snapshot details in sale_items';
COMMENT ON FUNCTION populate_sale_datetime IS 'Trigger function to auto-populate sale_date and sale_time in sales';
