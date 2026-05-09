-- ============================================================
-- Migration: Modernize Product Architecture & Cleanup Redundancy
-- ============================================================
-- Description: 
-- 1. Drops redundant stock_quantity column from products table.
-- 2. Drops legacy sync triggers and functions.
-- 3. Modernizes the ecommerce_products view to use the new 
--    multi-branch inventory architecture without grouping errors.
-- ============================================================

-- 1. Drop Legacy Triggers and Functions
DROP TRIGGER IF EXISTS auto_sync_product_stock ON branch_inventory;
DROP FUNCTION IF EXISTS public.sync_product_total_stock();
DROP FUNCTION IF EXISTS public.trigger_sync_product_stock();

-- Also drop the rogue trigger that fires on inventory_transactions INSERT and
-- overwrites ALL batches for a product with the same stock_quantity (no batch filter).
-- This conflicts with the multi-batch receive_purchase_order RPC.
DROP TRIGGER IF EXISTS trg_update_branch_inventory_stock ON inventory_transactions;
DROP FUNCTION IF EXISTS public.update_branch_inventory_stock();

-- 2. Modernize the E-commerce View
-- We drop the view first because CREATE OR REPLACE does not allow changing 
-- the column structure (shape) of an existing view.
DROP VIEW IF EXISTS public.ecommerce_products CASCADE;
CREATE VIEW public.ecommerce_products AS
SELECT
    p.id,
    -- Safely get tenant_id from related tables if it's missing on the master table
    COALESCE(
        (SELECT tenant_id FROM public.product_stock_balance WHERE product_id = p.id LIMIT 1),
        (SELECT tenant_id FROM public.branches LIMIT 1)
    ) as tenant_id,
    p.name,
    p.description,
    p.category,
    p.image_url,
    p.is_active,

    -- Aggregate stock via subquery
    (SELECT COALESCE(SUM(stock_balance), 0)::BIGINT 
     FROM public.product_stock_balance 
     WHERE product_id = p.id) as total_stock,

    -- Count branches via subquery
    (SELECT COUNT(DISTINCT branch_id) 
     FROM public.product_stock_balance 
     WHERE product_id = p.id AND stock_balance > 0) as branch_count,

    -- Collect detailed branch information
    (SELECT COALESCE(
        jsonb_agg(
            jsonb_build_object(
                'branch_id', b.id,
                'branch_name', b.name,
                'branch_address', b.address,
                'branch_phone', b.phone,
                'latitude', b.latitude,
                'longitude', b.longitude,
                'stock_quantity', psb.stock_balance,
                'selling_price', (SELECT MIN(selling_price) FROM public.branch_inventory bi WHERE bi.product_id = p.id AND bi.branch_id = b.id),
                'in_stock', psb.stock_balance > 0
            ) ORDER BY b.name
        ), 
        '[]'::jsonb
     )
     FROM public.product_stock_balance psb
     JOIN public.branches b ON psb.branch_id = b.id
     WHERE psb.product_id = p.id AND b.deleted_at IS NULL
    ) as branches,

    -- Min and max price via subqueries
    COALESCE((SELECT MIN(selling_price) FROM public.branch_inventory WHERE product_id = p.id AND is_active = true), 0) as min_price,
    COALESCE((SELECT MAX(selling_price) FROM public.branch_inventory WHERE product_id = p.id AND is_active = true), 0) as max_price,

    p.created_at,
    p.updated_at
FROM public.products p
WHERE p.deleted_at IS NULL
  AND p.is_active = TRUE;

-- 3. Update the E-commerce helper function
CREATE OR REPLACE FUNCTION public.get_ecommerce_products(
    p_tenant_id UUID,
    p_category VARCHAR DEFAULT NULL,
    p_branch_id UUID DEFAULT NULL,
    p_latitude DECIMAL DEFAULT NULL,
    p_longitude DECIMAL DEFAULT NULL,
    p_max_distance_km DECIMAL DEFAULT NULL,
    p_in_stock_only BOOLEAN DEFAULT TRUE
)
RETURNS TABLE (
    product_id UUID,
    product_name VARCHAR,
    description TEXT,
    category VARCHAR,
    unit_price DECIMAL,
    image_url TEXT,
    total_stock BIGINT,
    branch_count BIGINT,
    branches JSONB,
    min_price DECIMAL,
    max_price DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        ep.id,
        ep.name,
        ep.description,
        ep.category,
        ep.min_price as unit_price, -- Backward compatibility
        ep.image_url,
        ep.total_stock,
        ep.branch_count,
        ep.branches,
        ep.min_price,
        ep.max_price
    FROM public.ecommerce_products ep
    WHERE ep.tenant_id = p_tenant_id

    -- Category filter
    AND (p_category IS NULL OR ep.category = p_category)

    -- Stock filter
    AND (NOT p_in_stock_only OR ep.total_stock > 0)

    -- Branch filter
    AND (p_branch_id IS NULL OR EXISTS (
        SELECT 1 FROM jsonb_array_elements(ep.branches) AS branch
        WHERE (branch->>'branch_id')::UUID = p_branch_id
    ))

    -- Location filter
    AND (
        p_latitude IS NULL OR p_longitude IS NULL OR p_max_distance_km IS NULL
        OR EXISTS (
            SELECT 1 FROM jsonb_array_elements(ep.branches) AS branch
            WHERE (branch->>'latitude') IS NOT NULL
            AND (branch->>'longitude') IS NOT NULL
            AND (
                ST_DWithin(
                    ST_MakePoint((branch->>'longitude')::DECIMAL, (branch->>'latitude')::DECIMAL)::geography,
                    ST_MakePoint(p_longitude, p_latitude)::geography,
                    p_max_distance_km * 1000
                )
            )
        )
    )

    ORDER BY ep.name;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Drop Redundant Columns from products table
-- We do this LAST to ensure views have been updated first.
ALTER TABLE public.products DROP COLUMN IF EXISTS stock_quantity;
ALTER TABLE public.products DROP COLUMN IF EXISTS branch_id;
ALTER TABLE public.products DROP COLUMN IF EXISTS low_stock_threshold;
ALTER TABLE public.products DROP COLUMN IF EXISTS expiry_date;
ALTER TABLE public.products DROP COLUMN IF EXISTS cost_price;
ALTER TABLE public.products DROP COLUMN IF EXISTS unit_price;

-- 5. Final Audit Note
COMMENT ON VIEW ecommerce_products IS 'Aggregated product view for e-commerce storefront, modernized to use subqueries for maximum compatibility.';
