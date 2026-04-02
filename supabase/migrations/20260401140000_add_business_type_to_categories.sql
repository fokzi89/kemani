-- Add 'diagnostics' to business_type enum
ALTER TYPE business_type ADD VALUE IF NOT EXISTS 'diagnostics';

-- Add business_type column to categories
ALTER TABLE categories ADD COLUMN IF NOT EXISTS business_type business_type;

COMMENT ON COLUMN categories.business_type IS 'The type of business this category belongs to (e.g., pharmacy, supermarket, diagnostics).';
