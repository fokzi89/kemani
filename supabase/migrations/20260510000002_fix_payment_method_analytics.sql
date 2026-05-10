-- ============================================
-- Migration: Fix Payment Method Analytics
-- Description: Updates the analytics aggregation function to use 'bank_transfer'
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
        COUNT(*) FILTER (WHERE s.payment_method = 'bank_transfer') as transfer_transactions,
        COALESCE(SUM(s.total_amount) FILTER (WHERE s.payment_method = 'bank_transfer'), 0) as transfer_revenue,
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

END;
$$ LANGUAGE plpgsql;
