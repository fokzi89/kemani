-- ============================================================
-- ADD NEW BUSINESS TYPES
-- ============================================================

-- Add 'diagnostic_centre' and 'pharmacy_supermarket' to the business_type enum
-- Since Postgres doesn't allow dropping enum values easily, we'll just add the new ones

ALTER TYPE business_type ADD VALUE IF NOT EXISTS 'diagnostic_centre';
ALTER TYPE business_type ADD VALUE IF NOT EXISTS 'pharmacy_supermarket';
