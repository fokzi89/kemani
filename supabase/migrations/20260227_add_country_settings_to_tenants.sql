-- ============================================================
-- Migration: Add Country Settings to Tenants Table
-- ============================================================
-- Purpose: Add country_code, dial_code, and currency_code to tenants table
-- This fixes the schema mismatch where country settings were incorrectly
-- being saved to a non-existent profiles table instead of the tenants table.
--
-- User Story: US2 - Multi-Tenant Isolation and Email/Google Authentication
-- Acceptance Scenario: AS3 - System saves country code, dial code, currency code to tenant
--
-- Created: 2026-02-27

-- Add country settings columns to tenants table
ALTER TABLE tenants
ADD COLUMN IF NOT EXISTS country_code VARCHAR(2),
ADD COLUMN IF NOT EXISTS dial_code VARCHAR(10),
ADD COLUMN IF NOT EXISTS currency_code VARCHAR(3);

-- Add comments to document the fields
COMMENT ON COLUMN tenants.country_code IS
'ISO 3166-1 alpha-2 country code (e.g., "NG" for Nigeria, "US" for USA). Selected during tenant onboarding.';

COMMENT ON COLUMN tenants.dial_code IS
'International dialing code including + prefix (e.g., "+234" for Nigeria, "+1" for USA). Auto-populated based on country_code.';

COMMENT ON COLUMN tenants.currency_code IS
'ISO 4217 currency code (e.g., "NGN" for Nigerian Naira, "USD" for US Dollar). Auto-populated based on country_code and used for all pricing/transactions in this tenant.';

-- Add index for country-based queries (useful for analytics, regional reporting)
CREATE INDEX IF NOT EXISTS idx_tenants_country_code ON tenants(country_code)
WHERE country_code IS NOT NULL AND deleted_at IS NULL;

-- Add check constraint to ensure valid ISO codes if provided
ALTER TABLE tenants
ADD CONSTRAINT chk_country_code_format CHECK (
    country_code IS NULL OR (
        country_code ~ '^[A-Z]{2}$'
    )
);

ALTER TABLE tenants
ADD CONSTRAINT chk_dial_code_format CHECK (
    dial_code IS NULL OR (
        dial_code ~ '^\+[0-9]{1,4}$'
    )
);

ALTER TABLE tenants
ADD CONSTRAINT chk_currency_code_format CHECK (
    currency_code IS NULL OR (
        currency_code ~ '^[A-Z]{3}$'
    )
);

-- Note: We're not migrating data from profiles table because it doesn't exist
-- in the current schema. The Flutter app was incorrectly trying to save to it.

-- ============================================================
-- Also add gender field to users table (for user profiles)
-- ============================================================

ALTER TABLE users
ADD COLUMN IF NOT EXISTS gender VARCHAR(10);

COMMENT ON COLUMN users.gender IS
'User gender for profile (e.g., "male", "female", "other"). Optional field.';

-- Add check constraint for gender values
ALTER TABLE users
ADD CONSTRAINT chk_gender_values CHECK (
    gender IS NULL OR gender IN ('male', 'female', 'other')
);

-- Verification query to show updated schema
SELECT
    table_name,
    column_name,
    data_type,
    character_maximum_length,
    column_default,
    is_nullable
FROM information_schema.columns
WHERE table_name = 'tenants'
    AND column_name IN ('country_code', 'dial_code', 'currency_code')
ORDER BY ordinal_position;
