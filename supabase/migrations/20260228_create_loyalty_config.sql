-- ============================================================
-- Migration: Loyalty Configuration Table
-- ============================================================
-- Purpose: Tenant-configurable loyalty points system
-- Context: Each tenant can activate/deactivate loyalty and define
--          their own rules for earning and redeeming points
-- Date: 2026-02-28

-- ============================================================
-- Step 1: Create loyalty_config table
-- ============================================================

CREATE TABLE IF NOT EXISTS loyalty_config (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,

    -- Feature toggle
    is_enabled BOOLEAN NOT NULL DEFAULT FALSE,

    -- Earning rules
    points_per_currency_unit DECIMAL(8,2) NOT NULL DEFAULT 1.00,
    -- Example: 1 point per NGN 100 spent
    -- So if customer spends NGN 5,000, they earn: (5000 / 100) * 1.00 = 50 points

    currency_unit DECIMAL(8,2) NOT NULL DEFAULT 100.00,
    -- The currency amount needed to earn points_per_currency_unit points
    -- Default: NGN 100

    -- Redemption rules
    min_redemption_points INTEGER NOT NULL DEFAULT 100,
    -- Minimum points needed before customer can redeem

    allow_partial_payment BOOLEAN NOT NULL DEFAULT TRUE,
    -- Can points be used for partial order payment?

    allow_full_payment BOOLEAN NOT NULL DEFAULT TRUE,
    -- Can points cover the entire order amount?

    redemption_value_per_point DECIMAL(8,2) NOT NULL DEFAULT 1.00,
    -- How much currency does 1 point equal when redeemed?
    -- Default: 1 point = NGN 1

    max_points_per_order INTEGER,
    -- Optional: Maximum points that can be redeemed in a single order
    -- NULL = no limit

    points_expiry_days INTEGER,
    -- Optional: Days until points expire (NULL = never expire)

    -- Metadata
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Ensure one config per tenant
    CONSTRAINT loyalty_config_tenant_unique UNIQUE(tenant_id),

    -- Validation constraints
    CONSTRAINT valid_points_per_unit CHECK (points_per_currency_unit > 0),
    CONSTRAINT valid_currency_unit CHECK (currency_unit > 0),
    CONSTRAINT valid_min_redemption CHECK (min_redemption_points >= 0),
    CONSTRAINT valid_redemption_value CHECK (redemption_value_per_point > 0),
    CONSTRAINT valid_max_points_per_order CHECK (max_points_per_order IS NULL OR max_points_per_order > 0),
    CONSTRAINT valid_expiry_days CHECK (points_expiry_days IS NULL OR points_expiry_days > 0)
);

-- ============================================================
-- Step 2: Create indexes
-- ============================================================

CREATE INDEX idx_loyalty_config_tenant_id ON loyalty_config(tenant_id);
CREATE INDEX idx_loyalty_config_enabled ON loyalty_config(tenant_id, is_enabled);

-- ============================================================
-- Step 3: Enable Row Level Security
-- ============================================================

ALTER TABLE loyalty_config ENABLE ROW LEVEL SECURITY;

-- Tenant isolation policy
CREATE POLICY "Loyalty config tenant isolation" ON loyalty_config
    USING (tenant_id = current_tenant_id());

-- Allow tenants to view their loyalty config
CREATE POLICY "Tenants can view loyalty config" ON loyalty_config
    FOR SELECT
    USING (tenant_id = current_tenant_id());

-- Allow tenants to create loyalty config
CREATE POLICY "Tenants can create loyalty config" ON loyalty_config
    FOR INSERT
    WITH CHECK (tenant_id = current_tenant_id());

-- Allow tenants to update loyalty config
CREATE POLICY "Tenants can update loyalty config" ON loyalty_config
    FOR UPDATE
    USING (tenant_id = current_tenant_id())
    WITH CHECK (tenant_id = current_tenant_id());

-- ============================================================
-- Step 4: Create trigger to update updated_at
-- ============================================================

CREATE OR REPLACE FUNCTION update_loyalty_config_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_loyalty_config_updated_at
    BEFORE UPDATE ON loyalty_config
    FOR EACH ROW
    EXECUTE FUNCTION update_loyalty_config_updated_at();

-- ============================================================
-- Step 5: Create helper function to calculate loyalty points
-- ============================================================

CREATE OR REPLACE FUNCTION calculate_loyalty_points(
    p_tenant_id UUID,
    p_purchase_amount DECIMAL
)
RETURNS INTEGER AS $$
DECLARE
    v_config RECORD;
    v_points INTEGER;
BEGIN
    -- Get loyalty config for tenant
    SELECT
        is_enabled,
        points_per_currency_unit,
        currency_unit
    INTO v_config
    FROM loyalty_config
    WHERE tenant_id = p_tenant_id;

    -- If no config or not enabled, return 0
    IF v_config IS NULL OR v_config.is_enabled = FALSE THEN
        RETURN 0;
    END IF;

    -- Calculate points: (amount / currency_unit) * points_per_unit
    -- Example: (5000 / 100) * 1.00 = 50 points
    v_points := FLOOR((p_purchase_amount / v_config.currency_unit) * v_config.points_per_currency_unit);

    RETURN GREATEST(v_points, 0);  -- Never return negative
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- Step 6: Create helper function to calculate redemption value
-- ============================================================

CREATE OR REPLACE FUNCTION calculate_redemption_value(
    p_tenant_id UUID,
    p_points INTEGER
)
RETURNS DECIMAL AS $$
DECLARE
    v_config RECORD;
    v_value DECIMAL;
BEGIN
    -- Get loyalty config for tenant
    SELECT
        is_enabled,
        redemption_value_per_point,
        min_redemption_points
    INTO v_config
    FROM loyalty_config
    WHERE tenant_id = p_tenant_id;

    -- If no config or not enabled, return 0
    IF v_config IS NULL OR v_config.is_enabled = FALSE THEN
        RETURN 0;
    END IF;

    -- Check minimum redemption threshold
    IF p_points < v_config.min_redemption_points THEN
        RETURN 0;
    END IF;

    -- Calculate redemption value: points * value_per_point
    -- Example: 100 points * 1.00 = NGN 100
    v_value := p_points * v_config.redemption_value_per_point;

    RETURN v_value;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- Step 7: Insert default configs for existing tenants
-- ============================================================

-- Create disabled loyalty config for all existing tenants
INSERT INTO loyalty_config (
    tenant_id,
    is_enabled,
    points_per_currency_unit,
    currency_unit,
    min_redemption_points,
    allow_partial_payment,
    allow_full_payment,
    redemption_value_per_point
)
SELECT
    id,
    FALSE,  -- Disabled by default
    1.00,   -- 1 point per currency_unit
    100.00, -- Per NGN 100
    100,    -- Minimum 100 points to redeem
    TRUE,   -- Allow partial payment
    TRUE,   -- Allow full payment
    1.00    -- 1 point = NGN 1
FROM tenants
WHERE id NOT IN (SELECT tenant_id FROM loyalty_config);

-- ============================================================
-- Comments for documentation
-- ============================================================

COMMENT ON TABLE loyalty_config IS 'Tenant-specific loyalty points configuration - each tenant controls their own loyalty program';
COMMENT ON COLUMN loyalty_config.is_enabled IS 'Whether loyalty points are active for this tenant';
COMMENT ON COLUMN loyalty_config.points_per_currency_unit IS 'Number of points earned per currency_unit spent';
COMMENT ON COLUMN loyalty_config.currency_unit IS 'Currency amount needed to earn points (e.g., 100 for NGN 100)';
COMMENT ON COLUMN loyalty_config.min_redemption_points IS 'Minimum points required before customer can redeem';
COMMENT ON COLUMN loyalty_config.allow_partial_payment IS 'Can points be used alongside other payment methods?';
COMMENT ON COLUMN loyalty_config.allow_full_payment IS 'Can points cover the entire order amount?';
COMMENT ON COLUMN loyalty_config.redemption_value_per_point IS 'Currency value of 1 point when redeemed';
COMMENT ON COLUMN loyalty_config.max_points_per_order IS 'Maximum points that can be used in a single order (NULL = unlimited)';
COMMENT ON COLUMN loyalty_config.points_expiry_days IS 'Days until earned points expire (NULL = never expire)';

COMMENT ON FUNCTION calculate_loyalty_points(UUID, DECIMAL) IS 'Calculates loyalty points earned for a purchase amount based on tenant config';
COMMENT ON FUNCTION calculate_redemption_value(UUID, INTEGER) IS 'Calculates currency value of points for redemption based on tenant config';
