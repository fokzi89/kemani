# User Story 3: Customer Management and Marketplace Storefront - Analysis

**Date**: 2026-02-27
**Status**: Database schema exists, UI implementation needed

## Overview

User Story 3 focuses on:
- Digital storefront for tenant businesses
- Customer browsing and ordering (delivery or pickup)
- Purchase history and loyalty points
- Customer profile management

## Acceptance Scenarios

### AS1: Storefront Product Browsing
**Given** a tenant publishes their storefront, **When** nearby customers access the marketplace, **Then** they can browse products from this tenant with real-time inventory visibility

### AS2: Order Management
**Given** a customer places an order, **When** the order is confirmed, **Then** it appears in the merchant's order management system with customer details and fulfillment options (pickup or delivery)

### AS3: Loyalty Points
**Given** a customer completes a purchase, **When** the sale is recorded, **Then** the customer earns loyalty points based on purchase amount and their profile shows updated purchase history

### AS4: Purchase History
**Given** a returning customer, **When** they log in, **Then** they can view their complete purchase history across all orders and current loyalty points balance

### AS5: Customer Analytics
**Given** a merchant views customer data, **When** they access customer management, **Then** they see customer profiles, purchase frequency, total spend, and loyalty status

## Current Implementation Status

### ✅ Database Schema (100% Complete)

#### Customers Table
Location: `supabase/migrations/004_customer_sales_tables.sql`

```sql
CREATE TABLE customers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    phone VARCHAR(20) NOT NULL,
    email VARCHAR(255),
    full_name VARCHAR(255) NOT NULL,
    whatsapp_number VARCHAR(20),
    loyalty_points INTEGER NOT NULL DEFAULT 0,        -- ✅ AS3
    total_purchases DECIMAL(12,2) DEFAULT 0,          -- ✅ AS5
    purchase_count INTEGER DEFAULT 0,                 -- ✅ AS5
    last_purchase_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ,
    _sync_version BIGINT DEFAULT 1,
    _sync_modified_at TIMESTAMPTZ DEFAULT NOW(),
    _sync_client_id UUID,
    _sync_is_deleted BOOLEAN DEFAULT FALSE
);
```

**Features:**
- ✅ Multi-tenant isolation (tenant_id FK)
- ✅ Customer contact info (phone, email, WhatsApp)
- ✅ Loyalty points tracking (AS3)
- ✅ Purchase analytics (total_purchases, purchase_count, last_purchase_at) (AS5)
- ✅ Soft delete support (deleted_at)
- ✅ Offline sync support (_sync_* fields)

#### Customer Addresses Table
Location: `supabase/migrations/004_customer_sales_tables.sql`

```sql
CREATE TABLE customer_addresses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    label VARCHAR(50),
    address_line TEXT NOT NULL,
    latitude DECIMAL(10,8),
    longitude DECIMAL(11,8),
    is_default BOOLEAN DEFAULT FALSE
);
```

**Features:**
- ✅ Multiple addresses per customer
- ✅ Geolocation support (lat/long)
- ✅ Default address selection
- ✅ Address labels (Home, Work, etc.)

#### Orders Table
Location: `supabase/migrations/005_order_delivery_tables.sql`

```sql
CREATE TABLE orders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
    order_number VARCHAR(50) NOT NULL,
    customer_id UUID NOT NULL REFERENCES customers(id),
    order_type order_type NOT NULL,                   -- marketplace, pos, ecommerce, chat
    order_status order_status DEFAULT 'pending',      -- pending, confirmed, preparing, ready, completed, cancelled
    payment_status payment_status DEFAULT 'unpaid',   -- unpaid, paid, refunded, partial
    payment_method payment_method,
    payment_reference VARCHAR(255),
    subtotal DECIMAL(12,2) NOT NULL,
    delivery_fee DECIMAL(12,2) DEFAULT 0,
    tax_amount DECIMAL(12,2) DEFAULT 0,
    total_amount DECIMAL(12,2) NOT NULL,
    fulfillment_type fulfillment_type NOT NULL,       -- pickup, delivery (AS2)
    delivery_address_id UUID REFERENCES customer_addresses(id),
    special_instructions TEXT,
    ecommerce_platform VARCHAR(50),
    ecommerce_order_id VARCHAR(255),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

**Features:**
- ✅ Multi-tenant isolation
- ✅ Customer relationship (AS2, AS4)
- ✅ Order type (marketplace, POS, ecommerce, chat)
- ✅ Order status workflow
- ✅ Payment tracking
- ✅ Fulfillment options: pickup or delivery (AS2)
- ✅ Special instructions
- ✅ E-commerce platform integration ready

#### Order Items Table
Location: `supabase/migrations/005_order_delivery_tables.sql`

```sql
CREATE TABLE order_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id),
    product_name VARCHAR(255) NOT NULL,
    quantity INTEGER NOT NULL,
    unit_price DECIMAL(12,2) NOT NULL,
    subtotal DECIMAL(12,2) NOT NULL
);
```

**Features:**
- ✅ Line items for each order
- ✅ Product snapshot (product_name stored at time of order)
- ✅ Quantity and pricing
- ✅ Automatic subtotal calculation

#### RLS Policies
Location: `supabase/migrations/008_rls_policies.sql`

```sql
-- Customers
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Customer tenant isolation" ON customers
    USING (tenant_id = current_tenant_id());

-- Orders
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Order tenant isolation" ON orders
    USING (tenant_id = current_tenant_id());
CREATE POLICY "Order branch access" ON orders
    USING (branch_id IN (SELECT id FROM branches WHERE tenant_id = current_tenant_id()));
```

**Features:**
- ✅ Multi-tenant data isolation enforced at database level
- ✅ Branch-level access control for orders

### ❌ Backend Services (0% Complete)

**Missing:**
- ❌ Customer CRUD service methods
- ❌ Order creation service
- ❌ Loyalty points calculation logic
- ❌ Purchase history aggregation
- ❌ Customer search/filtering
- ❌ Order status updates
- ❌ Inventory reservation on order placement

### ❌ POS Admin UI - Customer Management (0% Complete)

**Missing:**
- ❌ Customer list screen with search/filter
- ❌ Customer detail view (profile, purchase history, loyalty points)
- ❌ Add/edit customer screen
- ❌ Customer address management
- ❌ Order management screen (view orders, update status)
- ❌ Order details view
- ❌ Customer analytics dashboard

**Expected Location**: `apps/pos_admin/lib/screens/customers/`

### ❌ Marketplace Storefront (0% Complete)

**Missing:**
- ❌ Tenant storefront pages (browse products by tenant)
- ❌ Product catalog with search/filter
- ❌ Product detail page
- ❌ Shopping cart
- ❌ Checkout flow (delivery/pickup selection)
- ❌ Customer login/registration
- ❌ Customer dashboard (order history, loyalty points)
- ❌ Order tracking page

**Expected App**: `apps/storefront/` (SvelteKit)
**Current Status**: Storefront app exists but contains only healthcare routes, no POS marketplace functionality

### ❌ Integration & E2E Tests (0% Complete)

**Missing:**
- ❌ Customer CRUD tests
- ❌ Order placement tests
- ❌ Loyalty points calculation tests
- ❌ Purchase history tests
- ❌ Multi-tenant customer isolation tests
- ❌ Storefront browsing tests
- ❌ Checkout flow tests

## Implementation Roadmap

### Phase 1: Backend Services (Priority: High)
**Estimated Effort**: 1 sprint

1. **Customer Service** (`apps/pos_admin/lib/services/customer_service.dart`)
   - createCustomer()
   - updateCustomer()
   - deleteCustomer()
   - getCustomer()
   - listCustomers(filters, pagination)
   - searchCustomers(query)
   - addCustomerAddress()
   - updateCustomerAddress()
   - setDefaultAddress()

2. **Order Service** (`apps/pos_admin/lib/services/order_service.dart`)
   - createOrder(customerId, items, fulfillmentType, addressId?)
   - updateOrderStatus(orderId, status)
   - getOrder(orderId)
   - listOrders(filters, pagination)
   - cancelOrder(orderId, reason)
   - getCustomerOrders(customerId)

3. **Loyalty Service** (`apps/pos_admin/lib/services/loyalty_service.dart`)
   - calculateLoyaltyPoints(purchaseAmount)
   - awardPoints(customerId, points, saleId)
   - getCustomerLoyaltyBalance(customerId)
   - getPurchaseHistory(customerId)
   - getCustomerAnalytics(customerId)

### Phase 2: POS Admin UI - Customer Management (Priority: High)
**Estimated Effort**: 1.5 sprints

1. **Customer List Screen** (`apps/pos_admin/lib/screens/customers/customer_list_screen.dart`)
   - DataTable with customers
   - Search by name, phone, email
   - Filter by loyalty tier, purchase frequency
   - Sort by total purchases, last purchase date
   - Pagination
   - Navigate to customer detail

2. **Customer Detail Screen** (`apps/pos_admin/lib/screens/customers/customer_detail_screen.dart`)
   - Customer profile info
   - Loyalty points balance
   - Purchase history (list of sales/orders)
   - Total spend, purchase count
   - Contact information
   - Edit customer button

3. **Add/Edit Customer Screen** (`apps/pos_admin/lib/screens/customers/customer_form_screen.dart`)
   - Form fields: name, phone, email, WhatsApp
   - Address management (add, edit, delete, set default)
   - Validation
   - Save customer

4. **Order Management Screen** (`apps/pos_admin/lib/screens/orders/order_list_screen.dart`)
   - DataTable with orders
   - Filter by status, order type, date range
   - Search by order number, customer name
   - Status badges (pending, confirmed, completed, cancelled)
   - Navigate to order detail

5. **Order Detail Screen** (`apps/pos_admin/lib/screens/orders/order_detail_screen.dart`)
   - Order information (number, date, customer)
   - Order items with quantities and prices
   - Payment info
   - Fulfillment type (pickup/delivery)
   - Delivery address (if delivery)
   - Status update controls
   - Cancel order button

### Phase 3: Marketplace Storefront (Priority: Medium)
**Estimated Effort**: 2 sprints

**Technology**: SvelteKit + Tailwind CSS
**Location**: `apps/storefront/src/routes/marketplace/`

1. **Tenant Storefront** (`/marketplace/[tenant_slug]/`)
   - Browse tenant products
   - Real-time inventory visibility
   - Product search/filter by category
   - Add to cart

2. **Product Detail** (`/marketplace/[tenant_slug]/products/[product_id]`)
   - Product images, description, price
   - Stock availability
   - Add to cart with quantity

3. **Shopping Cart** (`/marketplace/cart`)
   - View cart items
   - Update quantities
   - Remove items
   - Proceed to checkout

4. **Checkout** (`/marketplace/checkout`)
   - Customer info (name, phone, email)
   - Delivery address or pickup selection
   - Special instructions
   - Order summary
   - Place order

5. **Customer Dashboard** (`/marketplace/account/`)
   - Order history with status
   - Loyalty points balance
   - Purchase history
   - Order tracking

6. **Customer Auth** (`/marketplace/login`, `/marketplace/signup`)
   - Email/password or phone/OTP
   - Registration flow
   - Password reset

### Phase 4: Integration & E2E Tests (Priority: Medium)
**Estimated Effort**: 0.5 sprint

1. **Flutter Integration Tests** (`apps/pos_admin/test/integration/`)
   - customer_management_test.dart
   - order_management_test.dart
   - loyalty_points_test.dart

2. **Playwright E2E Tests** (`apps/storefront/e2e/tests/`)
   - marketplace-browsing.spec.ts
   - checkout-flow.spec.ts
   - customer-dashboard.spec.ts

## Database Enhancements Needed

### Migration: Add Loyalty Tiers
Location: `supabase/migrations/` (new migration)

```sql
-- Add loyalty tier to customers
ALTER TABLE customers
ADD COLUMN loyalty_tier VARCHAR(20) DEFAULT 'bronze';

ADD CONSTRAINT chk_loyalty_tier CHECK (
    loyalty_tier IN ('bronze', 'silver', 'gold', 'platinum')
);

-- Create loyalty config table
CREATE TABLE loyalty_config (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    points_per_currency_unit DECIMAL(8,2) DEFAULT 1.00,  -- e.g., 1 point per NGN 100
    bronze_threshold INTEGER DEFAULT 0,
    silver_threshold INTEGER DEFAULT 500,
    gold_threshold INTEGER DEFAULT 2000,
    platinum_threshold INTEGER DEFAULT 5000,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(tenant_id)
);
```

### Migration: Add Tenant Slug for Storefront URLs
Location: `supabase/migrations/` (new migration)

```sql
-- Add slug to tenants for storefront URLs
ALTER TABLE tenants
ADD COLUMN slug VARCHAR(100) UNIQUE;

-- Generate initial slugs from business names
UPDATE tenants
SET slug = LOWER(REGEXP_REPLACE(business_name, '[^a-zA-Z0-9]+', '-', 'g'))
WHERE slug IS NULL;

-- Make slug required going forward
ALTER TABLE tenants
ALTER COLUMN slug SET NOT NULL;

CREATE INDEX idx_tenants_slug ON tenants(slug);
```

## Business Logic Requirements

### Loyalty Points Calculation

**Rule**: Award 1 point per configured currency amount (e.g., 1 point per NGN 100)

**Implementation**:
```dart
int calculateLoyaltyPoints(double purchaseAmount, double pointsPerUnit) {
  return (purchaseAmount / 100 * pointsPerUnit).floor();
}
```

**Example**:
- Purchase: NGN 5,000
- Points per NGN 100: 1
- Loyalty points earned: 50

### Loyalty Tier Progression

**Tiers**:
- Bronze: 0-499 points
- Silver: 500-1,999 points
- Gold: 2,000-4,999 points
- Platinum: 5,000+ points

**Auto-upgrade**: When customer accumulates points, automatically update `loyalty_tier` column.

### Inventory Reservation

**Requirement**: When order is placed, inventory should be reserved until order is completed or cancelled.

**Options**:
1. **Immediate deduction**: Reduce `stock_quantity` immediately on order placement
2. **Reserved quantity**: Add `reserved_quantity` column to products table

**Recommendation**: Immediate deduction for MVP, reserved quantity for future enhancement.

## Success Criteria

### AS1: Storefront Product Browsing
- [ ] Customer can access tenant storefront via URL: `/marketplace/[tenant_slug]`
- [ ] Products display with real-time stock availability
- [ ] Product search and category filtering works
- [ ] Out-of-stock products are clearly marked

### AS2: Order Management
- [ ] Customer can place order with delivery or pickup option
- [ ] Order appears in merchant's order management screen within 30 seconds
- [ ] Merchant can view customer details, items, and fulfillment type
- [ ] Merchant can update order status (pending → confirmed → preparing → ready → completed)

### AS3: Loyalty Points
- [ ] Loyalty points calculated correctly based on purchase amount
- [ ] Points awarded on order completion (not just placement)
- [ ] Customer profile shows updated loyalty points balance
- [ ] Purchase history shows all completed orders

### AS4: Purchase History
- [ ] Customer can log in to marketplace account
- [ ] Customer dashboard shows complete order history
- [ ] Order details include date, items, total, status
- [ ] Loyalty points balance visible on dashboard

### AS5: Customer Analytics
- [ ] Merchant can view customer list with analytics
- [ ] Customer detail shows: total purchases, purchase count, last purchase date
- [ ] Customer detail shows purchase frequency (orders per month)
- [ ] Customer detail shows loyalty tier and points balance
- [ ] Export customer data to CSV

## Next Steps

**Immediate Action**:
1. Decide on implementation priority (Backend services first vs. Full vertical slice)
2. Create database enhancements (loyalty tiers, tenant slugs)
3. Start with Backend Services (Phase 1)

**Recommendation**: Implement in vertical slices (one acceptance scenario at a time) rather than horizontal layers (all backend, then all UI). This allows for faster feedback and testing.

**Vertical Slice Approach**:
1. **Slice 1**: Customer Management (AS5)
   - Customer service methods
   - Customer list screen
   - Customer detail screen
   - Add/edit customer screen

2. **Slice 2**: Order Placement (AS2)
   - Order service methods
   - Order management screen
   - Order detail screen
   - Status updates

3. **Slice 3**: Marketplace Storefront (AS1)
   - Tenant storefront page
   - Product browsing
   - Shopping cart
   - Checkout flow

4. **Slice 4**: Loyalty & History (AS3, AS4)
   - Loyalty service
   - Points calculation on order completion
   - Customer dashboard
   - Purchase history

## Questions for Clarification

1. **Loyalty Points Redemption**: Can customers redeem loyalty points for discounts? If yes, what's the conversion rate?
2. **Multi-Tenant Marketplace**: Do customers see products from ALL tenants, or do they browse one tenant at a time?
3. **Customer Registration**: Can customers register without placing an order, or is registration part of checkout?
4. **Inventory Reservation**: Should we reserve inventory on order placement or deduct immediately?
5. **Payment Integration**: Which payment providers should we integrate (Paystack, Flutterwave, Stripe)?
6. **Guest Checkout**: Can customers place orders without creating an account?
7. **Storefront Customization**: Can tenants customize their storefront (colors, banner, description)?

---

**Document Status**: Draft
**Next Update**: After clarification questions answered
**Owner**: Development Team
