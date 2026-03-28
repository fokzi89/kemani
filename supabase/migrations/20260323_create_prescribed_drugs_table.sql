-- ============================================================================
-- PRESCRIBED DRUGS & PRESCRIPTIONS TABLE UPDATES
-- ============================================================================

-- 1. Modify the existing `prescriptions` table
--    - Drop the old JSONB array for medications
--    - Update the patient_id foreign key constraint to reference the `patients` table instead of `auth.users`

ALTER TABLE prescriptions DROP COLUMN IF EXISTS medications;

-- Dynamically drop the old foreign key constraint if it exists (usually named prescriptions_patient_id_fkey)
ALTER TABLE prescriptions DROP CONSTRAINT IF EXISTS prescriptions_patient_id_fkey;

-- Add the new foreign key referencing the `patients` table
ALTER TABLE prescriptions 
    ADD CONSTRAINT prescriptions_patient_id_fkey 
    FOREIGN KEY (patient_id) REFERENCES patients(id) ON DELETE RESTRICT;

-- ============================================================================
-- 2. CREATE `prescribed_drugs` TABLE
-- ============================================================================
-- This table replaces the old JSONB array, normalizing each drug dispensed 
-- into its own relational row for better tracking and inventory management.

CREATE TABLE IF NOT EXISTS prescribed_drugs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    prescription_id UUID NOT NULL REFERENCES prescriptions(id) ON DELETE CASCADE,
    drug_id UUID REFERENCES drugs(id) ON DELETE SET NULL, -- References the new global drugs catalog
    
    -- Drug Details (Denormalized so the prescription record is immutable even if the catalog changes)
    name TEXT NOT NULL,
    generic_name TEXT,
    
    -- Instructions & Dispensing
    dispense_as TEXT,             -- e.g., "pack", "bottle", "unit"
    dispense_quantity INT,        -- Total amount to give
    dosage TEXT,                  -- e.g., "500mg"
    frequency TEXT,               -- e.g., "Twice daily (BD)"
    duration TEXT,                -- e.g., "5 days"
    special_instructions TEXT,    -- e.g., "Take after meals"
    substitution_allowed BOOLEAN DEFAULT true, -- Allows generic swapping
    
    -- Tracking the status of this specific drug
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'dispensed', 'out_of_stock', 'cancelled')),
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_prescribed_drugs_prescription_id ON prescribed_drugs(prescription_id);
CREATE INDEX IF NOT EXISTS idx_prescribed_drugs_drug_id ON prescribed_drugs(drug_id);

-- ============================================================================
-- TRIGGERS
-- ============================================================================

-- Automatically update the updated_at timestamp
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_prescribed_drugs_updated_at') THEN
        CREATE TRIGGER update_prescribed_drugs_updated_at
            BEFORE UPDATE ON prescribed_drugs
            FOR EACH ROW
            EXECUTE FUNCTION update_updated_at_column();
    END IF;
END $$;

-- ============================================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================================

ALTER TABLE prescribed_drugs ENABLE ROW LEVEL SECURITY;

-- Allow all authenticated users involved to view the prescribed drugs
-- Since this references `prescriptions`, anyone who can see the prescription 
-- should generally be able to see the drugs on it.
DROP POLICY IF EXISTS "Anyone can view prescribed drugs" ON prescribed_drugs;
CREATE POLICY "Anyone can view prescribed drugs"
    ON prescribed_drugs FOR SELECT
    TO authenticated
    USING (true);

-- Doctors can create/insert records
DROP POLICY IF EXISTS "Doctors can insert prescribed drugs" ON prescribed_drugs;
CREATE POLICY "Doctors can insert prescribed drugs"
    ON prescribed_drugs FOR INSERT
    TO authenticated
    WITH CHECK (true);

-- Allow status updates (e.g., pharmacy fulfilling a specific drug)
DROP POLICY IF EXISTS "Authenticated users can update prescribed drugs" ON prescribed_drugs;
CREATE POLICY "Authenticated users can update prescribed drugs"
    ON prescribed_drugs FOR UPDATE
    TO authenticated
    USING (true)
    WITH CHECK (true);
