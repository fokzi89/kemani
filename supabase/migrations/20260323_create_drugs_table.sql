-- ============================================================================
-- CREATE DRUGS CATALOG TABLE
-- ============================================================================
-- This table stores a global list of medications to be used in
-- predictive search during prescription creation by doctors.
-- ============================================================================

CREATE TABLE IF NOT EXISTS drugs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Core identification
    name TEXT NOT NULL, -- Primary display name (e.g., "Paracetamol 500mg Tablet")
    generic_name TEXT,  -- Active ingredient (e.g., "Acetaminophen")
    brand_name TEXT,    -- Commercial brand name
    manufacturer TEXT,  -- Producing company
    
    -- Formulation & Dosage
    dosage_form TEXT,   -- Form (e.g., "Tablet", "Syrup", "Injection")
    strength TEXT,      -- Concentration (e.g., "500 mg", "10 mg/ml")
    route_of_administration TEXT, -- How it's taken (e.g., "Oral", "Intravenous")
    
    -- Medical Information
    description TEXT,
    side_effects TEXT,
    contraindications TEXT,
    
    -- System fields
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add an index on the name for faster predictive autocomplete searches
CREATE INDEX IF NOT EXISTS idx_drugs_name ON drugs USING gin (name gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_drugs_generic_name ON drugs USING gin (generic_name gin_trgm_ops);

-- ============================================================================
-- TRIGGERS
-- ============================================================================

-- Automatically update the updated_at timestamp
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_drugs_updated_at') THEN
        CREATE TRIGGER update_drugs_updated_at
            BEFORE UPDATE ON drugs
            FOR EACH ROW
            EXECUTE FUNCTION update_updated_at_column();
    END IF;
END $$;

-- ============================================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================================

ALTER TABLE drugs ENABLE ROW LEVEL SECURITY;

-- Allow all authenticated users (Doctors/Providers/Patients) to read the drugs list
DROP POLICY IF EXISTS "Anyone can view active drugs" ON drugs;
CREATE POLICY "Anyone can view active drugs"
    ON drugs FOR SELECT
    TO authenticated
    USING (is_active = true);

-- Note: INSERT, UPDATE, and DELETE are intentionally omitted here.
-- Only the Service Role (Supabase Admin) will be able to modify the drug catalog 
-- by default unless explicitly granted.
