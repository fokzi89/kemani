-- ============================================================
-- Migration: Update ecommerce_products view for Pre-orders
-- ============================================================
-- Description: Adds allow_preorder, preorder_quantity, and 
--              preorder_limit to the branch-level storefront view.
--              Updated to use direct flags from branch_inventory.
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
    
    -- Pricing from THIS specific branch
    MIN(bi.selling_price) as selling_price,
    MIN(bi.sale_price) as sale_price,
    
    p.image_url,
    p.is_active,

    -- Total stock in THIS specific branch
    COALESCE(SUM(bi.stock_quantity), 0) as total_stock,

    -- Pre-order fields aggregated across batches
    bool_or(bi.allow_preorder) as allow_preorder,
    COALESCE(SUM(bi.preorder_quantity), 0) as preorder_quantity,
    MAX(bi.preorder_limit) as preorder_limit,

    -- Promotional Flags (Direct from branch_inventory)
    bool_or(bi.is_on_sale) as is_on_sale,
    bool_or(bi.is_featured) as is_featured,
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
