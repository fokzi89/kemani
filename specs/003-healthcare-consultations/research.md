# Phase 0: Technical Research & Decisions
## Healthcare Provider Directory and Telemedicine Consultations

**Date**: 2026-02-21
**Feature**: 003-healthcare-consultations
**Purpose**: Document all technical decisions, architectural patterns, and integration approaches before Phase 1 design.

---

## 1. Real-Time Communication Architecture

### Decision: Agora SDK for Video/Audio + Supabase Realtime for Chat

**Rationale**:
- **Agora SDK** is industry-standard for WebRTC with proven reliability at scale
- Handles complex NAT traversal, network quality adaptation, device compatibility
- Supports 480p+ quality requirement (SC-002) with automatic quality degradation
- Built-in recording capabilities for compliance/audit requirements
- Server-side token generation ensures secure channel access
- **Supabase Realtime** for chat consultations leverages existing infrastructure
- PostgreSQL-backed chat messages provide persistence and query capabilities
- WebSocket subscriptions for <2s latency requirement (SC-003)

**Alternatives Considered**:
- **Twilio Video**: More expensive, similar capabilities, less flexibility for custom UI
- **Daily.co**: Good developer experience but adds another vendor dependency
- **Custom WebRTC**: Too complex to build/maintain, network edge cases difficult
- **Socket.io for chat**: Adds dependency when Supabase Realtime already available

**Implementation Approach**:
- Agora Web SDK 4.x in SvelteKit Client Components (`VideoRoom.svelte`)
- Agora RTC tokens generated server-side:
  - Patient tokens: SvelteKit route (`/consultations/:id/join` - this repo)
  - Provider tokens: Flutter backend endpoint (`/api/medic/agora-token` - separate repo)
- Token expiration tied to consultation slot duration + 5min grace period
- Supabase Realtime subscriptions in `ChatInterface.svelte` for message delivery
- Presence tracking via Supabase Realtime for typing indicators

**References**:
- [Agora Web SDK 4.x Documentation](https://docs.agora.io/en/video-calling/get-started/get-started-sdk)
- [Supabase Realtime Documentation](https://supabase.com/docs/guides/realtime)

---

## 2. Multi-Tenancy & Data Isolation Strategy

### Decision: Supabase Row Level Security (RLS) Policies

**Rationale**:
- **RLS enforces data isolation at database level**, preventing application-level bugs from leaking tenant data
- All healthcare entities include `tenant_id` (business_id) foreign key to businesses table
- **Patient data scoped by customer_id**: Patients only see their own consultations/prescriptions
- **Provider data scoped by provider_id**: Providers see all consultations assigned to them across tenants
- **Business owners** via Flutter admin app use `tenant_id` to filter provider commissions, not patient data
- RLS policies checked on every query, even if application logic has bugs

**Alternatives Considered**:
- **Application-level filtering**: Error-prone, single mistake exposes cross-tenant data
- **Schema-per-tenant**: Massive operational overhead for hundreds/thousands of tenants
- **Encrypted tenant_id**: Adds complexity without RLS guarantees

**RLS Policy Examples**:
```sql
-- Patients can only see their own consultations
CREATE POLICY "patients_own_consultations" ON consultations
FOR SELECT USING (patient_id = auth.uid());

-- Providers can see consultations where they are the provider
CREATE POLICY "providers_assigned_consultations" ON consultations
FOR SELECT USING (provider_id = auth.uid());

-- Country-wide provider pool: filter by business's country
CREATE POLICY "providers_by_country" ON healthcare_providers
FOR SELECT USING (
  country = (SELECT country FROM businesses WHERE id = current_setting('app.current_tenant_id')::uuid)
);
```

**References**:
- [Supabase RLS Documentation](https://supabase.com/docs/guides/auth/row-level-security)
- [Multi-tenancy Patterns](https://supabase.com/docs/guides/auth/row-level-security#multi-tenancy)

---

## 3. Payment Integration & Commission Flow

### Decision: Existing Payment Gateway + Database Transaction Tracking

**Rationale**:
- **Reuse existing storefront payment gateway** (configured per tenant) for consistency
- Payment captured at booking time (all consultation types) per clarification session
- **Commission calculated asynchronously** when consultation marked complete
- Commission record stored in `consultation_transactions` table with status tracking
- Actual payout to providers handled outside this feature scope (assumptions state "existing payment infrastructure")

**Payment Flow**:
1. **Booking**: Patient proceeds to checkout (existing storefront checkout flow)
2. **Payment Gateway**: Charge processed via tenant's configured gateway
3. **Consultation Record**: Created with `payment_status: 'paid'`
4. **Consultation Completion**: Provider marks complete (chat) or call ends (video/audio/office)
5. **Commission Calculation**: Trigger function calculates `commission_amount = fee * platform_rate`
6. **Transaction Record**: Insert into `consultation_transactions` with status `pending_payout`
7. **Provider Payout**: External job processes `pending_payout` records (out of scope)

**Alternatives Considered**:
- **Stripe Connect split payments**: Requires all tenants to use Stripe, limits gateway choice
- **Commission escrow account**: Adds financial complexity and regulatory requirements
- **Pre-charge commission separately**: Confusing UX, requires explaining two charges

**Implementation Notes**:
- Platform commission rate stored in system config table (default 15%, adjustable)
- Refund policy (FR-015) triggers reverse commission calculation
- Commission only finalized after consultation completion to handle cancellations

**References**:
- Existing payment gateway integration in `apps/storefront/src/lib/services/payments.ts`

---

## 4. Provider Availability & Scheduling System

### Decision: Discrete Time Slot Model with Conflict Prevention

**Rationale**:
- **Provider configures recurring availability** (e.g., "Mondays 9am-5pm, 30min slots")
- System generates discrete slots for next 30 days (configurable horizon)
- **Slot booking atomicity** via PostgreSQL transactions with row-level locks
- Prevents double-booking even under concurrent requests (FR-022)
- Slot durations: 15/30/45/60 minutes (provider-selectable per clarification)

**Availability Schema**:
- `provider_availability_templates`: Recurring patterns (day_of_week, start_time, end_time, slot_duration)
- `provider_time_slots`: Materialized slots (provider_id, date, start_time, end_time, status, consultation_type)
- **Slot Status Lifecycle**: `available` → `booked` → `in_progress` → `completed` / `cancelled`

**Double-Booking Prevention**:
```sql
-- Atomic slot booking with optimistic locking
UPDATE provider_time_slots
SET status = 'booked', consultation_id = $1, version = version + 1
WHERE id = $2 AND status = 'available' AND version = $3
RETURNING *;

-- If no rows returned, slot was taken by concurrent request
```

**Alternatives Considered**:
- **Calendar blocking only**: No discrete slots, complex conflict detection
- **First-come reservation queue**: Unfair, complex timeout handling
- **Pessimistic locking**: Holds locks during user checkout, poor UX under high load

**Timezone Handling**:
- Store all times in UTC (provider sets availability in their timezone, converted to UTC)
- Display times in patient's timezone for scheduled consultations
- Reminder notifications account for timezone differences (FR-021)

**References**:
- [PostgreSQL Advisory Locks](https://www.postgresql.org/docs/current/explicit-locking.html)
- [Optimistic Concurrency Control](https://en.wikipedia.org/wiki/Optimistic_concurrency_control)

---

## 5. Prescription Expiration & Lifecycle Management

### Decision: Database-Triggered Expiration + Cron Job Monitoring

**Rationale**:
- Prescription `expiration_date` auto-calculated: `issue_date + 90 days` (per clarification)
- **Expiration check at cart checkout**: Prevent adding expired prescriptions to cart
- **Background cron job**: Daily scan for expiring prescriptions (notify 7 days before expiration)
- Expired prescriptions remain in database for record-keeping (compliance: 5 years minimum)

**Prescription State Machine**:
- `active` (issue_date ≤ today < expiration_date)
- `expired` (today ≥ expiration_date)
- `fulfilled` (medications added to pharmacy order, not reusable)

**Implementation**:
```sql
-- Computed column for prescription status
CREATE FUNCTION prescription_status(issue_date date, expiration_date date, fulfilled boolean)
RETURNS text AS $$
  SELECT CASE
    WHEN fulfilled THEN 'fulfilled'
    WHEN CURRENT_DATE >= expiration_date THEN 'expired'
    ELSE 'active'
  END
$$ LANGUAGE SQL IMMUTABLE;

-- Index for efficient expiration queries
CREATE INDEX idx_prescriptions_expiration ON prescriptions(expiration_date)
WHERE expiration_date > CURRENT_DATE;
```

**Alternatives Considered**:
- **Provider-specified expiration**: Too variable, compliance risk
- **No expiration**: Violates medical best practices
- **Manual expiration marking**: Error-prone, inconsistent

**References**:
- [PostgreSQL Generated Columns](https://www.postgresql.org/docs/current/ddl-generated-columns.html)

---

## 6. Video/Audio Duration Enforcement Mechanism

### Decision: Client-Side Warning + Server-Side Grace Period + Agora Channel Expiry

**Rationale**:
- **5-minute warning** displayed in video/audio UI (client-side timer)
- **5-minute grace period** after slot duration expires (total: slot_duration + 10 minutes)
- **Agora token expiration** set to slot_duration + 10 minutes (server enforces hard cutoff)
- When token expires, Agora SDK disconnects call automatically
- Consultation marked `completed` when either party ends call OR grace period expires

**Implementation**:
```typescript
// Client-side warning logic (VideoRoom.svelte)
const warningTime = slotDuration - 5 * 60 * 1000; // 5 min before end
const hardCutoff = slotDuration + 5 * 60 * 1000; // +5 min grace

onMount(() => {
  setTimeout(() => showWarning("5 minutes remaining"), warningTime);
  setTimeout(() => endCall("Time limit reached"), hardCutoff);
});

// Server-side token generation
const tokenExpiryTime = Math.floor(Date.now() / 1000) + (slotDuration + 600); // +10 min
const agoraToken = generateRtcToken(channel, uid, tokenExpiryTime);
```

**Alternatives Considered**:
- **Hard cutoff with no warning**: Poor UX, users caught mid-sentence
- **No enforcement**: Providers overrun slots, scheduling conflicts cascade
- **Server polling to disconnect**: Adds complexity, Agora token expiry simpler

**User Experience**:
- Visual countdown timer always visible
- Warning displayed prominently (modal + sound notification)
- Grace period allows natural conversation wrap-up
- Provider can manually end earlier if consultation complete

**References**:
- [Agora Token Authentication](https://docs.agora.io/en/video-calling/develop/authentication-workflow)

---

## 7. Database Schema Normalization & Indexing Strategy

### Decision: 3NF Normalization with Denormalization for Performance-Critical Queries

**Rationale**:
- **Healthcare entities highly relational**: providers → consultations → prescriptions → medications
- 3rd Normal Form prevents data anomalies (critical for medical records)
- **Strategic denormalization**: Provider name/photo cached in consultations for fast history queries
- Composite indexes for common query patterns (tenant + status, provider + date range)

**Index Strategy**:
```sql
-- Provider directory filtering (country + specialization + business type)
CREATE INDEX idx_providers_country_specialization
ON healthcare_providers(country, specialization)
WHERE active = true;

-- Consultation queries (patient's history, provider's schedule)
CREATE INDEX idx_consultations_patient_date
ON consultations(patient_id, scheduled_time DESC);

CREATE INDEX idx_consultations_provider_date
ON consultations(provider_id, scheduled_time DESC);

-- Availability slot lookups (provider + date range + status)
CREATE INDEX idx_time_slots_provider_date
ON provider_time_slots(provider_id, date, status)
WHERE status = 'available';

-- Prescription expiration queries
CREATE INDEX idx_prescriptions_expiration
ON prescriptions(expiration_date)
WHERE expiration_date >= CURRENT_DATE;
```

**Denormalized Fields**:
- `consultations.provider_name` (avoid JOIN for history list)
- `consultations.provider_photo_url` (avatar in consultation cards)
- `prescriptions.provider_name` (prescription header)

**Normalization Preserved**:
- Medications as JSONB array in prescriptions (structured but not separate table for MVP)
- Provider availability templates separate from materialized slots
- Commission transactions separate from consultations (audit trail)

**Alternatives Considered**:
- **Full denormalization (NoSQL-style)**: Violates constitution type safety, update anomalies
- **Zero denormalization**: Excessive JOINs on consultation history queries (performance)

**References**:
- [PostgreSQL Indexing Best Practices](https://www.postgresql.org/docs/current/indexes.html)
- [Supabase Performance Tips](https://supabase.com/docs/guides/database/performance)

---

## 8. Error Handling & Edge Case Strategies

### Decision: Graceful Degradation + User-Facing Error Messages + Audit Logging

**Rationale**:
- **Network failures during video/audio**: Agora SDK auto-reconnect (30s window), then suggest fallback to audio-only or reschedule
- **Payment failures at booking**: Clear error message, retain slot for 5 minutes (held_for_payment status), auto-release if not completed
- **Provider cancellation**: Refund triggered automatically (FR-015: full refund if >24h notice), email notification to patient
- **Prescription not in pharmacy catalog**: Display message "This medication may not be available at this pharmacy. Contact the pharmacy or your provider for alternatives."
- **Audit logging**: All consultation state transitions, prescription issuance, commission calculations logged to `audit_log` table

**Error Response Pattern**:
```typescript
// Standardized API error format
interface HealthcareApiError {
  code: string; // E.g., "SLOT_UNAVAILABLE", "PAYMENT_FAILED"
  message: string; // User-facing explanation
  action: string; // Suggested next step (e.g., "Please refresh and try again")
  metadata?: Record<string, any>; // Context for debugging
}
```

**Edge Case Handling Matrix**:
| Edge Case | Detection | Resolution | User Impact |
|-----------|-----------|------------|-------------|
| Double-booking attempt | Optimistic lock failure | Show "Slot no longer available", refresh calendar | Minor (choose another slot) |
| Payment gateway timeout | 30s request timeout | Retry with idempotency key, then show error | Moderate (contact support if persists) |
| Provider late to call | Patient waits >5 min | Send notification to provider, allow patient to cancel | Moderate (full refund) |
| Patient joins call late | >15 min after start time | Allow join but warn "consultation time reduced" | Minor (patient's choice) |
| Network loss mid-call | Agora disconnection event | Auto-reconnect UI, grace period for rejoin | Minor (resume if rejoins) |
| Prescription medication out of stock | Patient search returns no results | Show message suggesting contact pharmacy | Moderate (manual intervention) |

**References**:
- [Agora Connection State Management](https://docs.agora.io/en/video-calling/develop/handle-connection-loss)
- [Idempotent API Design](https://stripe.com/docs/api/idempotent_requests)

---

## 9. Compliance & Data Retention Policies

### Decision: GDPR/HIPAA-Aligned Data Handling with Configurable Retention

**Rationale**:
- **Minimum 5-year retention** for consultation records (assumption documented)
- **Right to be forgotten**: Patient data anonymization (not deletion) to preserve consultation history for providers/auditing
- **Data encryption**: At-rest via Supabase encryption, in-transit via HTTPS/TLS + Agora encryption
- **Access controls**: RLS policies + RBAC for admin access (providers only see own data, business owners see commission aggregates)

**Anonymization Strategy**:
```sql
-- When patient requests deletion, anonymize PII
UPDATE consultations
SET patient_name = 'Deleted User',
    patient_email = 'deleted@example.com',
    patient_phone = NULL
WHERE patient_id = $1;

-- Prescriptions retain medication data (medical necessity) but remove patient identifiers
UPDATE prescriptions
SET patient_name = 'Deleted User'
WHERE patient_id = $1;
```

**Audit Trail**:
- All consultation lifecycle events logged (created, started, completed, cancelled)
- Prescription issuance logged with provider ID and timestamp
- Commission calculations logged with formula snapshot (detect rate changes)
- Logs retained for 7 years (regulatory requirement for financial transactions)

**References**:
- [GDPR Right to Erasure](https://gdpr-info.eu/art-17-gdpr/)
- [HIPAA Data Retention Requirements](https://www.hhs.gov/hipaa/for-professionals/privacy/guidance/access/index.html)

---

## 10. Testing Strategy & Quality Assurance

### Decision: Integration-First Testing with Manual Video/Audio QA

**Rationale**:
- **Integration tests** for critical paths (constitution Principle III):
  - Booking flow: Provider selection → slot booking → payment → confirmation
  - Prescription issuance → cart addition (manual search flow)
  - Commission calculation accuracy
- **E2E tests** for video/audio join flow (Playwright):
  - Token generation → Agora channel join → UI renders
  - Does NOT test actual call quality (network variability too high)
- **Manual QA** for video/audio quality:
  - Test on different networks (3G, 4G, WiFi)
  - Multi-device testing (desktop, mobile browsers)
  - Latency measurements for compliance (SC-002)
- **Unit tests** for commission calculator (financial accuracy critical)

**Test Scenarios**:
```typescript
// Integration test: Complete booking flow
describe('Consultation Booking Flow', () => {
  it('should book consultation, process payment, and create consultation record', async () => {
    // 1. Select provider
    const provider = await selectProvider(country: 'Nigeria');

    // 2. Choose available slot
    const slot = await getAvailableSlots(provider.id, slotDuration: 30);

    // 3. Proceed to checkout
    const checkout = await initiateCheckout(slot.id, consultationType: 'video');

    // 4. Process payment (mocked gateway)
    const payment = await processPayment(checkout.id, paymentMethod: testCard);
    expect(payment.status).toBe('succeeded');

    // 5. Verify consultation created
    const consultation = await getConsultation(checkout.consultationId);
    expect(consultation.status).toBe('pending');
    expect(consultation.payment_status).toBe('paid');
  });
});

// Unit test: Commission calculation
describe('Commission Calculator', () => {
  it('should calculate platform commission correctly', () => {
    const fee = 5000; // 50.00 currency units
    const rate = 0.15; // 15% platform fee
    const commission = calculateCommission(fee, rate);
    expect(commission).toBe(750); // 7.50 currency units
  });
});
```

**Quality Gates**:
- All integration tests pass before merge (constitution compliance)
- Commission calculation unit tests have 100% coverage
- Manual QA checklist for each video/audio code change
- Lighthouse performance audit: LCP < 2.5s, bundle size < 200KB

**References**:
- [Vitest Documentation](https://vitest.dev/)
- [Playwright E2E Testing](https://playwright.dev/)

---

## Summary

All technical unknowns from plan.md Technical Context section resolved:
- ✅ Real-time communication: Agora SDK + Supabase Realtime
- ✅ Multi-tenancy: Supabase RLS policies
- ✅ Payment flow: Existing gateway + async commission tracking
- ✅ Scheduling: Discrete slot model with conflict prevention
- ✅ Prescription lifecycle: 90-day expiration with database automation
- ✅ Duration enforcement: Client warning + Agora token expiry
- ✅ Database design: 3NF with strategic denormalization
- ✅ Error handling: Graceful degradation + audit logging
- ✅ Compliance: GDPR/HIPAA-aligned retention + anonymization
- ✅ Testing: Integration-first + manual video QA

**Next Phase**: Generate data-model.md with detailed entity schemas and relationships.
