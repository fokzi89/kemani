-- ============================================================================
-- RLS SAFE VERSION: Skip system tables you don't own
-- ============================================================================

-- 1. COMMISSIONS
ALTER TABLE commissions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "commissions_tenant_access" ON commissions
  FOR SELECT USING (tenant_id = (auth.jwt() ->> 'tenant_id')::UUID);

-- 2. SUBSCRIPTIONS
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "subscriptions_tenant_access" ON subscriptions
  FOR SELECT USING (tenant_id = (auth.jwt() ->> 'tenant_id')::UUID);

-- 3. DIM_DATE (shared - all can read)
ALTER TABLE dim_date ENABLE ROW LEVEL SECURITY;
CREATE POLICY "dim_date_read_all" ON dim_date
  FOR SELECT USING (auth.role() = 'authenticated');

-- 4. DIM_TIME (shared - all can read)
ALTER TABLE dim_time ENABLE ROW LEVEL SECURITY;
CREATE POLICY "dim_time_read_all" ON dim_time
  FOR SELECT USING (auth.role() = 'authenticated');

-- NOTE: Skipping spatial_ref_sys (PostGIS system table - no permission to alter)

-- SUCCESS! 4 tables secured
