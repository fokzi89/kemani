# Phase 0: Technical Research & Decisions

**Feature**: Multi-Tenant POS-First Super App Platform
**Created**: 2026-01-17
**Status**: Complete

## Overview

This document consolidates technical research for 6 critical architectural decisions required for the multi-tenant, offline-first POS platform. Each decision includes evaluation criteria, alternatives considered, final choice, and rationale.

---

## Decision 1: Offline Sync Engine

### Context
The platform requires robust offline-first functionality where multiple POS devices can operate independently without internet, then sync changes when connectivity returns. The specification mandates Operational Transformation/CRDT-based conflict resolution to ensure arithmetic correctness for concurrent inventory updates.

### Requirements
- **Bidirectional sync** between SQLite (client) and Supabase PostgreSQL (server)
- **CRDT/OT support** for conflict-free inventory operations
- **Real-time sync** when online, background sync when connection restored
- **Resilience** to network interruptions common in Nigerian retail environments
- **TypeScript support** with Next.js 16 compatibility
- **Performance** suitable for low-end devices (2GB RAM)

### Alternatives Evaluated

#### Option A: ElectricSQL
**Description**: Reactive sync layer that replicates PostgreSQL tables to local SQLite with active-active replication.

**Pros**:
- Native PostgreSQL replication with CRDT support
- Real-time reactive queries
- Strong consistency guarantees
- Open source with active development
- TypeScript-first design
- Excellent documentation

**Cons**:
- Adds complexity with separate Electric sync service
- Requires Electric server deployment alongside Supabase
- Still maturing (v0.x as of Jan 2025)
- Additional infrastructure cost
- May require schema migrations on both Electric and Supabase

**Verdict**: Rejected due to infrastructure complexity and deployment overhead.

#### Option B: PowerSync
**Description**: Offline-first sync engine specifically designed for SQLite ↔ PostgreSQL/MongoDB sync with CRDT support.

**Pros**:
- Purpose-built for offline-first mobile/web apps
- Native CRDT conflict resolution
- Incremental sync reduces bandwidth
- React hooks for real-time reactivity
- Good TypeScript support
- Supabase integration guide available
- Optimized for React Native and web (PWA)

**Cons**:
- Commercial product (free tier available, paid for production)
- Proprietary sync protocol
- Less flexible than custom solution
- Pricing model may not scale well for multi-tenant SaaS
- Vendor lock-in risk

**Verdict**: Strong candidate but concerns about long-term costs for multi-tenant deployment.

#### Option C: Custom OT/CRDT Implementation
**Description**: Build custom sync layer using Automerge/Yjs for CRDT logic with manual SQLite ↔ Supabase sync.

**Pros**:
- Full control over sync logic and timing
- No vendor lock-in
- Can optimize for specific POS use cases (inventory, sales)
- Leverages existing CRDT libraries (Automerge, Yjs)
- No additional infrastructure costs

**Cons**:
- Significant development time (4-6 weeks minimum)
- Complex to implement correctly (conflict resolution edge cases)
- Ongoing maintenance burden
- Must handle schema migrations manually
- Higher risk of sync bugs

**Verdict**: Rejected for MVP due to development timeline and complexity.

#### Option D: Supabase Realtime + Manual Conflict Resolution
**Description**: Use Supabase Realtime subscriptions with custom last-write-wins or timestamp-based conflict resolution.

**Pros**:
- Simpler implementation
- Native Supabase integration
- Well-documented patterns
- Lower cognitive overhead

**Cons**:
- **Does not meet specification requirement for OT/CRDT**
- Last-write-wins loses data (conflicts rejected by spec)
- No offline queue guarantees
- Poor user experience when syncing conflicts

**Verdict**: Rejected - violates FR-002 requirement for OT/CRDT conflict resolution.

### Final Decision: **PowerSync**

**Rationale**:
1. **Specification Compliance**: PowerSync provides native CRDT conflict resolution required by FR-002, ensuring arithmetic correctness for concurrent inventory operations.
2. **Development Velocity**: Pre-built Supabase integration and React hooks enable faster MVP delivery compared to custom implementation (weeks vs months).
3. **Production-Ready**: Battle-tested in offline-first applications, reducing risk of sync bugs that could cause data loss.
4. **Cost Model**: Free tier supports development; paid tier pricing acceptable for B2B SaaS (cost passed to merchants via subscription).
5. **Technical Fit**: Optimized for PWA with TypeScript, aligns with Next.js 16 + React 19 stack.
6. **Fallback Path**: If vendor lock-in becomes issue post-MVP, can migrate to custom solution with established sync patterns.

**Implementation Notes**:
- Use PowerSync React hooks for real-time queries in Client Components
- Configure incremental sync to minimize bandwidth on 3G networks
- Implement sync status indicators for offline/syncing/online states
- Monitor sync performance metrics (latency, conflict rate, queue depth)

**Alternatives for Future Consideration**:
- If PowerSync pricing becomes prohibitive at scale (>1000 tenants), evaluate custom OT implementation using Automerge + Supabase Realtime
- ElectricSQL if it reaches v1.0 and simplifies deployment model

---

## Decision 2: SQLite for Web Implementation

### Context
The POS must operate fully offline in the browser, requiring a robust SQLite implementation that persists data locally and performs well on low-end Android devices (2GB RAM, Chrome/WebView).

### Requirements
- **Full SQL support** for complex POS queries (joins, aggregations, transactions)
- **ACID compliance** for inventory and sales transactions
- **Persistence** across browser sessions using IndexedDB or OPFS
- **Performance** suitable for 10,000+ products and 100,000+ transactions
- **Bundle size** under 1MB to meet Core Web Vitals targets
- **Browser compatibility** with Chrome 90+, Safari 14+
- **TypeScript support** with type-safe query builders

### Alternatives Evaluated

#### Option A: sql.js
**Description**: SQLite compiled to WebAssembly using Emscripten, runs entirely in browser memory.

**Pros**:
- Mature and widely used (1M+ weekly downloads)
- Full SQLite 3.x feature support
- Simple API, easy to integrate
- Good documentation and examples
- Works in all modern browsers
- TypeScript bindings available

**Cons**:
- **Database stored in memory** - requires manual persistence to IndexedDB
- Large bundle size (~800KB uncompressed wasm)
- No automatic persistence (must export/import manually)
- Performance degrades with large databases (>50MB)
- Must load entire database into memory on startup (slow on low-end devices)

**Verdict**: Not ideal for large POS datasets due to memory constraints.

#### Option B: wa-sqlite
**Description**: Minimal SQLite WebAssembly build with pluggable storage backends (IndexedDB, OPFS, memory).

**Pros**:
- **Much smaller bundle** (~300KB uncompressed)
- Pluggable VFS backends (IndexedDB-batch, OPFS, memory)
- Better performance than sql.js for large databases
- Supports incremental reads (doesn't load full DB into memory)
- Active development and maintenance
- TypeScript support via @types/wa-sqlite

**Cons**:
- Less mature than sql.js (fewer production deployments)
- Sparser documentation
- Requires manual VFS configuration
- Some edge cases with IndexedDB backend (locking issues)
- OPFS backend not supported in Safari yet

**Verdict**: Strong candidate for performance but Safari compatibility concerns.

#### Option C: absurd-sql
**Description**: Fork of sql.js with optimized IndexedDB backend for better persistence and performance.

**Pros**:
- Better performance than sql.js for large datasets
- Automatic IndexedDB persistence
- Handles multi-tab scenarios better
- Good for read-heavy workloads

**Cons**:
- **No longer actively maintained** (last update 2022)
- Security vulnerabilities may not be patched
- Based on older SQLite version (3.35)
- Limited TypeScript support
- Uncertain future compatibility

**Verdict**: Rejected due to lack of maintenance.

#### Option D: Kysely + Better-SQLite3 (Electron/Tauri)
**Description**: Use native Node.js SQLite bindings if deploying as Electron/Tauri desktop app instead of PWA.

**Pros**:
- Native performance (10-100x faster than wasm)
- Full SQLite feature set
- Better resource management
- Kysely provides excellent TypeScript query builder

**Cons**:
- **Not compatible with PWA requirement**
- Requires desktop app installation (friction for merchants)
- Larger download size (~50MB vs <1MB PWA)
- Platform-specific builds (Windows, macOS, Linux)

**Verdict**: Rejected - specification requires PWA for accessibility on low-end devices.

### Final Decision: **wa-sqlite with IndexedDB-batch VFS**

**Rationale**:
1. **Performance**: Incremental reads and smaller bundle size (~300KB) ensure acceptable performance on 2GB RAM devices.
2. **Persistence**: IndexedDB-batch VFS provides automatic persistence without manual export/import cycles.
3. **Scalability**: Handles large databases (>100MB) better than sql.js by not loading entire DB into memory.
4. **Bundle Size**: Meets Core Web Vitals targets (<200KB gzipped per route after brotli compression).
5. **Future-Proof**: Active maintenance and community, with OPFS backend available when Safari adds support.
6. **PowerSync Compatibility**: PowerSync supports wa-sqlite as backend, enabling seamless integration.

**Implementation Notes**:
- Use IndexedDB-batch VFS for production (best balance of compatibility and performance)
- Monitor for Safari OPFS support (better performance when available)
- Implement database migration strategy using PowerSync schema versioning
- Add lazy loading for large tables (products, transactions) with pagination
- Use Web Workers to run SQLite queries off main thread (prevents UI blocking)

**Fallback Plan**:
- If wa-sqlite performance issues arise on low-end devices, fallback to sql.js with optimized load strategy (lazy load historical data, keep only recent transactions in memory)

---

## Decision 3: Multi-Tenant Implementation with Supabase RLS

### Context
The platform must support multiple tenants (retail businesses) with complete data isolation, ensuring that Tenant A cannot access Tenant B's data. Supabase Row Level Security (RLS) is the primary enforcement mechanism.

### Requirements
- **Complete data isolation** between tenants (no cross-tenant data leaks)
- **Branch isolation** within tenants (branches can view own data + consolidated view for admin)
- **Performance** with 1000+ tenants and 10,000+ products per tenant
- **Developer experience** that prevents accidental cross-tenant queries
- **Audit trail** for all data access across tenant boundaries
- **Scalability** to support 10,000+ tenants without schema changes

### Alternatives Evaluated

#### Option A: Separate Database Per Tenant
**Description**: Each tenant gets dedicated PostgreSQL database with complete isolation.

**Pros**:
- Absolute data isolation (impossible to access other tenant's data)
- Easier compliance with data residency requirements
- Simpler backup/restore per tenant
- No query performance impact from tenant filtering

**Cons**:
- **Not supported by Supabase free/pro tiers** (requires custom deployment)
- Complex schema migrations (must run on all databases)
- Higher infrastructure costs (1000 databases vs 1)
- Difficult to implement cross-tenant analytics
- Connection pool exhaustion with many databases

**Verdict**: Rejected - not compatible with Supabase architecture.

#### Option B: Separate Schema Per Tenant
**Description**: Single PostgreSQL database with one schema per tenant (e.g., `tenant_123.products`).

**Pros**:
- Strong logical separation
- Easier to backup individual tenants
- Can set schema-level permissions

**Cons**:
- **Not natively supported by Supabase RLS**
- Complex query routing logic
- Schema proliferation issues at scale (PostgreSQL limit ~10K schemas)
- Migrations become complex (must run on all schemas)
- Poor fit with PowerSync sync model

**Verdict**: Rejected - poor Supabase integration.

#### Option C: Shared Schema with tenant_id Column + RLS Policies
**Description**: Single schema with `tenant_id` column on all tables, enforced via Supabase RLS policies.

**Pros**:
- **Native Supabase pattern** (well-documented, best practice)
- Simple schema migrations (single schema)
- Excellent query performance with proper indexing
- PowerSync supports tenant filtering
- Easy to implement role-based access (admin sees all branches, staff sees own branch)
- Cost-effective at scale

**Cons**:
- Requires discipline to always filter by `tenant_id`
- Risk of developer error exposing cross-tenant data
- Must index `tenant_id` on all tables for performance
- Slightly more complex queries (always include tenant filter)

**Verdict**: Recommended approach for Supabase-based multi-tenancy.

#### Option D: Hybrid (tenant_id + branch_id with Hierarchical RLS)
**Description**: Extension of Option C adding `branch_id` for multi-branch isolation within tenants.

**Pros**:
- Supports multi-branch requirement (FR-087 to FR-092)
- Allows branch-level access control (cashiers see own branch only)
- Owner/admin can query across all branches via RLS policy
- Enables consolidated analytics with drill-down

**Cons**:
- More complex RLS policies (must handle both tenant and branch filtering)
- Additional index overhead (`tenant_id, branch_id` composite indexes)
- Requires careful policy design to avoid performance issues

**Verdict**: Required for specification compliance.

### Final Decision: **Shared Schema with tenant_id + branch_id + Supabase RLS (Option D)**

**Rationale**:
1. **Specification Compliance**: Multi-branch requirement (FR-087 to FR-092) mandates branch-level isolation within tenants.
2. **Supabase Native**: Leverages Supabase RLS policies for declarative security enforcement.
3. **Performance**: Composite indexes on `(tenant_id, branch_id)` provide O(log n) lookups even with millions of rows.
4. **Flexibility**: RLS policies can enforce different access levels:
   - **Owner/Admin**: Full access to all branches in tenant
   - **Branch Manager**: Access to specific branch + read-only consolidated view
   - **Cashier**: Read/write access to own branch only
5. **Audit Trail**: RLS policies can log all queries via `auth.uid()` for compliance.
6. **PowerSync Integration**: PowerSync supports tenant/branch filtering in sync rules.

**Implementation Pattern**:

```sql
-- Example RLS policy for products table
CREATE POLICY "Tenant isolation" ON products
  FOR ALL
  USING (
    tenant_id = (SELECT tenant_id FROM auth.users WHERE id = auth.uid())
  );

CREATE POLICY "Branch access control" ON products
  FOR SELECT
  USING (
    tenant_id = (SELECT tenant_id FROM auth.users WHERE id = auth.uid())
    AND (
      branch_id = (SELECT branch_id FROM auth.users WHERE id = auth.uid())
      OR (SELECT role FROM auth.users WHERE id = auth.uid()) IN ('owner', 'admin')
    )
  );
```

**Schema Conventions**:
- All tenant-scoped tables include `tenant_id UUID NOT NULL REFERENCES tenants(id)`
- All branch-scoped tables include `branch_id UUID NOT NULL REFERENCES branches(id)`
- Composite indexes: `CREATE INDEX idx_products_tenant_branch ON products(tenant_id, branch_id)`
- Use `SET LOCAL` for admin queries that bypass RLS (with explicit audit logging)

**Security Checklist**:
- [ ] Enable RLS on all tenant-scoped tables (`ALTER TABLE ... ENABLE ROW LEVEL SECURITY`)
- [ ] Create `SELECT`, `INSERT`, `UPDATE`, `DELETE` policies for each table
- [ ] Test cross-tenant access attempts (should return 0 rows, not error)
- [ ] Verify branch-level isolation for cashier role
- [ ] Audit log all admin queries that use `SET LOCAL` to bypass RLS
- [ ] Add integration tests for RLS policies (use `pg_tap` or Supabase testing framework)

---

## Decision 4: OTP Delivery Providers

### Context
The platform uses phone number + OTP and email + OTP as primary authentication methods (FR-014). Nigeria-first UX requires reliable SMS delivery despite inconsistent telecom infrastructure. Email OTP serves as fallback.

### Requirements
- **SMS delivery to Nigerian mobile numbers** (+234 prefix)
- **Email delivery** with <1 minute latency
- **5-minute OTP expiration** (from clarifications)
- **Delivery rate >95%** for SMS, >99% for email
- **Cost-effective** at scale (1000s of auth requests/day)
- **Fallback mechanism** if primary provider fails
- **TypeScript SDK** for integration

### Alternatives Evaluated

#### Option A: Termii
**Description**: Nigerian SMS and voice API provider with focus on African markets.

**Pros**:
- **Nigeria-native provider** (understands local telecom landscape)
- Competitive pricing (₦2-4 per SMS for bulk)
- High delivery rates on Nigerian networks (MTN, Glo, Airtel, 9mobile)
- Voice OTP fallback option
- WhatsApp Business API integration (future feature)
- Good documentation with Node.js examples

**Cons**:
- No official TypeScript SDK (must wrap REST API)
- Occasional delays during peak hours (festive seasons)
- Customer support response time can be slow
- No email delivery (need separate provider)

**Verdict**: Strong candidate for SMS delivery.

#### Option B: Africa's Talking
**Description**: Pan-African API provider offering SMS, voice, and USSD across 20+ countries.

**Pros**:
- Broader African coverage (good for future expansion)
- Reliable delivery infrastructure
- Voice and USSD options
- Official Node.js SDK with TypeScript types
- Better documentation than Termii

**Cons**:
- **Higher cost** (₦5-7 per SMS in Nigeria)
- Some reports of lower delivery rates on Glo network
- No email delivery
- Overkill if only targeting Nigeria initially

**Verdict**: Good but more expensive than Termii.

#### Option C: Twilio
**Description**: Global CPaaS leader with SMS, voice, and email APIs.

**Pros**:
- Excellent TypeScript SDK and documentation
- 99.9% uptime SLA
- Advanced features (SMS verification API with fraud detection)
- Email delivery via SendGrid (same company)
- Global reach for future expansion

**Cons**:
- **Very expensive** (₦15-25 per SMS in Nigeria)
- Overkill for Nigeria-only MVP
- Some Nigerian numbers require registration for sender ID
- Less familiar with local telecom issues

**Verdict**: Rejected due to cost.

#### Option D: Supabase Auth (Email OTP Only)
**Description**: Use Supabase's built-in email authentication with magic links/OTP.

**Pros**:
- **Free** (included with Supabase subscription)
- Native integration (no additional SDK)
- Email delivery via Supabase's transactional email service
- Handles token generation and expiration automatically
- TypeScript support via Supabase client

**Cons**:
- **No SMS support** (email only)
- Requires users to have email addresses (less common in Nigerian retail)
- Slower authentication flow (must open email client)

**Verdict**: Use as email OTP provider, but needs SMS supplement.

### Final Decision: **Termii (SMS) + Supabase Auth (Email)**

**Rationale**:
1. **Cost Efficiency**: Termii's ₦2-4 per SMS pricing enables sustainable unit economics for B2B SaaS model.
2. **Local Expertise**: Termii's Nigeria focus ensures better delivery rates and understanding of local network issues.
3. **Dual Delivery**: Email OTP via Supabase Auth provides free fallback when users prefer email or SMS fails.
4. **Simplicity**: Supabase Auth handles email OTP complexity (token generation, expiration, verification) out of the box.
5. **Future-Proof**: Termii's WhatsApp Business API support aligns with specification's WhatsApp integration requirement (FR-064 to FR-068).

**Implementation Approach**:

```typescript
// Phone OTP flow
async function sendPhoneOTP(phoneNumber: string): Promise<void> {
  const otp = generateOTP(6); // 6-digit code
  await termii.sendSMS({
    to: phoneNumber,
    message: `Your Kemani verification code is ${otp}. Valid for 5 minutes.`,
  });
  await storeOTP(phoneNumber, otp, expiresIn: 5 * 60 * 1000); // 5 min
}

// Email OTP flow (using Supabase Auth)
async function sendEmailOTP(email: string): Promise<void> {
  await supabase.auth.signInWithOtp({
    email,
    options: {
      emailRedirectTo: `${window.location.origin}/auth/callback`,
      shouldCreateUser: true,
    },
  });
}
```

**Fallback Strategy**:
1. User enters phone number → Send SMS via Termii
2. If SMS fails (network error) → Offer email OTP option
3. If both fail → Show manual support contact

**Cost Projection**:
- Assume 1000 merchants × 5 staff = 5000 users
- Average 2 logins/day = 10,000 OTP/day
- Termii cost: 10,000 × ₦3 = ₦30,000/day = ₦900,000/month (~$600)
- Email OTP: Free via Supabase

**Monitoring**:
- Track SMS delivery rate by network provider (MTN, Glo, Airtel, 9mobile)
- Alert if delivery rate <90% on any network
- Monitor OTP verification success rate (should be >95%)

---

## Decision 5: Payment Gateway Integration

### Context
The platform requires payment processing for customer orders (card, bank transfer, USSD) and merchant subscription billing (FR-010). Nigeria-first approach requires support for local payment methods and Naira (₦) currency.

### Requirements
- **Nigerian payment methods**: Card (Visa, Mastercard, Verve), bank transfer, USSD
- **Subscription billing** for merchant SaaS fees
- **Commission processing** for delivery marketplace
- **Refund support** for order cancellations
- **Webhook reliability** for payment status updates
- **PCI compliance** (payment provider handles card data, not our servers)
- **Cost-effective** transaction fees (<2% + ₦50)

### Alternatives Evaluated

#### Option A: Paystack
**Description**: Leading Nigerian payment gateway owned by Stripe.

**Pros**:
- **Best Nigerian coverage** (all major banks and networks)
- Excellent TypeScript SDK with Next.js examples
- Supports all required payment methods (card, transfer, USSD)
- Subscription billing built-in (recurring charges)
- Split payments for marketplace commission
- 99.9% uptime SLA
- Comprehensive webhooks with retry logic
- Strong developer experience (docs, SDKs, sandbox)

**Cons**:
- Transaction fees: 1.5% + ₦100 (higher fixed fee than competitors)
- Owned by Stripe (potential future pricing changes)
- Some merchants prefer local providers

**Verdict**: Strong candidate, industry standard in Nigeria.

#### Option B: Flutterwave
**Description**: Pan-African payment gateway with strong Nigerian presence.

**Pros**:
- Broader African coverage (good for expansion)
- Competitive pricing: 1.4% + ₦50
- Good TypeScript SDK
- Subscription billing support
- Split payments for commission
- Mobile money support (future expansion to Ghana, Kenya)

**Cons**:
- Occasional webhook delivery delays
- Slightly less polished developer experience than Paystack
- Some merchants report slower settlement times

**Verdict**: Solid alternative to Paystack.

#### Option C: Interswitch
**Description**: Established Nigerian payment processor (Verve card issuer).

**Pros**:
- Strong banking relationships in Nigeria
- Best Verve card support (they own the network)
- Lower fees for Verve transactions

**Cons**:
- **Poor developer experience** (outdated docs, no TypeScript SDK)
- Complex integration process
- Less reliable webhooks
- No subscription billing built-in

**Verdict**: Rejected due to poor developer experience.

#### Option D: Stripe (International)
**Description**: Global payment leader with Nigeria support (via Stripe Atlas).

**Pros**:
- Best-in-class developer experience
- Excellent TypeScript SDK and documentation
- Robust subscription billing
- Advanced features (fraud detection, tax calculation)

**Cons**:
- **Requires international business entity** (Stripe Atlas or foreign company)
- Higher fees for Nigerian cards (3.5% + ₦100)
- Most Nigerian merchants prefer local gateways
- Settlement in USD (currency conversion risk)

**Verdict**: Rejected for Nigerian business model.

### Final Decision: **Paystack (Primary) + Flutterwave (Fallback)**

**Rationale**:
1. **Market Leader**: Paystack's dominance in Nigerian e-commerce provides merchant trust and familiarity.
2. **Developer Experience**: Excellent TypeScript SDK and Next.js integration reduce development time.
3. **Feature Completeness**: Built-in subscription billing and split payments cover all specification requirements (FR-010, FR-011).
4. **Reliability**: 99.9% uptime and robust webhook system ensure payment consistency.
5. **Redundancy**: Flutterwave as fallback mitigates vendor lock-in and provides backup during Paystack outages.
6. **Cost**: While fees are slightly higher than Flutterwave (₦100 vs ₦50 fixed), better reliability justifies cost.

**Implementation Approach**:

```typescript
// Payment abstraction layer
interface PaymentProvider {
  initializePayment(amount: number, email: string): Promise<PaymentReference>;
  verifyPayment(reference: string): Promise<PaymentStatus>;
  handleWebhook(payload: unknown): Promise<void>;
}

class PaystackProvider implements PaymentProvider {
  // Primary implementation
}

class FlutterwaveProvider implements PaymentProvider {
  // Fallback implementation
}

// Use primary, fallback to secondary on failure
const paymentService = new PaymentService(
  primary: new PaystackProvider(),
  fallback: new FlutterwaveProvider()
);
```

**Use Cases**:
1. **Customer Payments** (orders from marketplace): Use Paystack with split payment to deduct platform commission
2. **Merchant Subscriptions**: Use Paystack subscription billing with monthly/annual plans
3. **Delivery Fees**: Use Paystack split payment (merchant pays customer, platform deducts delivery commission)
4. **Refunds**: Use Paystack refund API for order cancellations

**Webhook Implementation**:
- Set up Paystack webhook endpoint: `/api/webhooks/paystack`
- Verify webhook signature using Paystack secret key
- Process events: `charge.success`, `subscription.create`, `subscription.disable`, `refund.processed`
- Implement idempotency using `event.id` to prevent duplicate processing
- Store webhook logs in Supabase for audit trail
- If webhook fails, poll Paystack API as fallback (verify payment status every 5 minutes)

**Cost Analysis**:
- Merchant subscription (₦5,000/month): Fee = ₦175 (1.5% + ₦100) = 3.5% effective rate
- Customer order (avg ₦10,000): Fee = ₦250 (1.5% + ₦100) = 2.5% effective rate
- Platform takes 5% commission → ₦500 revenue, ₦250 cost = ₦250 net = 50% margin

**Testing Strategy**:
- Use Paystack test mode with test cards
- Test all payment methods: card, transfer, USSD
- Test subscription lifecycle: create, renew, cancel
- Test split payments with various commission percentages
- Test webhook delivery failures (simulate timeout, retry logic)
- Test refund scenarios (partial, full refunds)

---

## Decision 6: PWA Implementation

### Context
The specification requires Progressive Web App (PWA) for offline-first access on low-end Android devices (2GB RAM, 3G connectivity). Must support install prompts, offline functionality, and push notifications.

### Requirements
- **Installable** (Add to Home Screen on Android/iOS)
- **Offline-first** (full POS functionality without internet)
- **Service Worker** for caching and background sync
- **Push notifications** for order updates and low stock alerts
- **App-like experience** (fullscreen, splash screen, icons)
- **Bundle size <200KB** per route (Core Web Vitals)
- **Next.js 16 compatibility** (App Router)

### Alternatives Evaluated

#### Option A: next-pwa
**Description**: Zero-config PWA plugin for Next.js using Workbox.

**Pros**:
- **Most popular** Next.js PWA solution (5K+ GitHub stars)
- Simple configuration in `next.config.js`
- Automatic service worker generation with Workbox
- Supports Next.js 13+ App Router
- Cache strategies: NetworkFirst, CacheFirst, StaleWhileRevalidate
- Handles manifest.json generation
- Good documentation and examples

**Cons**:
- **Not officially maintained by Vercel** (community project)
- Some issues with Next.js 14+ (requires version-specific workarounds)
- Limited customization without ejecting to manual Workbox config
- Occasional cache invalidation issues during deployments

**Verdict**: Best balance of simplicity and features.

#### Option B: Vite PWA Plugin (for Vite projects)
**Description**: Vite-specific PWA plugin, not compatible with Next.js.

**Pros**:
- Excellent developer experience for Vite projects
- Fast build times
- Good TypeScript support

**Cons**:
- **Not compatible with Next.js** (requires Vite bundler)
- Would require migrating from Next.js to Vite (violates tech stack decision)

**Verdict**: Rejected - incompatible with Next.js requirement.

#### Option C: Manual Workbox Configuration
**Description**: Manually configure Workbox service worker without plugin.

**Pros**:
- **Full control** over caching strategies and service worker lifecycle
- Can optimize for specific POS use cases (cache product images, never cache sales data)
- No dependency on third-party plugins
- Custom background sync logic

**Cons**:
- Significantly more development time (2-3 weeks vs 2-3 days)
- Must handle service worker registration, updates, skip waiting logic
- Must manually generate manifest.json
- Higher risk of bugs (service worker errors can break entire app)
- Ongoing maintenance burden

**Verdict**: Overkill for MVP, consider post-launch if next-pwa has limitations.

#### Option D: No PWA (Native Mobile App Instead)
**Description**: Skip PWA, build React Native app for mobile.

**Pros**:
- Better performance on mobile (native UI)
- Access to more device APIs (camera, NFC, Bluetooth)
- Better offline experience

**Cons**:
- **Violates specification requirement** (PWA explicitly required)
- Higher development cost (must build separate mobile app)
- App Store approval friction (delays merchant onboarding)
- Larger download size (~50MB vs <1MB PWA)
- Excludes merchants without smartphones (feature phones can run PWA in modern browsers)

**Verdict**: Rejected - specification mandates PWA.

### Final Decision: **next-pwa with Workbox**

**Rationale**:
1. **Specification Compliance**: Delivers all PWA requirements (installable, offline, push notifications).
2. **Development Velocity**: Zero-config setup reduces development time from weeks to days.
3. **Proven Solution**: Widely used in production Next.js apps with strong community support.
4. **Performance**: Workbox caching strategies optimize for 3G networks (StaleWhileRevalidate for API data, CacheFirst for static assets).
5. **Future-Proof**: If customization needed, can eject to manual Workbox config without rewriting from scratch.

**Configuration**:

```javascript
// next.config.ts
import withPWA from 'next-pwa';

export default withPWA({
  dest: 'public',
  register: true,
  skipWaiting: true,
  disable: process.env.NODE_ENV === 'development',
  runtimeCaching: [
    {
      urlPattern: /^https:\/\/api\.kemani\.app\/.*$/,
      handler: 'NetworkFirst',
      options: {
        cacheName: 'api-cache',
        expiration: {
          maxEntries: 100,
          maxAgeSeconds: 60 * 60 * 24, // 24 hours
        },
        networkTimeoutSeconds: 10,
      },
    },
    {
      urlPattern: /^https:\/\/.*\.supabase\.co\/.*$/,
      handler: 'NetworkFirst',
      options: {
        cacheName: 'supabase-cache',
        networkTimeoutSeconds: 10,
      },
    },
    {
      urlPattern: /\.(?:png|jpg|jpeg|svg|gif|webp)$/,
      handler: 'CacheFirst',
      options: {
        cacheName: 'image-cache',
        expiration: {
          maxEntries: 200,
          maxAgeSeconds: 60 * 60 * 24 * 30, // 30 days
        },
      },
    },
  ],
});
```

**Manifest Configuration**:

```json
// public/manifest.json
{
  "name": "Kemani POS",
  "short_name": "Kemani",
  "description": "Offline-first point of sale for Nigerian retailers",
  "start_url": "/",
  "display": "standalone",
  "background_color": "#ffffff",
  "theme_color": "#4F46E5",
  "orientation": "portrait",
  "icons": [
    {
      "src": "/icon-192.png",
      "sizes": "192x192",
      "type": "image/png",
      "purpose": "any maskable"
    },
    {
      "src": "/icon-512.png",
      "sizes": "512x512",
      "type": "image/png",
      "purpose": "any maskable"
    }
  ]
}
```

**Caching Strategy by Route**:
- **POS Screen** (`/pos`): Cache HTML shell, fetch data from IndexedDB/SQLite (full offline support)
- **Product Images**: CacheFirst with 30-day expiration
- **API Calls**: NetworkFirst with 10-second timeout, fallback to cache (for read operations)
- **Sales Data**: Never cache (always sync to server when online)

**Push Notification Implementation**:
- Use Web Push API with Supabase Edge Functions as notification sender
- Subscribe to channels: `low_stock_alert_tenant_{id}`, `order_update_branch_{id}`
- Show notification when app in background, update UI when in foreground
- Implement notification click handlers (navigate to relevant screen)

**Offline UX Indicators**:
- Show connection status banner: "Online" (green), "Syncing" (yellow), "Offline" (red)
- Display last sync timestamp
- Queue outgoing actions (sales, product updates) when offline, show queue count
- Auto-retry sync when connection restored

**Testing Checklist**:
- [ ] Install PWA on Android Chrome (verify Add to Home Screen prompt)
- [ ] Install PWA on iOS Safari (verify Add to Home Screen works)
- [ ] Test offline functionality (disable network, verify POS still works)
- [ ] Test service worker update (deploy new version, verify old SW replaced)
- [ ] Test push notifications (send notification while app backgrounded)
- [ ] Verify cache invalidation (clear cache on logout, version mismatch)
- [ ] Test on 3G throttled connection (verify reasonable performance)

---

## Decision 7: UI Component Library

### Context
The POS interface requires a comprehensive set of accessible, responsive UI components (buttons, forms, tables, modals, navigation). The components must work well on low-end Android devices, support offline operation, and integrate seamlessly with Tailwind CSS 4 already in the project.

### Requirements
- **Accessibility**: WCAG 2.1 AA compliant (keyboard navigation, screen readers, ARIA attributes)
- **Type Safety**: Full TypeScript support with proper prop types
- **Customization**: Easy to customize colors, spacing, and behavior for tenant branding
- **Performance**: Lightweight components suitable for low-end devices
- **Offline Compatible**: No runtime dependencies on CDNs or external resources
- **Developer Experience**: Well-documented, easy to use, active maintenance

### Alternatives Evaluated

#### Option A: shadcn/ui + Radix UI
**Description**: Collection of re-usable components built with Radix UI primitives and styled with Tailwind CSS. Components are copied into your project, not installed as dependency.

**Pros**:
- **Accessibility-first**: Built on Radix UI primitives (unstyled, accessible components)
- **Full ownership**: Components live in your codebase (`components/ui/`), easy to customize
- **Type-safe**: Excellent TypeScript support with proper prop types
- **Tailwind native**: Designed specifically for Tailwind CSS (uses `cn()` utility)
- **No bundle bloat**: Only include components you use (copy-paste model)
- **Active development**: Very popular (50K+ GitHub stars), frequent updates
- **Next.js optimized**: Works perfectly with App Router, Server Components
- **Form integration**: Built-in integration with React Hook Form + Zod

**Cons**:
- Not a traditional npm package (copy-paste approach may feel unusual)
- Need to update components manually when upstream changes (rare)
- Requires Tailwind CSS (already in project, so not a concern)

**Verdict**: Best fit for project requirements.

#### Option B: Material UI (MUI)
**Description**: Comprehensive React component library implementing Material Design.

**Pros**:
- Mature and battle-tested
- Large component library (100+ components)
- Strong TypeScript support
- Good documentation

**Cons**:
- **Large bundle size** (~300KB min+gzip for core) - problematic for low-end devices
- Material Design aesthetic may not fit POS use case
- More opinionated styling (harder to customize for tenant branding)
- Runtime CSS-in-JS overhead (performance concern)
- Not optimized for Tailwind CSS

**Verdict**: Rejected due to bundle size and customization overhead.

#### Option C: Chakra UI
**Description**: Modular component library with accessible components and theming support.

**Pros**:
- Accessibility built-in
- Good TypeScript support
- Easy theming system
- Smaller than MUI (~150KB)

**Cons**:
- Uses Emotion (CSS-in-JS) - runtime overhead
- Not designed for Tailwind CSS (requires separate styling approach)
- Theming system adds complexity vs. Tailwind
- Less popular than MUI or shadcn/ui in 2026

**Verdict**: Rejected - CSS-in-JS overhead and Tailwind incompatibility.

#### Option D: Headless UI (Tailwind Labs)
**Description**: Unstyled, accessible UI components from Tailwind CSS creators.

**Pros**:
- **Official Tailwind companion**
- Fully unstyled (complete styling freedom)
- Excellent accessibility
- Lightweight (no styling overhead)
- Great TypeScript support

**Cons**:
- **Too low-level** - requires building every component from scratch
- No pre-built form components, tables, cards, etc.
- Significantly more development time vs. shadcn/ui
- No copy-paste component library

**Verdict**: Rejected - too much development overhead for MVP timeline.

#### Option E: Ant Design
**Description**: Enterprise-class UI design language and React UI library.

**Pros**:
- Comprehensive component set
- Enterprise-proven
- Good for data-heavy applications

**Cons**:
- **Very large bundle** (~500KB+)
- Opinionated design language (Chinese enterprise aesthetic)
- Difficult to customize for branding
- Not optimized for Tailwind CSS
- Overkill for POS use case

**Verdict**: Rejected - bundle size and customization issues.

### Final Decision: **shadcn/ui + Radix UI**

**Rationale**:
1. **Accessibility**: Radix UI primitives ensure WCAG 2.1 AA compliance out of the box (keyboard navigation, focus management, ARIA attributes).
2. **Type Safety**: Full TypeScript support with proper prop types, integrates with Zod for form validation.
3. **Customization**: Components are copied into `components/ui/`, making customization trivial. Easy to apply tenant branding (colors, fonts) via Tailwind CSS variables.
4. **Performance**: Minimal bundle impact - only ship components you use, no runtime styling overhead. Suitable for low-end Android devices.
5. **Developer Experience**: CLI for adding components (`npx shadcn@latest add button`), excellent documentation, large community.
6. **Tailwind Integration**: Built specifically for Tailwind CSS 4, uses `cn()` utility for conditional classes.
7. **Next.js Compatible**: Works seamlessly with App Router, Server Components (components are Client Components when needed).
8. **Form Ecosystem**: Pre-built Form components with React Hook Form + Zod validation (matches project requirements).

**Implementation Notes**:
- Install shadcn/ui CLI: `npx shadcn@latest init`
- Add components as needed: `npx shadcn@latest add button input form table`
- Customize via `components.json` and Tailwind CSS variables in `globals.css`
- Use `cn()` utility for conditional styling: `cn("base-classes", condition && "conditional-classes")`
- Components live in `components/ui/` directory (version controlled, easy to customize)

**Component Strategy**:
```
POS Interface Components:
- Button, Input, Label, Select → Core interactions
- Card, Table → Product display, sales list
- Dialog, Sheet → Modals, side panels
- Form → Sales, product entry with validation
- Toast → Notifications (sale completed, sync status)
- Badge → Stock status, order status
- Skeleton → Loading states (offline sync)
```

**Alternatives for Future Consideration**:
- If shadcn/ui components become too opinionated, can drop down to Headless UI primitives (same accessibility, more control)
- For highly custom components (e.g., POS calculator, receipt preview), build from scratch with Tailwind

---

## Summary of Decisions

| Decision Area | Choice | Key Rationale |
|--------------|--------|---------------|
| **Offline Sync Engine** | PowerSync | CRDT support, Supabase integration, production-ready |
| **SQLite for Web** | wa-sqlite (IndexedDB-batch VFS) | Performance, bundle size, persistence |
| **Multi-Tenant Pattern** | Shared schema + RLS (tenant_id + branch_id) | Supabase native, scalable, supports multi-branch |
| **OTP Delivery** | Termii (SMS) + Supabase Auth (Email) | Cost-effective, local expertise, dual fallback |
| **Payment Gateway** | Paystack (primary) + Flutterwave (fallback) | Market leader, reliability, redundancy |
| **PWA Implementation** | next-pwa with Workbox | Zero-config, proven solution, Next.js compatible |
| **UI Component Library** | shadcn/ui + Tailwind CSS 4 | Accessible (Radix UI), customizable, copy-paste components, type-safe |

## Implementation Sequence

**Phase 1: Core Infrastructure** (Week 1-2)
1. Set up Next.js 16 project with TypeScript strict mode
2. Configure next-pwa with manifest and service worker
3. Integrate wa-sqlite with IndexedDB-batch VFS
4. Implement PowerSync sync engine with Supabase connection
5. Set up Supabase RLS policies for multi-tenant isolation

**Phase 2: Authentication** (Week 3)
1. Integrate Termii SDK for SMS OTP delivery
2. Configure Supabase Auth for email OTP
3. Build authentication flow UI (phone/email input, OTP verification)
4. Implement session management with tenant/branch context

**Phase 3: Payment Integration** (Week 4)
1. Integrate Paystack SDK for payments and subscriptions
2. Set up webhook endpoints with signature verification
3. Implement payment abstraction layer (primary/fallback pattern)
4. Build subscription management UI for merchants

**Phase 4: Testing & Optimization** (Week 5)
1. Test PWA installation on target devices (low-end Android)
2. Validate offline functionality and sync behavior
3. Load test multi-tenant RLS policies (1000+ tenants)
4. Performance audit (Core Web Vitals, bundle size)

## Risks & Mitigations

| Risk | Mitigation |
|------|-----------|
| **PowerSync vendor lock-in** | Build abstraction layer; evaluate migration path post-MVP if costs spike |
| **wa-sqlite Safari issues** | Monitor Safari OPFS support; fallback to sql.js if critical bugs found |
| **RLS policy performance degradation** | Benchmark with realistic data; add composite indexes; use `EXPLAIN ANALYZE` |
| **SMS delivery failures (Termii)** | Implement email OTP fallback; monitor delivery rates per network |
| **Paystack webhook delays** | Implement polling fallback; use idempotent event processing |
| **Service worker cache bugs** | Comprehensive testing; implement cache versioning; easy cache clear for users |

## Open Questions for Phase 1 Planning

1. **Database Schema**: Should we denormalize for offline performance (e.g., embed product info in sales records) or maintain normalized structure?
2. **Sync Granularity**: Sync entire tenant database or only active branch data to minimize bandwidth?
3. **Conflict UI**: How should cashiers be notified when sync conflicts are resolved automatically?
4. **Image Storage**: Store product images in Supabase Storage or use CDN (Cloudinary)? Offline caching strategy?
5. **Internationalization**: Build i18n infrastructure now (even if English-only MVP) or defer?

---

**Status**: ✅ Phase 0 Research Complete
**Next Step**: Proceed to Phase 1 (Design & Contracts) - Generate data-model.md and API contracts
