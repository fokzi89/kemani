-- ============================================================================
-- CORRECTED RLS MIGRATION - Based on Actual Table Schemas
-- ============================================================================
-- Date: 2026-01-25
-- This version uses the correct column names and relationships
-- ============================================================================

-- ============================================================================
-- 1. COMMISSIONS (has tenant_id directly)
-- ============================================================================
ALTER TABLE commissions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "commissions_tenant_access" ON commissions
  FOR SELECT USING (tenant_id = (auth.jwt() ->> 'tenant_id')::UUID);

CREATE POLICY "commissions_platform_admin" ON commissions
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM users u
      WHERE u.id = auth.uid() AND u.role = 'platform_admin'
    )
  );

-- ============================================================================
-- 2. SUBSCRIPTIONS (has tenant_id directly)
-- ============================================================================
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "subscriptions_tenant_access" ON subscriptions
  FOR SELECT USING (tenant_id = (auth.jwt() ->> 'tenant_id')::UUID);

CREATE POLICY "subscriptions_platform_admin" ON subscriptions
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM users u
      WHERE u.id = auth.uid() AND u.role = 'platform_admin'
    )
  );

-- ============================================================================
-- 3. CUSTOMER_ADDRESSES (NO tenant_id - join through customers)
-- ============================================================================
ALTER TABLE customer_addresses ENABLE ROW LEVEL SECURITY;

CREATE POLICY "customer_addresses_tenant_isolation" ON customer_addresses
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM customers c
      WHERE c.id = customer_addresses.customer_id
      AND c.tenant_id = (auth.jwt() ->> 'tenant_id')::UUID
    )
  );

-- ============================================================================
-- 4. RECEIPTS (NO tenant_id - join through sales)
-- ============================================================================
ALTER TABLE receipts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "receipts_tenant_isolation" ON receipts
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM sales s
      WHERE s.id = receipts.sale_id
      AND s.tenant_id = (auth.jwt() ->> 'tenant_id')::UUID
    )
  );

-- ============================================================================
-- 5. TRANSFER_ITEMS (NO tenant_id - join through inter_branch_transfers)
-- ============================================================================
ALTER TABLE transfer_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "transfer_items_tenant_isolation" ON transfer_items
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM inter_branch_transfers ibt
      WHERE ibt.id = transfer_items.transfer_id
      AND ibt.tenant_id = (auth.jwt() ->> 'tenant_id')::UUID
    )
  );

-- ============================================================================
-- 6. CHAT_MESSAGES (NO tenant_id - join through chat_conversations)
-- ============================================================================
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "chat_messages_tenant_isolation" ON chat_messages
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM chat_conversations cc
      WHERE cc.id = chat_messages.conversation_id
      AND cc.tenant_id = (auth.jwt() ->> 'tenant_id')::UUID
    )
  );

-- ============================================================================
-- 7. DIM_DATE (Shared dimension table - no tenant_id)
-- ============================================================================
ALTER TABLE dim_date ENABLE ROW LEVEL SECURITY;

-- All authenticated users can read
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
-- 8. DIM_TIME (Shared dimension table - no tenant_id)
-- ============================================================================
ALTER TABLE dim_time ENABLE ROW LEVEL SECURITY;

-- All authenticated users can read
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
-- 9. SPATIAL_REF_SYS (PostGIS system table)
-- ============================================================================
ALTER TABLE spatial_ref_sys ENABLE ROW LEVEL SECURITY;

-- All authenticated users can read
CREATE POLICY "spatial_ref_sys_read_all" ON spatial_ref_sys
  FOR SELECT USING (auth.role() = 'authenticated');

-- Only platform admins can modify (rarely needed)
CREATE POLICY "spatial_ref_sys_admin_modify" ON spatial_ref_sys
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM users u
      WHERE u.id = auth.uid() AND u.role = 'platform_admin'
    )
  );

-- ============================================================================
-- NOTE: ECOMMERCE_PRODUCTS
-- ============================================================================
-- ecommerce_products is a VIEW, not a table
-- RLS is applied on the underlying tables (products, branches)
-- No need to apply RLS on the view itself
-- The view already includes tenant_id and will be filtered by the
-- RLS policies on the products and branches tables

-- ============================================================================
-- SUCCESS! All 9 tables now have RLS enabled
-- ============================================================================
-- Tables secured:
-- 1. commissions (direct tenant_id)
-- 2. subscriptions (direct tenant_id)
-- 3. customer_addresses (via customers FK)
-- 4. receipts (via sales FK)
-- 5. transfer_items (via inter_branch_transfers FK)
-- 6. chat_messages (via chat_conversations FK)
-- 7. dim_date (shared - all can read)
-- 8. dim_time (shared - all can read)
-- 9. spatial_ref_sys (system table - all can read)
-- ============================================================================
