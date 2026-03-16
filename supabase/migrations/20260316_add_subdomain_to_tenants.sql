-- Add subdomain column to tenants table
-- Feature: 004-tenant-referral-commissions
-- Fix: Tenant table uses 'slug' but commission system expects 'subdomain'

-- Option 1: Add subdomain column and sync with slug
ALTER TABLE tenants
ADD COLUMN IF NOT EXISTS subdomain VARCHAR(100);

-- Copy existing slug values to subdomain
UPDATE tenants
SET subdomain = slug
WHERE subdomain IS NULL;

-- Make subdomain unique
ALTER TABLE tenants
ADD CONSTRAINT tenants_subdomain_unique UNIQUE (subdomain);

-- Create trigger to keep subdomain and slug in sync
CREATE OR REPLACE FUNCTION sync_subdomain_with_slug()
RETURNS TRIGGER AS $$
BEGIN
    -- When slug changes, update subdomain
    IF NEW.slug IS DISTINCT FROM OLD.slug THEN
        NEW.subdomain := NEW.slug;
    END IF;

    -- When subdomain changes, update slug
    IF NEW.subdomain IS DISTINCT FROM OLD.subdomain THEN
        NEW.slug := NEW.subdomain;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger
DROP TRIGGER IF EXISTS sync_subdomain_trigger ON tenants;
CREATE TRIGGER sync_subdomain_trigger
    BEFORE UPDATE ON tenants
    FOR EACH ROW
    EXECUTE FUNCTION sync_subdomain_with_slug();

-- Comment
COMMENT ON COLUMN tenants.subdomain IS 'Subdomain for referral tracking (synced with slug)';
