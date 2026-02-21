-- ============================================================================
-- Optimized Search Functions for Storefront (T030)
-- ============================================================================

-- Function to search storefront products with full-text search
CREATE OR REPLACE FUNCTION search_storefront_products(
    search_query TEXT,
    branch_id_param UUID,
    category_param TEXT DEFAULT NULL,
    min_price_param DECIMAL DEFAULT NULL,
    max_price_param DECIMAL DEFAULT NULL,
    limit_param INTEGER DEFAULT 20,
    offset_param INTEGER DEFAULT 0
)
RETURNS TABLE (
    id UUID,
    tenant_id UUID,
    branch_id UUID,
    catalog_product_id UUID,
    name TEXT,
    description TEXT,
    images TEXT[],
    primary_image TEXT,
    category TEXT,
    brand TEXT,
    barcode TEXT,
    business_type TEXT,
    specifications JSONB,
    sku TEXT,
    price DECIMAL,
    compare_at_price DECIMAL,
    cost_price DECIMAL,
    stock_quantity INTEGER,
    low_stock_threshold INTEGER,
    is_available BOOLEAN,
    has_variants BOOLEAN,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ,
    synced_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        sp.id,
        sp.tenant_id,
        sp.branch_id,
        sp.catalog_product_id,
        COALESCE(sp.custom_name, gc.name) as name,
        COALESCE(sp.custom_description, gc.description) as description,
        COALESCE(sp.custom_images, gc.images) as images,
        COALESCE(sp.custom_images[1], gc.primary_image) as primary_image,
        gc.category,
        gc.brand,
        gc.barcode,
        gc.business_type,
        gc.specifications,
        sp.sku,
        sp.price,
        sp.compare_at_price,
        sp.cost_price,
        sp.stock_quantity,
        sp.low_stock_threshold,
        sp.is_available,
        sp.has_variants,
        sp.created_at,
        sp.updated_at,
        sp.synced_at
    FROM storefront_products sp
    LEFT JOIN global_product_catalog gc ON sp.catalog_product_id = gc.id
    WHERE sp.branch_id = branch_id_param
        AND sp.is_available = TRUE
        AND (category_param IS NULL OR gc.category = category_param)
        AND (min_price_param IS NULL OR sp.price >= min_price_param)
        AND (max_price_param IS NULL OR sp.price <= max_price_param)
        AND (
            search_query IS NULL OR
            search_query = '' OR
            to_tsvector('english', 
                COALESCE(sp.custom_name, gc.name, '') || ' ' ||
                COALESCE(sp.custom_description, gc.description, '') || ' ' ||
                COALESCE(gc.brand, '') || ' ' ||
                COALESCE(gc.category, '') || ' ' ||
                COALESCE(sp.sku, '')
            ) @@ plainto_tsquery('english', search_query)
        )
    ORDER BY 
        CASE 
            WHEN search_query IS NOT NULL AND search_query != '' THEN
                ts_rank(
                    to_tsvector('english', 
                        COALESCE(sp.custom_name, gc.name, '') || ' ' ||
                        COALESCE(sp.custom_description, gc.description, '') || ' ' ||
                        COALESCE(gc.brand, '') || ' ' ||
                        COALESCE(gc.category, '')
                    ),
                    plainto_tsquery('english', search_query)
                )
            ELSE 0
        END DESC,
        COALESCE(sp.custom_name, gc.name) ASC
    LIMIT limit_param
    OFFSET offset_param;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to search products across multiple branches (Business Plan - T031)
CREATE OR REPLACE FUNCTION search_storefront_products_multi_branch(
    search_query TEXT,
    tenant_id_param UUID,
    branch_ids_param UUID[] DEFAULT NULL,
    category_param TEXT DEFAULT NULL,
    min_price_param DECIMAL DEFAULT NULL,
    max_price_param DECIMAL DEFAULT NULL,
    limit_param INTEGER DEFAULT 20,
    offset_param INTEGER DEFAULT 0
)
RETURNS TABLE (
    id UUID,
    tenant_id UUID,
    branch_id UUID,
    catalog_product_id UUID,
    name TEXT,
    description TEXT,
    images TEXT[],
    primary_image TEXT,
    category TEXT,
    brand TEXT,
    barcode TEXT,
    business_type TEXT,
    specifications JSONB,
    sku TEXT,
    price DECIMAL,
    compare_at_price DECIMAL,
    cost_price DECIMAL,
    stock_quantity INTEGER,
    low_stock_threshold INTEGER,
    is_available BOOLEAN,
    has_variants BOOLEAN,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ,
    synced_at TIMESTAMPTZ,
    branch_name TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        sp.id,
        sp.tenant_id,
        sp.branch_id,
        sp.catalog_product_id,
        COALESCE(sp.custom_name, gc.name) as name,
        COALESCE(sp.custom_description, gc.description) as description,
        COALESCE(sp.custom_images, gc.images) as images,
        COALESCE(sp.custom_images[1], gc.primary_image) as primary_image,
        gc.category,
        gc.brand,
        gc.barcode,
        gc.business_type,
        gc.specifications,
        sp.sku,
        sp.price,
        sp.compare_at_price,
        sp.cost_price,
        sp.stock_quantity,
        sp.low_stock_threshold,
        sp.is_available,
        sp.has_variants,
        sp.created_at,
        sp.updated_at,
        sp.synced_at,
        b.name as branch_name
    FROM storefront_products sp
    LEFT JOIN global_product_catalog gc ON sp.catalog_product_id = gc.id
    LEFT JOIN branches b ON sp.branch_id = b.id
    WHERE sp.tenant_id = tenant_id_param
        AND sp.is_available = TRUE
        AND (branch_ids_param IS NULL OR sp.branch_id = ANY(branch_ids_param))
        AND (category_param IS NULL OR gc.category = category_param)
        AND (min_price_param IS NULL OR sp.price >= min_price_param)
        AND (max_price_param IS NULL OR sp.price <= max_price_param)
        AND (
            search_query IS NULL OR
            search_query = '' OR
            to_tsvector('english', 
                COALESCE(sp.custom_name, gc.name, '') || ' ' ||
                COALESCE(sp.custom_description, gc.description, '') || ' ' ||
                COALESCE(gc.brand, '') || ' ' ||
                COALESCE(gc.category, '') || ' ' ||
                COALESCE(sp.sku, '')
            ) @@ plainto_tsquery('english', search_query)
        )
    ORDER BY 
        CASE 
            WHEN search_query IS NOT NULL AND search_query != '' THEN
                ts_rank(
                    to_tsvector('english', 
                        COALESCE(sp.custom_name, gc.name, '') || ' ' ||
                        COALESCE(sp.custom_description, gc.description, '') || ' ' ||
                        COALESCE(gc.brand, '') || ' ' ||
                        COALESCE(gc.category, '')
                    ),
                    plainto_tsquery('english', search_query)
                )
            ELSE 0
        END DESC,
        COALESCE(sp.custom_name, gc.name) ASC,
        b.name ASC
    LIMIT limit_param
    OFFSET offset_param;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get search suggestions
CREATE OR REPLACE FUNCTION get_search_suggestions(
    search_query TEXT,
    branch_id_param UUID,
    limit_param INTEGER DEFAULT 5
)
RETURNS TABLE (
    suggestion TEXT,
    type TEXT,
    count INTEGER
) AS $$
BEGIN
    RETURN QUERY
    WITH suggestions AS (
        -- Product names
        SELECT 
            COALESCE(sp.custom_name, gc.name) as suggestion,
            'product' as type,
            COUNT(*)::INTEGER as count
        FROM storefront_products sp
        LEFT JOIN global_product_catalog gc ON sp.catalog_product_id = gc.id
        WHERE sp.branch_id = branch_id_param
            AND sp.is_available = TRUE
            AND COALESCE(sp.custom_name, gc.name) ILIKE '%' || search_query || '%'
        GROUP BY COALESCE(sp.custom_name, gc.name)
        
        UNION ALL
        
        -- Categories
        SELECT 
            gc.category as suggestion,
            'category' as type,
            COUNT(*)::INTEGER as count
        FROM storefront_products sp
        LEFT JOIN global_product_catalog gc ON sp.catalog_product_id = gc.id
        WHERE sp.branch_id = branch_id_param
            AND sp.is_available = TRUE
            AND gc.category ILIKE '%' || search_query || '%'
        GROUP BY gc.category
        
        UNION ALL
        
        -- Brands
        SELECT 
            gc.brand as suggestion,
            'brand' as type,
            COUNT(*)::INTEGER as count
        FROM storefront_products sp
        LEFT JOIN global_product_catalog gc ON sp.catalog_product_id = gc.id
        WHERE sp.branch_id = branch_id_param
            AND sp.is_available = TRUE
            AND gc.brand ILIKE '%' || search_query || '%'
        GROUP BY gc.brand
    )
    SELECT s.suggestion, s.type, s.count
    FROM suggestions s
    WHERE s.suggestion IS NOT NULL
    ORDER BY s.count DESC, s.suggestion ASC
    LIMIT limit_param;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create indexes for better search performance
CREATE INDEX IF NOT EXISTS idx_storefront_products_search 
ON storefront_products 
USING gin(to_tsvector('english', sku));

-- Index on global catalog for full-text search
CREATE INDEX IF NOT EXISTS idx_global_catalog_fulltext 
ON global_product_catalog 
USING gin(to_tsvector('english', name || ' ' || COALESCE(description, '') || ' ' || COALESCE(brand, '') || ' ' || COALESCE(category, '')));

-- Composite indexes for common filter combinations
CREATE INDEX IF NOT EXISTS idx_storefront_products_branch_category_price 
ON storefront_products (branch_id, is_available) 
WHERE is_available = TRUE;

CREATE INDEX IF NOT EXISTS idx_storefront_products_tenant_branch_available 
ON storefront_products (tenant_id, branch_id, is_available) 
WHERE is_available = TRUE;

-- Comment on functions
COMMENT ON FUNCTION search_storefront_products IS 'Optimized full-text search for storefront products with ranking';
COMMENT ON FUNCTION search_storefront_products_multi_branch IS 'Multi-branch product search for Business Plan users';
COMMENT ON FUNCTION get_search_suggestions IS 'Get search suggestions based on partial query';