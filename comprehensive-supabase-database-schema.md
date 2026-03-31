# Comprehensive Supabase Database Schema Documentation

**Project:** Kemani Multi-Tenant POS & Healthcare System
**Last Updated:** March 10, 2026
**Database:** PostgreSQL via Supabase

---

## ⚡ Important Update (March 10, 2026)

**NEW: Automatic Inventory Sync Triggers**

The database now has automatic triggers for real-time inventory synchronization between POS and marketplace. When building your FlutterFlow app:

- ✅ **Just insert sales normally** - Inventory updates automatically
- ✅ **No manual stock updates needed** - Triggers handle everything
- ✅ **Use new views** - `marketplace_products_with_stock` and `product_stock_status`

See **[Section 8: Triggers](#triggers)** for complete details.

---

## Table of Contents

1. [Database Extensions](#database-extensions)
2. [Custom Enums (Types)](#custom-enums-types)
3. [Core Tables](#core-tables)
4. [Healthcare Tables](#healthcare-tables)
5. [Configuration Tables](#configuration-tables)
6. [Views](#views)
7. [Helper Functions](#helper-functions)
8. [⚡ Triggers (Updated - Real-Time Sync)](#-triggers-updated---real-time-sync)
9. [Row Level Security (RLS) Policies](#row-level-security-rls-policies)
10. [Indexes](#indexes)

---

## Database Extensions

The following PostgreSQL extensions are enabled:

```sql
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";        -- UUID generation
CREATE EXTENSION IF NOT EXISTS "pg_trgm";          -- Trigram text search
CREATE EXTENSION IF NOT EXISTS "postgis";          -- Geographic data support
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements"; -- Query performance tracking
```

---

## Custom Enums (Types)

### Business & User Enums

```sql
CREATE TYPE business_type AS ENUM (
    'supermarket', 'pharmacy', 'grocery', 'mini_mart', 'restaurant'
);

CREATE TYPE user_role AS ENUM (
    'platform_admin', 'tenant_admin', 'branch_manager', 'cashier', 'driver'
);
```

### Transaction & Payment Enums

```sql
CREATE TYPE payment_method AS ENUM (
    'cash', 'card', 'bank_transfer', 'mobile_money'
);

CREATE TYPE transaction_type AS ENUM (
    'sale', 'restock', 'adjustment', 'expiry', 'transfer_out', 'transfer_in'
);

CREATE TYPE payment_status AS ENUM (
    'unpaid', 'paid', 'refunded'
);
```

### Inventory & Transfer Enums

```sql
CREATE TYPE transfer_status AS ENUM (
    'pending', 'in_transit', 'completed', 'cancelled'
);

CREATE TYPE sale_status AS ENUM (
    'completed', 'voided', 'refunded'
);
```

### Order & Delivery Enums

```sql
CREATE TYPE order_type AS ENUM (
    'marketplace', 'ecommerce_sync', 'ai_chat'
);

CREATE TYPE order_status AS ENUM (
    'pending', 'confirmed', 'preparing', 'ready', 'completed', 'cancelled'
);

CREATE TYPE fulfillment_type AS ENUM (
    'pickup', 'delivery'
);

CREATE TYPE delivery_type AS ENUM (
    'local_bike', 'local_bicycle', 'intercity'
);

CREATE TYPE delivery_status AS ENUM (
    'pending', 'assigned', 'picked_up', 'in_transit', 'delivered', 'failed', 'cancelled'
);

CREATE TYPE proof_type AS ENUM (
    'photo', 'signature', 'recipient_name'
);

CREATE TYPE vehicle_type AS ENUM (
    'bike', 'bicycle'
);
```

### E-Commerce & Platform Enums

```sql
CREATE TYPE platform_type AS ENUM (
    'woocommerce', 'shopify', 'custom'
);

CREATE TYPE sync_status AS ENUM (
    'pending', 'syncing', 'success', 'error'
);
```

### Chat System Enums

```sql
CREATE TYPE chat_status AS ENUM (
    'active', 'completed', 'escalated', 'abandoned'
);

CREATE TYPE sender_type AS ENUM (
    'customer', 'ai_agent', 'staff'
);

CREATE TYPE chat_message_type AS ENUM (
    'text', 'image', 'audio', 'video', 'location', 'product_card',
    'receipt', 'payment_confirmation', 'discount_applied', 'system_action'
);

CREATE TYPE chat_action_type AS ENUM (
    'add_to_cart', 'apply_discount', 'view_product', 'confirm_payment',
    'update_delivery_address', 'request_human_agent'
);
```

### Subscription & Billing Enums

```sql
CREATE TYPE plan_tier AS ENUM (
    'free', 'basic', 'pro', 'enterprise', 'enterprise_custom'
);

CREATE TYPE subscription_status AS ENUM (
    'active', 'suspended', 'cancelled'
);

CREATE TYPE settlement_status AS ENUM (
    'pending', 'invoiced', 'paid'
);
```

### Messaging Enums

```sql
CREATE TYPE message_direction AS ENUM (
    'outbound', 'inbound'
);

CREATE TYPE message_type AS ENUM (
    'text', 'template', 'media'
);

CREATE TYPE whatsapp_delivery_status AS ENUM (
    'pending', 'sent', 'delivered', 'read', 'failed'
);
```

### Receipt & Misc Enums

```sql
CREATE TYPE receipt_format AS ENUM (
    'pdf', 'thermal_print', 'email'
);
```

---

## Core Tables

### 1. subscriptions

**Purpose:** Platform subscription plans with pricing and feature flags.

```sql
CREATE TABLE subscriptions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID UNIQUE REFERENCES tenants(id),
    plan_tier plan_tier NOT NULL,
    monthly_fee DECIMAL(12,2) NOT NULL CHECK (monthly_fee >= 0),
    commission_rate DECIMAL(5,2) NOT NULL CHECK (commission_rate >= 0 AND commission_rate <= 100),
    commission_cap_amount DECIMAL(12,2) DEFAULT 500.00 CHECK (commission_cap_amount >= 0),
    max_branches INTEGER NOT NULL CHECK (max_branches > 0),
    max_staff_users INTEGER NOT NULL CHECK (max_staff_users > 0),
    max_products INTEGER NOT NULL CHECK (max_products > 0),
    monthly_transaction_quota INTEGER NOT NULL CHECK (monthly_transaction_quota > 0),
    features JSONB DEFAULT '{}',
    billing_cycle_start TIMESTAMPTZ NOT NULL,
    billing_cycle_end TIMESTAMPTZ NOT NULL CHECK (billing_cycle_end > billing_cycle_start),
    status subscription_status DEFAULT 'active',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

**Features JSONB Example:**
```json
{
    "ai_chat": true,
    "ecommerce_chat": true,
    "ecommerce_enabled": true,
    "advanced_analytics": true,
    "api_access": true,
    "woocommerce_sync": true,
    "shopify_sync": true,
    "whatsapp_business_api": true,
    "multi_currency": true,
    "custom_integrations": false
}
```

---

### 2. tenants

**Purpose:** Multi-tenant business accounts with branding and settings.

```sql
CREATE TABLE tenants (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(100) UNIQUE NOT NULL,
    email VARCHAR(255),
    phone VARCHAR(20),
    logo_url TEXT,
    brand_color VARCHAR(7) CHECK (brand_color ~ '^#[0-9A-Fa-f]{6}$'),
    subscription_id UUID REFERENCES subscriptions(id),

    -- E-commerce settings
    ecommerce_enabled BOOLEAN DEFAULT FALSE,
    custom_domain VARCHAR(255),
    custom_domain_verified BOOLEAN DEFAULT FALSE,
    ecommerce_settings JSONB DEFAULT '{}',

    -- Country settings
    country_code VARCHAR(2),
    dial_code VARCHAR(10),
    currency_code VARCHAR(3),

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ,

    CONSTRAINT chk_country_code_format CHECK (country_code IS NULL OR country_code ~ '^[A-Z]{2}$'),
    CONSTRAINT chk_dial_code_format CHECK (dial_code IS NULL OR dial_code ~ '^\+[0-9]{1,4}$'),
    CONSTRAINT chk_currency_code_format CHECK (currency_code IS NULL OR currency_code ~ '^[A-Z]{3}$')
);
```

---

### 3. branches

**Purpose:** Physical business locations per tenant.

```sql
CREATE TABLE branches (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    business_type business_type NOT NULL,
    address TEXT,
    latitude DECIMAL(10,8) CHECK (latitude >= -90 AND latitude <= 90),
    longitude DECIMAL(11,8) CHECK (longitude >= -180 AND longitude <= 180),
    phone VARCHAR(20),
    tax_rate DECIMAL(5,2) DEFAULT 0 CHECK (tax_rate >= 0 AND tax_rate <= 100),
    currency VARCHAR(3) DEFAULT 'NGN',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);
```

---

### 4. users

**Purpose:** User accounts with role-based access control.

```sql
CREATE TABLE users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE,
    email VARCHAR(255),
    phone VARCHAR(20),
    full_name VARCHAR(255) NOT NULL,
    role user_role NOT NULL,
    branch_id UUID REFERENCES branches(id) ON DELETE SET NULL,
    avatar_url TEXT,
    gender VARCHAR(10),
    last_login_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ,

    CONSTRAINT email_or_phone_required CHECK (email IS NOT NULL OR phone IS NOT NULL),
    CONSTRAINT chk_gender_values CHECK (gender IS NULL OR gender IN ('male', 'female', 'other'))
);
```

---

### 5. products

**Purpose:** Tenant-scoped product catalog (stock tracked in branch_inventory).

```sql
CREATE TABLE products (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    -- tenant_id removed as product is now a global table
    name VARCHAR(255) NOT NULL,
    description TEXT,
    sku VARCHAR(100),
    barcode VARCHAR(100),
    category VARCHAR(100),
    unit_price DECIMAL(12,2) NOT NULL CHECK (unit_price > 0),
    cost_price DECIMAL(12,2) CHECK (cost_price >= 0),
    image_url TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ,

    -- Sync fields for offline-first architecture
    _sync_version BIGINT DEFAULT 1,
    _sync_modified_at TIMESTAMPTZ DEFAULT NOW(),
    _sync_client_id UUID,
    _sync_is_deleted BOOLEAN DEFAULT FALSE
);
```

---

### 6. branch_inventory

**Purpose:** Per-branch stock levels for products.

```sql
CREATE TABLE branch_inventory (
    id uuid not null default gen_random_uuid (),
    tenant_id uuid not null REFERENCES tenants(id) ON DELETE CASCADE,
    branch_id uuid not null REFERENCES branches(id) ON DELETE CASCADE,
    product_id uuid not null REFERENCES products(id) ON DELETE CASCADE,
    stock_quantity integer not null default 0 CHECK (stock_quantity >= 0),
    low_stock_threshold integer null default 10 CHECK (low_stock_threshold >= 0),
    expiry_date date null,
    expiry_alert_days integer null default 30 CHECK (expiry_alert_days >= 0),
    is_active boolean null default true,
    created_at timestamp with time zone not null default now(),
    updated_at timestamp with time zone not null default now(),
    _sync_version bigint null default 1,
    _sync_modified_at timestamp with time zone null default now(),
    _sync_client_id uuid null,
    _sync_is_deleted boolean null default false,
    reserved_quantity integer not null default 0 CHECK (reserved_quantity >= 0),
    unit_cost double precision not null,
    cost_price double precision null,
    unit_of_measure text null,
    product_type text null,
    barcode text null,
    sku text null,
    batch_no text null,
    dispense_qty integer null,
    product_name text null,
    image_url text null,
    supplier_id uuid null REFERENCES suppliers(id) ON DELETE SET NULL,
    purchase_invoice text null,
    purchase_code text null,
    added_by text null,
    
    UNIQUE(branch_id, product_id, batch_no),
    CONSTRAINT check_stock_available CHECK (stock_quantity >= reserved_quantity)
);
```

---

### 7. inventory_transactions

**Purpose:** Audit log for all inventory changes.

```sql
CREATE TABLE inventory_transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    branch_inventory_id UUID REFERENCES branch_inventory(id) ON DELETE CASCADE,
    transaction_type transaction_type NOT NULL,
    quantity_delta INTEGER NOT NULL CHECK (quantity_delta != 0),
    previous_quantity INTEGER NOT NULL,
    new_quantity INTEGER NOT NULL CHECK (new_quantity >= 0),
    unit_cost DECIMAL(12,2) CHECK (unit_cost >= 0),
    reference_id UUID,
    reference_type VARCHAR(50),
    notes TEXT,
    staff_id UUID NOT NULL REFERENCES users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT correct_delta CHECK (new_quantity = previous_quantity + quantity_delta)
);
```

---

### 8. inter_branch_transfers

**Purpose:** Track stock transfers between branches.

```sql
CREATE TABLE inter_branch_transfers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    source_branch_id UUID NOT NULL REFERENCES branches(id),
    destination_branch_id UUID NOT NULL REFERENCES branches(id),
    transfer_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    status transfer_status DEFAULT 'pending',
    notes TEXT,
    authorized_by_id UUID NOT NULL REFERENCES users(id),
    received_by_id UUID REFERENCES users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT different_branches CHECK (source_branch_id != destination_branch_id)
);
```

---

### 9. transfer_items

**Purpose:** Line items for inter-branch transfers.

```sql
CREATE TABLE transfer_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    transfer_id UUID NOT NULL REFERENCES inter_branch_transfers(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id),
    quantity INTEGER NOT NULL CHECK (quantity > 0)
);
```

### 10. product_stock_balance

**Purpose:** Rollup table for aggregated stock levels per product and branch.

```sql
CREATE TABLE product_stock_balance (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE,
    branch_id UUID REFERENCES branches(id) ON DELETE CASCADE,
    product_id UUID REFERENCES products(id) ON DELETE CASCADE,
    stock_balance DECIMAL(12,2) DEFAULT 0,
    reserved_balance DECIMAL(12,2) DEFAULT 0,
    available_balance DECIMAL(12,2) DEFAULT 0,
    low_stock_threshold DECIMAL(12,2) DEFAULT 5,
    last_updated TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(branch_id, product_id)
);
```

**Sync Strategy:**
- Automatically updated via `trg_sync_stock_balance` triggers on `branch_inventory`.
- Aggregates all batches for a specific product and branch into a single row for faster POS queries.

---

### 11. customers

**Purpose:** Customer records with loyalty program integration.

```sql
CREATE TABLE customers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    phone VARCHAR(20) NOT NULL,
    email VARCHAR(255),
    full_name VARCHAR(255) NOT NULL,
    whatsapp_number VARCHAR(20),
    loyalty_points INTEGER NOT NULL DEFAULT 0 CHECK (loyalty_points >= 0),
    total_purchases DECIMAL(12,2) DEFAULT 0 CHECK (total_purchases >= 0),
    purchase_count INTEGER DEFAULT 0 CHECK (purchase_count >= 0),
    last_purchase_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ,

    -- Sync fields
    _sync_version BIGINT DEFAULT 1,
    _sync_modified_at TIMESTAMPTZ DEFAULT NOW(),
    _sync_client_id UUID,
    _sync_is_deleted BOOLEAN DEFAULT FALSE
);
```

---

### 12. customer_addresses

**Purpose:** Delivery addresses for customers.

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

---

### 13. sales

**Purpose:** POS sales transactions.

```sql
CREATE TABLE public.sales (
  id uuid not null default extensions.uuid_generate_v4 (),
  tenant_id uuid not null,
  branch_id uuid not null,
  sale_number character varying(50) not null,
  cashier_id uuid not null,
  customer_id uuid null,
  subtotal numeric(12, 2) not null,
  tax_amount numeric(12, 2) not null default 0,
  discount_amount numeric(12, 2) not null default 0,
  total_amount numeric(12, 2) not null,
  payment_method public.payment_method not null,
  payment_reference character varying(255) null,
  sale_status public.sale_status null default 'completed'::sale_status,
  voided_at timestamp with time zone null,
  voided_by_id uuid null,
  void_reason text null,
  is_synced boolean null default false,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now(),
  _sync_version bigint null default 1,
  _sync_modified_at timestamp with time zone null default now(),
  _sync_client_id uuid null,
  _sync_is_deleted boolean null default false,
  customer_type character varying(20) null default 'walk-in'::character varying,
  sales_attendant_id uuid null,
  sale_type character varying(20) null default 'pos'::character varying,
  channel character varying(20) null default 'in-store'::character varying,
  voided_by uuid null,
  sale_date date not null,
  sale_time time without time zone not null,
  completed_at timestamp with time zone not null default now(),
  cash_received numeric(12, 2) null,
  change_given numeric(12, 2) null,
  customer_name character varying(255) null,
  constraint sales_pkey primary key (id),
  constraint valid_total check (total_amount = (subtotal + tax_amount) - discount_amount)
);
```

---

### 14. sale_items

**Purpose:** Line items for sales.

```sql
CREATE TABLE sale_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sale_id UUID NOT NULL REFERENCES sales(id) ON DELETE CASCADE,
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id),
    product_name VARCHAR(255) NOT NULL,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    unit_price DECIMAL(12,2) NOT NULL CHECK (unit_price > 0),
    discount_percent DECIMAL(5,2) DEFAULT 0 CHECK (discount_percent >= 0 AND discount_percent <= 100),
    discount_amount DECIMAL(12,2) DEFAULT 0 CHECK (discount_amount >= 0),
    subtotal DECIMAL(12,2) NOT NULL CHECK (subtotal >= 0),

    CONSTRAINT valid_subtotal CHECK (subtotal = (unit_price * quantity) - discount_amount)
);
```

---

### 15. orders

**Purpose:** E-commerce and marketplace orders.

```sql
CREATE TABLE orders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
    order_number VARCHAR(50) NOT NULL,
    customer_id UUID NOT NULL REFERENCES customers(id),
    order_type order_type NOT NULL,
    order_status order_status DEFAULT 'pending',
    payment_status payment_status DEFAULT 'unpaid',
    payment_method payment_method,
    payment_reference VARCHAR(255),
    subtotal DECIMAL(12,2) NOT NULL CHECK (subtotal >= 0),
    delivery_fee DECIMAL(12,2) DEFAULT 0 CHECK (delivery_fee >= 0),
    tax_amount DECIMAL(12,2) DEFAULT 0 CHECK (tax_amount >= 0),
    total_amount DECIMAL(12,2) NOT NULL CHECK (total_amount >= 0),
    fulfillment_type fulfillment_type NOT NULL,
    delivery_address_id UUID REFERENCES customer_addresses(id),
    special_instructions TEXT,
    ecommerce_platform VARCHAR(50),
    ecommerce_order_id VARCHAR(255),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Sync fields
    _sync_version BIGINT DEFAULT 1,
    _sync_modified_at TIMESTAMPTZ DEFAULT NOW(),
    _sync_client_id UUID,

    CONSTRAINT valid_total CHECK (total_amount = subtotal + delivery_fee + tax_amount),
    CONSTRAINT delivery_address_required CHECK (
        (fulfillment_type = 'pickup' AND delivery_address_id IS NULL) OR
        (fulfillment_type = 'delivery' AND delivery_address_id IS NOT NULL)
    )
);
```

---

### 15. order_items

**Purpose:** Line items for orders.

```sql
CREATE TABLE order_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id),
    product_name VARCHAR(255) NOT NULL,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    unit_price DECIMAL(12,2) NOT NULL CHECK (unit_price > 0),
    subtotal DECIMAL(12,2) NOT NULL CHECK (subtotal >= 0),

    CONSTRAINT valid_subtotal CHECK (subtotal = unit_price * quantity)
);
```

---

### 16. riders

**Purpose:** Delivery riders with performance metrics.

```sql
CREATE TABLE riders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    user_id UUID UNIQUE NOT NULL REFERENCES users(id),
    vehicle_type vehicle_type NOT NULL,
    license_number VARCHAR(50),
    phone VARCHAR(20) NOT NULL,
    is_available BOOLEAN DEFAULT TRUE,
    total_deliveries INTEGER DEFAULT 0 CHECK (total_deliveries >= 0),
    successful_deliveries INTEGER DEFAULT 0 CHECK (successful_deliveries >= 0),
    average_delivery_time_minutes DECIMAL(8,2),
    rating DECIMAL(3,2) CHECK (rating >= 0 AND rating <= 5),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ,

    CONSTRAINT valid_success_rate CHECK (successful_deliveries <= total_deliveries)
);
```

---

### 17. deliveries

**Purpose:** Delivery tracking with GPS and proof of delivery.

```sql
CREATE TABLE deliveries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
    order_id UUID UNIQUE NOT NULL REFERENCES orders(id),
    tracking_number VARCHAR(50) UNIQUE NOT NULL,
    delivery_type delivery_type NOT NULL,
    rider_id UUID REFERENCES riders(id),
    delivery_status delivery_status DEFAULT 'pending',
    customer_address TEXT NOT NULL,
    customer_phone VARCHAR(20) NOT NULL,
    customer_latitude DECIMAL(10,8),
    customer_longitude DECIMAL(11,8),
    distance_km DECIMAL(8,2),
    estimated_delivery_time TIMESTAMPTZ,
    actual_delivery_time TIMESTAMPTZ,
    proof_type proof_type,
    proof_data TEXT,
    failure_reason TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Sync fields
    _sync_version BIGINT DEFAULT 1,
    _sync_modified_at TIMESTAMPTZ DEFAULT NOW(),

    CONSTRAINT rider_required_for_local CHECK (
        (delivery_type IN ('local_bike', 'local_bicycle') AND rider_id IS NOT NULL) OR
        (delivery_type = 'intercity')
    ),
    CONSTRAINT proof_required_for_delivered CHECK (
        (delivery_status != 'delivered') OR
        (proof_type IS NOT NULL AND proof_data IS NOT NULL)
    )
);
```

---

### 18. staff_attendance

**Purpose:** Staff clock-in/clock-out tracking.

```sql
CREATE TABLE staff_attendance (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
    staff_id UUID NOT NULL REFERENCES users(id),
    clock_in_at TIMESTAMPTZ NOT NULL,
    clock_out_at TIMESTAMPTZ,
    total_hours DECIMAL(8,2),
    shift_date DATE NOT NULL,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT valid_clock_out CHECK (clock_out_at IS NULL OR clock_out_at > clock_in_at),
    CONSTRAINT valid_total_hours CHECK (
        (clock_out_at IS NULL AND total_hours IS NULL) OR
        (clock_out_at IS NOT NULL AND total_hours = EXTRACT(EPOCH FROM (clock_out_at - clock_in_at)) / 3600)
    )
);
```

---

### 19. ecommerce_connections

**Purpose:** External e-commerce platform integrations (WooCommerce, Shopify).

```sql
CREATE TABLE ecommerce_connections (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    platform_type platform_type NOT NULL,
    platform_name VARCHAR(100),
    store_url TEXT NOT NULL,
    api_key TEXT NOT NULL,
    api_secret TEXT,
    sync_enabled BOOLEAN DEFAULT TRUE,
    sync_interval_minutes INTEGER DEFAULT 15 CHECK (sync_interval_minutes > 0),
    last_sync_at TIMESTAMPTZ,
    sync_status sync_status DEFAULT 'pending',
    sync_error TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

---

### 20. chat_conversations

**Purpose:** Customer support and AI chat conversations.

```sql
CREATE TABLE chat_conversations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
    customer_id UUID NOT NULL REFERENCES customers(id),
    order_id UUID REFERENCES orders(id),
    status chat_status DEFAULT 'active',
    escalated_to_user_id UUID REFERENCES users(id),
    started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    ended_at TIMESTAMPTZ
);
```

---

### 21. chat_messages

**Purpose:** Messages within chat conversations with rich media support.

```sql
CREATE TABLE chat_messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    conversation_id UUID NOT NULL REFERENCES chat_conversations(id) ON DELETE CASCADE,
    sender_type sender_type NOT NULL,
    sender_id UUID REFERENCES users(id),

    -- Message content
    message_type chat_message_type DEFAULT 'text',
    message_text TEXT,

    -- Media support
    media_url TEXT,
    media_size_bytes BIGINT CHECK (media_size_bytes > 0),
    media_duration_seconds INTEGER CHECK (media_duration_seconds > 0),
    thumbnail_url TEXT,

    -- Structured data
    metadata JSONB DEFAULT '{}',

    -- Interactive actions
    action_type chat_action_type,
    action_data JSONB,
    action_completed_at TIMESTAMPTZ,
    action_completed_by UUID REFERENCES users(id),

    -- AI intent detection
    intent VARCHAR(100),
    confidence_score DECIMAL(3,2) CHECK (confidence_score >= 0 AND confidence_score <= 1),

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT text_or_media_required CHECK (
        message_text IS NOT NULL OR media_url IS NOT NULL
    ),
    CONSTRAINT action_requires_data CHECK (
        (action_type IS NULL AND action_data IS NULL) OR
        (action_type IS NOT NULL AND action_data IS NOT NULL)
    )
);
```

---

### 22. commissions

**Purpose:** Platform commission tracking for marketplace orders.

```sql
CREATE TABLE commissions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    order_id UUID UNIQUE NOT NULL REFERENCES orders(id),
    sale_amount DECIMAL(12,2) NOT NULL CHECK (sale_amount > 0),
    commission_rate DECIMAL(5,2) NOT NULL CHECK (commission_rate >= 0 AND commission_rate <= 100),
    commission_amount DECIMAL(12,2) NOT NULL CHECK (commission_amount >= 0),
    settlement_status settlement_status DEFAULT 'pending',
    settlement_date DATE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT valid_commission CHECK (commission_amount = sale_amount * (commission_rate / 100))
);
```

---

### 23. whatsapp_messages

**Purpose:** WhatsApp Business API message tracking.

```sql
CREATE TABLE whatsapp_messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    customer_id UUID NOT NULL REFERENCES customers(id),
    order_id UUID REFERENCES orders(id),
    direction message_direction NOT NULL,
    message_type message_type NOT NULL,
    message_content TEXT NOT NULL,
    template_name VARCHAR(100),
    media_url TEXT,
    whatsapp_message_id VARCHAR(255) UNIQUE,
    delivery_status whatsapp_delivery_status DEFAULT 'pending',
    error_message TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

---

### 24. receipts

**Purpose:** Digital receipts for sales.

```sql
CREATE TABLE receipts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sale_id UUID UNIQUE NOT NULL REFERENCES sales(id) ON DELETE CASCADE,
    receipt_number VARCHAR(50) UNIQUE NOT NULL,
    format receipt_format DEFAULT 'pdf',
    content TEXT,
    file_url TEXT,
    email_sent_to VARCHAR(255),
    email_sent_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

---

### 25. staff_invites

**Purpose:** Staff invitation management system.

```sql
CREATE TABLE staff_invites (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    email VARCHAR(255) NOT NULL,
    assigned_role VARCHAR(50) NOT NULL,
    branch_id UUID REFERENCES branches(id),
    invite_token VARCHAR(255) NOT NULL UNIQUE,
    invite_url TEXT NOT NULL,
    status VARCHAR(20) DEFAULT 'pending',
    expires_at TIMESTAMPTZ NOT NULL,
    sent_at TIMESTAMPTZ,
    accepted_at TIMESTAMPTZ,
    accepted_by_user_id UUID REFERENCES users(id),
    revoked_at TIMESTAMPTZ,
    revoked_by_user_id UUID REFERENCES users(id),
    created_by_user_id UUID NOT NULL REFERENCES users(id),
    email_sent BOOLEAN DEFAULT false,
    email_delivered BOOLEAN DEFAULT false,
    email_opened BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

---

### 26. product_variants

**Purpose:** Product variations (size, color, etc.).

```sql
CREATE TABLE product_variants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    variant_name VARCHAR(255) NOT NULL,
    variant_attributes JSONB NOT NULL,
    sku VARCHAR(100),
    barcode VARCHAR(100),
    selling_price DECIMAL(15, 2),
    cost_price DECIMAL(15, 2),
    current_stock INTEGER DEFAULT 0,
    image_url TEXT,
    status VARCHAR(20) DEFAULT 'active',
    version INTEGER DEFAULT 1,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);
```

---

### 27. invoices

**Purpose:** Platform billing and invoicing.

```sql
CREATE TABLE invoices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    invoice_number VARCHAR(50) NOT NULL UNIQUE,
    invoice_date DATE NOT NULL,
    due_date DATE NOT NULL,
    billing_period_start DATE NOT NULL,
    billing_period_end DATE NOT NULL,
    subscription_fee DECIMAL(15, 2) DEFAULT 0,
    commission_total DECIMAL(15, 2) DEFAULT 0,
    overage_charges DECIMAL(15, 2) DEFAULT 0,
    adjustments DECIMAL(15, 2) DEFAULT 0,
    subtotal DECIMAL(15, 2) NOT NULL,
    tax_amount DECIMAL(15, 2) DEFAULT 0,
    total_amount DECIMAL(15, 2) NOT NULL,
    payment_status VARCHAR(50) DEFAULT 'pending',
    paid_at TIMESTAMPTZ,
    payment_reference VARCHAR(255),
    invoice_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

---

### 28. sync_logs

**Purpose:** E-commerce synchronization logs and audit trail.

```sql
CREATE TABLE sync_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    connection_id UUID REFERENCES ecommerce_connections(id) ON DELETE CASCADE,
    sync_type VARCHAR(50) NOT NULL,
    sync_direction VARCHAR(50) NOT NULL,
    status VARCHAR(50) NOT NULL,
    items_processed INTEGER DEFAULT 0,
    items_succeeded INTEGER DEFAULT 0,
    items_failed INTEGER DEFAULT 0,
    started_at TIMESTAMPTZ NOT NULL,
    completed_at TIMESTAMPTZ,
    duration_seconds INTEGER,
    error_message TEXT,
    error_details JSONB,
    conflicts_detected INTEGER DEFAULT 0,
    conflicts_auto_resolved INTEGER DEFAULT 0,
    conflicts_manual_queue INTEGER DEFAULT 0,
    triggered_by VARCHAR(50),
    triggered_by_user_id UUID REFERENCES users(id),
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

---

### 29. audit_logs

**Purpose:** System-wide audit trail for critical operations.

```sql
CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID REFERENCES tenants(id),
    action VARCHAR(100) NOT NULL,
    entity_type VARCHAR(100),
    entity_id UUID,
    user_id UUID REFERENCES users(id),
    user_role VARCHAR(50),
    user_ip_address INET,
    old_values JSONB,
    new_values JSONB,
    metadata JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

---

## Healthcare Tables

### 30. healthcare_providers

**Purpose:** Healthcare professional directory (doctors, pharmacists, specialists).

```sql
CREATE TABLE healthcare_providers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,

    -- Basic Info
    full_name TEXT NOT NULL,
    slug TEXT UNIQUE NOT NULL,
    email TEXT,
    phone TEXT,
    profile_photo_url TEXT,

    -- Professional Info
    type TEXT NOT NULL CHECK (type IN ('doctor', 'pharmacist', 'diagnostician', 'specialist')),
    specialization TEXT NOT NULL,
    credentials TEXT,
    license_number TEXT,
    years_of_experience INTEGER DEFAULT 0,
    bio TEXT,

    -- Location
    country TEXT NOT NULL,
    region TEXT,
    clinic_address JSONB,

    -- Offerings
    consultation_types TEXT[] DEFAULT ARRAY['chat'],
    fees JSONB NOT NULL DEFAULT '{}',

    -- Stats
    average_rating DECIMAL(3,2) DEFAULT 0.00,
    total_consultations INTEGER DEFAULT 0,
    total_reviews INTEGER DEFAULT 0,

    -- Subscription Plan
    plan_tier TEXT DEFAULT 'free' CHECK (plan_tier IN ('free', 'pro', 'enterprise_custom')),
    custom_domain TEXT,
    clinic_settings JSONB DEFAULT '{}',

    -- Status
    is_verified BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    verified_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

---

### 31. provider_availability_templates

**Purpose:** Recurring availability schedules for healthcare providers.

```sql
CREATE TABLE provider_availability_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    provider_id UUID NOT NULL REFERENCES healthcare_providers(id) ON DELETE CASCADE,
    day_of_week INTEGER NOT NULL CHECK (day_of_week BETWEEN 0 AND 6),
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    slot_duration INTEGER NOT NULL CHECK (slot_duration IN (15, 30, 45, 60)),
    buffer_minutes INTEGER DEFAULT 0,
    consultation_types TEXT[] DEFAULT ARRAY['chat', 'video', 'audio', 'office_visit'],
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    CONSTRAINT valid_time_range CHECK (end_time > start_time)
);
```

---

### 32. provider_time_slots

**Purpose:** Materialized bookable time slots with optimistic locking.

```sql
CREATE TABLE provider_time_slots (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    provider_id UUID NOT NULL REFERENCES healthcare_providers(id) ON DELETE CASCADE,
    template_id UUID REFERENCES provider_availability_templates(id) ON DELETE SET NULL,
    date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    slot_duration INTEGER NOT NULL,
    consultation_type TEXT NOT NULL CHECK (consultation_type IN ('chat', 'video', 'audio', 'office_visit')),
    status TEXT DEFAULT 'available' CHECK (status IN ('available', 'held_for_payment', 'booked', 'in_progress', 'completed', 'cancelled')),
    version INTEGER DEFAULT 1 NOT NULL,
    held_until TIMESTAMPTZ,
    held_by_user UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE (provider_id, date, start_time),
    CONSTRAINT valid_slot_time CHECK (end_time > start_time)
);
```

---

### 33. consultations

**Purpose:** Healthcare consultation sessions with referral tracking.

```sql
CREATE TABLE consultations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    provider_id UUID NOT NULL REFERENCES healthcare_providers(id) ON DELETE RESTRICT,
    patient_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE RESTRICT,
    tenant_id UUID NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('chat', 'video', 'audio', 'office_visit')),
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'completed', 'cancelled')),
    scheduled_time TIMESTAMPTZ,
    slot_duration INTEGER,
    started_at TIMESTAMPTZ,
    ended_at TIMESTAMPTZ,
    location_address JSONB,

    -- Agora Integration (video/audio)
    agora_channel_name TEXT,
    agora_token_patient TEXT,
    agora_token_provider TEXT,
    agora_token_expiry TIMESTAMPTZ,

    -- Referral Tracking
    referral_source TEXT NOT NULL CHECK (referral_source IN ('storefront', 'medic_clinic', 'direct')),
    referrer_entity_id UUID,

    -- Denormalized Provider Info
    provider_name TEXT NOT NULL,
    provider_photo_url TEXT,

    -- Financial
    consultation_fee DECIMAL(10,2) NOT NULL,
    payment_status TEXT DEFAULT 'pending' CHECK (payment_status IN ('pending', 'paid', 'failed', 'refunded')),
    paid_at TIMESTAMPTZ,
    payment_reference TEXT,
    commission_calculated_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    CONSTRAINT chat_no_schedule CHECK (type = 'chat' OR scheduled_time IS NOT NULL),
    CONSTRAINT office_has_location CHECK (type != 'office_visit' OR location_address IS NOT NULL),
    CONSTRAINT video_audio_has_agora CHECK (type NOT IN ('video', 'audio') OR agora_channel_name IS NOT NULL)
);
```

---

### 34. consultation_messages

**Purpose:** Chat messages within consultations.

```sql
CREATE TABLE consultation_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    consultation_id UUID NOT NULL REFERENCES consultations(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    sender_type TEXT NOT NULL CHECK (sender_type IN ('patient', 'provider')),
    content TEXT NOT NULL,
    attachments JSONB,
    read_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

---

### 35. prescriptions

**Purpose:** Digital prescriptions with auto-expiration and pharmacy routing.

```sql
CREATE TABLE prescriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    consultation_id UUID NOT NULL REFERENCES consultations(id) ON DELETE RESTRICT,
    provider_id UUID NOT NULL REFERENCES healthcare_providers(id) ON DELETE RESTRICT,
    patient_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE RESTRICT,
    diagnosis TEXT,
    medications JSONB NOT NULL,
    notes TEXT,

    -- Pharmacy Routing
    routing_strategy TEXT,
    primary_pharmacy_id UUID,
    routing_details JSONB,

    -- Denormalized Provider Info
    provider_name TEXT NOT NULL,
    provider_credentials TEXT,

    -- Status & Dates
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'expired', 'fulfilled', 'cancelled')),
    issue_date DATE DEFAULT CURRENT_DATE,
    expiration_date DATE DEFAULT (CURRENT_DATE + INTERVAL '90 days'),
    dispensed_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    CONSTRAINT valid_expiration CHECK (expiration_date > issue_date)
);
```

---

### 36. consultation_transactions

**Purpose:** Payment and commission tracking for consultations.

```sql
CREATE TABLE consultation_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    consultation_id UUID UNIQUE NOT NULL REFERENCES consultations(id) ON DELETE RESTRICT,
    provider_id UUID NOT NULL REFERENCES healthcare_providers(id) ON DELETE RESTRICT,
    patient_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE RESTRICT,
    tenant_id UUID NOT NULL,

    -- Financial Breakdown
    gross_amount DECIMAL(10,2) NOT NULL,
    commission_amount DECIMAL(10,2) NOT NULL,
    net_provider_amount DECIMAL(10,2) NOT NULL,
    commission_rate DECIMAL(5,4) NOT NULL,

    -- Referral Commission
    referral_source TEXT NOT NULL CHECK (referral_source IN ('storefront', 'medic_clinic', 'direct')),
    referrer_entity_id UUID,
    referrer_commission_amount DECIMAL(10,2) DEFAULT 0,

    -- Payment Gateway
    payment_method TEXT,
    payment_reference TEXT UNIQUE,
    payment_status TEXT DEFAULT 'pending' CHECK (payment_status IN ('pending', 'completed', 'failed', 'refunded')),

    -- Payout Tracking
    payout_status TEXT DEFAULT 'pending_payout' CHECK (payout_status IN ('pending_payout', 'paid_out', 'on_hold', 'cancelled')),
    payout_reference TEXT,
    payout_date TIMESTAMPTZ,

    -- Refunds
    refund_amount DECIMAL(10,2) DEFAULT 0,
    refund_reason TEXT,
    commission_reversed BOOLEAN DEFAULT FALSE,
    refunded_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    CONSTRAINT valid_commission CHECK (gross_amount = commission_amount + net_provider_amount)
);
```

---

### 37. favorite_providers

**Purpose:** Patient bookmarks for favorite healthcare providers.

```sql
CREATE TABLE favorite_providers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    provider_id UUID NOT NULL REFERENCES healthcare_providers(id) ON DELETE CASCADE,
    notes TEXT,
    tags TEXT[],
    created_at TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE (patient_id, provider_id)
);
```

---

## Configuration Tables

### 38. loyalty_config

**Purpose:** Tenant-configurable loyalty points system.

```sql
CREATE TABLE loyalty_config (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    is_enabled BOOLEAN NOT NULL DEFAULT FALSE,
    points_per_currency_unit DECIMAL(8,2) NOT NULL DEFAULT 1.00,
    currency_unit DECIMAL(8,2) NOT NULL DEFAULT 100.00,
    min_redemption_points INTEGER NOT NULL DEFAULT 100,
    allow_partial_payment BOOLEAN NOT NULL DEFAULT TRUE,
    allow_full_payment BOOLEAN NOT NULL DEFAULT TRUE,
    redemption_value_per_point DECIMAL(8,2) NOT NULL DEFAULT 1.00,
    max_points_per_order INTEGER,
    points_expiry_days INTEGER,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT loyalty_config_tenant_unique UNIQUE(tenant_id),
    CONSTRAINT valid_points_per_unit CHECK (points_per_currency_unit > 0),
    CONSTRAINT valid_currency_unit CHECK (currency_unit > 0),
    CONSTRAINT valid_min_redemption CHECK (min_redemption_points >= 0),
    CONSTRAINT valid_redemption_value CHECK (redemption_value_per_point > 0),
    CONSTRAINT valid_max_points_per_order CHECK (max_points_per_order IS NULL OR max_points_per_order > 0),
    CONSTRAINT valid_expiry_days CHECK (points_expiry_days IS NULL OR points_expiry_days > 0)
);
```

---

### 39. storefront_config

**Purpose:** Marketplace storefront customization per tenant.

```sql
CREATE TABLE storefront_config (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    banner_url TEXT,
    about_text TEXT,
    welcome_message TEXT,
    operating_hours JSONB,
    contact_email VARCHAR(255),
    contact_phone VARCHAR(20),
    contact_whatsapp VARCHAR(20),
    physical_address TEXT,
    facebook_url TEXT,
    instagram_url TEXT,
    twitter_url TEXT,
    minimum_order_value DECIMAL(12,2) NOT NULL DEFAULT 0 CHECK (minimum_order_value >= 0),
    accept_online_orders BOOLEAN NOT NULL DEFAULT TRUE,
    allow_guest_checkout BOOLEAN NOT NULL DEFAULT TRUE,
    require_phone_verification BOOLEAN NOT NULL DEFAULT FALSE,
    show_stock_quantity BOOLEAN NOT NULL DEFAULT FALSE,
    show_out_of_stock BOOLEAN NOT NULL DEFAULT TRUE,
    products_per_page INTEGER NOT NULL DEFAULT 20 CHECK (products_per_page > 0),
    meta_title VARCHAR(255),
    meta_description TEXT,
    meta_keywords TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT storefront_config_tenant_unique UNIQUE(tenant_id)
);
```

---

### 40. system_config

**Purpose:** Global system configuration key-value store.

```sql
CREATE TABLE system_config (
    key TEXT PRIMARY KEY,
    value TEXT NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

**Example Values:**
- `healthcare_commission_rate`: `0.15` (15% commission for healthcare consultations)

---

## Views

### v_branch_products

**Purpose:** Join products with branch inventory levels.

```sql
CREATE VIEW v_branch_products AS
SELECT
    p.*,
    bi.branch_id,
    bi.stock_quantity,
    bi.low_stock_threshold,
    bi.expiry_date,
    bi.expiry_alert_days,
    bi.is_active as inventory_active,
    CASE
        WHEN bi.stock_quantity <= bi.low_stock_threshold THEN true
        ELSE false
    END as is_low_stock,
    CASE
        WHEN bi.expiry_date IS NOT NULL
        AND bi.expiry_date <= CURRENT_DATE + (bi.expiry_alert_days || ' days')::INTERVAL
        THEN true
        ELSE false
    END as is_expiring_soon
FROM products p
INNER JOIN branch_inventory bi ON bi.product_id = p.id
WHERE p._sync_is_deleted = false
AND bi._sync_is_deleted = false;
```

---

### ecommerce_products

**Purpose:** Aggregated product catalog for e-commerce storefront.

```sql
CREATE VIEW ecommerce_products AS
SELECT
    p.id,
    p.tenant_id,
    p.name,
    p.description,
    p.category,
    p.unit_price,
    p.image_url,
    p.is_active,
    COALESCE(SUM(bi.stock_quantity), 0) as total_stock,
    COUNT(DISTINCT bi.branch_id) as branch_count,
    COALESCE(
        jsonb_agg(
            jsonb_build_object(
                'branch_id', b.id,
                'branch_name', b.name,
                'branch_address', b.address,
                'branch_phone', b.phone,
                'latitude', b.latitude,
                'longitude', b.longitude,
                'stock_quantity', bi.stock_quantity,
                'in_stock', bi.stock_quantity > 0
            ) ORDER BY b.name
        ) FILTER (WHERE bi.id IS NOT NULL),
        '[]'::jsonb
    ) as branches,
    p.unit_price as min_price,
    p.unit_price as max_price,
    p.created_at,
    p.updated_at
FROM products p
LEFT JOIN branch_inventory bi ON bi.product_id = p.id AND bi.is_active = true
LEFT JOIN branches b ON bi.branch_id = b.id AND b.deleted_at IS NULL
WHERE p._sync_is_deleted = false
  AND p.is_active = TRUE
GROUP BY p.id, p.tenant_id, p.name, p.description, p.category, p.unit_price, p.image_url, p.is_active, p.created_at, p.updated_at;
```

---

### product_stock_status

**Purpose:** Real-time stock status per branch with alerts.

```sql
CREATE VIEW product_stock_status AS
SELECT
    p.id AS product_id,
    p.tenant_id,
    bi.branch_id,
    p.name AS product_name,
    p.sku,
    p.barcode,
    bi.stock_quantity,
    bi.reserved_quantity,
    (bi.stock_quantity - bi.reserved_quantity) AS available_quantity,
    bi.low_stock_threshold,
    CASE
        WHEN (bi.stock_quantity - bi.reserved_quantity) <= 0 THEN 'out_of_stock'
        WHEN bi.low_stock_threshold IS NOT NULL
             AND (bi.stock_quantity - bi.reserved_quantity) <= bi.low_stock_threshold THEN 'low_stock'
        ELSE 'in_stock'
    END AS stock_status,
    p.unit_price AS selling_price,
    p.cost_price,
    (p.cost_price * bi.stock_quantity) AS total_stock_value,
    bi.expiry_date,
    CASE
        WHEN bi.expiry_date IS NULL THEN NULL
        WHEN bi.expiry_date < CURRENT_DATE THEN 'expired'
        WHEN bi.expiry_date < (CURRENT_DATE + bi.expiry_alert_days) THEN 'expiring_soon'
        ELSE 'valid'
    END AS expiry_status,
    bi.expiry_alert_days,
    p.is_active,
    bi.created_at,
    bi.updated_at
FROM products p
INNER JOIN branch_inventory bi ON p.id = bi.product_id
WHERE p.is_active = TRUE;
```

---

## Helper Functions

### RLS Helper Functions

```sql
-- Get current tenant ID
CREATE FUNCTION current_tenant_id() RETURNS UUID AS $$
    SELECT tenant_id FROM users WHERE id = auth.uid();
$$ LANGUAGE SQL SECURITY DEFINER STABLE;

-- Get current user role
CREATE FUNCTION current_user_role() RETURNS TEXT AS $$
    SELECT role FROM users WHERE id = auth.uid();
$$ LANGUAGE SQL SECURITY DEFINER STABLE;

-- Get current user branch ID
CREATE FUNCTION current_user_branch_id() RETURNS UUID AS $$
    SELECT branch_id FROM users WHERE id = auth.uid();
$$ LANGUAGE SQL SECURITY DEFINER STABLE;

-- Check if user has permission
CREATE FUNCTION has_permission(required_role TEXT) RETURNS BOOLEAN AS $$
DECLARE
    v_user_role TEXT;
    v_role_hierarchy INTEGER;
    v_required_hierarchy INTEGER;
BEGIN
    v_user_role := current_user_role();
    v_role_hierarchy := CASE v_user_role
        WHEN 'super_admin' THEN 100
        WHEN 'tenant_admin' THEN 80
        WHEN 'branch_manager' THEN 60
        WHEN 'staff' THEN 40
        WHEN 'rider' THEN 20
        ELSE 0
    END;
    v_required_hierarchy := CASE required_role
        WHEN 'super_admin' THEN 100
        WHEN 'tenant_admin' THEN 80
        WHEN 'branch_manager' THEN 60
        WHEN 'staff' THEN 40
        WHEN 'rider' THEN 20
        ELSE 0
    END;
    RETURN v_role_hierarchy >= v_required_hierarchy;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- Check tenant access
CREATE FUNCTION is_in_tenant(check_tenant_id UUID) RETURNS BOOLEAN AS $$
BEGIN
    RETURN check_tenant_id = current_tenant_id();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- Check branch access
CREATE FUNCTION can_access_branch(check_branch_id UUID) RETURNS BOOLEAN AS $$
DECLARE
    v_user_role TEXT;
    v_user_branch_id UUID;
    v_tenant_id UUID;
    v_branch_tenant_id UUID;
BEGIN
    v_user_role := current_user_role();
    v_user_branch_id := current_user_branch_id();
    v_tenant_id := current_tenant_id();
    IF v_user_role IN ('super_admin', 'tenant_admin') THEN
        SELECT tenant_id INTO v_branch_tenant_id
        FROM branches WHERE id = check_branch_id;
        RETURN v_branch_tenant_id = v_tenant_id;
    ELSE
        RETURN check_branch_id = v_user_branch_id OR v_user_branch_id IS NULL;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- Permission check functions
CREATE FUNCTION can_manage_users() RETURNS BOOLEAN AS $$
BEGIN
    RETURN current_user_role() IN ('super_admin', 'tenant_admin', 'branch_manager');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

CREATE FUNCTION can_manage_products() RETURNS BOOLEAN AS $$
BEGIN
    RETURN current_user_role() IN ('super_admin', 'tenant_admin', 'branch_manager');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

CREATE FUNCTION can_view_reports() RETURNS BOOLEAN AS $$
BEGIN
    RETURN current_user_role() IN ('super_admin', 'tenant_admin', 'branch_manager');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

CREATE FUNCTION can_void_sales() RETURNS BOOLEAN AS $$
BEGIN
    RETURN current_user_role() IN ('super_admin', 'tenant_admin', 'branch_manager');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- Get accessible branches
CREATE FUNCTION get_accessible_branches() RETURNS SETOF UUID AS $$
DECLARE
    v_user_role TEXT;
    v_tenant_id UUID;
    v_user_branch_id UUID;
BEGIN
    v_user_role := current_user_role();
    v_tenant_id := current_tenant_id();
    v_user_branch_id := current_user_branch_id();
    IF v_user_role IN ('super_admin', 'tenant_admin') THEN
        RETURN QUERY SELECT id FROM branches WHERE tenant_id = v_tenant_id;
    ELSE
        IF v_user_branch_id IS NOT NULL THEN
            RETURN QUERY SELECT v_user_branch_id;
        END IF;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
```

---

### Business Logic Functions

```sql
-- Calculate loyalty points
CREATE FUNCTION calculate_loyalty_points(
    p_tenant_id UUID,
    p_purchase_amount DECIMAL
) RETURNS INTEGER AS $$
DECLARE
    v_config RECORD;
    v_points INTEGER;
BEGIN
    SELECT is_enabled, points_per_currency_unit, currency_unit
    INTO v_config FROM loyalty_config WHERE tenant_id = p_tenant_id;
    IF v_config IS NULL OR v_config.is_enabled = FALSE THEN
        RETURN 0;
    END IF;
    v_points := FLOOR((p_purchase_amount / v_config.currency_unit) * v_config.points_per_currency_unit);
    RETURN GREATEST(v_points, 0);
END;
$$ LANGUAGE plpgsql;

-- Calculate redemption value
CREATE FUNCTION calculate_redemption_value(
    p_tenant_id UUID,
    p_points INTEGER
) RETURNS DECIMAL AS $$
DECLARE
    v_config RECORD;
    v_value DECIMAL;
BEGIN
    SELECT is_enabled, redemption_value_per_point, min_redemption_points
    INTO v_config FROM loyalty_config WHERE tenant_id = p_tenant_id;
    IF v_config IS NULL OR v_config.is_enabled = FALSE THEN
        RETURN 0;
    END IF;
    IF p_points < v_config.min_redemption_points THEN
        RETURN 0;
    END IF;
    v_value := p_points * v_config.redemption_value_per_point;
    RETURN v_value;
END;
$$ LANGUAGE plpgsql;

-- Calculate commission with cap
CREATE FUNCTION calculate_commission(
    p_tenant_id UUID,
    p_order_amount DECIMAL
) RETURNS DECIMAL AS $$
DECLARE
    v_commission_rate DECIMAL;
    v_commission_cap DECIMAL;
    v_calculated_commission DECIMAL;
BEGIN
    SELECT s.commission_rate, s.commission_cap_amount
    INTO v_commission_rate, v_commission_cap
    FROM tenants t
    JOIN subscriptions s ON t.subscription_id = s.id
    WHERE t.id = p_tenant_id AND s.status = 'active';
    IF v_commission_rate IS NULL OR v_commission_rate = 0 THEN
        RETURN 0;
    END IF;
    v_calculated_commission := p_order_amount * (v_commission_rate / 100);
    IF v_commission_cap IS NOT NULL AND v_calculated_commission > v_commission_cap THEN
        RETURN v_commission_cap;
    END IF;
    RETURN v_calculated_commission;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Check if tenant has chat feature
CREATE FUNCTION has_chat_feature(p_tenant_id UUID) RETURNS BOOLEAN AS $$
DECLARE
    v_plan_tier plan_tier;
BEGIN
    SELECT s.plan_tier INTO v_plan_tier
    FROM tenants t
    JOIN subscriptions s ON t.subscription_id = s.id
    WHERE t.id = p_tenant_id AND s.status = 'active';
    RETURN v_plan_tier IN ('pro', 'enterprise', 'enterprise_custom');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Check if tenant can enable e-commerce
CREATE FUNCTION can_enable_ecommerce(p_tenant_id UUID) RETURNS BOOLEAN AS $$
DECLARE
    v_plan_tier plan_tier;
BEGIN
    SELECT s.plan_tier INTO v_plan_tier
    FROM tenants t
    JOIN subscriptions s ON t.subscription_id = s.id
    WHERE t.id = p_tenant_id AND s.status = 'active';
    RETURN v_plan_tier IN ('pro', 'enterprise', 'enterprise_custom');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Check if storefront is open
CREATE FUNCTION is_storefront_open(
    p_tenant_id UUID,
    p_check_time TIMESTAMPTZ DEFAULT NOW()
) RETURNS BOOLEAN AS $$
DECLARE
    v_config RECORD;
    v_day_of_week TEXT;
    v_current_time TIME;
    v_hours JSONB;
    v_is_open BOOLEAN;
    v_open_time TIME;
    v_close_time TIME;
BEGIN
    SELECT is_active, operating_hours INTO v_config
    FROM storefront_config WHERE tenant_id = p_tenant_id;
    IF v_config IS NULL OR v_config.is_active = FALSE THEN
        RETURN FALSE;
    END IF;
    IF v_config.operating_hours IS NULL THEN
        RETURN TRUE;
    END IF;
    v_day_of_week := LOWER(TO_CHAR(p_check_time, 'Day'));
    v_day_of_week := TRIM(v_day_of_week);
    v_current_time := p_check_time::TIME;
    v_hours := v_config.operating_hours -> v_day_of_week;
    IF v_hours IS NULL THEN
        RETURN FALSE;
    END IF;
    v_is_open := (v_hours ->> 'is_open')::BOOLEAN;
    IF v_is_open = FALSE THEN
        RETURN FALSE;
    END IF;
    v_open_time := (v_hours ->> 'open')::TIME;
    v_close_time := (v_hours ->> 'close')::TIME;
    RETURN v_current_time BETWEEN v_open_time AND v_close_time;
END;
$$ LANGUAGE plpgsql;
```

---

### Inventory Management Functions

```sql
-- Get available stock
CREATE FUNCTION get_available_stock(
    p_branch_id UUID,
    p_product_id UUID
) RETURNS INTEGER AS $$
DECLARE
    v_available INTEGER;
BEGIN
    SELECT stock_quantity - reserved_quantity INTO v_available
    FROM branch_inventory
    WHERE branch_id = p_branch_id AND product_id = p_product_id;
    RETURN COALESCE(v_available, 0);
END;
$$ LANGUAGE plpgsql;

-- Reserve inventory
CREATE FUNCTION reserve_inventory(
    p_branch_id UUID,
    p_product_id UUID,
    p_quantity INTEGER
) RETURNS BOOLEAN AS $$
DECLARE
    v_available INTEGER;
    v_rows_updated INTEGER;
BEGIN
    v_available := get_available_stock(p_branch_id, p_product_id);
    IF v_available < p_quantity THEN
        RETURN FALSE;
    END IF;
    UPDATE branch_inventory
    SET reserved_quantity = reserved_quantity + p_quantity, updated_at = NOW()
    WHERE branch_id = p_branch_id AND product_id = p_product_id
    AND (stock_quantity - reserved_quantity) >= p_quantity;
    GET DIAGNOSTICS v_rows_updated = ROW_COUNT;
    RETURN v_rows_updated > 0;
END;
$$ LANGUAGE plpgsql;

-- Release reserved inventory
CREATE FUNCTION release_reserved_inventory(
    p_branch_id UUID,
    p_product_id UUID,
    p_quantity INTEGER
) RETURNS BOOLEAN AS $$
DECLARE
    v_rows_updated INTEGER;
BEGIN
    UPDATE branch_inventory
    SET reserved_quantity = GREATEST(reserved_quantity - p_quantity, 0), updated_at = NOW()
    WHERE branch_id = p_branch_id AND product_id = p_product_id
    AND reserved_quantity >= p_quantity;
    GET DIAGNOSTICS v_rows_updated = ROW_COUNT;
    RETURN v_rows_updated > 0;
END;
$$ LANGUAGE plpgsql;

-- Confirm reservation (deduct stock)
CREATE FUNCTION confirm_reservation(
    p_branch_id UUID,
    p_product_id UUID,
    p_quantity INTEGER
) RETURNS BOOLEAN AS $$
DECLARE
    v_rows_updated INTEGER;
BEGIN
    UPDATE branch_inventory
    SET stock_quantity = stock_quantity - p_quantity,
        reserved_quantity = GREATEST(reserved_quantity - p_quantity, 0),
        updated_at = NOW()
    WHERE branch_id = p_branch_id AND product_id = p_product_id
    AND reserved_quantity >= p_quantity AND stock_quantity >= p_quantity;
    GET DIAGNOSTICS v_rows_updated = ROW_COUNT;
    RETURN v_rows_updated > 0;
END;
$$ LANGUAGE plpgsql;
```

---

### Healthcare Functions

```sql
-- Release expired slot holds
CREATE FUNCTION release_expired_slot_holds() RETURNS void AS $$
BEGIN
    UPDATE provider_time_slots
    SET status = 'available', held_until = NULL, held_by_user = NULL, version = version + 1
    WHERE status = 'held_for_payment' AND held_until < NOW();
END;
$$ LANGUAGE plpgsql;
```

---

## ⚡ Triggers (Updated - Real-Time Sync)

**Last Updated:** March 10, 2026

### Overview

The database has both **legacy triggers** (for timestamps, sync versions, etc.) and **NEW automatic inventory sync triggers** added on March 10, 2026.

---

### 🆕 NEW: Real-Time Inventory Sync Triggers (March 10, 2026)

These triggers automatically handle inventory synchronization between POS and marketplace:

#### 1. `auto_sync_inventory_on_sale`
**Table:** `sales`
**Event:** AFTER INSERT OR UPDATE OF status
**When:** `NEW.status = 'completed'`

```sql
CREATE FUNCTION trigger_sync_inventory_on_sale() RETURNS TRIGGER AS $$
DECLARE
    v_item RECORD;
BEGIN
    IF NEW.status = 'completed' THEN
        FOR v_item IN
            SELECT product_id, quantity FROM sale_items WHERE sale_id = NEW.id
        LOOP
            UPDATE branch_inventory
            SET stock_quantity = stock_quantity - v_item.quantity,
                updated_at = NOW()
            WHERE branch_id = NEW.branch_id
              AND product_id = v_item.product_id
              AND stock_quantity >= v_item.quantity;
        END LOOP;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

**Purpose:** When a POS sale is completed, automatically deducts inventory from `branch_inventory`.

---

#### 2. `auto_sync_product_stock`
**Table:** `branch_inventory`
**Event:** AFTER INSERT OR UPDATE OR DELETE

```sql
CREATE FUNCTION trigger_sync_product_stock() RETURNS TRIGGER AS $$
BEGIN
    PERFORM sync_product_total_stock(COALESCE(NEW.product_id, OLD.product_id));
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

**Purpose:** When `branch_inventory` changes, recalculates `products.stock_quantity` (total across all branches).

---

#### 3. `auto_reserve_inventory_on_order`
**Table:** `orders`
**Event:** AFTER INSERT

```sql
CREATE FUNCTION reserve_inventory_on_order_create() RETURNS TRIGGER AS $$
DECLARE
    v_item RECORD;
    v_success BOOLEAN;
BEGIN
    IF NEW.status = 'pending' THEN
        FOR v_item IN
            SELECT product_id, quantity FROM order_items WHERE order_id = NEW.id
        LOOP
            v_success := reserve_inventory(NEW.branch_id, v_item.product_id, v_item.quantity);
            IF NOT v_success THEN
                RAISE EXCEPTION 'Failed to reserve inventory for product % in order %',
                    v_item.product_id, NEW.id;
            END IF;
        END LOOP;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

**Purpose:** When a marketplace order is created, reserves inventory in `branch_inventory.reserved_quantity`.

---

#### 4. `auto_order_inventory_sync`
**Table:** `orders`
**Event:** AFTER UPDATE OF status
**When:** `OLD.status IS DISTINCT FROM NEW.status`

```sql
CREATE FUNCTION trigger_order_inventory_sync() RETURNS TRIGGER AS $$
BEGIN
    -- When order confirmed, deduct inventory
    IF OLD.status IN ('pending') AND NEW.status IN ('confirmed', 'processing') THEN
        PERFORM deduct_inventory_on_order_confirm(NEW.id);
    END IF;

    -- When order cancelled, restore inventory
    IF NEW.status = 'cancelled' AND OLD.status != 'cancelled' THEN
        PERFORM restore_inventory_on_order_cancel(NEW.id);
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

**Purpose:** Manages inventory when order status changes (confirms or cancels).

---

### New Database Views for Real-Time Stock

#### `marketplace_products_with_stock`
Shows all products with aggregated available stock across branches:

```sql
CREATE VIEW marketplace_products_with_stock AS
SELECT
    p.id, p.tenant_id, p.name, p.description, p.sku, p.category,
    p.unit_price AS price, p.image_url,
    COALESCE(SUM(bi.stock_quantity - bi.reserved_quantity), 0)::INTEGER AS stock_quantity,
    COALESCE(SUM(bi.stock_quantity - bi.reserved_quantity), 0) > 0 AS is_available,
    p.created_at, p.updated_at
FROM products p
LEFT JOIN branch_inventory bi ON p.id = bi.product_id
WHERE p.is_active = TRUE AND p.deleted_at IS NULL
GROUP BY p.id, p.tenant_id, p.name, p.description, p.sku,
         p.category, p.unit_price, p.image_url, p.created_at, p.updated_at;
```

**FlutterFlow Usage:**
```dart
// Query this view instead of products table for real-time stock
final products = await Supabase.instance.client
  .from('marketplace_products_with_stock')
  .select()
  .eq('tenant_id', tenantId);
```

---

#### `product_stock_status`
Detailed stock status per branch with reserved quantities:

```sql
CREATE VIEW product_stock_status AS
SELECT
    p.id AS product_id, p.tenant_id, bi.branch_id, p.name AS product_name,
    bi.stock_quantity, bi.reserved_quantity,
    (bi.stock_quantity - bi.reserved_quantity) AS available_quantity,
    bi.low_stock_threshold,
    CASE
        WHEN (bi.stock_quantity - bi.reserved_quantity) <= 0 THEN 'out_of_stock'
        WHEN (bi.stock_quantity - bi.reserved_quantity) <= bi.low_stock_threshold THEN 'low_stock'
        ELSE 'in_stock'
    END AS stock_status,
    bi.created_at, bi.updated_at
FROM products p
INNER JOIN branch_inventory bi ON p.id = bi.product_id
WHERE p.is_active = TRUE;
```

**FlutterFlow Usage:**
```dart
// Get detailed stock status per branch
final stockStatus = await Supabase.instance.client
  .from('product_stock_status')
  .select()
  .eq('branch_id', branchId);
```

---

### Helper Functions for Inventory Sync

#### `sync_product_total_stock(product_id)`
Recalculates total product stock from all branches:

```sql
CREATE FUNCTION sync_product_total_stock(p_product_id UUID) RETURNS VOID AS $$
DECLARE
    v_total_stock INTEGER;
BEGIN
    SELECT COALESCE(SUM(stock_quantity - reserved_quantity), 0)
    INTO v_total_stock
    FROM branch_inventory
    WHERE product_id = p_product_id;

    UPDATE products
    SET stock_quantity = v_total_stock, updated_at = NOW()
    WHERE id = p_product_id;
END;
$$ LANGUAGE plpgsql;
```

---

#### `get_marketplace_stock(product_id, tenant_id)`
Returns real-time stock information:

```sql
CREATE FUNCTION get_marketplace_stock(p_product_id UUID, p_tenant_id UUID)
RETURNS TABLE (
    product_id UUID,
    total_stock INTEGER,
    reserved_stock INTEGER,
    available_stock INTEGER,
    is_available BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        p.id AS product_id,
        COALESCE(SUM(bi.stock_quantity), 0)::INTEGER AS total_stock,
        COALESCE(SUM(bi.reserved_quantity), 0)::INTEGER AS reserved_stock,
        COALESCE(SUM(bi.stock_quantity - bi.reserved_quantity), 0)::INTEGER AS available_stock,
        COALESCE(SUM(bi.stock_quantity - bi.reserved_quantity), 0) > 0 AS is_available
    FROM products p
    LEFT JOIN branch_inventory bi ON p.id = bi.product_id
    WHERE p.id = p_product_id AND p.tenant_id = p_tenant_id
    GROUP BY p.id;
END;
$$ LANGUAGE plpgsql;
```

**FlutterFlow Usage:**
```dart
final result = await Supabase.instance.client.rpc('get_marketplace_stock', {
  'p_product_id': productId,
  'p_tenant_id': tenantId
});
```

---

#### `check_product_availability(product_id, quantity, tenant_id)`
Validates if product has sufficient stock:

```sql
CREATE FUNCTION check_product_availability(
    p_product_id UUID,
    p_quantity INTEGER,
    p_tenant_id UUID DEFAULT NULL
) RETURNS JSON AS $$
DECLARE
    v_available INTEGER;
    v_result JSON;
BEGIN
    SELECT available_stock INTO v_available
    FROM get_marketplace_stock(p_product_id, p_tenant_id);

    v_result := json_build_object(
        'product_id', p_product_id,
        'available_stock', COALESCE(v_available, 0),
        'requested_quantity', p_quantity,
        'is_available', COALESCE(v_available, 0) >= p_quantity,
        'message', CASE
            WHEN COALESCE(v_available, 0) >= p_quantity THEN 'Product available'
            WHEN COALESCE(v_available, 0) > 0 THEN format('Only %s units available', v_available)
            ELSE 'Product out of stock'
        END
    );

    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

---

### Impact on FlutterFlow Development

**What Changed:**
- ✅ Sales automatically update inventory (no manual code needed)
- ✅ Marketplace shows real-time stock (via views)
- ✅ Orders automatically reserve/deduct inventory
- ✅ Multi-platform sync (Flutter POS ↔ SvelteKit Marketplace)

**What to Do:**
```dart
// ✅ DO THIS - Simple sale completion
await Supabase.instance.client.from('sales').insert({
  'status': 'completed',  // Triggers fire automatically!
  // ... other fields
});

// ✅ DO THIS - Query real-time stock
final products = await Supabase.instance.client
  .from('marketplace_products_with_stock')
  .select();

// ❌ DON'T DO THIS - Manual stock updates (unnecessary!)
// The triggers handle this automatically
```

**📖 Complete Guide:** [AUTOMATIC_DATABASE_TRIGGERS.md](./AUTOMATIC_DATABASE_TRIGGERS.md)

---

### Legacy Triggers (Existing)

### Update Timestamp Triggers

```sql
-- Generic updated_at trigger function
CREATE FUNCTION update_updated_at() RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Applied to tables: tenants, branches, users, products, customers, sales,
-- subscriptions, branch_inventory, inter_branch_transfers, loyalty_config, storefront_config
```

---

### Sync Version Triggers

```sql
-- Increment sync version for CRDT (offline-first)
CREATE FUNCTION increment_sync_version() RETURNS TRIGGER AS $$
BEGIN
    NEW._sync_version = OLD._sync_version + 1;
    NEW._sync_modified_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Applied to: products, sales, customers
```

---

### Business Logic Triggers

```sql
-- Auto-generate sale number
CREATE FUNCTION generate_sale_number() RETURNS TRIGGER AS $$
DECLARE
    branch_code VARCHAR(10);
    sequence_num INTEGER;
BEGIN
    SELECT LEFT(name, 3) INTO branch_code FROM branches WHERE id = NEW.branch_id;
    SELECT COUNT(*) + 1 INTO sequence_num
    FROM sales WHERE branch_id = NEW.branch_id AND DATE(created_at) = CURRENT_DATE;
    NEW.sale_number = UPPER(branch_code) || '-' || TO_CHAR(CURRENT_DATE, 'YYYYMMDD') || '-' || LPAD(sequence_num::TEXT, 4, '0');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Auto-create commission on order completion
CREATE FUNCTION create_commission_on_order_complete() RETURNS TRIGGER AS $$
DECLARE
    tenant_commission_rate DECIMAL(5,2);
BEGIN
    IF NEW.order_status = 'completed' AND NEW.order_type = 'marketplace' THEN
        SELECT commission_rate INTO tenant_commission_rate
        FROM subscriptions WHERE tenant_id = NEW.tenant_id;
        INSERT INTO commissions (tenant_id, order_id, sale_amount, commission_rate, commission_amount)
        VALUES (
            NEW.tenant_id,
            NEW.id,
            NEW.total_amount,
            tenant_commission_rate,
            NEW.total_amount * (tenant_commission_rate / 100)
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Update customer loyalty on sale
CREATE FUNCTION update_customer_loyalty() RETURNS TRIGGER AS $$
DECLARE
    points_earned INTEGER;
BEGIN
    IF NEW.customer_id IS NOT NULL AND NEW.status = 'completed' THEN
        points_earned = FLOOR(NEW.total_amount / 100);
        UPDATE customers
        SET loyalty_points = loyalty_points + points_earned,
            total_purchases = total_purchases + NEW.total_amount,
            purchase_count = purchase_count + 1,
            last_purchase_at = NEW.created_at
        WHERE id = NEW.customer_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Update branch inventory stock after transaction
CREATE FUNCTION update_branch_inventory_stock() RETURNS TRIGGER AS $$
BEGIN
    UPDATE branch_inventory
    SET stock_quantity = NEW.new_quantity, updated_at = NOW()
    WHERE branch_id = NEW.branch_id AND product_id = NEW.product_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Check reorder alert
CREATE FUNCTION check_reorder_alert() RETURNS TRIGGER AS $$
DECLARE
    v_available INTEGER;
    v_product_name TEXT;
BEGIN
    v_available := NEW.stock_quantity - NEW.reserved_quantity;
    SELECT name INTO v_product_name FROM products WHERE id = NEW.product_id;
    IF NEW.low_stock_threshold IS NOT NULL THEN
        IF v_available <= NEW.low_stock_threshold THEN
            RAISE NOTICE 'Low stock alert: Product % (%) at branch % has % available (threshold: %)',
                v_product_name, NEW.product_id, NEW.branch_id, v_available, NEW.low_stock_threshold;
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Auto-expire prescriptions
CREATE FUNCTION update_prescription_status() RETURNS TRIGGER AS $$
BEGIN
    IF NEW.expiration_date < CURRENT_DATE AND NEW.status = 'active' THEN
        NEW.status := 'expired';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

---

## Row Level Security (RLS) Policies

### Core Principle
All tables have RLS enabled with tenant isolation as the base policy.

### Pattern: Tenant Isolation

```sql
-- Tenant-scoped tables
CREATE POLICY "Tenant isolation" ON <table>
    FOR ALL USING (tenant_id = current_tenant_id());
```

Applied to: tenants, branches, products, branch_inventory, inventory_transactions, customers, sales, sale_items, orders, order_items, deliveries, riders, staff_attendance, ecommerce_connections, chat_conversations, whatsapp_messages, commissions, loyalty_config, storefront_config

---

### User Registration Policies

```sql
-- Allow self-registration
CREATE POLICY "users_insert_own" ON users FOR INSERT
    WITH CHECK (auth.uid() = id);

-- Allow managers to create staff
CREATE POLICY "managers_insert_staff" ON users FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM users AS u
            WHERE u.id = auth.uid()
            AND u.tenant_id IS NOT NULL
            AND u.role IN ('platform_admin', 'tenant_admin', 'branch_manager')
        )
        AND tenant_id IS NOT NULL
    );
```

---

### Branch-Level Access Control

```sql
-- Products: Tenant admins see all, others see their branch
CREATE POLICY "Product branch access" ON products FOR SELECT
    USING (
        current_user_role() = 'tenant_admin' OR
        branch_id = current_user_branch_id()
    );
```

---

### Healthcare RLS Policies

```sql
-- Public read for active/verified providers
CREATE POLICY "Anyone can view active verified providers"
    ON healthcare_providers FOR SELECT
    USING (is_active = TRUE AND is_verified = TRUE);

-- Patients can view their own consultations
CREATE POLICY "Patients can view own consultations"
    ON consultations FOR SELECT
    USING (patient_id = auth.uid());

-- Providers can view their assigned consultations
CREATE POLICY "Providers can view assigned consultations"
    ON consultations FOR SELECT
    USING (provider_id IN (SELECT id FROM healthcare_providers WHERE user_id = auth.uid()));
```

---

## Indexes

### Performance Indexes

```sql
-- Tenants
CREATE INDEX idx_tenants_slug ON tenants(slug);
CREATE INDEX idx_tenants_email ON tenants(email) WHERE email IS NOT NULL;
CREATE INDEX idx_tenants_country_code ON tenants(country_code) WHERE country_code IS NOT NULL AND deleted_at IS NULL;
CREATE UNIQUE INDEX idx_tenants_custom_domain ON tenants(custom_domain) WHERE custom_domain IS NOT NULL AND deleted_at IS NULL;

-- Branches
CREATE INDEX idx_branches_tenant ON branches(tenant_id, deleted_at) WHERE deleted_at IS NULL;
CREATE INDEX idx_branches_location ON branches USING GIST(geography(ST_MakePoint(longitude, latitude))) WHERE latitude IS NOT NULL AND longitude IS NOT NULL;

-- Users
CREATE INDEX idx_users_tenant ON users(tenant_id, deleted_at) WHERE deleted_at IS NULL;
CREATE UNIQUE INDEX idx_users_email ON users(email) WHERE email IS NOT NULL AND deleted_at IS NULL;
CREATE UNIQUE INDEX idx_users_phone ON users(phone) WHERE phone IS NOT NULL AND deleted_at IS NULL;

-- Products
CREATE INDEX idx_products_name_search ON products USING gin(to_tsvector('english', name));
CREATE INDEX idx_products_ecommerce ON products(tenant_id, category, is_active, deleted_at) WHERE deleted_at IS NULL AND is_active = TRUE;

-- Branch Inventory
CREATE INDEX idx_branch_inventory_tenant ON branch_inventory(tenant_id);
CREATE INDEX idx_branch_inventory_branch ON branch_inventory(branch_id);
CREATE INDEX idx_branch_inventory_product ON branch_inventory(product_id);
CREATE INDEX idx_branch_inventory_low_stock ON branch_inventory(branch_id) WHERE stock_quantity <= low_stock_threshold AND is_active = true;
CREATE INDEX idx_branch_inventory_available_stock ON branch_inventory(tenant_id, branch_id, (stock_quantity - reserved_quantity));

-- Inventory Transactions
CREATE INDEX idx_inventory_txn_branch_product ON inventory_transactions(branch_id, product_id, created_at DESC);
CREATE INDEX idx_inventory_txn_reference ON inventory_transactions(reference_type, reference_id);
CREATE INDEX idx_inventory_transactions_branch_inventory ON inventory_transactions(branch_inventory_id);

-- Customers
CREATE UNIQUE INDEX idx_customers_tenant_phone ON customers(tenant_id, phone) WHERE deleted_at IS NULL;
CREATE INDEX idx_customers_loyalty ON customers(tenant_id, loyalty_points DESC);

-- Sales
CREATE INDEX idx_sales_tenant_branch ON sales(tenant_id, branch_id, created_at DESC);
CREATE INDEX idx_sales_cashier ON sales(cashier_id, created_at DESC);
CREATE UNIQUE INDEX idx_sales_number ON sales(tenant_id, sale_number);

-- Orders
CREATE INDEX idx_orders_tenant_branch ON orders(tenant_id, branch_id, created_at DESC);
CREATE INDEX idx_orders_customer ON orders(customer_id, created_at DESC);
CREATE UNIQUE INDEX idx_orders_number ON orders(tenant_id, order_number);

-- Deliveries
CREATE UNIQUE INDEX idx_deliveries_tracking ON deliveries(tracking_number);
CREATE INDEX idx_deliveries_tenant_branch ON deliveries(tenant_id, branch_id, delivery_status);
CREATE INDEX idx_deliveries_rider ON deliveries(rider_id, delivery_status) WHERE rider_id IS NOT NULL;

-- Healthcare
CREATE INDEX idx_providers_country_specialization ON healthcare_providers(country, specialization);
CREATE INDEX idx_providers_rating ON healthcare_providers(average_rating DESC) WHERE is_active = TRUE AND is_verified = TRUE;
CREATE INDEX idx_slots_provider_date ON provider_time_slots(provider_id, date, status);
CREATE INDEX idx_consultations_patient ON consultations(patient_id, created_at DESC);
CREATE INDEX idx_consultations_provider ON consultations(provider_id, scheduled_time DESC);
CREATE INDEX idx_consultations_referral ON consultations(referral_source, referrer_entity_id);

-- Chat
CREATE INDEX idx_chat_tenant_branch ON chat_conversations(tenant_id, branch_id, started_at DESC);
CREATE INDEX idx_chat_messages_conversation ON chat_messages(conversation_id, created_at DESC);
CREATE INDEX idx_chat_messages_type ON chat_messages(message_type, created_at DESC);

-- Commissions
CREATE INDEX idx_commissions_tenant ON commissions(tenant_id, settlement_status);
CREATE INDEX idx_commissions_settlement ON commissions(settlement_status, created_at DESC);
```

---

## Summary

This database schema supports:

- **Multi-tenancy** with comprehensive RLS isolation
- **Multi-branch operations** with inter-branch transfers
- **Offline-first POS** with CRDT sync fields
- **E-commerce marketplace** with commission tracking
- **Healthcare telemedicine** with consultation management
- **Loyalty programs** per tenant
- **Delivery tracking** with GPS and proof of delivery
- **AI chat system** with rich media support
- **WhatsApp Business API** integration
- **Subscription-based billing** with usage tracking
- **Comprehensive audit logging** for compliance
- **Real-time inventory management** with reservation system

**Total Tables:** 40
**Total Views:** 3
**Total Functions:** 30+
**Total Triggers:** 10+
**Total RLS Policies:** 50+
**Total Indexes:** 100+

---

**End of Documentation**
