-- ============================================================
-- Fix RLS Policy for Healthcare Providers and Patients
-- ============================================================
-- Purpose: Allow providers to read their own profile and insert patients

-- ============================================================
-- Step 1: Add SELECT policy for providers to read their own profile
-- ============================================================

-- Drop existing policy if it exists
DROP POLICY IF EXISTS "Providers can read own profile" ON healthcare_providers;

-- Create SELECT policy for providers to read their own profile
CREATE POLICY "Providers can read own profile"
ON healthcare_providers FOR SELECT
USING (
    user_id = auth.uid()
    OR
    (is_active = TRUE AND is_verified = TRUE) -- Allow viewing active/verified profiles
);

-- ============================================================
-- Step 2: Simplify patients INSERT policy
-- ============================================================

-- Drop the existing INSERT policy
DROP POLICY IF EXISTS "Providers can insert patients" ON patients;

-- Create a simpler INSERT policy that works
CREATE POLICY "Providers can insert patients"
ON patients FOR INSERT
WITH CHECK (
    -- Check that the healthcare_provider_id belongs to the current user
    EXISTS (
        SELECT 1 FROM healthcare_providers
        WHERE id = healthcare_provider_id
        AND user_id = auth.uid()
    )
);

-- ============================================================
-- Step 3: Verify other policies are correct
-- ============================================================

-- Drop and recreate UPDATE policy for safety
DROP POLICY IF EXISTS "Providers can update their patients" ON patients;

CREATE POLICY "Providers can update their patients"
ON patients FOR UPDATE
USING (
    EXISTS (
        SELECT 1 FROM healthcare_providers
        WHERE id = healthcare_provider_id
        AND user_id = auth.uid()
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1 FROM healthcare_providers
        WHERE id = healthcare_provider_id
        AND user_id = auth.uid()
    )
);

-- Drop and recreate SELECT policy for safety
DROP POLICY IF EXISTS "Providers can view their patients" ON patients;

CREATE POLICY "Providers can view their patients"
ON patients FOR SELECT
USING (
    is_deleted = FALSE
    AND EXISTS (
        SELECT 1 FROM healthcare_providers
        WHERE id = healthcare_provider_id
        AND user_id = auth.uid()
    )
);

-- Drop and recreate DELETE policy for safety
DROP POLICY IF EXISTS "Providers can delete their patients" ON patients;

CREATE POLICY "Providers can delete their patients"
ON patients FOR DELETE
USING (
    EXISTS (
        SELECT 1 FROM healthcare_providers
        WHERE id = healthcare_provider_id
        AND user_id = auth.uid()
    )
);

-- ============================================================
-- Comments
-- ============================================================

COMMENT ON POLICY "Providers can read own profile" ON healthcare_providers IS
'Allows providers to read their own profile and view active/verified public profiles';

COMMENT ON POLICY "Providers can insert patients" ON patients IS
'Allows providers to insert patients only for their own provider account';

COMMENT ON POLICY "Providers can update their patients" ON patients IS
'Allows providers to update only their own patients';

COMMENT ON POLICY "Providers can view their patients" ON patients IS
'Allows providers to view their own non-deleted patients';

COMMENT ON POLICY "Providers can delete their patients" ON patients IS
'Allows providers to delete their own patients';
