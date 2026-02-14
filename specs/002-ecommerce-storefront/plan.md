# Implementation Plan: Ecommerce Storefront for Tenant Branches

**Branch**: `002-ecommerce-storefront` | **Date**: 2026-02-11 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/002-ecommerce-storefront/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Build a complete ecommerce storefront for tenant branches with customer-facing product browsing, shopping cart, checkout with Paystack payment integration, and live chat support with rich media attachments. Supports three subscription tiers (Free, Growth, Business) with graduated feature access. Customers can authenticate via Google/Apple or checkout as guests. Business plan includes AI agent with image recognition. Four delivery methods (Self Pick Up, Bicycle, Motor Bike, Platform) with standardized fees (N100 transaction + N100 delivery addition).

## Technical Context

**Language/Version**: TypeScript 5.x with SvelteKit (storefront), existing Next.js 16 (admin/POS)
**Primary Dependencies**: SvelteKit 2.x, Supabase Client, Paystack JS SDK, OAuth libraries (google-auth-library, apple-signin-auth), WebSocket/Socket.io (live chat), NEEDS CLARIFICATION: AI agent service API/SDK
**Storage**: Supabase PostgreSQL (products, orders, customers, chat sessions), Supabase Storage (chat attachments: images, voice, PDFs)
**Testing**: Vitest (unit), Playwright (E2E for checkout flows), RECOMMENDED: Integration tests for payment callbacks
**Target Platform**: Web (desktop + mobile responsive), deployed as separate SvelteKit app or embedded in existing Next.js via iframe/subdomain
**Project Type**: Web application (storefront frontend + backend API routes in SvelteKit)
**Performance Goals**: <3s page load, <1s product search response, <2s delivery fee calculation, <5s chat attachment upload
**Constraints**: Core Web Vitals compliance (LCP <2.5s, FID <100ms, CLS <0.1), mobile-first responsive design, 200KB JS bundle per route
**Scale/Scope**: Support 1000+ products per branch, 100+ concurrent customers, 50+ concurrent chat sessions (Business plan), 10k+ orders/month per tenant

**Architecture Decision Required**:
- **NEEDS CLARIFICATION**: Integration approach with existing Next.js app
  - Option A: Separate SvelteKit app on subdomain (e.g., `store.tenant.com` or `tenant.store.example.com`)
  - Option B: Embedded iframe in existing Next.js tenant pages
  - Option C: Migration path - build in Next.js now, migrate to SvelteKit later
  - **Recommendation**: Option A (separate subdomain) for clean separation, independent deployment, better performance isolation

**External Integrations**:
- Paystack payment gateway (initialization, callbacks, webhooks)
- Google OAuth 2.0 (customer authentication)
- Apple Sign In (customer authentication)
- NEEDS CLARIFICATION: AI agent service provider (OpenAI, Anthropic, custom) for Business plan image recognition
- NEEDS CLARIFICATION: Third-party platform delivery API for inter-city logistics
- NEEDS CLARIFICATION: SMS/Email notification service for order confirmations

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Type Safety ✅
- TypeScript strict mode enabled for SvelteKit storefront
- All components will have explicit prop types
- Supabase types generated from database schema
- **Action**: Generate TypeScript types from Supabase schema for storefront entities

### Component Architecture ⚠️
- SvelteKit components follow single responsibility principle
- Server-side rendering by default (SvelteKit SSR)
- Client-side interactivity scoped to necessary components (cart, chat, search)
- **Clarification Needed**: Shared component strategy between Next.js admin and SvelteKit storefront (if any)
- **Decision**: Treat storefront as independent app, no shared UI components initially

### Testing Strategy ✅ RECOMMENDED
- Critical paths MUST have test coverage: checkout flow, payment callbacks, cart management
- Integration tests for Paystack payment success/failure scenarios
- E2E tests for complete customer journeys (guest checkout, authenticated checkout)
- **Action**: TDD recommended for payment integration and cart logic

### Performance Standards ✅
- Meet Core Web Vitals: LCP <2.5s, FID <100ms, CLS <0.1
- Image optimization using SvelteKit's image handling or external CDN
- Lazy loading for chat interface, product images
- Code splitting per route
- **Action**: Bundle size monitoring, lighthouse audits in CI

### User Experience ✅
- Real-time product search with <1s response
- Visual feedback on all interactions (<100ms)
- Loading states for async operations (payment redirect, chat uploads)
- Clear error messages for validation, payment failures
- **Action**: Design system for consistent UX across storefront

### Security & Data Privacy ✅
- Server-side validation for all user inputs (delivery info, search queries)
- Paystack secret keys stored in environment variables (server-side only)
- OAuth tokens in HTTP-only cookies
- Supabase RLS policies for customer data isolation per tenant
- Chat attachments access controlled (only participants)
- **Action**: Security audit for payment flow, file upload validation

### Accessibility Standards ✅
- Keyboard navigation for product browsing, cart, checkout
- Screen reader support for all interactive elements
- Form labels and ARIA attributes
- Color contrast compliance
- **Action**: Accessibility testing with screen readers

### Violations Requiring Justification

None identified. Architecture aligns with constitution principles.

## Project Structure

### Documentation (this feature)

```text
specs/002-ecommerce-storefront/
├── plan.md              # This file
├── research.md          # Phase 0 output (technical decisions)
├── data-model.md        # Phase 1 output (database schema)
├── quickstart.md        # Phase 1 output (setup guide)
├── contracts/           # Phase 1 output (API contracts)
│   ├── storefront-api.yaml      # Product, cart, checkout endpoints
│   ├── payment-webhooks.yaml    # Paystack callback schemas
│   └── chat-api.yaml            # Live chat WebSocket/REST API
└── tasks.md             # Phase 2 output (/speckit.tasks - NOT created yet)
```

### Source Code (repository root)

**Architecture Decision**: Separate SvelteKit application for storefront

```text
# Option 1: Separate SvelteKit App (RECOMMENDED)
apps/storefront/              # New SvelteKit app
├── src/
│   ├── routes/
│   │   ├── +layout.svelte           # Root layout
│   │   ├── +page.svelte             # Product list
│   │   ├── [slug]/+page.svelte      # Product detail
│   │   ├── cart/+page.svelte        # Shopping cart
│   │   ├── checkout/+page.svelte    # Checkout flow
│   │   ├── orders/+page.svelte      # Order history (authenticated)
│   │   └── api/
│   │       ├── products/+server.ts       # Product search/filter
│   │       ├── cart/+server.ts           # Cart management
│   │       ├── checkout/+server.ts       # Order creation
│   │       ├── payment/
│   │       │   ├── initialize/+server.ts # Paystack init
│   │       │   └── callback/+server.ts   # Paystack webhook
│   │       └── chat/
│   │           ├── +server.ts            # WebSocket chat
│   │           └── upload/+server.ts     # File attachment upload
│   ├── lib/
│   │   ├── components/
│   │   │   ├── ProductCard.svelte
│   │   │   ├── ProductGrid.svelte
│   │   │   ├── SearchBar.svelte
│   │   │   ├── Cart.svelte
│   │   │   ├── CheckoutForm.svelte
│   │   │   └── ChatWidget.svelte
│   │   ├── stores/
│   │   │   ├── cart.ts               # Cart state management
│   │   │   ├── auth.ts               # Customer auth state
│   │   │   └── chat.ts               # Chat session state
│   │   ├── services/
│   │   │   ├── supabase.ts           # Supabase client
│   │   │   ├── paystack.ts           # Paystack integration
│   │   │   ├── auth.ts               # Google/Apple OAuth
│   │   │   └── chat.ts               # Chat service (WebSocket)
│   │   └── types/
│   │       ├── product.ts
│   │       ├── order.ts
│   │       ├── customer.ts
│   │       └── chat.ts
│   └── hooks.server.ts               # Server hooks (auth, RLS)
└── tests/
    ├── unit/
    │   ├── cart.test.ts
    │   └── checkout.test.ts
    └── e2e/
        ├── guest-checkout.spec.ts
        ├── authenticated-checkout.spec.ts
        └── payment-flow.spec.ts

# Existing Next.js App (reference)
app/
├── (admin)/                     # Admin portal (existing)
├── (pos)/                       # POS system (existing)
└── api/
    └── storefront/              # Shared APIs if needed
        └── products/sync        # Product data sync to storefront DB

# Shared Libraries (if applicable)
lib/
├── pos/                         # Existing POS logic
├── supabase/                    # Existing Supabase utils
└── storefront/                  # NEW: Shared storefront utilities
    ├── delivery.ts              # Delivery fee calculation
    ├── pricing.ts               # Fee calculation (N100 + N100)
    └── plans.ts                 # Plan feature access logic

supabase/
├── migrations/
│   └── 20260211_storefront_schema.sql    # NEW: Storefront tables
└── functions/
    └── chat-ai-agent/                    # Edge function for AI agent
```

**Structure Decision**:
- **Separate SvelteKit application** in `apps/storefront/` for clean separation
- Independent deployment pipeline for storefront
- Shared database (Supabase) with RLS policies for multi-tenancy
- Shared utilities in `lib/storefront/` for delivery/pricing logic
- Edge functions for AI agent (Supabase Functions or Vercel Functions)

**Alternative Considered**: Building storefront in Next.js App Router to avoid introducing SvelteKit complexity. **Rejected because**: User explicitly specified SvelteKit, and separate framework allows storefront-specific optimizations and independent scaling.

## Complexity Tracking

No constitutional violations requiring justification.

**Complexity Notes**:
- **Multi-framework architecture** (Next.js + SvelteKit): Justified by user requirement for SvelteKit storefront and need to maintain existing Next.js admin/POS systems
- **Separate deployment**: Increases operational complexity but provides better performance isolation and independent scaling
- **Shared database**: Requires careful RLS policy management but leverages existing Supabase infrastructure

---

**Next Steps**: Execute Phase 0 (Research) to resolve NEEDS CLARIFICATION items and finalize technical decisions.
