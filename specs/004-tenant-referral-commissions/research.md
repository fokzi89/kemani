# Technical Research: Multi-Tenant Referral Commission System

**Feature**: Multi-Tenant Referral Commission System
**Branch**: `004-tenant-referral-commissions`
**Research Date**: 2026-03-13

## Overview

This document consolidates technical research and decisions for implementing the multi-tenant referral commission system. Each decision includes rationale, alternatives considered, and implementation guidance. Many foundational decisions leverage research from the existing multi-tenant POS platform (see `specs/001-multi-tenant-pos/research.md`).

---

## 1. Session Tracking Strategy

### Decision: HTTP-only Cookie + Server-side Session Management

**Rationale**:
- **Security**: HTTP-only cookies prevent JavaScript access, protecting against XSS attacks on referral session hijacking
- **Subdomain-based attribution**: SvelteKit hooks can extract referring tenant from subdomain (e.g., `fokz.kemani.com` → tenant ID)
- **Server-authoritative**: Session validation happens on server, client cannot forge referrer
- **Persistent across navigation**: Cookie survives page reloads within same browser session
- **Supabase integration**: Session token can be correlated with Supabase auth session for logged-in users

**Implementation**:
- `hooks.server.ts` extracts subdomain and tenant ID on every request
- Set secure, HTTP-only cookie `referral_session_id` with 24-hour expiry
- Store session in `referral_sessions` table: `{ session_id, customer_id, referring_tenant_id, created_at, active }`
- On checkout, look up active session to determine referrer for commission attribution

**Alternatives Considered**:
- **localStorage**: Client-side JavaScript can manipulate, security risk
- **URL parameters**: Ugly UX (`?ref=fokz`), easy to lose on navigation, can be stripped
- **First-touch attribution in database**: Violates session-based requirement (need dynamic attribution per visit)
- **IP-based tracking**: Inaccurate (shared IPs, VPNs), privacy concerns

---

## 2. Commission Calculation Architecture

### Decision: PostgreSQL Functions + Supabase Edge Functions

**Rationale**:
- **Accuracy guarantee**: Server-side calculation ensures 100% accuracy requirement (SC-002)
- **Single source of truth**: PostgreSQL functions prevent client/server calculation drift
- **Performance**: Database functions execute in < 10ms, well under 100ms requirement
- **Type safety**: TypeScript types generated from database schema
- **Audit trail**: All calculations logged with input parameters for debugging
- **Currency precision**: Use `DECIMAL(12,2)` for amounts to avoid floating-point errors

**Implementation**:
```sql
CREATE FUNCTION calculate_service_commission(
  base_price DECIMAL(12,2),
  has_referrer BOOLEAN
) RETURNS TABLE (
  customer_pays DECIMAL(12,2),
  provider_gets DECIMAL(12,2),
  referrer_gets DECIMAL(12,2),
  platform_gets DECIMAL(12,2)
) AS $$
BEGIN
  IF has_referrer THEN
    RETURN QUERY SELECT
      base_price * 1.10,  -- customer_pays
      base_price * 0.90,  -- provider_gets
      base_price * 0.10,  -- referrer_gets
      base_price * 0.10;  -- platform_gets
  ELSE
    RETURN QUERY SELECT
      base_price * 1.10,  -- customer_pays
      base_price * 0.90,  -- provider_gets
      0::DECIMAL(12,2),   -- referrer_gets (no referrer)
      base_price * 0.20;  -- platform_gets (double)
  END IF;
END;
$$ LANGUAGE plpgsql IMMUTABLE;
```

**Alternatives Considered**:
- **Client-side calculation**: Cannot guarantee accuracy, user can manipulate
- **Application-level (SvelteKit)**: Requires duplication for Flutter app, drift risk
- **Hardcoded percentages in application**: Changes require code deployment vs. database migration
- **Stripe/Paystack Connect**: Adds third-party dependency, commission structure doesn't map cleanly

---

## 3. Fulfillment Routing Logic

### Decision: Database Trigger + Conditional Routing Table

**Rationale**:
- **Automatic**: Prescription/test creation automatically checks for pharmacy/lab referrer
- **Guaranteed routing**: Referring pharmacy/lab always gets first fulfillment opportunity
- **Fallback**: If referrer is not pharmacy/lab, show directory (requirement FR-008, FR-009)
- **Auditable**: Routing decisions logged in `fulfillment_routing` table
- **Performance**: Trigger executes in database, no network round-trip

**Implementation**:
```sql
CREATE TABLE fulfillment_routing (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  prescription_id UUID REFERENCES prescriptions(id),
  test_request_id UUID REFERENCES test_requests(id),
  fulfilling_tenant_id UUID REFERENCES tenants(id),
  routing_reason TEXT, -- 'pharmacy_referrer', 'diagnostic_referrer', 'customer_selected'
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE FUNCTION route_prescription_to_referrer()
RETURNS TRIGGER AS $$
DECLARE
  referrer_tenant_id UUID;
  referrer_type TEXT;
BEGIN
  -- Get referring tenant type from session
  SELECT rs.referring_tenant_id, t.tenant_type
  INTO referrer_tenant_id, referrer_type
  FROM referral_sessions rs
  JOIN tenants t ON t.id = rs.referring_tenant_id
  WHERE rs.customer_id = NEW.customer_id AND rs.active = TRUE
  LIMIT 1;

  -- Auto-route if referrer is pharmacy
  IF referrer_type = 'pharmacy' THEN
    NEW.fulfilling_pharmacy_id := referrer_tenant_id;
    INSERT INTO fulfillment_routing (prescription_id, fulfilling_tenant_id, routing_reason)
    VALUES (NEW.id, referrer_tenant_id, 'pharmacy_referrer');
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER prescription_auto_route
BEFORE INSERT ON prescriptions
FOR EACH ROW EXECUTE FUNCTION route_prescription_to_referrer();
```

**Alternatives Considered**:
- **Application-level routing**: Slower, requires explicit calls from frontend
- **Always show directory**: Violates guaranteed fulfillment requirement (FR-006, FR-007)
- **Manual assignment**: Extra friction for customer, defeats purpose of automatic routing

---

## 4. Commission Status Lifecycle

### Decision: State Machine with PostgreSQL Enum + Audit Log

**Rationale**:
- **Clear states**: `pending → processed → paid_out` with valid transitions enforced
- **Audit trail**: Every state change logged with timestamp and actor
- **Query performance**: Enum type is indexed, fast filtering for dashboard
- **Data integrity**: Check constraints prevent invalid state transitions
- **Payment reconciliation**: Can match `paid_out` records to bank transfers

**Implementation**:
```sql
CREATE TYPE commission_status AS ENUM ('pending', 'processed', 'paid_out');

CREATE TABLE commissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  transaction_id UUID NOT NULL,
  transaction_type VARCHAR(50) NOT NULL,

  provider_tenant_id UUID NOT NULL REFERENCES tenants(id),
  referrer_tenant_id UUID REFERENCES tenants(id),
  customer_id UUID NOT NULL,

  base_amount DECIMAL(12,2) NOT NULL,
  customer_paid DECIMAL(12,2) NOT NULL,
  provider_amount DECIMAL(12,2) NOT NULL,
  referrer_amount DECIMAL(12,2),
  platform_amount DECIMAL(12,2) NOT NULL,

  status commission_status DEFAULT 'pending',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  processed_at TIMESTAMPTZ,
  paid_at TIMESTAMPTZ,

  CONSTRAINT valid_state_timestamps CHECK (
    (status = 'pending' AND processed_at IS NULL AND paid_at IS NULL) OR
    (status = 'processed' AND processed_at IS NOT NULL AND paid_at IS NULL) OR
    (status = 'paid_out' AND processed_at IS NOT NULL AND paid_at IS NOT NULL)
  )
);

CREATE INDEX idx_commissions_tenant_status ON commissions(referrer_tenant_id, status, created_at);
```

**Alternatives Considered**:
- **Boolean flags**: `is_processed`, `is_paid` → error-prone, no transition validation
- **String status**: Typos possible, no compile-time safety
- **Timestamp-only**: Ambiguous states (is NULL pending or error?)

---

## 5. Multi-Service Commission Tracking

### Decision: Transaction Group ID + Referral Session Linkage

**Rationale**:
- **Single session, multiple transactions**: One checkout can include consultation + drugs + test
- **Consistent referrer**: All transactions in session attribute to same referrer (requirement FR-005)
- **Atomic commission calculation**: Calculate all commissions in single database transaction
- **Audit trail**: Group ID allows querying all transactions from one customer session

**Implementation**:
```sql
CREATE TABLE transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id UUID NOT NULL, -- Links transactions from same checkout
  type VARCHAR(50) NOT NULL, -- 'consultation', 'product_sale', 'diagnostic_test'

  provider_tenant_id UUID NOT NULL REFERENCES tenants(id),
  customer_id UUID NOT NULL,
  referring_tenant_id UUID REFERENCES tenants(id),

  base_price DECIMAL(12,2) NOT NULL,
  final_price_paid DECIMAL(12,2) NOT NULL,
  payment_status VARCHAR(20) NOT NULL,

  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- On checkout, create all transactions with same group_id
-- Calculate commissions for all transactions in single pass
CREATE FUNCTION process_transaction_group(group_id UUID)
RETURNS SETOF commissions AS $$
  -- For each transaction in group, calculate commission and insert into commissions table
$$ LANGUAGE plpgsql;
```

**Alternatives Considered**:
- **One transaction per service**: Lost relationship between checkout items
- **Nested JSON in single transaction**: Hard to query, violates normalization
- **Separate commission per transaction**: Works but loses grouping for analytics

---

## 6. Offline Commission Dashboard (FlutterFlow POS)

### Decision: FlutterFlow Local State + Supabase Offline Support + App State Variables

**Rationale**:
- **Offline-first**: Tenant can view commissions even without internet (requirement: offline-capable)
- **FlutterFlow pattern**: Use App State variables for caching + Supabase Flutter SDK built-in offline support
- **No custom code needed**: FlutterFlow handles offline data persistence automatically with App State
- **Sync strategy**: Background sync when connection restored via FlutterFlow's Supabase integration, conflict-free (commissions are read-only from tenant perspective)
- **Performance**: FlutterFlow caches Supabase query results automatically

**Implementation**:
```
FlutterFlow Implementation:
1. Create Data Type "CommissionRecord" with fields:
   - id (String)
   - transactionType (String)
   - amount (Double)
   - createdAt (DateTime)
   - status (String)
   - paidAt (DateTime, nullable)

2. Create App State variable "cachedCommissions" (List<CommissionRecord>)

3. Create Custom Action "syncCommissions":
   - Query Supabase commissions table
   - Filter by referrer_tenant_id = current tenant
   - Store results in cachedCommissions App State
   - Set lastSyncTimestamp App State

4. Commission Dashboard Page:
   - On page load: Check internet connection
   - If online: Run syncCommissions action, display live data
   - If offline: Display cachedCommissions from App State
   - Show "Offline Mode" indicator when no connection

5. Background sync:
   - Use FlutterFlow's onResume trigger
   - Check connection, sync if online
```

**Alternatives Considered**:
- **Hive local storage**: Requires custom Dart code, not FlutterFlow-native
- **Always online**: Violates offline requirement, poor UX in low-connectivity areas
- **SQLite**: Requires custom code, FlutterFlow doesn't have built-in SQLite support
- **SharedPreferences**: FlutterFlow App State abstracts this, no need for manual implementation

---

## 7. Commission Dashboard Analytics

### Decision: Pre-aggregated Views + fl_chart for Visualization (FlutterFlow)

**Rationale**:
- **Performance**: Pre-aggregated materialized views refresh nightly, fast dashboard loads
- **Common queries**: "Total earned this month", "Commission by transaction type"
- **Chart library**: fl_chart (FlutterFlow-compatible chart package for Flutter)
- **Real-time option**: Can query raw `commissions` table for up-to-the-minute data if needed
- **FlutterFlow integration**: fl_chart widgets can be added via FlutterFlow's custom widget system

**Implementation**:
```sql
CREATE MATERIALIZED VIEW commission_daily_summary AS
SELECT
  referrer_tenant_id,
  DATE(created_at) AS date,
  transaction_type,
  SUM(referrer_amount) AS total_earned,
  COUNT(*) AS transaction_count,
  status
FROM commissions
GROUP BY referrer_tenant_id, DATE(created_at), transaction_type, status;

CREATE UNIQUE INDEX ON commission_daily_summary (referrer_tenant_id, date, transaction_type, status);

-- Refresh nightly via cron job
REFRESH MATERIALIZED VIEW CONCURRENTLY commission_daily_summary;
```

**Alternatives Considered**:
- **Real-time aggregation**: Slow for tenants with thousands of transactions
- **Application-level caching**: Duplication between Flutter and SvelteKit
- **Third-party analytics (Mixpanel, etc.)**: Overkill, extra cost, data privacy concerns

---

## 8. RLS Policies for Commission Data

### Decision: Strict Tenant Isolation with Referrer/Provider Duality

**Rationale**:
- **Security**: Tenant can only see commissions where they are the referrer or provider
- **No cross-tenant leaks**: Constitutional requirement (Sec. VI)
- **Dual role**: A tenant can earn commissions (as referrer) and pay commissions (as provider)
- **Platform access**: Platform admin can see all commissions for reconciliation

**Implementation**:
```sql
-- Enable RLS
ALTER TABLE commissions ENABLE ROW LEVEL SECURITY;

-- Tenants see commissions where they are referrer (earning) or provider (paying)
CREATE POLICY tenant_commission_access ON commissions
FOR SELECT
USING (
  auth.jwt() ->> 'tenant_id' = referrer_tenant_id::TEXT OR
  auth.jwt() ->> 'tenant_id' = provider_tenant_id::TEXT OR
  auth.jwt() ->> 'role' = 'platform_admin'
);

-- Only platform can insert/update commission records (during payment processing)
CREATE POLICY platform_commission_write ON commissions
FOR ALL
USING (auth.jwt() ->> 'role' = 'platform_admin');
```

**Alternatives Considered**:
- **Application-level filtering**: Can be bypassed, not secure
- **Separate tables per tenant**: Doesn't scale, migration nightmare
- **View-based access**: Less performant than RLS, more complex

---

## 9. Commission Payment Distribution

### Decision: Supabase Edge Function + Payment Gateway Webhooks

**Rationale**:
- **Payment gateway integration**: Existing Paystack/Flutterwave integration handles split payments
- **Edge function**: Process payment webhook, calculate splits, distribute to tenant accounts
- **Async processing**: Webhook triggers edge function, doesn't block customer checkout
- **Idempotency**: Webhook replay protection via `transaction_id` uniqueness

**Implementation**:
```typescript
// supabase/functions/process-referral-payment/index.ts
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

serve(async (req) => {
  const { transaction_id, amount, customer_id } = await req.json();

  const supabase = createClient(/* credentials */);

  // Get active referral session
  const { data: session } = await supabase
    .from('referral_sessions')
    .select('referring_tenant_id, tenants(tenant_type)')
    .eq('customer_id', customer_id)
    .eq('active', true)
    .single();

  // Calculate commission
  const commission = await supabase.rpc('calculate_service_commission', {
    base_price: amount,
    has_referrer: !!session
  });

  // Create commission record
  await supabase.from('commissions').insert({
    transaction_id,
    provider_amount: commission.provider_gets,
    referrer_amount: commission.referrer_gets,
    platform_amount: commission.platform_gets,
    status: 'pending'
  });

  // Trigger payment split via Paystack API
  // ... (integrate with payment gateway)

  return new Response(JSON.stringify({ success: true }), { status: 200 });
});
```

**Alternatives Considered**:
- **Manual payout**: Not scalable, slow, error-prone
- **Batch processing**: Delayed commission availability, poor UX
- **Direct database writes from payment webhook**: Security risk (webhook signature validation in edge function)

---

## 10. Testing Strategy for Commission Accuracy

### Decision: Property-Based Testing + Integration Tests

**Rationale**:
- **Critical requirement**: 100% accuracy (SC-002) demands rigorous testing
- **Property-based tests**: Verify commission formulas hold for all inputs (e.g., `customer_pays = provider_gets + referrer_gets + platform_gets`)
- **Integration tests**: Full checkout flow with real database functions
- **Test scenarios**: All commission formulas (service/product, with/without referrer)

**Implementation**:
```typescript
// apps/storefront/tests/commission-calculation.test.ts
import { describe, it, expect } from 'vitest';
import { fc, test } from '@fast-check/vitest';

describe('Commission Calculations', () => {
  test.prop([fc.float({ min: 100, max: 100000 })])('Service commission totals match customer payment', async (basePrice) => {
    const commission = await calculateServiceCommission(basePrice, true);

    const total = commission.provider_gets + commission.referrer_gets + commission.platform_gets;

    expect(total).toBeCloseTo(commission.customer_pays, 2); // Within 0.01 due to rounding
  });

  it('Consultation with referrer: ₦1000 base → ₦1100 customer pays, ₦900/₦100/₦100 split', async () => {
    const commission = await calculateServiceCommission(1000, true);

    expect(commission.customer_pays).toBe(1100);
    expect(commission.provider_gets).toBe(900);
    expect(commission.referrer_gets).toBe(100);
    expect(commission.platform_gets).toBe(100);
  });

  // ... more test cases for all scenarios
});
```

**Alternatives Considered**:
- **Manual testing**: Error-prone, doesn't scale, misses edge cases
- **Unit tests only**: Doesn't catch integration issues (e.g., RLS policy blocking commission writes)
- **Snapshot testing**: Not appropriate for numerical calculations

---

## Summary of Key Decisions

| Area | Decision | Key Rationale |
|------|----------|---------------|
| Session Tracking | HTTP-only cookie + server session | Security, subdomain-based attribution, server-authoritative |
| Commission Calculation | PostgreSQL functions | 100% accuracy guarantee, single source of truth, < 100ms |
| Fulfillment Routing | Database trigger + routing table | Automatic, guaranteed routing, auditable |
| Commission Status | Enum state machine + audit log | Clear transitions, queryable, payment reconciliation |
| Multi-Service Tracking | Transaction group ID | Single session attribution, audit trail |
| Offline Dashboard | FlutterFlow App State + Supabase offline | Offline-first, FlutterFlow-native, no custom code |
| Analytics | Pre-aggregated materialized views | Performance, common queries, fl_chart integration |
| Data Security | RLS policies (tenant isolation) | Constitutional requirement, dual role support |
| Payment Distribution | Edge function + webhook | Async processing, idempotency, payment gateway integration |
| Testing | Property-based + integration | Critical accuracy requirement, full coverage |

---

**All technical decisions finalized. Ready for Phase 1: Data Model & Contracts.**
