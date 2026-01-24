-- ============================================
-- Migration: RLS Helper Functions
-- Description: Helper functions for Row Level Security policies
-- Created: 2026-01-23
-- ============================================

-- ============================================
-- DROP EXISTING FUNCTIONS (if they exist)
-- ============================================

DROP FUNCTION IF EXISTS current_tenant_id() CASCADE;
DROP FUNCTION IF EXISTS current_user_role() CASCADE;
DROP FUNCTION IF EXISTS current_user_branch_id() CASCADE;
DROP FUNCTION IF EXISTS has_permission(TEXT) CASCADE;
DROP FUNCTION IF EXISTS is_in_tenant(UUID) CASCADE;
DROP FUNCTION IF EXISTS can_access_branch(UUID) CASCADE;
DROP FUNCTION IF EXISTS can_manage_users() CASCADE;
DROP FUNCTION IF EXISTS can_manage_products() CASCADE;
DROP FUNCTION IF EXISTS can_view_reports() CASCADE;
DROP FUNCTION IF EXISTS can_void_sales() CASCADE;
DROP FUNCTION IF EXISTS get_accessible_branches() CASCADE;
DROP FUNCTION IF EXISTS log_audit_event(TEXT, TEXT, UUID, JSONB, JSONB) CASCADE;

-- ============================================
-- 1. GET CURRENT TENANT ID
-- ============================================

CREATE OR REPLACE FUNCTION current_tenant_id()
RETURNS UUID AS $$
DECLARE
    v_tenant_id UUID;
BEGIN
    -- Get tenant_id from the authenticated user
    SELECT tenant_id INTO v_tenant_id
    FROM users
    WHERE id = auth.uid();

    RETURN v_tenant_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

COMMENT ON FUNCTION current_tenant_id() IS 'Returns the tenant_id of the currently authenticated user';

-- ============================================
-- 2. GET CURRENT USER ROLE
-- ============================================

CREATE OR REPLACE FUNCTION current_user_role()
RETURNS TEXT AS $$
DECLARE
    v_role TEXT;
BEGIN
    -- Get role from the authenticated user
    SELECT role INTO v_role
    FROM users
    WHERE id = auth.uid();

    RETURN v_role;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

COMMENT ON FUNCTION current_user_role() IS 'Returns the role of the currently authenticated user';

-- ============================================
-- 3. GET CURRENT USER BRANCH ID
-- ============================================

CREATE OR REPLACE FUNCTION current_user_branch_id()
RETURNS UUID AS $$
DECLARE
    v_branch_id UUID;
BEGIN
    -- Get branch_id from the authenticated user
    SELECT branch_id INTO v_branch_id
    FROM users
    WHERE id = auth.uid();

    RETURN v_branch_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

COMMENT ON FUNCTION current_user_branch_id() IS 'Returns the branch_id of the currently authenticated user';

-- ============================================
-- 4. CHECK IF USER HAS PERMISSION
-- ============================================

CREATE OR REPLACE FUNCTION has_permission(required_role TEXT)
RETURNS BOOLEAN AS $$
DECLARE
    v_user_role TEXT;
    v_role_hierarchy INTEGER;
    v_required_hierarchy INTEGER;
BEGIN
    -- Get current user's role
    v_user_role := current_user_role();

    -- Define role hierarchy (higher number = more permissions)
    v_role_hierarchy := CASE v_user_role
        WHEN 'super_admin' THEN 100
        WHEN 'tenant_admin' THEN 80
        WHEN 'branch_manager' THEN 60
        WHEN 'staff' THEN 40
        WHEN 'rider' THEN 20
        ELSE 0
    END;

    v_required_hierarchy := CASE required_role
        WHEN 'super_admin' THEN 100
        WHEN 'tenant_admin' THEN 80
        WHEN 'branch_manager' THEN 60
        WHEN 'staff' THEN 40
        WHEN 'rider' THEN 20
        ELSE 0
    END;

    RETURN v_role_hierarchy >= v_required_hierarchy;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

COMMENT ON FUNCTION has_permission(TEXT) IS 'Checks if current user has required permission level';

-- ============================================
-- 5. CHECK IF USER IS IN TENANT
-- ============================================

CREATE OR REPLACE FUNCTION is_in_tenant(check_tenant_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN check_tenant_id = current_tenant_id();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

COMMENT ON FUNCTION is_in_tenant(UUID) IS 'Checks if provided tenant_id matches current user''s tenant';

-- ============================================
-- 6. CHECK IF USER CAN ACCESS BRANCH
-- ============================================

CREATE OR REPLACE FUNCTION can_access_branch(check_branch_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    v_user_role TEXT;
    v_user_branch_id UUID;
    v_tenant_id UUID;
    v_branch_tenant_id UUID;
BEGIN
    v_user_role := current_user_role();
    v_user_branch_id := current_user_branch_id();
    v_tenant_id := current_tenant_id();

    -- Super admins and tenant admins can access all branches in their tenant
    IF v_user_role IN ('super_admin', 'tenant_admin') THEN
        -- Check if branch belongs to user's tenant
        SELECT tenant_id INTO v_branch_tenant_id
        FROM branches
        WHERE id = check_branch_id;

        RETURN v_branch_tenant_id = v_tenant_id;
    ELSE
        -- Other roles can only access their assigned branch
        RETURN check_branch_id = v_user_branch_id OR v_user_branch_id IS NULL;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

COMMENT ON FUNCTION can_access_branch(UUID) IS 'Checks if current user can access the specified branch';

-- ============================================
-- 7. CHECK IF USER CAN MANAGE USERS
-- ============================================

CREATE OR REPLACE FUNCTION can_manage_users()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN current_user_role() IN ('super_admin', 'tenant_admin', 'branch_manager');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

COMMENT ON FUNCTION can_manage_users() IS 'Checks if current user can manage other users';

-- ============================================
-- 8. CHECK IF USER CAN MANAGE PRODUCTS
-- ============================================

CREATE OR REPLACE FUNCTION can_manage_products()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN current_user_role() IN ('super_admin', 'tenant_admin', 'branch_manager');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

COMMENT ON FUNCTION can_manage_products() IS 'Checks if current user can manage products';

-- ============================================
-- 9. CHECK IF USER CAN VIEW REPORTS
-- ============================================

CREATE OR REPLACE FUNCTION can_view_reports()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN current_user_role() IN ('super_admin', 'tenant_admin', 'branch_manager');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

COMMENT ON FUNCTION can_view_reports() IS 'Checks if current user can view analytics reports';

-- ============================================
-- 10. CHECK IF USER CAN VOID SALES
-- ============================================

CREATE OR REPLACE FUNCTION can_void_sales()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN current_user_role() IN ('super_admin', 'tenant_admin', 'branch_manager');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

COMMENT ON FUNCTION can_void_sales() IS 'Checks if current user can void sales transactions';

-- ============================================
-- 11. GET USER'S ACCESSIBLE BRANCHES
-- ============================================

CREATE OR REPLACE FUNCTION get_accessible_branches()
RETURNS SETOF UUID AS $$
DECLARE
    v_user_role TEXT;
    v_tenant_id UUID;
    v_user_branch_id UUID;
BEGIN
    v_user_role := current_user_role();
    v_tenant_id := current_tenant_id();
    v_user_branch_id := current_user_branch_id();

    -- Super admins and tenant admins can access all branches in their tenant
    IF v_user_role IN ('super_admin', 'tenant_admin') THEN
        RETURN QUERY
        SELECT id FROM branches WHERE tenant_id = v_tenant_id;
    ELSE
        -- Other roles can only access their assigned branch
        IF v_user_branch_id IS NOT NULL THEN
            RETURN QUERY SELECT v_user_branch_id;
        END IF;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

COMMENT ON FUNCTION get_accessible_branches() IS 'Returns UUIDs of branches accessible to current user';

-- ============================================
-- 12. AUDIT LOG FUNCTION
-- ============================================

CREATE OR REPLACE FUNCTION log_audit_event(
    p_table_name TEXT,
    p_operation TEXT,
    p_record_id UUID,
    p_old_data JSONB DEFAULT NULL,
    p_new_data JSONB DEFAULT NULL
)
RETURNS VOID AS $$
BEGIN
    -- Create audit_logs table if it doesn't exist
    CREATE TABLE IF NOT EXISTS audit_logs (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        tenant_id UUID NOT NULL,
        user_id UUID NOT NULL,
        table_name TEXT NOT NULL,
        operation TEXT NOT NULL, -- INSERT, UPDATE, DELETE
        record_id UUID NOT NULL,
        old_data JSONB,
        new_data JSONB,
        ip_address INET,
        user_agent TEXT,
        created_at TIMESTAMPTZ DEFAULT NOW()
    );

    INSERT INTO audit_logs (
        tenant_id,
        user_id,
        table_name,
        operation,
        record_id,
        old_data,
        new_data
    ) VALUES (
        current_tenant_id(),
        auth.uid(),
        p_table_name,
        p_operation,
        p_record_id,
        p_old_data,
        p_new_data
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION log_audit_event IS 'Logs audit events for critical operations';

-- ============================================
-- GRANT EXECUTE PERMISSIONS
-- ============================================

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION current_tenant_id() TO authenticated;
GRANT EXECUTE ON FUNCTION current_user_role() TO authenticated;
GRANT EXECUTE ON FUNCTION current_user_branch_id() TO authenticated;
GRANT EXECUTE ON FUNCTION has_permission(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION is_in_tenant(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION can_access_branch(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION can_manage_users() TO authenticated;
GRANT EXECUTE ON FUNCTION can_manage_products() TO authenticated;
GRANT EXECUTE ON FUNCTION can_view_reports() TO authenticated;
GRANT EXECUTE ON FUNCTION can_void_sales() TO authenticated;
GRANT EXECUTE ON FUNCTION get_accessible_branches() TO authenticated;
GRANT EXECUTE ON FUNCTION log_audit_event(TEXT, TEXT, UUID, JSONB, JSONB) TO authenticated;
