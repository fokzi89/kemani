# Automatic Routing & Self-Provider Logic

**Feature**: 004-tenant-referral-commissions
**User Story 4**: Guaranteed Fulfillment Routing
**Priority**: P2
**Status**: ✅ Implementation Complete

## Overview

This document explains the **automatic service routing** and **self-provider commission** logic that determines:
1. When customers are auto-routed to referring tenant's services
2. When external service directories are shown
3. How commissions are calculated for self-provider vs external provider scenarios

## Business Rules

### Rule 1: One Subdomain, Multiple Services

A single subdomain can represent multiple service types for the same tenant.

**Example:**
- `fokz.kemani.com` → Fokz Pharmacy (tenant_id: `fokz-uuid-123`)
  - Offers: Pharmacy + Diagnostic services
  - Both services share same subdomain
  - Both services have same `tenant_id`

**Implementation:**
```sql
-- Tenants table
CREATE TABLE tenants (
  id UUID PRIMARY KEY,
  subdomain VARCHAR(255) UNIQUE,
  services_offered TEXT[] DEFAULT ARRAY[]::TEXT[],
  -- services_offered can contain: ['pharmacy', 'diagnostic', 'consultation']
  ...
);

-- Example data
INSERT INTO tenants (id, subdomain, services_offered)
VALUES (
  'fokz-uuid-123',
  'fokz',
  ARRAY['pharmacy', 'diagnostic']
);
```

### Rule 2: Automatic Routing Logic

When a customer requests a service, the system checks if the **referring tenant** offers that service:

**IF** referring tenant offers service:
- ✅ **AUTO-ROUTE** to referring tenant
- ❌ **DO NOT** show external directory
- ℹ️ Customer sees notification about auto-routing

**IF** referring tenant does **NOT** offer service:
- ❌ **DO NOT** auto-route
- ✅ **SHOW** external service directory
- ℹ️ Customer can select from available external providers

**Decision Flow:**
```
Customer on fokz.kemani.com wants diagnostic test
  ↓
Check: Does Fokz Pharmacy offer 'diagnostic' service?
  ↓
YES → Auto-route to Fokz Diagnostics (no directory)
NO  → Show directory of external diagnostic centers
```

**Implementation:**
```typescript
const routing = await ServiceRouter.getServiceProvider(
  'fokz-uuid-123',  // referring tenant
  'diagnostic'      // requested service
);

if (routing.shouldAutoRoute) {
  // Navigate to fokz.kemani.com/diagnostics
  redirectToProvider(routing.providerTenantId);
} else {
  // Show external directory
  showServiceDirectory('diagnostic');
}
```

### Rule 3: Self-Provider Commission (No Referral)

When `provider_tenant_id === referring_tenant_id`, it's a **self-provider scenario**.

**Commission Rules:**
- ❌ **NO** referral commission awarded
- ✅ Provider gets provider share
- ✅ Platform gets **both** referrer share + platform share

**Why?**
A tenant cannot earn referral commission by referring customers to themselves. The platform captures the referral commission since no external referral occurred.

**Example 1: Fokz selling own pharmacy products**
```typescript
// Scenario
customer: "John Doe"
subdomain: "fokz.kemani.com"
service: "pharmacy"
provider: Fokz Pharmacy (fokz-uuid-123)
referrer: Fokz Pharmacy (fokz-uuid-123)  // ← SAME tenant

// Commission Calculation
base_price: ₦5,000
is_self_provider: TRUE

// Formula (Product, No Referrer)
customer_pays: ₦5,000 (no markup for products)
provider_gets: ₦4,700 (94%)
referrer_gets: ₦0     (self-provider, no commission)
platform_gets: ₦300   (6% = 4.5% referrer share + 1.5% platform share)

// Total: ₦5,000 ✓
```

**Example 2: Fokz offering own diagnostic tests**
```typescript
// Scenario
subdomain: "fokz.kemani.com"
service: "diagnostic_test"
provider: Fokz Diagnostics (fokz-uuid-123)
referrer: Fokz Pharmacy (fokz-uuid-123)  // ← SAME tenant

// Commission Calculation
base_price: ₦5,000
is_self_provider: TRUE

// Formula (Service, No Referrer)
markup: 10%
customer_pays: ₦5,500 (₦5,000 × 1.10)
provider_gets: ₦4,950 (90% of ₦5,500)
referrer_gets: ₦0     (self-provider, no commission)
platform_gets: ₦550   (10% of ₦5,500 = 10% referrer share + 10% platform share combined)

// Total: ₦5,500 ✓
```

### Rule 4: External Provider Commission (With Referral)

When `provider_tenant_id ≠ referring_tenant_id`, it's an **external provider scenario**.

**Commission Rules:**
- ✅ **YES** referral commission awarded
- ✅ Provider gets provider share
- ✅ Referrer gets referral commission
- ✅ Platform gets platform share

**Example: Fokz referring to external doctor**
```typescript
// Scenario
subdomain: "fokz.kemani.com"
service: "consultation"
provider: Dr. Kome (doctor-uuid-456)
referrer: Fokz Pharmacy (fokz-uuid-123)  // ← DIFFERENT tenant

// Commission Calculation
base_price: ₦1,000
is_self_provider: FALSE

// Formula (Service, With Referrer)
markup: 10%
customer_pays: ₦1,100 (₦1,000 × 1.10)
provider_gets: ₦990   (90% of ₦1,100)
referrer_gets: ₦110   (10% of ₦1,100) ← Fokz earns this!
platform_gets: ₦110   (10% of ₦1,100)

// Total: ₦1,210 (customer pays ₦1,100, platform + referrer get ₦220 markup)
```

### Rule 5: Multi-Service Cart with Mixed Scenarios

A single checkout can include **both** self-provider and external provider items.

**Example: Complex Cart**
```typescript
// Customer on fokz.kemani.com buys:
const cart = [
  {
    type: 'product_sale',
    base: 5000,
    provider: 'fokz-uuid-123',  // Fokz's own products
    referrer: 'fokz-uuid-123'   // Self-provider
  },
  {
    type: 'consultation',
    base: 1000,
    provider: 'doctor-uuid-456', // External doctor
    referrer: 'fokz-uuid-123'    // Referral applies
  },
  {
    type: 'diagnostic_test',
    base: 5000,
    provider: 'fokz-uuid-123',  // Fokz's own diagnostics
    referrer: 'fokz-uuid-123'   // Self-provider
  }
];

// Item 1: Product (Self-Provider)
customer_pays: ₦5,000
provider_gets: ₦4,700
referrer_gets: ₦0       // Self
platform_gets: ₦300

// Item 2: Consultation (External)
customer_pays: ₦1,100
provider_gets: ₦990
referrer_gets: ₦110     // ← Fokz earns referral commission!
platform_gets: ₦110

// Item 3: Diagnostic (Self-Provider)
customer_pays: ₦5,500
provider_gets: ₦4,950
referrer_gets: ₦0       // Self
platform_gets: ₦550

// TOTALS
Total customer pays: ₦11,600
Fokz earns: ₦4,700 (product) + ₦110 (referral) + ₦4,950 (diagnostic) = ₦9,760
Platform earns: ₦300 + ₦110 + ₦550 = ₦960
Doctor earns: ₦990
```

**Key Insight:**
Fokz earns **₦110 referral commission** on the external consultation, even though they don't earn referral commission on their own products/services.

### Rule 6: Branch Management (Same Tenant ID)

All branches of the same tenant share one `tenant_id`.

**Example:**
```
Fokz Pharmacy
├─ Fokz Pharmacy (Lekki Branch)
├─ Fokz Pharmacy (VI Branch)
└─ Fokz Diagnostics (Lekki Branch)

All branches: tenant_id = 'fokz-uuid-123'
```

**Commission Rule:**
- ❌ **NO** referral commission between branches
- All inter-branch transactions are **self-provider** scenarios

**Why?**
Branches are not separate entities. They're all part of the same tenant organization.

### Rule 7: No Marketplace (Tenant-Only Products)

Customers can **only** see products/services from the referring tenant's branches.

**What this means:**
- ❌ Customer on `fokz.kemani.com` **CANNOT** see products from other pharmacies
- ✅ Customer **CAN** see other Fokz branches
- ✅ Customer **CAN** see external services (doctors, labs) when Fokz doesn't offer them

**Product Flow:**
```
Customer on fokz.kemani.com
  ↓
Wants to buy drugs
  ↓
Sees ONLY: Fokz Pharmacy branches (Lekki, VI, etc.)
  ↓
If drug unavailable in all branches:
  → Fokz pharmacy manually sources drug
  → Platform admin can help find drug
  → NO other pharmacies shown to customer
```

**Service Flow:**
```
Customer on fokz.kemani.com
  ↓
Wants consultation
  ↓
Fokz does NOT offer consultation
  ↓
Show directory of doctors (external providers)
  ↓
Customer selects doctor
  ↓
Fokz earns referral commission
```

## Database Schema

### Tenants Table
```sql
CREATE TABLE tenants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL,
  subdomain VARCHAR(255) UNIQUE NOT NULL,
  business_type VARCHAR(100),
  city VARCHAR(100),
  address TEXT,

  -- NEW: Services offered by tenant
  services_offered TEXT[] DEFAULT ARRAY[]::TEXT[],
  -- Valid values: ['pharmacy', 'diagnostic', 'consultation']

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  -- Constraint: Only allow valid service types
  CONSTRAINT valid_service_types CHECK (
    services_offered <@ ARRAY['pharmacy', 'diagnostic', 'consultation']::TEXT[]
  )
);

-- Index for fast service lookups
CREATE INDEX idx_tenants_services ON tenants USING GIN (services_offered);
```

### Helper Functions

**Check if tenant offers service:**
```sql
CREATE OR REPLACE FUNCTION tenant_offers_service(
  p_tenant_id UUID,
  p_service_type TEXT
) RETURNS BOOLEAN AS $$
DECLARE
  services TEXT[];
BEGIN
  SELECT services_offered INTO services
  FROM tenants WHERE id = p_tenant_id;

  RETURN p_service_type = ANY(services);
END;
$$ LANGUAGE plpgsql STABLE;

-- Usage
SELECT tenant_offers_service('fokz-uuid-123', 'pharmacy');
-- Returns: TRUE (if Fokz offers pharmacy)
```

**Get service provider (routing logic):**
```sql
CREATE OR REPLACE FUNCTION get_service_provider(
  p_referring_tenant_id UUID,
  p_service_type TEXT
) RETURNS TABLE (
  should_auto_route BOOLEAN,
  provider_tenant_id UUID,
  provider_name TEXT
) AS $$
BEGIN
  IF tenant_offers_service(p_referring_tenant_id, p_service_type) THEN
    -- AUTO-ROUTE to referring tenant
    RETURN QUERY
    SELECT TRUE, t.id, t.name
    FROM tenants t WHERE t.id = p_referring_tenant_id;
  ELSE
    -- NO AUTO-ROUTE, show directory
    RETURN QUERY
    SELECT FALSE, NULL::UUID, NULL::TEXT;
  END IF;
END;
$$ LANGUAGE plpgsql STABLE;

-- Usage
SELECT * FROM get_service_provider('fokz-uuid-123', 'diagnostic');
-- Returns: (TRUE, 'fokz-uuid-123', 'Fokz Pharmacy') if they offer diagnostic
-- Returns: (FALSE, NULL, NULL) if they don't offer diagnostic
```

**Commission calculation with self-provider check:**
```sql
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
    SELECT * INTO calc FROM calculate_service_commission(p_base_price, has_ref);
  ELSIF p_transaction_type = 'product_sale' THEN
    SELECT * INTO calc FROM calculate_product_commission(p_base_price, has_ref);
  END IF;

  RETURN QUERY SELECT
    calc.customer_pays,
    calc.provider_gets,
    calc.referrer_gets,
    calc.platform_gets,
    is_self,
    has_ref;
END;
$$ LANGUAGE plpgsql IMMUTABLE;
```

## TypeScript Services

### ServiceRouter Service

**File:** `apps/storefront/src/lib/services/serviceRouter.ts`

**Key Methods:**

```typescript
// Check if tenant offers service
const canProvide = await ServiceRouter.checkTenantOffersService(
  'fokz-uuid-123',
  'pharmacy'
);
// Returns: true/false

// Get routing decision
const routing = await ServiceRouter.getServiceProvider(
  'fokz-uuid-123',  // referring tenant
  'diagnostic'      // requested service
);
// Returns: { shouldAutoRoute, providerTenantId, providerName, showDirectory }

// Check if self-provider
const isSelf = ServiceRouter.isSelfProvider(
  'fokz-uuid-123',  // provider
  'fokz-uuid-123'   // referrer
);
// Returns: true (same tenant)

// Check if referral commission applies
const shouldAward = ServiceRouter.shouldAwardReferralCommission(
  'doctor-uuid-456',  // provider
  'fokz-uuid-123'     // referrer
);
// Returns: true (different tenants)
```

## UI Components

### ServiceSelector

**File:** `apps/storefront/src/lib/components/referral/ServiceSelector.svelte`

**Usage:**
```svelte
<script>
  import ServiceSelector from '$lib/components/referral/ServiceSelector.svelte';
  import { page } from '$app/stores';
</script>

<ServiceSelector
  serviceType="diagnostic"
  referringTenantId={$page.data.referringTenantId}
  autoNavigate={true}
  showNotification={true}
/>
```

**Features:**
- Auto-routes when tenant offers service
- Shows directory when tenant doesn't offer service
- Dispatches events for parent components
- Handles loading and error states

### AutoRouteNotification

**File:** `apps/storefront/src/lib/components/referral/AutoRouteNotification.svelte`

**Usage:**
```svelte
<AutoRouteNotification
  serviceType="pharmacy"
  providerName="Fokz Pharmacy"
  autoDismiss={true}
  dismissDelay={5000}
/>
```

**Features:**
- Beautiful gradient notification
- Auto-dismisses after 5 seconds
- Explains auto-routing to customer

### ServiceDirectory

**File:** `apps/storefront/src/lib/components/referral/ServiceDirectory.svelte`

**Usage:**
```svelte
<ServiceDirectory
  serviceType="consultation"
  referringTenantId={referringTenantId}
  city="Lagos"
/>
```

**Features:**
- Displays external service providers
- Filters by city (optional)
- Excludes referring tenant (they don't offer this service)
- Dispatches provider selection events

## Edge Function Updates

**File:** `supabase/functions/process-referral-payment/index.ts`

**Key Changes:**
- Uses `calculate_commission_with_provider_check()` function
- Includes `is_self_provider` and `has_referrer` in response
- Handles both self-provider and external provider scenarios

**Response Example (Self-Provider):**
```json
{
  "success": true,
  "breakdown": {
    "customer_paid": 5000,
    "provider_gets": 4700,
    "referrer_gets": 0,
    "platform_gets": 300,
    "has_referrer": false,
    "is_self_provider": true,
    "referring_tenant_id": "fokz-uuid-123"
  }
}
```

**Response Example (External Provider):**
```json
{
  "success": true,
  "breakdown": {
    "customer_paid": 1100,
    "provider_gets": 990,
    "referrer_gets": 110,
    "platform_gets": 110,
    "has_referrer": true,
    "is_self_provider": false,
    "referring_tenant_id": "fokz-uuid-123"
  }
}
```

## Testing

**File:** `tests/automatic-routing-self-provider.spec.ts`

**Test Coverage:**
- T083: Auto-route when tenant offers service
- T084: Show directory when tenant doesn't offer service
- T085: Different subdomains offer different services
- T086: Self-provider commission calculation
- T087: External provider commission calculation
- T088: Multi-service cart with mixed scenarios
- T089: isSelfProvider unit test
- T090: shouldAwardReferralCommission unit test

**Run Tests:**
```bash
npx playwright test tests/automatic-routing-self-provider.spec.ts
```

## Integration Guide

### Step 1: Configure Tenant Services

```sql
-- Example: Fokz Pharmacy with pharmacy + diagnostic
UPDATE tenants
SET services_offered = ARRAY['pharmacy', 'diagnostic']
WHERE subdomain = 'fokz';

-- Example: Medic Clinic with consultation only
UPDATE tenants
SET services_offered = ARRAY['consultation']
WHERE subdomain = 'medic';
```

### Step 2: Add ServiceSelector to Pages

```svelte
<!-- apps/storefront/src/routes/diagnostics/+page.svelte -->
<script>
  import ServiceSelector from '$lib/components/referral/ServiceSelector.svelte';
  import ServiceDirectory from '$lib/components/referral/ServiceDirectory.svelte';
  import { page } from '$app/stores';

  let showDirectory = false;

  function handleShowDirectory() {
    showDirectory = true;
  }
</script>

<ServiceSelector
  serviceType="diagnostic"
  referringTenantId={$page.data.referringTenantId}
  on:showDirectory={handleShowDirectory}
>
  <svelte:fragment slot="directory">
    {#if showDirectory}
      <ServiceDirectory
        serviceType="diagnostic"
        referringTenantId={$page.data.referringTenantId}
      />
    {/if}
  </svelte:fragment>
</ServiceSelector>
```

### Step 3: Use ServiceRouter in Business Logic

```typescript
import { ServiceRouter } from '$lib/services/serviceRouter';

// In checkout flow
export async function createTransaction(
  serviceType: ServiceType,
  customerId: string,
  referringTenantId: string | null
) {
  // Determine provider
  const routing = await ServiceRouter.getServiceProvider(
    referringTenantId,
    serviceType
  );

  const providerTenantId = routing.shouldAutoRoute
    ? routing.providerTenantId  // Auto-routed
    : selectedProviderId;        // Customer selected from directory

  // Check if self-provider
  const isSelfProvider = ServiceRouter.isSelfProvider(
    providerTenantId,
    referringTenantId
  );

  // Create transaction with proper attribution
  await createTransactionRecord({
    type: serviceType,
    provider_tenant_id: providerTenantId,
    referring_tenant_id: isSelfProvider ? null : referringTenantId,
    // ...
  });
}
```

## Summary

**Key Business Rules:**
1. ✅ One subdomain = multiple service types
2. ✅ Auto-route when tenant offers service
3. ✅ Show directory when tenant doesn't offer service
4. ✅ Self-provider = no referral commission
5. ✅ External provider = referral commission applies
6. ✅ All branches = same tenant_id = self-provider
7. ✅ No marketplace = tenant-only products

**Implementation Complete:**
- ✅ Database migration with services_offered column
- ✅ ServiceRouter TypeScript service
- ✅ UI components (ServiceSelector, AutoRouteNotification, ServiceDirectory)
- ✅ Edge Function updated with self-provider check
- ✅ Comprehensive tests (8 test cases)
- ✅ Documentation with examples

**Next Steps:**
- Deploy migration to production
- Configure tenant services_offered data
- Update frontend pages to use ServiceSelector
- Monitor commission calculations in production
