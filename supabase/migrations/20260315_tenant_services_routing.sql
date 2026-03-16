-- Tenant Services and Automatic Routing
-- Feature: 004-tenant-referral-commissions
-- Created: 2026-03-15
-- Description: Adds service offerings to tenants for automatic routing

-- =============================================================================
-- PART 1: ADD SERVICES OFFERED TO TENANTS
-- =============================================================================

-- Add services_offered column to track what services each tenant provides
ALTER TABLE tenants
ADD COLUMN IF NOT EXISTS services_offered TEXT[] DEFAULT ARRAY[]::TEXT[];

-- Add constraint to ensure valid service types
ALTER TABLE tenants
ADD CONSTRAINT valid_service_types CHECK (
  services_offered <@ ARRAY['pharmacy', 'diagnostic', 'consultation']::TEXT[]
);

-- Create index for faster service lookups
CREATE INDEX IF NOT EXISTS idx_tenants_services ON tenants USING GIN (services_offered);

-- =============================================================================
-- PART 2: HELPER FUNCTION - CHECK IF TENANT OFFERS SERVICE
-- =============================================================================

CREATE OR REPLACE FUNCTION tenant_offers_service(
  p_tenant_id UUID,
  p_service_type TEXT
) RETURNS BOOLEAN AS $$
DECLARE
  services TEXT[];
BEGIN
  -- Get services offered by tenant
  SELECT services_offered INTO services
  FROM tenants
  WHERE id = p_tenant_id;

  -- Return true if service is in array
  RETURN p_service_type = ANY(services);
END;
$$ LANGUAGE plpgsql STABLE;

-- =============================================================================
-- PART 3: ROUTING LOGIC FUNCTION
-- =============================================================================

CREATE OR REPLACE FUNCTION get_service_provider(
  p_referring_tenant_id UUID,
  p_service_type TEXT
) RETURNS TABLE (
  should_auto_route BOOLEAN,
  provider_tenant_id UUID,
  provider_name TEXT
) AS $$
BEGIN
  -- Check if referring tenant offers the requested service
  IF tenant_offers_service(p_referring_tenant_id, p_service_type) THEN
    -- AUTO-ROUTE to referring tenant
    RETURN QUERY
    SELECT
      TRUE as should_auto_route,
      t.id as provider_tenant_id,
      t.name as provider_name
    FROM tenants t
    WHERE t.id = p_referring_tenant_id;
  ELSE
    -- NO AUTO-ROUTE, return null (show directory)
    RETURN QUERY
    SELECT
      FALSE as should_auto_route,
      NULL::UUID as provider_tenant_id,
      NULL::TEXT as provider_name;
  END IF;
END;
$$ LANGUAGE plpgsql STABLE;

-- =============================================================================
-- PART 4: UPDATE COMMISSION CALCULATION TO CHECK SELF-PROVIDER
-- =============================================================================

-- This function is called by Edge Function to determine commission split
CREATE OR REPLACE FUNCTION calculate_commission_with_provider_check(
  p_transaction_type TEXT,
  p_base_price DECIMAL(12,2),
  p_provider_tenant_id UUID,
  p_referring_tenant_id UUID
) RETURNS TABLE (
  customer_pays DECIMAL(12,2),
  provider_gets DECIMAL(12,2),
  referrer_gets DECIMAL(12,2),
  platform_gets DECIMAL(12,2),
  is_self_provider BOOLEAN,
  has_referrer BOOLEAN
) AS $$
DECLARE
  is_self BOOLEAN;
  has_ref BOOLEAN;
  calc RECORD;
BEGIN
  -- Check if provider is same as referrer
  is_self := (p_provider_tenant_id = p_referring_tenant_id);

  -- Determine if there's a genuine referrer
  has_ref := (p_referring_tenant_id IS NOT NULL AND NOT is_self);

  -- Calculate commission based on transaction type
  IF p_transaction_type IN ('consultation', 'diagnostic_test') THEN
    -- Service commission
    SELECT * INTO calc FROM calculate_service_commission(p_base_price, has_ref);
  ELSIF p_transaction_type = 'product_sale' THEN
    -- Product commission
    SELECT * INTO calc FROM calculate_product_commission(p_base_price, has_ref);
  ELSE
    RAISE EXCEPTION 'Invalid transaction type: %', p_transaction_type;
  END IF;

  -- Return results with provider check flags
  RETURN QUERY SELECT
    calc.customer_pays,
    calc.provider_gets,
    calc.referrer_gets,
    calc.platform_gets,
    is_self,
    has_ref;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- =============================================================================
-- PART 5: COMMENTS
-- =============================================================================

COMMENT ON COLUMN tenants.services_offered IS 'Array of services this tenant provides: pharmacy, diagnostic, consultation';
COMMENT ON FUNCTION tenant_offers_service IS 'Check if a tenant offers a specific service type';
COMMENT ON FUNCTION get_service_provider IS 'Determines if service should auto-route to referring tenant or show directory';
COMMENT ON FUNCTION calculate_commission_with_provider_check IS 'Calculates commission with self-provider check for automatic routing';

-- =============================================================================
-- PART 6: EXAMPLE DATA (for reference)
-- =============================================================================

-- Example: Fokz Pharmacy with both pharmacy and diagnostic services
-- UPDATE tenants
-- SET services_offered = ARRAY['pharmacy', 'diagnostic']
-- WHERE subdomain = 'fokz';

-- Example: Medic Clinic with only consultation services
-- UPDATE tenants
-- SET services_offered = ARRAY['consultation']
-- WHERE subdomain = 'medic';

-- Example: CareLab with only diagnostic services
-- UPDATE tenants
-- SET services_offered = ARRAY['diagnostic']
-- WHERE subdomain = 'carelab';
