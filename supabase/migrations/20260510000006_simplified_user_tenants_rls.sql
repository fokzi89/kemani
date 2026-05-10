-- ============================================================
-- Migration: Simplified user_tenants RLS to avoid 500 errors
-- ============================================================

-- 1. Drop all existing policies on user_tenants to start clean
DROP POLICY IF EXISTS "Users can view own tenant memberships" ON user_tenants;
DROP POLICY IF EXISTS "Admins can view tenant memberships" ON user_tenants;
DROP POLICY IF EXISTS "Admins can update tenant memberships" ON user_tenants;
DROP POLICY IF EXISTS "Admins can delete tenant memberships" ON user_tenants;
DROP POLICY IF EXISTS "Allow insert own membership on invite acceptance" ON user_tenants;

-- 2. Basic Visibility: Everyone can see their own memberships
CREATE POLICY "user_tenants_self_view" ON user_tenants
    FOR SELECT USING (user_id = auth.uid());

-- 3. Admin Visibility: Admins can see everyone in their tenant
-- We use a raw check against the users table legacy column ONLY for this specific junction table 
-- to completely bypass any recursion logic while the migration is in progress.
CREATE POLICY "user_tenants_admin_view" ON user_tenants
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE id = auth.uid() 
              AND tenant_id = user_tenants.tenant_id 
              AND role IN ('tenant_admin', 'branch_manager', 'super_admin')
        )
    );

-- 4. Updates: Same logic for updates
CREATE POLICY "user_tenants_admin_update" ON user_tenants
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE id = auth.uid() 
              AND tenant_id = user_tenants.tenant_id 
              AND role IN ('tenant_admin', 'super_admin')
        )
    );

-- 5. Insert: Allow self-insert (for invites) and admin-insert
CREATE POLICY "user_tenants_insert" ON user_tenants
    FOR INSERT WITH CHECK (
        user_id = auth.uid() OR 
        EXISTS (
            SELECT 1 FROM users 
            WHERE id = auth.uid() 
              AND tenant_id = user_tenants.tenant_id 
              AND role IN ('tenant_admin', 'super_admin')
        )
    );
