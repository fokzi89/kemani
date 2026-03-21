-- Link Healthcare Providers to Existing Subscriptions Table
-- Date: 2026-03-19
--
-- This migration adds a subscription_id column to healthcare_providers
-- to reference the existing subscriptions table used by the POS app

-- ============================================================================
-- ADD SUBSCRIPTION_ID TO HEALTHCARE_PROVIDERS
-- ============================================================================

ALTER TABLE healthcare_providers
ADD COLUMN IF NOT EXISTS subscription_id UUID REFERENCES subscriptions(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_providers_subscription_id ON healthcare_providers(subscription_id);

COMMENT ON COLUMN healthcare_providers.subscription_id IS 'Links healthcare provider to their subscription plan (shared with POS tenants)';
