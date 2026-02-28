-- Analytics RPC Functions for Product Sales Analytics
-- These functions are used by the analytics service to query sales data

-- ============================================================================
-- Function: get_top_products_by_volume
-- Description: Returns top selling products ranked by total quantity sold
-- ============================================================================
CREATE OR REPLACE FUNCTION get_top_products_by_volume(
  start_date timestamptz,
  end_date timestamptz,
  product_limit int DEFAULT 10
)
RETURNS TABLE (
  product_id uuid,
  product_name text,
  total_quantity bigint,
  total_revenue numeric,
  profit numeric,
  trend text
)
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
  current_user_tenant_id uuid;
BEGIN
  -- Get the tenant_id from the authenticated user's metadata
  current_user_tenant_id := (auth.jwt() -> 'user_metadata' ->> 'tenant_id')::uuid;

  IF current_user_tenant_id IS NULL THEN
    RAISE EXCEPTION 'No tenant_id found for user';
  END IF;

  RETURN QUERY
  SELECT
    p.id AS product_id,
    p.name AS product_name,
    COALESCE(SUM(si.quantity), 0) AS total_quantity,
    COALESCE(SUM(si.quantity * si.unit_price), 0) AS total_revenue,
    COALESCE(SUM(si.quantity * (si.unit_price - COALESCE(p.cost_price, 0))), 0) AS profit,
    'stable'::text AS trend  -- TODO: Calculate actual trend based on previous period
  FROM products p
  LEFT JOIN sale_items si ON si.product_id = p.id
  LEFT JOIN sales s ON s.id = si.sale_id
  WHERE p.tenant_id = current_user_tenant_id
    AND p.is_active = true
    AND s.created_at >= start_date
    AND s.created_at <= end_date
  GROUP BY p.id, p.name
  ORDER BY total_quantity DESC
  LIMIT product_limit;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION get_top_products_by_volume(timestamptz, timestamptz, int) TO authenticated;

-- ============================================================================
-- Function: get_top_products_by_value
-- Description: Returns top selling products ranked by total revenue
-- ============================================================================
CREATE OR REPLACE FUNCTION get_top_products_by_value(
  start_date timestamptz,
  end_date timestamptz,
  product_limit int DEFAULT 10
)
RETURNS TABLE (
  product_id uuid,
  product_name text,
  total_quantity bigint,
  total_revenue numeric,
  profit numeric,
  trend text
)
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
  current_user_tenant_id uuid;
BEGIN
  -- Get the tenant_id from the authenticated user's metadata
  current_user_tenant_id := (auth.jwt() -> 'user_metadata' ->> 'tenant_id')::uuid;

  IF current_user_tenant_id IS NULL THEN
    RAISE EXCEPTION 'No tenant_id found for user';
  END IF;

  RETURN QUERY
  SELECT
    p.id AS product_id,
    p.name AS product_name,
    COALESCE(SUM(si.quantity), 0) AS total_quantity,
    COALESCE(SUM(si.quantity * si.unit_price), 0) AS total_revenue,
    COALESCE(SUM(si.quantity * (si.unit_price - COALESCE(p.cost_price, 0))), 0) AS profit,
    'stable'::text AS trend  -- TODO: Calculate actual trend based on previous period
  FROM products p
  LEFT JOIN sale_items si ON si.product_id = p.id
  LEFT JOIN sales s ON s.id = si.sale_id
  WHERE p.tenant_id = current_user_tenant_id
    AND p.is_active = true
    AND s.created_at >= start_date
    AND s.created_at <= end_date
  GROUP BY p.id, p.name
  ORDER BY total_revenue DESC
  LIMIT product_limit;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION get_top_products_by_value(timestamptz, timestamptz, int) TO authenticated;

-- ============================================================================
-- Function: get_product_sales_trend
-- Description: Returns sales trend data for a specific product over time
-- ============================================================================
CREATE OR REPLACE FUNCTION get_product_sales_trend(
  p_product_id uuid,
  start_date timestamptz,
  end_date timestamptz,
  period_type text DEFAULT 'daily' -- 'daily', 'weekly', 'monthly', 'quarterly', 'yearly'
)
RETURNS TABLE (
  period_start timestamptz,
  period_end timestamptz,
  total_quantity bigint,
  total_revenue numeric,
  period_label text
)
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
  current_user_tenant_id uuid;
BEGIN
  -- Get the tenant_id from the authenticated user's metadata
  current_user_tenant_id := (auth.jwt() -> 'user_metadata' ->> 'tenant_id')::uuid;

  IF current_user_tenant_id IS NULL THEN
    RAISE EXCEPTION 'No tenant_id found for user';
  END IF;

  -- Verify product belongs to user's tenant
  IF NOT EXISTS (
    SELECT 1 FROM products
    WHERE id = p_product_id
    AND tenant_id = current_user_tenant_id
  ) THEN
    RAISE EXCEPTION 'Product not found or access denied';
  END IF;

  -- Return data grouped by the specified period
  RETURN QUERY
  WITH date_series AS (
    SELECT
      CASE
        WHEN period_type = 'daily' THEN date_trunc('day', s.created_at)
        WHEN period_type = 'weekly' THEN date_trunc('week', s.created_at)
        WHEN period_type = 'monthly' THEN date_trunc('month', s.created_at)
        WHEN period_type = 'quarterly' THEN date_trunc('quarter', s.created_at)
        WHEN period_type = 'yearly' THEN date_trunc('year', s.created_at)
        ELSE date_trunc('day', s.created_at)
      END AS period_start,
      si.quantity,
      si.unit_price
    FROM sales s
    JOIN sale_items si ON si.sale_id = s.id
    WHERE si.product_id = p_product_id
      AND s.created_at >= start_date
      AND s.created_at <= end_date
  )
  SELECT
    period_start,
    CASE
      WHEN period_type = 'daily' THEN period_start + interval '1 day' - interval '1 second'
      WHEN period_type = 'weekly' THEN period_start + interval '1 week' - interval '1 second'
      WHEN period_type = 'monthly' THEN period_start + interval '1 month' - interval '1 second'
      WHEN period_type = 'quarterly' THEN period_start + interval '3 months' - interval '1 second'
      WHEN period_type = 'yearly' THEN period_start + interval '1 year' - interval '1 second'
      ELSE period_start + interval '1 day' - interval '1 second'
    END AS period_end,
    COALESCE(SUM(quantity), 0) AS total_quantity,
    COALESCE(SUM(quantity * unit_price), 0) AS total_revenue,
    to_char(period_start, 'YYYY-MM-DD') AS period_label
  FROM date_series
  GROUP BY period_start
  ORDER BY period_start;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION get_product_sales_trend(uuid, timestamptz, timestamptz, text) TO authenticated;

-- ============================================================================
-- Function: get_sales_by_category
-- Description: Returns sales aggregated by product category
-- ============================================================================
CREATE OR REPLACE FUNCTION get_sales_by_category(
  start_date timestamptz,
  end_date timestamptz
)
RETURNS TABLE (
  category text,
  total_quantity bigint,
  total_revenue numeric,
  product_count bigint
)
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
  current_user_tenant_id uuid;
BEGIN
  -- Get the tenant_id from the authenticated user's metadata
  current_user_tenant_id := (auth.jwt() -> 'user_metadata' ->> 'tenant_id')::uuid;

  IF current_user_tenant_id IS NULL THEN
    RAISE EXCEPTION 'No tenant_id found for user';
  END IF;

  RETURN QUERY
  SELECT
    COALESCE(p.category, 'Uncategorized') AS category,
    COALESCE(SUM(si.quantity), 0) AS total_quantity,
    COALESCE(SUM(si.quantity * si.unit_price), 0) AS total_revenue,
    COUNT(DISTINCT p.id) AS product_count
  FROM products p
  LEFT JOIN sale_items si ON si.product_id = p.id
  LEFT JOIN sales s ON s.id = si.sale_id
  WHERE p.tenant_id = current_user_tenant_id
    AND p.is_active = true
    AND s.created_at >= start_date
    AND s.created_at <= end_date
  GROUP BY COALESCE(p.category, 'Uncategorized')
  ORDER BY total_revenue DESC;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION get_sales_by_category(timestamptz, timestamptz) TO authenticated;

-- ============================================================================
-- Comments for documentation
-- ============================================================================
COMMENT ON FUNCTION get_top_products_by_volume IS 'Returns top selling products ranked by total quantity sold within a date range. Tenant-scoped.';
COMMENT ON FUNCTION get_top_products_by_value IS 'Returns top selling products ranked by total revenue within a date range. Tenant-scoped.';
COMMENT ON FUNCTION get_product_sales_trend IS 'Returns sales trend data for a specific product over time, grouped by period (daily/weekly/monthly/quarterly/yearly). Tenant-scoped.';
COMMENT ON FUNCTION get_sales_by_category IS 'Returns sales aggregated by product category. Tenant-scoped.';
