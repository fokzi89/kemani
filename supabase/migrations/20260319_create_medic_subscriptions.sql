-- Create Medic Subscriptions Table for Healthcare Providers
-- Date: 2026-03-19
--
-- Separate subscription system for healthcare providers to avoid conflicts with POS

-- ============================================================================
-- 1. CREATE MEDIC_SUBSCRIPTIONS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS medic_subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    provider_id UUID REFERENCES healthcare_providers(id) ON DELETE CASCADE,

    -- Subscription Tier
    tier TEXT NOT NULL CHECK (tier IN ('free', 'growth', 'enterprise')),
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'cancelled', 'suspended', 'trial')),

    -- Pricing
    monthly_fee DECIMAL(12,2) NOT NULL CHECK (monthly_fee >= 0),
    -- Free: ₦0, Growth: ₦25,000, Enterprise: ₦120,000

    -- Billing Cycle
    billing_cycle_start TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    billing_cycle_end TIMESTAMPTZ NOT NULL,
    next_billing_date TIMESTAMPTZ,

    -- Payment
    last_payment_date TIMESTAMPTZ,
    payment_method TEXT,

    -- Features (stored as JSONB for flexibility)
    features JSONB DEFAULT '{}',
    -- Tier Features:
    -- FREE (₦0/month):
    --   chat/video/audio: true, office: false, quota: unlimited
    --   drug/diagnostic commissions: false, custom_branding: false
    --   analytics: basic, priority_support: false
    --
    -- GROWTH (₦25,000/month):
    --   chat/video/audio: true, office: false, quota: unlimited
    --   drug/diagnostic commissions: true, custom_branding: true
    --   analytics: full, priority_support: false
    --
    -- ENTERPRISE (₦120,000/month):
    --   chat/video/audio/office: all true, quota: unlimited
    --   drug/diagnostic commissions: true, custom_branding: true
    --   analytics: advanced, priority_support: true, dedicated_manager: true

    -- Commission Settings
    consultation_commission_rate DECIMAL(5,2) DEFAULT 0 CHECK (consultation_commission_rate >= 0 AND consultation_commission_rate <= 100),
    drug_commission_rate DECIMAL(5,2) DEFAULT 0 CHECK (drug_commission_rate >= 0 AND drug_commission_rate <= 100),
    diagnostic_commission_rate DECIMAL(5,2) DEFAULT 0 CHECK (diagnostic_commission_rate >= 0 AND diagnostic_commission_rate <= 100),

    -- Metadata
    notes TEXT,

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- 2. INDEXES
-- ============================================================================

CREATE INDEX idx_medic_subscriptions_user_id ON medic_subscriptions(user_id);
CREATE INDEX idx_medic_subscriptions_provider_id ON medic_subscriptions(provider_id);
CREATE INDEX idx_medic_subscriptions_tier ON medic_subscriptions(tier);
CREATE INDEX idx_medic_subscriptions_status ON medic_subscriptions(status);

-- ============================================================================
-- 3. ROW LEVEL SECURITY
-- ============================================================================

ALTER TABLE medic_subscriptions ENABLE ROW LEVEL SECURITY;

-- Providers can view their own subscription
CREATE POLICY "Providers can view own subscription"
    ON medic_subscriptions FOR SELECT
    USING (user_id = auth.uid());

-- Providers can create their own subscription (during onboarding)
CREATE POLICY "Providers can create own subscription"
    ON medic_subscriptions FOR INSERT
    WITH CHECK (user_id = auth.uid());

-- Providers can update their own subscription
CREATE POLICY "Providers can update own subscription"
    ON medic_subscriptions FOR UPDATE
    USING (user_id = auth.uid());

-- ============================================================================
-- 4. UPDATE TRIGGER
-- ============================================================================

-- Create the update_updated_at_column function if it doesn't exist
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_medic_subscriptions_updated_at
    BEFORE UPDATE ON medic_subscriptions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- 5. UPDATE HEALTHCARE_PROVIDERS TABLE
-- ============================================================================

-- First, drop the policies that depend on the subscription_id column
DROP POLICY IF EXISTS "Users can view own subscriptions" ON subscriptions;
DROP POLICY IF EXISTS "Healthcare providers can update own subscriptions" ON subscriptions;

-- Now remove the old subscription_id column
ALTER TABLE healthcare_providers DROP COLUMN IF EXISTS subscription_id CASCADE;

-- Add new medic_subscription_id column
ALTER TABLE healthcare_providers
ADD COLUMN IF NOT EXISTS medic_subscription_id UUID REFERENCES medic_subscriptions(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_providers_medic_subscription_id ON healthcare_providers(medic_subscription_id);

COMMENT ON COLUMN healthcare_providers.medic_subscription_id IS 'Links healthcare provider to their medic subscription plan';

-- ============================================================================
-- 6. FIX HEALTHCARE_PROVIDERS RLS POLICY
-- ============================================================================

-- Allow providers to read their own profile (even if unverified)
DROP POLICY IF EXISTS "Providers can view own profile" ON healthcare_providers;
CREATE POLICY "Providers can view own profile"
    ON healthcare_providers FOR SELECT
    USING (user_id = auth.uid());

-- ============================================================================
-- 7. HELPER FUNCTION TO GET SUBSCRIPTION TIER NAME
-- ============================================================================

CREATE OR REPLACE FUNCTION get_medic_subscription_tier_name(tier TEXT)
RETURNS TEXT AS $$
BEGIN
    CASE tier
        WHEN 'free' THEN RETURN 'Free';
        WHEN 'growth' THEN RETURN 'Growth';
        WHEN 'enterprise' THEN RETURN 'Enterprise';
        ELSE RETURN 'Unknown';
    END CASE;
END;
$$ LANGUAGE plpgsql IMMUTABLE;
