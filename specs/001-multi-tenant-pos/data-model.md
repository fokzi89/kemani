# Data Model: Multi-Tenant POS Platform

**Feature**: Multi-Tenant POS-First Super App Platform
**Branch**: `001-multi-tenant-pos`
**Created**: 2026-01-24
**Status**: Draft

## Overview

This document defines the complete data model for the multi-tenant POS platform, including all entities, relationships, constraints, indexes, and Row Level Security (RLS) policies for multi-tenant isolation.

### Database Technology

- **Backend**: Supabase (PostgreSQL 15+)
- **Offline Storage**: IndexedDB via Dexie.js (browser-based)
- **Schema Conventions**:
  - Table names: `snake_case` (PostgreSQL convention)
  - Primary keys: `id UUID DEFAULT gen_random_uuid()`
  - Foreign keys: `{table_singular}_id UUID`
  - Timestamps: `created_at TIMESTAMPTZ DEFAULT NOW()`, `updated_at TIMESTAMPTZ DEFAULT NOW()`
  - Soft deletes: `deleted_at TIMESTAMPTZ NULL`
  - Version tracking: `version INTEGER DEFAULT 1` (for optimistic locking)
  - Multi-tenancy: `tenant_id UUID REFERENCES tenants(id)`

### Multi-Tenancy Strategy

All tenant-scoped tables include `tenant_id` column with RLS policies enforcing isolation:

```sql
-- Enable RLS on all tenant-scoped tables
ALTER TABLE {table_name} ENABLE ROW LEVEL SECURITY;

-- Policy for SELECT (users can only see their tenant's data)
CREATE POLICY "tenant_isolation_select" ON {table_name}
  FOR SELECT USING (tenant_id = (auth.jwt() ->> 'tenant_id')::UUID);

-- Policy for INSERT (users can only insert with their tenant_id)
CREATE POLICY "tenant_isolation_insert" ON {table_name}
  FOR INSERT WITH CHECK (tenant_id = (auth.jwt() ->> 'tenant_id')::UUID);

-- Policy for UPDATE (users can only update their tenant's data)
CREATE POLICY "tenant_isolation_update" ON {table_name}
  FOR UPDATE USING (tenant_id = (auth.jwt() ->> 'tenant_id')::UUID);

-- Policy for DELETE (users can only delete their tenant's data)
CREATE POLICY "tenant_isolation_delete" ON {table_name}
  FOR DELETE USING (tenant_id = (auth.jwt() ->> 'tenant_id')::UUID);
```

---

## Core Entities

### 1. Tenants

**Description**: Independent businesses (pharmacy, supermarket, grocery shop, mini-mart) using the platform.

**Table Name**: `tenants`

```sql
CREATE TABLE tenants (
  -- Primary Key
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Business Information
  business_name VARCHAR(255) NOT NULL,
  business_type VARCHAR(50) NOT NULL, -- pharmacy, supermarket, pharmacy_supermarket, restaurant, retail, kiosk, neighbourhood_store
  subdomain VARCHAR(100) UNIQUE, -- for marketplace storefront URL (auto-generated from business_name)

  -- Contact Information
  phone_number VARCHAR(20),
  email VARCHAR(255),

  -- Address Information (from onboarding)
  address TEXT,
  country VARCHAR(100), -- Full country name from dropdown
  city VARCHAR(100),
  office_address TEXT,
  latitude DECIMAL(10, 8), -- Auto-populated from geocoding
  longitude DECIMAL(11, 8), -- Auto-populated from geocoding

  -- Branding
  logo_url TEXT,
  primary_color VARCHAR(7) DEFAULT '#10b981', -- hex color
  secondary_color VARCHAR(7) DEFAULT '#0ea5e9',

  -- Configuration
  currency_code VARCHAR(3) DEFAULT 'NGN',
  timezone VARCHAR(50) DEFAULT 'Africa/Lagos',
  tax_rate DECIMAL(5,2) DEFAULT 7.5, -- Nigerian VAT rate

  -- Business Settings
  business_hours JSONB, -- {mon: {open: "09:00", close: "18:00"}, ...}
  payment_methods JSONB, -- [cash, card, bank_transfer, mobile_money]
  delivery_zones JSONB, -- [{name: "Zone 1", radius_km: 5}, ...]

  -- Subscription
  subscription_id UUID REFERENCES subscriptions(id),
  subscription_status VARCHAR(20) DEFAULT 'trial', -- trial, active, suspended, cancelled

  -- Status
  status VARCHAR(20) DEFAULT 'active', -- active, suspended, deactivated
  onboarding_completed BOOLEAN DEFAULT false,

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);

-- Indexes
CREATE INDEX idx_tenants_subdomain ON tenants(subdomain) WHERE deleted_at IS NULL;
CREATE INDEX idx_tenants_phone_number ON tenants(phone_number) WHERE deleted_at IS NULL;
CREATE INDEX idx_tenants_subscription_id ON tenants(subscription_id);
CREATE INDEX idx_tenants_status ON tenants(status) WHERE deleted_at IS NULL;

-- Triggers
CREATE TRIGGER set_tenants_updated_at BEFORE UPDATE ON tenants
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
```

**RLS Policy**: No RLS on tenants table (platform-level access only). Access controlled via API layer.

**Validation Rules**:
- `business_name`: 3-255 characters
- `subdomain`: 3-100 characters, alphanumeric and hyphens only, must be unique
- `phone_number`: Valid Nigerian phone format (+234...)
- `tax_rate`: 0-100

---

### 2. Users

**Description**: People using the system with role-based access.

**Table Name**: `users`

```sql
CREATE TABLE users (
  -- Primary Key
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,

  -- Multi-Tenancy (nullable for users during onboarding)
  tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE,

  -- Personal Information
  full_name VARCHAR(255) NOT NULL,
  phone_number VARCHAR(20),
  email VARCHAR(255),

  -- Profile Information (from onboarding Step 1)
  profile_picture_url TEXT,
  gender VARCHAR(10), -- male, female
  onboarding_completed_at TIMESTAMPTZ, -- tracks when user completed onboarding

  -- Role & Permissions
  role VARCHAR(50) NOT NULL DEFAULT 'tenant_admin', -- platform_admin, tenant_admin, branch_manager, cashier, delivery_rider
  permissions JSONB DEFAULT '[]', -- custom permissions beyond role

  -- Employment Details (for staff)
  employee_id VARCHAR(50),
  branch_id UUID REFERENCES branches(id),
  hire_date DATE,

  -- Authentication
  phone_verified BOOLEAN DEFAULT false,
  email_verified BOOLEAN DEFAULT false,
  last_login_at TIMESTAMPTZ,

  -- Status
  status VARCHAR(20) DEFAULT 'active', -- active, inactive, suspended

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);

-- Indexes
CREATE INDEX idx_users_tenant_id ON users(tenant_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_users_phone_number ON users(phone_number) WHERE deleted_at IS NULL;
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_status ON users(status) WHERE deleted_at IS NULL;
CREATE UNIQUE INDEX idx_users_tenant_phone ON users(tenant_id, phone_number) WHERE deleted_at IS NULL;

-- RLS Policies
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

CREATE POLICY "users_tenant_isolation" ON users
  FOR ALL USING (tenant_id = (auth.jwt() ->> 'tenant_id')::UUID);

-- Platform admins can see all users
CREATE POLICY "users_platform_admin_access" ON users
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM users u
      WHERE u.id = auth.uid() AND u.role = 'platform_admin'
    )
  );
```

**Validation Rules**:
- `full_name`: 2-255 characters
- `phone_number`: Valid phone format
- `role`: Must be one of: platform_admin, tenant_admin, branch_manager, cashier, delivery_rider
- `email`: Valid email format if provided

**Role Permissions**:
- **platform_admin**: Full system access, manage all tenants
- **tenant_admin**: Full tenant access, manage staff, settings, subscriptions
- **branch_manager**: Manage branch operations, staff attendance, view reports
- **cashier**: Process sales, manage inventory, customer interactions
- **delivery_rider**: View assigned deliveries, update delivery status

---

### 3. Staff Invites

**Description**: Email invitations sent to prospective staff members with 7-day expiry.

**Table Name**: `staff_invites`

```sql
CREATE TABLE staff_invites (
  -- Primary Key
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Multi-Tenancy
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,

  -- Invite Details
  email VARCHAR(255) NOT NULL,
  assigned_role VARCHAR(50) NOT NULL, -- branch_manager, cashier, delivery_rider
  branch_id UUID REFERENCES branches(id),

  -- Invite Token
  invite_token VARCHAR(255) NOT NULL UNIQUE,
  invite_url TEXT NOT NULL,

  -- Status
  status VARCHAR(20) DEFAULT 'pending', -- pending, accepted, expired, revoked

  -- Expiry
  expires_at TIMESTAMPTZ NOT NULL, -- 7 days from creation

  -- Tracking
  sent_at TIMESTAMPTZ,
  accepted_at TIMESTAMPTZ,
  accepted_by_user_id UUID REFERENCES users(id),
  revoked_at TIMESTAMPTZ,
  revoked_by_user_id UUID REFERENCES users(id),

  -- Audit
  created_by_user_id UUID NOT NULL REFERENCES users(id),

  -- Email Delivery
  email_sent BOOLEAN DEFAULT false,
  email_delivered BOOLEAN DEFAULT false,
  email_opened BOOLEAN DEFAULT false,

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_staff_invites_tenant_id ON staff_invites(tenant_id);
CREATE INDEX idx_staff_invites_email ON staff_invites(email);
CREATE INDEX idx_staff_invites_token ON staff_invites(invite_token);
CREATE INDEX idx_staff_invites_status ON staff_invites(status);
CREATE INDEX idx_staff_invites_expires_at ON staff_invites(expires_at);

-- RLS Policies
ALTER TABLE staff_invites ENABLE ROW LEVEL SECURITY;

CREATE POLICY "staff_invites_tenant_isolation" ON staff_invites
  FOR ALL USING (tenant_id = (auth.jwt() ->> 'tenant_id')::UUID);

-- Function to auto-expire invites
CREATE OR REPLACE FUNCTION expire_old_staff_invites()
RETURNS void AS $$
BEGIN
  UPDATE staff_invites
  SET status = 'expired'
  WHERE status = 'pending'
    AND expires_at < NOW();
END;
$$ LANGUAGE plpgsql;

-- Schedule to run every hour
SELECT cron.schedule('expire-staff-invites', '0 * * * *', 'SELECT expire_old_staff_invites()');
```

**Validation Rules**:
- `email`: Valid email format, required
- `assigned_role`: Must be one of: branch_manager, cashier, delivery_rider (not tenant_admin)
- `expires_at`: Must be set to NOW() + 7 days on creation
- `invite_token`: Cryptographically secure random token (32+ characters)

**Lifecycle**:
1. **Created**: Admin creates invite with email and role
2. **Pending**: Invite email sent, awaiting acceptance
3. **Accepted**: User clicks link and completes registration
4. **Expired**: 7 days passed without acceptance
5. **Revoked**: Admin manually revoked the invite

---

### 4. Branches

**Description**: Physical locations for multi-branch tenants (future feature, single branch in Phase 1).

**Table Name**: `branches`

```sql
CREATE TABLE branches (
  -- Primary Key
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Multi-Tenancy
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,

  -- Branch Information
  name VARCHAR(255) NOT NULL,
  branch_code VARCHAR(50),

  -- Location
  address TEXT NOT NULL,
  city VARCHAR(100),
  state VARCHAR(100),
  postal_code VARCHAR(20),
  latitude DECIMAL(10, 8),
  longitude DECIMAL(11, 8),

  -- Contact
  phone_number VARCHAR(20),
  email VARCHAR(255),

  -- Manager
  manager_user_id UUID REFERENCES users(id),

  -- Settings
  is_primary BOOLEAN DEFAULT false, -- one primary branch per tenant

  -- Status
  status VARCHAR(20) DEFAULT 'active', -- active, inactive

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);

-- Indexes
CREATE INDEX idx_branches_tenant_id ON branches(tenant_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_branches_manager_id ON branches(manager_user_id);
CREATE INDEX idx_branches_status ON branches(status) WHERE deleted_at IS NULL;

-- RLS Policies
ALTER TABLE branches ENABLE ROW LEVEL SECURITY;

CREATE POLICY "branches_tenant_isolation" ON branches
  FOR ALL USING (tenant_id = (auth.jwt() ->> 'tenant_id')::UUID);
```

---

## Product Management

### 5. Products

**Description**: Sellable items with variants, expiry tracking, and e-commerce sync mappings.

**Table Name**: `products`

```sql
CREATE TABLE products (
  -- Primary Key
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Multi-Tenancy
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  branch_id UUID REFERENCES branches(id), -- NULL for tenant-wide products

  -- Product Information
  name VARCHAR(255) NOT NULL,
  description TEXT,
  sku VARCHAR(100), -- Stock Keeping Unit
  barcode VARCHAR(100),

  -- Categorization
  category_id UUID REFERENCES product_categories(id),
  tags TEXT[], -- searchable tags

  -- Pricing
  cost_price DECIMAL(15, 2), -- purchase cost
  selling_price DECIMAL(15, 2) NOT NULL,
  compare_at_price DECIMAL(15, 2), -- original price for discounts

  -- Inventory
  track_inventory BOOLEAN DEFAULT true,
  current_stock INTEGER DEFAULT 0,
  low_stock_threshold INTEGER DEFAULT 10,

  -- Expiry Management
  has_expiry BOOLEAN DEFAULT false,
  expiry_date DATE,
  expiry_alert_days INTEGER DEFAULT 30, -- alert when expiring within N days

  -- Product Variants (if applicable)
  has_variants BOOLEAN DEFAULT false,
  variant_attributes JSONB, -- {size: [small, medium, large], color: [red, blue]}

  -- Images
  primary_image_url TEXT,
  additional_images JSONB, -- array of image URLs

  -- E-Commerce Sync
  sync_to_marketplace BOOLEAN DEFAULT true,
  woocommerce_product_id VARCHAR(50),
  shopify_product_id VARCHAR(50),

  -- Tax
  tax_exempt BOOLEAN DEFAULT false,
  tax_rate DECIMAL(5, 2),

  -- Status
  status VARCHAR(20) DEFAULT 'active', -- active, inactive, discontinued

  -- Sync Tracking
  version INTEGER DEFAULT 1,
  last_synced_at TIMESTAMPTZ,
  sync_status VARCHAR(20) DEFAULT 'synced', -- synced, pending, conflict

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);

-- Indexes
CREATE INDEX idx_products_tenant_id ON products(tenant_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_products_category_id ON products(category_id);
CREATE INDEX idx_products_sku ON products(sku) WHERE deleted_at IS NULL;
CREATE INDEX idx_products_barcode ON products(barcode) WHERE deleted_at IS NULL;
CREATE INDEX idx_products_name_search ON products USING gin(to_tsvector('english', name));
CREATE INDEX idx_products_status ON products(status) WHERE deleted_at IS NULL;
CREATE INDEX idx_products_expiry_date ON products(expiry_date) WHERE has_expiry = true AND deleted_at IS NULL;
CREATE INDEX idx_products_low_stock ON products(current_stock) WHERE track_inventory = true AND deleted_at IS NULL;
CREATE UNIQUE INDEX idx_products_tenant_sku ON products(tenant_id, sku) WHERE deleted_at IS NULL;

-- RLS Policies
ALTER TABLE products ENABLE ROW LEVEL SECURITY;

CREATE POLICY "products_tenant_isolation" ON products
  FOR ALL USING (tenant_id = (auth.jwt() ->> 'tenant_id')::UUID);

-- Trigger to increment version on update
CREATE OR REPLACE FUNCTION increment_product_version()
RETURNS TRIGGER AS $$
BEGIN
  NEW.version = OLD.version + 1;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER product_version_increment BEFORE UPDATE ON products
  FOR EACH ROW EXECUTE FUNCTION increment_product_version();
```

**Validation Rules**:
- `name`: 1-255 characters, required
- `sku`: Unique per tenant if provided
- `selling_price`: Must be > 0
- `current_stock`: Must be >= 0
- `expiry_date`: Must be in the future for new products
- `expiry_alert_days`: 1-365

**Expiry Alert Logic**:
- Products with `has_expiry = true` and `expiry_date - NOW() <= expiry_alert_days` trigger alerts
- Dashboard shows count of expiring products
- Background job sends notifications when products approaching expiry

---

### 6. Product Variants

**Description**: Variations of a product (size, color, etc.).

**Table Name**: `product_variants`

```sql
CREATE TABLE product_variants (
  -- Primary Key
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Multi-Tenancy
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,

  -- Parent Product
  product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,

  -- Variant Details
  variant_name VARCHAR(255) NOT NULL, -- "Small - Red"
  variant_attributes JSONB NOT NULL, -- {size: "small", color: "red"}

  -- SKU & Barcode (variant-specific)
  sku VARCHAR(100),
  barcode VARCHAR(100),

  -- Pricing (override parent if different)
  selling_price DECIMAL(15, 2),
  cost_price DECIMAL(15, 2),

  -- Inventory
  current_stock INTEGER DEFAULT 0,

  -- Images
  image_url TEXT,

  -- Status
  status VARCHAR(20) DEFAULT 'active',

  -- Sync Tracking
  version INTEGER DEFAULT 1,

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);

-- Indexes
CREATE INDEX idx_product_variants_tenant_id ON product_variants(tenant_id);
CREATE INDEX idx_product_variants_product_id ON product_variants(product_id);
CREATE INDEX idx_product_variants_sku ON product_variants(sku);
CREATE UNIQUE INDEX idx_product_variants_tenant_sku ON product_variants(tenant_id, sku) WHERE deleted_at IS NULL;

-- RLS Policies
ALTER TABLE product_variants ENABLE ROW LEVEL SECURITY;

CREATE POLICY "product_variants_tenant_isolation" ON product_variants
  FOR ALL USING (tenant_id = (auth.jwt() ->> 'tenant_id')::UUID);
```

---

### 7. Product Categories

**Description**: Hierarchical product categorization.

**Table Name**: `product_categories`

```sql
CREATE TABLE product_categories (
  -- Primary Key
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Multi-Tenancy
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,

  -- Category Information
  name VARCHAR(255) NOT NULL,
  description TEXT,
  slug VARCHAR(255),

  -- Hierarchy
  parent_category_id UUID REFERENCES product_categories(id),
  display_order INTEGER DEFAULT 0,

  -- Images
  image_url TEXT,

  -- Status
  status VARCHAR(20) DEFAULT 'active',

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);

-- Indexes
CREATE INDEX idx_categories_tenant_id ON product_categories(tenant_id);
CREATE INDEX idx_categories_parent_id ON product_categories(parent_category_id);
CREATE INDEX idx_categories_slug ON product_categories(slug);
CREATE UNIQUE INDEX idx_categories_tenant_name ON product_categories(tenant_id, name) WHERE deleted_at IS NULL;

-- RLS Policies
ALTER TABLE product_categories ENABLE ROW LEVEL SECURITY;

CREATE POLICY "categories_tenant_isolation" ON product_categories
  FOR ALL USING (tenant_id = (auth.jwt() ->> 'tenant_id')::UUID);
```

---

### 8. Inventory Transactions

**Description**: Audit log of all inventory changes.

**Table Name**: `inventory_transactions`

```sql
CREATE TABLE inventory_transactions (
  -- Primary Key
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Multi-Tenancy
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,

  -- Product Reference
  product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  variant_id UUID REFERENCES product_variants(id),
  branch_id UUID REFERENCES branches(id),

  -- Transaction Details
  transaction_type VARCHAR(50) NOT NULL, -- sale, restock, adjustment, transfer, expiry, return
  quantity_change INTEGER NOT NULL, -- positive for additions, negative for subtractions
  quantity_before INTEGER NOT NULL,
  quantity_after INTEGER NOT NULL,

  -- Cost Tracking
  unit_cost DECIMAL(15, 2),
  total_cost DECIMAL(15, 2),

  -- Reference
  reference_type VARCHAR(50), -- sale, purchase_order, manual_adjustment
  reference_id UUID, -- ID of the related record (sale_id, purchase_order_id, etc.)

  -- User & Notes
  user_id UUID REFERENCES users(id),
  notes TEXT,

  -- Sync Status
  sync_status VARCHAR(20) DEFAULT 'synced',

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_inventory_txn_tenant_id ON inventory_transactions(tenant_id);
CREATE INDEX idx_inventory_txn_product_id ON inventory_transactions(product_id);
CREATE INDEX idx_inventory_txn_type ON inventory_transactions(transaction_type);
CREATE INDEX idx_inventory_txn_created_at ON inventory_transactions(created_at DESC);
CREATE INDEX idx_inventory_txn_reference ON inventory_transactions(reference_type, reference_id);

-- RLS Policies
ALTER TABLE inventory_transactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "inventory_txn_tenant_isolation" ON inventory_transactions
  FOR ALL USING (tenant_id = (auth.jwt() ->> 'tenant_id')::UUID);
```

**Transaction Types**:
- **sale**: Inventory reduced due to sale
- **restock**: Inventory added via purchase order
- **adjustment**: Manual inventory correction
- **transfer**: Movement between branches
- **expiry**: Product expired and removed
- **return**: Customer return, inventory restored

---

## Sales & Transactions

### 9. Sales

**Description**: Completed sales transactions (in-store POS or marketplace).

**Table Name**: `sales`

```sql
CREATE TABLE sales (
  -- Primary Key
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Multi-Tenancy
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  branch_id UUID REFERENCES branches(id),

  -- Sale Information
  sale_number VARCHAR(50) NOT NULL UNIQUE, -- human-readable: SALE-2024-00001
  sale_date TIMESTAMPTZ DEFAULT NOW(),

  -- Customer
  customer_id UUID REFERENCES customers(id),
  customer_name VARCHAR(255),
  customer_phone VARCHAR(20),

  -- Staff
  cashier_id UUID NOT NULL REFERENCES users(id),

  -- Pricing
  subtotal DECIMAL(15, 2) NOT NULL,
  tax_amount DECIMAL(15, 2) DEFAULT 0,
  discount_amount DECIMAL(15, 2) DEFAULT 0,
  total_amount DECIMAL(15, 2) NOT NULL,

  -- Payment
  payment_method VARCHAR(50) NOT NULL, -- cash, card, bank_transfer, mobile_money
  payment_status VARCHAR(20) DEFAULT 'completed', -- pending, completed, refunded
  payment_reference VARCHAR(255),

  -- Source
  sale_source VARCHAR(50) DEFAULT 'pos', -- pos, marketplace, chat_agent, woocommerce, shopify
  order_id UUID REFERENCES orders(id), -- if from marketplace order

  -- Receipt
  receipt_generated BOOLEAN DEFAULT false,
  receipt_url TEXT,

  -- Status
  status VARCHAR(20) DEFAULT 'completed', -- completed, voided, refunded
  voided_at TIMESTAMPTZ,
  voided_by_user_id UUID REFERENCES users(id),
  void_reason TEXT,

  -- Sync Tracking
  version INTEGER DEFAULT 1,
  sync_status VARCHAR(20) DEFAULT 'synced',
  synced_at TIMESTAMPTZ,

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_sales_tenant_id ON sales(tenant_id);
CREATE INDEX idx_sales_branch_id ON sales(branch_id);
CREATE INDEX idx_sales_sale_number ON sales(sale_number);
CREATE INDEX idx_sales_customer_id ON sales(customer_id);
CREATE INDEX idx_sales_cashier_id ON sales(cashier_id);
CREATE INDEX idx_sales_sale_date ON sales(sale_date DESC);
CREATE INDEX idx_sales_payment_method ON sales(payment_method);
CREATE INDEX idx_sales_status ON sales(status);
CREATE INDEX idx_sales_sync_status ON sales(sync_status);

-- RLS Policies
ALTER TABLE sales ENABLE ROW LEVEL SECURITY;

CREATE POLICY "sales_tenant_isolation" ON sales
  FOR ALL USING (tenant_id = (auth.jwt() ->> 'tenant_id')::UUID);

-- Auto-increment sale number
CREATE SEQUENCE IF NOT EXISTS sale_number_seq;

CREATE OR REPLACE FUNCTION generate_sale_number()
RETURNS TRIGGER AS $$
BEGIN
  NEW.sale_number = 'SALE-' || TO_CHAR(NOW(), 'YYYY') || '-' || LPAD(nextval('sale_number_seq')::TEXT, 6, '0');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_sale_number BEFORE INSERT ON sales
  FOR EACH ROW WHEN (NEW.sale_number IS NULL)
  EXECUTE FUNCTION generate_sale_number();
```

**Validation Rules**:
- `subtotal`: Must be > 0
- `total_amount`: Must be >= 0 (can be 0 with 100% discount)
- `payment_method`: Required for completed sales
- Voided sales cannot be modified

**State Transitions**:
```
pending → completed
completed → voided (requires authorization)
completed → refunded (creates negative sale record)
```

---

### 10. Sale Items

**Description**: Line items within a sale.

**Table Name**: `sale_items`

```sql
CREATE TABLE sale_items (
  -- Primary Key
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Multi-Tenancy
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,

  -- Sale Reference
  sale_id UUID NOT NULL REFERENCES sales(id) ON DELETE CASCADE,

  -- Product Reference
  product_id UUID NOT NULL REFERENCES products(id),
  variant_id UUID REFERENCES product_variants(id),

  -- Item Details (snapshot at time of sale)
  product_name VARCHAR(255) NOT NULL,
  product_sku VARCHAR(100),
  variant_name VARCHAR(255),

  -- Quantity & Pricing
  quantity INTEGER NOT NULL,
  unit_price DECIMAL(15, 2) NOT NULL, -- price at time of sale
  discount_amount DECIMAL(15, 2) DEFAULT 0,
  tax_amount DECIMAL(15, 2) DEFAULT 0,
  subtotal DECIMAL(15, 2) NOT NULL, -- (unit_price * quantity) - discount + tax

  -- Cost (for profit calculation)
  unit_cost DECIMAL(15, 2),

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_sale_items_tenant_id ON sale_items(tenant_id);
CREATE INDEX idx_sale_items_sale_id ON sale_items(sale_id);
CREATE INDEX idx_sale_items_product_id ON sale_items(product_id);

-- RLS Policies
ALTER TABLE sale_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "sale_items_tenant_isolation" ON sale_items
  FOR ALL USING (tenant_id = (auth.jwt() ->> 'tenant_id')::UUID);
```

---

## Customer Management

### 11. Customers

**Description**: Customers making purchases with loyalty points tracking.

**Table Name**: `customers`

```sql
CREATE TABLE customers (
  -- Primary Key
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Multi-Tenancy
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,

  -- Personal Information
  full_name VARCHAR(255) NOT NULL,
  phone_number VARCHAR(20) NOT NULL, -- primary identifier
  email VARCHAR(255),
  whatsapp_number VARCHAR(20),

  -- Demographics
  date_of_birth DATE,
  gender VARCHAR(20),

  -- Loyalty Program
  loyalty_points INTEGER DEFAULT 0,
  loyalty_tier VARCHAR(50) DEFAULT 'bronze', -- bronze, silver, gold, platinum
  total_lifetime_spend DECIMAL(15, 2) DEFAULT 0,

  -- Statistics
  total_orders INTEGER DEFAULT 0,
  total_sales INTEGER DEFAULT 0, -- count of completed sales
  average_order_value DECIMAL(15, 2) DEFAULT 0,
  last_purchase_at TIMESTAMPTZ,

  -- Marketing Preferences
  email_opt_in BOOLEAN DEFAULT true,
  sms_opt_in BOOLEAN DEFAULT true,
  whatsapp_opt_in BOOLEAN DEFAULT true,

  -- Status
  status VARCHAR(20) DEFAULT 'active', -- active, inactive, blocked

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);

-- Indexes
CREATE INDEX idx_customers_tenant_id ON customers(tenant_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_customers_phone_number ON customers(phone_number);
CREATE INDEX idx_customers_email ON customers(email);
CREATE INDEX idx_customers_loyalty_tier ON customers(loyalty_tier);
CREATE UNIQUE INDEX idx_customers_tenant_phone ON customers(tenant_id, phone_number) WHERE deleted_at IS NULL;

-- RLS Policies
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "customers_tenant_isolation" ON customers
  FOR ALL USING (tenant_id = (auth.jwt() ->> 'tenant_id')::UUID);

-- Function to update customer statistics
CREATE OR REPLACE FUNCTION update_customer_stats()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE customers
    SET
      total_sales = total_sales + 1,
      total_lifetime_spend = total_lifetime_spend + NEW.total_amount,
      last_purchase_at = NEW.sale_date,
      average_order_value = (total_lifetime_spend + NEW.total_amount) / (total_sales + 1)
    WHERE id = NEW.customer_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_customer_stats_on_sale AFTER INSERT ON sales
  FOR EACH ROW WHEN (NEW.customer_id IS NOT NULL AND NEW.status = 'completed')
  EXECUTE FUNCTION update_customer_stats();
```

**Loyalty Tiers** (auto-calculated based on total_lifetime_spend):
- **Bronze**: ₦0 - ₦49,999
- **Silver**: ₦50,000 - ₦149,999
- **Gold**: ₦150,000 - ₦499,999
- **Platinum**: ₦500,000+

**Loyalty Points Calculation**:
- 1 point per ₦100 spent (configurable per tenant)
- Bonus multipliers based on tier (2x for Gold, 3x for Platinum)

---

### 12. Customer Addresses

**Description**: Delivery addresses for customers.

**Table Name**: `customer_addresses`

```sql
CREATE TABLE customer_addresses (
  -- Primary Key
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Multi-Tenancy
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,

  -- Customer Reference
  customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE CASCADE,

  -- Address Information
  address_label VARCHAR(100), -- Home, Office, etc.
  address_line1 TEXT NOT NULL,
  address_line2 TEXT,
  city VARCHAR(100),
  state VARCHAR(100),
  postal_code VARCHAR(20),
  country VARCHAR(100) DEFAULT 'Nigeria',

  -- Geolocation
  latitude DECIMAL(10, 8),
  longitude DECIMAL(11, 8),

  -- Delivery Instructions
  delivery_instructions TEXT,

  -- Flags
  is_default BOOLEAN DEFAULT false,

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_customer_addresses_tenant_id ON customer_addresses(tenant_id);
CREATE INDEX idx_customer_addresses_customer_id ON customer_addresses(customer_id);

-- RLS Policies
ALTER TABLE customer_addresses ENABLE ROW LEVEL SECURITY;

CREATE POLICY "customer_addresses_tenant_isolation" ON customer_addresses
  FOR ALL USING (tenant_id = (auth.jwt() ->> 'tenant_id')::UUID);
```

---

## Order Management (Marketplace)

### 13. Orders

**Description**: Customer orders from marketplace or e-commerce platforms.

**Table Name**: `orders`

```sql
CREATE TABLE orders (
  -- Primary Key
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Multi-Tenancy
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  branch_id UUID REFERENCES branches(id),

  -- Order Information
  order_number VARCHAR(50) NOT NULL UNIQUE,
  order_date TIMESTAMPTZ DEFAULT NOW(),

  -- Customer
  customer_id UUID NOT NULL REFERENCES customers(id),
  customer_name VARCHAR(255) NOT NULL,
  customer_phone VARCHAR(20) NOT NULL,
  customer_email VARCHAR(255),

  -- Pricing
  subtotal DECIMAL(15, 2) NOT NULL,
  tax_amount DECIMAL(15, 2) DEFAULT 0,
  discount_amount DECIMAL(15, 2) DEFAULT 0,
  delivery_fee DECIMAL(15, 2) DEFAULT 0,
  total_amount DECIMAL(15, 2) NOT NULL,

  -- Payment
  payment_method VARCHAR(50),
  payment_status VARCHAR(20) DEFAULT 'pending', -- pending, paid, failed, refunded
  payment_reference VARCHAR(255),

  -- Fulfillment
  fulfillment_type VARCHAR(50) NOT NULL, -- pickup, local_delivery, intercity_delivery
  order_status VARCHAR(50) DEFAULT 'pending', -- pending, confirmed, preparing, ready, out_for_delivery, delivered, cancelled

  -- Delivery Details
  delivery_address_id UUID REFERENCES customer_addresses(id),
  delivery_address_text TEXT,
  delivery_instructions TEXT,
  estimated_delivery_date DATE,
  actual_delivery_date TIMESTAMPTZ,

  -- Source
  order_source VARCHAR(50) DEFAULT 'marketplace', -- marketplace, chat_agent, woocommerce, shopify
  external_order_id VARCHAR(255), -- ID from external platform

  -- Notes
  customer_notes TEXT,
  internal_notes TEXT,

  -- Commission (for marketplace orders)
  commission_rate DECIMAL(5, 2),
  commission_amount DECIMAL(15, 2),

  -- Sync Tracking
  version INTEGER DEFAULT 1,
  sync_status VARCHAR(20) DEFAULT 'synced',

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  cancelled_at TIMESTAMPTZ,
  cancelled_by_user_id UUID REFERENCES users(id),
  cancellation_reason TEXT
);

-- Indexes
CREATE INDEX idx_orders_tenant_id ON orders(tenant_id);
CREATE INDEX idx_orders_order_number ON orders(order_number);
CREATE INDEX idx_orders_customer_id ON orders(customer_id);
CREATE INDEX idx_orders_order_date ON orders(order_date DESC);
CREATE INDEX idx_orders_order_status ON orders(order_status);
CREATE INDEX idx_orders_payment_status ON orders(payment_status);
CREATE INDEX idx_orders_fulfillment_type ON orders(fulfillment_type);
CREATE INDEX idx_orders_external_id ON orders(external_order_id);

-- RLS Policies
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;

CREATE POLICY "orders_tenant_isolation" ON orders
  FOR ALL USING (tenant_id = (auth.jwt() ->> 'tenant_id')::UUID);
```

**Order Status State Machine**:

```
pending → confirmed → preparing → ready
                                    ↓
                              out_for_delivery → delivered

Any state → cancelled
```

**State Transition Rules**:
- **pending**: Customer placed order, awaiting merchant confirmation
- **confirmed**: Merchant confirmed order, payment verified
- **preparing**: Order items being prepared/packed
- **ready**: Order ready for pickup (if fulfillment_type = pickup)
- **out_for_delivery**: Assigned to delivery rider
- **delivered**: Successfully delivered to customer
- **cancelled**: Order cancelled (by customer or merchant)

**Validation Rules**:
- Cannot change status to earlier state in workflow
- Cannot modify cancelled orders
- Payment must be completed before order can be marked as "confirmed"
- `estimated_delivery_date` required for delivery orders

---

### 14. Order Items

**Description**: Line items within an order.

**Table Name**: `order_items`

```sql
CREATE TABLE order_items (
  -- Primary Key
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Multi-Tenancy
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,

  -- Order Reference
  order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,

  -- Product Reference
  product_id UUID NOT NULL REFERENCES products(id),
  variant_id UUID REFERENCES product_variants(id),

  -- Item Details (snapshot at time of order)
  product_name VARCHAR(255) NOT NULL,
  product_sku VARCHAR(100),
  variant_name VARCHAR(255),

  -- Quantity & Pricing
  quantity INTEGER NOT NULL,
  unit_price DECIMAL(15, 2) NOT NULL,
  discount_amount DECIMAL(15, 2) DEFAULT 0,
  tax_amount DECIMAL(15, 2) DEFAULT 0,
  subtotal DECIMAL(15, 2) NOT NULL,

  -- Fulfillment Status (per item)
  fulfillment_status VARCHAR(50) DEFAULT 'pending', -- pending, fulfilled, out_of_stock, cancelled

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_order_items_tenant_id ON order_items(tenant_id);
CREATE INDEX idx_order_items_order_id ON order_items(order_id);
CREATE INDEX idx_order_items_product_id ON order_items(product_id);

-- RLS Policies
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "order_items_tenant_isolation" ON order_items
  FOR ALL USING (tenant_id = (auth.jwt() ->> 'tenant_id')::UUID);
```

---

## Delivery Management

### 15. Deliveries

**Description**: Delivery tasks for local and inter-city orders.

**Table Name**: `deliveries`

```sql
CREATE TABLE deliveries (
  -- Primary Key
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Multi-Tenancy
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,

  -- Order Reference
  order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,

  -- Delivery Information
  tracking_number VARCHAR(50) NOT NULL UNIQUE,
  delivery_type VARCHAR(50) NOT NULL, -- local_bike, local_bicycle, intercity_platform

  -- Rider Assignment (for local deliveries)
  rider_id UUID REFERENCES riders(id),
  assigned_at TIMESTAMPTZ,

  -- Platform Delivery (for inter-city)
  platform_delivery_service VARCHAR(100), -- GIG Logistics, Kwik, etc.
  platform_tracking_number VARCHAR(255),
  platform_tracking_url TEXT,

  -- Delivery Address
  delivery_address TEXT NOT NULL,
  customer_name VARCHAR(255) NOT NULL,
  customer_phone VARCHAR(20) NOT NULL,
  delivery_instructions TEXT,

  -- Geolocation
  pickup_latitude DECIMAL(10, 8),
  pickup_longitude DECIMAL(11, 8),
  delivery_latitude DECIMAL(10, 8),
  delivery_longitude DECIMAL(11, 8),

  -- Status & Timeline
  status VARCHAR(50) DEFAULT 'pending', -- pending, assigned, picked_up, in_transit, delivered, failed, cancelled
  estimated_pickup_time TIMESTAMPTZ,
  actual_pickup_time TIMESTAMPTZ,
  estimated_delivery_time TIMESTAMPTZ,
  actual_delivery_time TIMESTAMPTZ,

  -- Proof of Delivery
  proof_of_delivery_type VARCHAR(50), -- photo, signature, recipient_name, code
  proof_of_delivery_url TEXT,
  recipient_name VARCHAR(255),
  recipient_signature_url TEXT,
  delivery_code VARCHAR(10), -- verification code

  -- Fees
  delivery_fee DECIMAL(15, 2),
  rider_payout DECIMAL(15, 2), -- for local riders

  -- Failure Details
  failed_at TIMESTAMPTZ,
  failure_reason TEXT,
  retry_count INTEGER DEFAULT 0,

  -- Notes
  internal_notes TEXT,

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_deliveries_tenant_id ON deliveries(tenant_id);
CREATE INDEX idx_deliveries_order_id ON deliveries(order_id);
CREATE INDEX idx_deliveries_tracking_number ON deliveries(tracking_number);
CREATE INDEX idx_deliveries_rider_id ON deliveries(rider_id);
CREATE INDEX idx_deliveries_status ON deliveries(status);
CREATE INDEX idx_deliveries_delivery_type ON deliveries(delivery_type);
CREATE INDEX idx_deliveries_created_at ON deliveries(created_at DESC);

-- RLS Policies
ALTER TABLE deliveries ENABLE ROW LEVEL SECURITY;

CREATE POLICY "deliveries_tenant_isolation" ON deliveries
  FOR ALL USING (tenant_id = (auth.jwt() ->> 'tenant_id')::UUID);

-- Riders can see their assigned deliveries
CREATE POLICY "deliveries_rider_access" ON deliveries
  FOR SELECT USING (
    rider_id IN (
      SELECT r.id FROM riders r
      JOIN users u ON r.user_id = u.id
      WHERE u.id = auth.uid()
    )
  );
```

**Delivery Status State Machine**:

```
pending → assigned → picked_up → in_transit → delivered
                                                  ↓
                                              (proof of delivery captured)

Any state → failed → pending (retry)
Any state → cancelled
```

**Validation Rules**:
- `delivery_type` required
- Local deliveries require `rider_id` assignment
- Inter-city deliveries require `platform_delivery_service`
- `proof_of_delivery_*` required when status = delivered
- Cannot mark as delivered without proof

---

### 16. Riders

**Description**: Delivery personnel (bike/bicycle riders).

**Table Name**: `riders`

```sql
CREATE TABLE riders (
  -- Primary Key
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Multi-Tenancy
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,

  -- User Reference
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  -- Rider Information
  full_name VARCHAR(255) NOT NULL,
  phone_number VARCHAR(20) NOT NULL,
  email VARCHAR(255),

  -- Vehicle Information
  vehicle_type VARCHAR(50) NOT NULL, -- bike, bicycle, motorcycle
  vehicle_registration VARCHAR(100),

  -- Documents
  drivers_license VARCHAR(100),
  drivers_license_expiry DATE,
  vehicle_insurance VARCHAR(100),
  vehicle_insurance_expiry DATE,

  -- Performance Metrics
  total_deliveries INTEGER DEFAULT 0,
  completed_deliveries INTEGER DEFAULT 0,
  failed_deliveries INTEGER DEFAULT 0,
  delivery_success_rate DECIMAL(5, 2) DEFAULT 0,
  average_delivery_time_minutes INTEGER, -- in minutes
  average_rating DECIMAL(3, 2), -- 0.00 to 5.00

  -- Availability
  is_available BOOLEAN DEFAULT false,
  current_location_latitude DECIMAL(10, 8),
  current_location_longitude DECIMAL(11, 8),
  last_location_update TIMESTAMPTZ,

  -- Status
  status VARCHAR(20) DEFAULT 'active', -- active, inactive, suspended

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);

-- Indexes
CREATE INDEX idx_riders_tenant_id ON riders(tenant_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_riders_user_id ON riders(user_id);
CREATE INDEX idx_riders_phone_number ON riders(phone_number);
CREATE INDEX idx_riders_status ON riders(status) WHERE deleted_at IS NULL;
CREATE INDEX idx_riders_availability ON riders(is_available) WHERE status = 'active';
CREATE INDEX idx_riders_location ON riders(current_location_latitude, current_location_longitude) WHERE is_available = true;

-- RLS Policies
ALTER TABLE riders ENABLE ROW LEVEL SECURITY;

CREATE POLICY "riders_tenant_isolation" ON riders
  FOR ALL USING (tenant_id = (auth.jwt() ->> 'tenant_id')::UUID);

-- Riders can see their own profile
CREATE POLICY "riders_self_access" ON riders
  FOR SELECT USING (user_id = auth.uid());
```

**Performance Metrics Auto-Update**:
- Triggered by delivery status changes
- Success rate = (completed_deliveries / total_deliveries) * 100
- Average delivery time calculated from actual_pickup_time to actual_delivery_time

---

## Staff Management

### 17. Staff Attendance

**Description**: Clock in/out records for staff time tracking.

**Table Name**: `staff_attendance`

```sql
CREATE TABLE staff_attendance (
  -- Primary Key
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Multi-Tenancy
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  branch_id UUID REFERENCES branches(id),

  -- Staff Reference
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  -- Attendance Details
  attendance_date DATE NOT NULL DEFAULT CURRENT_DATE,
  clock_in_time TIMESTAMPTZ NOT NULL,
  clock_out_time TIMESTAMPTZ,

  -- Hours Worked
  total_hours_worked DECIMAL(5, 2), -- calculated on clock out

  -- Break Time (optional)
  break_start_time TIMESTAMPTZ,
  break_end_time TIMESTAMPTZ,
  total_break_minutes INTEGER DEFAULT 0,

  -- Location (optional geofencing)
  clock_in_latitude DECIMAL(10, 8),
  clock_in_longitude DECIMAL(11, 8),
  clock_out_latitude DECIMAL(10, 8),
  clock_out_longitude DECIMAL(11, 8),

  -- Status
  status VARCHAR(20) DEFAULT 'active', -- active (clocked in), completed (clocked out)

  -- Notes
  notes TEXT,

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_staff_attendance_tenant_id ON staff_attendance(tenant_id);
CREATE INDEX idx_staff_attendance_user_id ON staff_attendance(user_id);
CREATE INDEX idx_staff_attendance_date ON staff_attendance(attendance_date DESC);
CREATE INDEX idx_staff_attendance_status ON staff_attendance(status);

-- RLS Policies
ALTER TABLE staff_attendance ENABLE ROW LEVEL SECURITY;

CREATE POLICY "staff_attendance_tenant_isolation" ON staff_attendance
  FOR ALL USING (tenant_id = (auth.jwt() ->> 'tenant_id')::UUID);

-- Staff can see their own attendance
CREATE POLICY "staff_attendance_self_access" ON staff_attendance
  FOR SELECT USING (user_id = auth.uid());

-- Function to calculate hours worked on clock out
CREATE OR REPLACE FUNCTION calculate_hours_worked()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.clock_out_time IS NOT NULL THEN
    NEW.total_hours_worked = EXTRACT(EPOCH FROM (NEW.clock_out_time - NEW.clock_in_time)) / 3600
                              - (NEW.total_break_minutes / 60.0);
    NEW.status = 'completed';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER calculate_attendance_hours BEFORE UPDATE ON staff_attendance
  FOR EACH ROW WHEN (OLD.clock_out_time IS NULL AND NEW.clock_out_time IS NOT NULL)
  EXECUTE FUNCTION calculate_hours_worked();
```

**Validation Rules**:
- `clock_in_time` required
- `clock_out_time` must be after `clock_in_time`
- Cannot have multiple active (not clocked out) records for same user
- Geofencing: If enabled, clock in/out location must be within configured radius of branch

---

## E-Commerce Integrations

### 18. E-Commerce Connections

**Description**: Configuration for third-party e-commerce platform integrations.

**Table Name**: `ecommerce_connections`

```sql
CREATE TABLE ecommerce_connections (
  -- Primary Key
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Multi-Tenancy
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,

  -- Platform Details
  platform_type VARCHAR(50) NOT NULL, -- woocommerce, shopify, other
  platform_name VARCHAR(255), -- custom name for this connection
  store_url TEXT NOT NULL,

  -- Authentication (encrypted)
  api_credentials JSONB NOT NULL, -- {consumer_key, consumer_secret} or {access_token}

  -- Sync Configuration
  sync_enabled BOOLEAN DEFAULT true,
  sync_frequency_minutes INTEGER DEFAULT 15, -- how often to poll
  sync_direction VARCHAR(50) DEFAULT 'bidirectional', -- bidirectional, to_pos, to_platform

  -- Sync Settings
  sync_products BOOLEAN DEFAULT true,
  sync_inventory BOOLEAN DEFAULT true,
  sync_orders BOOLEAN DEFAULT true,
  sync_customers BOOLEAN DEFAULT false,

  -- Conflict Resolution
  conflict_resolution_strategy VARCHAR(50) DEFAULT 'pos_priority', -- pos_priority, platform_priority, last_write_wins, manual

  -- Sync Status
  last_sync_at TIMESTAMPTZ,
  last_successful_sync_at TIMESTAMPTZ,
  sync_status VARCHAR(50) DEFAULT 'connected', -- connected, syncing, error, paused
  last_sync_error TEXT,

  -- Statistics
  total_syncs INTEGER DEFAULT 0,
  successful_syncs INTEGER DEFAULT 0,
  failed_syncs INTEGER DEFAULT 0,

  -- Webhook
  webhook_secret VARCHAR(255), -- for verifying incoming webhooks

  -- Status
  status VARCHAR(20) DEFAULT 'active', -- active, paused, error, disconnected

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);

-- Indexes
CREATE INDEX idx_ecommerce_connections_tenant_id ON ecommerce_connections(tenant_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_ecommerce_connections_platform_type ON ecommerce_connections(platform_type);
CREATE INDEX idx_ecommerce_connections_sync_status ON ecommerce_connections(sync_status);

-- RLS Policies
ALTER TABLE ecommerce_connections ENABLE ROW LEVEL SECURITY;

CREATE POLICY "ecommerce_connections_tenant_isolation" ON ecommerce_connections
  FOR ALL USING (tenant_id = (auth.jwt() ->> 'tenant_id')::UUID);
```

**Validation Rules**:
- `store_url` must be valid URL
- `api_credentials` encrypted at rest using Supabase Vault
- `sync_frequency_minutes` minimum: 5 minutes (avoid rate limiting)
- Platform-specific credential validation on creation

---

### 19. Sync Logs

**Description**: Audit trail of all sync operations.

**Table Name**: `sync_logs`

```sql
CREATE TABLE sync_logs (
  -- Primary Key
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Multi-Tenancy
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,

  -- Connection Reference
  connection_id UUID REFERENCES ecommerce_connections(id) ON DELETE CASCADE,

  -- Sync Details
  sync_type VARCHAR(50) NOT NULL, -- product_sync, inventory_sync, order_import, manual_trigger
  sync_direction VARCHAR(50) NOT NULL, -- to_pos, to_platform, bidirectional

  -- Results
  status VARCHAR(50) NOT NULL, -- success, partial_success, failed
  items_processed INTEGER DEFAULT 0,
  items_succeeded INTEGER DEFAULT 0,
  items_failed INTEGER DEFAULT 0,

  -- Timing
  started_at TIMESTAMPTZ NOT NULL,
  completed_at TIMESTAMPTZ,
  duration_seconds INTEGER,

  -- Error Details
  error_message TEXT,
  error_details JSONB,

  -- Conflicts
  conflicts_detected INTEGER DEFAULT 0,
  conflicts_auto_resolved INTEGER DEFAULT 0,
  conflicts_manual_queue INTEGER DEFAULT 0,

  -- Metadata
  triggered_by VARCHAR(50), -- scheduled, webhook, manual, user_id
  triggered_by_user_id UUID REFERENCES users(id),

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_sync_logs_tenant_id ON sync_logs(tenant_id);
CREATE INDEX idx_sync_logs_connection_id ON sync_logs(connection_id);
CREATE INDEX idx_sync_logs_status ON sync_logs(status);
CREATE INDEX idx_sync_logs_created_at ON sync_logs(created_at DESC);

-- RLS Policies
ALTER TABLE sync_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "sync_logs_tenant_isolation" ON sync_logs
  FOR ALL USING (tenant_id = (auth.jwt() ->> 'tenant_id')::UUID);

-- Auto-delete old logs (keep 90 days)
CREATE OR REPLACE FUNCTION cleanup_old_sync_logs()
RETURNS void AS $$
BEGIN
  DELETE FROM sync_logs
  WHERE created_at < NOW() - INTERVAL '90 days';
END;
$$ LANGUAGE plpgsql;

SELECT cron.schedule('cleanup-sync-logs', '0 2 * * *', 'SELECT cleanup_old_sync_logs()');
```

---

## AI Chat Agent

### 20. Chat Conversations

**Description**: AI chat sessions with customers.

**Table Name**: `chat_conversations`

```sql
CREATE TABLE chat_conversations (
  -- Primary Key
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Multi-Tenancy
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,

  -- Participants
  customer_id UUID REFERENCES customers(id),
  customer_name VARCHAR(255),
  customer_phone VARCHAR(20),

  -- Channel
  channel VARCHAR(50) DEFAULT 'web_chat', -- web_chat, whatsapp, sms

  -- AI Agent
  ai_agent_enabled BOOLEAN DEFAULT true,
  escalated_to_human BOOLEAN DEFAULT false,
  escalated_at TIMESTAMPTZ,
  assigned_staff_id UUID REFERENCES users(id),

  -- Order Creation
  order_created BOOLEAN DEFAULT false,
  order_id UUID REFERENCES orders(id),

  -- Status
  status VARCHAR(50) DEFAULT 'active', -- active, completed, abandoned, escalated

  -- Metadata
  session_data JSONB, -- context, preferences, etc.

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  last_message_at TIMESTAMPTZ,
  closed_at TIMESTAMPTZ
);

-- Indexes
CREATE INDEX idx_chat_conversations_tenant_id ON chat_conversations(tenant_id);
CREATE INDEX idx_chat_conversations_customer_id ON chat_conversations(customer_id);
CREATE INDEX idx_chat_conversations_status ON chat_conversations(status);
CREATE INDEX idx_chat_conversations_assigned_staff ON chat_conversations(assigned_staff_id);
CREATE INDEX idx_chat_conversations_last_message ON chat_conversations(last_message_at DESC);

-- RLS Policies
ALTER TABLE chat_conversations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "chat_conversations_tenant_isolation" ON chat_conversations
  FOR ALL USING (tenant_id = (auth.jwt() ->> 'tenant_id')::UUID);
```

---

### 21. Chat Messages

**Description**: Individual messages within a conversation.

**Table Name**: `chat_messages`

```sql
CREATE TABLE chat_messages (
  -- Primary Key
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Multi-Tenancy
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,

  -- Conversation Reference
  conversation_id UUID NOT NULL REFERENCES chat_conversations(id) ON DELETE CASCADE,

  -- Message Details
  sender_type VARCHAR(50) NOT NULL, -- customer, ai_agent, staff
  sender_user_id UUID REFERENCES users(id), -- if sender_type = staff

  -- Content
  message_text TEXT NOT NULL,
  message_type VARCHAR(50) DEFAULT 'text', -- text, image, order, product

  -- AI Context
  ai_intent VARCHAR(100), -- product_inquiry, check_availability, create_order, modify_order, cancel_order
  ai_confidence DECIMAL(3, 2), -- 0.00 to 1.00
  ai_function_called VARCHAR(100),
  ai_function_result JSONB,

  -- Attachments
  attachments JSONB, -- [{type: "image", url: "..."}]

  -- Read Status
  is_read BOOLEAN DEFAULT false,
  read_at TIMESTAMPTZ,

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_chat_messages_tenant_id ON chat_messages(tenant_id);
CREATE INDEX idx_chat_messages_conversation_id ON chat_messages(conversation_id);
CREATE INDEX idx_chat_messages_sender_type ON chat_messages(sender_type);
CREATE INDEX idx_chat_messages_created_at ON chat_messages(created_at DESC);

-- RLS Policies
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "chat_messages_tenant_isolation" ON chat_messages
  FOR ALL USING (tenant_id = (auth.jwt() ->> 'tenant_id')::UUID);

-- Update conversation last_message_at on new message
CREATE OR REPLACE FUNCTION update_conversation_last_message()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE chat_conversations
  SET last_message_at = NEW.created_at
  WHERE id = NEW.conversation_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_conversation_on_message AFTER INSERT ON chat_messages
  FOR EACH ROW EXECUTE FUNCTION update_conversation_last_message();
```

---

## WhatsApp Integration

### 22. WhatsApp Messages

**Description**: WhatsApp communication log.

**Table Name**: `whatsapp_messages`

```sql
CREATE TABLE whatsapp_messages (
  -- Primary Key
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Multi-Tenancy
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,

  -- Message Details
  direction VARCHAR(20) NOT NULL, -- inbound, outbound
  sender_phone VARCHAR(20) NOT NULL,
  recipient_phone VARCHAR(20) NOT NULL,

  -- Content
  message_type VARCHAR(50) DEFAULT 'text', -- text, template, image, document, interactive
  message_text TEXT,
  template_name VARCHAR(255), -- if type = template
  template_variables JSONB,
  media_url TEXT,

  -- WhatsApp API
  whatsapp_message_id VARCHAR(255) UNIQUE,
  whatsapp_status VARCHAR(50), -- queued, sent, delivered, read, failed

  -- References
  conversation_id UUID REFERENCES chat_conversations(id),
  order_id UUID REFERENCES orders(id),
  customer_id UUID REFERENCES customers(id),

  -- Delivery
  sent_at TIMESTAMPTZ,
  delivered_at TIMESTAMPTZ,
  read_at TIMESTAMPTZ,
  failed_at TIMESTAMPTZ,
  failure_reason TEXT,

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_whatsapp_messages_tenant_id ON whatsapp_messages(tenant_id);
CREATE INDEX idx_whatsapp_messages_sender ON whatsapp_messages(sender_phone);
CREATE INDEX idx_whatsapp_messages_recipient ON whatsapp_messages(recipient_phone);
CREATE INDEX idx_whatsapp_messages_status ON whatsapp_messages(whatsapp_status);
CREATE INDEX idx_whatsapp_messages_created_at ON whatsapp_messages(created_at DESC);
CREATE INDEX idx_whatsapp_messages_conversation_id ON whatsapp_messages(conversation_id);

-- RLS Policies
ALTER TABLE whatsapp_messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "whatsapp_messages_tenant_isolation" ON whatsapp_messages
  FOR ALL USING (tenant_id = (auth.jwt() ->> 'tenant_id')::UUID);
```

**Template Message Examples**:
- **Order Confirmation**: "Hi {customer_name}, your order #{order_number} has been confirmed. Total: ₦{total_amount}. Track: {tracking_url}"
- **Delivery Update**: "Your order #{order_number} is out for delivery. ETA: {eta}. Track: {tracking_url}"
- **OTP**: "Your verification code is {otp_code}. Valid for 5 minutes."

---

## Subscription & Monetization

### 23. Subscriptions

**Description**: Tenant subscription plans with feature gating and limits.

**Table Name**: `subscriptions`

```sql
CREATE TABLE subscriptions (
  -- Primary Key
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Tenant Reference
  tenant_id UUID NOT NULL UNIQUE REFERENCES tenants(id) ON DELETE CASCADE,

  -- Plan Details
  plan_tier VARCHAR(50) NOT NULL, -- free, basic, pro, enterprise
  plan_name VARCHAR(255) NOT NULL,

  -- Pricing
  monthly_fee DECIMAL(15, 2) NOT NULL,
  currency_code VARCHAR(3) DEFAULT 'NGN',

  -- Limits
  max_branches INTEGER DEFAULT 1,
  max_staff_users INTEGER DEFAULT 5,
  max_products INTEGER DEFAULT 100,
  monthly_transaction_quota INTEGER DEFAULT 1000,
  storage_quota_gb INTEGER DEFAULT 1,

  -- Commission
  commission_rate DECIMAL(5, 2) DEFAULT 2.5, -- percentage on marketplace sales

  -- Features (JSON flags)
  features JSONB NOT NULL, -- {offline_pos: true, marketplace: false, ai_chat: false, ...}

  -- Billing Cycle
  billing_cycle_start DATE NOT NULL,
  billing_cycle_end DATE NOT NULL,
  next_billing_date DATE,

  -- Status
  status VARCHAR(20) DEFAULT 'active', -- active, suspended, cancelled, trial
  trial_ends_at DATE,

  -- Payment
  payment_method_id VARCHAR(255), -- Paystack/Flutterwave payment method reference
  auto_renew BOOLEAN DEFAULT true,

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_subscriptions_tenant_id ON subscriptions(tenant_id);
CREATE INDEX idx_subscriptions_plan_tier ON subscriptions(plan_tier);
CREATE INDEX idx_subscriptions_status ON subscriptions(status);
CREATE INDEX idx_subscriptions_next_billing ON subscriptions(next_billing_date);

-- No RLS on subscriptions (platform-level access)
```

**Plan Tiers**:

| Feature | Free | Basic | Pro | Enterprise |
|---------|------|-------|-----|------------|
| Monthly Fee | ₦0 | ₦5,000 | ₦15,000 | Custom |
| Max Branches | 1 | 1 | 3 | Unlimited |
| Max Staff | 2 | 10 | 50 | Unlimited |
| Max Products | 50 | 500 | 5,000 | Unlimited |
| Monthly Transactions | 100 | 1,000 | 10,000 | Unlimited |
| Commission Rate | 5% | 2.5% | 1.5% | Custom |
| Offline POS | ✓ | ✓ | ✓ | ✓ |
| Marketplace | ✗ | ✓ | ✓ | ✓ |
| Delivery Management | ✗ | Basic | Full | Full |
| E-Commerce Sync | ✗ | ✗ | ✓ | ✓ |
| AI Chat Agent | ✗ | ✗ | ✓ | ✓ |
| WhatsApp Integration | ✗ | ✗ | ✓ | ✓ |
| Advanced Analytics | ✗ | Basic | Full | Full |

---

### 24. Commissions

**Description**: Platform commission tracking on marketplace sales.

**Table Name**: `commissions`

```sql
CREATE TABLE commissions (
  -- Primary Key
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Tenant Reference
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,

  -- Transaction References
  order_id UUID REFERENCES orders(id),
  sale_id UUID REFERENCES sales(id),

  -- Commission Calculation
  transaction_amount DECIMAL(15, 2) NOT NULL,
  commission_rate DECIMAL(5, 2) NOT NULL,
  commission_amount DECIMAL(15, 2) NOT NULL,

  -- Settlement
  settlement_status VARCHAR(50) DEFAULT 'pending', -- pending, settled, disputed
  settled_at TIMESTAMPTZ,
  settlement_reference VARCHAR(255),

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_commissions_tenant_id ON commissions(tenant_id);
CREATE INDEX idx_commissions_order_id ON commissions(order_id);
CREATE INDEX idx_commissions_settlement_status ON commissions(settlement_status);
CREATE INDEX idx_commissions_created_at ON commissions(created_at DESC);

-- No RLS (platform-level access for commission tracking)

-- Auto-create commission on marketplace order completion
CREATE OR REPLACE FUNCTION create_commission_on_order()
RETURNS TRIGGER AS $$
DECLARE
  subscription_record RECORD;
BEGIN
  IF NEW.order_status = 'delivered' AND NEW.payment_status = 'paid' AND NEW.order_source IN ('marketplace', 'chat_agent') THEN
    SELECT * INTO subscription_record FROM subscriptions WHERE tenant_id = NEW.tenant_id;

    INSERT INTO commissions (tenant_id, order_id, transaction_amount, commission_rate, commission_amount)
    VALUES (
      NEW.tenant_id,
      NEW.id,
      NEW.total_amount,
      subscription_record.commission_rate,
      NEW.total_amount * (subscription_record.commission_rate / 100)
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER create_commission_trigger AFTER UPDATE ON orders
  FOR EACH ROW WHEN (OLD.order_status != 'delivered' AND NEW.order_status = 'delivered')
  EXECUTE FUNCTION create_commission_on_order();
```

---

### 25. Invoices

**Description**: Monthly billing invoices for tenants.

**Table Name**: `invoices`

```sql
CREATE TABLE invoices (
  -- Primary Key
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Tenant Reference
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,

  -- Invoice Details
  invoice_number VARCHAR(50) NOT NULL UNIQUE,
  invoice_date DATE NOT NULL,
  due_date DATE NOT NULL,

  -- Billing Period
  billing_period_start DATE NOT NULL,
  billing_period_end DATE NOT NULL,

  -- Line Items
  subscription_fee DECIMAL(15, 2) DEFAULT 0,
  commission_total DECIMAL(15, 2) DEFAULT 0,
  overage_charges DECIMAL(15, 2) DEFAULT 0, -- for exceeding plan limits
  adjustments DECIMAL(15, 2) DEFAULT 0,
  subtotal DECIMAL(15, 2) NOT NULL,
  tax_amount DECIMAL(15, 2) DEFAULT 0,
  total_amount DECIMAL(15, 2) NOT NULL,

  -- Payment
  payment_status VARCHAR(50) DEFAULT 'pending', -- pending, paid, overdue, cancelled
  paid_at TIMESTAMPTZ,
  payment_reference VARCHAR(255),

  -- Invoice Files
  invoice_url TEXT, -- PDF download link

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_invoices_tenant_id ON invoices(tenant_id);
CREATE INDEX idx_invoices_invoice_number ON invoices(invoice_number);
CREATE INDEX idx_invoices_payment_status ON invoices(payment_status);
CREATE INDEX idx_invoices_due_date ON invoices(due_date);

-- No RLS (platform-level access)
```

---

## Receipts

### 26. Receipts

**Description**: Transaction receipts with tenant branding.

**Table Name**: `receipts`

```sql
CREATE TABLE receipts (
  -- Primary Key
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Multi-Tenancy
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,

  -- Transaction Reference
  sale_id UUID REFERENCES sales(id),
  order_id UUID REFERENCES orders(id),

  -- Receipt Details
  receipt_number VARCHAR(50) NOT NULL UNIQUE,
  receipt_type VARCHAR(50) DEFAULT 'sale', -- sale, order, refund, credit_note

  -- Format
  format VARCHAR(20) DEFAULT 'digital', -- digital, thermal_print, a4_print

  -- Content (rendered HTML/text)
  receipt_html TEXT,
  receipt_text TEXT,

  -- Files
  receipt_pdf_url TEXT,

  -- Branding (snapshot at generation time)
  business_name VARCHAR(255),
  business_logo_url TEXT,
  business_address TEXT,
  business_phone VARCHAR(20),

  -- Delivery
  sent_to_customer BOOLEAN DEFAULT false,
  sent_via VARCHAR(50), -- email, whatsapp, sms, printed
  sent_at TIMESTAMPTZ,

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_receipts_tenant_id ON receipts(tenant_id);
CREATE INDEX idx_receipts_sale_id ON receipts(sale_id);
CREATE INDEX idx_receipts_order_id ON receipts(order_id);
CREATE INDEX idx_receipts_receipt_number ON receipts(receipt_number);

-- RLS Policies
ALTER TABLE receipts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "receipts_tenant_isolation" ON receipts
  FOR ALL USING (tenant_id = (auth.jwt() ->> 'tenant_id')::UUID);
```

---

## Utility Tables

### 27. Sync Queue

**Description**: Queue of pending offline operations awaiting cloud sync.

**Table Name**: `sync_queue`

```sql
CREATE TABLE sync_queue (
  -- Primary Key
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Multi-Tenancy
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,

  -- Operation Details
  operation_type VARCHAR(50) NOT NULL, -- insert, update, delete
  table_name VARCHAR(100) NOT NULL,
  record_id UUID NOT NULL,

  -- Data
  operation_data JSONB NOT NULL, -- full record data or delta

  -- Sync Status
  status VARCHAR(50) DEFAULT 'pending', -- pending, processing, completed, failed
  retry_count INTEGER DEFAULT 0,
  max_retries INTEGER DEFAULT 3,

  -- Error Handling
  last_error TEXT,
  last_attempt_at TIMESTAMPTZ,

  -- Ordering
  sequence_number BIGSERIAL,
  depends_on_queue_id UUID REFERENCES sync_queue(id), -- for operations with dependencies

  -- User Context
  user_id UUID REFERENCES users(id),

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  completed_at TIMESTAMPTZ
);

-- Indexes
CREATE INDEX idx_sync_queue_tenant_id ON sync_queue(tenant_id);
CREATE INDEX idx_sync_queue_status ON sync_queue(status);
CREATE INDEX idx_sync_queue_sequence ON sync_queue(sequence_number) WHERE status = 'pending';
CREATE INDEX idx_sync_queue_table ON sync_queue(table_name);

-- RLS Policies
ALTER TABLE sync_queue ENABLE ROW LEVEL SECURITY;

CREATE POLICY "sync_queue_tenant_isolation" ON sync_queue
  FOR ALL USING (tenant_id = (auth.jwt() ->> 'tenant_id')::UUID);
```

---

### 28. Audit Logs

**Description**: System-wide audit trail for critical operations.

**Table Name**: `audit_logs`

```sql
CREATE TABLE audit_logs (
  -- Primary Key
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Multi-Tenancy (nullable for platform-level actions)
  tenant_id UUID REFERENCES tenants(id),

  -- Action Details
  action VARCHAR(100) NOT NULL, -- user_login, sale_created, product_updated, etc.
  entity_type VARCHAR(100), -- users, sales, products, etc.
  entity_id UUID,

  -- User Context
  user_id UUID REFERENCES users(id),
  user_role VARCHAR(50),
  user_ip_address INET,

  -- Changes
  old_values JSONB,
  new_values JSONB,

  -- Metadata
  metadata JSONB, -- additional context

  -- Timestamp
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_audit_logs_tenant_id ON audit_logs(tenant_id);
CREATE INDEX idx_audit_logs_user_id ON audit_logs(user_id);
CREATE INDEX idx_audit_logs_action ON audit_logs(action);
CREATE INDEX idx_audit_logs_entity ON audit_logs(entity_type, entity_id);
CREATE INDEX idx_audit_logs_created_at ON audit_logs(created_at DESC);

-- Partition by month for performance (retention: 12 months)
CREATE TABLE audit_logs_partitioned (LIKE audit_logs INCLUDING ALL) PARTITION BY RANGE (created_at);

-- RLS Policies
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "audit_logs_tenant_isolation" ON audit_logs
  FOR SELECT USING (
    tenant_id = (auth.jwt() ->> 'tenant_id')::UUID OR
    tenant_id IS NULL -- platform-level logs visible to platform admins only
  );
```

---

## Enums and Custom Types

### Custom Enums

```sql
-- User Roles
CREATE TYPE user_role AS ENUM (
  'platform_admin',
  'tenant_admin',
  'branch_manager',
  'cashier',
  'delivery_rider'
);

-- Order Status
CREATE TYPE order_status AS ENUM (
  'pending',
  'confirmed',
  'preparing',
  'ready',
  'out_for_delivery',
  'delivered',
  'cancelled'
);

-- Delivery Status
CREATE TYPE delivery_status AS ENUM (
  'pending',
  'assigned',
  'picked_up',
  'in_transit',
  'delivered',
  'failed',
  'cancelled'
);

-- Payment Status
CREATE TYPE payment_status AS ENUM (
  'pending',
  'paid',
  'failed',
  'refunded'
);

-- Subscription Tier
CREATE TYPE subscription_tier AS ENUM (
  'free',
  'basic',
  'pro',
  'enterprise'
);

-- Sync Status
CREATE TYPE sync_status AS ENUM (
  'synced',
  'pending',
  'conflict',
  'failed'
);
```

---

## Database Functions & Triggers

### 1. Updated At Trigger Function

```sql
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to all tables with updated_at column
-- Example: CREATE TRIGGER set_updated_at BEFORE UPDATE ON {table_name}
--          FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
```

### 2. Soft Delete Function

```sql
CREATE OR REPLACE FUNCTION soft_delete()
RETURNS TRIGGER AS $$
BEGIN
  NEW.deleted_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

### 3. Inventory Update on Sale

```sql
CREATE OR REPLACE FUNCTION update_inventory_on_sale()
RETURNS TRIGGER AS $$
BEGIN
  -- Reduce product stock
  UPDATE products
  SET current_stock = current_stock - NEW.quantity
  WHERE id = NEW.product_id;

  -- Log inventory transaction
  INSERT INTO inventory_transactions (
    tenant_id, product_id, transaction_type, quantity_change,
    quantity_before, quantity_after, reference_type, reference_id, user_id
  )
  SELECT
    p.tenant_id,
    NEW.product_id,
    'sale',
    -NEW.quantity,
    p.current_stock + NEW.quantity,
    p.current_stock,
    'sale',
    NEW.sale_id,
    (SELECT cashier_id FROM sales WHERE id = NEW.sale_id)
  FROM products p
  WHERE p.id = NEW.product_id;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER inventory_update_trigger AFTER INSERT ON sale_items
  FOR EACH ROW EXECUTE FUNCTION update_inventory_on_sale();
```

---

## Indexes Summary

Key indexes for performance optimization:

### Multi-Tenant Queries
```sql
-- All tenant-scoped tables MUST have this index
CREATE INDEX idx_{table}_tenant_id ON {table}(tenant_id) WHERE deleted_at IS NULL;
```

### Composite Indexes for Common Queries
```sql
-- Sales by tenant and date range
CREATE INDEX idx_sales_tenant_date ON sales(tenant_id, sale_date DESC);

-- Products by tenant and category
CREATE INDEX idx_products_tenant_category ON products(tenant_id, category_id) WHERE deleted_at IS NULL;

-- Orders by tenant and status
CREATE INDEX idx_orders_tenant_status ON orders(tenant_id, order_status);

-- Customers by tenant and phone
CREATE INDEX idx_customers_tenant_phone ON customers(tenant_id, phone_number);
```

### Full-Text Search
```sql
-- Product name search
CREATE INDEX idx_products_name_fts ON products USING gin(to_tsvector('english', name));

-- Customer name search
CREATE INDEX idx_customers_name_fts ON customers USING gin(to_tsvector('english', full_name));
```

---

## Data Retention & Archival

### Retention Policies

| Table | Retention Period | Archive Strategy |
|-------|------------------|------------------|
| sales | 7 years | Archive to cold storage after 2 years |
| orders | 7 years | Archive to cold storage after 2 years |
| inventory_transactions | 2 years | Archive to cold storage after 1 year |
| sync_logs | 90 days | Delete after 90 days |
| audit_logs | 12 months | Delete after 12 months |
| chat_messages | 6 months | Archive after 6 months |
| whatsapp_messages | 6 months | Archive after 6 months |

### Archive Function

```sql
CREATE OR REPLACE FUNCTION archive_old_records()
RETURNS void AS $$
BEGIN
  -- Move sales older than 2 years to archive table
  INSERT INTO sales_archive
  SELECT * FROM sales
  WHERE sale_date < NOW() - INTERVAL '2 years';

  DELETE FROM sales
  WHERE sale_date < NOW() - INTERVAL '2 years';

  -- Similar for other tables...
END;
$$ LANGUAGE plpgsql;

-- Schedule monthly archival
SELECT cron.schedule('archive-records', '0 3 1 * *', 'SELECT archive_old_records()');
```

---

## Performance Considerations

### 1. Query Optimization
- Use composite indexes on `(tenant_id, other_columns)` for tenant-scoped queries
- Leverage partial indexes with `WHERE deleted_at IS NULL` for soft-deleted tables
- Use `EXPLAIN ANALYZE` to identify slow queries

### 2. Connection Pooling
- Supabase Pooler for connection management
- Set appropriate pool size based on concurrent users

### 3. Database Partitioning
- Partition large tables (sales, orders, audit_logs) by date range
- Monthly or quarterly partitions for tables with high write volume

### 4. Caching Strategy
- Cache frequently accessed data (products, categories) in Redis
- Use Supabase Realtime for cache invalidation

### 5. Background Jobs
- Use pg_cron for scheduled tasks (expiry checks, archival, sync)
- Queue heavy operations (CSV import, bulk sync) using job queue

---

## Security Considerations

### 1. Row Level Security (RLS)
- ALL tenant-scoped tables MUST have RLS enabled
- Policies enforce tenant_id filtering automatically
- Platform admins have separate policies for cross-tenant access

### 2. Data Encryption
- Sensitive fields (api_credentials) encrypted using Supabase Vault
- All data encrypted at rest (PostgreSQL encryption)
- TLS 1.2+ for data in transit

### 3. API Security
- JWT-based authentication with short expiry
- Rate limiting per tenant and per user
- API key rotation for integrations

### 4. Audit Trail
- All critical operations logged to audit_logs
- Immutable audit records (no updates/deletes)
- Separate retention policy for audit data

---

## Migration Strategy

### Phase 1: Core POS (MVP)
- Tenants, Users, Branches
- Products, Product Categories, Product Variants
- Inventory Transactions
- Sales, Sale Items
- Staff Attendance
- Receipts
- Sync Queue

### Phase 2: Customers & Orders
- Customers, Customer Addresses
- Orders, Order Items
- Staff Invites

### Phase 3: Delivery
- Deliveries, Riders

### Phase 4: Integrations
- E-Commerce Connections, Sync Logs
- Chat Conversations, Chat Messages
- WhatsApp Messages

### Phase 5: Analytics & Payments
- Subscriptions, Commissions, Invoices

### Migration Files
- Each phase has dedicated migration files
- Use Supabase CLI: `supabase migration new {phase_name}`
- Test migrations in staging before production
- Rollback plan for each migration

---

## Offline Storage Schema (IndexedDB via Dexie.js)

The offline schema mirrors the Supabase schema for relevant tables:

```typescript
// lib/db/offline.ts
import Dexie, { Table } from 'dexie';

export class OfflineDatabase extends Dexie {
  products!: Table<Product>;
  sales!: Table<Sale>;
  sale_items!: Table<SaleItem>;
  customers!: Table<Customer>;
  inventory_transactions!: Table<InventoryTransaction>;
  sync_queue!: Table<SyncQueueItem>;

  constructor() {
    super('kemani_offline');

    this.version(1).stores({
      products: 'id, tenant_id, sku, barcode, name, category_id, sync_status',
      sales: 'id, tenant_id, sale_number, sale_date, cashier_id, sync_status',
      sale_items: 'id, sale_id, product_id',
      customers: 'id, tenant_id, phone_number, email',
      inventory_transactions: 'id, product_id, transaction_type, created_at',
      sync_queue: '++sequence_number, status, table_name, created_at'
    });
  }
}

export const db = new OfflineDatabase();
```

**Sync Strategy**:
1. All writes go to IndexedDB first (optimistic UI)
2. Writes added to `sync_queue` table
3. Background sync worker processes queue when online
4. Conflict detection using `version` field
5. Conflict resolution per strategy (LWW, manual queue)

---

## Conclusion

This data model provides a complete, production-ready schema for the multi-tenant POS platform with:

- Strong multi-tenancy isolation via RLS
- Offline-first support with sync queue
- Comprehensive audit trail
- Performance optimization through indexing
- Scalability via partitioning and archival
- Security through encryption and RLS
- Extensibility for future features

All entities are designed to support the user scenarios and functional requirements defined in the spec.md document.
