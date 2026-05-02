-- ============================================
-- Migration: Tenant Branding Fields
-- Description: Adds logo_url (ensure exists), slogan, hero_title, 
--              hero_subtitle, and about_us to tenants table.
-- Created: 2026-05-02
-- ============================================

ALTER TABLE tenants 
ADD COLUMN IF NOT EXISTS slogan TEXT,
ADD COLUMN IF NOT EXISTS hero_title TEXT,
ADD COLUMN IF NOT EXISTS hero_subtitle TEXT,
ADD COLUMN IF NOT EXISTS about_us TEXT;

-- Update comments for clarity
COMMENT ON COLUMN tenants.logo_url IS 'URL to the tenant business logo';
COMMENT ON COLUMN tenants.slogan IS 'Short company slogan or catchphrase';
COMMENT ON COLUMN tenants.hero_title IS 'Main title displayed on the storefront hero section';
COMMENT ON COLUMN tenants.hero_subtitle IS 'Subtitle or description displayed below the hero title';
COMMENT ON COLUMN tenants.about_us IS 'Detailed information about the business for the footer/about page';
