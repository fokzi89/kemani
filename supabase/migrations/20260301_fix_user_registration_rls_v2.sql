-- Fix RLS policy to allow new user registration (v2 - Comprehensive Fix)
-- Issue: New users cannot insert into users table during signup
-- Solution: Drop conflicting policies and create correct INSERT policy

-- Step 1: Check and drop ALL existing INSERT policies on users table
DROP POLICY IF EXISTS "Users can create own account" ON users;
DROP POLICY IF EXISTS "Managers can create users" ON users;
DROP POLICY IF EXISTS "Admins can create users" ON users;
DROP POLICY IF EXISTS "Allow user registration and staff creation" ON users;
DROP POLICY IF EXISTS "users_insert_own" ON users;
DROP POLICY IF EXISTS "managers_insert_staff" ON users;

-- Step 2: Create simple policy for self-registration
-- Allows users to create their own account during signup
CREATE POLICY "users_insert_own"
    ON users FOR INSERT
    WITH CHECK (auth.uid() = id);

-- Step 3: Create separate policy for managers to invite staff
-- Uses valid user_role enum values: platform_admin, tenant_admin, branch_manager
CREATE POLICY "managers_insert_staff"
    ON users FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM users AS u
            WHERE u.id = auth.uid()
            AND u.tenant_id IS NOT NULL
            AND u.role IN ('platform_admin', 'tenant_admin', 'branch_manager')
        )
        AND tenant_id IS NOT NULL
    );

-- Step 4: Verify the policies were created
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_policies
        WHERE tablename = 'users'
        AND policyname = 'users_insert_own'
        AND cmd = 'INSERT'
    ) AND EXISTS (
        SELECT 1 FROM pg_policies
        WHERE tablename = 'users'
        AND policyname = 'managers_insert_staff'
        AND cmd = 'INSERT'
    ) THEN
        RAISE NOTICE '✅ Both policies created successfully';
    ELSE
        RAISE EXCEPTION '❌ Failed to create one or more policies';
    END IF;
END $$;

-- Comments
COMMENT ON POLICY "users_insert_own" ON users IS
'Allows self-registration during signup (auth.uid() = id)';

COMMENT ON POLICY "managers_insert_staff" ON users IS
'Allows platform_admin, tenant_admin, and branch_manager to create users for staff invites';
