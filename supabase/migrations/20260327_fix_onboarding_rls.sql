-- ============================================================
-- FIX RLS FOR ONBOARDING (V3)
-- ============================================================
-- Allow new authenticated users to create and see their tenant, branch, and subscription

-- 1. Tenants: Allow INSERT and SELECT by email
ALTER TABLE tenants ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Authenticated users can create tenant" ON tenants;
CREATE POLICY "Authenticated users can create tenant"
    ON tenants FOR INSERT
    TO authenticated
    WITH CHECK (true);

DROP POLICY IF EXISTS "Users can select their own tenant by email" ON tenants;
CREATE POLICY "Users can select their own tenant by email"
    ON tenants FOR SELECT
    TO authenticated
    USING (email = auth.jwt() ->> 'email');

-- 2. Branches: Allow INSERT and SELECT for the tenant they are creating
ALTER TABLE branches ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Authenticated users can create branch" ON branches;
CREATE POLICY "Authenticated users can create branch"
    ON branches FOR INSERT
    TO authenticated
    WITH CHECK (true);

DROP POLICY IF EXISTS "Users can view own branch" ON branches;
CREATE POLICY "Users can view own branch"
    ON branches FOR SELECT
    TO authenticated
    USING (
        tenant_id IN (
            SELECT id FROM tenants WHERE email = auth.jwt() ->> 'email'
        )
    );

-- 3. Subscriptions: Enable RLS and allow insert/select
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Authenticated users can create subscription" ON subscriptions;
CREATE POLICY "Authenticated users can create subscription"
    ON subscriptions FOR INSERT
    TO authenticated
    WITH CHECK (true);

DROP POLICY IF EXISTS "Users can view own subscription" ON subscriptions;
CREATE POLICY "Users can view own subscription"
    ON subscriptions FOR SELECT
    TO authenticated
    USING (
        tenant_id IN (
            SELECT id FROM tenants WHERE email = auth.jwt() ->> 'email'
        )
    );

-- 4. Users: Allow a "SELECT" and "INSERT" for the user themselves
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can view own profile" ON users;
CREATE POLICY "Users can view own profile"
    ON users FOR SELECT
    USING (id = auth.uid());

DROP POLICY IF EXISTS "Users can create own profile" ON users;
CREATE POLICY "Users can create own profile"
    ON users FOR INSERT
    WITH CHECK (id = auth.uid());
