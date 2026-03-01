-- Fix RLS policy to allow new user registration
-- Issue: New users cannot insert into users table during signup
-- Solution: Allow authenticated users to create their own user record

-- Drop existing policy if it exists
DROP POLICY IF EXISTS "Users can create own account" ON users;

-- Allow authenticated users to INSERT their own user record
CREATE POLICY "Users can create own account"
    ON users FOR INSERT
    WITH CHECK (
        auth.uid() = id  -- User is creating their own record
    );

-- This policy allows:
-- 1. New users to create their own account during signup (auth.uid() = id)
-- 2. Existing "Managers can create users" policy still applies for inviting staff

-- Note: The existing "Managers can create users" policy is kept for staff invitations
