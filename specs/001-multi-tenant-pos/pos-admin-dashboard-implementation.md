# POS Admin Dashboard - Implementation Status & Plan

**Date**: 2026-02-28
**Scope**: Complete POS Admin Dashboard for multi-tenant POS system

## Business Context

### Subscription Plans (from pricing page)

| Plan | Price | Branches | Staff | Products | Transactions | Key Features |
|------|-------|----------|-------|----------|--------------|--------------|
| **Free** | ₦0/month | 1 | 1 | 100 | 500/month | Email support, no marketplace, no offline mode |
| **Basic** | ₦5,000/month | 3 | 10 | Unlimited | Unlimited | Offline POS, WhatsApp, delivery, email support |
| **Pro** | ₦15,000/month | 10 | 50 | Unlimited | Unlimited | + Marketplace, e-commerce sync, analytics, API, phone support, 1.5% commission |
| **Enterprise** | ₦50,000/month | Unlimited | Unlimited | Unlimited | Unlimited | + Multi-currency, 24/7 support, custom reporting, 1% commission |
| **Enterprise Custom** | Custom | Unlimited | Unlimited | Unlimited | Unlimited | + White-label, custom domain, on-premise, 0.5% commission |

### User Story 3 Clarifications

#### Loyalty Points (Optional & Configurable)
- ✅ Tenant admin can activate/deactivate
- ✅ Flexible configuration: points-per-currency, redemption threshold, payment options
- ✅ Tenant-specific rules stored in `loyalty_config` table

#### Customer Management
- ✅ Junction table: `customer_tenants` links customers to multiple tenants
- ✅ Smart email detection: auto-login if exists, register if new
- ✅ Tenant-scoped order history (customer only sees orders from current tenant)
- ✅ Guest checkout allowed

#### Marketplace Structure
- ✅ One storefront per tenant: `/marketplace/[tenant_slug]`
- ✅ Customers filter products by branch within tenant
- ✅ Tenant shares storefront URL

#### Inventory & Orders
- ✅ `reserved_quantity` field for inventory reservation
- ✅ Reserve on order placement, deduct on payment confirmation

#### Delivery Management
- ✅ Tenant-defined delivery types (van, motorbike, bicycle, trek)
- ✅ Minimum order value (tenant-configurable)
- ✅ Delivery fee options: flat rate, free over distance, distance-based

#### Communications
- ✅ Free plan: Email only
- ✅ Paid plans: Email + WhatsApp + SMS

#### Storefront Customization
- ✅ Free plan: No customization
- ✅ Paid plans: Banner, brand colors, description, hours, contact info

## Database Schema Status

### ✅ Fully Implemented Tables

**Core Tables (002_core_tables.sql)**
```sql
✅ subscriptions (plan_tier, monthly_fee, commission_rate, limits, features)
✅ tenants (name, slug, logo_url, brand_color, country_code, currency_code)
✅ branches (tenant_id, name, location_type, address, city, state)
✅ users (tenant_id, email, full_name, role, phone, gender, passcode_hash)
```

**Product & Inventory (003_product_inventory_tables.sql)**
```sql
✅ categories (tenant_id, name, description, icon_url)
✅ brands (tenant_id, name, logo_url)
✅ products (tenant_id, branch_id, name, sku, barcode, selling_price, cost_price, stock_quantity, reorder_level, expiry_date)
```

**Customer & Sales (004_customer_sales_tables.sql)**
```sql
✅ customers (tenant_id, phone, email, full_name, loyalty_points, total_purchases, purchase_count)
✅ customer_addresses (customer_id, address_line, latitude, longitude, is_default)
✅ sales (tenant_id, branch_id, sale_number, cashier_id, customer_id, subtotal, tax_amount, discount_amount, total_amount, payment_method, status)
✅ sale_items (sale_id, product_id, product_name, quantity, unit_price, discount_amount, subtotal)
```

**Orders & Delivery (005_order_delivery_tables.sql)**
```sql
✅ orders (tenant_id, branch_id, order_number, customer_id, order_type, order_status, payment_status, fulfillment_type, delivery_address_id)
✅ order_items (order_id, product_id, product_name, quantity, unit_price, subtotal)
✅ riders (tenant_id, user_id, vehicle_type, phone, is_available, rating)
✅ deliveries (tenant_id, branch_id, order_id, tracking_number, delivery_type, rider_id, delivery_status, proof_type)
✅ staff_attendance (tenant_id, branch_id, staff_id, clock_in_at, clock_out_at, total_hours)
```

**Additional Tables (006_additional_tables.sql)**
```sql
✅ staff_invites (tenant_id, full_name, email, phone_number, role, invite_token, status, expires_at)
✅ chat_conversations, chat_messages, chat_agent_config
✅ ecommerce_integrations (tenant_id, platform, credentials, sync_status)
```

**RLS Policies (008_rls_policies.sql, 020_enable_rls_policies.sql)**
```sql
✅ All tables have RLS enabled
✅ Tenant isolation enforced via current_tenant_id()
✅ Role-based permissions via current_user_role()
```

### ❌ Missing Database Enhancements

**Need to add:**

1. **Customer-Tenants Junction Table**
```sql
CREATE TABLE customer_tenants (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    loyalty_points INTEGER NOT NULL DEFAULT 0,
    total_purchases DECIMAL(12,2) DEFAULT 0,
    purchase_count INTEGER DEFAULT 0,
    last_purchase_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(customer_id, tenant_id)
);
```

2. **Loyalty Configuration Table**
```sql
CREATE TABLE loyalty_config (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    is_enabled BOOLEAN DEFAULT FALSE,
    points_per_currency_unit DECIMAL(8,2) DEFAULT 1.00,  -- e.g., 1 point per NGN 100
    currency_unit DECIMAL(8,2) DEFAULT 100.00,            -- NGN 100
    min_redemption_points INTEGER DEFAULT 100,
    allow_partial_payment BOOLEAN DEFAULT TRUE,
    allow_full_payment BOOLEAN DEFAULT TRUE,
    redemption_value_per_point DECIMAL(8,2) DEFAULT 1.00, -- 1 point = NGN 1
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(tenant_id)
);
```

3. **Delivery Types Table (Tenant-Defined)**
```sql
CREATE TABLE delivery_types (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    name VARCHAR(50) NOT NULL,                    -- Van, Motorbike, Bicycle, Trek
    base_fee DECIMAL(12,2) NOT NULL DEFAULT 0,    -- Flat rate
    per_km_fee DECIMAL(12,2) DEFAULT 0,           -- Distance-based fee
    free_distance_km DECIMAL(8,2) DEFAULT 0,      -- Free delivery under this distance
    max_distance_km DECIMAL(8,2),                 -- Maximum service distance
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(tenant_id, name)
);
```

4. **Storefront Configuration Table**
```sql
CREATE TABLE storefront_config (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    banner_url TEXT,
    description TEXT,
    operating_hours JSONB,  -- {monday: {open: "08:00", close: "18:00"}, ...}
    contact_email VARCHAR(255),
    contact_phone VARCHAR(20),
    contact_whatsapp VARCHAR(20),
    minimum_order_value DECIMAL(12,2) DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(tenant_id)
);
```

5. **Reserved Quantity Field in Products**
```sql
ALTER TABLE products
ADD COLUMN IF NOT EXISTS reserved_quantity INTEGER DEFAULT 0 CHECK (reserved_quantity >= 0),
ADD CONSTRAINT stock_available CHECK (stock_quantity >= reserved_quantity);
```

6. **Update Customers Table (Global, No tenant_id)**
```sql
-- Remove tenant_id from customers (make it global)
-- Move tenant-specific data to customer_tenants junction table
ALTER TABLE customers DROP COLUMN IF EXISTS tenant_id;
ALTER TABLE customers DROP COLUMN IF EXISTS loyalty_points;
ALTER TABLE customers DROP COLUMN IF EXISTS total_purchases;
ALTER TABLE customers DROP COLUMN IF EXISTS purchase_count;
ALTER TABLE customers DROP COLUMN IF EXISTS last_purchase_at;

-- Add unique constraint on email
ALTER TABLE customers ADD CONSTRAINT customers_email_unique UNIQUE (email);
```

## Flutter POS Admin - Current Implementation

### ✅ Completed Features

**Authentication & Onboarding**
- ✅ Email/password signup with email confirmation
- ✅ Google OAuth signin
- ✅ Country selection with dial code and currency
- ✅ Business setup with branding (logo, brand color)
- ✅ Staff invite system with email invitations
- ✅ Multi-tenant isolation

**UI Structure**
- ✅ Dashboard shell with bottom navigation
- ✅ Theme toggle (dark/light mode)
- ✅ Staff invite dialog
- ✅ Profile menu with logout

**Services**
- ✅ SupabaseService with auth methods
- ✅ Product CRUD methods
- ✅ Sales CRUD methods
- ✅ Staff management methods
- ✅ Image upload to Supabase storage

**Data Models**
- ✅ Country model
- ✅ Product model (created in this session)

### ❌ Missing Flutter Implementation

#### 1. Dashboard Overview Screen (Currently Placeholder)
**Location**: `apps/pos_admin/lib/screens/dashboard_screen.dart` (DashboardOverview widget)

**Current**: Static placeholder with hardcoded values
```dart
_StatCard(title: 'Total Sales', value: '\$0.00', ...)
_StatCard(title: 'Products', value: '0', ...)
```

**Needs**:
- Real-time statistics from database
- Today's sales, week's sales, month's sales
- Product count, low stock count
- Transaction count
- Recent sales list
- Quick actions (New Sale, Add Product)
- Sales chart (daily/weekly/monthly)

#### 2. Products Management Screen (Currently Placeholder)
**Location**: `apps/pos_admin/lib/screens/dashboard_screen.dart` (ProductsScreen widget)

**Current**: "Products Screen - Coming Soon"

**Needs**:
- Product list with search and filters
- Add/Edit product form
- Product categories management
- Brands management
- Bulk import from CSV
- Barcode scanner integration
- Product images upload
- Stock level indicators
- Expiry date alerts

#### 3. Inventory Management Screen (Currently Placeholder)
**Location**: `apps/pos_admin/lib/screens/dashboard_screen.dart` (InventoryScreen widget)

**Current**: "Inventory Screen - Coming Soon"

**Needs**:
- Stock levels by product
- Low stock alerts
- Expiring products alerts
- Stock adjustment form
- Inter-branch transfer (if multiple branches)
- Inventory history
- Stock value calculations

#### 4. Sales/POS Screen (Currently Placeholder)
**Location**: `apps/pos_admin/lib/screens/dashboard_screen.dart` (SalesScreen widget)

**Current**: "Sales Screen - Coming Soon"

**Needs**:
- Product search/scan
- Shopping cart
- Customer selection (optional)
- Payment method selection
- Discount application
- Receipt generation
- Sale history
- Void/refund sales
- Offline mode support
- Sync indicator

#### 5. Analytics Screen (Currently Placeholder)
**Location**: `apps/pos_admin/lib/screens/dashboard_screen.dart` (AnalyticsScreen widget)

**Current**: "Analytics Screen - Coming Soon"

**Needs**:
- Sales trends charts
- Top products by revenue
- Category performance
- Payment method breakdown
- Staff performance
- Time-based analysis (hourly, daily, weekly, monthly)
- Export reports to CSV/PDF

## Implementation Plan

### Phase 1: Core Data Models & Services (Priority: HIGH)

**Goal**: Build foundation for all screens

**Tasks**:
1. ✅ Create Product model (DONE)
2. Create Sale model
3. Create Customer model
4. Create Order model
5. Create Category model
6. Create Brand model
7. Enhance SupabaseService with:
   - Dashboard statistics queries
   - Product filtering/search
   - Sales with items join queries
   - Customer loyalty queries
   - Analytics aggregation queries

**Files to Create**:
```
apps/pos_admin/lib/models/
  ├── product.dart ✅
  ├── sale.dart
  ├── customer.dart
  ├── order.dart
  ├── category.dart
  └── brand.dart
```

### Phase 2: Dashboard Overview (Priority: HIGH)

**Goal**: Replace placeholder with real statistics

**Tasks**:
1. Fetch tenant-specific statistics
2. Display today's sales revenue
3. Display product count and low stock count
4. Display transaction count
5. Show recent sales list
6. Add quick action buttons
7. Add sales trend chart (using fl_chart package)

**Files to Modify**:
```
apps/pos_admin/lib/screens/dashboard_screen.dart
apps/pos_admin/lib/services/supabase_service.dart
```

**Dependencies**:
```yaml
# pubspec.yaml
dependencies:
  fl_chart: ^0.66.0  # For charts
  intl: ^0.18.0      # For number/date formatting
```

### Phase 3: Products Management (Priority: HIGH)

**Goal**: Complete product CRUD functionality

**Tasks**:
1. Create ProductListScreen
2. Create AddEditProductScreen
3. Create ProductDetailScreen (optional)
4. Implement search and filters
5. Add barcode scanner (mobile_scanner package)
6. Add image upload
7. Add CSV import
8. Create categories management screen
9. Create brands management screen

**Files to Create**:
```
apps/pos_admin/lib/screens/products/
  ├── product_list_screen.dart
  ├── product_form_screen.dart
  ├── category_list_screen.dart
  └── brand_list_screen.dart

apps/pos_admin/lib/widgets/products/
  ├── product_card.dart
  ├── product_search_bar.dart
  └── low_stock_badge.dart
```

### Phase 4: POS/Sales Screen (Priority: HIGH)

**Goal**: Core sales transaction functionality

**Tasks**:
1. Create POS screen layout
2. Product search with autocomplete
3. Barcode scanner integration
4. Shopping cart management
5. Customer selection (optional)
6. Payment method selection
7. Discount application
8. Receipt generation
9. Print receipt (printing package)
10. Sales history view

**Files to Create**:
```
apps/pos_admin/lib/screens/sales/
  ├── pos_screen.dart
  ├── sales_history_screen.dart
  └── receipt_screen.dart

apps/pos_admin/lib/widgets/sales/
  ├── product_search_bar.dart
  ├── cart_item.dart
  ├── payment_selector.dart
  └── receipt_preview.dart
```

### Phase 5: Inventory Management (Priority: MEDIUM)

**Goal**: Stock management and tracking

**Tasks**:
1. Create InventoryListScreen
2. Show stock levels by product
3. Low stock alerts
4. Expiring products alerts
5. Stock adjustment form
6. Inventory history
7. Stock valuation

**Files to Create**:
```
apps/pos_admin/lib/screens/inventory/
  ├── inventory_list_screen.dart
  ├── stock_adjustment_screen.dart
  └── inventory_history_screen.dart
```

### Phase 6: Analytics (Priority: MEDIUM)

**Goal**: Business intelligence and reporting

**Tasks**:
1. Create AnalyticsScreen
2. Sales trend charts (daily, weekly, monthly)
3. Top products by revenue
4. Category performance
5. Payment method breakdown
6. Time-based analysis
7. Export to CSV

**Files to Create**:
```
apps/pos_admin/lib/screens/analytics/
  ├── analytics_overview_screen.dart
  ├── sales_report_screen.dart
  └── product_report_screen.dart
```

### Phase 7: Customer Management (Priority: LOW - User Story 3)

**Goal**: Customer profiles and order management

**Tasks**:
1. Create CustomerListScreen
2. Create CustomerDetailScreen
3. Create AddEditCustomerScreen
4. Order management screen
5. Loyalty points display
6. Purchase history

**Files to Create**:
```
apps/pos_admin/lib/screens/customers/
  ├── customer_list_screen.dart
  ├── customer_detail_screen.dart
  ├── customer_form_screen.dart
  └── order_list_screen.dart
```

## Testing Requirements

### Unit Tests
```
apps/pos_admin/test/unit/
  ├── models/product_test.dart
  ├── models/sale_test.dart
  └── services/supabase_service_test.dart
```

### Integration Tests
```
apps/pos_admin/test/integration/
  ├── dashboard_test.dart
  ├── products_test.dart
  ├── pos_sales_test.dart
  └── inventory_test.dart
```

### E2E Tests (Playwright)
```
apps/pos_admin/e2e/tests/
  ├── dashboard.spec.ts
  ├── products-management.spec.ts
  ├── pos-sales.spec.ts
  └── inventory-management.spec.ts
```

## Success Criteria

### Dashboard Overview
- [ ] Shows real-time statistics from database
- [ ] Displays today's, week's, and month's sales
- [ ] Shows low stock alerts count
- [ ] Recent sales list (last 10 transactions)
- [ ] Sales trend chart (7-day view)
- [ ] Quick actions work (New Sale, Add Product)

### Products Management
- [ ] List all products with pagination
- [ ] Search by name, SKU, barcode
- [ ] Filter by category, brand, stock status
- [ ] Add new product with image upload
- [ ] Edit existing product
- [ ] Delete product (soft delete)
- [ ] Scan barcode to add product
- [ ] Import products from CSV
- [ ] Low stock badge on products below reorder level
- [ ] Expiry date alerts for products expiring in 30 days

### POS/Sales
- [ ] Search products by name/SKU/barcode
- [ ] Scan barcode to add to cart
- [ ] Add/remove items from cart
- [ ] Adjust quantities
- [ ] Apply discounts (percentage or fixed)
- [ ] Select customer (optional)
- [ ] Choose payment method
- [ ] Complete sale and update inventory
- [ ] Generate and print receipt
- [ ] View sales history
- [ ] Void/refund sales (with authorization)

### Inventory Management
- [ ] View all products with stock levels
- [ ] Low stock alerts (below reorder level)
- [ ] Expiring products alerts (within 30 days)
- [ ] Adjust stock levels (add/remove)
- [ ] View stock adjustment history
- [ ] Calculate total stock value

### Analytics
- [ ] Sales trend chart (daily/weekly/monthly views)
- [ ] Top 10 products by revenue
- [ ] Category performance comparison
- [ ] Payment method breakdown
- [ ] Hourly sales pattern (for staffing optimization)
- [ ] Export reports to CSV

## Next Steps

**Immediate Actions**:
1. Create missing database migrations (customer_tenants, loyalty_config, delivery_types, storefront_config)
2. Complete data models (Sale, Customer, Order, Category, Brand)
3. Build Dashboard Overview with real data
4. Implement Products Management screen
5. Implement POS/Sales screen

**Recommendation**: Start with **Phase 2 (Dashboard Overview)** as it provides immediate value and tests the data flow from database to UI.

---

**Status**: Ready for implementation
**Last Updated**: 2026-02-28
**Next Review**: After Phase 2 completion
