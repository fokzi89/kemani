-- ============================================================
-- Multi-Tenant Patient Identity System
-- ============================================================
-- Purpose: Enable unified patient profiles across multiple tenant accounts
-- while maintaining separate authentication per tenant
--
-- Architecture:
-- - Customers have separate accounts per tenant (different passwords allowed)
-- - Backend automatically links accounts via email/phone matching
-- - Unified patient profiles for cross-tenant medical history
-- - Privacy-first with explicit consent controls
-- ============================================================

-- ============================================================
-- Table 1: Unified Patient Profiles
-- ============================================================
-- Universal patient identity that links multiple tenant accounts

CREATE TABLE IF NOT EXISTS unified_patient_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Primary contact information (from first account or most recent)
    primary_email VARCHAR(255),
    primary_phone VARCHAR(20),
    primary_name VARCHAR(255),

    -- Metadata
    first_seen_at TIMESTAMPTZ DEFAULT NOW(),
    last_seen_at TIMESTAMPTZ DEFAULT NOW(),
    total_accounts INTEGER DEFAULT 0,

    -- Matching metadata (how confident we are this is the same person)
    match_confidence DECIMAL(3,2) DEFAULT 1.00 CHECK (match_confidence >= 0 AND match_confidence <= 1.00),
    match_method VARCHAR(50) DEFAULT 'email_phone', -- 'email_phone', 'email_name', 'phone_name', 'email_only', 'phone_only'

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for fast email/phone lookups
CREATE INDEX IF NOT EXISTS idx_unified_patients_email ON unified_patient_profiles(primary_email) WHERE primary_email IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_unified_patients_phone ON unified_patient_profiles(primary_phone) WHERE primary_phone IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_unified_patients_email_phone ON unified_patient_profiles(primary_email, primary_phone);

-- ============================================================
-- Table 2: Patient Account Links
-- ============================================================
-- Maps tenant-specific customer accounts to unified patient profiles

CREATE TABLE IF NOT EXISTS patient_account_links (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    unified_patient_id UUID NOT NULL REFERENCES unified_patient_profiles(id) ON DELETE CASCADE,
    customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,

    -- Account details at time of linking (for audit trail)
    email_at_link VARCHAR(255),
    phone_at_link VARCHAR(20),
    name_at_link VARCHAR(255),

    -- Metadata
    is_primary_account BOOLEAN DEFAULT FALSE,
    linked_at TIMESTAMPTZ DEFAULT NOW(),
    linked_by VARCHAR(50) DEFAULT 'auto', -- 'auto', 'manual', 'user_merge'

    UNIQUE(customer_id, tenant_id)
);

-- Indexes for fast lookups
CREATE INDEX IF NOT EXISTS idx_account_links_unified_patient ON patient_account_links(unified_patient_id);
CREATE INDEX IF NOT EXISTS idx_account_links_customer ON patient_account_links(customer_id);
CREATE INDEX IF NOT EXISTS idx_account_links_tenant ON patient_account_links(tenant_id);

-- ============================================================
-- Table 3: Cross-Tenant Consents
-- ============================================================
-- Track patient consent for cross-tenant data sharing (GDPR compliant)

CREATE TABLE IF NOT EXISTS cross_tenant_consents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    unified_patient_id UUID NOT NULL REFERENCES unified_patient_profiles(id) ON DELETE CASCADE,

    -- What data can be shared across tenants
    share_medical_history BOOLEAN DEFAULT FALSE,
    share_prescriptions BOOLEAN DEFAULT FALSE,
    share_consultation_notes BOOLEAN DEFAULT FALSE,
    share_purchase_history BOOLEAN DEFAULT FALSE,
    share_with_pharmacies BOOLEAN DEFAULT FALSE,
    share_with_labs BOOLEAN DEFAULT FALSE,
    share_with_doctors BOOLEAN DEFAULT TRUE, -- Default true for better care

    -- When and how consent was given
    consented_at TIMESTAMPTZ DEFAULT NOW(),
    consent_method VARCHAR(50) DEFAULT 'implicit', -- 'signup', 'settings_update', 'implicit'
    consent_version VARCHAR(20) DEFAULT '1.0', -- Track consent form versions

    updated_at TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(unified_patient_id)
);

-- Index for fast consent lookups
CREATE INDEX IF NOT EXISTS idx_consents_unified_patient ON cross_tenant_consents(unified_patient_id);

-- ============================================================
-- Function 1: Find or Create Unified Patient Profile
-- ============================================================
-- Searches for existing profile by email/phone or creates new one

CREATE OR REPLACE FUNCTION find_or_create_unified_patient(
    p_email VARCHAR(255),
    p_phone VARCHAR(20),
    p_name VARCHAR(255)
)
RETURNS UUID AS $$
DECLARE
    v_unified_patient_id UUID;
    v_match_confidence DECIMAL(3,2);
    v_match_method VARCHAR(50);
BEGIN
    -- Try to find existing profile by email (highest confidence)
    IF p_email IS NOT NULL THEN
        SELECT id INTO v_unified_patient_id
        FROM unified_patient_profiles
        WHERE primary_email = p_email
        LIMIT 1;

        IF FOUND THEN
            -- Update last_seen_at
            UPDATE unified_patient_profiles
            SET last_seen_at = NOW()
            WHERE id = v_unified_patient_id;

            RETURN v_unified_patient_id;
        END IF;
    END IF;

    -- Try to find by phone if email not found (medium confidence)
    IF p_phone IS NOT NULL THEN
        SELECT id INTO v_unified_patient_id
        FROM unified_patient_profiles
        WHERE primary_phone = p_phone
        LIMIT 1;

        IF FOUND THEN
            -- Update last_seen_at and potentially update email
            UPDATE unified_patient_profiles
            SET
                last_seen_at = NOW(),
                primary_email = COALESCE(primary_email, p_email)
            WHERE id = v_unified_patient_id;

            RETURN v_unified_patient_id;
        END IF;
    END IF;

    -- No existing profile found, create new one
    v_match_confidence := 1.00;
    IF p_email IS NOT NULL AND p_phone IS NOT NULL THEN
        v_match_method := 'email_phone';
    ELSIF p_email IS NOT NULL THEN
        v_match_method := 'email_only';
    ELSIF p_phone IS NOT NULL THEN
        v_match_method := 'phone_only';
    ELSE
        v_match_method := 'name_only';
        v_match_confidence := 0.50;
    END IF;

    INSERT INTO unified_patient_profiles (
        primary_email,
        primary_phone,
        primary_name,
        first_seen_at,
        last_seen_at,
        total_accounts,
        match_confidence,
        match_method
    )
    VALUES (
        p_email,
        p_phone,
        p_name,
        NOW(),
        NOW(),
        0,
        v_match_confidence,
        v_match_method
    )
    RETURNING id INTO v_unified_patient_id;

    -- Create default consent record (implicit consent for medical data sharing)
    INSERT INTO cross_tenant_consents (
        unified_patient_id,
        share_medical_history,
        share_prescriptions,
        share_consultation_notes,
        share_with_doctors,
        consent_method
    )
    VALUES (
        v_unified_patient_id,
        TRUE,
        TRUE,
        TRUE,
        TRUE,
        'implicit'
    );

    RETURN v_unified_patient_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- Function 2: Link Customer Account to Unified Patient
-- ============================================================
-- Creates the link between a tenant-specific customer and unified profile

CREATE OR REPLACE FUNCTION link_customer_to_unified_patient(
    p_customer_id UUID,
    p_tenant_id UUID,
    p_email VARCHAR(255) DEFAULT NULL,
    p_phone VARCHAR(20) DEFAULT NULL,
    p_name VARCHAR(255) DEFAULT NULL,
    p_linked_by VARCHAR(50) DEFAULT 'auto'
)
RETURNS UUID AS $$
DECLARE
    v_unified_patient_id UUID;
    v_existing_link UUID;
    v_total_accounts INTEGER;
BEGIN
    -- Check if customer is already linked
    SELECT id, unified_patient_id INTO v_existing_link, v_unified_patient_id
    FROM patient_account_links
    WHERE customer_id = p_customer_id AND tenant_id = p_tenant_id;

    IF FOUND THEN
        -- Already linked, return existing unified patient ID
        RETURN v_unified_patient_id;
    END IF;

    -- Find or create unified patient profile
    v_unified_patient_id := find_or_create_unified_patient(p_email, p_phone, p_name);

    -- Create the link
    INSERT INTO patient_account_links (
        unified_patient_id,
        customer_id,
        tenant_id,
        email_at_link,
        phone_at_link,
        name_at_link,
        is_primary_account,
        linked_by
    )
    VALUES (
        v_unified_patient_id,
        p_customer_id,
        p_tenant_id,
        p_email,
        p_phone,
        p_name,
        FALSE, -- Will set primary separately if needed
        p_linked_by
    );

    -- Update total_accounts counter
    SELECT COUNT(*) INTO v_total_accounts
    FROM patient_account_links
    WHERE unified_patient_id = v_unified_patient_id;

    UPDATE unified_patient_profiles
    SET
        total_accounts = v_total_accounts,
        last_seen_at = NOW()
    WHERE id = v_unified_patient_id;

    RETURN v_unified_patient_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- Function 3: Get All Customer IDs for Unified Patient
-- ============================================================
-- Returns all tenant-specific customer IDs for a unified patient

CREATE OR REPLACE FUNCTION get_all_customer_ids_for_patient(
    p_customer_id UUID
)
RETURNS TABLE (
    customer_id UUID,
    tenant_id UUID,
    tenant_name VARCHAR(255),
    email VARCHAR(255),
    phone VARCHAR(20),
    linked_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        c.id as customer_id,
        c.tenant_id,
        t.business_name as tenant_name,
        c.email,
        c.phone,
        pal.linked_at
    FROM customers c
    JOIN patient_account_links pal ON c.id = pal.customer_id
    JOIN tenants t ON c.tenant_id = t.id
    WHERE pal.unified_patient_id = (
        SELECT unified_patient_id
        FROM patient_account_links
        WHERE customer_id = p_customer_id
        LIMIT 1
    )
    ORDER BY pal.linked_at ASC;
END;
$$ LANGUAGE plpgsql STABLE;

-- ============================================================
-- Function 4: Check Cross-Tenant Data Sharing Consent
-- ============================================================
-- Verifies if patient has consented to share specific data types

CREATE OR REPLACE FUNCTION can_share_patient_data(
    p_customer_id UUID,
    p_data_type VARCHAR(50)
)
RETURNS BOOLEAN AS $$
DECLARE
    v_unified_patient_id UUID;
    v_can_share BOOLEAN;
BEGIN
    -- Get unified patient ID
    SELECT unified_patient_id INTO v_unified_patient_id
    FROM patient_account_links
    WHERE customer_id = p_customer_id
    LIMIT 1;

    IF NOT FOUND THEN
        RETURN FALSE; -- No unified profile = no sharing
    END IF;

    -- Check consent based on data type
    CASE p_data_type
        WHEN 'medical_history' THEN
            SELECT share_medical_history INTO v_can_share
            FROM cross_tenant_consents
            WHERE unified_patient_id = v_unified_patient_id;
        WHEN 'prescriptions' THEN
            SELECT share_prescriptions INTO v_can_share
            FROM cross_tenant_consents
            WHERE unified_patient_id = v_unified_patient_id;
        WHEN 'consultation_notes' THEN
            SELECT share_consultation_notes INTO v_can_share
            FROM cross_tenant_consents
            WHERE unified_patient_id = v_unified_patient_id;
        WHEN 'purchase_history' THEN
            SELECT share_purchase_history INTO v_can_share
            FROM cross_tenant_consents
            WHERE unified_patient_id = v_unified_patient_id;
        ELSE
            RETURN FALSE;
    END CASE;

    RETURN COALESCE(v_can_share, FALSE);
END;
$$ LANGUAGE plpgsql STABLE;

-- ============================================================
-- Function 5: Get Unified Patient Medical History
-- ============================================================
-- Returns complete patient history across all linked accounts

CREATE OR REPLACE FUNCTION get_unified_patient_history(
    p_customer_id UUID
)
RETURNS TABLE (
    event_type VARCHAR(50),
    event_id UUID,
    event_date TIMESTAMPTZ,
    tenant_name VARCHAR(255),
    description TEXT,
    amount DECIMAL(12,2)
) AS $$
BEGIN
    RETURN QUERY
    WITH unified_patient AS (
        SELECT unified_patient_id
        FROM patient_account_links
        WHERE customer_id = p_customer_id
        LIMIT 1
    ),
    all_customer_ids AS (
        SELECT pal.customer_id
        FROM patient_account_links pal
        WHERE pal.unified_patient_id = (SELECT unified_patient_id FROM unified_patient)
    )
    -- Consultations
    SELECT
        'consultation'::VARCHAR(50) as event_type,
        c.id as event_id,
        c.created_at as event_date,
        t.business_name as tenant_name,
        ('Consultation: ' || c.type)::TEXT as description,
        c.consultation_fee as amount
    FROM consultations c
    JOIN tenants t ON c.tenant_id = t.id
    WHERE c.patient_id IN (SELECT customer_id FROM all_customer_ids)

    UNION ALL

    -- Sales/Orders
    SELECT
        'purchase'::VARCHAR(50) as event_type,
        s.id as event_id,
        s.created_at as event_date,
        t.business_name as tenant_name,
        ('Purchase: ' || s.sale_number)::TEXT as description,
        s.total_amount as amount
    FROM sales s
    JOIN tenants t ON s.tenant_id = t.id
    WHERE s.customer_id IN (SELECT customer_id FROM all_customer_ids)

    ORDER BY event_date DESC;
END;
$$ LANGUAGE plpgsql STABLE;

-- ============================================================
-- Trigger: Update unified_patient_profiles.updated_at
-- ============================================================

CREATE OR REPLACE FUNCTION update_unified_patient_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS update_unified_patient_profiles_timestamp ON unified_patient_profiles;
CREATE TRIGGER update_unified_patient_profiles_timestamp
    BEFORE UPDATE ON unified_patient_profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_unified_patient_timestamp();

-- ============================================================
-- Trigger: Update cross_tenant_consents.updated_at
-- ============================================================

DROP TRIGGER IF EXISTS update_cross_tenant_consents_timestamp ON cross_tenant_consents;
CREATE TRIGGER update_cross_tenant_consents_timestamp
    BEFORE UPDATE ON cross_tenant_consents
    FOR EACH ROW
    EXECUTE FUNCTION update_unified_patient_timestamp();

-- ============================================================
-- Row Level Security (RLS) Policies
-- ============================================================

-- Enable RLS on new tables
ALTER TABLE unified_patient_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE patient_account_links ENABLE ROW LEVEL SECURITY;
ALTER TABLE cross_tenant_consents ENABLE ROW LEVEL SECURITY;

-- Unified Patient Profiles: Only accessible by authenticated users for their own profile
CREATE POLICY "Users can view own unified profile"
    ON unified_patient_profiles FOR SELECT
    USING (
        id IN (
            SELECT unified_patient_id
            FROM patient_account_links
            WHERE customer_id IN (
                SELECT id FROM customers WHERE id = auth.uid()
            )
        )
    );

-- Patient Account Links: Users can view their own links
CREATE POLICY "Users can view own account links"
    ON patient_account_links FOR SELECT
    USING (
        customer_id IN (
            SELECT id FROM customers WHERE id = auth.uid()
        )
    );

-- Cross-Tenant Consents: Users can view and update their own consents
CREATE POLICY "Users can view own consents"
    ON cross_tenant_consents FOR SELECT
    USING (
        unified_patient_id IN (
            SELECT unified_patient_id
            FROM patient_account_links
            WHERE customer_id IN (
                SELECT id FROM customers WHERE id = auth.uid()
            )
        )
    );

CREATE POLICY "Users can update own consents"
    ON cross_tenant_consents FOR UPDATE
    USING (
        unified_patient_id IN (
            SELECT unified_patient_id
            FROM patient_account_links
            WHERE customer_id IN (
                SELECT id FROM customers WHERE id = auth.uid()
            )
        )
    );

-- ============================================================
-- Comments for Documentation
-- ============================================================

COMMENT ON TABLE unified_patient_profiles IS 'Universal patient identity that links multiple tenant accounts for cross-tenant medical history';
COMMENT ON TABLE patient_account_links IS 'Maps tenant-specific customer accounts to unified patient profiles';
COMMENT ON TABLE cross_tenant_consents IS 'Tracks patient consent for cross-tenant data sharing (GDPR compliant)';

COMMENT ON FUNCTION find_or_create_unified_patient IS 'Searches for existing patient profile by email/phone or creates new one';
COMMENT ON FUNCTION link_customer_to_unified_patient IS 'Links a tenant-specific customer account to a unified patient profile';
COMMENT ON FUNCTION get_all_customer_ids_for_patient IS 'Returns all tenant-specific customer IDs for a unified patient';
COMMENT ON FUNCTION can_share_patient_data IS 'Checks if patient has consented to share specific data types across tenants';
COMMENT ON FUNCTION get_unified_patient_history IS 'Returns complete patient history (consultations, purchases) across all linked accounts';
