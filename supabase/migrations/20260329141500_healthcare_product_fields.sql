-- Expand Products table with Healthcare fields (Medications and Lab Tests)
-- Date: 2026-03-29
-- Source: User provided schema update

-- Add columns to products table if they don't exist
ALTER TABLE products 
  ADD COLUMN IF NOT EXISTS unit_of_measure VARCHAR(20) DEFAULT 'piece',
  ADD COLUMN IF NOT EXISTS product_type TEXT,
  ADD COLUMN IF NOT EXISTS generic_name TEXT,
  ADD COLUMN IF NOT EXISTS strength TEXT,
  ADD COLUMN IF NOT EXISTS dosage_form TEXT,
  ADD COLUMN IF NOT EXISTS manufacturer TEXT,
  ADD COLUMN IF NOT EXISTS test_name TEXT,
  ADD COLUMN IF NOT EXISTS sample_type TEXT;

-- Comments for the new fields
COMMENT ON COLUMN products.unit_of_measure IS 'Unit of measurement (e.g., piece, box, ml)';
COMMENT ON COLUMN products.product_type IS 'Type categorization (e.g., medication, service, test)';
COMMENT ON COLUMN products.generic_name IS 'Active pharmaceutical ingredient name';
COMMENT ON COLUMN products.strength IS 'Concentration or potency (e.g., 500mg, 10mg/ml)';
COMMENT ON COLUMN products.dosage_form IS 'Physical form (e.g., tablet, syrup, injection)';
COMMENT ON COLUMN products.manufacturer IS 'Producing company or laboratory';
COMMENT ON COLUMN products.test_name IS 'Full descriptive name of laboratory test';
COMMENT ON COLUMN products.sample_type IS 'Specimen requirement for tests (e.g., blood, urine)';

-- Re-syncing triggers and indexes as specified in the provided schema
-- Note: Some of these may already exist, so we use IF NOT EXISTS or DROP/CREATE

-- Indexes as specified in prompt
CREATE INDEX IF NOT EXISTS idx_products_brand ON public.products(brand_id) WHERE (brand_id is not null);
CREATE INDEX IF NOT EXISTS idx_products_category ON public.products(category_id) WHERE (category_id is not null);

-- Ensure sync triggers are active on products (standard project triggers)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'increment_sync_version' AND tgrelid = 'public.products'::regclass) THEN
        CREATE TRIGGER increment_sync_version BEFORE UPDATE ON products
            FOR EACH ROW EXECUTE FUNCTION increment_sync_version();
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'set_updated_at' AND tgrelid = 'public.products'::regclass) THEN
        CREATE TRIGGER set_updated_at BEFORE UPDATE ON products
            FOR EACH ROW EXECUTE FUNCTION update_updated_at();
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_track_product_price_change' AND tgrelid = 'public.products'::regclass) THEN
        CREATE TRIGGER trg_track_product_price_change AFTER UPDATE ON products
            FOR EACH ROW EXECUTE FUNCTION track_product_price_change();
    END IF;
END $$;
