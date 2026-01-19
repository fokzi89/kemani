-- ============================================================
-- Migration 012: E-Commerce Enhancements
-- ============================================================
-- Purpose: Add e-commerce storefront support with custom domain capability

-- Add commission cap to subscriptions table
ALTER TABLE subscriptions
ADD COLUMN commission_cap_amount DECIMAL(12,2) DEFAULT 500.00 CHECK (commission_cap_amount >= 0);

COMMENT ON COLUMN subscriptions.commission_cap_amount IS
'Maximum commission amount per order in Naira. Default is ₦500 cap for all plans.';

-- Add e-commerce fields to tenants table
ALTER TABLE tenants
ADD COLUMN ecommerce_enabled BOOLEAN DEFAULT FALSE,
ADD COLUMN custom_domain VARCHAR(255),
ADD COLUMN custom_domain_verified BOOLEAN DEFAULT FALSE,
ADD COLUMN ecommerce_settings JSONB DEFAULT '{}';

-- Create unique index on custom_domain
CREATE UNIQUE INDEX idx_tenants_custom_domain ON tenants(custom_domain)
    WHERE custom_domain IS NOT NULL AND deleted_at IS NULL;

-- Add comments to document the fields
COMMENT ON COLUMN tenants.ecommerce_enabled IS
'Indicates if tenant has e-commerce storefront enabled. Available for Pro, Enterprise, and Enterprise Custom plans.';

COMMENT ON COLUMN tenants.custom_domain IS
'Custom domain for e-commerce storefront (e.g., "shop.mystore.com"). Only available for Enterprise Custom plan. NULL means using default /tenant-slug URL.';

COMMENT ON COLUMN tenants.custom_domain_verified IS
'Indicates if custom domain DNS has been verified and is active.';

COMMENT ON COLUMN tenants.ecommerce_settings IS
'E-commerce configuration. Example: {
  "show_out_of_stock": false,
  "enable_branch_filter": true,
  "enable_location_filter": true,
  "default_view": "category",
  "currency_display": "NGN",
  "delivery_enabled": true,
  "pickup_enabled": true,
  "min_order_amount": 1000,
  "seo": {
    "meta_title": "Shop at MyStore",
    "meta_description": "...",
    "og_image": "https://..."
  },
  "theme": {
    "primary_color": "#FF6B35",
    "secondary_color": "#004E89"
  }
}';

-- Function to check if tenant can enable e-commerce
CREATE OR REPLACE FUNCTION can_enable_ecommerce(p_tenant_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    v_plan_tier plan_tier;
BEGIN
    SELECT s.plan_tier INTO v_plan_tier
    FROM tenants t
    JOIN subscriptions s ON t.subscription_id = s.id
    WHERE t.id = p_tenant_id
    AND s.status = 'active';

    -- E-commerce available for Pro, Enterprise, and Enterprise Custom plans
    RETURN v_plan_tier IN ('pro', 'enterprise', 'enterprise_custom');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if tenant can use custom domain
CREATE OR REPLACE FUNCTION can_use_custom_domain(p_tenant_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    v_plan_tier plan_tier;
BEGIN
    SELECT s.plan_tier INTO v_plan_tier
    FROM tenants t
    JOIN subscriptions s ON t.subscription_id = s.id
    WHERE t.id = p_tenant_id
    AND s.status = 'active';

    -- Custom domain only available for Enterprise Custom plan
    RETURN v_plan_tier = 'enterprise_custom';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get tenant storefront URL
CREATE OR REPLACE FUNCTION get_storefront_url(p_tenant_id UUID, p_base_url TEXT DEFAULT 'https://yourdomain.com')
RETURNS TEXT AS $$
DECLARE
    v_custom_domain VARCHAR(255);
    v_custom_domain_verified BOOLEAN;
    v_slug VARCHAR(100);
    v_ecommerce_enabled BOOLEAN;
BEGIN
    SELECT custom_domain, custom_domain_verified, slug, ecommerce_enabled
    INTO v_custom_domain, v_custom_domain_verified, v_slug, v_ecommerce_enabled
    FROM tenants
    WHERE id = p_tenant_id
    AND deleted_at IS NULL;

    -- Return NULL if e-commerce is not enabled
    IF NOT v_ecommerce_enabled THEN
        RETURN NULL;
    END IF;

    -- Return custom domain if verified
    IF v_custom_domain IS NOT NULL AND v_custom_domain_verified THEN
        RETURN 'https://' || v_custom_domain;
    END IF;

    -- Return default slug-based URL
    RETURN p_base_url || '/' || v_slug;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- View for e-commerce product catalog (aggregates products across all branches)
CREATE OR REPLACE VIEW ecommerce_products AS
SELECT
    p.id,
    p.tenant_id,
    p.name,
    p.description,
    p.category,
    p.unit_price,
    p.image_url,
    p.is_active,

    -- Aggregate stock across all branches
    SUM(p.stock_quantity) as total_stock,

    -- Count how many branches have this product
    COUNT(DISTINCT p.branch_id) as branch_count,

    -- Collect branch information
    jsonb_agg(
        jsonb_build_object(
            'branch_id', b.id,
            'branch_name', b.name,
            'branch_address', b.address,
            'branch_phone', b.phone,
            'latitude', b.latitude,
            'longitude', b.longitude,
            'stock_quantity', p.stock_quantity,
            'in_stock', p.stock_quantity > 0
        ) ORDER BY b.name
    ) as branches,

    -- Min and max price across branches (in case prices differ)
    MIN(p.unit_price) as min_price,
    MAX(p.unit_price) as max_price,

    p.created_at,
    p.updated_at
FROM products p
JOIN branches b ON p.branch_id = b.id
WHERE p.deleted_at IS NULL
  AND b.deleted_at IS NULL
  AND p.is_active = TRUE
GROUP BY
    p.id,
    p.tenant_id,
    p.name,
    p.description,
    p.category,
    p.unit_price,
    p.image_url,
    p.is_active,
    p.created_at,
    p.updated_at;

-- Comment on the view
COMMENT ON VIEW ecommerce_products IS
'Aggregated product view for e-commerce storefront. Shows products across all branches with stock and location information.';

-- Function to get products for e-commerce by tenant with optional filters
CREATE OR REPLACE FUNCTION get_ecommerce_products(
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
        ep.unit_price,
        ep.image_url,
        ep.total_stock,
        ep.branch_count,
        ep.branches,
        ep.min_price,
        ep.max_price
    FROM ecommerce_products ep
    WHERE ep.tenant_id = p_tenant_id

    -- Category filter
    AND (p_category IS NULL OR ep.category = p_category)

    -- Stock filter
    AND (NOT p_in_stock_only OR ep.total_stock > 0)

    -- Branch filter (if specific branch requested)
    AND (p_branch_id IS NULL OR EXISTS (
        SELECT 1 FROM jsonb_array_elements(ep.branches) AS branch
        WHERE (branch->>'branch_id')::UUID = p_branch_id
    ))

    -- Location-based filter (if coordinates provided)
    AND (
        p_latitude IS NULL OR p_longitude IS NULL OR p_max_distance_km IS NULL
        OR EXISTS (
            SELECT 1 FROM jsonb_array_elements(ep.branches) AS branch
            WHERE (branch->>'latitude') IS NOT NULL
            AND (branch->>'longitude') IS NOT NULL
            AND ST_DWithin(
                ST_MakePoint((branch->>'longitude')::DECIMAL, (branch->>'latitude')::DECIMAL)::geography,
                ST_MakePoint(p_longitude, p_latitude)::geography,
                p_max_distance_km * 1000  -- Convert km to meters
            )
        )
    )

    ORDER BY ep.name;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to calculate commission with cap
CREATE OR REPLACE FUNCTION calculate_commission(
    p_tenant_id UUID,
    p_order_amount DECIMAL
)
RETURNS DECIMAL AS $$
DECLARE
    v_commission_rate DECIMAL;
    v_commission_cap DECIMAL;
    v_calculated_commission DECIMAL;
BEGIN
    -- Get commission rate and cap for tenant's subscription
    SELECT s.commission_rate, s.commission_cap_amount
    INTO v_commission_rate, v_commission_cap
    FROM tenants t
    JOIN subscriptions s ON t.subscription_id = s.id
    WHERE t.id = p_tenant_id
    AND s.status = 'active';

    -- If no subscription found or commission rate is 0, return 0
    IF v_commission_rate IS NULL OR v_commission_rate = 0 THEN
        RETURN 0;
    END IF;

    -- Calculate commission based on rate
    v_calculated_commission := p_order_amount * (v_commission_rate / 100);

    -- Apply cap if set and calculated commission exceeds it
    IF v_commission_cap IS NOT NULL AND v_calculated_commission > v_commission_cap THEN
        RETURN v_commission_cap;
    END IF;

    RETURN v_calculated_commission;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION calculate_commission IS
'Calculate commission for an e-commerce order with cap.
Example: For Pro plan (1.5% rate, ₦500 cap):
- ₦10,000 order = ₦150 commission (1.5% of ₦10,000)
- ₦50,000 order = ₦500 commission (1.5% would be ₦750, but capped at ₦500)
- ₦100,000 order = ₦500 commission (capped)';

-- Add index to help with e-commerce queries
CREATE INDEX idx_products_ecommerce ON products(tenant_id, category, is_active, deleted_at)
    WHERE deleted_at IS NULL AND is_active = TRUE;
