-- ============================================================
-- Healthcare Provider Patient Management
-- ============================================================
-- Purpose: Link customers to healthcare providers as their patients
-- Add profile photos and soft delete support for patient management

-- Add healthcare_provider_id to customers table (patients added by providers)
ALTER TABLE customers
ADD COLUMN IF NOT EXISTS healthcare_provider_id UUID REFERENCES healthcare_providers(id) ON DELETE SET NULL;

-- Add profile photo support for patients
ALTER TABLE customers
ADD COLUMN IF NOT EXISTS profile_photo_url TEXT;

-- Add is_deleted column for soft delete (separate from sync)
ALTER TABLE customers
ADD COLUMN IF NOT EXISTS is_deleted BOOLEAN DEFAULT FALSE;

-- Index for fast provider patient lookups
CREATE INDEX IF NOT EXISTS idx_customers_provider_id
ON customers(healthcare_provider_id)
WHERE is_deleted = FALSE;

-- Index for profile photos
CREATE INDEX IF NOT EXISTS idx_customers_profile_photo
ON customers(profile_photo_url)
WHERE profile_photo_url IS NOT NULL;

-- Update unified_patient_profiles to include profile photo
ALTER TABLE unified_patient_profiles
ADD COLUMN IF NOT EXISTS profile_photo_url TEXT;

-- ============================================================
-- RLS Policies for Provider-Patient Access
-- ============================================================

-- Providers can view their own patients
CREATE POLICY "Providers can view their patients"
ON customers FOR SELECT
USING (
    healthcare_provider_id IN (
        SELECT id FROM healthcare_providers
        WHERE user_id = auth.uid()
    )
    AND is_deleted = FALSE
);

-- Providers can insert patients
CREATE POLICY "Providers can add patients"
ON customers FOR INSERT
WITH CHECK (
    healthcare_provider_id IN (
        SELECT id FROM healthcare_providers
        WHERE user_id = auth.uid()
    )
);

-- Providers can update their patients
CREATE POLICY "Providers can update their patients"
ON customers FOR UPDATE
USING (
    healthcare_provider_id IN (
        SELECT id FROM healthcare_providers
        WHERE user_id = auth.uid()
    )
);

-- Providers can soft delete their patients (update is_deleted)
CREATE POLICY "Providers can soft delete their patients"
ON customers FOR UPDATE
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

-- ============================================================
-- Helper Function: Get Provider's Patients
-- ============================================================

CREATE OR REPLACE FUNCTION get_provider_patients(
    p_provider_id UUID
)
RETURNS TABLE (
    id UUID,
    full_name VARCHAR(255),
    email VARCHAR(255),
    phone VARCHAR(20),
    profile_photo_url TEXT,
    unified_patient_id UUID,
    total_consultations INTEGER,
    last_consultation_date TIMESTAMPTZ,
    created_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        c.id,
        c.full_name,
        c.email,
        c.phone,
        c.profile_photo_url,
        pal.unified_patient_id,
        COALESCE(
            (SELECT COUNT(*)::INTEGER
             FROM consultations
             WHERE patient_id = c.id
             AND provider_id = p_provider_id),
            0
        ) as total_consultations,
        (SELECT MAX(created_at)
         FROM consultations
         WHERE patient_id = c.id
         AND provider_id = p_provider_id) as last_consultation_date,
        c.created_at
    FROM customers c
    LEFT JOIN patient_account_links pal ON c.id = pal.customer_id
    WHERE c.healthcare_provider_id = p_provider_id
    AND c.is_deleted = FALSE
    ORDER BY c.created_at DESC;
END;
$$ LANGUAGE plpgsql STABLE;

-- ============================================================
-- Comments
-- ============================================================

COMMENT ON COLUMN customers.healthcare_provider_id IS 'Provider who added this patient to their practice';
COMMENT ON COLUMN customers.profile_photo_url IS 'Patient profile picture URL';
COMMENT ON COLUMN customers.is_deleted IS 'Soft delete flag for patient records';
COMMENT ON FUNCTION get_provider_patients IS 'Returns all active patients for a healthcare provider with consultation stats';
