# Implementation Roadmap

## Current Status ✅

- ✅ Database schema designed (12 migrations)
- ✅ Subscription tiers defined (5 plans)
- ✅ E-commerce storefront architecture planned
- ✅ Rich media chat system designed
- ✅ Commission structure with ₦500 cap
- ✅ Documentation complete

## What's Next

---

## Phase 1: Database Setup & Validation (Week 1)

### 1.1 Apply All Migrations

**Priority:** 🔴 Critical

```bash
# Navigate to project
cd C:\Users\AFOKE\kemani

# Apply migrations via Supabase Dashboard or CLI
supabase db push

# Or manually apply in order:
# 001_extensions_and_enums.sql
# 002_core_tables.sql
# 003_product_inventory_tables.sql
# 004_customer_sales_tables.sql
# 005_order_delivery_tables.sql
# 006_additional_tables.sql
# 007_indexes.sql
# 008_rls_policies.sql
# 009_triggers.sql
# 010_seed_data.sql
# 011_chat_enhancements.sql
# 012_ecommerce_enhancements.sql
```

**Validation:**
```sql
-- Check all 5 subscription plans were created
SELECT plan_tier, monthly_fee, commission_rate, commission_cap_amount
FROM subscriptions
ORDER BY monthly_fee;

-- Should return: free, basic, pro, enterprise, enterprise_custom
```

---

### 1.2 Set Up Row Level Security (RLS)

**Priority:** 🔴 Critical

**File:** `supabase/migrations/008_rls_policies.sql`

Tasks:
- Review and update RLS policies
- Ensure tenants can only access their own data
- Set up policies for:
  - Tenants (admin access)
  - Branches (tenant-scoped)
  - Products (tenant + branch scoped)
  - Orders (tenant + branch scoped)
  - Chat (tenant + customer scoped)
  - E-commerce products (public read, tenant write)

**Test RLS:**
```sql
-- Test as tenant user
SET LOCAL ROLE authenticated;
SET LOCAL request.jwt.claims TO '{"sub": "user-uuid", "tenant_id": "tenant-uuid"}';

-- Should only return this tenant's data
SELECT * FROM products;
```

---

### 1.3 Create Test Data

**Priority:** 🟡 Important

Create sample data for development:

```sql
-- Create a test tenant on Pro plan
INSERT INTO tenants (name, slug, email, ecommerce_enabled, subscription_id)
VALUES (
    'Acme Supermarket',
    'acme-supermarket',
    'admin@acme.com',
    TRUE,
    (SELECT id FROM subscriptions WHERE plan_tier = 'pro')
);

-- Create 2-3 branches
-- Add 20-30 sample products across categories
-- Create sample customers
-- Add test orders
```

**Use seed script:**
```bash
# Create test data script
psql -h [db-host] -U postgres -d postgres -f scripts/seed-test-data.sql
```

---

## Phase 2: Core POS Features (Weeks 2-4)

### 2.1 Authentication & User Management

**Priority:** 🔴 Critical

**Tech Stack:**
- Supabase Auth
- Next.js 14 App Router
- Server Components

**Features to Build:**
- [ ] Login/Logout (email + password)
- [ ] User registration (tenant admin)
- [ ] Role-based access control (RBAC)
  - Platform Admin
  - Tenant Admin
  - Branch Manager
  - Cashier
  - Driver
- [ ] User profile management
- [ ] Password reset

**Pages:**
```
app/
├── (auth)/
│   ├── login/page.tsx
│   ├── register/page.tsx
│   └── forgot-password/page.tsx
└── dashboard/
    └── users/
        ├── page.tsx          # User list
        └── [id]/page.tsx     # User details
```

---

### 2.2 Tenant & Branch Management

**Priority:** 🔴 Critical

**Features:**
- [ ] Tenant onboarding flow
- [ ] Subscription plan selection
- [ ] Branch creation/management
- [ ] Branch location mapping (PostGIS)
- [ ] Business settings
  - Logo upload
  - Brand colors
  - Tax rates
  - Currency

**Pages:**
```
app/dashboard/
├── settings/
│   ├── page.tsx              # Tenant settings
│   ├── subscription/page.tsx # Plan management
│   └── branding/page.tsx     # Logo, colors
└── branches/
    ├── page.tsx              # Branch list
    ├── new/page.tsx          # Create branch
    └── [id]/page.tsx         # Branch details
```

---

### 2.3 Product & Inventory Management

**Priority:** 🔴 Critical

**Features:**
- [ ] Product CRUD operations
- [ ] Category management
- [ ] SKU/Barcode scanning
- [ ] Stock quantity tracking
- [ ] Low stock alerts
- [ ] Expiry date tracking
- [ ] Product image upload (Supabase Storage)
- [ ] Bulk import/export (CSV)
- [ ] Inter-branch transfers

**Pages:**
```
app/dashboard/
├── products/
│   ├── page.tsx              # Product grid/list
│   ├── new/page.tsx          # Add product
│   ├── [id]/page.tsx         # Edit product
│   └── import/page.tsx       # Bulk import
├── inventory/
│   ├── page.tsx              # Stock overview
│   ├── transactions/page.tsx # Transaction log
│   └── transfers/page.tsx    # Inter-branch transfers
└── categories/
    └── page.tsx              # Manage categories
```

---

### 2.4 Point of Sale (POS) Interface

**Priority:** 🔴 Critical

**Features:**
- [ ] Product search & selection
- [ ] Barcode scanner integration
- [ ] Cart management (add/remove items)
- [ ] Customer selection (optional)
- [ ] Apply discounts
- [ ] Multiple payment methods
  - Cash
  - Card
  - Bank Transfer
  - Mobile Money
- [ ] Receipt generation (PDF)
- [ ] Print receipt (thermal printer)
- [ ] Offline mode (PWA)
- [ ] Sync when online

**Pages:**
```
app/
└── pos/
    ├── page.tsx              # Main POS interface
    └── receipt/[id]/page.tsx # View/print receipt
```

**Key Considerations:**
- Fast, keyboard-friendly interface
- Touch-optimized for tablets
- Works offline (IndexedDB + sync)
- Barcode scanner support

---

## Phase 3: E-Commerce Storefront (Weeks 5-6)

### 3.1 Storefront Frontend

**Priority:** 🟢 Medium

**Features:**
- [ ] Tenant storefront at `/[slug]`
- [ ] Product catalog (multi-branch)
- [ ] Category filtering
- [ ] Branch filtering
- [ ] Location-based filtering (5km, 10km, etc.)
- [ ] Product search
- [ ] Product detail page
- [ ] Shopping cart
- [ ] Checkout flow
- [ ] Order tracking
- [ ] Customer account
- [ ] Order history

**Pages:**
```
app/
└── [slug]/                   # Tenant storefront
    ├── page.tsx              # Homepage/catalog
    ├── products/
    │   └── [id]/page.tsx     # Product detail
    ├── cart/page.tsx         # Shopping cart
    ├── checkout/page.tsx     # Checkout
    └── orders/
        ├── page.tsx          # Order history
        └── [id]/page.tsx     # Order tracking
```

---

### 3.2 Custom Domain Support (Enterprise Custom)

**Priority:** 🟡 Low

**Features:**
- [ ] DNS verification system
- [ ] SSL certificate setup (Let's Encrypt)
- [ ] Domain mapping
- [ ] Verification dashboard

**Implementation:**
- Use Vercel custom domains API
- Or Cloudflare Workers for routing
- Store verified domains in `tenants.custom_domain`

---

## Phase 4: Chat System (Week 7)

### 4.1 AI Chat Agent

**Priority:** 🟢 Medium

**Tech Stack:**
- OpenAI GPT-4 or Claude API
- Supabase Realtime (WebSockets)
- React Query for state management

**Features:**
- [ ] Chat widget on storefront (Pro+)
- [ ] AI responses for common questions
- [ ] Product recommendations
- [ ] Intent detection
- [ ] Escalation to human agent
- [ ] Rich media support
  - Images
  - Audio messages
  - Videos
  - Location sharing
- [ ] Product cards with "Add to Cart"
- [ ] Staff discount application
- [ ] Payment confirmation

**Components:**
```
components/
└── chat/
    ├── ChatWidget.tsx        # Floating chat button
    ├── ChatWindow.tsx        # Chat interface
    ├── MessageList.tsx       # Messages display
    ├── MessageInput.tsx      # Text + media input
    ├── ProductCard.tsx       # Product in chat
    └── LocationPicker.tsx    # Share location
```

---

### 4.2 Staff Chat Dashboard

**Priority:** 🟢 Medium

**Features:**
- [ ] View active conversations
- [ ] Take over from AI agent
- [ ] Send messages (text, media, products)
- [ ] Apply discounts in chat
- [ ] Mark conversation as resolved
- [ ] Chat analytics

**Pages:**
```
app/dashboard/
└── chat/
    ├── page.tsx              # Conversations list
    └── [id]/page.tsx         # Chat interface
```

---

## Phase 5: Orders & Delivery (Week 8)

### 5.1 Order Management

**Priority:** 🟢 Medium

**Features:**
- [ ] Order list (all sources)
  - In-store POS
  - E-commerce
  - AI Chat
- [ ] Order status workflow
  - Pending → Confirmed → Preparing → Ready → Completed
- [ ] Order details view
- [ ] Update order status
- [ ] Cancel/refund orders
- [ ] WhatsApp notifications

**Pages:**
```
app/dashboard/
└── orders/
    ├── page.tsx              # Orders list
    └── [id]/page.tsx         # Order details
```

---

### 5.2 Delivery Management

**Priority:** 🟢 Medium

**Features:**
- [ ] Rider management (CRUD)
- [ ] Assign rider to delivery
- [ ] Track delivery status
- [ ] Delivery proof upload (photo/signature)
- [ ] Route optimization (Google Maps API)
- [ ] Real-time delivery tracking
- [ ] Customer notifications (WhatsApp)

**Pages:**
```
app/dashboard/
├── deliveries/
│   ├── page.tsx              # Deliveries list
│   └── [id]/page.tsx         # Delivery tracking
└── riders/
    ├── page.tsx              # Riders list
    └── [id]/page.tsx         # Rider profile
```

---

## Phase 6: Analytics & Reporting (Week 9)

### 6.1 Sales Analytics

**Priority:** 🟢 Medium

**Features:**
- [ ] Daily sales overview
- [ ] Revenue trends (charts)
- [ ] Top-selling products
- [ ] Sales by branch
- [ ] Sales by category
- [ ] Sales by cashier
- [ ] Low stock alerts
- [ ] Expiry alerts
- [ ] Export reports (CSV, PDF)

**Pages:**
```
app/dashboard/
├── page.tsx                  # Dashboard home
└── analytics/
    ├── sales/page.tsx        # Sales analytics
    ├── products/page.tsx     # Product analytics
    └── customers/page.tsx    # Customer insights
```

**Tech:**
- Charts: Recharts or Chart.js
- Date ranges: react-day-picker
- Export: jsPDF, Papa Parse

---

### 6.2 Commission Tracking

**Priority:** 🟡 Important

**Features:**
- [ ] View commission breakdown
- [ ] Monthly commission summary
- [ ] Commission per order
- [ ] Settlement status
- [ ] Download invoices

**Pages:**
```
app/dashboard/
└── commissions/
    ├── page.tsx              # Commission dashboard
    └── invoices/[id]/page.tsx # Invoice view
```

---

## Phase 7: Integrations (Week 10)

### 7.1 WhatsApp Business API

**Priority:** 🟢 Medium (Basic+)

**Features:**
- [ ] Order confirmations
- [ ] Delivery updates
- [ ] Payment reminders
- [ ] Template messages
- [ ] Two-way chat integration

**Provider Options:**
- Twilio WhatsApp API
- 360dialog
- Meta Cloud API

---

### 7.2 E-Commerce Platform Sync

**Priority:** 🟡 Low (Pro+)

**Features:**
- [ ] WooCommerce product sync
- [ ] Shopify product sync
- [ ] Order import from WooCommerce/Shopify
- [ ] Inventory sync (bi-directional)

**Implementation:**
- Webhook listeners
- Scheduled sync jobs (cron)
- Conflict resolution

---

### 7.3 Payment Gateways

**Priority:** 🔴 Critical

**Providers:**
- Paystack (Nigeria)
- Flutterwave (Africa-wide)
- Stripe (International)

**Features:**
- [ ] Card payments
- [ ] Bank transfer
- [ ] Mobile money (MTN, Airtel)
- [ ] Payment verification
- [ ] Refunds

---

## Phase 8: Advanced Features (Weeks 11-12)

### 8.1 Mobile App (Optional)

**Priority:** 🟡 Low

**Tech Stack:**
- React Native or Flutter
- Expo (for React Native)

**Apps:**
1. **Cashier App** - POS on mobile
2. **Manager App** - Inventory & reports
3. **Rider App** - Delivery tracking

---

### 8.2 Offline Support (PWA)

**Priority:** 🟢 Medium

**Features:**
- [ ] Service Worker
- [ ] IndexedDB for offline data
- [ ] Background sync
- [ ] Offline POS transactions
- [ ] Auto-sync when online

**Tech:**
- Workbox (Service Worker)
- Dexie.js (IndexedDB)
- Next.js PWA plugin

---

### 8.3 Multi-Currency Support

**Priority:** 🟡 Low (Enterprise+)

**Features:**
- [ ] Currency selection per tenant
- [ ] Exchange rate management
- [ ] Price conversion
- [ ] Multi-currency reporting

---

## Tech Stack Summary

### Frontend
- **Framework:** Next.js 14 (App Router)
- **UI Library:** Tailwind CSS 4
- **Components:** shadcn/ui or Radix UI
- **State:** React Query + Zustand
- **Forms:** React Hook Form + Zod
- **Charts:** Recharts
- **Icons:** Lucide React

### Backend
- **Database:** PostgreSQL (Supabase)
- **Auth:** Supabase Auth
- **Storage:** Supabase Storage
- **Realtime:** Supabase Realtime
- **API:** Next.js API Routes / Server Actions

### DevOps
- **Hosting:** Vercel
- **Database:** Supabase (hosted PostgreSQL)
- **CDN:** Vercel Edge Network
- **Monitoring:** Sentry
- **Analytics:** PostHog or Vercel Analytics

---

## Immediate Next Steps (Today/This Week)

### 1. Apply Database Migrations ⚡

```bash
# Option A: Supabase Dashboard
# 1. Go to Supabase Dashboard → SQL Editor
# 2. Copy/paste each migration file content
# 3. Run in order (001 → 012)

# Option B: Supabase CLI
supabase db push
```

### 2. Verify Database Setup ⚡

```sql
-- Check subscription plans
SELECT * FROM subscriptions;

-- Check enums
SELECT enum_range(NULL::plan_tier);

-- Check functions
SELECT proname FROM pg_proc WHERE proname LIKE '%ecommerce%';
```

### 3. Set Up Development Environment ⚡

```bash
# Install dependencies
npm install

# Set up environment variables
cp .env.example .env.local

# Add Supabase credentials
NEXT_PUBLIC_SUPABASE_URL=your-project-url
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
```

### 4. Create First Feature Branch ⚡

```bash
git checkout -b feature/authentication

# Start building login page
# app/(auth)/login/page.tsx
```

### 5. Build Authentication (Day 1-2) ⚡

**File to create:** `app/(auth)/login/page.tsx`

```typescript
import { createClient } from '@/lib/supabase/server';
import { redirect } from 'next/navigation';

export default async function LoginPage() {
  // Login form with Supabase Auth
  // Redirect to /dashboard on success
}
```

---

## Recommended Build Order

**Week 1:**
- ✅ Database migrations
- ⚡ Authentication & user management
- ⚡ Tenant setup flow

**Week 2:**
- ⚡ Branch management
- ⚡ Product CRUD

**Week 3:**
- ⚡ Inventory management
- ⚡ POS interface (basic)

**Week 4:**
- ⚡ Sales & receipts
- ⚡ Customer management

**Week 5:**
- E-commerce storefront (catalog)
- Shopping cart & checkout

**Week 6:**
- E-commerce storefront (checkout & orders)
- Payment integration

**Week 7:**
- Chat system (AI agent)
- Chat dashboard for staff

**Week 8:**
- Order management
- Delivery tracking

**Week 9:**
- Analytics dashboard
- Reports

**Week 10:**
- WhatsApp integration
- WooCommerce/Shopify sync

**Weeks 11-12:**
- Polish & testing
- Deployment
- Documentation

---

## Success Metrics

**Technical:**
- [ ] All 12 migrations applied successfully
- [ ] RLS policies working correctly
- [ ] Authentication flow complete
- [ ] POS can process sales offline
- [ ] E-commerce storefront loads in <2s
- [ ] Chat responses in <1s

**Business:**
- [ ] 10 test tenants onboarded
- [ ] 100+ products in catalog
- [ ] 50+ test orders processed
- [ ] Commission calculation accurate
- [ ] Payments processing successfully

---

## Resources Needed

**Development:**
- Supabase account (free tier OK for now)
- Vercel account (free tier)
- OpenAI API key (for chat)
- Paystack/Flutterwave test credentials

**Optional:**
- Google Maps API key (delivery tracking)
- Twilio account (WhatsApp)
- Sentry account (error tracking)

---

## Questions to Resolve

1. **Payment Gateway:** Which provider? Paystack (₦) or Flutterwave?
2. **AI Chat:** OpenAI GPT-4 or Claude? Budget for API calls?
3. **WhatsApp:** Required for MVP or phase 2?
4. **Mobile Apps:** React Native or Flutter? Timeline?
5. **Deployment:** Single Vercel project or separate frontend/backend?

---

## Want me to start building?

I can help you:
1. ✅ **Apply database migrations** → Verify everything works
2. ✅ **Set up authentication** → Login/register pages
3. ✅ **Build first dashboard** → Tenant overview
4. ✅ **Create POS interface** → Start with basic product selection

**Which would you like to tackle first?**
