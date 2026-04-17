-- ============================================================
-- Migration: Fix Patient Deletion RLS Conflicts
-- ============================================================
-- Purpose: Allow owners to view their own records even if marked as deleted.
-- This ensures that soft-delete updates can be confirmed by the database
-- while maintaining privacy. The UI already filters these out via queries.

-- 1. Drop the old restrictive select policy
DROP POLICY IF EXISTS "Providers can view their patients" ON patients;

-- 2. Create a new select policy that only checks for ownership
CREATE POLICY "Providers can view their patients"
ON patients FOR SELECT
USING (
    healthcare_provider_id IN (
        SELECT id FROM healthcare_providers
        WHERE user_id = auth.uid()
    )
    -- Remove the 'AND is_deleted = FALSE' so providers can see their own deleted records
);

-- Note: The UI query should still explicitly filter with .eq('is_deleted', false)
-- to keep the patient list clean.
COMMENT ON POLICY "Providers can view their patients" ON patients IS 'Allowed owners to see their own records, even if deleted, to prevent soft-delete confirmation hangs.';
