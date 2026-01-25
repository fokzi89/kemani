-- ============================================================================
-- CRITICAL SECURITY FIX: Enable Row Level Security
-- ============================================================================
-- Apply Date: 2026-01-25
-- Fixes: Multi-tenant data leakage vulnerability on 10 tables
-- Estimated Time: 30 seconds
-- ============================================================================

-- 1. CUSTOMER_ADDRESSES
ALTER TABLE customer_addresses ENABLE ROW LEVEL SECURITY;
CREATE POLICY "customer_addresses_tenant_isolation_select" ON customer_addresses FOR SELECT USING (tenant_id = (auth.jwt() ->> 'tenant_id')::UUID);
CREATE POLICY "customer_addresses_tenant_isolation_insert" ON customer_addresses FOR INSERT WITH CHECK (tenant_id = (auth.jwt() ->> 'tenant_id')::UUID);
CREATE POLICY "customer_addresses_tenant_isolation_update" ON customer_addresses FOR UPDATE USING (tenant_id = (auth.jwt() ->> 'tenant_id')::UUID);
CREATE POLICY "customer_addresses_tenant_isolation_delete" ON customer_addresses FOR DELETE USING (tenant_id = (auth.jwt() ->> 'tenant_id')::UUID);

-- 2. SUBSCRIPTIONS
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "subscriptions_tenant_access" ON subscriptions FOR SELECT USING (tenant_id = (auth.jwt() ->> 'tenant_id')::UUID);
CREATE POLICY "subscriptions_platform_admin_access" ON subscriptions FOR ALL USING (EXISTS (SELECT 1 FROM users u WHERE u.id = auth.uid() AND u.role = 'platform_admin'));

-- 3. COMMISSIONS
ALTER TABLE commissions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "commissions_tenant_access" ON commissions FOR SELECT USING (tenant_id = (auth.jwt() ->> 'tenant_id')::UUID);
CREATE POLICY "commissions_platform_admin_access" ON commissions FOR ALL USING (EXISTS (SELECT 1 FROM users u WHERE u.id = auth.uid() AND u.role = 'platform_admin'));

-- 4. RECEIPTS
ALTER TABLE receipts ENABLE ROW LEVEL SECURITY;
CREATE POLICY "receipts_tenant_isolation_select" ON receipts FOR SELECT USING (tenant_id = (auth.jwt() ->> 'tenant_id')::UUID);
CREATE POLICY "receipts_tenant_isolation_insert" ON receipts FOR INSERT WITH CHECK (tenant_id = (auth.jwt() ->> 'tenant_id')::UUID);
CREATE POLICY "receipts_tenant_isolation_update" ON receipts FOR UPDATE USING (tenant_id = (auth.jwt() ->> 'tenant_id')::UUID);
CREATE POLICY "receipts_tenant_isolation_delete" ON receipts FOR DELETE USING (tenant_id = (auth.jwt() ->> 'tenant_id')::UUID);

-- 5. TRANSFER_ITEMS
ALTER TABLE transfer_items ENABLE ROW LEVEL SECURITY;
CREATE POLICY "transfer_items_tenant_isolation_select" ON transfer_items FOR SELECT USING (tenant_id = (auth.jwt() ->> 'tenant_id')::UUID);
CREATE POLICY "transfer_items_tenant_isolation_insert" ON transfer_items FOR INSERT WITH CHECK (tenant_id = (auth.jwt() ->> 'tenant_id')::UUID);
CREATE POLICY "transfer_items_tenant_isolation_update" ON transfer_items FOR UPDATE USING (tenant_id = (auth.jwt() ->> 'tenant_id')::UUID);
CREATE POLICY "transfer_items_tenant_isolation_delete" ON transfer_items FOR DELETE USING (tenant_id = (auth.jwt() ->> 'tenant_id')::UUID);

-- 6. CHAT_MESSAGES
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;
CREATE POLICY "chat_messages_tenant_isolation_select" ON chat_messages FOR SELECT USING (tenant_id = (auth.jwt() ->> 'tenant_id')::UUID);
CREATE POLICY "chat_messages_tenant_isolation_insert" ON chat_messages FOR INSERT WITH CHECK (tenant_id = (auth.jwt() ->> 'tenant_id')::UUID);
CREATE POLICY "chat_messages_tenant_isolation_update" ON chat_messages FOR UPDATE USING (tenant_id = (auth.jwt() ->> 'tenant_id')::UUID);
CREATE POLICY "chat_messages_tenant_isolation_delete" ON chat_messages FOR DELETE USING (tenant_id = (auth.jwt() ->> 'tenant_id')::UUID);

-- 7. ECOMMERCE_PRODUCTS
ALTER TABLE ecommerce_products ENABLE ROW LEVEL SECURITY;
CREATE POLICY "ecommerce_products_tenant_isolation_select" ON ecommerce_products FOR SELECT USING (tenant_id = (auth.jwt() ->> 'tenant_id')::UUID);
CREATE POLICY "ecommerce_products_tenant_isolation_insert" ON ecommerce_products FOR INSERT WITH CHECK (tenant_id = (auth.jwt() ->> 'tenant_id')::UUID);
CREATE POLICY "ecommerce_products_tenant_isolation_update" ON ecommerce_products FOR UPDATE USING (tenant_id = (auth.jwt() ->> 'tenant_id')::UUID);
CREATE POLICY "ecommerce_products_tenant_isolation_delete" ON ecommerce_products FOR DELETE USING (tenant_id = (auth.jwt() ->> 'tenant_id')::UUID);

-- 8. DIM_DATE (Shared dimension - all tenants can read)
ALTER TABLE dim_date ENABLE ROW LEVEL SECURITY;
CREATE POLICY "dim_date_read_all" ON dim_date FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "dim_date_admin_modify" ON dim_date FOR ALL USING (EXISTS (SELECT 1 FROM users u WHERE u.id = auth.uid() AND u.role = 'platform_admin'));

-- 9. DIM_TIME (Shared dimension - all tenants can read)
ALTER TABLE dim_time ENABLE ROW LEVEL SECURITY;
CREATE POLICY "dim_time_read_all" ON dim_time FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "dim_time_admin_modify" ON dim_time FOR ALL USING (EXISTS (SELECT 1 FROM users u WHERE u.id = auth.uid() AND u.role = 'platform_admin'));

-- 10. SPATIAL_REF_SYS (PostGIS system table)
ALTER TABLE spatial_ref_sys ENABLE ROW LEVEL SECURITY;
CREATE POLICY "spatial_ref_sys_read_all" ON spatial_ref_sys FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "spatial_ref_sys_admin_modify" ON spatial_ref_sys FOR ALL USING (EXISTS (SELECT 1 FROM users u WHERE u.id = auth.uid() AND u.role = 'platform_admin'));

-- ============================================================================
-- SUCCESS! RLS is now enabled on all 10 tables
-- ============================================================================
