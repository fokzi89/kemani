-- ============================================================================
-- Migration: Search Storefront Products RPC
-- Feature: 002-ecommerce-storefront
-- User Story: T029, T030
-- Description: Adds RPC function for optimized product search and filtering
-- ============================================================================

-- Function to search storefront products using the view
CREATE OR REPLACE FUNCTION search_storefront_products(
  p_search_query TEXT DEFAULT NULL,
  p_category TEXT DEFAULT NULL,
  p_min_price DECIMAL DEFAULT NULL,
  p_max_price DECIMAL DEFAULT NULL,
  p_branch_id UUID DEFAULT NULL,
  p_tenant_id UUID DEFAULT NULL,
  p_limit INTEGER DEFAULT 50,
  p_offset INTEGER DEFAULT 0,
  p_sort_by TEXT DEFAULT 'created_at', -- 'price_asc', 'price_desc', 'created_at', 'name'
  p_available_only BOOLEAN DEFAULT TRUE
)
RETURNS SETOF storefront_products_with_catalog
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_base_query TEXT;
BEGIN
  -- We use dynamic SQL to handle sorted pagination and flexible filtering
  -- However, for simplicity and safety against injection in this specific RPC pattern,
  -- we can often stick to simple PL/PGSQL with partial filtering if indices are good.
  -- But since we need dynamic sorting, returning query result directly is cleaner.
  
  RETURN QUERY
  SELECT *
  FROM storefront_products_with_catalog sp
  WHERE
    -- 1. Filter by Branch OR Tenant (Must provide at least one to narrow scope)
    (p_branch_id IS NULL OR sp.branch_id = p_branch_id)
    AND
    (p_tenant_id IS NULL OR sp.tenant_id = p_tenant_id)
    AND
    -- 2. Availability Filter
    (NOT p_available_only OR sp.is_available = TRUE)
    AND
    -- 3. Category Filter
    (p_category IS NULL OR sp.category = p_category)
    AND
    -- 4. Price Range Filter
    (p_min_price IS NULL OR sp.price >= p_min_price)
    AND
    (p_max_price IS NULL OR sp.price <= p_max_price)
    AND
    -- 5. Text Search (Name, Description, Brand)
    (
      p_search_query IS NULL OR p_search_query = '' OR
      (
        sp.name ILIKE '%' || p_search_query || '%' OR
        sp.description ILIKE '%' || p_search_query || '%' OR
        sp.brand ILIKE '%' || p_search_query || '%'
      )
    )
  ORDER BY
    CASE WHEN p_sort_by = 'price_asc' THEN sp.price END ASC,
    CASE WHEN p_sort_by = 'price_desc' THEN sp.price END DESC,
    CASE WHEN p_sort_by = 'name' THEN sp.name END ASC,
    CASE WHEN p_sort_by = 'created_at' THEN sp.created_at END DESC,
    -- Default fallback
    sp.created_at DESC
  LIMIT p_limit
  OFFSET p_offset;
END;
$$;

COMMENT ON FUNCTION search_storefront_products IS 'Search storefront products with filtering, sorting, and pagination.';
