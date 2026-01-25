-- ============================================================================
-- RLS Policy Verification Script
-- ============================================================================
-- Purpose: Verify that Row Level Security is properly configured on all tables
-- Date: 2026-01-25
-- Usage: Run this in Supabase SQL Editor after applying RLS migrations

-- ============================================================================
-- 1. CHECK RLS IS ENABLED ON ALL TABLES
-- ============================================================================

SELECT
  schemaname,
  tablename,
  CASE
    WHEN rowsecurity = true THEN '✅ ENABLED'
    ELSE '❌ DISABLED'
  END as rls_status
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename NOT IN ('schema_migrations', 'supabase_migrations') -- exclude migration tables
ORDER BY
  CASE WHEN rowsecurity = false THEN 0 ELSE 1 END, -- Show disabled first
  tablename;

-- Expected: ALL tables should show "✅ ENABLED"
-- If any show "❌ DISABLED", run the RLS migration again for those tables

-- ============================================================================
-- 2. LIST ALL RLS POLICIES
-- ============================================================================

SELECT
  schemaname,
  tablename,
  policyname,
  permissive,
  cmd as operation, -- SELECT, INSERT, UPDATE, DELETE, ALL
  roles,
  qual as using_clause,
  with_check as with_check_clause
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- Expected: Each table should have at least one policy
-- Tenant-scoped tables should have policies checking tenant_id

-- ============================================================================
-- 3. FIND TABLES WITHOUT ANY RLS POLICIES
-- ============================================================================

SELECT
  t.tablename,
  '⚠️ NO POLICIES' as status
FROM pg_tables t
WHERE t.schemaname = 'public'
  AND t.rowsecurity = true
  AND NOT EXISTS (
    SELECT 1 FROM pg_policies p
    WHERE p.schemaname = t.schemaname
      AND p.tablename = t.tablename
  )
ORDER BY t.tablename;

-- Expected: No results (all RLS-enabled tables should have policies)
-- If any tables show up, they have RLS enabled but NO policies (no one can access!)

-- ============================================================================
-- 4. VERIFY TENANT ISOLATION POLICIES
-- ============================================================================

-- Tables that should have tenant_id isolation
WITH tenant_tables AS (
  SELECT unnest(ARRAY[
    'tenants', 'users', 'branches', 'brands', 'categories',
    'products', 'product_variants', 'customers', 'customer_addresses',
    'sales', 'sale_items', 'inventory_transactions',
    'orders', 'order_items', 'deliveries', 'riders',
    'staff_attendance', 'staff_invites', 'receipts',
    'chat_conversations', 'chat_messages', 'whatsapp_messages',
    'ecommerce_connections', 'ecommerce_products', 'sync_logs',
    'inter_branch_transfers', 'transfer_items', 'product_price_history',
    'audit_logs',
    -- Fact tables
    'fact_brand_sales', 'fact_daily_sales', 'fact_hourly_sales',
    'fact_product_sales', 'fact_staff_sales'
  ]) AS table_name
)
SELECT
  tt.table_name,
  CASE
    WHEN EXISTS (
      SELECT 1 FROM pg_policies p
      WHERE p.tablename = tt.table_name
        AND p.qual::text LIKE '%tenant_id%'
    )
    THEN '✅ HAS TENANT ISOLATION'
    ELSE '❌ MISSING TENANT ISOLATION'
  END as isolation_status
FROM tenant_tables tt
ORDER BY isolation_status, table_name;

-- Expected: All tables should show "✅ HAS TENANT ISOLATION"

-- ============================================================================
-- 5. CHECK SPECIAL TABLES (Non-Tenant Scoped)
-- ============================================================================

-- These tables should NOT have tenant isolation (shared or platform-level)
SELECT
  tablename,
  COUNT(*) as policy_count
FROM pg_policies
WHERE tablename IN ('subscriptions', 'commissions', 'invoices', 'dim_date', 'dim_time', 'spatial_ref_sys')
  AND schemaname = 'public'
GROUP BY tablename
ORDER BY tablename;

-- Expected:
-- - subscriptions: 2 policies (tenant access + platform admin)
-- - commissions: 2 policies (tenant access + platform admin)
-- - invoices: 2 policies (tenant access + platform admin)
-- - dim_date: 2 policies (read all + admin modify)
-- - dim_time: 2 policies (read all + admin modify)
-- - spatial_ref_sys: 2 policies (read all + admin modify)

-- ============================================================================
-- 6. TEST RLS WITH SAMPLE DATA (Manual Testing)
-- ============================================================================

-- IMPORTANT: Run these tests as different users to verify isolation

-- Step 1: Create two test tenants
-- INSERT INTO tenants (id, name) VALUES
--   ('11111111-1111-1111-1111-111111111111', 'Test Tenant A'),
--   ('22222222-2222-2222-2222-222222222222', 'Test Tenant B');

-- Step 2: Create test users for each tenant
-- Make sure their JWT includes the correct tenant_id claim

-- Step 3: Create sample data for each tenant
-- INSERT INTO products (name, unit_price, tenant_id, branch_id) VALUES
--   ('Product A1', 100, '11111111-1111-1111-1111-111111111111', 'branch-a-id'),
--   ('Product B1', 200, '22222222-2222-2222-2222-222222222222', 'branch-b-id');

-- Step 4: Query as Tenant A user (should only see Product A1)
-- SET LOCAL jwt.claims.tenant_id = '11111111-1111-1111-1111-111111111111';
-- SELECT * FROM products;

-- Step 5: Query as Tenant B user (should only see Product B1)
-- SET LOCAL jwt.claims.tenant_id = '22222222-2222-2222-2222-222222222222';
-- SELECT * FROM products;

-- Expected: Each tenant should only see their own data

-- ============================================================================
-- 7. COMMON RLS ISSUES CHECK
-- ============================================================================

-- Issue 1: Policies that always return false (block all access)
SELECT
  tablename,
  policyname,
  'Policy may block all access' as warning
FROM pg_policies
WHERE qual::text LIKE '%false%' OR with_check::text LIKE '%false%';

-- Issue 2: Policies without tenant_id check on tenant-scoped tables
SELECT
  tablename,
  policyname,
  'Missing tenant_id check' as warning
FROM pg_policies
WHERE tablename IN ('products', 'sales', 'customers', 'orders')
  AND qual::text NOT LIKE '%tenant_id%';

-- Issue 3: Tables with RLS but no SELECT policy (no one can read)
SELECT DISTINCT
  tablename,
  'No SELECT policy found' as warning
FROM pg_policies
WHERE tablename NOT IN (
  SELECT tablename FROM pg_policies WHERE cmd = 'SELECT' OR cmd = 'ALL'
)
AND schemaname = 'public';

-- ============================================================================
-- 8. SECURITY AUDIT SUMMARY
-- ============================================================================

SELECT
  'Total tables in public schema' as metric,
  COUNT(*)::text as value
FROM pg_tables
WHERE schemaname = 'public'

UNION ALL

SELECT
  'Tables with RLS enabled',
  COUNT(*)::text
FROM pg_tables
WHERE schemaname = 'public' AND rowsecurity = true

UNION ALL

SELECT
  'Tables with RLS disabled (⚠️)',
  COUNT(*)::text
FROM pg_tables
WHERE schemaname = 'public' AND rowsecurity = false

UNION ALL

SELECT
  'Total RLS policies',
  COUNT(*)::text
FROM pg_policies
WHERE schemaname = 'public'

UNION ALL

SELECT
  'Tables with tenant isolation',
  COUNT(DISTINCT tablename)::text
FROM pg_policies
WHERE schemaname = 'public'
  AND qual::text LIKE '%tenant_id%';

-- ============================================================================
-- 9. RECOMMENDED ACTIONS
-- ============================================================================

-- If any tables show RLS disabled:
-- 1. Review if the table should have RLS
-- 2. Enable RLS: ALTER TABLE table_name ENABLE ROW LEVEL SECURITY;
-- 3. Create appropriate policies

-- If any tables have RLS but no policies:
-- 1. Create policies immediately (table is completely blocked)
-- 2. Start with tenant isolation: tenant_id = auth.jwt() ->> 'tenant_id'

-- If any tenant-scoped tables lack tenant_id check:
-- 1. Add tenant isolation policy
-- 2. This is a CRITICAL security vulnerability

-- ============================================================================
-- 10. EXPORT RESULTS FOR DOCUMENTATION
-- ============================================================================

-- To save verification results:
-- Copy the output of this query to a file

SELECT
  ROW_NUMBER() OVER (ORDER BY tablename) as "#",
  tablename as "Table",
  CASE WHEN rowsecurity THEN '✅' ELSE '❌' END as "RLS Enabled",
  COALESCE(policy_count::text, '0') as "Policy Count",
  CASE
    WHEN policy_count > 0 THEN '✅'
    WHEN rowsecurity = false THEN 'N/A'
    ELSE '⚠️'
  END as "Status"
FROM pg_tables t
LEFT JOIN (
  SELECT tablename, COUNT(*) as policy_count
  FROM pg_policies
  WHERE schemaname = 'public'
  GROUP BY tablename
) p ON t.tablename = p.tablename
WHERE t.schemaname = 'public'
ORDER BY t.tablename;

-- ============================================================================
-- NOTES
-- ============================================================================

-- 1. Run this script AFTER applying RLS migration
-- 2. Review all "❌" and "⚠️" results
-- 3. Test with actual user sessions (not superuser)
-- 4. Verify auth.jwt() ->> 'tenant_id' returns correct value
-- 5. Set up automated RLS testing in CI/CD

-- ============================================================================
