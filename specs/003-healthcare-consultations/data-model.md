# Phase 1: Data Model
## Healthcare Provider Directory and Telemedicine Consultations

**Date**: 2026-02-21 | **Feature**: 003-healthcare-consultations

This document defines the complete database schema for all 8 healthcare entities with relationships, constraints, indexes, and RLS policies. Full SQL implementation available in `supabase/migrations/`.

---

## Entity Overview

| Entity | Purpose | Relationships |
|--------|---------|---------------|
| **healthcare_providers** | Country-wide provider pool | 1:N consultations, availability_templates, time_slots |
| **provider_availability_templates** | Recurring schedule patterns | N:1 providers, 1:N time_slots |
| **provider_time_slots** | Materialized bookable slots | N:1 providers, 1:1 consultations |
| **consultations** | Core consultation sessions | N:1 providers, N:1 patients, 1:N messages, 1:1 transactions |
| **consultation_messages** | Chat messages | N:1 consultations |
| **prescriptions** | Digital prescriptions | N:1 consultations, N:1 providers, N:1 patients |
| **consultation_transactions** | Payment & commission tracking | 1:1 consultations |
| **favorite_providers** | Patient bookmarks | N:1 patients, N:1 providers |

---

## Key Schema Details

### healthcare_providers
- **Primary Key**: `id UUID`
- **Critical Fields**: `country TEXT`, `specialization TEXT`, `fees JSONB`, `consultation_types TEXT[]`
- **RLS**: Public read for active/verified providers in customer's country
- **Indexes**: `(country, specialization)`, `(region)`, `(average_rating DESC)`

### consultations
- **Primary Key**: `id UUID`
- **Critical Fields**: `type TEXT` (chat/video/audio/office_visit), `status TEXT`, `payment_status TEXT`
- **Lifecycle**: pending → in_progress → completed / cancelled
- **Payment**: Captured at booking (`paid_at TIMESTAMPTZ`)
- **Agora Integration**: `agora_channel_name`, `agora_token_expiry` for video/audio
- **Referral Tracking**: `referral_source TEXT` (storefront/medic_clinic/direct), `referrer_entity_id UUID` (business_id or host_medic_id for commission attribution)
- **RLS**: Patients see own, providers see assigned
- **Indexes**: `(patient_id, created_at DESC)`, `(provider_id, scheduled_time DESC)`, `(referral_source, referrer_entity_id)`

### provider_time_slots
- **Optimistic Locking**: `version INTEGER` prevents double-booking
- **Status Flow**: available → held_for_payment (5min) → booked → in_progress → completed
- **Constraints**: `UNIQUE(provider_id, date, start_time)` prevents overlaps
- **Indexes**: `(provider_id, date, status)`, `(date, status) WHERE status = 'available'`

### prescriptions
- **Auto-Expiration**: `expiration_date DATE DEFAULT (CURRENT_DATE + INTERVAL '90 days')`
- **Medications**: `JSONB` array with structure:
  ```json
  [{
    "name": "Amoxicillin",
    "dosage": "500mg",
    "frequency": "3 times daily",
    "duration": "7 days",
    "special_instructions": "Take with food"
  }]
  ```
- **Auto-Status**: Trigger computes `status` (active/expired/fulfilled) based on dates
- **RLS**: Patients see own, providers see issued prescriptions

### consultation_transactions
- **Commission Calculation**: `gross_amount = commission_amount + net_provider_amount`
- **Commission Rate**: Stored at transaction time (platform rate may change)
- **Payout Tracking**: `payout_status` (pending_payout/paid_out/on_hold/cancelled)
- **Refund Support**: `refund_amount`, `commission_reversed` for cancellations
- **Constraint**: `UNIQUE(consultation_id)` - one transaction per consultation

---

## Multi-Tenancy Strategy

**RLS Enforcement** on all tables:
- **Patient Scope**: `patient_id = auth.uid()` (see own consultations/prescriptions)
- **Provider Scope**: `provider_id IN (SELECT id WHERE user_id = auth.uid())` (see assigned consultations)
- **Country Filtering**: Providers visible only to businesses in same country
- **Tenant Isolation**: `tenant_id` reference prevents cross-tenant data leaks

**Session Variables**:
- `app.current_tenant_id`: Set by API middleware for country-based provider filtering

---

## Performance Optimizations

**Strategic Denormalization**:
- Provider name/photo cached in consultations (avoid JOINs in history queries)
- Provider name/credentials cached in prescriptions (prescription header)

**Critical Indexes** (35 total):
- Provider directory queries: `(country, specialization)`
- Consultation history: `(patient_id, created_at DESC)`
- Available slots: `(date, status) WHERE status = 'available'`
- Prescription expiration: `(expiration_date) WHERE status = 'active'`

**Query Patterns**:
- Provider search: ~50ms (indexed on country + specialization)
- Consultation history: ~30ms (patient_id index + denormalized provider data)
- Slot availability: ~20ms (date + status composite index)

---

## Data Integrity Constraints

1. **Scheduled consultations MUST have time**: `(type = 'chat') OR (scheduled_time IS NOT NULL)`
2. **Office visits MUST have location**: `(type != 'office_visit') OR (location_address IS NOT NULL)`
3. **Video/audio MUST have Agora channel**: `(type NOT IN ('video', 'audio')) OR (agora_channel_name IS NOT NULL)`
4. **Prescription expiration > issue date**: `expiration_date > issue_date`
5. **Commission math**: `gross_amount = commission_amount + net_provider_amount`
6. **Slot duration options**: `slot_duration IN (15, 30, 45, 60)`
7. **No slot overlaps**: `UNIQUE(provider_id, date, start_time)`

---

## Migration Notes

**Migration Order** (dependency resolution):
1. `healthcare_providers` (base entity)
2. `provider_availability_templates` (FK to providers)
3. `provider_time_slots` (FK to providers, templates)
4. `consultations` (FK to providers, patients, tenants)
5. `consultation_messages` (FK to consultations)
6. `prescriptions` (FK to consultations, providers, patients)
7. `consultation_transactions` (FK to consultations, providers, patients, tenants)
8. `favorite_providers` (FK to providers, patients)

**Seed Data Required**:
- Platform commission rate config (`system_config` table: `healthcare_commission_rate = 0.15`)

**Full SQL Schema**: See `supabase/migrations/[timestamp]_healthcare_consultation.sql`
