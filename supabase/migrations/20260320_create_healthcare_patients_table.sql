-- ============================================================
-- Healthcare Patients Table - Clean Separation
-- ============================================================
-- Purpose: Create dedicated patients table for healthcare providers
-- This avoids conflicts with the tenant-based customers table

-- ============================================================
-- Step 1: Remove obsolete columns from customers table
-- ============================================================

-- Drop the policies we created earlier (they're not working anyway)
DROP POLICY IF EXISTS "Healthcare providers can view their patients" ON customers;
DROP POLICY IF EXISTS "Healthcare providers can insert patients" ON customers;
DROP POLICY IF EXISTS "Healthcare providers can update their patients" ON customers;
DROP POLICY IF EXISTS "Healthcare providers can soft delete patients" ON customers;
DROP POLICY IF EXISTS "Tenant members can view customers" ON customers;
DROP POLICY IF EXISTS "Tenant members can insert customers" ON customers;
DROP POLICY IF EXISTS "Tenant members can update customers" ON customers;
DROP POLICY IF EXISTS "Tenant members can delete customers" ON customers;

-- Recreate the original simple policy for customers
CREATE POLICY "Customer tenant isolation" ON customers
    FOR ALL USING (tenant_id = current_tenant_id());

-- Drop obsolete columns from customers (if they exist)
ALTER TABLE customers DROP COLUMN IF EXISTS healthcare_provider_id;
ALTER TABLE customers DROP COLUMN IF EXISTS is_deleted;

-- ============================================================
-- Step 2: Create dedicated patients table
-- ============================================================

CREATE TABLE IF NOT EXISTS patients (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Link to healthcare provider
    healthcare_provider_id UUID NOT NULL REFERENCES healthcare_providers(id) ON DELETE CASCADE,

    -- Link to unified patient profile (for cross-tenant medical history)
    unified_patient_id UUID REFERENCES unified_patient_profiles(id) ON DELETE SET NULL,

    -- Patient Information
    full_name VARCHAR(255) NOT NULL,
    email VARCHAR(255),
    phone VARCHAR(20) NOT NULL,
    whatsapp_number VARCHAR(20),
    date_of_birth DATE,
    gender VARCHAR(20),

    -- Profile
    profile_photo_url TEXT,

    -- Medical Info (optional, can be expanded)
    blood_group VARCHAR(10),
    allergies TEXT[],
    chronic_conditions TEXT[],
    emergency_contact_name VARCHAR(255),
    emergency_contact_phone VARCHAR(20),

    -- Soft delete
    is_deleted BOOLEAN DEFAULT FALSE,
    deleted_at TIMESTAMPTZ,

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    -- Ensure phone is unique per provider (can't add same patient twice)
    UNIQUE(healthcare_provider_id, phone)
);

-- ============================================================
-- Step 3: Indexes for performance
-- ============================================================

CREATE INDEX idx_patients_provider ON patients(healthcare_provider_id) WHERE is_deleted = FALSE;
CREATE INDEX idx_patients_unified ON patients(unified_patient_id);
CREATE INDEX idx_patients_phone ON patients(phone);
CREATE INDEX idx_patients_email ON patients(email) WHERE email IS NOT NULL;
CREATE INDEX idx_patients_deleted ON patients(is_deleted);

-- ============================================================
-- Step 4: Enable RLS
-- ============================================================

ALTER TABLE patients ENABLE ROW LEVEL SECURITY;

-- Providers can view their own patients (not deleted)
CREATE POLICY "Providers can view their patients"
ON patients FOR SELECT
USING (
    healthcare_provider_id IN (
        SELECT id FROM healthcare_providers
        WHERE user_id = auth.uid()
    )
    AND is_deleted = FALSE
);

-- Providers can insert patients
CREATE POLICY "Providers can insert patients"
ON patients FOR INSERT
WITH CHECK (
    healthcare_provider_id IN (
        SELECT id FROM healthcare_providers
        WHERE user_id = auth.uid()
    )
);

-- Providers can update their patients
CREATE POLICY "Providers can update their patients"
ON patients FOR UPDATE
USING (
    healthcare_provider_id IN (
        SELECT id FROM healthcare_providers
        WHERE user_id = auth.uid()
    )
)
WITH CHECK (
    healthcare_provider_id IN (
        SELECT id FROM healthcare_providers
        WHERE user_id = auth.uid()
    )
);

-- Providers can delete (soft delete) their patients
CREATE POLICY "Providers can delete their patients"
ON patients FOR DELETE
USING (
    healthcare_provider_id IN (
        SELECT id FROM healthcare_providers
        WHERE user_id = auth.uid()
    )
);

-- ============================================================
-- Step 5: Trigger to update timestamps
-- ============================================================

CREATE OR REPLACE FUNCTION update_patients_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_patients_timestamp_trigger ON patients;
CREATE TRIGGER update_patients_timestamp_trigger
    BEFORE UPDATE ON patients
    FOR EACH ROW
    EXECUTE FUNCTION update_patients_timestamp();

-- ============================================================
-- Step 6: Function to link patient to unified profile
-- ============================================================

CREATE OR REPLACE FUNCTION link_patient_to_unified_profile()
RETURNS TRIGGER AS $$
DECLARE
    v_unified_patient_id UUID;
BEGIN
    -- Only create link if email or phone is provided
    IF NEW.email IS NOT NULL OR NEW.phone IS NOT NULL THEN
        -- Find or create unified patient profile
        v_unified_patient_id := find_or_create_unified_patient(
            NEW.email,
            NEW.phone,
            NEW.full_name
        );

        -- Update the patient record with unified_patient_id
        NEW.unified_patient_id := v_unified_patient_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS link_patient_to_unified_trigger ON patients;
CREATE TRIGGER link_patient_to_unified_trigger
    BEFORE INSERT ON patients
    FOR EACH ROW
    EXECUTE FUNCTION link_patient_to_unified_profile();

-- ============================================================
-- Step 7: Update consultations to reference patients table
-- ============================================================

-- Add a new column for healthcare patients
ALTER TABLE consultations
ADD COLUMN IF NOT EXISTS healthcare_patient_id UUID REFERENCES patients(id) ON DELETE SET NULL;

-- Create index for fast lookups
CREATE INDEX IF NOT EXISTS idx_consultations_healthcare_patient
ON consultations(healthcare_patient_id);

-- ============================================================
-- Step 8: Helper function to get patient stats
-- ============================================================

CREATE OR REPLACE FUNCTION get_patient_consultation_stats(p_patient_id UUID)
RETURNS TABLE (
    total_consultations INTEGER,
    last_consultation_date TIMESTAMPTZ,
    last_consultation_type VARCHAR(50)
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        COUNT(*)::INTEGER as total_consultations,
        MAX(c.created_at) as last_consultation_date,
        (SELECT type FROM consultations
         WHERE healthcare_patient_id = p_patient_id
         ORDER BY created_at DESC
         LIMIT 1) as last_consultation_type
    FROM consultations c
    WHERE c.healthcare_patient_id = p_patient_id;
END;
$$ LANGUAGE plpgsql STABLE;

-- ============================================================
-- Comments for documentation
-- ============================================================

COMMENT ON TABLE patients IS 'Dedicated patients table for healthcare providers, separate from POS customers';
COMMENT ON COLUMN patients.healthcare_provider_id IS 'Provider who manages this patient';
COMMENT ON COLUMN patients.unified_patient_id IS 'Link to unified patient profile for cross-provider medical history';
COMMENT ON COLUMN patients.is_deleted IS 'Soft delete flag - keeps historical data but hides from UI';
COMMENT ON FUNCTION link_patient_to_unified_profile IS 'Automatically links new patients to unified patient profiles';
COMMENT ON FUNCTION get_patient_consultation_stats IS 'Returns consultation statistics for a patient';
