# Implementation Plan: Healthcare Provider Directory and Telemedicine Consultations

**Branch**: `003-healthcare-consultations` | **Date**: 2026-02-22 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/003-healthcare-consultations/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Add comprehensive telemedicine capabilities to pharmacy and diagnostic centre storefronts (paid plans only), including: healthcare provider directory from country-wide pool, multi-modal consultations (text chat, video, audio, office visits), digital prescription management with pharmacy catalog integration, and commission-based provider payment system.

**Critical Architecture**: Multi-domain branding continuity - customers entering through storefront remain in storefront domain (store.fokz.com/healthcare/*) with storefront branding; customers entering through medic clinic page (Growth+ Doctor List) remain in medic domain (medic.kemani.com/c/dr-kate/* or custom domain) with medic branding. Referral source tracking (storefront, medic_clinic, direct) drives commission attribution via bridge system.

Uses Agora SDK for real-time video/audio in SvelteKit storefront. Medic providers manage their practice via Flutter kemani_medic app with its own backend API (separate repository).

## Technical Context

**Language/Version**: TypeScript (strict mode), Node.js 20+, SvelteKit 2.x (Svelte 5), Dart/Flutter (medic app)

**Primary Dependencies**:
- Frontend (Storefront): SvelteKit 2.x, Svelte 5, Tailwind CSS 4, Agora Web SDK 4.x (video/audio)
- Backend (Medic API): Flutter/Dart backend (separate repository), Supabase client, Agora Server SDK
- Database: Supabase PostgreSQL with Row Level Security (RLS)
- Real-time: Supabase Realtime (chat messaging), Agora RTC (video/audio)

**Storage**:
- Supabase PostgreSQL for all healthcare entities (providers, consultations, prescriptions, availability, transactions)
- Supabase Storage for provider profile photos and prescription documents
- Existing product catalog for pharmacy inventory

**Testing**:
- Vitest for SvelteKit components and integration tests
- Flutter/Dart testing framework for medic app backend (separate repository)
- Playwright for end-to-end storefront flows
- Manual testing for Agora video/audio quality

**Target Platform**:
- Web (SvelteKit storefront - patient/customer-facing)
- Mobile (Flutter kemani_medic app with backend API - provider-facing, separate repository)

**Project Type**: Monorepo web application (SvelteKit storefront) + separate Flutter app with backend

**Performance Goals**:
- Chat message latency < 2 seconds (SC-003)
- Video/audio quality 480p minimum for 95% sessions (SC-002)
- Consultation history load < 3 seconds (SC-009)
- Support 50 concurrent video/audio consultations (SC-008)
- Booking flow completion < 5 minutes (SC-001)
- Branding continuity maintained 100% of consultations (SC-014)

**Constraints**:
- Feature restricted to pharmacy & diagnostic centre business types only
- Paid subscription plans only (enforce via subscription management system)
- Healthcare data privacy compliance (HIPAA/GDPR equivalents)
- Transport-level encryption (HTTPS/TLS + Agora encryption) + at-rest database encryption
- Multi-tenancy via Supabase RLS (tenant_id isolation)
- Commission calculated at completion but payment captured at booking
- **URL Routing**: Multi-domain branding continuity based on entry point (storefront vs medic clinic vs direct)

**Scale/Scope**:
- Country-wide provider pool (hundreds to thousands of providers per country)
- Support for 4 consultation types across 2 business types
- 8 new database entities with complex relationships
- ~12-15 new API routes for storefront (this repo)
- ~10-15 new API routes for Flutter admin (provider management, separate repo)
- Integration with existing payment gateway per tenant
- 90-day prescription lifecycle management
- Three referral patterns for commission tracking (storefront, medic_clinic, direct)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Principle I: TypeScript & Type Safety ✅ PASS
- All code will use TypeScript strict mode
- Agora SDK types from `@types/agora-rtc-sdk-ng`
- Supabase generated types from database schema
- Zod schemas for API validation (consultations, prescriptions, availability)

### Principle II: Component Architecture ✅ PASS
- Server Components default in SvelteKit (+page.server.ts for data loading)
- Client Components only for Agora video/audio UI and real-time chat
- Provider directory components in `apps/storefront/src/lib/components/healthcare/`
- Consultation UI components scoped per type (chat, video, audio, office-visit)

### Principle III: Testing Strategy (RECOMMENDED) ⚠️ FLEXIBLE
- Integration tests for critical paths: booking flow, payment, prescription issuance
- E2E tests for video/audio call join flow
- Unit tests for commission calculation logic (financial accuracy critical)
- Agora quality testing manual (network variability)

### Principle IV: Performance Standards ✅ PASS
- Lazy load Agora SDK only when joining video/audio consultation
- Image optimization for provider profile photos via SvelteKit image optimization
- Chat message pagination to avoid large payload
- Provider directory pagination (20-50 providers per page)
- Success criteria align with Core Web Vitals

### Principle V: User Experience ✅ PASS
- Real-time chat feedback (typing indicators, message delivery status)
- Loading states for consultation booking, payment processing
- Clear error messages for payment failures, network issues
- Visual countdown for video/audio duration (5-minute warning + grace period)
- Accessibility for provider profiles and booking forms
- **Branding continuity**: Customer never leaves referring domain/branding context

### Principle VI: Security & Data Privacy ✅ PASS
- Server-side validation for all consultation booking, prescription issuance
- Agora tokens generated server-side (secure RTC access)
- HTTPS/TLS for all communications
- Supabase RLS for multi-tenant data isolation (patient can only see own consultations)
- No sensitive data in client-side logs
- Prescription data encrypted at rest

### Principle VII: Accessibility Standards ✅ PASS
- Keyboard navigation for provider directory, booking forms
- Screen reader support for consultation status, prescription details
- ARIA labels for video/audio controls
- Color not sole indicator for consultation status (pending/in-progress/completed)
- Alt text for provider profile photos

### Gates Status: ✅ ALL PASS
No constitutional violations. Implementation can proceed to Phase 0.

## Project Structure

### Documentation (this feature)

```text
specs/003-healthcare-consultations/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (technical decisions)
├── data-model.md        # Phase 1 output (database schema)
├── quickstart.md        # Phase 1 output (implementation guide)
├── contracts/           # Phase 1 output (API specifications)
│   ├── storefront-api.md          # SvelteKit storefront API (patient-facing, this repo)
│   └── admin-api.md               # Flutter medic app backend API spec (provider-facing, separate repo)
├── medic-admin-dashboard.md       # Flutter admin dashboard feature spec
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
# SvelteKit Storefront (Customer-facing)
apps/storefront/
├── src/
│   ├── routes/
│   │   ├── healthcare/                      # Healthcare feature routes
│   │   │   ├── providers/                   # Provider directory
│   │   │   │   ├── +page.svelte            # Directory listing
│   │   │   │   ├── +page.server.ts         # Load providers from API
│   │   │   │   └── [id]/                   # Provider detail page
│   │   │   │       ├── +page.svelte
│   │   │   │       └── +page.server.ts
│   │   │   ├── consultations/              # Consultation management
│   │   │   │   ├── +page.svelte            # Consultation history
│   │   │   │   ├── +page.server.ts
│   │   │   │   ├── chat/[id]/              # Chat consultation UI
│   │   │   │   │   ├── +page.svelte        # (Client Component for real-time)
│   │   │   │   │   └── +page.server.ts
│   │   │   │   ├── video/[id]/             # Video consultation UI
│   │   │   │   │   ├── +page.svelte        # (Client Component for Agora)
│   │   │   │   │   └── +page.server.ts
│   │   │   │   └── office/[id]/            # Office visit details
│   │   │   │       ├── +page.svelte
│   │   │   │       └── +page.server.ts
│   │   │   ├── prescriptions/              # Prescription management
│   │   │   │   ├── +page.svelte            # Prescription history
│   │   │   │   ├── +page.server.ts
│   │   │   │   └── [id]/                   # Prescription detail
│   │   │   │       ├── +page.svelte
│   │   │   │       └── +page.server.ts
│   │   │   └── api/                        # Storefront API routes
│   │   │       ├── providers/              # Provider listing/details
│   │   │       ├── consultations/          # Booking, status updates
│   │   │       ├── chat/                   # Real-time messaging endpoints
│   │   │       ├── prescriptions/          # Prescription CRUD
│   │   │       ├── availability/           # Provider availability slots
│   │   │       └── favorites/              # Favorite providers
│   ├── lib/
│   │   ├── components/
│   │   │   └── healthcare/                 # Healthcare-specific components
│   │   │       ├── ProviderCard.svelte
│   │   │       ├── ProviderProfile.svelte
│   │   │       ├── ConsultationBooking.svelte
│   │   │       ├── ChatInterface.svelte    # (Client Component)
│   │   │       ├── VideoRoom.svelte        # (Client Component - Agora)
│   │   │       ├── PrescriptionView.svelte
│   │   │       └── AvailabilityCalendar.svelte
│   │   ├── stores/
│   │   │   └── healthcare.ts               # Svelte stores for consultation state
│   │   ├── services/
│   │   │   ├── agora.ts                    # Agora SDK integration
│   │   │   ├── consultations.ts            # Consultation API client
│   │   │   └── prescriptions.ts            # Prescription API client
│   │   ├── middleware/
│   │   │   └── healthcare-access.ts        # Subscription + business type checks
│   │   └── types/
│   │       └── healthcare.ts               # TypeScript types for healthcare entities
│   └── tests/
│       └── healthcare/                     # Feature-specific tests

# Database Migrations (shared across all apps)
supabase/migrations/
└── [timestamp]_healthcare_consultation.sql # Schema for all 8 healthcare entities
```

**Structure Decision**: This monorepo contains the SvelteKit customer-facing storefront. The Flutter kemani_medic app (separate repository) handles its own backend API at `/api/medic/*`. Healthcare feature spans both:
- **Storefront (this repo)**: Patient-facing provider directory, booking, consultations, prescriptions
- **Flutter App (separate repo)**: Provider-facing app with backend API for consultation management, prescription issuance, availability management

**URL Routing Architecture**:
- **Storefront referral**: `store.fokz.com/healthcare/*` (all healthcare workflows within storefront domain)
- **Medic clinic referral** (Growth+ Doctor List): `medic.kemani.com/c/dr-kate/*` or custom domain (all healthcare workflows within medic domain)
- **Direct medic access**: Medic's own domain, no referral commission

Shared Supabase database schema ensures data consistency between both applications. Agora integration happens in both (storefront web SDK for patients, Flutter SDK + backend token generation for providers).

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

No constitutional violations. This section is not applicable.
