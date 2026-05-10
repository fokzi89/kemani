-- ============================================================
-- Migration: Backfill existing users into user_tenants
-- Run AFTER 20260510000001_create_user_tenants.sql
-- ============================================================

-- Backfill all existing users who have a tenant_id into user_tenants
INSERT INTO user_tenants (
    user_id,
    tenant_id,
    branch_id,
    role,
    "canManagePOS",
    "canManageProducts",
    "canManageCustomers",
    "canManageOrders",
    "canViewMessages",
    "canViewAnalytics",
    "canManageStaff",
    "canManageInventory",
    "canManageTransfer",
    "canManageBranches",
    "canManageRoles",
    "canTransferProduct",
    "canReturnProducts",
    "canCreatePrescription",
    "canApplyDiscount",
    "canReferDoctor",
    "canManageExpenses",
    onboarding_done,
    is_active,
    joined_at,
    created_at,
    updated_at
)
SELECT
    u.id,
    u.tenant_id,
    u.branch_id,
    u.role,
    COALESCE(u."canManagePOS", false),
    COALESCE(u."canManageProducts", false),
    COALESCE(u."canManageCustomers", false),
    COALESCE(u."canManageOrders", false),
    COALESCE(u."canViewMessages", false),
    COALESCE(u."canViewAnalytics", false),
    COALESCE(u."canManageStaff", false),
    COALESCE(u."canManageInventory", false),
    COALESCE(u."canManageTransfer", false),
    COALESCE(u."canManageBranches", false),
    COALESCE(u."canManageRoles", false),
    COALESCE(u."canTransferProduct", false),
    COALESCE(u."canReturnProducts", false),
    COALESCE(u."canCreatePrescription", false),
    COALESCE(u."canApplyDiscount", false),
    COALESCE(u."canReferDoctor", false),
    COALESCE(u."canManageExpenses", false),
    COALESCE(u.onboarding_done, false),
    true, -- all existing users are active
    COALESCE(u.created_at, NOW()),
    NOW(),
    NOW()
FROM users u
WHERE u.tenant_id IS NOT NULL
  AND u.deleted_at IS NULL
ON CONFLICT (user_id, tenant_id) DO NOTHING;

-- Verification query (run to check results)
-- SELECT COUNT(*) FROM user_tenants;
-- SELECT COUNT(*) FROM users WHERE tenant_id IS NOT NULL AND deleted_at IS NULL;
