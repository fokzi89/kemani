-- ============================================================
-- Migration: Branch-Level Storefront Aggregation
-- ============================================================
-- Description: Updates the ecommerce_products view to aggregate 
--              batches PER BRANCH instead of per tenant.
-- ============================================================

DROP VIEW IF EXISTS ecommerce_products CASCADE;

CREATE OR REPLACE VIEW ecommerce_products AS
SELECT
    -- Unique ID for the view (Product + Branch)
    (p.id::text || '-' || bi.branch_id::text) as id,
    p.id as product_id,
    bi.tenant_id,
    bi.branch_id,
    b.name as branch_name,
    b.address as branch_address,
    p.name,
    p.description,
    p.category,
    
    -- Lowest price in THIS specific branch
    MIN(bi.selling_price) as selling_price,
    MIN(COALESCE(sp.sale_price, bi.sale_price)) as sale_price,
    
    p.image_url,
    p.is_active,

    -- Total stock in THIS specific branch
    COALESCE(SUM(bi.stock_quantity), 0) as total_stock,

    -- Flags
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
JOIN branches b ON bi.branch_id = b.id AND b.deleted_at IS NULL
LEFT JOIN sale_products sp ON sp.product_id = p.id AND sp.tenant_id = bi.tenant_id
WHERE p._sync_is_deleted = false
  AND p.is_active = TRUE
GROUP BY
    p.id,
    bi.tenant_id,
    bi.branch_id,
    b.name,
    b.address,
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
