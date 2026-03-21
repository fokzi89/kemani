-- ============================================================
-- Fix RLS Policies for Healthcare Provider Patient Management
-- ============================================================
-- Purpose: Allow healthcare providers to add and manage patients
-- without being blocked by tenant-based RLS policies

-- Drop conflicting policies if they exist from previous migration
DROP POLICY IF EXISTS "Providers can view their patients" ON customers;
DROP POLICY IF EXISTS "Providers can add patients" ON customers;
DROP POLICY IF EXISTS "Providers can update their patients" ON customers;
DROP POLICY IF EXISTS "Providers can soft delete their patients" ON customers;

-- ============================================================
-- New RLS Policies for Healthcare Providers
-- ============================================================

-- Policy 1: Healthcare providers can SELECT their patients
CREATE POLICY "Healthcare providers can view their patients"
ON customers FOR SELECT
USING (
    -- Original tenant-based access
    tenant_id = current_tenant_id()
    OR
    -- Healthcare provider access to their patients
    (
        healthcare_provider_id IN (
            SELECT id FROM healthcare_providers
            WHERE user_id = auth.uid()
        )
        AND is_deleted = FALSE
    )
);

-- Policy 2: Healthcare providers can INSERT patients
CREATE POLICY "Healthcare providers can insert patients"
ON customers FOR INSERT
WITH CHECK (
    -- Original tenant-based access
    tenant_id = current_tenant_id()
    OR
    -- Healthcare provider can add patients
    healthcare_provider_id IN (
        SELECT id FROM healthcare_providers
        WHERE user_id = auth.uid()
    )
);

-- Policy 3: Healthcare providers can UPDATE their patients
CREATE POLICY "Healthcare providers can update their patients"
ON customers FOR UPDATE
USING (
    -- Original tenant-based access
    tenant_id = current_tenant_id()
    OR
    -- Healthcare provider access to their patients
    healthcare_provider_id IN (
        SELECT id FROM healthcare_providers
        WHERE user_id = auth.uid()
    )
)
WITH CHECK (
    -- Must still belong to the same provider after update
    healthcare_provider_id IN (
        SELECT id FROM healthcare_providers
        WHERE user_id = auth.uid()
    )
);

-- Policy 4: Healthcare providers can soft DELETE (update is_deleted)
CREATE POLICY "Healthcare providers can soft delete patients"
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
    AND is_deleted = TRUE -- Only allow setting to deleted
);

-- ============================================================
-- Update existing "Customer tenant isolation" policy
-- ============================================================
-- We need to replace the overly broad "FOR ALL" policy with specific ones

-- Drop the old broad policy
DROP POLICY IF EXISTS "Customer tenant isolation" ON customers;

-- Create specific policies for tenant-based access
CREATE POLICY "Tenant members can view customers"
ON customers FOR SELECT
USING (tenant_id = current_tenant_id());

CREATE POLICY "Tenant members can insert customers"
ON customers FOR INSERT
WITH CHECK (tenant_id = current_tenant_id());

CREATE POLICY "Tenant members can update customers"
ON customers FOR UPDATE
USING (tenant_id = current_tenant_id())
WITH CHECK (tenant_id = current_tenant_id());

CREATE POLICY "Tenant members can delete customers"
ON customers FOR DELETE
USING (tenant_id = current_tenant_id());

-- ============================================================
-- Comments
-- ============================================================

COMMENT ON POLICY "Healthcare providers can view their patients" ON customers IS
'Allows healthcare providers to view patients they have added, filtered by is_deleted=false';

COMMENT ON POLICY "Healthcare providers can insert patients" ON customers IS
'Allows healthcare providers to add new patients to their practice';

COMMENT ON POLICY "Healthcare providers can update their patients" ON customers IS
'Allows healthcare providers to update patient information for their own patients';

COMMENT ON POLICY "Healthcare providers can soft delete patients" ON customers IS
'Allows healthcare providers to soft delete patients by setting is_deleted=true';
