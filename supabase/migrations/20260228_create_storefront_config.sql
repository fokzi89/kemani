-- ============================================================
-- Migration: Storefront Configuration Table
-- ============================================================
-- Purpose: Marketplace storefront customization for each tenant
-- Context: Paid plans can customize their storefront appearance
--          Free plan gets basic storefront only
-- Date: 2026-02-28

-- ============================================================
-- Step 1: Create storefront_config table
-- ============================================================

CREATE TABLE IF NOT EXISTS storefront_config (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,

    -- Visual customization (paid plans only)
    banner_url TEXT,
    -- Hero banner image URL

    about_text TEXT,
    -- About/description text shown on storefront

    welcome_message TEXT,
    -- Custom welcome message for customers

    -- Business hours (stored as JSON for flexibility)
    operating_hours JSONB,
    -- Example: {
    --   "monday": {"open": "08:00", "close": "18:00", "is_open": true},
    --   "tuesday": {"open": "08:00", "close": "18:00", "is_open": true},
    --   ...
    --   "sunday": {"is_open": false}
    -- }

    -- Contact information
    contact_email VARCHAR(255),
    contact_phone VARCHAR(20),
    contact_whatsapp VARCHAR(20),
    physical_address TEXT,

    -- Social media links
    facebook_url TEXT,
    instagram_url TEXT,
    twitter_url TEXT,

    -- Order settings
    minimum_order_value DECIMAL(12,2) NOT NULL DEFAULT 0 CHECK (minimum_order_value >= 0),
    -- Minimum order value for checkout

    accept_online_orders BOOLEAN NOT NULL DEFAULT TRUE,
    -- Can customers place orders online?

    allow_guest_checkout BOOLEAN NOT NULL DEFAULT TRUE,
    -- Can customers checkout without account?

    require_phone_verification BOOLEAN NOT NULL DEFAULT FALSE,
    -- Require phone OTP verification before checkout?

    -- Display settings
    show_stock_quantity BOOLEAN NOT NULL DEFAULT FALSE,
    -- Show exact stock numbers to customers?

    show_out_of_stock BOOLEAN NOT NULL DEFAULT TRUE,
    -- Display out-of-stock products?

    products_per_page INTEGER NOT NULL DEFAULT 20 CHECK (products_per_page > 0),
    -- Pagination setting

    -- SEO settings
    meta_title VARCHAR(255),
    meta_description TEXT,
    meta_keywords TEXT,

    -- Status
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    -- Is storefront live and accessible to customers?

    -- Metadata
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Ensure one config per tenant
    CONSTRAINT storefront_config_tenant_unique UNIQUE(tenant_id)
);

-- ============================================================
-- Step 2: Create indexes
-- ============================================================

CREATE INDEX idx_storefront_config_tenant_id ON storefront_config(tenant_id);
CREATE INDEX idx_storefront_config_active ON storefront_config(tenant_id, is_active);

-- ============================================================
-- Step 3: Enable Row Level Security
-- ============================================================

ALTER TABLE storefront_config ENABLE ROW LEVEL SECURITY;

-- Tenant isolation policy
CREATE POLICY "Storefront config tenant isolation" ON storefront_config
    USING (tenant_id = current_tenant_id());

-- Allow tenants to view their storefront config
CREATE POLICY "Tenants can view storefront config" ON storefront_config
    FOR SELECT
    USING (tenant_id = current_tenant_id());

-- Allow tenants to create storefront config
CREATE POLICY "Tenants can create storefront config" ON storefront_config
    FOR INSERT
    WITH CHECK (tenant_id = current_tenant_id());

-- Allow tenants to update storefront config
CREATE POLICY "Tenants can update storefront config" ON storefront_config
    FOR UPDATE
    USING (tenant_id = current_tenant_id())
    WITH CHECK (tenant_id = current_tenant_id());

-- Allow public read access to active storefronts (for customer browsing)
CREATE POLICY "Public can view active storefronts" ON storefront_config
    FOR SELECT
    USING (is_active = TRUE);

-- ============================================================
-- Step 4: Create trigger to update updated_at
-- ============================================================

CREATE OR REPLACE FUNCTION update_storefront_config_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_storefront_config_updated_at
    BEFORE UPDATE ON storefront_config
    FOR EACH ROW
    EXECUTE FUNCTION update_storefront_config_updated_at();

-- ============================================================
-- Step 5: Create helper function to check if storefront is open
-- ============================================================

CREATE OR REPLACE FUNCTION is_storefront_open(
    p_tenant_id UUID,
    p_check_time TIMESTAMPTZ DEFAULT NOW()
)
RETURNS BOOLEAN AS $$
DECLARE
    v_config RECORD;
    v_day_of_week TEXT;
    v_current_time TIME;
    v_hours JSONB;
    v_is_open BOOLEAN;
    v_open_time TIME;
    v_close_time TIME;
BEGIN
    -- Get storefront config
    SELECT
        is_active,
        operating_hours
    INTO v_config
    FROM storefront_config
    WHERE tenant_id = p_tenant_id;

    -- If no config or inactive, return FALSE
    IF v_config IS NULL OR v_config.is_active = FALSE THEN
        RETURN FALSE;
    END IF;

    -- If no operating hours defined, assume always open
    IF v_config.operating_hours IS NULL THEN
        RETURN TRUE;
    END IF;

    -- Get day of week (lowercase)
    v_day_of_week := LOWER(TO_CHAR(p_check_time, 'Day'));
    v_day_of_week := TRIM(v_day_of_week);

    -- Get current time
    v_current_time := p_check_time::TIME;

    -- Get hours for this day
    v_hours := v_config.operating_hours -> v_day_of_week;

    -- If no hours defined for this day, assume closed
    IF v_hours IS NULL THEN
        RETURN FALSE;
    END IF;

    -- Check if marked as open
    v_is_open := (v_hours ->> 'is_open')::BOOLEAN;

    IF v_is_open = FALSE THEN
        RETURN FALSE;
    END IF;

    -- Get open/close times
    v_open_time := (v_hours ->> 'open')::TIME;
    v_close_time := (v_hours ->> 'close')::TIME;

    -- Check if current time is within operating hours
    RETURN v_current_time BETWEEN v_open_time AND v_close_time;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- Step 6: Insert default storefront configs for existing tenants
-- ============================================================

-- Create basic storefront config for all existing tenants
INSERT INTO storefront_config (
    tenant_id,
    about_text,
    welcome_message,
    operating_hours,
    minimum_order_value,
    accept_online_orders,
    allow_guest_checkout,
    require_phone_verification,
    show_stock_quantity,
    show_out_of_stock,
    products_per_page,
    is_active
)
SELECT
    t.id,
    'Welcome to our store! We offer quality products at great prices.',
    'Shop with us today!',
    jsonb_build_object(
        'monday', jsonb_build_object('open', '08:00', 'close', '18:00', 'is_open', true),
        'tuesday', jsonb_build_object('open', '08:00', 'close', '18:00', 'is_open', true),
        'wednesday', jsonb_build_object('open', '08:00', 'close', '18:00', 'is_open', true),
        'thursday', jsonb_build_object('open', '08:00', 'close', '18:00', 'is_open', true),
        'friday', jsonb_build_object('open', '08:00', 'close', '18:00', 'is_open', true),
        'saturday', jsonb_build_object('open', '09:00', 'close', '17:00', 'is_open', true),
        'sunday', jsonb_build_object('is_open', false)
    ),
    0,       -- No minimum order value
    TRUE,    -- Accept online orders
    TRUE,    -- Allow guest checkout
    FALSE,   -- Don't require phone verification
    FALSE,   -- Don't show exact stock quantities
    TRUE,    -- Show out-of-stock products
    20,      -- 20 products per page
    FALSE    -- Inactive by default (tenant must activate)
FROM tenants t
WHERE t.id NOT IN (SELECT tenant_id FROM storefront_config);

-- ============================================================
-- Comments for documentation
-- ============================================================

COMMENT ON TABLE storefront_config IS 'Tenant storefront customization and settings for online marketplace';
COMMENT ON COLUMN storefront_config.banner_url IS 'Hero banner image URL (paid plans only)';
COMMENT ON COLUMN storefront_config.about_text IS 'About/description text shown on storefront (paid plans only)';
COMMENT ON COLUMN storefront_config.operating_hours IS 'Business hours by day of week in JSON format';
COMMENT ON COLUMN storefront_config.minimum_order_value IS 'Minimum order value required for checkout';
COMMENT ON COLUMN storefront_config.accept_online_orders IS 'Whether storefront accepts online orders';
COMMENT ON COLUMN storefront_config.allow_guest_checkout IS 'Whether customers can checkout without creating account';
COMMENT ON COLUMN storefront_config.require_phone_verification IS 'Whether phone OTP verification is required before checkout';
COMMENT ON COLUMN storefront_config.show_stock_quantity IS 'Whether to display exact stock numbers to customers';
COMMENT ON COLUMN storefront_config.show_out_of_stock IS 'Whether to display out-of-stock products';
COMMENT ON COLUMN storefront_config.is_active IS 'Whether storefront is live and accessible to customers';

COMMENT ON FUNCTION is_storefront_open(UUID, TIMESTAMPTZ) IS 'Checks if a tenant storefront is currently open based on operating hours';
