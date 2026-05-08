-- ============================================================
-- Migration: Update Inventory View with Name and Strength
-- ============================================================
-- Description: Redefines v_branch_products to include all
--              necessary fields for the inventory dashboard,
--              including product name, strength, and batches.
-- ============================================================

CREATE OR REPLACE VIEW public.v_branch_products AS
SELECT
    bi.id as inv_id,
    bi.tenant_id,
    bi.branch_id,
    bi.product_id,
    bi.stock_quantity,
    bi.reserved_quantity,
    bi.batch_no,
    bi.expiry_date,
    bi.low_stock_threshold,
    bi.cost_price,
    bi.selling_price,
    bi."isPOM",
    bi.is_active as inventory_active,
    bi.updated_at,
    
    -- Product details from the master catalog
    p.name as product_name,
    p.sku,
    p.barcode,
    p.image_url,
    p.strength,
    p.product_type,
    p.unit_of_measure,
    p.is_active as product_active,
    
    -- Status flags
    CASE
        WHEN bi.stock_quantity <= bi.low_stock_threshold THEN true
        ELSE false
    END as is_low_stock,
    CASE
        WHEN bi.expiry_date IS NOT NULL
        AND bi.expiry_date <= CURRENT_DATE + INTERVAL '90 days'
        THEN true
        ELSE false
    END as is_expiring_soon
FROM branch_inventory bi
JOIN products p ON bi.product_id = p.id;

COMMENT ON VIEW v_branch_products IS 'Comprehensive view joining branch inventory with product master data';
