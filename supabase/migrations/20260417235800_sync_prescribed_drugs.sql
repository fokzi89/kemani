-- ============================================================================
-- Sync prescribed_drugs table with user specifications
-- ============================================================================

-- 1. Rename drug_id to product_id if it exists
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'prescribed_drugs' AND column_name = 'drug_id'
    ) THEN
        ALTER TABLE prescribed_drugs RENAME COLUMN drug_id TO product_id;
    END IF;
END $$;

-- 2. Drop existing foreign key on product_id/drug_id if it exists to clean up
DO $$
DECLARE
    v_constraint_name TEXT;
BEGIN
    SELECT constraint_name INTO v_constraint_name
    FROM information_schema.key_column_usage
    WHERE table_name = 'prescribed_drugs' AND column_name = 'product_id';
    
    IF v_constraint_name IS NOT NULL THEN
        EXECUTE 'ALTER TABLE prescribed_drugs DROP CONSTRAINT IF EXISTS ' || v_constraint_name;
    END IF;
END $$;

-- 3. Add proper foreign key to products
ALTER TABLE prescribed_drugs 
    ADD CONSTRAINT prescribed_drugs_product_id_fkey 
    FOREIGN KEY (product_id) REFERENCES products(id);

-- 4. Ensure all columns from the user's spec exist
ALTER TABLE prescribed_drugs ADD COLUMN IF NOT EXISTS generic_name TEXT;
ALTER TABLE prescribed_drugs ADD COLUMN IF NOT EXISTS dispense_as TEXT;
ALTER TABLE prescribed_drugs ADD COLUMN IF NOT EXISTS dispense_quantity INTEGER;
ALTER TABLE prescribed_drugs ADD COLUMN IF NOT EXISTS dosage TEXT;
ALTER TABLE prescribed_drugs ADD COLUMN IF NOT EXISTS frequency TEXT;
ALTER TABLE prescribed_drugs ADD COLUMN IF NOT EXISTS drug_pic_url TEXT;
ALTER TABLE prescribed_drugs ADD COLUMN IF NOT EXISTS duration TEXT;
ALTER TABLE prescribed_drugs ADD COLUMN IF NOT EXISTS special_instructions TEXT;
ALTER TABLE prescribed_drugs ADD COLUMN IF NOT EXISTS substitution_allowed BOOLEAN DEFAULT true;
ALTER TABLE prescribed_drugs ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'pending';

-- 5. Update status check constraint
ALTER TABLE prescribed_drugs DROP CONSTRAINT IF EXISTS prescribed_drugs_status_check;
ALTER TABLE prescribed_drugs ADD CONSTRAINT prescribed_drugs_status_check 
    CHECK (status IN ('pending', 'dispensed', 'out_of_stock', 'cancelled'));

-- 6. Ensure updated_at trigger exists
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_prescribed_drugs_updated_at') THEN
        CREATE TRIGGER update_prescribed_drugs_updated_at
            BEFORE UPDATE ON prescribed_drugs
            FOR EACH ROW
            EXECUTE FUNCTION update_updated_at_column();
    END IF;
END $$;
