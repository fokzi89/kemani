# Implementation Plan: Multi-Tenant POS-First Super App Platform

**Branch**: `001-multi-tenant-pos` | **Date**: 2026-01-24 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-multi-tenant-pos/spec.md`

## Summary

A comprehensive multi-tenant POS-first platform for independent Nigerian businesses (pharmacies, supermarkets, grocery shops, mini-marts) featuring offline-first architecture with cloud sync, marketplace storefronts, delivery management, e-commerce integrations, AI chat agent, and business analytics. The platform prioritizes reliability in low-connectivity environments using Progressive Web App architecture with SQLite local storage syncing to Supabase backend.

**Core Value**: Enable reliable POS operations offline with automatic cloud sync, extend to online marketplace, and provide comprehensive business management tools.

## Technical Context

**Language/Version**: TypeScript (strict mode), Next.js 16 (App Router), React 19
**Primary Dependencies**: Supabase (PostgreSQL, Auth, Realtime, Storage), SQLite/IndexedDB for offline, Tailwind CSS 4
**Storage**: Dual-layer - Supabase PostgreSQL (cloud), SQLite/IndexedDB (offline local storage)
**Testing**: NEEDS CLARIFICATION (Vitest, Jest, Playwright, or other testing frameworks)
**Target Platform**: Progressive Web App (PWA), optimized for low-end Android devices (2GB RAM, Android 8.0+, 3G connectivity)
**Project Type**: Web application (Next.js App Router with frontend and API routes)
**Performance Goals**:
- PWA loads in <5 seconds on 3G/low-end Android
- Offline transactions complete in <2 seconds
- Analytics dashboards load in <3 seconds
- Cloud sync of 100 transactions in <2 minutes
- API responses <500ms (p90) when online

**Constraints**:
- Offline-first architecture (all core POS features work without internet)
- Multi-tenant data isolation (zero cross-tenant data leaks)
- Email/password or Google Sign-In authentication (no phone OTP)
  - Country selection, phone code (dial code), and currency selection during onboarding
  - Support low-end devices (2GB RAM, 3G)
- Initial JavaScript bundle <200KB gzipped per route (constitutional requirement)
- Core Web Vitals: LCP <2.5s, FID <100ms, CLS <0.1

**Scale/Scope**:
- Target 10,000 tenants within 24 months
- 1M transactions/month capacity
- 200 concurrent tenants with 5-10 active users each (1,000-2,000 total concurrent users)
- Product catalogs up to 10,000 items per tenant
- Multi-phase rollout (5 phases: Core POS → Customers/Orders → Delivery → Integrations/AI → Analytics/Payments)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Core Principles Compliance

✅ **I. TypeScript & Type Safety**
- All code will use TypeScript strict mode (already configured in tsconfig.json)
- No `any` types except for third-party library interfaces (with documentation)
- All React components will have explicit prop type definitions
- Server Components and Client Components properly typed and distinguished

✅ **II. Component Architecture**
- Server Components default; Client Components (`'use client'`) scoped narrowly for interactivity
- Single Responsibility Principle for all components
- Shared components in `app/components/`, page-specific components colocated
- One default export per component file matching filename

✅ **III. Testing Strategy (RECOMMENDED)**
- TDD recommended but not mandatory - team will decide per-feature
- When tests are written, integration tests prioritized over unit tests
- Critical paths MUST have test coverage: authentication, data mutations, offline sync, payment flows
- NEEDS CLARIFICATION: Choose testing framework (Vitest vs Jest) and E2E tool (Playwright vs Cypress)

✅ **IV. Performance Standards**
- Core Web Vitals targets: LCP <2.5s, FID <100ms, CLS <0.1
- JavaScript bundles <200KB gzipped per route
- Next.js Image component for all images with proper sizing and lazy loading
- Dynamic imports for heavy components (analytics dashboards, charts, file uploads)
- Third-party scripts (payment gateways, chat, analytics) via Next.js Script component

✅ **V. User Experience**
- Visual feedback within 100ms for all interactions
- Form validation on blur with clear error messages
- Loading states for operations >200ms (especially sync operations)
- Instant navigation using Next.js Link with prefetching
- Clear, actionable user-facing text (especially important for Nigeria market UX)

✅ **VI. Security & Data Privacy**
- All input validated client AND server (Zod schema validation)
- Sensitive data NEVER logged or in client code
- Authentication tokens in HTTP-only cookies (Supabase Auth handles this)
- External API calls from Server Components or Route Handlers only
- Explicit CORS configuration (no wildcard in production)
- Supabase Row Level Security (RLS) for multi-tenant isolation

✅ **VII. Accessibility Standards**
- All interactive elements keyboard accessible
- Color not sole information conveyor
- Descriptive alt text for images
- Associated labels for form inputs
- Semantic heading hierarchy
- ARIA attributes used correctly
- Screen reader navigation support

### Quality Gates

All code must pass before merge:
- ✅ Type checking: `npx tsc --noEmit` (zero errors)
- ✅ Linting: `npm run lint` (zero errors, minimal warnings)
- ✅ Build: `npm run build` (successful production build)
- ✅ Tests (if present): All pass, new tests for new functionality

### Development Workflow

- ✅ Feature branch: `001-multi-tenant-pos` (already created)
- ✅ Pull requests required with clear descriptions and spec references
- ✅ Code reviews verify constitutional compliance
- ✅ No direct commits to master

### Constitutional Compliance: PASS ✅

All constitutional principles align with this feature. No violations requiring justification. One clarification needed: testing framework selection (addressed in Phase 0 research).

---

## Post-Design Constitution Re-Check

*Re-evaluated after Phase 1 design completion (data-model.md, contracts/, quickstart.md)*

### Design Artifacts Review

✅ **TypeScript & Type Safety**
- data-model.md defines all entities with strict types (enums, constraints)
- openapi.yaml includes detailed schemas with validation rules
- All API contracts specify TypeScript-compatible types
- No `any` types in design

✅ **Component Architecture**
- Project structure separates Server Components (default) from Client Components
- App Router route groups follow SRP (`(auth)/`, `(dashboard)/`, `(marketplace)/`)
- API routes organized by domain for maintainability

✅ **Testing Strategy (RECOMMENDED)**
- research.md confirms Vitest + Playwright selection
- Testing framework aligns with constitution (recommended, not mandatory)
- Critical paths identified: auth, offline sync, payment flows
- quickstart.md includes testing workflows

✅ **Performance Standards**
- research.md addresses bundle size (Dexie.js 20KB, Recharts 90KB)
- Dynamic imports planned for heavy components (analytics, charts)
- IndexedDB strategy optimizes offline performance
- Service Worker (Workbox) implements caching strategies

✅ **User Experience**
- API contracts include proper error responses (400, 401, 403, 404, 409, 500)
- Validation schemas for forms (React Hook Form + Zod)
- Real-time sync status via Supabase Realtime
- Clear error messages in API design

✅ **Security & Data Privacy**
- data-model.md implements RLS policies for all tenant-scoped tables
- Authentication flows use email/password or Google OAuth via Supabase Auth (secure, no OTP)
- Webhook signature verification documented
- No sensitive data in client-side schemas
- All API endpoints require authentication (except public marketplace)

✅ **Accessibility Standards**
- Not directly testable in design phase
- quickstart.md references constitutional accessibility requirements
- To be enforced during implementation

### Final Compliance Status: PASS ✅

**Summary**: All design artifacts (research.md, data-model.md, contracts/, quickstart.md) fully comply with constitutional principles. No violations or complexity justifications needed. Ready for Phase 2: Task Generation (`/speckit.tasks`).

**Testing Clarification Resolved**: Vitest + Playwright selected per constitutional flexibility (testing recommended, not mandatory).

---

## Project Structure

### Documentation (this feature)

```text
specs/001-multi-tenant-pos/
├── spec.md              # Feature specification (/speckit.specify output)
├── plan.md              # This file (/speckit.plan output)
├── research.md          # Phase 0 research findings (generated below)
├── data-model.md        # Phase 1 data model (generated below)
├── quickstart.md        # Phase 1 developer quickstart (generated below)
├── contracts/           # Phase 1 API contracts (generated below)
│   ├── openapi.yaml     # OpenAPI 3.0 specification
│   └── webhooks.md      # Webhook documentation
└── tasks.md             # Phase 2 tasks (/speckit.tasks command - NOT created yet)
```

### Source Code (repository root)

```text
# Next.js 16 App Router structure (web application)

app/
├── (auth)/              # Auth route group
│   ├── login/           # Email/password + Google Sign-In
│   ├── register/        # Email/password + Google Sign-In
│   └── auth-callback/   # Google OAuth callback handler
├── (dashboard)/         # Dashboard route group (authenticated)
│   ├── layout.tsx       # Dashboard layout with navigation
│   ├── page.tsx         # Dashboard home
│   ├── pos/             # POS interface
│   ├── inventory/       # Inventory management
│   ├── orders/          # Order management
│   ├── customers/       # Customer management
│   ├── staff/           # Staff management
│   ├── delivery/        # Delivery management
│   ├── analytics/       # Analytics dashboards
│   ├── settings/        # Tenant settings
│   └── integrations/    # E-commerce, WhatsApp integrations
├── (marketplace)/       # Public marketplace route group
│   └── [tenantSlug]/    # Dynamic tenant storefronts
├── api/                 # API routes
│   ├── auth/            # Auth endpoints (email/Google OAuth callback)
│   ├── pos/             # POS operations
│   ├── sync/            # Offline sync endpoints
│   ├── webhooks/        # Webhook handlers (payments, platforms)
│   └── chat/            # AI chat agent endpoints
├── components/          # Shared components
│   ├── ui/              # UI primitives (buttons, forms, modals)
│   ├── pos/             # POS-specific components
│   ├── marketplace/     # Marketplace components
│   └── analytics/       # Analytics/chart components
├── layout.tsx           # Root layout
├── page.tsx             # Landing page
└── globals.css          # Global styles

lib/
├── auth/                # Authentication utilities
│   ├── google.ts        # Google OAuth helpers
│   └── session.ts       # Session management with tenant/country/currency context
├── db/                  # Database utilities
│   ├── supabase.ts      # Supabase client
│   ├── offline.ts       # SQLite/IndexedDB client
│   └── sync.ts          # Sync engine
├── integrations/        # Third-party integrations
│   ├── woocommerce.ts   # WooCommerce sync
│   ├── shopify.ts       # Shopify sync
│   ├── whatsapp.ts      # WhatsApp Business API
│   └── payments.ts      # Paystack/Flutterwave
├── offline/             # Offline-first utilities
│   ├── storage.ts       # Local storage abstraction
│   ├── queue.ts         # Sync queue management
│   └── conflict.ts      # Conflict resolution
└── utils/               # General utilities
    ├── validation.ts    # Zod schemas
    ├── formatting.ts    # Number, date, currency formatting
    └── errors.ts        # Error handling

types/
├── database.types.ts    # Supabase generated types
├── api.types.ts         # API request/response types
└── models.types.ts      # Domain model types

public/
├── sw.js                # Service Worker for PWA
└── manifest.json        # PWA manifest

tests/
├── integration/         # Integration tests
│   ├── auth.test.ts
│   ├── pos.test.ts
│   ├── sync.test.ts
│   └── offline.test.ts
├── e2e/                 # End-to-end tests
│   ├── pos-flow.spec.ts
│   ├── marketplace.spec.ts
│   └── offline.spec.ts
└── unit/                # Unit tests
    ├── utils/
    ├── sync/
    └── integrations/
```

**Structure Decision**: Next.js 16 App Router web application structure. App directory uses route groups for logical organization (auth, dashboard, marketplace). API routes colocated in `app/api/`. Shared business logic in `lib/`. Component library in `app/components/`. This structure leverages Next.js Server Components by default with selective Client Components for interactivity (POS interface, real-time sync status).

## Complexity Tracking

> No constitutional violations requiring justification. This section intentionally left empty.
