-- ============================================================
-- Migration: Create user_tenants junction table
-- This enables one user (staff) to belong to multiple tenants
-- (e.g. locum pharmacists working across multiple pharmacies)
-- ============================================================

-- NOTE: Run 20260510000000_expand_user_roles.sql FIRST to add 'staff' and 'accountant' to the enum

CREATE TABLE IF NOT EXISTS user_tenants (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    branch_id UUID REFERENCES branches(id) ON DELETE SET NULL,
    role user_role NOT NULL DEFAULT 'cashier',
    -- Privilege flags (mirror of what was on users table)
    "canManagePOS" BOOLEAN NOT NULL DEFAULT false,
    "canManageProducts" BOOLEAN NOT NULL DEFAULT false,
    "canManageCustomers" BOOLEAN NOT NULL DEFAULT false,
    "canManageOrders" BOOLEAN NOT NULL DEFAULT false,
    "canViewMessages" BOOLEAN NOT NULL DEFAULT false,
    "canViewAnalytics" BOOLEAN NOT NULL DEFAULT false,
    "canManageStaff" BOOLEAN NOT NULL DEFAULT false,
    "canManageInventory" BOOLEAN NOT NULL DEFAULT false,
    "canManageTransfer" BOOLEAN NOT NULL DEFAULT false,
    "canManageBranches" BOOLEAN NOT NULL DEFAULT false,
    "canManageRoles" BOOLEAN NOT NULL DEFAULT false,
    "canTransferProduct" BOOLEAN NOT NULL DEFAULT false,
    "canReturnProducts" BOOLEAN NOT NULL DEFAULT false,
    "canCreatePrescription" BOOLEAN NOT NULL DEFAULT false,
    "canApplyDiscount" BOOLEAN NOT NULL DEFAULT false,
    "canReferDoctor" BOOLEAN NOT NULL DEFAULT false,
    "canManageExpenses" BOOLEAN NOT NULL DEFAULT false,
    onboarding_done BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,
    joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, tenant_id)
);

-- Index for fast lookups by user or tenant
CREATE INDEX IF NOT EXISTS idx_user_tenants_user_id ON user_tenants(user_id);
CREATE INDEX IF NOT EXISTS idx_user_tenants_tenant_id ON user_tenants(tenant_id);
CREATE INDEX IF NOT EXISTS idx_user_tenants_branch_id ON user_tenants(branch_id) WHERE branch_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_user_tenants_active ON user_tenants(user_id, tenant_id) WHERE is_active = true AND deleted_at IS NULL;

-- Updated_at trigger
CREATE TRIGGER set_user_tenants_updated_at
    BEFORE UPDATE ON user_tenants
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Enable RLS
ALTER TABLE user_tenants ENABLE ROW LEVEL SECURITY;

-- Staff can view their own memberships
CREATE POLICY "Users can view own tenant memberships" ON user_tenants
    FOR SELECT USING (user_id = auth.uid());

-- Tenant admins and branch managers can view all memberships in their tenant
CREATE POLICY "Admins can view tenant memberships" ON user_tenants
    FOR SELECT USING (
        tenant_id IN (
            SELECT ut.tenant_id FROM user_tenants ut
            WHERE ut.user_id = auth.uid()
              AND ut.role IN ('tenant_admin', 'branch_manager')
              AND ut.is_active = true
              AND ut.deleted_at IS NULL
        )
    );

-- Tenant admins can insert new memberships (when accepting invitations or adding staff)
CREATE POLICY "Allow insert own membership on invite acceptance" ON user_tenants
    FOR INSERT WITH CHECK (user_id = auth.uid());

-- Tenant admins can update memberships in their tenant
CREATE POLICY "Admins can update tenant memberships" ON user_tenants
    FOR UPDATE USING (
        tenant_id IN (
            SELECT ut.tenant_id FROM user_tenants ut
            WHERE ut.user_id = auth.uid()
              AND ut.role IN ('tenant_admin', 'branch_manager')
              AND ut.is_active = true
        )
    );
