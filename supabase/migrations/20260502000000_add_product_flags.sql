-- ============================================
-- Migration: Add Product Flags to Branch Inventory
-- Description: Adds is_on_sale, is_featured, and is_new_arrival flags to branch_inventory
--              to support storefront categories.
-- Created: 2026-05-02
-- ============================================

ALTER TABLE branch_inventory 
ADD COLUMN IF NOT EXISTS is_on_sale BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS is_featured BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS is_new_arrival BOOLEAN DEFAULT FALSE;

COMMENT ON COLUMN branch_inventory.is_on_sale IS 'Whether the product is currently on sale in this branch';
COMMENT ON COLUMN branch_inventory.is_featured IS 'Whether the product should be featured on the storefront';
COMMENT ON COLUMN branch_inventory.is_new_arrival IS 'Whether the product is a new arrival';

-- Update the ecommerce_products view to include these flags
-- We use bool_or() to see if ANY branch has the flag set for a product within a tenant
CREATE OR REPLACE VIEW ecommerce_products AS
SELECT
    p.id,
    bi.tenant_id,
    p.name,
    p.description,
    p.category,
    bi.selling_price,
    bi.sale_price,
    p.image_url,
    p.is_active,

    -- Aggregate stock across all branches for this tenant
    COALESCE(SUM(bi.stock_quantity), 0) as total_stock,

    -- Count how many branches have this product
    COUNT(DISTINCT bi.branch_id) as branch_count,

    -- Collect branch information
    COALESCE(
        jsonb_agg(
            jsonb_build_object(
                'branch_id', b.id,
                'branch_name', b.name,
                'branch_address', b.address,
                'branch_phone', b.phone,
                'latitude', b.latitude,
                'longitude', b.longitude,
                'stock_quantity', bi.stock_quantity,
                'in_stock', bi.stock_quantity > 0,
                'is_on_sale', bi.is_on_sale,
                'is_featured', bi.is_featured,
                'is_new_arrival', bi.is_new_arrival,
                'selling_price', bi.selling_price,
                'sale_price', bi.sale_price
            ) ORDER BY b.name
        ) FILTER (WHERE bi.id IS NOT NULL),
        '[]'::jsonb
    ) as branches,

    -- Flags aggregated across branches
    bool_or(bi.is_on_sale) as is_on_sale,
    bool_or(bi.is_featured) as is_featured,
    bool_or(bi.is_new_arrival) as is_new_arrival,

    -- Min and max price (using branch-specific selling_price)
    MIN(bi.selling_price) as min_price,
    MAX(bi.selling_price) as max_price,

    p.created_at,
    p.updated_at,
    
    -- Healthcare & Laboratory expansions
    p.unit_of_measure,
    p.product_type,
    p.generic_name,
    p.strength,
    p.dosage_form,
    p.manufacturer
FROM products p
JOIN branch_inventory bi ON bi.product_id = p.id AND bi.is_active = true
LEFT JOIN branches b ON bi.branch_id = b.id AND b.deleted_at IS NULL
WHERE p._sync_is_deleted = false
  AND p.is_active = TRUE
GROUP BY
    p.id,
    bi.tenant_id,
    p.name,
    p.description,
    p.category,
    bi.selling_price,
    bi.sale_price,
    p.image_url,
    p.is_active,
    p.created_at,
    p.updated_at,
    
    -- Essential group by fields
    p.unit_of_measure,
    p.product_type,
    p.generic_name,
    p.strength,
    p.dosage_form,
    p.manufacturer;
