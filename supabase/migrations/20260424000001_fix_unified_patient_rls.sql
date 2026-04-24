-- ============================================================
-- Fix RLS Policies for Unified Patient Profiles
-- ============================================================
-- Purpose: Allow authenticated users to create their unified profiles and links
-- during the signup or first-time login flow.

-- 1. Unified Patient Profiles
DROP POLICY IF EXISTS "Allow authenticated insert for unified profile" ON unified_patient_profiles;
CREATE POLICY "Allow authenticated insert for unified profile"
ON unified_patient_profiles FOR INSERT
TO authenticated
WITH CHECK (true);

-- 2. Patient Account Links
DROP POLICY IF EXISTS "Users can insert own account links" ON patient_account_links;
CREATE POLICY "Users can insert own account links"
ON patient_account_links FOR INSERT
TO authenticated
WITH CHECK (customer_id = auth.uid());

-- 3. Cross-Tenant Consents
DROP POLICY IF EXISTS "Users can insert own consents" ON cross_tenant_consents;
CREATE POLICY "Users can insert own consents"
ON cross_tenant_consents FOR INSERT
TO authenticated
WITH CHECK (true);

-- Also ensure the SECURITY DEFINER functions are owned by a role that can bypass RLS if possible,
-- but adding policies is safer for general compatibility.
