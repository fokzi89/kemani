-- ============================================================
-- FIX RLS FOR ONBOARDING UPSERT
-- ============================================================

-- Allow UPDATE on own profile to support UPSERT during onboarding
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can update own profile" ON users;
CREATE POLICY "Users can update own profile"
    ON users FOR UPDATE
    USING (id = auth.uid())
    WITH CHECK (id = auth.uid());
