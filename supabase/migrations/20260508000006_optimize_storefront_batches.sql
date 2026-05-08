-- ============================================================
-- Migration: Optimize Storefront for Batch Tracking
-- ============================================================
-- Description: Updates the ecommerce_products view to aggregate 
--              multiple inventory batches into a single customer 
--              offering with the best price.
-- ============================================================

-- Drop the existing view first to allow changing the column structure
DROP VIEW IF EXISTS ecommerce_products CASCADE;

CREATE OR REPLACE VIEW ecommerce_products AS
SELECT
    p.id,
    bi.tenant_id,
    p.name,
    p.description,
    p.category,
    
    -- Display the lowest available selling price among all batches
    MIN(bi.selling_price) as selling_price,
    
    -- Display the lowest sale price if available
    MIN(COALESCE(sp.sale_price, bi.sale_price)) as sale_price,
    
    p.image_url,
    p.is_active,

    -- Aggregate total stock across all batches and all branches for this tenant
    COALESCE(SUM(bi.stock_quantity), 0) as total_stock,

    -- Count how many unique branches carry this product
    COUNT(DISTINCT bi.branch_id) as branch_count,

    -- Roll up branch details while summing stock per branch
    COALESCE(
        (
            SELECT jsonb_agg(branch_data)
            FROM (
                SELECT 
                    b.id as branch_id,
                    b.name as branch_name,
                    b.address as branch_address,
                    SUM(bi2.stock_quantity) as stock_quantity,
                    SUM(bi2.stock_quantity) > 0 as in_stock,
                    MIN(bi2.selling_price) as selling_price,
                    MIN(COALESCE(sp2.sale_price, bi2.sale_price)) as sale_price
                FROM branches b
                JOIN branch_inventory bi2 ON bi2.branch_id = b.id
                LEFT JOIN sale_products sp2 ON sp2.product_id = p.id AND sp2.tenant_id = bi2.tenant_id
                WHERE bi2.product_id = p.id AND bi2.is_active = true AND b.deleted_at IS NULL
                GROUP BY b.id, b.name, b.address
                ORDER BY b.name
            ) branch_data
        ),
        '[]'::jsonb
    ) as branches,

    -- Global flags
    EXISTS (SELECT 1 FROM sale_products sp3 WHERE sp3.product_id = p.id AND sp3.tenant_id = bi.tenant_id) as is_on_sale,
    EXISTS (SELECT 1 FROM featured_products fp3 WHERE fp3.product_id = p.id AND fp3.tenant_id = bi.tenant_id) as is_featured,
    bool_or(bi.is_new_arrival) as is_new_arrival,
    p."isPOM" as is_pom,

    p.created_at,
    p.updated_at,
    
    -- Catalog metadata
    p.unit_of_measure,
    p.product_type,
    p.generic_name,
    p.strength,
    p.dosage_form,
    p.manufacturer
FROM products p
JOIN branch_inventory bi ON bi.product_id = p.id AND bi.is_active = true
LEFT JOIN sale_products sp ON sp.product_id = p.id AND sp.tenant_id = bi.tenant_id
WHERE p._sync_is_deleted = false
  AND p.is_active = TRUE
GROUP BY
    p.id,
    bi.tenant_id,
    p.name,
    p.description,
    p.category,
    p.image_url,
    p.is_active,
    p.created_at,
    p.updated_at,
    p."isPOM",
    p.unit_of_measure,
    p.product_type,
    p.generic_name,
    p.strength,
    p.dosage_form,
    p.manufacturer;
