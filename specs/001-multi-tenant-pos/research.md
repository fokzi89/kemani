# Technical Research: Multi-Tenant POS Platform

**Feature**: Multi-Tenant POS-First Super App Platform
**Branch**: `001-multi-tenant-pos`
**Research Date**: 2026-01-24

## Overview

This document consolidates technical research and decisions for implementing the multi-tenant POS platform. Each decision includes rationale, alternatives considered, and implementation guidance.

---

## 1. Testing Framework Selection

### Decision: Vitest + Playwright

**Rationale**:
- **Vitest** for unit and integration tests:
  - Native ESM support (Next.js 16 uses ESM)
  - Vite-powered for extremely fast test execution
  - Jest-compatible API (easy migration if needed)
  - Built-in TypeScript support
  - Better performance than Jest for modern codebases
  - Excellent watch mode for TDD workflow

- **Playwright** for E2E tests:
  - Multi-browser support (Chromium, Firefox, WebKit)
  - Mobile emulation for testing low-end Android devices
  - Network throttling to simulate 3G connections
  - Built-in test isolation and parallelization
  - Auto-wait for elements (more reliable than Cypress)
  - Better offline testing capabilities (critical for this project)

**Alternatives Considered**:
- **Jest + Cypress**: More mature ecosystem but slower test execution and less optimal for ESM/Next.js 16
- **Jest + Testing Library**: Good but lacks built-in browser automation for offline scenarios
- **Playwright Test only**: Could handle both unit and E2E but Vitest is better optimized for unit tests

**Implementation Notes**:
- Install: `npm install -D vitest @vitejs/plugin-react @playwright/test`
- Configure Vitest in `vitest.config.ts` with path aliases matching tsconfig.json
- Playwright config in `playwright.config.ts` with mobile device profiles for Android testing
- Test file conventions: `*.test.ts`, `*.test.tsx` for Vitest; `*.spec.ts` for Playwright

---

## 2. Offline Storage Strategy

### Decision: IndexedDB with Dexie.js wrapper

**Rationale**:
- **IndexedDB** is the W3C standard for client-side storage in browsers
- **Dexie.js** wrapper provides:
  - Promise-based API (async/await friendly)
  - Easier schema management and migrations
  - Better TypeScript support
  - Query syntax more intuitive than raw IndexedDB
  - Smaller bundle size than alternatives (~20KB gzipped)
  - Sync primitives for conflict detection
  - Works in all modern browsers and PWAs

- Meets requirements:
  - Works on low-end Android devices
  - No size limitations beyond device storage
  - Transactional writes for data integrity
  - Indexed queries for fast product/customer lookups
  - Schema versioning for migrations

**Alternatives Considered**:
- **SQL.js (SQLite compiled to WASM)**: Heavier bundle size (~500KB), slower initial load, but SQL syntax familiarity
- **PouchDB**: CouchDB-compatible, built-in sync, but larger bundle (~140KB), complex replication model
- **LocalForage**: Simple API but lacks advanced querying and transactions
- **Native SQLite**: Not available in web browsers (only in native apps)

**Implementation Notes**:
- Install: `npm install dexie dexie-react-hooks`
- Create database schema in `lib/db/offline.ts` with tables matching Supabase schema
- Use versioned migrations for schema changes
- Implement sync queue table to track pending operations
- Use Dexie's `Table.mapToClass()` for domain model binding

---

## 3. Sync Conflict Resolution Strategy

### Decision: Hybrid approach - Last-Write-Wins (LWW) with Manual Queue for Critical Conflicts

**Rationale**:
- **Last-Write-Wins (LWW)** for non-critical data:
  - Customer information (name, email, address)
  - Product descriptions, categories
  - Tenant settings (branding, configurations)
  - Simple to implement with timestamps
  - Minimal user friction

- **Operational Transformation (OT) / CRDT-like** for inventory:
  - Inventory changes are additive operations (sold 5, restocked 10)
  - Track delta operations, not absolute values
  - Replay operations in order when syncing
  - Prevents lost sales or inventory discrepancies

- **Manual Resolution Queue** for critical conflicts:
  - Duplicate transactions with different payment methods
  - Simultaneous price changes to same product
  - User role/permission conflicts
  - Queue conflicts for tenant admin review in dashboard

- Conflict detection:
  - Every record has `version` field (incremented on update)
  - `updated_at` timestamp (server authoritative)
  - `updated_by` user reference
  - `sync_status`: `synced`, `pending`, `conflict`

**Alternatives Considered**:
- **Pure LWW**: Too risky for inventory and transactions
- **Pure Manual Resolution**: Too much user friction, slows down operations
- **CRDTs everywhere**: Overly complex for this use case, larger overhead
- **Server Always Wins**: Loses offline changes, defeats offline-first goal

**Implementation Notes**:
- Implement sync engine in `lib/db/sync.ts`
- Conflict resolution logic in `lib/offline/conflict.ts`
- Admin UI for manual conflict resolution in dashboard
- Use Supabase Realtime to detect server-side changes during sync
- Log all conflict resolutions for audit trail

---

## 4. Service Worker Architecture for PWA

### Decision: Workbox with Network-First and Cache-First strategies

**Rationale**:
- **Workbox** (Google's PWA toolkit):
  - Production-ready caching strategies
  - Background sync for offline queue
  - Precaching for app shell
  - Easy integration with Next.js
  - Handles cache versioning automatically

- **Caching Strategies**:
  - **Network-First**: API calls, sync endpoints (try network, fallback to cache if offline)
  - **Cache-First**: Static assets, images, fonts (fast loading, update in background)
  - **Stale-While-Revalidate**: Product data, customer lists (show cached, update in background)
  - **Network-Only**: Authentication, OTP verification (never cache)

- **Background Sync**:
  - Queue failed API requests (sales, inventory updates)
  - Retry when connectivity restored
  - Preserve order of operations (important for transactions)

**Alternatives Considered**:
- **Custom Service Worker**: Full control but reinventing the wheel, more bugs
- **next-pwa plugin**: Easier setup but less flexibility for complex offline scenarios
- **No Service Worker**: App doesn't work offline, fails core requirement

**Implementation Notes**:
- Install: `npm install -D workbox-webpack-plugin`
- Configure in `next.config.ts` with Workbox plugin
- Service Worker in `public/sw.js` (auto-generated by Workbox)
- PWA manifest in `public/manifest.json`
- Register Service Worker in `app/layout.tsx`
- Cache strategies defined in Workbox config

---

## 5. Multi-Tenancy Implementation in Supabase

### Decision: Row Level Security (RLS) with tenant_id column in all tables

**Rationale**:
- **Supabase RLS** provides database-level multi-tenant isolation:
  - Zero cross-tenant data leaks (enforced at PostgreSQL level)
  - No application code can bypass (even if bugs exist)
  - User session automatically provides `auth.uid()` and custom `tenant_id` claim
  - Policies apply to all queries (SELECT, INSERT, UPDATE, DELETE)

- **Implementation Pattern**:
  - Every table has `tenant_id UUID` column (references `tenants.id`)
  - RLS policies: `USING (tenant_id = auth.jwt() ->> 'tenant_id')`
  - Custom JWT claims include `tenant_id` when user logs in
  - Supabase Auth hooks inject `tenant_id` into session

- **Schema Structure**:
  - `tenants` table (no RLS, platform-level access)
  - `users` table with `tenant_id` FK
  - All business tables (products, sales, customers) with `tenant_id` FK
  - Composite indexes on `(tenant_id, id)` for query performance

**Alternatives Considered**:
- **Separate databases per tenant**: Expensive, complex migrations, overkill for 10K tenants
- **Schema-per-tenant in PostgreSQL**: Better than separate DBs but still complex, harder to query across tenants (for platform analytics)
- **Application-level filtering**: Error-prone, easy to introduce cross-tenant leaks, doesn't protect against SQL injection

**Implementation Notes**:
- Create Supabase migration: `supabase migration new enable_rls`
- Enable RLS on all tables: `ALTER TABLE products ENABLE ROW LEVEL SECURITY;`
- Create policies for each table with tenant_id check
- Use Supabase Auth hooks to set `tenant_id` claim on login
- Test with multiple test tenants to verify isolation

---

## 6. OTP Delivery Service Selection

### Decision: Termii (primary) with Twilio (fallback)

**Rationale**:
- **Termii** (Nigeria-focused):
  - Local Nigerian SMS provider
  - Better delivery rates in Nigeria than global providers
  - Lower costs for Nigerian phone numbers
  - Supports Nigerian telcos (MTN, Glo, Airtel, 9mobile)
  - OTP-specific API with rate limiting built-in
  - Pricing: ₦2-3 per SMS (vs $0.04-0.08 for Twilio)

- **Twilio** (fallback):
  - Global provider with Nigeria coverage
  - More reliable API and SLA
  - Better documentation and libraries
  - Automatic fallback if Termii fails
  - Pricing: Higher but acceptable for fallback

- **Implementation**:
  - Primary: Termii API for OTP sending
  - Fallback: If Termii fails, retry with Twilio
  - Rate limiting: Max 3 OTP sends per phone number per hour (prevent abuse)
  - OTP expiry: 5 minutes
  - OTP format: 6-digit numeric code

**Alternatives Considered**:
- **Africa's Talking**: Good option but Termii has better Nigerian coverage
- **SMS Portal**: Expensive for high volume
- **Twilio only**: Higher costs, less optimized for Nigeria
- **Email-based OTP**: Not suitable for Nigeria market where phone is primary identifier

**Implementation Notes**:
- Install: `npm install termii axios`
- Environment variables: `TERMII_API_KEY`, `TERMII_SENDER_ID`, `TWILIO_ACCOUNT_SID`, `TWILIO_AUTH_TOKEN`
- Implement in `lib/auth/otp.ts` with fallback logic
- Store OTP hash (not plaintext) in database with expiry
- Rate limiting via Redis or Supabase (store attempt counts)

---

## 7. Staff Invite Email Delivery

### Decision: Resend for transactional emails

**Rationale**:
- **Resend** advantages:
  - Modern API designed for developers
  - React email template support
  - Built-in email analytics (opens, clicks)
  - Generous free tier (3,000 emails/month)
  - Excellent deliverability (partnerships with major email providers)
  - Simple integration with Next.js
  - Type-safe SDK for TypeScript

- **Email Template Strategy**:
  - Use React Email for templates (type-safe, version-controlled)
  - Staff invite template with:
    - Tenant branding (logo, colors)
    - Invite link with expiry countdown
    - Role assignment details
    - Clear CTA button
  - Responsive design for mobile viewing

**Alternatives Considered**:
- **SendGrid**: More features but complex pricing, overkill for invite emails
- **Supabase built-in SMTP**: Limited customization, no analytics
- **Postmark**: Good but more expensive than Resend
- **Nodemailer + custom SMTP**: Requires managing email infrastructure, poor deliverability

**Implementation Notes**:
- Install: `npm install resend react-email @react-email/components`
- Environment variable: `RESEND_API_KEY`
- Create email templates in `emails/` directory using React Email
- Implement send logic in `lib/integrations/email.ts`
- Track email status (sent, delivered, opened) in `staff_invites` table
- Resend email functionality for expired/bounced invites

---

## 8. Payment Gateway Integration

### Decision: Dual integration - Paystack (primary) + Flutterwave (optional)

**Rationale**:
- **Paystack**:
  - Most popular in Nigeria
  - Excellent Nigerian bank integration
  - Subscription billing built-in
  - Webhooks for payment status
  - 1.5% + ₦100 transaction fee (capped)
  - Dashboard for reconciliation

- **Flutterwave**:
  - Alternative for merchants who prefer it
  - Pan-African coverage
  - Similar features to Paystack
  - Slightly higher fees (1.4% + processing fees)

- **Implementation**:
  - Tenant can choose preferred gateway in settings
  - Platform uses Paystack for subscription billing
  - Marketplace sales use tenant's selected gateway
  - Webhook handlers for both gateways

**Alternatives Considered**:
- **Stripe**: Limited Nigeria support, complex verification
- **Paystack only**: Some merchants prefer Flutterwave, limiting options
- **Direct bank integration**: Complex regulatory compliance

**Implementation Notes**:
- Install: `npm install paystack @flutterwave/node-v3`
- Environment variables: `PAYSTACK_SECRET_KEY`, `FLUTTERWAVE_SECRET_KEY`
- Implement in `lib/integrations/payments.ts`
- Webhook endpoint: `/api/webhooks/payments`
- Store payment reference and status in database
- Verify webhook signatures for security

---

## 9. AI Chat Agent Implementation

### Decision: OpenAI GPT-4 Turbo with function calling

**Rationale**:
- **GPT-4 Turbo**:
  - Best natural language understanding for Nigerian English and pidgin
  - Function calling for structured tool use (check inventory, create order)
  - JSON mode for reliable structured output
  - Streaming responses for better UX
  - Pricing: $10/1M input tokens, $30/1M output tokens (affordable for chat)

- **Architecture**:
  - Chat endpoint: `/api/chat`
  - Functions: `checkInventory`, `createOrder`, `modifyOrder`, `cancelOrder`
  - Context injection: Product catalog, customer info, order history
  - Conversation memory: Store in database for continuity
  - Safety: Input validation, rate limiting, cost tracking per tenant

**Alternatives Considered**:
- **Anthropic Claude**: Excellent but higher latency for Nigeria (no Africa region)
- **Open-source models (Llama, Mistral)**: Lower cost but worse Nigerian English understanding, requires hosting
- **Rule-based chatbot**: Cheaper but poor UX, can't handle natural language variations

**Implementation Notes**:
- Install: `npm install openai`
- Environment variable: `OPENAI_API_KEY`
- Implement in `app/api/chat/route.ts`
- Function definitions in `lib/integrations/ai-functions.ts`
- Streaming using OpenAI SDK streaming API
- Cost tracking per tenant with usage limits
- Moderation API to filter inappropriate messages

---

## 10. E-Commerce Platform Sync

### Decision: REST API polling with webhook subscriptions where available

**Rationale**:
- **WooCommerce**:
  - REST API v3 (JSON)
  - Webhook support for real-time updates (order created, product updated)
  - OAuth 1.0a or API keys for authentication
  - Pagination for large product catalogs

- **Shopify**:
  - Admin API (GraphQL or REST)
  - Webhook subscriptions for events
  - OAuth 2.0 for authentication
  - Rate limits: 2 requests/second (standard plan)

- **Sync Strategy**:
  - **Webhooks** (preferred): Real-time sync when platform sends event
  - **Polling** (fallback): Every 5-15 minutes for platforms without webhooks
  - **Manual trigger**: Merchant can force sync anytime
  - **Conflict resolution**: Use Last-Write-Wins with timestamp comparison

**Alternatives Considered**:
- **Real-time only**: Some platforms don't support webhooks reliably
- **Polling only**: Higher latency, more API calls, rate limit risk
- **Platform-specific SDKs**: Larger bundle size, less control

**Implementation Notes**:
- WooCommerce SDK: `npm install @woocommerce/woocommerce-rest-api`
- Shopify SDK: `npm install @shopify/shopify-api`
- Webhook handlers: `/api/webhooks/woocommerce`, `/api/webhooks/shopify`
- Background jobs for polling using Vercel Cron or BullMQ
- Sync status dashboard showing last sync time and health

---

## 11. WhatsApp Business API Integration

### Decision: Use official WhatsApp Cloud API via Twilio or Meta directly

**Rationale**:
- **WhatsApp Cloud API** (Meta):
  - Official API from Meta/Facebook
  - Free for first 1,000 conversations/month
  - Template messages for notifications
  - Interactive messages (buttons, lists)
  - Requires business verification

- **Twilio WhatsApp API** (wrapper):
  - Easier onboarding than direct Meta API
  - Better documentation and support
  - Pre-approved templates
  - Costs: $0.005-0.01 per message

- **Implementation**:
  - Template messages for: Order confirmations, Delivery updates, OTP (if SMS fails)
  - Interactive buttons for order status ("View Order", "Track Delivery")
  - Message limits: Max 1 business-initiated message per 24h per user
  - Webhook for incoming messages to unified inbox

**Alternatives Considered**:
- **Unofficial WhatsApp Web API**: Risk of account bans, unreliable
- **WhatsApp Business App**: Manual messaging, doesn't scale
- **Third-party providers (MessageBird, Vonage)**: Similar to Twilio but less mature

**Implementation Notes**:
- Choose: Meta direct API or Twilio wrapper (decide based on onboarding ease)
- Install: `npm install twilio` (if using Twilio wrapper)
- Environment variables: `WHATSAPP_PHONE_NUMBER`, `WHATSAPP_API_KEY`
- Create message templates in WhatsApp Business Manager
- Implement in `lib/integrations/whatsapp.ts`
- Webhook handler: `/api/webhooks/whatsapp`

---

## 12. Analytics and Charting Library

### Decision: Recharts for data visualization

**Rationale**:
- **Recharts**:
  - React-native charting library
  - Composable chart components
  - Responsive by default
  - TypeScript support
  - Smaller bundle size (~90KB gzipped)
  - Server-side rendering compatible (Next.js)
  - Chart types: Line, Bar, Area, Pie, Scatter

- **Performance Optimization**:
  - Dynamic import charts: `const Chart = dynamic(() => import('recharts'), { ssr: false })`
  - Reduce data points for large datasets (aggregate by day/week)
  - Virtualize long lists with `react-window`

**Alternatives Considered**:
- **Chart.js**: Not React-native, requires wrapper, less composable
- **Victory**: Larger bundle (~150KB), more features but overkill
- **Nivo**: Beautiful but heavy (~200KB+)
- **D3.js**: Most powerful but steep learning curve, large bundle

**Implementation Notes**:
- Install: `npm install recharts`
- Components in `app/components/analytics/`
- Dynamic import to reduce initial bundle
- Custom color palette matching Kemani brand
- Accessibility: ARIA labels, keyboard navigation for data points

---

## 13. State Management Strategy

### Decision: React Server Components + URL state + Zustand (minimal client state)

**Rationale**:
- **React Server Components** (default):
  - Fetch data on server (faster, no client JS)
  - Pass data as props to Client Components
  - Eliminates need for global state for server data

- **URL state** (Next.js searchParams):
  - Filters, pagination, sorting
  - Shareable links to specific views
  - Browser back/forward works automatically

- **Zustand** (lightweight client state):
  - POS cart (client-only, not persisted to server immediately)
  - Offline sync queue status
  - UI state (modals, sidebars)
  - ~1KB gzipped, minimal overhead

**Alternatives Considered**:
- **Redux**: Too heavy for this use case (~10KB), boilerplate overhead
- **React Context**: Performance issues with frequent updates (cart changes)
- **Zustand everywhere**: Server Components reduce need for client state
- **Jotai/Recoil**: Similar to Zustand but less mature

**Implementation Notes**:
- Install: `npm install zustand`
- Create stores in `lib/store/` (cart, sync, ui)
- Use Server Components for data fetching
- Client Components only where interactivity needed
- Persist sync queue to IndexedDB via Zustand middleware

---

## 14. Form Handling and Validation

### Decision: React Hook Form + Zod

**Rationale**:
- **React Hook Form**:
  - Minimal re-renders (uncontrolled inputs)
  - Built-in TypeScript support
  - ~9KB gzipped
  - Excellent DX with `useForm` hook
  - Validation on blur (constitutional requirement)

- **Zod**:
  - Type-safe schema validation
  - Shared schemas between client and server
  - Detailed error messages
  - Composable and reusable schemas
  - ~13KB gzipped

- **Validation Strategy**:
  - Client: React Hook Form + Zod (immediate feedback)
  - Server: Zod schemas in API routes (authoritative validation)
  - Shared schemas in `lib/utils/validation.ts`

**Alternatives Considered**:
- **Formik**: Heavier (~30KB), controlled inputs (more re-renders)
- **Yup**: Similar to Zod but no type inference
- **Native browser validation**: Limited, poor UX
- **Manual validation**: Error-prone, not type-safe

**Implementation Notes**:
- Install: `npm install react-hook-form zod @hookform/resolvers`
- Create Zod schemas in `lib/utils/validation.ts`
- Form components in `app/components/forms/`
- Server-side validation in API routes using same schemas
- Error display components with accessible ARIA labels

---

## 15. Real-Time Sync Status Indicators

### Decision: Supabase Realtime Subscriptions

**Rationale**:
- **Supabase Realtime**:
  - WebSocket-based subscriptions
  - Listen to PostgreSQL changes via replication
  - Automatic reconnection on network issues
  - Filter subscriptions by table and tenant_id
  - No additional infrastructure needed

- **Use Cases**:
  - Sync status indicators (syncing, synced, conflict)
  - Real-time inventory updates (when teammate makes sale)
  - Order notifications (new marketplace order)
  - Delivery status updates

**Alternatives Considered**:
- **Polling**: Higher latency, more API calls, battery drain
- **WebSockets (custom)**: Requires separate server, more complexity
- **Server-Sent Events**: One-way only, less suitable
- **Pusher/Ably**: Additional service, cost, complexity

**Implementation Notes**:
- Supabase client already includes Realtime
- Subscribe in Client Components using `useEffect`
- Channel naming: `tenant:{tenant_id}:sync`
- Unsubscribe on component unmount to prevent memory leaks
- Show toast notifications for real-time events

---

## Summary of Key Decisions

| Area | Decision | Key Rationale |
|------|----------|---------------|
| Testing | Vitest + Playwright | Fast ESM tests, mobile emulation, offline testing |
| Offline Storage | IndexedDB + Dexie.js | Browser standard, TypeScript support, 20KB bundle |
| Sync Conflicts | Hybrid (LWW + OT + Manual) | Balance automation with data integrity |
| PWA | Workbox | Production-ready, multiple cache strategies |
| Multi-Tenancy | Supabase RLS | Database-level isolation, zero cross-tenant leaks |
| OTP Delivery | Termii + Twilio fallback | Nigeria-optimized, cost-effective |
| Staff Invites | Resend | Developer-friendly, React email templates |
| Payments | Paystack + Flutterwave | Nigerian market standard, subscription support |
| AI Chat | OpenAI GPT-4 Turbo | Best NLU for Nigerian English, function calling |
| E-Commerce Sync | REST + Webhooks | Real-time when available, polling fallback |
| WhatsApp | Twilio WhatsApp API | Easier onboarding than Meta direct |
| Charts | Recharts | Lightweight, SSR-compatible, React-native |
| State Management | Server Components + Zustand | Minimal client state, leverage Next.js 16 |
| Forms | React Hook Form + Zod | Type-safe, minimal re-renders, shared validation |
| Real-Time | Supabase Realtime | Built-in, no extra infrastructure |

---

**All NEEDS CLARIFICATION items resolved. Ready for Phase 1: Design.**
