-- ============================================================
-- Migration: Update RLS helper functions to use user_tenants
-- Run AFTER 20260510000002_backfill_user_tenants.sql
-- ============================================================

-- Helper: get tenant_id for a user given an active_tenant_id context.
-- With multi-tenancy, the frontend passes the active tenant via
-- the `active_tenant_id` argument. Falls back to first membership if null.
CREATE OR REPLACE FUNCTION current_tenant_id(p_tenant_id UUID DEFAULT NULL)
RETURNS UUID AS $$
DECLARE
    v_tenant_id UUID;
BEGIN
    IF p_tenant_id IS NOT NULL THEN
        -- Verify the user actually belongs to this tenant
        SELECT tenant_id INTO v_tenant_id
        FROM user_tenants
        WHERE user_id = auth.uid()
          AND tenant_id = p_tenant_id
          AND is_active = true
          AND deleted_at IS NULL
        LIMIT 1;
    ELSE
        -- Fall back: first active membership (single-tenant case stays unchanged)
        SELECT tenant_id INTO v_tenant_id
        FROM user_tenants
        WHERE user_id = auth.uid()
          AND is_active = true
          AND deleted_at IS NULL
        ORDER BY joined_at ASC
        LIMIT 1;
    END IF;
    RETURN v_tenant_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- Helper: get role for the current user in a given tenant context
CREATE OR REPLACE FUNCTION current_user_role(p_tenant_id UUID DEFAULT NULL)
RETURNS TEXT AS $$
DECLARE
    v_role TEXT;
    v_tenant UUID;
BEGIN
    v_tenant := COALESCE(p_tenant_id, current_tenant_id());
    SELECT role INTO v_role
    FROM user_tenants
    WHERE user_id = auth.uid()
      AND tenant_id = v_tenant
      AND is_active = true
      AND deleted_at IS NULL
    LIMIT 1;
    RETURN v_role;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- Helper: get branch_id for current user in a given tenant context
CREATE OR REPLACE FUNCTION current_user_branch_id(p_tenant_id UUID DEFAULT NULL)
RETURNS UUID AS $$
DECLARE
    v_branch_id UUID;
    v_tenant UUID;
BEGIN
    v_tenant := COALESCE(p_tenant_id, current_tenant_id());
    SELECT branch_id INTO v_branch_id
    FROM user_tenants
    WHERE user_id = auth.uid()
      AND tenant_id = v_tenant
      AND is_active = true
      AND deleted_at IS NULL
    LIMIT 1;
    RETURN v_branch_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- Helper: check if user belongs to a given tenant (used by RLS policies)
CREATE OR REPLACE FUNCTION is_in_tenant(check_tenant_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM user_tenants
        WHERE user_id = auth.uid()
          AND tenant_id = check_tenant_id
          AND is_active = true
          AND deleted_at IS NULL
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- Helper: can user access a branch (admin sees all in tenant, staff only own)
CREATE OR REPLACE FUNCTION can_access_branch(check_branch_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    v_role TEXT;
    v_branch_id UUID;
    v_tenant_id UUID;
    v_branch_tenant_id UUID;
BEGIN
    -- Find which tenant owns this branch
    SELECT tenant_id INTO v_branch_tenant_id
    FROM branches WHERE id = check_branch_id;

    -- Check user membership in that tenant
    SELECT role, branch_id INTO v_role, v_branch_id
    FROM user_tenants
    WHERE user_id = auth.uid()
      AND tenant_id = v_branch_tenant_id
      AND is_active = true
      AND deleted_at IS NULL
    LIMIT 1;

    IF v_role IN ('tenant_admin', 'super_admin') THEN
        RETURN true;
    ELSE
        RETURN check_branch_id = v_branch_id OR v_branch_id IS NULL;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- Convenience helpers (unchanged signatures, updated internals)
CREATE OR REPLACE FUNCTION can_manage_users()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN current_user_role() IN ('super_admin', 'tenant_admin', 'branch_manager');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

CREATE OR REPLACE FUNCTION can_manage_products()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN current_user_role() IN ('super_admin', 'tenant_admin', 'branch_manager');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

CREATE OR REPLACE FUNCTION can_view_reports()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN current_user_role() IN ('super_admin', 'tenant_admin', 'branch_manager');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

CREATE OR REPLACE FUNCTION can_void_sales()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN current_user_role() IN ('super_admin', 'tenant_admin', 'branch_manager');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

CREATE OR REPLACE FUNCTION get_accessible_branches()
RETURNS SETOF UUID AS $$
DECLARE
    v_role TEXT;
    v_tenant_id UUID;
    v_branch_id UUID;
BEGIN
    v_role := current_user_role();
    v_tenant_id := current_tenant_id();
    v_branch_id := current_user_branch_id();

    IF v_role IN ('super_admin', 'tenant_admin') THEN
        RETURN QUERY SELECT id FROM branches WHERE tenant_id = v_tenant_id;
    ELSE
        IF v_branch_id IS NOT NULL THEN
            RETURN QUERY SELECT v_branch_id;
        END IF;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- Re-grant permissions
GRANT EXECUTE ON FUNCTION current_tenant_id(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION current_user_role(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION current_user_branch_id(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION is_in_tenant(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION can_access_branch(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION can_manage_users() TO authenticated;
GRANT EXECUTE ON FUNCTION can_manage_products() TO authenticated;
GRANT EXECUTE ON FUNCTION can_view_reports() TO authenticated;
GRANT EXECUTE ON FUNCTION can_void_sales() TO authenticated;
GRANT EXECUTE ON FUNCTION get_accessible_branches() TO authenticated;
