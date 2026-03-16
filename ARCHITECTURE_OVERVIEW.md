# Kemani Platform Architecture Overview

## 🏗️ Current Architecture

The Kemani platform is a **multi-app monorepo** with two separate frontend applications sharing a common backend:

```
┌─────────────────────────────────────────────────────────────────┐
│                     KEMANI PLATFORM                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌────────────────────────┐    ┌────────────────────────────┐  │
│  │   E-Commerce Storefront│    │  Healthcare Customer App   │  │
│  │  (apps/storefront/)    │    │  (apps/healthcare_customer)│  │
│  │                        │    │                            │  │
│  │  - Product Marketplace │    │  - Provider Directory      │  │
│  │  - Shopping Cart       │    │  - Book Consultations      │  │
│  │  - Checkout & Payment  │    │  - Video/Chat Sessions     │  │
│  │  - Order Tracking      │    │  - Prescriptions           │  │
│  │  - Loyalty Points      │    │  - Health Records          │  │
│  │                        │    │                            │  │
│  │  Port: 5174            │    │  Port: 5173                │  │
│  └───────────┬────────────┘    └────────────┬───────────────┘  │
│              │                               │                   │
│              └───────────┬───────────────────┘                   │
│                          │                                       │
│                          ▼                                       │
│              ┌─────────────────────────┐                        │
│              │   SHARED SUPABASE       │                        │
│              │   DATABASE & AUTH       │                        │
│              │                         │                        │
│              │  - Multi-tenant schema  │                        │
│              │  - Authentication       │                        │
│              │  - Row-Level Security   │                        │
│              │  - Real-time sync       │                        │
│              └─────────────────────────┘                        │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## 📊 Current Integration Model

### Option 1: **Separate Applications** (Current State)

Both apps are **standalone** but share the same database:

```
Customer Journey A: E-Commerce
┌──────────────────────────────────────────────────┐
│ 1. Visit: https://shop.kemani.com               │
│ 2. Browse products                               │
│ 3. Add to cart                                   │
│ 4. Login with email OTP                          │
│ 5. Checkout & pay                                │
│ 6. Track order                                   │
└──────────────────────────────────────────────────┘

Customer Journey B: Healthcare
┌──────────────────────────────────────────────────┐
│ 1. Visit: https://medic.kemani.com              │
│ 2. Browse providers                              │
│ 3. Select consultation type                      │
│ 4. Login with email OTP (SAME AUTH)             │
│ 5. Book & pay                                    │
│ 6. Join video call                               │
└──────────────────────────────────────────────────┘
```

**Shared Components:**
- ✅ Authentication system (Supabase Auth)
- ✅ Customer records (`customers` table)
- ✅ Payment gateway (Paystack/Flutterwave)
- ✅ Tenant management
- ✅ Loyalty points system

**Separate Components:**
- 📦 Products vs. Healthcare Providers
- 📦 Shopping cart vs. Consultation booking
- 📦 Physical delivery vs. Virtual consultations
- 📦 Inventory management vs. Provider availability

### Option 2: **Unified Platform** (Integration Approach)

You can integrate both into a single customer experience:

```
┌─────────────────────────────────────────────────────────────────┐
│               KEMANI UNIFIED CUSTOMER PORTAL                     │
│                  https://kemani.com                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Navigation:  [Shop] [Medic] [My Account] [Cart/Bookings]      │
│                                                                  │
│  ┌─────────────────────┐      ┌─────────────────────┐          │
│  │  Shop Tab           │      │  Medic Tab          │          │
│  │  (/shop)            │      │  (/medic)           │          │
│  │                     │      │                     │          │
│  │  - Products         │      │  - Providers        │          │
│  │  - Orders           │      │  - Consultations    │          │
│  │  - Delivery         │      │  - Prescriptions    │          │
│  └─────────────────────┘      └─────────────────────┘          │
│                                                                  │
│  ┌──────────────────────────────────────────────────┐          │
│  │  Shared Customer Dashboard                       │          │
│  │  (/dashboard)                                    │          │
│  │                                                  │          │
│  │  - Single Sign-On                               │          │
│  │  - Unified order history (products + medic)     │          │
│  │  - Combined loyalty points                      │          │
│  │  - One wallet for both services                 │          │
│  │  - Shared payment methods                       │          │
│  └──────────────────────────────────────────────────┘          │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## 🗄️ Database Integration

### Shared Tables

Both apps use the **same Supabase database** with these shared tables:

#### 1. **`customers`** - Shared customer records
```sql
-- Single customer record for both shop and medic
CREATE TABLE customers (
    id UUID PRIMARY KEY,           -- Same across both apps
    tenant_id UUID,                -- Business/organization
    email VARCHAR,                 -- Shared login
    full_name VARCHAR,
    phone VARCHAR,
    loyalty_points INTEGER,        -- Earned from both shop + medic
    total_purchases DECIMAL,       -- Combined from both
    created_at TIMESTAMPTZ
);
```

**Integration:**
- Customer signs up once → can access both shop and medic
- Loyalty points earned from **both** product purchases and consultations
- Single profile, single login

#### 2. **Tenant Isolation**

```sql
-- Multi-tenant architecture
CREATE TABLE tenants (
    id UUID PRIMARY KEY,
    business_name VARCHAR,
    tenant_type VARCHAR,  -- 'ecommerce', 'healthcare', 'both'
    -- ...
);
```

**Use cases:**
1. **Pure E-commerce**: `tenant_type = 'ecommerce'` → Only storefront enabled
2. **Pure Healthcare**: `tenant_type = 'healthcare'` → Only medic enabled
3. **Hybrid (Pharmacy + Clinic)**: `tenant_type = 'both'` → Both enabled

#### 3. **Separate Domain Tables**

**E-Commerce Tables:**
- `products` - Physical/digital products
- `orders` - Product orders
- `order_items` - Order line items
- `branch_inventory` - Stock management

**Healthcare Tables:**
- `healthcare_providers` - Doctors, pharmacists
- `consultations` - Video/chat sessions
- `prescriptions` - Digital prescriptions
- `provider_time_slots` - Booking availability

## 🔐 Authentication Integration

### Shared Authentication Flow

Both apps use **the same authentication system**:

```typescript
// Same auth service used in both apps
import { AuthService } from '$lib/services/auth';

// Login flow (identical in both apps)
await AuthService.sendOTP({
  email: 'customer@example.com',
  full_name: 'John Doe'
});

// Verify OTP
await AuthService.verifyOTP(email, code);
```

**What's shared:**
- ✅ Email OTP verification
- ✅ Session management
- ✅ Customer record creation
- ✅ Password reset
- ✅ Session cookies

**Customer Experience:**
```
1. Login on storefront → Creates customer record
2. Visit healthcare app → ALREADY LOGGED IN
3. Book consultation → Same customer_id used
4. Return to shop → Still logged in
```

## 💰 Payment Integration

### Shared Payment Gateway

Both apps can use the **same payment configuration**:

```typescript
// apps/storefront/src/lib/services/payment.ts
export class PaymentService {
  static async initializePayment(amount: number, purpose: 'product' | 'consultation') {
    // Same Paystack/Flutterwave account
    // Different metadata for tracking
    const metadata = {
      customer_id: user.id,
      tenant_id: tenant.id,
      purpose: purpose,  // 'product' or 'consultation'
    };

    return await paystack.initializeTransaction({
      amount,
      email: user.email,
      metadata
    });
  }
}
```

**Payment Flow:**
1. Customer pays for products → `purpose: 'product'` → Creates order
2. Customer pays for consultation → `purpose: 'consultation'` → Creates consultation
3. **Same payment gateway, different entities created**

## 🎯 Integration Scenarios

### Scenario 1: **Pharmacy + Telemedicine**

Perfect integration example:

```
Customer Flow:
1. Books telemedicine consultation (healthcare app)
2. Doctor prescribes medication
3. Prescription auto-added to shopping cart (ecommerce app)
4. Customer pays and gets medication delivered
```

**Implementation:**
```typescript
// After consultation, create prescription
const prescription = await createPrescription({
  consultation_id: consultation.id,
  medications: ['Paracetamol 500mg', 'Vitamin C']
});

// Option A: Auto-add to cart
await addPrescriptionToCart(prescription.id);

// Option B: Send link to purchase
await sendEmail({
  to: customer.email,
  subject: 'Your prescription is ready',
  link: `https://shop.kemani.com/prescriptions/${prescription.id}`
});
```

### Scenario 2: **Wellness Products + Nutrition Consultation**

```
1. Customer buys fitness supplements (shop)
2. Gets free nutrition consultation as loyalty reward
3. Consultation booked through healthcare app
4. Nutritionist recommends more products
5. Products added to cart with discount
```

### Scenario 3: **Medical Equipment Store + Device Training**

```
1. Customer buys blood pressure monitor (shop)
2. Receives link to book free training session
3. Video consultation on how to use device (medic)
4. Follow-up consultations available for purchase
```

## 🔄 Data Flow Examples

### Example 1: Shared Loyalty Points

```sql
-- Customer buys products → Earns points
INSERT INTO loyalty_transactions (
  customer_id,
  points_earned,
  source,
  source_id
) VALUES (
  '123-customer-id',
  50,
  'product_purchase',
  'order-456'
);

-- Customer books consultation → Earns points
INSERT INTO loyalty_transactions (
  customer_id,
  points_earned,
  source,
  source_id
) VALUES (
  '123-customer-id',
  100,
  'consultation',
  'consultation-789'
);

-- Total points available for both shop and medic
SELECT SUM(points_earned - points_redeemed) as total_points
FROM loyalty_transactions
WHERE customer_id = '123-customer-id';
-- Result: 150 points (can use on either platform)
```

### Example 2: Unified Order History

```typescript
// Fetch all customer transactions
const getCustomerActivity = async (customerId: string) => {
  // Product orders
  const orders = await supabase
    .from('orders')
    .select('*, order_items(*)')
    .eq('customer_id', customerId);

  // Healthcare consultations
  const consultations = await supabase
    .from('consultations')
    .select('*, provider:healthcare_providers(*)')
    .eq('patient_id', customerId);

  // Combine and sort by date
  return [...orders, ...consultations]
    .sort((a, b) => new Date(b.created_at) - new Date(a.created_at));
};
```

**Customer sees:**
```
My Activity:
- Mar 10, 2026: Video consultation with Dr. Smith - ₦5,000
- Mar 8, 2026: Ordered Paracetamol x2 - ₦1,200
- Mar 5, 2026: Chat consultation with Pharmacist - ₦2,000
- Mar 1, 2026: Ordered Vitamins x3 - ₦8,500
```

## 🚀 Deployment Strategies

### Strategy 1: **Separate Domains (Current)**

```
https://shop.kemani.com    → E-commerce storefront
https://medic.kemani.com   → Healthcare customer app
https://api.kemani.com     → Shared Supabase backend
```

**Pros:**
- ✅ Independent deployments
- ✅ Different UX optimizations
- ✅ Easier to scale separately
- ✅ Clear separation of concerns

**Cons:**
- ❌ Customer switches between domains
- ❌ Harder to cross-sell
- ❌ Duplicate navigation/layout code

### Strategy 2: **Unified Domain with Routes**

```
https://kemani.com/shop      → E-commerce routes
https://kemani.com/medic     → Healthcare routes
https://kemani.com/dashboard → Unified customer portal
https://kemani.com/api       → Shared backend
```

**Pros:**
- ✅ Single domain (better SEO)
- ✅ Shared session/cookies
- ✅ Easier cross-selling
- ✅ Unified branding

**Cons:**
- ❌ More complex routing
- ❌ Larger bundle size
- ❌ Coupled deployments

### Strategy 3: **Micro-Frontends**

```
https://kemani.com
  ├── /shop      → Loads shop micro-frontend
  ├── /medic     → Loads medic micro-frontend
  └── /dashboard → Shared shell
```

**Pros:**
- ✅ Best of both worlds
- ✅ Independent dev teams
- ✅ Shared shell for common UI
- ✅ Lazy loading

## 📱 Recommended Integration Approach

### Option A: **Gradual Integration** (Recommended)

Keep separate apps but add cross-linking:

**Phase 1: Add Navigation Links**
```svelte
<!-- In storefront header -->
<nav>
  <a href="/">Shop</a>
  <a href="https://medic.kemani.com">Healthcare</a>
  <a href="/dashboard">My Account</a>
</nav>

<!-- In healthcare header -->
<nav>
  <a href="https://shop.kemani.com">Shop</a>
  <a href="/">Healthcare</a>
  <a href="/dashboard">My Account</a>
</nav>
```

**Phase 2: Shared Dashboard**

Create `/dashboard` route in both apps showing:
- Combined activity (orders + consultations)
- Unified loyalty points
- Single payment methods
- Shared addresses

**Phase 3: Cross-Selling**

In storefront:
```svelte
<!-- After checkout -->
<div class="upsell">
  <h3>Want to consult with a healthcare provider?</h3>
  <p>Book a free consultation with our pharmacist!</p>
  <a href="https://medic.kemani.com/providers?type=pharmacist">
    Book Now
  </a>
</div>
```

In healthcare app:
```svelte
<!-- After consultation -->
<div class="prescription">
  <h3>Your Prescription</h3>
  <p>Order your prescribed medications now!</p>
  <a href="https://shop.kemani.com/prescriptions/{prescriptionId}">
    Order Medications
  </a>
</div>
```

### Option B: **Full Integration** (Future)

Merge into single SvelteKit app:

```
apps/unified/
├── src/
│   ├── routes/
│   │   ├── shop/           # E-commerce routes
│   │   ├── medic/          # Healthcare routes
│   │   ├── dashboard/      # Shared portal
│   │   └── +layout.svelte  # Shared navigation
│   ├── lib/
│   │   ├── shop/           # Shop-specific components
│   │   ├── medic/          # Medic-specific components
│   │   └── shared/         # Shared components
```

## 📊 Database Schema Shared vs Separate

### Shared Schema (Both Apps Use)

```sql
-- Authentication & Customers
- auth.users                 ✅ SHARED
- customers                  ✅ SHARED
- customer_addresses         ✅ SHARED
- tenants                    ✅ SHARED
- branches                   ✅ SHARED
- users                      ✅ SHARED

-- Loyalty & Payments
- loyalty_transactions       ✅ SHARED
- payment_methods            ✅ SHARED (if implemented)
```

### E-Commerce Only

```sql
- products
- categories
- brands
- branch_inventory
- orders
- order_items
- sales
- sale_items
```

### Healthcare Only

```sql
- healthcare_providers
- provider_time_slots
- provider_availability_templates
- consultations
- consultation_messages
- prescriptions
- consultation_transactions
- favorite_providers
```

## 🎯 Summary

### Current State:
- ✅ Two **separate applications**
- ✅ **Shared authentication** (same login)
- ✅ **Shared database** (Supabase)
- ✅ **Shared customer records**
- ⏳ **Not visually connected** (different URLs)

### Integration Level:
- **Backend**: 90% integrated (shared database, auth, customers)
- **Frontend**: 10% integrated (separate apps, no cross-linking)
- **User Experience**: 0% integrated (user doesn't know they're related)

### Best Next Steps:

1. **Keep separate apps** (easier to maintain)
2. **Add cross-navigation** (link between shop and medic)
3. **Create shared dashboard** (unified customer view)
4. **Enable cross-selling** (recommend medic in shop, products in medic)
5. **Unified branding** (same logo, colors, theme)

### Future Vision:

A customer can:
1. Shop for wellness products
2. Book a nutrition consultation
3. Get personalized product recommendations
4. Order prescribed medications
5. Track everything in one dashboard
6. Use loyalty points across both services
7. Make all payments with one saved method

**All while feeling like ONE seamless platform!** 🚀

Would you like me to implement any specific integration feature?
