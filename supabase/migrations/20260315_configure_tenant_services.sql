-- Configure Tenant Services
-- Feature: 004-tenant-referral-commissions
-- Run this after applying 20260315_tenant_services_routing.sql

-- =============================================================================
-- STEP 1: VIEW CURRENT TENANTS
-- =============================================================================

-- First, let's see all existing tenants
-- Uncomment and run this in SQL editor to see your tenants:
-- SELECT id, name, subdomain, business_type, services_offered FROM tenants;

-- =============================================================================
-- STEP 2: CONFIGURE SERVICES FOR EACH TENANT
-- =============================================================================

-- Example: Fokz Pharmacy (pharmacy + diagnostic)
-- UPDATE tenants
-- SET services_offered = ARRAY['pharmacy', 'diagnostic']
-- WHERE subdomain = 'fokz';

-- Example: Medic Clinic (consultation only)
-- UPDATE tenants
-- SET services_offered = ARRAY['consultation']
-- WHERE subdomain = 'medic';

-- Example: CareLab (diagnostic only)
-- UPDATE tenants
-- SET services_offered = ARRAY['diagnostic']
-- WHERE subdomain = 'carelab';

-- Example: General Hospital (all services)
-- UPDATE tenants
-- SET services_offered = ARRAY['pharmacy', 'diagnostic', 'consultation']
-- WHERE subdomain = 'general-hospital';

-- =============================================================================
-- STEP 3: CONFIGURE BASED ON BUSINESS TYPE (BULK UPDATE)
-- =============================================================================

-- Option 1: Configure all pharmacies to offer pharmacy services
UPDATE tenants
SET services_offered = ARRAY['pharmacy']
WHERE business_type = 'pharmacy'
  AND services_offered = ARRAY[]::TEXT[];

-- Option 2: Configure all diagnostic centers
UPDATE tenants
SET services_offered = ARRAY['diagnostic']
WHERE business_type IN ('diagnostic_center', 'laboratory')
  AND services_offered = ARRAY[]::TEXT[];

-- Option 3: Configure all clinics/hospitals
UPDATE tenants
SET services_offered = ARRAY['consultation']
WHERE business_type IN ('clinic', 'hospital', 'medical_center')
  AND services_offered = ARRAY[]::TEXT[];

-- =============================================================================
-- STEP 4: VERIFY CONFIGURATION
-- =============================================================================

-- Check all tenants and their services
SELECT
  id,
  name,
  subdomain,
  business_type,
  services_offered,
  CASE
    WHEN 'pharmacy' = ANY(services_offered) THEN 'Yes'
    ELSE 'No'
  END as offers_pharmacy,
  CASE
    WHEN 'diagnostic' = ANY(services_offered) THEN 'Yes'
    ELSE 'No'
  END as offers_diagnostic,
  CASE
    WHEN 'consultation' = ANY(services_offered) THEN 'Yes'
    ELSE 'No'
  END as offers_consultation
FROM tenants
ORDER BY name;

-- =============================================================================
-- STEP 5: TEST SERVICE ROUTING
-- =============================================================================

-- Test 1: Check if tenant offers specific service
-- SELECT tenant_offers_service('YOUR-TENANT-UUID', 'pharmacy');

-- Test 2: Get routing decision
-- SELECT * FROM get_service_provider('YOUR-TENANT-UUID', 'diagnostic');

-- Expected Results:
-- If tenant offers service: (TRUE, tenant-uuid, tenant-name)
-- If tenant doesn't offer: (FALSE, NULL, NULL)

-- =============================================================================
-- NOTES
-- =============================================================================

-- Valid service types: 'pharmacy', 'diagnostic', 'consultation'
-- One tenant can offer multiple services
-- Empty array means tenant offers no services (always show directory)
-- Services determine auto-routing behavior in storefront

-- Business Rules:
-- 1. If referring tenant offers service → auto-route to them
-- 2. If referring tenant doesn't offer service → show external directory
-- 3. Same tenant as provider → self-provider (no referral commission)
-- 4. Different tenant as provider → referral commission applies
