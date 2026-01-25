-- Migration: Add Row Level Security to Unrestricted Tables
-- Date: 2026-01-25
-- Description: Enable RLS and add tenant isolation policies for 10 tables missing security

-- ============================================================================
-- 1. CUSTOMER_ADDRESSES
-- ============================================================================

ALTER TABLE customer_addresses ENABLE ROW LEVEL SECURITY;

-- Tenant isolation for SELECT
CREATE POLICY "customer_addresses_tenant_isolation_select" ON customer_addresses
  FOR SELECT USING (tenant_id = (auth.jwt() ->> 'tenant_id')::UUID);

-- Tenant isolation for INSERT
CREATE POLICY "customer_addresses_tenant_isolation_insert" ON customer_addresses
  FOR INSERT WITH CHECK (tenant_id = (auth.jwt() ->> 'tenant_id')::UUID);

-- Tenant isolation for UPDATE
CREATE POLICY "customer_addresses_tenant_isolation_update" ON customer_addresses
  FOR UPDATE USING (tenant_id = (auth.jwt() ->> 'tenant_id')::UUID);

-- Tenant isolation for DELETE
CREATE POLICY "customer_addresses_tenant_isolation_delete" ON customer_addresses
  FOR DELETE USING (tenant_id = (auth.jwt() ->> 'tenant_id')::UUID);

-- ============================================================================
-- 2. SUBSCRIPTIONS
-- ============================================================================

ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;

-- Tenant can view their own subscription
CREATE POLICY "subscriptions_tenant_access" ON subscriptions
  FOR SELECT USING (tenant_id = (auth.jwt() ->> 'tenant_id')::UUID);

-- Platform admins can view all subscriptions
CREATE POLICY "subscriptions_platform_admin_access" ON subscriptions
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM users u
      WHERE u.id = auth.uid() AND u.role = 'platform_admin'
    )
  );

-- Tenants cannot modify their own subscriptions (platform only)
-- No INSERT, UPDATE, DELETE policies for tenants

-- ============================================================================
-- 3. COMMISSIONS
-- ============================================================================

ALTER TABLE commissions ENABLE ROW LEVEL SECURITY;

-- Tenant can view their own commissions
CREATE POLICY "commissions_tenant_access" ON commissions
  FOR SELECT USING (tenant_id = (auth.jwt() ->> 'tenant_id')::UUID);

-- Platform admins can manage all commissions
CREATE POLICY "commissions_platform_admin_access" ON commissions
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM users u
      WHERE u.id = auth.uid() AND u.role = 'platform_admin'
    )
  );

-- ============================================================================
-- 4. RECEIPTS
-- ============================================================================

ALTER TABLE receipts ENABLE ROW LEVEL SECURITY;

-- Tenant isolation for SELECT
CREATE POLICY "receipts_tenant_isolation_select" ON receipts
  FOR SELECT USING (tenant_id = (auth.jwt() ->> 'tenant_id')::UUID);

-- Tenant isolation for INSERT
CREATE POLICY "receipts_tenant_isolation_insert" ON receipts
  FOR INSERT WITH CHECK (tenant_id = (auth.jwt() ->> 'tenant_id')::UUID);

-- Tenant isolation for UPDATE
CREATE POLICY "receipts_tenant_isolation_update" ON receipts
  FOR UPDATE USING (tenant_id = (auth.jwt() ->> 'tenant_id')::UUID);

-- Tenant isolation for DELETE
CREATE POLICY "receipts_tenant_isolation_delete" ON receipts
  FOR DELETE USING (tenant_id = (auth.jwt() ->> 'tenant_id')::UUID);

-- ============================================================================
-- 5. TRANSFER_ITEMS
-- ============================================================================

ALTER TABLE transfer_items ENABLE ROW LEVEL SECURITY;

-- Assuming transfer_items has tenant_id (if not, needs to join through inter_branch_transfers)
-- If transfer_items has tenant_id directly:
CREATE POLICY "transfer_items_tenant_isolation_select" ON transfer_items
  FOR SELECT USING (
    tenant_id = (auth.jwt() ->> 'tenant_id')::UUID
  );

CREATE POLICY "transfer_items_tenant_isolation_insert" ON transfer_items
  FOR INSERT WITH CHECK (
    tenant_id = (auth.jwt() ->> 'tenant_id')::UUID
  );

CREATE POLICY "transfer_items_tenant_isolation_update" ON transfer_items
  FOR UPDATE USING (
    tenant_id = (auth.jwt() ->> 'tenant_id')::UUID
  );

CREATE POLICY "transfer_items_tenant_isolation_delete" ON transfer_items
  FOR DELETE USING (
    tenant_id = (auth.jwt() ->> 'tenant_id')::UUID
  );

-- If transfer_items doesn't have tenant_id, use this alternative (join through parent):
-- CREATE POLICY "transfer_items_tenant_isolation_select" ON transfer_items
--   FOR SELECT USING (
--     EXISTS (
--       SELECT 1 FROM inter_branch_transfers ibt
--       WHERE ibt.id = transfer_items.transfer_id
--       AND ibt.tenant_id = (auth.jwt() ->> 'tenant_id')::UUID
--     )
--   );

-- ============================================================================
-- 6. CHAT_MESSAGES
-- ============================================================================

ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;

-- Tenant isolation for SELECT
CREATE POLICY "chat_messages_tenant_isolation_select" ON chat_messages
  FOR SELECT USING (tenant_id = (auth.jwt() ->> 'tenant_id')::UUID);

-- Tenant isolation for INSERT
CREATE POLICY "chat_messages_tenant_isolation_insert" ON chat_messages
  FOR INSERT WITH CHECK (tenant_id = (auth.jwt() ->> 'tenant_id')::UUID);

-- Tenant isolation for UPDATE
CREATE POLICY "chat_messages_tenant_isolation_update" ON chat_messages
  FOR UPDATE USING (tenant_id = (auth.jwt() ->> 'tenant_id')::UUID);

-- Tenant isolation for DELETE
CREATE POLICY "chat_messages_tenant_isolation_delete" ON chat_messages
  FOR DELETE USING (tenant_id = (auth.jwt() ->> 'tenant_id')::UUID);

-- ============================================================================
-- 7. ECOMMERCE_PRODUCTS (assuming this is the ecommerce_pr... table)
-- ============================================================================

-- Note: Adjust table name if different
ALTER TABLE ecommerce_products ENABLE ROW LEVEL SECURITY;

CREATE POLICY "ecommerce_products_tenant_isolation_select" ON ecommerce_products
  FOR SELECT USING (tenant_id = (auth.jwt() ->> 'tenant_id')::UUID);

CREATE POLICY "ecommerce_products_tenant_isolation_insert" ON ecommerce_products
  FOR INSERT WITH CHECK (tenant_id = (auth.jwt() ->> 'tenant_id')::UUID);

CREATE POLICY "ecommerce_products_tenant_isolation_update" ON ecommerce_products
  FOR UPDATE USING (tenant_id = (auth.jwt() ->> 'tenant_id')::UUID);

CREATE POLICY "ecommerce_products_tenant_isolation_delete" ON ecommerce_products
  FOR DELETE USING (tenant_id = (auth.jwt() ->> 'tenant_id')::UUID);

-- ============================================================================
-- 8. DIM_DATE (Analytics Dimension Table)
-- ============================================================================

ALTER TABLE dim_date ENABLE ROW LEVEL SECURITY;

-- Dimension tables are shared across tenants (no tenant_id)
-- All authenticated users can read, but cannot modify
CREATE POLICY "dim_date_read_all" ON dim_date
  FOR SELECT USING (auth.role() = 'authenticated');

-- Only platform admins can modify
CREATE POLICY "dim_date_admin_modify" ON dim_date
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM users u
      WHERE u.id = auth.uid() AND u.role = 'platform_admin'
    )
  );

-- ============================================================================
-- 9. DIM_TIME (Analytics Dimension Table)
-- ============================================================================

ALTER TABLE dim_time ENABLE ROW LEVEL SECURITY;

-- Dimension tables are shared across tenants (no tenant_id)
-- All authenticated users can read, but cannot modify
CREATE POLICY "dim_time_read_all" ON dim_time
  FOR SELECT USING (auth.role() = 'authenticated');

-- Only platform admins can modify
CREATE POLICY "dim_time_admin_modify" ON dim_time
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM users u
      WHERE u.id = auth.uid() AND u.role = 'platform_admin'
    )
  );

-- ============================================================================
-- 10. SPATIAL_REF_SYS (PostGIS System Table)
-- ============================================================================

ALTER TABLE spatial_ref_sys ENABLE ROW LEVEL SECURITY;

-- PostGIS system table - all authenticated users can read
CREATE POLICY "spatial_ref_sys_read_all" ON spatial_ref_sys
  FOR SELECT USING (auth.role() = 'authenticated');

-- Only platform admins can modify (should rarely be needed)
CREATE POLICY "spatial_ref_sys_admin_modify" ON spatial_ref_sys
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM users u
      WHERE u.id = auth.uid() AND u.role = 'platform_admin'
    )
  );

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================

-- Run these queries to verify RLS is enabled:
-- SELECT tablename, rowsecurity FROM pg_tables WHERE schemaname = 'public' AND rowsecurity = false;

-- Run this to see all policies:
-- SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual
-- FROM pg_policies
-- WHERE schemaname = 'public'
-- ORDER BY tablename, policyname;

-- ============================================================================
-- NOTES
-- ============================================================================

-- 1. transfer_items: If this table doesn't have tenant_id, uncomment the alternative policy
-- 2. ecommerce_products: Verify the exact table name in your schema
-- 3. dim_date, dim_time: These are dimension tables shared across all tenants
-- 4. spatial_ref_sys: PostGIS system table, rarely modified
-- 5. Platform admin role: Assumes users table has 'platform_admin' role

-- ============================================================================
-- ROLLBACK (if needed)
-- ============================================================================

-- To disable RLS on all tables (DANGEROUS - only for emergency):
-- ALTER TABLE customer_addresses DISABLE ROW LEVEL SECURITY;
-- ALTER TABLE subscriptions DISABLE ROW LEVEL SECURITY;
-- ALTER TABLE commissions DISABLE ROW LEVEL SECURITY;
-- ALTER TABLE receipts DISABLE ROW LEVEL SECURITY;
-- ALTER TABLE transfer_items DISABLE ROW LEVEL SECURITY;
-- ALTER TABLE chat_messages DISABLE ROW LEVEL SECURITY;
-- ALTER TABLE ecommerce_products DISABLE ROW LEVEL SECURITY;
-- ALTER TABLE dim_date DISABLE ROW LEVEL SECURITY;
-- ALTER TABLE dim_time DISABLE ROW LEVEL SECURITY;
-- ALTER TABLE spatial_ref_sys DISABLE ROW LEVEL SECURITY;
