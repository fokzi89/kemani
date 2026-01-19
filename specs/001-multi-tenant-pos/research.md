# Phase 0: Technical Research & Decisions

**Feature**: Multi-Tenant POS-First Super App Platform
**Created**: 2026-01-18
**Status**: Complete

## Overview

This document captures all technical research and architectural decisions for the multi-tenant POS platform. Each decision includes rationale, alternatives considered, and best practices from the domain.

---

## 1. Offline-First Architecture

### Decision: PowerSync + SQLite for Paid Tiers

**Chosen**: [PowerSync](https://www.powersync.com/) as offline-first sync layer with SQLite for local storage (Basic, Growth, Enterprise tiers only)

**Rationale**:
- PowerSync provides production-ready offline-first sync with Supabase PostgreSQL integration
- Handles conflict resolution using Operational Transformation (OT) and CRDTs for inventory arithmetic correctness
- Supports incremental sync reducing bandwidth consumption (critical for Nigerian 3G networks)
- Built-in schema migration support for evolving data models
- TypeScript SDK with React hooks for easy integration
- Proven scalability (supports 10,000+ concurrent users per PowerSync instance)

**Alternatives Considered**:
1. **WatermelonDB**: Open-source offline-first database
   - ❌ Rejected: Less mature conflict resolution, manual sync logic implementation required
   - ❌ No built-in Supabase integration, would need custom sync server

2. **RxDB**: Reactive offline-first database
   - ❌ Rejected: Complex replication protocol, higher learning curve
   - ❌ Larger bundle size (~150KB), conflicts with 200KB route target

3. **Custom IndexedDB + Sync Logic**: Build our own sync layer
   - ❌ Rejected: High development cost, months of effort to match PowerSync features
   - ❌ Risk of bugs in conflict resolution (critical for inventory management)

**Best Practices**:
- Use PowerSync's conflict resolution strategies: OT/CRDTs for counters (inventory), last-write-wins for non-critical data
- Implement sync status UI showing pending/syncing/synced states for user transparency
- Batch sync operations to reduce network calls
- Use PowerSync React hooks (`usePowerSync`, `useQuery`) for real-time UI updates
- Configure sync throttling to prevent overwhelming low-end devices

**Free Tier Exception**: Cloud-only (direct Supabase writes) to avoid PowerSync licensing costs per user

---

## 2. Multi-Tenant Database Isolation

### Decision: Supabase Row Level Security (RLS) Policies

**Chosen**: Supabase PostgreSQL with Row Level Security (RLS) policies for complete tenant isolation

**Rationale**:
- RLS provides database-level enforcement of tenant boundaries (cannot be bypassed by application bugs)
- Supabase Auth integration makes `auth.uid()` and tenant context available in RLS policies
- Single database simplifies operations (no tenant database provisioning)
- Scales to 10,000+ tenants without architectural changes
- Cost-effective (shared infrastructure)

**Alternatives Considered**:
1. **Database-per-Tenant**: Separate PostgreSQL database for each tenant
   - ❌ Rejected: Expensive (database provisioning overhead), complex migrations
   - ❌ Difficult to implement cross-tenant analytics for platform admins

2. **Schema-per-Tenant**: Separate PostgreSQL schema for each tenant
   - ❌ Rejected: Still complex migrations, connection pool exhaustion risk
   - ❌ Limited Supabase support for multi-schema RLS

3. **Application-Level Filtering**: Add `WHERE tenant_id = X` to all queries
   - ❌ Rejected: High risk of data leaks from forgotten filters
   - ❌ Does not provide defense-in-depth security

**Best Practices**:
- Every tenant-scoped table includes `tenant_id UUID NOT NULL REFERENCES tenants(id)`
- RLS policies check `auth.jwt() ->> 'tenant_id' = tenant_id` on all tenant tables
- Use Supabase's `SET LOCAL` to set tenant context for session-level filtering
- Create indexes on `tenant_id` columns for query performance
- Test RLS policies with multiple tenant accounts to verify isolation
- Use Supabase's generated TypeScript types to ensure type-safe queries with RLS

**Implementation Note**: Branch-level data (products, sales) includes both `tenant_id` and `branch_id` for dual isolation

---

## 3. Authentication Strategy

### Decision: Passkeys (WebAuthn) + PIN + OTP Multi-Method Auth

**Chosen**: Hybrid authentication supporting Passkeys, PIN codes, and OTP via Supabase Auth

**Rationale**:
- **Passkeys (WebAuthn)**: Fast biometric login (<3s) ideal for busy POS environments, eliminates password management
- **PIN Code**: Fallback for devices without biometric sensors (older Android phones)
- **OTP**: Initial registration and account recovery only (reduces SMS costs)
- **Social Login**: For customers (Google/Facebook)
- Supabase Auth supports all methods with built-in session management

**Alternatives Considered**:
1. **Passwords-Only**: Traditional username/password
   - ❌ Rejected: Slow login, password fatigue, security risks
   - ❌ Cashiers forget passwords frequently in retail environments

2. **OTP-Only**: SMS/email codes for every login
   - ❌ Rejected: Expensive (SMS costs), slow login flow
   - ❌ Unreliable (Nigerian SMS delivery not 100%)

3. **Magic Links**: Email-based passwordless login
   - ❌ Rejected: Requires email access, too slow for POS workflow

**Best Practices**:
- Use `@simplewebauthn/browser` for WebAuthn client-side implementation
- Store passkey credentials in Supabase `auth.identities` table
- Implement graceful degradation: Passkey → PIN → OTP fallback chain
- Rate limit PIN attempts (5 attempts per 15 minutes)
- OTP expiration: 5 minutes (per spec clarifications)
- HTTP-only cookies for session tokens (never localStorage)
- Implement "Remember this device" for passkey registration prompts

**Nigeria-Specific Considerations**:
- Test on low-end Android devices (Tecno, Infinix) for biometric sensor compatibility
- Provide clear offline passkey UX (biometric auth works offline, but registration requires online)

---

## 4. Subscription & Billing Management

### Decision: Supabase + Paystack Integration for Nigerian Payments

**Chosen**: Supabase for subscription state management, Paystack for payment processing

**Rationale**:
- **Paystack**: Leading Nigerian payment gateway, supports local payment methods (card, bank transfer, mobile money)
- No need for heavy billing SaaS (Stripe Billing) given Nigerian market focus
- Supabase database tracks subscription state, Paystack handles payment flows
- Webhook-driven architecture for async payment confirmation

**Alternatives Considered**:
1. **Stripe**: Global payment platform
   - ❌ Rejected: Limited Nigerian payment method support
   - ❌ Higher transaction fees for Nigerian merchants

2. **Flutterwave**: Nigerian payment gateway (alternative)
   - ⚠️ Considered: Similar to Paystack, could add as secondary option
   - ✅ Will support both Paystack and Flutterwave for redundancy

3. **ChargeBee / Recurly**: Dedicated billing SaaS
   - ❌ Rejected: Overkill for simple tiered pricing
   - ❌ Additional cost and complexity

**Best Practices**:
- Store subscription state in Supabase `subscriptions` table (tier, limits, billing cycle)
- Paystack webhooks update subscription status (active, past_due, canceled)
- Implement idempotent webhook handlers (use Paystack event IDs to prevent duplicate processing)
- Enforce tier limits in application logic (check limits before operations)
- Provide 7-day grace period for failed payments before downgrade to Free tier
- Display usage metrics on tenant dashboard (users, products, transactions vs. limits)

**Implementation Details**:
- Use Paystack Subscriptions API for recurring billing
- Support manual billing for Enterprise tier (custom invoicing)
- Prorate upgrades/downgrades using Paystack's subscription update API
- Annual billing: Create single-charge subscription (not recurring monthly) with 1-month discount

---

## 5. Data Retention & Archival Strategy

### Decision: Indefinite Retention with Cold Storage Archival

**Chosen**: Indefinite data retention with automatic archival to cold storage after 2 years

**Rationale**:
- Business requirement: Merchants want complete historical records for analytics
- NDPR compliance: Support customer data deletion while preserving anonymized transactions
- Cost optimization: Archive old data to cheaper cold storage tier

**Alternatives Considered**:
1. **Fixed Retention (7 years)**: Common for financial records
   - ❌ Rejected: Merchants requested indefinite retention for long-term customer insights
   - ⚠️ Could implement as optional cleanup for Free tier to control costs

2. **Merchant-Configurable Retention**: Each tenant sets their own policy
   - ❌ Rejected: Added complexity, most merchants don't have strong preferences
   - ❌ Still need platform-wide strategy for platform data

**Best Practices**:
- **Database Partitioning**: Use PostgreSQL declarative partitioning by month/year
  ```sql
  CREATE TABLE sales PARTITION OF sales_parent
  FOR VALUES FROM ('2026-01-01') TO ('2026-02-01');
  ```
- **Archival Jobs**: Automated pg_dump of partitions older than 2 years to S3/Supabase Storage
- **Query Optimization**: Add `WHERE created_at > NOW() - INTERVAL '2 years'` to common queries
- **NDPR Compliance**: Replace customer PII with anonymous IDs on deletion, preserve transaction metadata
- **Cold Storage**: Use Supabase Storage with lifecycle policies to move to infrequent-access tier

**Implementation Timeline**:
- Phase 1: Implement partitioning in initial schema
- Phase 3: Add automated archival jobs (before hitting 2-year mark)

---

## 6. Real-Time Features & WebSockets

### Decision: Supabase Realtime for Live Updates

**Chosen**: Supabase Realtime (built on PostgreSQL logical replication) for inventory sync, order updates, delivery tracking

**Rationale**:
- Native Supabase integration, no additional infrastructure
- PostgreSQL logical replication is production-proven and scalable
- Automatic multi-tenant filtering via RLS policies
- Low latency (<500ms) for real-time updates
- Free tier supports 200 concurrent connections (sufficient for MVP)

**Alternatives Considered**:
1. **Socket.IO**: Custom WebSocket server
   - ❌ Rejected: Additional infrastructure, separate deployment
   - ❌ Must implement own multi-tenant filtering logic

2. **Pusher / Ably**: Hosted real-time services
   - ❌ Rejected: Additional cost, vendor lock-in
   - ❌ Requires syncing data from Supabase to Pusher

3. **Server-Sent Events (SSE)**: HTTP-based one-way push
   - ❌ Rejected: No bidirectional communication
   - ❌ Less browser support than WebSockets

**Best Practices**:
- Subscribe only to relevant channels (current tenant/branch)
- Implement connection retry with exponential backoff
- Use Supabase Realtime presence for online/offline rider status
- Debounce UI updates to prevent excessive re-renders
- Unsubscribe from channels when components unmount

**Use Cases**:
- Inventory sync: Real-time stock updates across devices
- Order tracking: Status changes (preparing → ready → out for delivery)
- Delivery: Live rider location updates
- Chat: Live agent/AI conversations with customers

---

## 7. File Storage & CDN

### Decision: Supabase Storage with Automatic Optimization

**Chosen**: Supabase Storage for images, receipts, and documents with built-in CDN

**Rationale**:
- Integrated with Supabase auth and RLS (automatic tenant isolation)
- Built-in image transformation (resize, format conversion, optimization)
- Global CDN for fast delivery in Nigeria
- Generous free tier (100 GB storage)

**Alternatives Considered**:
1. **Cloudinary**: Dedicated image management service
   - ❌ Rejected: Additional cost, separate integration
   - ✅ Consider for future if heavy image processing needed

2. **AWS S3 + CloudFront**: Direct cloud storage
   - ❌ Rejected: More complex setup, manual RLS implementation
   - ❌ Higher operational complexity

3. **Vercel Blob**: Edge storage (if deploying to Vercel)
   - ⚠️ Considered: Good integration if using Vercel
   - ❌ Rejected: Want platform-agnostic solution

**Best Practices**:
- Use Supabase Storage public buckets for product images (with RLS policies)
- Private buckets for receipts, delivery proofs (tenant-scoped access)
- Implement automatic image optimization on upload (WebP format, max 1024px width)
- Use Supabase Storage image transformation for thumbnails (`?width=200`)
- Set appropriate cache headers (1 year for product images, shorter for receipts)
- Implement upload size limits (max 5MB per image, 20MB for PDFs)

**Nigeria-Specific Optimizations**:
- Aggressive image compression (target <100KB per product image)
- Lazy loading for product images to reduce initial page weight
- Offline-first: Cache product images locally for offline POS use

---

## 8. Analytics & Reporting

### Decision: Server-Side Aggregation + Chart.js for Visualization

**Chosen**: PostgreSQL materialized views for aggregation, Chart.js for client-side charts

**Rationale**:
- PostgreSQL is powerful enough for analytics on 1M transactions/month scale
- Materialized views pre-compute expensive aggregations
- Chart.js is lightweight (11KB gzipped), meets <200KB bundle target
- No need for dedicated analytics warehouse at current scale

**Alternatives Considered**:
1. **Google BigQuery / Snowflake**: Cloud data warehouse
   - ❌ Rejected: Overkill for current scale, expensive data export
   - ⚠️ Consider for future when scale exceeds 10M transactions/month

2. **Metabase / Superset**: Self-hosted BI tools
   - ❌ Rejected: Separate deployment, not embedded in app
   - ⚠️ Could add for internal platform analytics

3. **Recharts / Victory**: Alternative React charting libraries
   - ❌ Rejected: Larger bundle sizes (30-50KB)
   - Chart.js has better tree-shaking support

**Best Practices**:
- Create materialized views for common analytics queries:
  ```sql
  CREATE MATERIALIZED VIEW daily_sales_summary AS
  SELECT date_trunc('day', created_at) as day, branch_id, SUM(total) as revenue, COUNT(*) as transactions
  FROM sales GROUP BY day, branch_id;
  ```
- Refresh materialized views via cron job (daily at 1 AM WAT)
- Use PostgreSQL window functions for trends (day-over-day, week-over-week)
- Implement data export to CSV/PDF using server-side generation (Next.js API routes)
- Dynamic imports for chart components to reduce initial bundle:
  ```ts
  const Chart = dynamic(() => import('./Chart'), { ssr: false });
  ```

**Tier-Specific Analytics**:
- Free/Basic: Basic reports (last 30/90 days)
- Growth: Advanced analytics (sales patterns, inventory turnover, forecasting placeholders)
- Enterprise: AI-powered insights (demand forecasting, fraud detection via future ML integration)

---

## 9. E-Commerce Integration Pattern

### Decision: Webhook-Driven Bidirectional Sync

**Chosen**: Webhook-based integration with WooCommerce/Shopify using OAuth 2.0 authentication

**Rationale**:
- Webhooks provide real-time event notifications (order created, product updated)
- OAuth 2.0 is standard for WooCommerce/Shopify apps
- Bidirectional sync: POS sales update e-commerce inventory, e-commerce orders flow into POS
- No polling required (saves API rate limits)

**Alternatives Considered**:
1. **Polling-Based Sync**: Periodic API calls to fetch updates
   - ❌ Rejected: Wastes API rate limits, delayed updates (5-15 min lag)
   - ❌ Higher server costs (constant polling)

2. **Zapier Integration**: No-code integration platform
   - ❌ Rejected: Additional cost per tenant
   - ❌ Less control over sync logic, error handling

3. **Direct Database Access**: Connect to WooCommerce/Shopify databases
   - ❌ Rejected: Not supported by platforms, breaks warranty
   - ❌ Security risk

**Best Practices**:
- Use Supabase Edge Functions for webhook handlers (serverless, auto-scaling)
- Implement webhook signature verification (HMAC validation)
- Idempotent processing using webhook event IDs
- Queue failed webhooks for retry (exponential backoff, max 5 attempts)
- Conflict resolution: POS inventory is source of truth (e-commerce defers to POS)
- Map product SKUs between platforms (tenant configures SKU mapping)
- Sync only active products (exclude drafts/archived)

**WooCommerce Specifics**:
- Use WooCommerce REST API v3
- Subscribe to webhooks: `product.created`, `product.updated`, `order.created`
- Handle WooCommerce variations as product variants in POS

**Shopify Specifics**:
- Use Shopify Admin GraphQL API
- Subscribe to webhooks: `products/create`, `products/update`, `orders/create`
- Map Shopify product variants to POS variants

---

## 10. Delivery Fee Calculation

### Decision: Merchant-Configured Distance-Based Pricing

**Chosen**: Tenant admin sets distance ranges, branch merchants set fees per range

**Rationale**:
- Flexibility: Each merchant controls their own pricing
- Consistency: Tenant admin provides structure (distance ranges)
- Transparency: Customers see exact fee before checkout based on distance
- Per spec clarifications: Merchant-configured with admin variables

**Alternatives Considered**:
1. **Fixed Flat Fee**: Single fee regardless of distance
   - ❌ Rejected: Unfair to customers (short distances pay same as long)
   - ❌ Doesn't incentivize nearby customers

2. **Platform-Set Pricing**: Platform controls all delivery fees
   - ❌ Rejected: Removes merchant flexibility
   - ❌ Doesn't account for local market conditions

3. **Real-Time Dynamic Pricing**: Uber-style surge pricing
   - ❌ Rejected: Too complex, poor UX for Nigerian market
   - ❌ Customers expect predictable pricing

**Best Practices**:
- Use Google Maps Distance Matrix API or Mapbox for distance calculation
- Cache distance calculations for common routes (reduce API calls)
- Implement customer-favorable rounding (5.0km uses 0-5km range, not 5-10km)
- Display distance range and fee clearly during checkout
- Allow merchants to set ₦0 delivery fee for promotional free delivery
- Default distance ranges (configurable per tenant):
  - 0-5km: ₦300
  - 5-10km: ₦500
  - 10-25km: ₦800
  - >25km: Platform inter-city delivery (separate pricing)

**Implementation Notes**:
- Store delivery fee config in `delivery_fee_config` table (tenant-level)
- Store merchant overrides in `branch_delivery_fee` table
- Calculate fee on frontend before checkout, validate on backend (prevent manipulation)

---

## 11. Customer Support Ticketing

### Decision: Custom Support System with Business Hours SLA Tracking

**Chosen**: Build custom support ticket system in Supabase with SLA timer logic

**Rationale**:
- Simple requirements (email/SMS/chat channels, business hours SLA)
- No need for heavy helpdesk software (Zendesk, Intercom) at this scale
- Better integration with tenant context (automatic tenant assignment)
- Full control over SLA calculation (business hours, Nigerian holidays)

**Alternatives Considered**:
1. **Zendesk / Freshdesk**: Dedicated helpdesk platforms
   - ❌ Rejected: Expensive per-agent pricing
   - ❌ Overkill for simple tier-based SLA requirements

2. **Intercom**: Customer messaging platform
   - ❌ Rejected: High cost, focused on chat (need email/SMS too)
   - ❌ Complex pricing tiers

3. **Email-Only**: Simple email support
   - ❌ Rejected: No SLA tracking, hard to manage multiple tiers
   - ❌ No unified inbox for team

**Best Practices**:
- Store tickets in `support_tickets` table with SLA deadline (calculated at creation)
- SLA timer pauses outside business hours (8 AM - 6 PM WAT, Monday-Friday)
- Exclude Nigerian public holidays from SLA calculation
- Send auto-acknowledgment for requests outside business hours
- Implement escalation alerts (notify support manager when SLA breach imminent)
- Use Supabase Realtime for support agent dashboard updates
- Integrate with email (SendGrid/Postmark) and SMS (Termii) for multi-channel support

**SLA Calculation Example**:
```typescript
function calculateSLADeadline(createdAt: Date, slaHours: number): Date {
  // Skip weekends, Nigerian holidays, non-business hours
  // Return deadline timestamp
}
```

---

## 12. PWA & Offline Capabilities

### Decision: Next.js PWA with Workbox Service Worker

**Chosen**: `next-pwa` package (Workbox wrapper for Next.js) for PWA functionality

**Rationale**:
- Simple integration with Next.js
- Workbox provides production-ready caching strategies
- Automatic service worker generation
- Supports offline fallback pages
- No manual service worker JavaScript required

**Alternatives Considered**:
1. **Custom Service Worker**: Manually write SW logic
   - ❌ Rejected: High complexity, error-prone
   - ❌ Workbox provides battle-tested strategies

2. **Vite PWA Plugin**: Alternative for Vite projects
   - N/A: Using Next.js, not Vite

**Best Practices**:
- **Caching Strategy**:
  - Static assets (JS, CSS, fonts): Cache-first with versioning
  - Product images: Stale-while-revalidate (show cached, update in background)
  - API responses: Network-first (fresh data), fallback to cache offline
  - HTML pages: Network-first for dashboard, cache-first for marketing pages
- Configure manifest.json with app icons (192x192, 512x512)
- Implement offline fallback page (`/offline.html`) for uncached routes
- Add "Add to Home Screen" prompt for mobile users
- Test on real Android devices (Tecno, Infinix brands common in Nigeria)
- Use `skipWaiting` carefully (prompt user before updating SW to prevent data loss)

**Nigeria-Specific Optimizations**:
- Precache critical POS assets (cart, checkout, product list)
- Minimal SW file size (target <50KB)
- Aggressive image compression for cached assets

---

## 13. Live Agent Chat vs. AI Chat Agent

### Decision: Growth = Live Agent, Enterprise = Toggle (Live or AI)

**Chosen**: Implement live agent chat system with real-time messaging, add AI agent as Enterprise feature with dashboard toggle

**Rationale**:
- Growth tier merchants want personalized service (human touch)
- Enterprise tier gets flexibility (choose based on volume/preferences)
- Real-time messaging via Supabase Realtime
- AI agent uses OpenAI GPT-4 or Anthropic Claude for conversations

**Alternatives Considered**:
1. **AI-Only**: No live agent option
   - ❌ Rejected: Some merchants prefer human interaction
   - ❌ AI can't handle all edge cases (custom requests, complaints)

2. **Live-Agent-Only**: No AI option
   - ❌ Rejected: High-volume Enterprise customers need automation
   - ❌ Expensive to staff 24/7 live agents

**Best Practices - Live Agent**:
- Store chat messages in `chat_conversations` table with real-time sync
- Use Supabase Realtime for instant message delivery
- Implement agent online/offline status using Presence
- Assign conversations to available agents (round-robin or skill-based)
- Provide agent dashboard showing active chats, pending queue
- Notify agents via browser push notifications and SMS for new messages

**Best Practices - AI Agent**:
- Use OpenAI Assistants API or Anthropic Claude with function calling
- Implement tool functions for:
  - Query inventory (`check_product_availability`)
  - Create order (`create_customer_order`)
  - Modify order (`update_order_items`)
  - Cancel order (`cancel_order`)
- Image recognition for customer-uploaded product photos (OpenAI Vision API)
- Log all AI conversations for merchant review and quality control
- Implement escalation to human agent when AI confidence is low
- Use streaming responses for better UX (show AI typing in real-time)

**Enterprise Toggle Implementation**:
- Branch-level or tenant-level setting: `chat_mode: 'live_agent' | 'ai_agent'`
- Route customer messages based on mode
- Display appropriate UI indicator (chatting with agent vs. AI assistant)

---

## 14. Loyalty Points Manual Approval

### Decision: Merchant Dashboard for Points Approval Workflow

**Chosen**: Implement loyalty points approval queue with bulk approval interface

**Rationale**:
- Per spec clarifications: Merchants must manually approve loyalty points
- Prevents abuse (fraudulent transactions, returns)
- Gives merchants control over points allocation

**Alternatives Considered**:
1. **Automatic Points**: Auto-credit on transaction completion
   - ❌ Rejected: Per user requirements, manual approval needed

2. **Time-Delayed Auto-Approval**: Auto-approve after 24 hours
   - ❌ Rejected: Doesn't meet manual approval requirement

**Best Practices**:
- Store points in `loyalty_points_transactions` table with status: `pending_approval | approved | rejected | revoked`
- Create merchant dashboard page showing pending points transactions
- Display customer name, purchase details, points amount, date
- Provide bulk approval checkbox (select all, approve selected)
- Send customer notification on approval (WhatsApp/SMS/email)
- Implement points revocation for returns/refunds
- Track audit trail: approving staff member, timestamp, reason for rejection

**UX Considerations**:
- Remind merchants about pending approvals (notification badge on dashboard)
- Auto-expire pending points after 30 days (prevent indefinite pending state)
- Allow filtering by customer, date range, points amount

---

## Summary of Key Decisions

| Decision Area | Chosen Solution | Primary Rationale |
|---------------|----------------|------------------|
| Offline Sync | PowerSync + SQLite | Production-ready, conflict resolution, Supabase integration |
| Multi-Tenancy | Supabase RLS Policies | Database-level isolation, defense-in-depth security |
| Authentication | Passkeys + PIN + OTP | Fast POS login, fallback chain, reduced SMS costs |
| Payments | Paystack (+ Flutterwave) | Nigerian market leader, local payment methods |
| Data Retention | Indefinite with cold archival | Business requirement, cost optimization |
| Real-Time | Supabase Realtime | Native integration, RLS support, scalable |
| File Storage | Supabase Storage | Integrated auth/RLS, image optimization, CDN |
| Analytics | PostgreSQL + Chart.js | Sufficient for scale, lightweight client charts |
| E-Commerce Sync | Webhooks + OAuth | Real-time, standard approach, no polling |
| Delivery Fees | Merchant-configured + distance | Flexibility, transparency, per spec |
| Support System | Custom with SLA tracking | Simple requirements, better integration |
| PWA | next-pwa (Workbox) | Next.js integration, production-ready caching |
| Chat | Live Agent + AI Toggle | Flexibility, tier-appropriate features |
| Loyalty Approval | Manual with bulk approval | Per spec, prevents abuse, merchant control |

---

**Phase 0 Status**: ✅ Complete

All technical decisions documented with rationale and alternatives. Ready to proceed to Phase 1: Data Model & Contracts.
