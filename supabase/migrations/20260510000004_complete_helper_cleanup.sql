-- ============================================================
-- Migration: Complete RLS helper function cleanup
-- Updates has_permission and log_audit_event to use user_tenants
-- ============================================================

-- 1. Updated has_permission: Now checks role within the user_tenants context
CREATE OR REPLACE FUNCTION has_permission(required_role TEXT, p_tenant_id UUID DEFAULT NULL)
RETURNS BOOLEAN AS $$
DECLARE
    v_user_role TEXT;
    v_role_hierarchy INTEGER;
    v_required_hierarchy INTEGER;
BEGIN
    -- Get current user's role for the specific tenant
    v_user_role := current_user_role(p_tenant_id);

    -- Define role hierarchy
    v_role_hierarchy := CASE v_user_role
        WHEN 'super_admin' THEN 100
        WHEN 'tenant_admin' THEN 80
        WHEN 'branch_manager' THEN 60
        WHEN 'pharmacist' THEN 50
        WHEN 'staff' THEN 40
        WHEN 'cashier' THEN 30
        WHEN 'accountant' THEN 30
        WHEN 'rider' THEN 20
        ELSE 0
    END;

    v_required_hierarchy := CASE required_role
        WHEN 'super_admin' THEN 100
        WHEN 'tenant_admin' THEN 80
        WHEN 'branch_manager' THEN 60
        WHEN 'pharmacist' THEN 50
        WHEN 'staff' THEN 40
        WHEN 'cashier' THEN 30
        WHEN 'accountant' THEN 30
        WHEN 'rider' THEN 20
        ELSE 0
    END;

    RETURN v_role_hierarchy >= v_required_hierarchy;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- 2. Updated log_audit_event: Uses current_tenant_id() which is now multi-tenant aware
CREATE OR REPLACE FUNCTION log_audit_event(
    p_table_name TEXT,
    p_operation TEXT,
    p_record_id UUID,
    p_old_data JSONB DEFAULT NULL,
    p_new_data JSONB DEFAULT NULL
)
RETURNS VOID AS $$
BEGIN
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

-- 3. Re-grant permissions
GRANT EXECUTE ON FUNCTION has_permission(TEXT, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION log_audit_event(TEXT, TEXT, UUID, JSONB, JSONB) TO authenticated;
