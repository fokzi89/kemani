# Data Model: Multi-Tenant Referral Commission System

**Feature**: Multi-Tenant Referral Commission System
**Branch**: `004-tenant-referral-commissions`
**Created**: 2026-03-13

## Overview

This document defines the complete data model for the referral commission system, including all entities, fields, relationships, validation rules, and state transitions. All tables use Supabase PostgreSQL with Row Level Security (RLS) enabled for multi-tenant isolation.

---

## Entity Relationship Diagram

```
┌──────────────┐         ┌──────────────────────┐         ┌─────────────────┐
│   tenants    │◄────────│  referral_sessions   │────────►│    customers    │
└──────────────┘         └──────────────────────┘         └─────────────────┘
       ▲                           │                               │
       │                           │ referring_tenant_id           │
       │                           ▼                               │
       │                  ┌──────────────────┐                     │
       │                  │  transactions    │◄────────────────────┘
       │                  └──────────────────┘
       │                           │
       │                           │ provider_tenant_id
       │                           ▼
       ├──────────────────►┌──────────────────┐
       │                   │   commissions    │
       │                   └──────────────────┘
       │                           │
       │                           │ referrer_tenant_id
       └───────────────────────────┘

┌─────────────────┐         ┌────────────────────────┐
│  prescriptions  │────────►│  fulfillment_routing   │
└─────────────────┘         └────────────────────────┘
                                      │
┌─────────────────┐                   │
│  test_requests  │───────────────────┘
└─────────────────┘
```

---

## Core Entities

### 1. referral_sessions

**Purpose**: Tracks which tenant's page a customer is currently browsing (the referrer for commission attribution).

**Schema**:
```sql
CREATE TABLE referral_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_token VARCHAR(255) UNIQUE NOT NULL,      -- Secure random token stored in cookie
  customer_id UUID REFERENCES customers(id),        -- Nullable for anonymous browsing
  referring_tenant_id UUID NOT NULL REFERENCES tenants(id),

  active BOOLEAN DEFAULT TRUE,                      -- Session still valid
  created_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ DEFAULT NOW() + INTERVAL '24 hours',
  last_activity_at TIMESTAMPTZ DEFAULT NOW(),

  CONSTRAINT valid_expiry CHECK (expires_at > created_at)
);

CREATE INDEX idx_referral_sessions_token ON referral_sessions(session_token);
CREATE INDEX idx_referral_sessions_customer_active ON referral_sessions(customer_id, active);
```

**Fields**:
- `id`: Primary key (UUID)
- `session_token`: Secure random string (256-bit) stored in HTTP-only cookie
- `customer_id`: Foreign key to customer who is browsing (NULL if not logged in)
- `referring_tenant_id`: Which tenant's page they're on (e.g., Fokz Pharmacy)
- `active`: Boolean flag (TRUE = session still valid, FALSE = expired or ended)
- `created_at`: Session creation timestamp
- `expires_at`: Session expiration (24 hours from creation)
- `last_activity_at`: Last page view timestamp (updated on each request)

**Relationships**:
- `customer_id` → `customers.id` (nullable, one-to-many from customers)
- `referring_tenant_id` → `tenants.id` (required, many-to-one to tenants)

**Validation Rules**:
- Session token must be cryptographically secure random string (generated server-side)
- Expires_at must be after created_at
- Active sessions must have expires_at in the future
- Cannot have multiple active sessions for same customer with different referrers (session-based, not parallel)

**State Transitions**:
```
[Created] → active = TRUE
         ↓
[Customer navigates away or session expires] → active = FALSE
         ↓
[Garbage collection] → DELETE (after 30 days of inactivity)
```

**RLS Policy**:
```sql
-- Customers see their own sessions (read-only)
CREATE POLICY customer_session_read ON referral_sessions
FOR SELECT
USING (auth.uid() = customer_id::TEXT);

-- Platform can manage all sessions
CREATE POLICY platform_session_manage ON referral_sessions
FOR ALL
USING (auth.jwt() ->> 'role' = 'platform_admin');
```

---

### 2. transactions

**Purpose**: Records all customer purchases (consultations, product sales, diagnostic tests) with pricing and referral attribution.

**Schema**:
```sql
CREATE TABLE transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id UUID NOT NULL,                            -- Links transactions from same checkout
  type VARCHAR(50) NOT NULL,                         -- 'consultation', 'product_sale', 'diagnostic_test'

  provider_tenant_id UUID NOT NULL REFERENCES tenants(id),
  customer_id UUID NOT NULL REFERENCES customers(id),
  referring_tenant_id UUID REFERENCES tenants(id),   -- NULL if no referrer (direct access)

  base_price DECIMAL(12,2) NOT NULL,                 -- Provider's base price (before markup)
  final_price_paid DECIMAL(12,2) NOT NULL,           -- Total amount customer paid
  payment_status VARCHAR(20) NOT NULL DEFAULT 'pending',
  payment_reference VARCHAR(255),                    -- Paystack/Flutterwave transaction ref

  created_at TIMESTAMPTZ DEFAULT NOW(),
  paid_at TIMESTAMPTZ,

  CONSTRAINT valid_transaction_type CHECK (type IN ('consultation', 'product_sale', 'diagnostic_test')),
  CONSTRAINT valid_payment_status CHECK (payment_status IN ('pending', 'completed', 'failed', 'refunded')),
  CONSTRAINT positive_prices CHECK (base_price > 0 AND final_price_paid >= base_price)
);

CREATE INDEX idx_transactions_group ON transactions(group_id);
CREATE INDEX idx_transactions_provider_date ON transactions(provider_tenant_id, created_at DESC);
CREATE INDEX idx_transactions_customer_date ON transactions(customer_id, created_at DESC);
CREATE INDEX idx_transactions_referrer_date ON transactions(referring_tenant_id, created_at DESC) WHERE referring_tenant_id IS NOT NULL;
```

**Fields**:
- `id`: Primary key
- `group_id`: Groups multiple transactions from same checkout (e.g., consultation + drugs + test)
- `type`: Transaction type (consultation, product_sale, diagnostic_test)
- `provider_tenant_id`: Who provided the service/product
- `customer_id`: Who made the purchase
- `referring_tenant_id`: Which tenant referred this transaction (NULL if direct access)
- `base_price`: Provider's base price (₦1,000 for consultation, ₦5,000 for drugs, etc.)
- `final_price_paid`: Total customer paid (includes markup for services, no markup for products)
- `payment_status`: pending → completed → (refunded)
- `payment_reference`: Payment gateway transaction ID
- `created_at`: Transaction creation timestamp
- `paid_at`: Payment completion timestamp

**Relationships**:
- `provider_tenant_id` → `tenants.id` (required)
- `customer_id` → `customers.id` (required)
- `referring_tenant_id` → `tenants.id` (nullable)

**Validation Rules**:
- Type must be one of: `consultation`, `product_sale`, `diagnostic_test`
- Payment status must be: `pending`, `completed`, `failed`, `refunded`
- Base price and final price must be positive
- Final price >= base price (markup never negative)
- For services: `final_price_paid = base_price * 1.10`
- For products: `final_price_paid = base_price` (no markup) or `base_price + 100` (if no referrer)

**State Transitions**:
```
[Created] → payment_status = 'pending'
         ↓
[Payment processed] → payment_status = 'completed', paid_at = NOW()
         ↓
[Commission calculated] → Create commission record
         ↓
[Optional: Refunded] → payment_status = 'refunded', trigger commission clawback
```

**RLS Policy**:
```sql
-- Customers see their own transactions
CREATE POLICY customer_transaction_read ON transactions
FOR SELECT
USING (auth.uid() = customer_id::TEXT);

-- Providers see transactions they fulfilled
CREATE POLICY provider_transaction_read ON transactions
FOR SELECT
USING (auth.jwt() ->> 'tenant_id' = provider_tenant_id::TEXT);

-- Referrers see transactions they referred
CREATE POLICY referrer_transaction_read ON transactions
FOR SELECT
USING (auth.jwt() ->> 'tenant_id' = referring_tenant_id::TEXT);

-- Platform can manage all transactions
CREATE POLICY platform_transaction_manage ON transactions
FOR ALL
USING (auth.jwt() ->> 'role' = 'platform_admin');
```

---

### 3. commissions

**Purpose**: Records commission amounts earned/paid for each transaction with status tracking.

**Schema**:
```sql
CREATE TYPE commission_status AS ENUM ('pending', 'processed', 'paid_out');

CREATE TABLE commissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  transaction_id UUID NOT NULL REFERENCES transactions(id),
  transaction_type VARCHAR(50) NOT NULL,

  -- Parties involved
  provider_tenant_id UUID NOT NULL REFERENCES tenants(id),
  referrer_tenant_id UUID REFERENCES tenants(id),      -- NULL if no referrer
  customer_id UUID NOT NULL REFERENCES customers(id),

  -- Amounts (all in Naira, DECIMAL for precision)
  base_amount DECIMAL(12,2) NOT NULL,                  -- Base price before markup
  customer_paid DECIMAL(12,2) NOT NULL,                -- Total customer paid
  provider_amount DECIMAL(12,2) NOT NULL,              -- Amount provider receives
  referrer_amount DECIMAL(12,2),                       -- Amount referrer earns (NULL if no referrer)
  platform_amount DECIMAL(12,2) NOT NULL,              -- Amount platform keeps

  -- Lifecycle
  status commission_status DEFAULT 'pending',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  processed_at TIMESTAMPTZ,                            -- When commission calculated
  paid_at TIMESTAMPTZ,                                 -- When commission paid to tenant

  -- Audit
  calculation_metadata JSONB,                          -- Store formula used, rates applied

  CONSTRAINT commission_totals_balance CHECK (
    ABS((provider_amount + COALESCE(referrer_amount, 0) + platform_amount) - customer_paid) < 0.01
  ),
  CONSTRAINT valid_state_timestamps CHECK (
    (status = 'pending' AND processed_at IS NULL AND paid_at IS NULL) OR
    (status = 'processed' AND processed_at IS NOT NULL AND paid_at IS NULL) OR
    (status = 'paid_out' AND processed_at IS NOT NULL AND paid_at IS NOT NULL)
  )
);

CREATE UNIQUE INDEX idx_commissions_transaction ON commissions(transaction_id);
CREATE INDEX idx_commissions_referrer_status_date ON commissions(referrer_tenant_id, status, created_at DESC) WHERE referrer_tenant_id IS NOT NULL;
CREATE INDEX idx_commissions_provider_date ON commissions(provider_tenant_id, created_at DESC);
```

**Fields**:
- `id`: Primary key
- `transaction_id`: Foreign key to transaction this commission is for
- `transaction_type`: Type (consultation, product_sale, diagnostic_test)
- `provider_tenant_id`: Who provided the service/product
- `referrer_tenant_id`: Who referred the customer (NULL if direct)
- `customer_id`: Who made the purchase
- `base_amount`: Base price (₦1,000, ₦5,000, etc.)
- `customer_paid`: Total customer paid (₦1,100, ₦5,500, etc.)
- `provider_amount`: What provider receives (₦900, ₦4,500, ₦4,700, etc.)
- `referrer_amount`: What referrer earns (₦100, ₦500, ₦225, etc., NULL if no referrer)
- `platform_amount`: What platform keeps (₦100, ₦500, ₦75, etc.)
- `status`: pending → processed → paid_out
- `created_at`: Commission record creation
- `processed_at`: When commission calculation finalized
- `paid_at`: When tenant received payout
- `calculation_metadata`: JSON with formula used, rates, for audit trail

**Relationships**:
- `transaction_id` → `transactions.id` (required, one-to-one)
- `provider_tenant_id` → `tenants.id` (required)
- `referrer_tenant_id` → `tenants.id` (nullable)
- `customer_id` → `customers.id` (required)

**Validation Rules**:
- Commission amounts must balance: `provider_amount + referrer_amount + platform_amount = customer_paid` (within 0.01 for rounding)
- State timestamps must match status:
  - `pending`: Both processed_at and paid_at are NULL
  - `processed`: processed_at set, paid_at NULL
  - `paid_out`: Both timestamps set
- Referrer amount NULL if and only if referrer_tenant_id is NULL

**State Transitions**:
```
[Transaction completed] → status = 'pending', created_at = NOW()
         ↓
[Commission calculated] → status = 'processed', processed_at = NOW()
         ↓
[Payment distributed] → status = 'paid_out', paid_at = NOW()
```

**RLS Policy**:
```sql
-- Tenants see commissions where they are referrer (earning) or provider (paying)
CREATE POLICY tenant_commission_access ON commissions
FOR SELECT
USING (
  auth.jwt() ->> 'tenant_id' = referrer_tenant_id::TEXT OR
  auth.jwt() ->> 'tenant_id' = provider_tenant_id::TEXT OR
  auth.jwt() ->> 'role' = 'platform_admin'
);

-- Only platform can insert/update commissions
CREATE POLICY platform_commission_write ON commissions
FOR ALL
USING (auth.jwt() ->> 'role' = 'platform_admin');
```

---

### 4. fulfillment_routing

**Purpose**: Tracks automatic routing of prescriptions and test requests to referring pharmacies/diagnostic centers.

**Schema**:
```sql
CREATE TABLE fulfillment_routing (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  prescription_id UUID REFERENCES prescriptions(id),
  test_request_id UUID REFERENCES test_requests(id),

  fulfilling_tenant_id UUID NOT NULL REFERENCES tenants(id),
  routing_reason VARCHAR(50) NOT NULL,               -- 'pharmacy_referrer', 'diagnostic_referrer', 'customer_selected'

  created_at TIMESTAMPTZ DEFAULT NOW(),

  CONSTRAINT one_fulfillment_type CHECK (
    (prescription_id IS NOT NULL AND test_request_id IS NULL) OR
    (prescription_id IS NULL AND test_request_id IS NOT NULL)
  ),
  CONSTRAINT valid_routing_reason CHECK (routing_reason IN ('pharmacy_referrer', 'diagnostic_referrer', 'customer_selected'))
);

CREATE INDEX idx_fulfillment_prescription ON fulfillment_routing(prescription_id) WHERE prescription_id IS NOT NULL;
CREATE INDEX idx_fulfillment_test ON fulfillment_routing(test_request_id) WHERE test_request_id IS NOT NULL;
CREATE INDEX idx_fulfillment_tenant ON fulfillment_routing(fulfilling_tenant_id);
```

**Fields**:
- `id`: Primary key
- `prescription_id`: Foreign key to prescription being fulfilled (NULL if test request)
- `test_request_id`: Foreign key to test request being fulfilled (NULL if prescription)
- `fulfilling_tenant_id`: Which tenant is fulfilling this order
- `routing_reason`: Why this tenant was chosen
  - `pharmacy_referrer`: Auto-routed because customer came through pharmacy's page
  - `diagnostic_referrer`: Auto-routed because customer came through diagnostic center's page
  - `customer_selected`: Customer chose from directory (no referrer)
- `created_at`: Routing decision timestamp

**Relationships**:
- `prescription_id` → `prescriptions.id` (nullable, one-to-one)
- `test_request_id` → `test_requests.id` (nullable, one-to-one)
- `fulfilling_tenant_id` → `tenants.id` (required)

**Validation Rules**:
- Exactly one of prescription_id or test_request_id must be set (XOR constraint)
- Routing reason must be one of the three valid values
- For `pharmacy_referrer`: fulfilling_tenant_id must be a pharmacy tenant
- For `diagnostic_referrer`: fulfilling_tenant_id must be a diagnostic center tenant

**State Transitions**:
```
[Prescription/Test created] → CREATE fulfillment_routing record
         ↓
[Immutable] → Record never updated, only read for audit trail
```

**RLS Policy**:
```sql
-- Tenants see routing where they are the fulfiller
CREATE POLICY tenant_routing_read ON fulfillment_routing
FOR SELECT
USING (
  auth.jwt() ->> 'tenant_id' = fulfilling_tenant_id::TEXT OR
  auth.jwt() ->> 'role' = 'platform_admin'
);

-- Only platform can create routing records (via triggers)
CREATE POLICY platform_routing_write ON fulfillment_routing
FOR ALL
USING (auth.jwt() ->> 'role' = 'platform_admin');
```

---

## Extended Entities (Modifications to Existing Tables)

### 5. prescriptions (MODIFIED)

**Purpose**: Medication prescriptions issued by doctors. **Modified to add automatic fulfillment routing.**

**New Fields**:
```sql
ALTER TABLE prescriptions
ADD COLUMN fulfilling_pharmacy_id UUID REFERENCES tenants(id),
ADD COLUMN referring_tenant_id UUID REFERENCES tenants(id),
ADD CONSTRAINT fulfilling_pharmacy_is_pharmacy CHECK (
  fulfilling_pharmacy_id IS NULL OR
  EXISTS (SELECT 1 FROM tenants WHERE id = fulfilling_pharmacy_id AND tenant_type = 'pharmacy')
);
```

**Fields Added**:
- `fulfilling_pharmacy_id`: Which pharmacy will fulfill this prescription (auto-assigned if referrer is pharmacy)
- `referring_tenant_id`: Tracks which tenant referred the consultation that led to this prescription

**Trigger for Auto-Routing**:
```sql
CREATE FUNCTION route_prescription_to_referrer()
RETURNS TRIGGER AS $$
DECLARE
  referrer_tenant_id UUID;
  referrer_type TEXT;
BEGIN
  -- Get referring tenant from customer's active session
  SELECT rs.referring_tenant_id, t.tenant_type
  INTO referrer_tenant_id, referrer_type
  FROM referral_sessions rs
  JOIN tenants t ON t.id = rs.referring_tenant_id
  WHERE rs.customer_id = NEW.customer_id AND rs.active = TRUE
  LIMIT 1;

  NEW.referring_tenant_id := referrer_tenant_id;

  -- Auto-route if referrer is pharmacy
  IF referrer_type = 'pharmacy' THEN
    NEW.fulfilling_pharmacy_id := referrer_tenant_id;

    -- Log routing decision
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

---

### 6. test_requests (MODIFIED)

**Purpose**: Diagnostic test orders. **Modified to add automatic fulfillment routing.**

**New Fields**:
```sql
ALTER TABLE test_requests
ADD COLUMN fulfilling_diagnostic_center_id UUID REFERENCES tenants(id),
ADD COLUMN referring_tenant_id UUID REFERENCES tenants(id),
ADD CONSTRAINT fulfilling_diagnostic_is_diagnostic CHECK (
  fulfilling_diagnostic_center_id IS NULL OR
  EXISTS (SELECT 1 FROM tenants WHERE id = fulfilling_diagnostic_center_id AND tenant_type = 'diagnostic')
);
```

**Fields Added**:
- `fulfilling_diagnostic_center_id`: Which diagnostic center will process this test (auto-assigned if referrer is diagnostic center)
- `referring_tenant_id`: Tracks which tenant referred the consultation that led to this test

**Trigger for Auto-Routing**:
```sql
CREATE FUNCTION route_test_to_referrer()
RETURNS TRIGGER AS $$
DECLARE
  referrer_tenant_id UUID;
  referrer_type TEXT;
BEGIN
  SELECT rs.referring_tenant_id, t.tenant_type
  INTO referrer_tenant_id, referrer_type
  FROM referral_sessions rs
  JOIN tenants t ON t.id = rs.referring_tenant_id
  WHERE rs.customer_id = NEW.customer_id AND rs.active = TRUE
  LIMIT 1;

  NEW.referring_tenant_id := referrer_tenant_id;

  -- Auto-route if referrer is diagnostic center
  IF referrer_type = 'diagnostic' THEN
    NEW.fulfilling_diagnostic_center_id := referrer_tenant_id;

    INSERT INTO fulfillment_routing (test_request_id, fulfilling_tenant_id, routing_reason)
    VALUES (NEW.id, referrer_tenant_id, 'diagnostic_referrer');
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER test_auto_route
BEFORE INSERT ON test_requests
FOR EACH ROW EXECUTE FUNCTION route_test_to_referrer();
```

---

### 7. consultations (MODIFIED)

**Purpose**: Doctor consultations. **Modified to track referral attribution for commission calculation.**

**New Fields**:
```sql
ALTER TABLE consultations
ADD COLUMN referring_tenant_id UUID REFERENCES tenants(id),
ADD COLUMN commission_calculated BOOLEAN DEFAULT FALSE;
```

**Fields Added**:
- `referring_tenant_id`: Which tenant referred this consultation (NULL if direct)
- `commission_calculated`: Flag to prevent duplicate commission calculations

---

### 8. orders (MODIFIED)

**Purpose**: Product orders (pharmacy, supermarket, retail). **Modified to track referral attribution.**

**New Fields**:
```sql
ALTER TABLE orders
ADD COLUMN referring_tenant_id UUID REFERENCES tenants(id),
ADD COLUMN commission_calculated BOOLEAN DEFAULT FALSE;
```

**Fields Added**:
- `referring_tenant_id`: Which tenant referred this order (NULL if direct)
- `commission_calculated`: Flag to prevent duplicate commission calculations

---

## Analytical Views

### commission_daily_summary (Materialized View)

**Purpose**: Pre-aggregated commission data for fast dashboard queries.

**Schema**:
```sql
CREATE MATERIALIZED VIEW commission_daily_summary AS
SELECT
  referrer_tenant_id,
  DATE(created_at) AS date,
  transaction_type,
  status,

  SUM(referrer_amount) AS total_earned,
  COUNT(*) AS transaction_count,
  AVG(referrer_amount) AS avg_commission,
  MIN(referrer_amount) AS min_commission,
  MAX(referrer_amount) AS max_commission

FROM commissions
WHERE referrer_tenant_id IS NOT NULL
GROUP BY referrer_tenant_id, DATE(created_at), transaction_type, status;

CREATE UNIQUE INDEX ON commission_daily_summary (referrer_tenant_id, date, transaction_type, status);

-- Refresh nightly
CREATE OR REPLACE FUNCTION refresh_commission_summary()
RETURNS void AS $$
BEGIN
  REFRESH MATERIALIZED VIEW CONCURRENTLY commission_daily_summary;
END;
$$ LANGUAGE plpgsql;
```

**Usage**: Dashboard queries for "Total earned this month", "Commission by transaction type", etc.

---

## Database Functions

### calculate_service_commission

**Purpose**: Calculate commission splits for service-based transactions (consultations, diagnostic tests).

**Signature**:
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
      base_price * 1.10,  -- 10% markup
      base_price * 0.90,  -- provider
      base_price * 0.10,  -- referrer
      base_price * 0.10;  -- platform
  ELSE
    RETURN QUERY SELECT
      base_price * 1.10,
      base_price * 0.90,
      0::DECIMAL(12,2),   -- no referrer
      base_price * 0.20;  -- platform double share
  END IF;
END;
$$ LANGUAGE plpgsql IMMUTABLE;
```

### calculate_product_commission

**Purpose**: Calculate commission splits for product-based transactions (pharmacy drugs).

**Signature**:
```sql
CREATE FUNCTION calculate_product_commission(
  product_price DECIMAL(12,2),
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
      product_price,                -- no markup
      product_price * 0.94,         -- provider
      product_price * 0.045,        -- referrer 4.5%
      product_price * 0.015;        -- platform 1.5%
  ELSE
    RETURN QUERY SELECT
      product_price + 100,          -- ₦100 fixed charge
      product_price * 0.94,         -- provider
      0::DECIMAL(12,2),             -- no referrer
      product_price * 0.015 + 100;  -- platform 1.5% + ₦100
  END IF;
END;
$$ LANGUAGE plpgsql IMMUTABLE;
```

---

## TypeScript Types (Generated from Schema)

```typescript
// Generated types for TypeScript clients
export type CommissionStatus = 'pending' | 'processed' | 'paid_out';
export type TransactionType = 'consultation' | 'product_sale' | 'diagnostic_test';
export type RoutingReason = 'pharmacy_referrer' | 'diagnostic_referrer' | 'customer_selected';

export interface ReferralSession {
  id: string;
  session_token: string;
  customer_id: string | null;
  referring_tenant_id: string;
  active: boolean;
  created_at: string;
  expires_at: string;
  last_activity_at: string;
}

export interface Transaction {
  id: string;
  group_id: string;
  type: TransactionType;
  provider_tenant_id: string;
  customer_id: string;
  referring_tenant_id: string | null;
  base_price: number;
  final_price_paid: number;
  payment_status: string;
  payment_reference: string | null;
  created_at: string;
  paid_at: string | null;
}

export interface Commission {
  id: string;
  transaction_id: string;
  transaction_type: TransactionType;
  provider_tenant_id: string;
  referrer_tenant_id: string | null;
  customer_id: string;
  base_amount: number;
  customer_paid: number;
  provider_amount: number;
  referrer_amount: number | null;
  platform_amount: number;
  status: CommissionStatus;
  created_at: string;
  processed_at: string | null;
  paid_at: string | null;
  calculation_metadata: Record<string, any> | null;
}

export interface FulfillmentRouting {
  id: string;
  prescription_id: string | null;
  test_request_id: string | null;
  fulfilling_tenant_id: string;
  routing_reason: RoutingReason;
  created_at: string;
}

export interface CommissionCalculation {
  customer_pays: number;
  provider_gets: number;
  referrer_gets: number;
  platform_gets: number;
}
```

---

## Migration Strategy

**Migration File**: `supabase/migrations/20260313_referral_commissions.sql`

**Execution Order**:
1. Create enum types (`commission_status`, etc.)
2. Create new tables (`referral_sessions`, `transactions`, `commissions`, `fulfillment_routing`)
3. Add new columns to existing tables (`prescriptions`, `test_requests`, `consultations`, `orders`)
4. Create indexes for performance
5. Create database functions (`calculate_service_commission`, `calculate_product_commission`)
6. Create triggers (`prescription_auto_route`, `test_auto_route`)
7. Enable RLS policies on all tables
8. Create materialized views (`commission_daily_summary`)
9. Set up cron job for nightly view refresh

**Rollback Strategy**:
- Drop triggers first
- Drop functions
- Drop new tables
- Remove added columns from existing tables
- Drop enum types

---

**Data model complete. Ready for contracts generation.**
