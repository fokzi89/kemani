-- ============================================================
-- Migration: Add Onboarding Fields for Owner and Staff
-- ============================================================
-- Purpose: Add fields required for guided onboarding flow
-- Date: 2026-02-08
-- Related: Task T095 - User Story 2 (Multi-Tenant Authentication and Onboarding)

-- ============================================================
-- 1. Add Profile Fields to Users Table
-- ============================================================

-- Add profile picture URL (separate from avatar_url for clarity)
ALTER TABLE users
ADD COLUMN IF NOT EXISTS profile_picture_url TEXT;

-- Add gender field (male/female)
ALTER TABLE users
ADD COLUMN IF NOT EXISTS gender VARCHAR(10) CHECK (gender IN ('male', 'female'));

-- Add onboarding completion timestamp
ALTER TABLE users
ADD COLUMN IF NOT EXISTS onboarding_completed_at TIMESTAMPTZ;

-- Add comments for documentation
COMMENT ON COLUMN users.profile_picture_url IS 'URL to user profile picture uploaded during onboarding';
COMMENT ON COLUMN users.gender IS 'User gender: male or female';
COMMENT ON COLUMN users.onboarding_completed_at IS 'Timestamp when user completed onboarding flow (profile + company/security setup)';

-- ============================================================
-- 2. Add Company/Location Fields to Tenants Table
-- ============================================================

-- Add business type to tenant (in addition to branch-level business type)
ALTER TABLE tenants
ADD COLUMN IF NOT EXISTS business_type business_type;

-- Add full address field
ALTER TABLE tenants
ADD COLUMN IF NOT EXISTS address TEXT;

-- Add country field (full country name)
ALTER TABLE tenants
ADD COLUMN IF NOT EXISTS country VARCHAR(100);

-- Add city field
ALTER TABLE tenants
ADD COLUMN IF NOT EXISTS city VARCHAR(100);

-- Add office address field (more specific than general address)
ALTER TABLE tenants
ADD COLUMN IF NOT EXISTS office_address TEXT;

-- Add latitude and longitude for tenant headquarters (separate from branch coordinates)
ALTER TABLE tenants
ADD COLUMN IF NOT EXISTS latitude DECIMAL(10,8) CHECK (latitude >= -90 AND latitude <= 90);

ALTER TABLE tenants
ADD COLUMN IF NOT EXISTS longitude DECIMAL(11,8) CHECK (longitude >= -180 AND longitude <= 180);

-- Add comments for documentation
COMMENT ON COLUMN tenants.business_type IS 'Primary business type for the tenant company';
COMMENT ON COLUMN tenants.address IS 'General business address';
COMMENT ON COLUMN tenants.country IS 'Country where business is registered (full name from dropdown)';
COMMENT ON COLUMN tenants.city IS 'City where business headquarters is located';
COMMENT ON COLUMN tenants.office_address IS 'Specific office address (more detailed than general address)';
COMMENT ON COLUMN tenants.latitude IS 'Latitude of business headquarters (auto-populated from geocoding)';
COMMENT ON COLUMN tenants.longitude IS 'Longitude of business headquarters (auto-populated from geocoding)';

-- ============================================================
-- 3. Update Constraints
-- ============================================================

-- Make tenant_id nullable in users table (for users in onboarding flow who haven't created tenant yet)
ALTER TABLE users
ALTER COLUMN tenant_id DROP NOT NULL;

-- Update comment on tenant_id
COMMENT ON COLUMN users.tenant_id IS 'Reference to tenant - NULL during owner onboarding before company setup';

-- ============================================================
-- 4. Create Indexes for Performance
-- ============================================================

-- Index on onboarding_completed_at for filtering users who need onboarding
CREATE INDEX IF NOT EXISTS idx_users_onboarding_completed
ON users(onboarding_completed_at)
WHERE onboarding_completed_at IS NULL;

-- Index on tenant business_type for filtering/reporting
CREATE INDEX IF NOT EXISTS idx_tenants_business_type
ON tenants(business_type)
WHERE deleted_at IS NULL;

-- Index on tenant country for regional analytics
CREATE INDEX IF NOT EXISTS idx_tenants_country
ON tenants(country)
WHERE deleted_at IS NULL;

-- Spatial index on tenant coordinates (for location-based queries)
CREATE INDEX IF NOT EXISTS idx_tenants_location
ON tenants(latitude, longitude)
WHERE latitude IS NOT NULL AND longitude IS NOT NULL AND deleted_at IS NULL;

-- ============================================================
-- 5. Update Existing Data (Optional - Set Defaults)
-- ============================================================

-- Mark existing users as having completed onboarding (they were created before this flow existed)
UPDATE users
SET onboarding_completed_at = created_at
WHERE onboarding_completed_at IS NULL
  AND created_at < NOW() - INTERVAL '1 day';

-- Set a default business type for existing tenants (based on their branches)
UPDATE tenants t
SET business_type = (
    SELECT b.business_type
    FROM branches b
    WHERE b.tenant_id = t.id
      AND b.deleted_at IS NULL
    LIMIT 1
)
WHERE t.business_type IS NULL
  AND t.deleted_at IS NULL
  AND EXISTS (
    SELECT 1 FROM branches b
    WHERE b.tenant_id = t.id AND b.deleted_at IS NULL
  );

-- ============================================================
-- Migration Complete
-- ============================================================

-- Verify changes
DO $$
BEGIN
    RAISE NOTICE 'Migration 20260208_add_onboarding_fields completed successfully';
    RAISE NOTICE 'Added to users: profile_picture_url, gender, onboarding_completed_at';
    RAISE NOTICE 'Added to tenants: business_type, address, country, city, office_address, latitude, longitude';
    RAISE NOTICE 'Created 4 new indexes for performance';
END $$;
