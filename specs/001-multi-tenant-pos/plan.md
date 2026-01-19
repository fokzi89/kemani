# Implementation Plan: Multi-Tenant POS-First Super App Platform

**Branch**: `001-multi-tenant-pos` | **Date**: 2026-01-18 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-multi-tenant-pos/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

A comprehensive offline-first Point-of-Sale (POS) system with multi-tenant architecture supporting independent businesses (pharmacies, supermarkets, grocery shops, restaurants) across Nigeria. The platform combines in-store POS functionality with online marketplace capabilities, delivery management, e-commerce integrations, and customer relationship tools. Built as a Progressive Web App (PWA) targeting low-end Android devices with unreliable internet connectivity.

**Key Technical Approach**:
- **Offline-first architecture** using PowerSync + SQLite for paid tiers (Basic, Growth, Enterprise) enabling full POS functionality without internet
- **Cloud-only architecture** for Free tier using direct Supabase writes with IndexedDB caching to reduce infrastructure costs
- **Multi-tenant isolation** enforced through Supabase Row Level Security (RLS) policies
- **Multi-branch support** allowing tenant companies to manage multiple physical locations with independent inventory
- **Tiered subscription model** (Free, Basic, Growth, Enterprise) with feature gating and usage limits

## Technical Context

**Language/Version**: TypeScript 5.x with strict mode enabled (ES2017 target)
**Framework**: Next.js 16 (App Router) with React 19
**Primary Dependencies**:
- Supabase (PostgreSQL backend, authentication, real-time, storage)
- PowerSync (offline-first sync for paid tiers)
- SQLite/IndexedDB (client-side persistence)
- Tailwind CSS 4 (styling)
- Zod (runtime validation)

**Storage**:
- **Cloud**: Supabase PostgreSQL with RLS for multi-tenant isolation, date-range partitioning for scalability
- **Local**: SQLite (via PowerSync) for paid tiers, IndexedDB for Free tier caching
- **File Storage**: Supabase Storage for logos, product images, receipts, proof of delivery

**Testing**: Jest + React Testing Library (recommended but not mandatory per constitution)

**Target Platform**:
- Progressive Web App (PWA) optimized for low-end Android devices (minimum 2GB RAM, Android 8.0+)
- Web browsers: Chrome 90+, Firefox 88+, Safari 14+, Edge 90+
- WebAuthn support for passkey authentication

**Project Type**: Web application (Next.js App Router SPA/SSR hybrid)

**Performance Goals**:
- PWA loads < 5 seconds on low-end Android over 3G
- Offline POS transactions complete < 2 seconds (paid tiers)
- Online transactions complete < 3 seconds (Free tier)
- Cloud sync: 100 offline transactions within 2 minutes
- Core Web Vitals: LCP < 2.5s, FID < 100ms, CLS < 0.1
- Staff passkey authentication < 3 seconds with 95% first-attempt success

**Constraints**:
- Nigeria-first UX (optimized for Nigerian market, payment gateways, mobile-first)
- Low bandwidth tolerance (minimal data usage, aggressive caching)
- Intermittent connectivity (not 100% offline forever, but periodic sync required)
- 99.5% uptime during business hours (6 AM - 10 PM WAT)
- Free tier requires internet for transactions (cloud-only to reduce PowerSync costs)
- Support SLAs apply only during business hours (8 AM - 6 PM WAT, Monday-Friday)

**Scale/Scope**:
- Target: 10,000 tenants within 24 months
- Target: 1M transactions/month
- Indefinite data retention with archival strategy (hot: < 2 years, cold: ≥ 2 years)
- 4 subscription tiers with distinct feature sets and limits
- Multi-branch support (Free: 1, Basic: 2, Growth: 5, Enterprise: unlimited)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### ✅ I. TypeScript & Type Safety
**Status**: COMPLIANT
- TypeScript strict mode enabled in `tsconfig.json`
- All React components will have explicit prop type definitions
- Zod schemas for runtime validation at system boundaries
- Type `any` prohibited except for untyped third-party libraries (will be documented)

### ✅ II. Component Architecture
**Status**: COMPLIANT
- Server Components as default (Next.js 16 App Router)
- Client Components (`'use client'`) only for interactive elements (forms, real-time updates, offline sync UI)
- Single Responsibility Principle enforced
- Shared components in `app/components/`, page-specific colocated with pages

### ⚠️ III. Testing Strategy (RECOMMENDED)
**Status**: COMPLIANT (flexible approach)
- TDD recommended but not mandatory per constitution
- Critical paths will have test coverage: authentication, sales transactions, inventory sync, payment processing
- Integration tests prioritized over unit tests
- Test files colocated with source using `.test.ts` / `.test.tsx`

### ✅ IV. Performance Standards
**Status**: COMPLIANT
- Core Web Vitals targets aligned with constitution
- Next.js Image component for all images
- Dynamic imports for heavy components (charts, analytics, chat)
- JavaScript bundle target: < 200KB gzipped per route
- PWA optimized for low-end devices and 3G connectivity

### ✅ V. User Experience
**Status**: COMPLIANT
- Interactive feedback < 100ms
- Form validation on blur with clear error messages
- Loading states for operations > 200ms
- Offline indicators showing connectivity status
- Nigeria-first UX with clear, actionable text

### ✅ VI. Security & Data Privacy
**Status**: COMPLIANT
- Client + server validation on all inputs (Zod schemas)
- Supabase RLS policies for multi-tenant isolation
- HTTP-only cookies for authentication tokens
- API calls from Server Components or Route Handlers only
- No sensitive data in client-side code or logs
- NDPR (Nigeria Data Protection Regulation) compliance for customer data deletion

### ✅ VII. Accessibility Standards
**Status**: COMPLIANT
- Keyboard navigation for all interactive elements
- ARIA attributes for complex UI (delivery tracking, inventory management)
- Semantic heading hierarchy
- Alt text for all images
- Form labels associated with inputs
- Screen reader testing for critical flows

### Constitution Compliance Summary

**Overall Status**: ✅ **PASSED** - All principles satisfied

No violations requiring justification. The architecture aligns with all constitutional principles:
- TypeScript strict mode throughout
- Server-first component architecture leveraging Next.js 16
- Flexible testing approach (tests recommended for critical paths)
- Performance optimizations for low-end devices and poor connectivity
- Security-first design with RLS, passkeys, and NDPR compliance
- Accessibility built-in from the start

## Project Structure

### Documentation (this feature)

```text
specs/001-multi-tenant-pos/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
│   ├── api-endpoints.md
│   ├── sync-protocol.md
│   └── webhooks.md
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
app/                                    # Next.js 16 App Router
├── (auth)/                             # Auth route group
│   ├── login/
│   ├── register/
│   └── layout.tsx
├── (dashboard)/                        # Authenticated routes
│   ├── layout.tsx                      # Tenant/branch selector, navigation
│   ├── pos/                            # POS interface
│   │   ├── page.tsx                    # Main POS screen (Client Component for offline)
│   │   └── components/                 # Cart, product search, payment
│   ├── inventory/
│   │   ├── page.tsx
│   │   ├── products/
│   │   ├── expiry-alerts/
│   │   └── transfers/
│   ├── customers/
│   │   ├── page.tsx
│   │   ├── loyalty/
│   │   └── orders/
│   ├── orders/
│   ├── delivery/
│   ├── analytics/
│   ├── staff/
│   ├── settings/
│   │   ├── branding/
│   │   ├── integrations/
│   │   ├── delivery-fees/             # Merchant delivery fee config
│   │   └── branches/
│   └── support/
├── (marketplace)/                      # Public storefront routes
│   ├── [tenantSlug]/
│   │   └── [branchSlug]/               # Branch-level storefronts
│   │       ├── page.tsx
│   │       ├── products/[id]/
│   │       ├── cart/
│   │       ├── checkout/
│   │       └── chat/                   # Live agent or AI chat
│   └── track/[orderId]/                # Public order tracking
├── (landing)/                          # Marketing website
│   ├── page.tsx                        # Landing page
│   ├── pricing/                        # Pricing tiers
│   ├── features/
│   └── about/
├── api/                                # Route Handlers (Server-side API)
│   ├── auth/
│   ├── sync/                           # PowerSync integration
│   ├── webhooks/
│   │   ├── paystack/
│   │   ├── whatsapp/
│   │   └── ecommerce/
│   ├── support/                        # Support ticket system
│   └── admin/                          # Platform admin endpoints
├── components/                         # Shared components
│   ├── ui/                             # Shadcn UI components (buttons, forms, etc.)
│   ├── pos/                            # Reusable POS components
│   ├── charts/                         # Analytics visualizations
│   └── layout/                         # Navigation, headers, footers
├── lib/                                # Utility libraries
│   ├── supabase/                       # Supabase client (server & client)
│   ├── powersync/                      # PowerSync configuration
│   ├── db/                             # Database utilities, migrations
│   ├── auth/                           # Authentication helpers, passkey setup
│   ├── validation/                     # Zod schemas
│   ├── sync/                           # Offline sync logic
│   └── utils/                          # General utilities
├── types/                              # TypeScript type definitions
│   ├── database.ts                     # Generated from Supabase schema
│   ├── models.ts                       # Business entity types
│   └── api.ts                          # API request/response types
├── hooks/                              # React hooks
│   ├── useSync.ts                      # Sync status monitoring
│   ├── useOffline.ts                   # Offline detection
│   ├── useAuth.ts                      # Authentication state
│   └── useTenant.ts                    # Current tenant/branch context
├── globals.css                         # Global styles, Tailwind directives
└── layout.tsx                          # Root layout with fonts, metadata

supabase/
├── migrations/                         # SQL migration files
│   ├── 001_initial_schema.sql
│   ├── 002_rls_policies.sql
│   ├── 003_partitioning.sql
│   └── ...
├── functions/                          # Edge Functions
│   ├── process-webhook/
│   ├── sync-ecommerce/
│   └── send-notifications/
└── seed.sql                            # Seed data for development

public/
├── service-worker.js                   # PWA service worker
├── manifest.json                       # PWA manifest
├── icons/                              # App icons
└── offline.html                        # Offline fallback page

__tests__/                              # Test files (if TDD approach taken)
├── integration/
│   ├── auth.test.ts
│   ├── sales.test.ts
│   └── sync.test.ts
└── e2e/
    └── critical-paths.test.ts

.specify/                               # SpecKit workflow
├── memory/
│   └── constitution.md
├── templates/
└── scripts/

.claude/                                # Claude Code configuration
├── settings.local.json                 # Supabase MCP server config
└── commands/                           # Custom skills
```

**Structure Decision**: Web application structure chosen based on Next.js 16 App Router. The app follows a route-group organization pattern:
- `(auth)`: Unauthenticated routes (login, register)
- `(dashboard)`: Authenticated tenant/branch management routes
- `(marketplace)`: Public-facing storefronts for customers
- `(landing)`: Marketing website and pricing pages

This structure supports Server Components by default with selective Client Components for offline-first POS functionality and real-time features. The `lib/` directory centralizes Supabase, PowerSync, and sync logic for reuse across components.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

*No violations identified. All constitutional principles are satisfied by the proposed architecture.*
