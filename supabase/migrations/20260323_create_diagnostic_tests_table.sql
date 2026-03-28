-- ============================================================================
-- CREATE DIAGNOSTIC TESTS CATALOG TABLE
-- ============================================================================
-- This table stores a global list of lab tests, imaging, and other 
-- investigations for predictive search when doctors order tests.
-- ============================================================================

CREATE TABLE IF NOT EXISTS diagnostic_tests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Core identification
    name TEXT NOT NULL, -- Full name (e.g., "Complete Blood Count")
    code TEXT,          -- Short code/LOINC (e.g., "CBC")
    category TEXT,      -- Department (e.g., "Hematology", "Radiology")
    
    -- Clinical Context
    specimen_type TEXT,            -- What's collected (e.g., "Blood")
    preparation_instructions TEXT, -- Patient prep (e.g., "Fast for 12 hours")
    description TEXT,              -- What it indicates
    
    -- System fields
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add indexes for fast predictive autocomplete searches
CREATE INDEX IF NOT EXISTS idx_diagnostic_tests_name ON diagnostic_tests USING gin (name gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_diagnostic_tests_code ON diagnostic_tests USING gin (code gin_trgm_ops);

-- ============================================================================
-- TRIGGERS
-- ============================================================================

-- Automatically update the updated_at timestamp
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_diagnostic_tests_updated_at') THEN
        CREATE TRIGGER update_diagnostic_tests_updated_at
            BEFORE UPDATE ON diagnostic_tests
            FOR EACH ROW
            EXECUTE FUNCTION update_updated_at_column();
    END IF;
END $$;

-- ============================================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================================

ALTER TABLE diagnostic_tests ENABLE ROW LEVEL SECURITY;

-- Allow all authenticated users (Doctors/Providers/Patients) to read the catalog
DROP POLICY IF EXISTS "Anyone can view active diagnostic tests" ON diagnostic_tests;
CREATE POLICY "Anyone can view active diagnostic tests"
    ON diagnostic_tests FOR SELECT
    TO authenticated
    USING (is_active = true);

-- Note: INSERT, UPDATE, and DELETE are restricted to Admin/Service Role by default.
