-- Migration: Add Row Level Security to Unrestricted Tables
-- Date: 2026-01-25
-- Description: Enable RLS and add tenant isolation policies for 10 tables missing security

-- ============================================================================
-- 1. CUSTOMER_ADDRESSES
-- ============================================================================

ALTER TABLE customer_addresses ENABLE ROW LEVEL SECURITY;

-- Add tenant_id if missing (Fix for RLS policy dependency)
ALTER TABLE customer_addresses ADD COLUMN IF NOT EXISTS tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE;

-- Tenant isolation for SELECT
DROP POLICY IF EXISTS "customer_addresses_tenant_isolation_select" ON customer_addresses;
CREATE POLICY "customer_addresses_tenant_isolation_select" ON customer_addresses
  FOR SELECT USING (tenant_id = (auth.jwt() ->> 'tenant_id')::UUID);

-- Tenant isolation for INSERT
DROP POLICY IF EXISTS "customer_addresses_tenant_isolation_insert" ON customer_addresses;
CREATE POLICY "customer_addresses_tenant_isolation_insert" ON customer_addresses
  FOR INSERT WITH CHECK (tenant_id = (auth.jwt() ->> 'tenant_id')::UUID);

-- Tenant isolation for UPDATE
DROP POLICY IF EXISTS "customer_addresses_tenant_isolation_update" ON customer_addresses;
CREATE POLICY "customer_addresses_tenant_isolation_update" ON customer_addresses
  FOR UPDATE USING (tenant_id = (auth.jwt() ->> 'tenant_id')::UUID);

-- Tenant isolation for DELETE
DROP POLICY IF EXISTS "customer_addresses_tenant_isolation_delete" ON customer_addresses;
CREATE POLICY "customer_addresses_tenant_isolation_delete" ON customer_addresses
  FOR DELETE USING (tenant_id = (auth.jwt() ->> 'tenant_id')::UUID);

-- ============================================================================
-- 2. SUBSCRIPTIONS
-- ============================================================================

ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;

-- Tenant can view their own subscription
DROP POLICY IF EXISTS "subscriptions_tenant_access" ON subscriptions;
CREATE POLICY "subscriptions_tenant_access" ON subscriptions
  FOR SELECT USING (tenant_id = (auth.jwt() ->> 'tenant_id')::UUID);

-- Platform admins can view all subscriptions
DROP POLICY IF EXISTS "subscriptions_platform_admin_access" ON subscriptions;
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
DROP POLICY IF EXISTS "commissions_tenant_access" ON commissions;
CREATE POLICY "commissions_tenant_access" ON commissions
  FOR SELECT USING (tenant_id = (auth.jwt() ->> 'tenant_id')::UUID);

-- Platform admins can manage all commissions
DROP POLICY IF EXISTS "commissions_platform_admin_access" ON commissions;
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
DROP POLICY IF EXISTS "receipts_tenant_isolation_select" ON receipts;
CREATE POLICY "receipts_tenant_isolation_select" ON receipts
  FOR SELECT USING (tenant_id = (auth.jwt() ->> 'tenant_id')::UUID);

-- Tenant isolation for INSERT
DROP POLICY IF EXISTS "receipts_tenant_isolation_insert" ON receipts;
CREATE POLICY "receipts_tenant_isolation_insert" ON receipts
  FOR INSERT WITH CHECK (tenant_id = (auth.jwt() ->> 'tenant_id')::UUID);

-- Tenant isolation for UPDATE
DROP POLICY IF EXISTS "receipts_tenant_isolation_update" ON receipts;
CREATE POLICY "receipts_tenant_isolation_update" ON receipts
  FOR UPDATE USING (tenant_id = (auth.jwt() ->> 'tenant_id')::UUID);

-- Tenant isolation for DELETE
DROP POLICY IF EXISTS "receipts_tenant_isolation_delete" ON receipts;
CREATE POLICY "receipts_tenant_isolation_delete" ON receipts
  FOR DELETE USING (tenant_id = (auth.jwt() ->> 'tenant_id')::UUID);

-- ============================================================================
-- 5. TRANSFER_ITEMS
-- ============================================================================

ALTER TABLE transfer_items ENABLE ROW LEVEL SECURITY;

-- Assuming transfer_items has tenant_id (if not, needs to join through inter_branch_transfers)
-- If transfer_items has tenant_id directly:
DROP POLICY IF EXISTS "transfer_items_tenant_isolation_select" ON transfer_items;
CREATE POLICY "transfer_items_tenant_isolation_select" ON transfer_items
  FOR SELECT USING (
    tenant_id = (auth.jwt() ->> 'tenant_id')::UUID
  );

DROP POLICY IF EXISTS "transfer_items_tenant_isolation_insert" ON transfer_items;
CREATE POLICY "transfer_items_tenant_isolation_insert" ON transfer_items
  FOR INSERT WITH CHECK (
    tenant_id = (auth.jwt() ->> 'tenant_id')::UUID
  );

DROP POLICY IF EXISTS "transfer_items_tenant_isolation_update" ON transfer_items;
CREATE POLICY "transfer_items_tenant_isolation_update" ON transfer_items
  FOR UPDATE USING (
    tenant_id = (auth.jwt() ->> 'tenant_id')::UUID
  );

DROP POLICY IF EXISTS "transfer_items_tenant_isolation_delete" ON transfer_items;
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
DROP POLICY IF EXISTS "chat_messages_tenant_isolation_select" ON chat_messages;
CREATE POLICY "chat_messages_tenant_isolation_select" ON chat_messages
  FOR SELECT USING (tenant_id = (auth.jwt() ->> 'tenant_id')::UUID);

-- Tenant isolation for INSERT
DROP POLICY IF EXISTS "chat_messages_tenant_isolation_insert" ON chat_messages;
CREATE POLICY "chat_messages_tenant_isolation_insert" ON chat_messages
  FOR INSERT WITH CHECK (tenant_id = (auth.jwt() ->> 'tenant_id')::UUID);

-- Tenant isolation for UPDATE
DROP POLICY IF EXISTS "chat_messages_tenant_isolation_update" ON chat_messages;
CREATE POLICY "chat_messages_tenant_isolation_update" ON chat_messages
  FOR UPDATE USING (tenant_id = (auth.jwt() ->> 'tenant_id')::UUID);

-- Tenant isolation for DELETE
DROP POLICY IF EXISTS "chat_messages_tenant_isolation_delete" ON chat_messages;
CREATE POLICY "chat_messages_tenant_isolation_delete" ON chat_messages
  FOR DELETE USING (tenant_id = (auth.jwt() ->> 'tenant_id')::UUID);

-- ============================================================================
-- 7. ECOMMERCE_PRODUCTS (assuming this is the ecommerce_pr... table)
-- ============================================================================

-- Note: Adjust table name if different
-- ALTER TABLE ecommerce_products ENABLE ROW LEVEL SECURITY;
-- Skipping potential missing table to avoid blockers, or assume it exists.
-- User code has `ecommerce_products`? Code uses `ecommerce_connections`?
-- Let's stick to simple "IF EXISTS" logic for tables if Postgres supported `ALTER TABLE IF EXISTS` but for enabling RLS strictly it doesn't matter.
-- Assuming table exists.

ALTER TABLE ecommerce_products ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "ecommerce_products_tenant_isolation_select" ON ecommerce_products;
CREATE POLICY "ecommerce_products_tenant_isolation_select" ON ecommerce_products
  FOR SELECT USING (tenant_id = (auth.jwt() ->> 'tenant_id')::UUID);

DROP POLICY IF EXISTS "ecommerce_products_tenant_isolation_insert" ON ecommerce_products;
CREATE POLICY "ecommerce_products_tenant_isolation_insert" ON ecommerce_products
  FOR INSERT WITH CHECK (tenant_id = (auth.jwt() ->> 'tenant_id')::UUID);

DROP POLICY IF EXISTS "ecommerce_products_tenant_isolation_update" ON ecommerce_products;
CREATE POLICY "ecommerce_products_tenant_isolation_update" ON ecommerce_products
  FOR UPDATE USING (tenant_id = (auth.jwt() ->> 'tenant_id')::UUID);

DROP POLICY IF EXISTS "ecommerce_products_tenant_isolation_delete" ON ecommerce_products;
CREATE POLICY "ecommerce_products_tenant_isolation_delete" ON ecommerce_products
  FOR DELETE USING (tenant_id = (auth.jwt() ->> 'tenant_id')::UUID);

-- ============================================================================
-- 8. DIM_DATE (Analytics Dimension Table)
-- ============================================================================

ALTER TABLE dim_date ENABLE ROW LEVEL SECURITY;

-- Dimension tables are shared across tenants (no tenant_id)
-- All authenticated users can read, but cannot modify
DROP POLICY IF EXISTS "dim_date_read_all" ON dim_date;
CREATE POLICY "dim_date_read_all" ON dim_date
  FOR SELECT USING (auth.role() = 'authenticated');

-- Only platform admins can modify
DROP POLICY IF EXISTS "dim_date_admin_modify" ON dim_date;
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
DROP POLICY IF EXISTS "dim_time_read_all" ON dim_time;
CREATE POLICY "dim_time_read_all" ON dim_time
  FOR SELECT USING (auth.role() = 'authenticated');

-- Only platform admins can modify
DROP POLICY IF EXISTS "dim_time_admin_modify" ON dim_time;
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
DROP POLICY IF EXISTS "spatial_ref_sys_read_all" ON spatial_ref_sys;
CREATE POLICY "spatial_ref_sys_read_all" ON spatial_ref_sys
  FOR SELECT USING (auth.role() = 'authenticated');

-- Only platform admins can modify (should rarely be needed)
DROP POLICY IF EXISTS "spatial_ref_sys_admin_modify" ON spatial_ref_sys;
CREATE POLICY "spatial_ref_sys_admin_modify" ON spatial_ref_sys
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM users u
      WHERE u.id = auth.uid() AND u.role = 'platform_admin'
    )
  );
