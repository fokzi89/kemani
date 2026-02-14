-- ============================================================================
-- RLS STEP 1: Enable RLS on tables with DIRECT tenant_id column only
-- ============================================================================
-- This will work for sure since we confirmed these tables have tenant_id
-- ============================================================================

-- 1. COMMISSIONS (confirmed has tenant_id)
ALTER TABLE commissions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "commissions_tenant_access" ON commissions;
CREATE POLICY "commissions_tenant_access" ON commissions
  FOR SELECT USING (tenant_id = (auth.jwt() ->> 'tenant_id')::UUID);

-- 2. SUBSCRIPTIONS (confirmed has tenant_id)
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "subscriptions_tenant_access" ON subscriptions;
CREATE POLICY "subscriptions_tenant_access" ON subscriptions
  FOR SELECT USING (tenant_id = (auth.jwt() ->> 'tenant_id')::UUID);

-- 3. DIM_DATE (shared table - no tenant_id, all can read)
ALTER TABLE dim_date ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "dim_date_read_all" ON dim_date;
CREATE POLICY "dim_date_read_all" ON dim_date
  FOR SELECT USING (auth.role() = 'authenticated');

-- 4. DIM_TIME (shared table - no tenant_id, all can read)
ALTER TABLE dim_time ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "dim_time_read_all" ON dim_time;
CREATE POLICY "dim_time_read_all" ON dim_time
  FOR SELECT USING (auth.role() = 'authenticated');

-- 5. SPATIAL_REF_SYS (PostGIS system table)
ALTER TABLE spatial_ref_sys ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "spatial_ref_sys_read_all" ON spatial_ref_sys;
CREATE POLICY "spatial_ref_sys_read_all" ON spatial_ref_sys
  FOR SELECT USING (auth.role() = 'authenticated');

-- ============================================================================
-- SUCCESS! 5 tables secured
-- Next: We'll handle the joined tables after checking parent table schemas
-- ============================================================================
