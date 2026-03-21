-- ============================================================================
-- HEALTHCARE PROVIDER PROFILE EDITING SUPPORT
-- ============================================================================
-- This migration adds support for comprehensive provider profile editing:
-- - Work experience management
-- - Certificate uploads with metadata
-- - License uploads with metadata
-- - Sub-specialty field
-- - Preferred languages array field
-- ============================================================================

-- ============================================================================
-- PROVIDER WORK EXPERIENCE TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS provider_work_experience (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    provider_id UUID NOT NULL REFERENCES healthcare_providers(id) ON DELETE CASCADE,

    -- Work Details
    position TEXT NOT NULL,
    organization TEXT NOT NULL,
    location TEXT,
    start_date DATE NOT NULL,
    end_date DATE, -- NULL if current position
    is_current BOOLEAN DEFAULT FALSE,
    description TEXT,

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_work_experience_provider ON provider_work_experience(provider_id);
CREATE INDEX idx_work_experience_dates ON provider_work_experience(start_date DESC, end_date DESC);

-- RLS Policies
ALTER TABLE provider_work_experience ENABLE ROW LEVEL SECURITY;

-- Providers can manage their own work experience
CREATE POLICY "Providers can manage own work experience"
    ON provider_work_experience FOR ALL
    USING (provider_id IN (SELECT id FROM healthcare_providers WHERE user_id = auth.uid()));

-- Public read for verified providers
CREATE POLICY "Anyone can view verified provider work experience"
    ON provider_work_experience FOR SELECT
    USING (
        provider_id IN (
            SELECT id FROM healthcare_providers
            WHERE is_active = TRUE AND is_verified = TRUE
        )
    );

-- ============================================================================
-- PROVIDER CERTIFICATES TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS provider_certificates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    provider_id UUID NOT NULL REFERENCES healthcare_providers(id) ON DELETE CASCADE,

    -- Certificate Details
    certificate_name TEXT NOT NULL,
    issuing_organization TEXT NOT NULL,
    issue_date DATE NOT NULL,
    expiry_date DATE, -- NULL if no expiry
    certificate_number TEXT,

    -- File Storage
    file_url TEXT NOT NULL, -- Supabase Storage URL
    file_name TEXT NOT NULL,
    file_size INTEGER, -- bytes
    file_type TEXT, -- PDF, image/jpeg, etc.

    -- Verification
    is_verified BOOLEAN DEFAULT FALSE,
    verified_at TIMESTAMPTZ,
    verified_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_certificates_provider ON provider_certificates(provider_id);
CREATE INDEX idx_certificates_expiry ON provider_certificates(expiry_date) WHERE expiry_date IS NOT NULL;

-- RLS Policies
ALTER TABLE provider_certificates ENABLE ROW LEVEL SECURITY;

-- Providers can manage their own certificates
CREATE POLICY "Providers can manage own certificates"
    ON provider_certificates FOR ALL
    USING (provider_id IN (SELECT id FROM healthcare_providers WHERE user_id = auth.uid()));

-- Public read for verified providers
CREATE POLICY "Anyone can view verified provider certificates"
    ON provider_certificates FOR SELECT
    USING (
        provider_id IN (
            SELECT id FROM healthcare_providers
            WHERE is_active = TRUE AND is_verified = TRUE
        )
    );

-- ============================================================================
-- PROVIDER LICENSES TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS provider_licenses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    provider_id UUID NOT NULL REFERENCES healthcare_providers(id) ON DELETE CASCADE,

    -- License Details
    license_type TEXT NOT NULL, -- 'Medical License', 'Pharmacy License', etc.
    license_number TEXT NOT NULL,
    issuing_authority TEXT NOT NULL, -- 'MDCN', 'PCN', etc.
    issue_date DATE NOT NULL,
    expiry_date DATE NOT NULL,
    country TEXT NOT NULL,
    state_region TEXT,

    -- File Storage
    file_url TEXT NOT NULL, -- Supabase Storage URL
    file_name TEXT NOT NULL,
    file_size INTEGER, -- bytes
    file_type TEXT,

    -- Verification
    is_verified BOOLEAN DEFAULT FALSE,
    verified_at TIMESTAMPTZ,
    verified_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,

    -- Status
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'expired', 'revoked', 'suspended')),

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    -- Constraints
    CONSTRAINT valid_license_dates CHECK (expiry_date > issue_date)
);

CREATE INDEX idx_licenses_provider ON provider_licenses(provider_id);
CREATE INDEX idx_licenses_expiry ON provider_licenses(expiry_date);
CREATE INDEX idx_licenses_status ON provider_licenses(status, provider_id);

-- RLS Policies
ALTER TABLE provider_licenses ENABLE ROW LEVEL SECURITY;

-- Providers can manage their own licenses
CREATE POLICY "Providers can manage own licenses"
    ON provider_licenses FOR ALL
    USING (provider_id IN (SELECT id FROM healthcare_providers WHERE user_id = auth.uid()));

-- Public read for verified providers with active licenses
CREATE POLICY "Anyone can view verified provider licenses"
    ON provider_licenses FOR SELECT
    USING (
        provider_id IN (
            SELECT id FROM healthcare_providers
            WHERE is_active = TRUE AND is_verified = TRUE
        )
    );

-- ============================================================================
-- ADD NEW FIELDS TO HEALTHCARE_PROVIDERS TABLE
-- ============================================================================
ALTER TABLE healthcare_providers
ADD COLUMN IF NOT EXISTS sub_specialty TEXT,
ADD COLUMN IF NOT EXISTS preferred_languages TEXT[]; -- Array of languages

-- Create GIN index for array search
CREATE INDEX IF NOT EXISTS idx_providers_languages ON healthcare_providers USING GIN (preferred_languages);

-- Comments
COMMENT ON COLUMN healthcare_providers.sub_specialty IS 'Sub-specialty within main specialization (free text)';
COMMENT ON COLUMN healthcare_providers.preferred_languages IS 'Array of languages the provider can communicate in';
COMMENT ON TABLE provider_work_experience IS 'Stores work experience history for healthcare providers';
COMMENT ON TABLE provider_certificates IS 'Stores professional certificates with file attachments for healthcare providers';
COMMENT ON TABLE provider_licenses IS 'Stores professional licenses with file attachments and verification status for healthcare providers';
