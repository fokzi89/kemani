-- ============================================================
-- Migration: Fix RLS Recursion in user_tenants table
-- Updates policies to use SECURITY DEFINER helper functions
-- ============================================================

-- 1. Drop the recursive policies
DROP POLICY IF EXISTS "Admins can view tenant memberships" ON user_tenants;
DROP POLICY IF EXISTS "Admins can update tenant memberships" ON user_tenants;

-- 2. Re-create using the safe helper functions
-- (These functions are SECURITY DEFINER, so they bypass RLS on the table they query internally, breaking the recursion)

-- Tenant admins and branch managers can view all memberships in their tenant
CREATE POLICY "Admins can view tenant memberships" ON user_tenants
    FOR SELECT USING (
        has_permission('branch_manager', tenant_id)
    );

-- Tenant admins can update memberships in their tenant (e.g. deactivate staff)
CREATE POLICY "Admins can update tenant memberships" ON user_tenants
    FOR UPDATE USING (
        has_permission('tenant_admin', tenant_id)
    );

-- 3. Note: The "Users can view own tenant memberships" policy (user_id = auth.uid()) 
-- is NOT recursive and can stay as is, but we'll re-verify it.
-- We'll also add a DELETE policy for completeness.

CREATE POLICY "Admins can delete tenant memberships" ON user_tenants
    FOR DELETE USING (
        has_permission('tenant_admin', tenant_id)
    );
