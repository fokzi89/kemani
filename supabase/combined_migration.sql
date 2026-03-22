-- Combined Migrations

-- File: 000_update_existing_database.sql
-- ============================================================
-- Database Update Script
-- ============================================================
-- Purpose: Update existing database with latest subscription data and apply new migrations
-- Run this in Supabase SQL Editor if you already have some migrations applied

-- Step 1: Delete old subscription data
DELETE FROM subscriptions;

-- Step 2: Update enum to include enterprise_custom (if not already there)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_enum WHERE enumlabel = 'enterprise_custom' AND enumtypid = 'plan_tier'::regtype) THEN
        ALTER TYPE plan_tier ADD VALUE 'enterprise_custom';
    END IF;
END $$;

-- Step 3: Add commission_cap_amount column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name='subscriptions' AND column_name='commission_cap_amount') THEN
        ALTER TABLE subscriptions ADD COLUMN commission_cap_amount DECIMAL(12,2) DEFAULT 500.00 CHECK (commission_cap_amount >= 0);
    END IF;
END $$;

-- Step 4: Insert updated subscription plans with correct commission rates and cap
INSERT INTO subscriptions (plan_tier, monthly_fee, commission_rate, max_branches, max_staff_users, max_products, monthly_transaction_quota, features, billing_cycle_start, billing_cycle_end, status, commission_cap_amount) VALUES
    -- Free Plan (â‚¦0/month, 0% commission - no e-commerce)
    (
        'free',
        0.00,
        0.00,
        1,
        3,
        100,
        500,
        '{
            "ai_chat": false,
            "ecommerce_chat": false,
            "ecommerce_enabled": false,
            "advanced_analytics": false,
            "api_access": false,
            "woocommerce_sync": false,
            "shopify_sync": false,
            "whatsapp_business_api": false,
            "multi_currency": false,
            "custom_integrations": false
        }'::jsonb,
        NOW(),
        NOW() + INTERVAL '1 month',
        'active',
        500.00
    ),

    -- Basic Plan (â‚¦5,000/month, 0% commission - no e-commerce)
    (
        'basic',
        5000.00,
        0.00,
        3,
        10,
        1000,
        5000,
        '{
            "ai_chat": true,
            "ecommerce_chat": false,
            "ecommerce_enabled": false,
            "advanced_analytics": false,
            "api_access": false,
            "woocommerce_sync": false,
            "shopify_sync": false,
            "whatsapp_business_api": true,
            "multi_currency": false,
            "custom_integrations": false,
            "inter_branch_transfers": true,
            "delivery_management": true
        }'::jsonb,
        NOW(),
        NOW() + INTERVAL '1 month',
        'active',
        500.00
    ),

    -- Pro Plan (â‚¦15,000/month, 1.5% commission)
    (
        'pro',
        15000.00,
        1.50,
        10,
        50,
        10000,
        50000,
        '{
            "ai_chat": true,
            "ecommerce_chat": true,
            "ecommerce_enabled": true,
            "advanced_analytics": true,
            "api_access": true,
            "woocommerce_sync": true,
            "shopify_sync": true,
            "whatsapp_business_api": true,
            "multi_currency": false,
            "custom_integrations": false,
            "inter_branch_transfers": true,
            "delivery_management": true,
            "bulk_import_export": true,
            "priority_support": true
        }'::jsonb,
        NOW(),
        NOW() + INTERVAL '1 month',
        'active',
        500.00
    ),

    -- Enterprise Plan (â‚¦50,000/month, 1% commission)
    (
        'enterprise',
        50000.00,
        1.00,
        999999,
        999999,
        999999,
        999999,
        '{
            "ai_chat": true,
            "ecommerce_chat": true,
            "ecommerce_enabled": true,
            "advanced_analytics": true,
            "api_access": true,
            "woocommerce_sync": true,
            "shopify_sync": true,
            "whatsapp_business_api": true,
            "multi_currency": true,
            "custom_integrations": false,
            "inter_branch_transfers": true,
            "delivery_management": true,
            "bulk_import_export": true,
            "priority_support": true,
            "phone_support": true,
            "dedicated_account_manager": true,
            "custom_reporting": true,
            "sla_guarantees": true,
            "data_export": true
        }'::jsonb,
        NOW(),
        NOW() + INTERVAL '1 month',
        'active',
        500.00
    ),

    -- Enterprise Custom Plan (Contact Sales, 0.5% commission)
    (
        'enterprise_custom',
        0.00,
        0.50,
        999999,
        999999,
        999999,
        999999,
        '{
            "ai_chat": true,
            "ecommerce_chat": true,
            "ecommerce_enabled": true,
            "custom_domain": true,
            "white_label": true,
            "advanced_analytics": true,
            "api_access": true,
            "woocommerce_sync": true,
            "shopify_sync": true,
            "whatsapp_business_api": true,
            "multi_currency": true,
            "custom_integrations": true,
            "inter_branch_transfers": true,
            "delivery_management": true,
            "bulk_import_export": true,
            "priority_support": true,
            "phone_support": true,
            "dedicated_account_manager": true,
            "support_24_7": true,
            "custom_reporting": true,
            "sla_guarantees": true,
            "data_export": true,
            "custom_development": true,
            "on_premise_option": true,
            "dedicated_infrastructure": false
        }'::jsonb,
        NOW(),
        NOW() + INTERVAL '1 month',
        'active',
        500.00
    );

-- Step 5: Add e-commerce fields to tenants table if they don't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name='tenants' AND column_name='ecommerce_enabled') THEN
        ALTER TABLE tenants ADD COLUMN ecommerce_enabled BOOLEAN DEFAULT FALSE;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name='tenants' AND column_name='custom_domain') THEN
        ALTER TABLE tenants ADD COLUMN custom_domain VARCHAR(255);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name='tenants' AND column_name='custom_domain_verified') THEN
        ALTER TABLE tenants ADD COLUMN custom_domain_verified BOOLEAN DEFAULT FALSE;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name='tenants' AND column_name='ecommerce_settings') THEN
        ALTER TABLE tenants ADD COLUMN ecommerce_settings JSONB DEFAULT '{}';
    END IF;
END $$;

-- Verify update
SELECT
    plan_tier,
    monthly_fee,
    commission_rate,
    commission_cap_amount,
    features->>'ecommerce_enabled' as ecommerce_enabled
FROM subscriptions
ORDER BY monthly_fee;


-- File: 001_extensions_and_enums.sql
-- ============================================================
-- Migration 001: Extensions and Enums
-- ============================================================
-- Purpose: Enable required PostgreSQL extensions and create custom types

-- Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";
CREATE EXTENSION IF NOT EXISTS "postgis";
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";

-- Enums
CREATE TYPE business_type AS ENUM ('supermarket', 'pharmacy', 'grocery', 'mini_mart', 'restaurant');
CREATE TYPE user_role AS ENUM ('platform_admin', 'tenant_admin', 'branch_manager', 'cashier', 'driver');
CREATE TYPE payment_method AS ENUM ('cash', 'card', 'bank_transfer', 'mobile_money');
CREATE TYPE transaction_type AS ENUM ('sale', 'restock', 'adjustment', 'expiry', 'transfer_out', 'transfer_in');
CREATE TYPE transfer_status AS ENUM ('pending', 'in_transit', 'completed', 'cancelled');
CREATE TYPE sale_status AS ENUM ('completed', 'voided', 'refunded');
CREATE TYPE order_type AS ENUM ('marketplace', 'ecommerce_sync', 'ai_chat');
CREATE TYPE order_status AS ENUM ('pending', 'confirmed', 'preparing', 'ready', 'completed', 'cancelled');
CREATE TYPE payment_status AS ENUM ('unpaid', 'paid', 'refunded');
CREATE TYPE fulfillment_type AS ENUM ('pickup', 'delivery');
CREATE TYPE delivery_type AS ENUM ('local_bike', 'local_bicycle', 'intercity');
CREATE TYPE delivery_status AS ENUM ('pending', 'assigned', 'picked_up', 'in_transit', 'delivered', 'failed', 'cancelled');
CREATE TYPE proof_type AS ENUM ('photo', 'signature', 'recipient_name');
CREATE TYPE vehicle_type AS ENUM ('bike', 'bicycle');
CREATE TYPE platform_type AS ENUM ('woocommerce', 'shopify', 'custom');
CREATE TYPE sync_status AS ENUM ('pending', 'syncing', 'success', 'error');
CREATE TYPE chat_status AS ENUM ('active', 'completed', 'escalated', 'abandoned');
CREATE TYPE sender_type AS ENUM ('customer', 'ai_agent', 'staff');
CREATE TYPE plan_tier AS ENUM ('free', 'basic', 'pro', 'enterprise', 'enterprise_custom');
CREATE TYPE subscription_status AS ENUM ('active', 'suspended', 'cancelled');
CREATE TYPE settlement_status AS ENUM ('pending', 'invoiced', 'paid');
CREATE TYPE message_direction AS ENUM ('outbound', 'inbound');
CREATE TYPE message_type AS ENUM ('text', 'template', 'media');
CREATE TYPE whatsapp_delivery_status AS ENUM ('pending', 'sent', 'delivered', 'read', 'failed');
CREATE TYPE receipt_format AS ENUM ('pdf', 'thermal_print', 'email');


-- File: 002_core_tables.sql
-- ============================================================
-- Migration 002: Core Tables
-- ============================================================
-- Purpose: Create subscriptions, tenants, branches, and users tables

-- Subscriptions
CREATE TABLE subscriptions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    plan_tier plan_tier NOT NULL,
    monthly_fee DECIMAL(12,2) NOT NULL CHECK (monthly_fee >= 0),
    commission_rate DECIMAL(5,2) NOT NULL CHECK (commission_rate >= 0 AND commission_rate <= 100),
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

-- Tenants
CREATE TABLE tenants (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(100) UNIQUE NOT NULL,
    email VARCHAR(255),
    phone VARCHAR(20),
    logo_url TEXT,
    brand_color VARCHAR(7) CHECK (brand_color ~ '^#[0-9A-Fa-f]{6}$'),
    subscription_id UUID REFERENCES subscriptions(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

-- Link subscription to tenant
ALTER TABLE subscriptions ADD COLUMN tenant_id UUID UNIQUE REFERENCES tenants(id);

-- Branches
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

-- Users
CREATE TABLE users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE,
    email VARCHAR(255),
    phone VARCHAR(20),
    full_name VARCHAR(255) NOT NULL,
    role user_role NOT NULL,
    branch_id UUID REFERENCES branches(id) ON DELETE SET NULL,
    avatar_url TEXT,
    last_login_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ,
    CONSTRAINT email_or_phone_required CHECK (email IS NOT NULL OR phone IS NOT NULL)
);


-- File: 003_product_inventory_tables.sql
-- ============================================================
-- Migration 003: Product and Inventory Tables
-- ============================================================
-- Purpose: Create products, inventory transactions, and transfer tables

-- Products
CREATE TABLE products (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    sku VARCHAR(100),
    barcode VARCHAR(100),
    category VARCHAR(100),
    unit_price DECIMAL(12,2) NOT NULL CHECK (unit_price > 0),
    cost_price DECIMAL(12,2) CHECK (cost_price >= 0),
    stock_quantity INTEGER NOT NULL DEFAULT 0 CHECK (stock_quantity >= 0),
    low_stock_threshold INTEGER DEFAULT 10 CHECK (low_stock_threshold >= 0),
    expiry_date DATE,
    expiry_alert_days INTEGER DEFAULT 30 CHECK (expiry_alert_days >= 0),
    image_url TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ,
    _sync_version BIGINT DEFAULT 1,
    _sync_modified_at TIMESTAMPTZ DEFAULT NOW(),
    _sync_client_id UUID,
    _sync_is_deleted BOOLEAN DEFAULT FALSE
);

-- Inventory Transactions
CREATE TABLE inventory_transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
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

-- Inter-Branch Transfers
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

CREATE TABLE transfer_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    transfer_id UUID NOT NULL REFERENCES inter_branch_transfers(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id),
    quantity INTEGER NOT NULL CHECK (quantity > 0)
);


-- File: 004_customer_sales_tables.sql
-- ============================================================
-- Migration 004: Customer and Sales Tables
-- ============================================================
-- Purpose: Create customers, customer addresses, sales, and sale items tables

-- Customers
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
    _sync_version BIGINT DEFAULT 1,
    _sync_modified_at TIMESTAMPTZ DEFAULT NOW(),
    _sync_client_id UUID,
    _sync_is_deleted BOOLEAN DEFAULT FALSE
);

CREATE TABLE customer_addresses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    label VARCHAR(50),
    address_line TEXT NOT NULL,
    latitude DECIMAL(10,8),
    longitude DECIMAL(11,8),
    is_default BOOLEAN DEFAULT FALSE
);

-- Sales
CREATE TABLE sales (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
    sale_number VARCHAR(50) NOT NULL,
    cashier_id UUID NOT NULL REFERENCES users(id),
    customer_id UUID REFERENCES customers(id),
    subtotal DECIMAL(12,2) NOT NULL CHECK (subtotal >= 0),
    tax_amount DECIMAL(12,2) NOT NULL DEFAULT 0 CHECK (tax_amount >= 0),
    discount_amount DECIMAL(12,2) NOT NULL DEFAULT 0 CHECK (discount_amount >= 0),
    total_amount DECIMAL(12,2) NOT NULL CHECK (total_amount > 0),
    payment_method payment_method NOT NULL,
    payment_reference VARCHAR(255),
    status sale_status DEFAULT 'completed',
    voided_at TIMESTAMPTZ,
    voided_by_id UUID REFERENCES users(id),
    void_reason TEXT,
    is_synced BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    _sync_version BIGINT DEFAULT 1,
    _sync_modified_at TIMESTAMPTZ DEFAULT NOW(),
    _sync_client_id UUID,
    _sync_is_deleted BOOLEAN DEFAULT FALSE,
    CONSTRAINT valid_total CHECK (total_amount = subtotal + tax_amount - discount_amount)
);

CREATE TABLE sale_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sale_id UUID NOT NULL REFERENCES sales(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id),
    product_name VARCHAR(255) NOT NULL,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    unit_price DECIMAL(12,2) NOT NULL CHECK (unit_price > 0),
    discount_percent DECIMAL(5,2) DEFAULT 0 CHECK (discount_percent >= 0 AND discount_percent <= 100),
    discount_amount DECIMAL(12,2) DEFAULT 0 CHECK (discount_amount >= 0),
    subtotal DECIMAL(12,2) NOT NULL CHECK (subtotal >= 0),
    CONSTRAINT valid_subtotal CHECK (subtotal = (unit_price * quantity) - discount_amount)
);


-- File: 005_order_delivery_tables.sql
-- ============================================================
-- Migration 005: Order and Delivery Tables
-- ============================================================
-- Purpose: Create orders, order items, riders, deliveries, and staff attendance tables

-- Orders
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
    _sync_version BIGINT DEFAULT 1,
    _sync_modified_at TIMESTAMPTZ DEFAULT NOW(),
    _sync_client_id UUID,
    CONSTRAINT valid_total CHECK (total_amount = subtotal + delivery_fee + tax_amount),
    CONSTRAINT delivery_address_required CHECK (
        (fulfillment_type = 'pickup' AND delivery_address_id IS NULL) OR
        (fulfillment_type = 'delivery' AND delivery_address_id IS NOT NULL)
    )
);

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

-- Riders
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

-- Deliveries
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

-- Staff Attendance
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


-- File: 006_additional_tables.sql
-- ============================================================
-- Migration 006: Additional Tables
-- ============================================================
-- Purpose: Create ecommerce, chat, commission, whatsapp, and receipt tables

-- E-Commerce Connections
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

-- Chat Conversations
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

CREATE TABLE chat_messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    conversation_id UUID NOT NULL REFERENCES chat_conversations(id) ON DELETE CASCADE,
    sender_type sender_type NOT NULL,
    sender_id UUID REFERENCES users(id),
    message_text TEXT NOT NULL,
    intent VARCHAR(100),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Commissions
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

-- WhatsApp Messages
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

-- Receipts
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


-- File: 007_indexes.sql
-- ============================================================
-- Migration 007: Indexes
-- ============================================================
-- Purpose: Create performance indexes for all tables

-- Tenants
CREATE INDEX idx_tenants_slug ON tenants(slug);
CREATE INDEX idx_tenants_email ON tenants(email) WHERE email IS NOT NULL;
CREATE INDEX idx_tenants_deleted ON tenants(deleted_at) WHERE deleted_at IS NULL;

-- Branches
CREATE INDEX idx_branches_tenant ON branches(tenant_id, deleted_at) WHERE deleted_at IS NULL;
CREATE INDEX idx_branches_location ON branches USING GIST(geography(ST_MakePoint(longitude, latitude)))
    WHERE latitude IS NOT NULL AND longitude IS NOT NULL;

-- Users
CREATE INDEX idx_users_tenant ON users(tenant_id, deleted_at) WHERE deleted_at IS NULL;
CREATE INDEX idx_users_branch ON users(branch_id, deleted_at) WHERE deleted_at IS NULL;
CREATE UNIQUE INDEX idx_users_email ON users(email) WHERE email IS NOT NULL AND deleted_at IS NULL;
CREATE UNIQUE INDEX idx_users_phone ON users(phone) WHERE phone IS NOT NULL AND deleted_at IS NULL;

-- Products
CREATE INDEX idx_products_tenant_branch ON products(tenant_id, branch_id, deleted_at) WHERE deleted_at IS NULL;
CREATE INDEX idx_products_sku ON products(tenant_id, sku) WHERE sku IS NOT NULL AND deleted_at IS NULL;
CREATE INDEX idx_products_barcode ON products(tenant_id, barcode) WHERE barcode IS NOT NULL AND deleted_at IS NULL;
CREATE INDEX idx_products_expiry ON products(expiry_date) WHERE expiry_date IS NOT NULL AND deleted_at IS NULL;
CREATE INDEX idx_products_low_stock ON products(branch_id)
    WHERE stock_quantity <= low_stock_threshold AND deleted_at IS NULL;
CREATE INDEX idx_products_name_search ON products USING gin(to_tsvector('english', name));

-- Inventory Transactions
CREATE INDEX idx_inventory_txn_branch_product ON inventory_transactions(branch_id, product_id, created_at DESC);
CREATE INDEX idx_inventory_txn_reference ON inventory_transactions(reference_type, reference_id);
CREATE INDEX idx_inventory_txn_type ON inventory_transactions(transaction_type, created_at DESC);

-- Transfers
CREATE INDEX idx_transfers_tenant ON inter_branch_transfers(tenant_id, created_at DESC);
CREATE INDEX idx_transfers_source ON inter_branch_transfers(source_branch_id, status);
CREATE INDEX idx_transfers_destination ON inter_branch_transfers(destination_branch_id, status);

-- Customers
CREATE UNIQUE INDEX idx_customers_tenant_phone ON customers(tenant_id, phone) WHERE deleted_at IS NULL;
CREATE INDEX idx_customers_email ON customers(email) WHERE email IS NOT NULL AND deleted_at IS NULL;
CREATE INDEX idx_customers_loyalty ON customers(tenant_id, loyalty_points DESC);

-- Sales
CREATE INDEX idx_sales_tenant_branch ON sales(tenant_id, branch_id, created_at DESC);
CREATE INDEX idx_sales_cashier ON sales(cashier_id, created_at DESC);
CREATE INDEX idx_sales_customer ON sales(customer_id, created_at DESC) WHERE customer_id IS NOT NULL;
CREATE INDEX idx_sales_status ON sales(status, created_at DESC);
CREATE INDEX idx_sales_sync ON sales(is_synced) WHERE is_synced = FALSE;
CREATE UNIQUE INDEX idx_sales_number ON sales(tenant_id, sale_number);

-- Orders
CREATE INDEX idx_orders_tenant_branch ON orders(tenant_id, branch_id, created_at DESC);
CREATE INDEX idx_orders_customer ON orders(customer_id, created_at DESC);
CREATE INDEX idx_orders_status ON orders(order_status, created_at DESC);
CREATE UNIQUE INDEX idx_orders_number ON orders(tenant_id, order_number);
CREATE INDEX idx_orders_ecommerce ON orders(ecommerce_platform, ecommerce_order_id)
    WHERE ecommerce_platform IS NOT NULL;

-- Deliveries
CREATE UNIQUE INDEX idx_deliveries_tracking ON deliveries(tracking_number);
CREATE INDEX idx_deliveries_tenant_branch ON deliveries(tenant_id, branch_id, delivery_status);
CREATE INDEX idx_deliveries_rider ON deliveries(rider_id, delivery_status) WHERE rider_id IS NOT NULL;
CREATE INDEX idx_deliveries_status ON deliveries(delivery_status, created_at DESC);

-- Staff Attendance
CREATE INDEX idx_attendance_staff ON staff_attendance(staff_id, shift_date DESC);
CREATE INDEX idx_attendance_branch ON staff_attendance(branch_id, shift_date DESC);
CREATE INDEX idx_attendance_open ON staff_attendance(staff_id) WHERE clock_out_at IS NULL;

-- Chat
CREATE INDEX idx_chat_tenant_branch ON chat_conversations(tenant_id, branch_id, started_at DESC);
CREATE INDEX idx_chat_customer ON chat_conversations(customer_id, started_at DESC);
CREATE INDEX idx_chat_status ON chat_conversations(status) WHERE status = 'active';

-- Commissions
CREATE INDEX idx_commissions_tenant ON commissions(tenant_id, settlement_status);
CREATE INDEX idx_commissions_settlement ON commissions(settlement_status, created_at DESC);

-- WhatsApp
CREATE INDEX idx_whatsapp_tenant_customer ON whatsapp_messages(tenant_id, customer_id, created_at DESC);
CREATE INDEX idx_whatsapp_order ON whatsapp_messages(order_id) WHERE order_id IS NOT NULL;
CREATE INDEX idx_whatsapp_delivery ON whatsapp_messages(delivery_status, created_at DESC);


-- File: 008_rls_policies.sql
-- ============================================================
-- Migration 008: Row Level Security Policies
-- ============================================================
-- Purpose: Enable RLS and create helper functions and policies

-- Enable RLS on all tenant-scoped tables
ALTER TABLE tenants ENABLE ROW LEVEL SECURITY;
ALTER TABLE branches ENABLE ROW LEVEL SECURITY;
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE inventory_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE inter_branch_transfers ENABLE ROW LEVEL SECURITY;
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE sales ENABLE ROW LEVEL SECURITY;
ALTER TABLE sale_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE deliveries ENABLE ROW LEVEL SECURITY;
ALTER TABLE riders ENABLE ROW LEVEL SECURITY;
ALTER TABLE staff_attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE ecommerce_connections ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE whatsapp_messages ENABLE ROW LEVEL SECURITY;

-- Helper functions for RLS policies
CREATE OR REPLACE FUNCTION current_tenant_id() RETURNS UUID AS $$
    SELECT tenant_id FROM users WHERE id = auth.uid();
$$ LANGUAGE SQL SECURITY DEFINER;

CREATE OR REPLACE FUNCTION current_user_role() RETURNS user_role AS $$
    SELECT role FROM users WHERE id = auth.uid();
$$ LANGUAGE SQL SECURITY DEFINER;

CREATE OR REPLACE FUNCTION current_user_branch_id() RETURNS UUID AS $$
    SELECT branch_id FROM users WHERE id = auth.uid();
$$ LANGUAGE SQL SECURITY DEFINER;

-- Tenants: Users see only their tenant
CREATE POLICY "Users can view own tenant" ON tenants
    FOR SELECT USING (id = current_tenant_id());

CREATE POLICY "Users can update own tenant" ON tenants
    FOR UPDATE USING (id = current_tenant_id() AND current_user_role() = 'tenant_admin');

-- Branches: Tenant isolation
CREATE POLICY "Tenant branch isolation" ON branches
    FOR ALL USING (tenant_id = current_tenant_id());

-- Products: Branch-level access control
CREATE POLICY "Product tenant isolation" ON products
    FOR ALL USING (tenant_id = current_tenant_id());

CREATE POLICY "Product branch access" ON products
    FOR SELECT USING (
        current_user_role() = 'tenant_admin' OR
        branch_id = current_user_branch_id()
    );

-- Sales: Branch-level access
CREATE POLICY "Sale tenant isolation" ON sales
    FOR ALL USING (tenant_id = current_tenant_id());

CREATE POLICY "Sale branch access" ON sales
    FOR SELECT USING (
        current_user_role() = 'tenant_admin' OR
        branch_id = current_user_branch_id()
    );

-- Customers: Tenant-wide (shared across branches)
CREATE POLICY "Customer tenant isolation" ON customers
    FOR ALL USING (tenant_id = current_tenant_id());

-- Orders: Branch-level access
CREATE POLICY "Order tenant isolation" ON orders
    FOR ALL USING (tenant_id = current_tenant_id());

CREATE POLICY "Order branch access" ON orders
    FOR SELECT USING (
        current_user_role() = 'tenant_admin' OR
        branch_id = current_user_branch_id()
    );

-- Deliveries: Branch and rider access
CREATE POLICY "Delivery tenant isolation" ON deliveries
    FOR ALL USING (tenant_id = current_tenant_id());

CREATE POLICY "Delivery rider access" ON deliveries
    FOR SELECT USING (
        current_user_role() IN ('tenant_admin', 'branch_manager') OR
        rider_id IN (SELECT id FROM riders WHERE user_id = auth.uid())
    );


-- File: 009_triggers.sql
-- ============================================================
-- Migration 009: Triggers
-- ============================================================
-- Purpose: Create triggers for automated updates and business logic

-- Update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_updated_at BEFORE UPDATE ON tenants
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER set_updated_at BEFORE UPDATE ON branches
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER set_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER set_updated_at BEFORE UPDATE ON products
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER set_updated_at BEFORE UPDATE ON customers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER set_updated_at BEFORE UPDATE ON sales
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Sync version increment on update (for CRDT)
CREATE OR REPLACE FUNCTION increment_sync_version()
RETURNS TRIGGER AS $$
BEGIN
    NEW._sync_version = OLD._sync_version + 1;
    NEW._sync_modified_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER increment_sync_version BEFORE UPDATE ON products
    FOR EACH ROW EXECUTE FUNCTION increment_sync_version();
CREATE TRIGGER increment_sync_version BEFORE UPDATE ON sales
    FOR EACH ROW EXECUTE FUNCTION increment_sync_version();
CREATE TRIGGER increment_sync_version BEFORE UPDATE ON customers
    FOR EACH ROW EXECUTE FUNCTION increment_sync_version();

-- Auto-generate sale_number
CREATE OR REPLACE FUNCTION generate_sale_number()
RETURNS TRIGGER AS $$
DECLARE
    branch_code VARCHAR(10);
    sequence_num INTEGER;
BEGIN
    SELECT LEFT(name, 3) INTO branch_code FROM branches WHERE id = NEW.branch_id;
    SELECT COUNT(*) + 1 INTO sequence_num
        FROM sales
        WHERE branch_id = NEW.branch_id AND DATE(created_at) = CURRENT_DATE;

    NEW.sale_number = UPPER(branch_code) || '-' || TO_CHAR(CURRENT_DATE, 'YYYYMMDD') || '-' || LPAD(sequence_num::TEXT, 4, '0');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER generate_sale_number BEFORE INSERT ON sales
    FOR EACH ROW WHEN (NEW.sale_number IS NULL)
    EXECUTE FUNCTION generate_sale_number();

-- Auto-create commission on order completion
CREATE OR REPLACE FUNCTION create_commission_on_order_complete()
RETURNS TRIGGER AS $$
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

CREATE TRIGGER create_commission AFTER UPDATE ON orders
    FOR EACH ROW WHEN (OLD.order_status != 'completed' AND NEW.order_status = 'completed')
    EXECUTE FUNCTION create_commission_on_order_complete();

-- Update customer loyalty points on sale
CREATE OR REPLACE FUNCTION update_customer_loyalty()
RETURNS TRIGGER AS $$
DECLARE
    points_earned INTEGER;
BEGIN
    IF NEW.customer_id IS NOT NULL AND NEW.status = 'completed' THEN
        -- 1 point per â‚¦100 spent
        points_earned = FLOOR(NEW.total_amount / 100);

        UPDATE customers
        SET
            loyalty_points = loyalty_points + points_earned,
            total_purchases = total_purchases + NEW.total_amount,
            purchase_count = purchase_count + 1,
            last_purchase_at = NEW.created_at
        WHERE id = NEW.customer_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_customer_loyalty AFTER INSERT ON sales
    FOR EACH ROW EXECUTE FUNCTION update_customer_loyalty();


-- File: 010_analytics_schema.sql
-- ============================================
-- Migration: Analytics Schema for Sales Reports
-- Description: Comprehensive analytics tables for in-depth sales analysis
-- Created: 2026-01-22
-- ============================================

-- ============================================
-- 1. BRANDS TABLE (Product Brands)
-- ============================================

CREATE TABLE IF NOT EXISTS brands (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,

    name VARCHAR(255) NOT NULL,
    code VARCHAR(50),
    description TEXT,
    logo_url TEXT,

    -- Brand classification
    tier VARCHAR(20), -- premium, mid-range, budget
    is_house_brand BOOLEAN DEFAULT false,

    -- Metadata
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(tenant_id, name)
);

-- RLS for brands
ALTER TABLE brands ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view brands in their tenant"
    ON brands FOR SELECT
    USING (tenant_id IN (SELECT tenant_id FROM users WHERE id = auth.uid()));

CREATE POLICY "Managers can insert brands"
    ON brands FOR INSERT
    WITH CHECK (
        tenant_id IN (
            SELECT tenant_id FROM users
            WHERE id = auth.uid()
            AND role IN ('owner', 'admin', 'manager')
        )
    );

CREATE POLICY "Managers can update brands"
    ON brands FOR UPDATE
    USING (
        tenant_id IN (
            SELECT tenant_id FROM users
            WHERE id = auth.uid()
            AND role IN ('owner', 'admin', 'manager')
        )
    );

-- ============================================
-- 2. CATEGORIES TABLE (Hierarchical)
-- ============================================

CREATE TABLE IF NOT EXISTS categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,

    name VARCHAR(255) NOT NULL,
    code VARCHAR(50),
    parent_category_id UUID REFERENCES categories(id) ON DELETE SET NULL,

    -- Category hierarchy
    level INTEGER DEFAULT 1, -- 1=main, 2=sub, 3=sub-sub
    path TEXT, -- Materialized path: /Electronics/Phones/Smartphones/

    description TEXT,
    sort_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(tenant_id, name, parent_category_id)
);

-- RLS for categories
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view categories in their tenant"
    ON categories FOR SELECT
    USING (tenant_id IN (SELECT tenant_id FROM users WHERE id = auth.uid()));

CREATE POLICY "Managers can manage categories"
    ON categories FOR ALL
    USING (
        tenant_id IN (
            SELECT tenant_id FROM users
            WHERE id = auth.uid()
            AND role IN ('owner', 'admin', 'manager')
        )
    );

-- ============================================
-- 3. ENHANCE PRODUCTS TABLE
-- ============================================

-- Add brand_id and category_id to products if not exists
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'products' AND column_name = 'brand_id') THEN
        ALTER TABLE products ADD COLUMN brand_id UUID REFERENCES brands(id) ON DELETE SET NULL;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'products' AND column_name = 'category_id') THEN
        ALTER TABLE products ADD COLUMN category_id UUID REFERENCES categories(id) ON DELETE SET NULL;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'products' AND column_name = 'cost_price') THEN
        ALTER TABLE products ADD COLUMN cost_price DECIMAL(15,2);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'products' AND column_name = 'unit_of_measure') THEN
        ALTER TABLE products ADD COLUMN unit_of_measure VARCHAR(20) DEFAULT 'piece';
    END IF;
END $$;

-- ============================================
-- 4. PRODUCT PRICE HISTORY (SCD Type 2)
-- ============================================

CREATE TABLE IF NOT EXISTS product_price_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,

    cost_price DECIMAL(15,2),
    selling_price DECIMAL(15,2) NOT NULL,

    -- Price change tracking
    price_change_reason VARCHAR(100),
    changed_by UUID REFERENCES users(id),

    -- Validity period (SCD Type 2)
    valid_from TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    valid_to TIMESTAMPTZ,
    is_current BOOLEAN DEFAULT true,

    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS for price history
ALTER TABLE product_price_history ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view price history in their tenant"
    ON product_price_history FOR SELECT
    USING (tenant_id IN (SELECT tenant_id FROM users WHERE id = auth.uid()));

-- ============================================
-- 5. ENHANCE SALES TABLE
-- ============================================

-- Add analytics-friendly columns to sales table
DO $$
BEGIN
    -- Add sales attendant tracking (separate from cashier)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'sales' AND column_name = 'sales_attendant_id') THEN
        ALTER TABLE sales ADD COLUMN sales_attendant_id UUID REFERENCES users(id);
    END IF;

    -- Add customer type for segmentation
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'sales' AND column_name = 'customer_type') THEN
        ALTER TABLE sales ADD COLUMN customer_type VARCHAR(20) DEFAULT 'walk-in';
    END IF;

    -- Add channel tracking
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'sales' AND column_name = 'channel') THEN
        ALTER TABLE sales ADD COLUMN channel VARCHAR(20) DEFAULT 'in-store';
    END IF;

    -- Add sale_date for easy queries (denormalized from completed_at)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'sales' AND column_name = 'sale_date') THEN
        ALTER TABLE sales ADD COLUMN sale_date DATE;
        -- Populate existing records
        UPDATE sales SET sale_date = DATE(completed_at) WHERE sale_date IS NULL;
        ALTER TABLE sales ALTER COLUMN sale_date SET NOT NULL;
    END IF;

    -- Add sale_time for hourly analysis
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'sales' AND column_name = 'sale_time') THEN
        ALTER TABLE sales ADD COLUMN sale_time TIME;
        -- Populate existing records
        UPDATE sales SET sale_time = completed_at::TIME WHERE sale_time IS NULL;
        ALTER TABLE sales ALTER COLUMN sale_time SET NOT NULL;
    END IF;

    -- Add void tracking
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'sales' AND column_name = 'void_reason') THEN
        ALTER TABLE sales ADD COLUMN void_reason TEXT;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'sales' AND column_name = 'voided_by') THEN
        ALTER TABLE sales ADD COLUMN voided_by UUID REFERENCES users(id);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'sales' AND column_name = 'voided_at') THEN
        ALTER TABLE sales ADD COLUMN voided_at TIMESTAMPTZ;
    END IF;
END $$;

-- ============================================
-- 6. ENHANCE SALE ITEMS TABLE
-- ============================================

-- Add analytics columns to sale_items
DO $$
BEGIN
    -- Product snapshot fields
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'sale_items' AND column_name = 'product_name') THEN
        ALTER TABLE sale_items ADD COLUMN product_name VARCHAR(255);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'sale_items' AND column_name = 'product_sku') THEN
        ALTER TABLE sale_items ADD COLUMN product_sku VARCHAR(100);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'sale_items' AND column_name = 'brand_id') THEN
        ALTER TABLE sale_items ADD COLUMN brand_id UUID REFERENCES brands(id);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'sale_items' AND column_name = 'brand_name') THEN
        ALTER TABLE sale_items ADD COLUMN brand_name VARCHAR(255);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'sale_items' AND column_name = 'category_id') THEN
        ALTER TABLE sale_items ADD COLUMN category_id UUID REFERENCES categories(id);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'sale_items' AND column_name = 'category_name') THEN
        ALTER TABLE sale_items ADD COLUMN category_name VARCHAR(255);
    END IF;

    -- Unit of measure
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'sale_items' AND column_name = 'unit_of_measure') THEN
        ALTER TABLE sale_items ADD COLUMN unit_of_measure VARCHAR(20) DEFAULT 'piece';
    END IF;

    -- Pricing details
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'sale_items' AND column_name = 'original_price') THEN
        ALTER TABLE sale_items ADD COLUMN original_price DECIMAL(15,2);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'sale_items' AND column_name = 'discount_percentage') THEN
        ALTER TABLE sale_items ADD COLUMN discount_percentage DECIMAL(5,2) DEFAULT 0;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'sale_items' AND column_name = 'discount_amount') THEN
        ALTER TABLE sale_items ADD COLUMN discount_amount DECIMAL(15,2) DEFAULT 0;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'sale_items' AND column_name = 'tax_percentage') THEN
        ALTER TABLE sale_items ADD COLUMN tax_percentage DECIMAL(5,2) DEFAULT 0;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'sale_items' AND column_name = 'tax_amount') THEN
        ALTER TABLE sale_items ADD COLUMN tax_amount DECIMAL(15,2) DEFAULT 0;
    END IF;

    -- Cost and profit tracking
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'sale_items' AND column_name = 'unit_cost') THEN
        ALTER TABLE sale_items ADD COLUMN unit_cost DECIMAL(15,2);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'sale_items' AND column_name = 'total_cost') THEN
        ALTER TABLE sale_items ADD COLUMN total_cost DECIMAL(15,2);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'sale_items' AND column_name = 'gross_profit') THEN
        ALTER TABLE sale_items ADD COLUMN gross_profit DECIMAL(15,2);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'sale_items' AND column_name = 'profit_margin') THEN
        ALTER TABLE sale_items ADD COLUMN profit_margin DECIMAL(5,2);
    END IF;

    -- Discount tracking
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'sale_items' AND column_name = 'discount_type') THEN
        ALTER TABLE sale_items ADD COLUMN discount_type VARCHAR(50);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'sale_items' AND column_name = 'discount_code') THEN
        ALTER TABLE sale_items ADD COLUMN discount_code VARCHAR(50);
    END IF;
END $$;

-- ============================================
-- 7. TIME DIMENSIONS
-- ============================================

-- Date dimension table
CREATE TABLE IF NOT EXISTS dim_date (
    date_key INTEGER PRIMARY KEY,
    date_value DATE NOT NULL UNIQUE,

    -- Date components
    day INTEGER NOT NULL,
    day_of_week INTEGER NOT NULL,
    day_of_week_name VARCHAR(10) NOT NULL,
    day_of_year INTEGER NOT NULL,

    -- Week
    week_of_year INTEGER NOT NULL,
    week_start_date DATE NOT NULL,
    week_end_date DATE NOT NULL,

    -- Month
    month INTEGER NOT NULL,
    month_name VARCHAR(10) NOT NULL,
    month_abbr VARCHAR(3) NOT NULL,
    month_start_date DATE NOT NULL,
    month_end_date DATE NOT NULL,

    -- Quarter
    quarter INTEGER NOT NULL,
    quarter_name VARCHAR(10) NOT NULL,
    quarter_start_date DATE NOT NULL,
    quarter_end_date DATE NOT NULL,

    -- Year
    year INTEGER NOT NULL,
    year_start_date DATE NOT NULL,
    year_end_date DATE NOT NULL,

    -- Fiscal periods
    fiscal_year INTEGER,
    fiscal_quarter INTEGER,
    fiscal_month INTEGER,

    -- Business flags
    is_weekend BOOLEAN NOT NULL,
    is_holiday BOOLEAN DEFAULT false,
    holiday_name VARCHAR(100),
    is_business_day BOOLEAN NOT NULL,

    -- Prior period references
    prior_day_key INTEGER,
    prior_week_key INTEGER,
    prior_month_key INTEGER,
    prior_quarter_key INTEGER,
    prior_year_key INTEGER,

    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Time dimension table
CREATE TABLE IF NOT EXISTS dim_time (
    time_key INTEGER PRIMARY KEY,
    time_value TIME NOT NULL UNIQUE,

    -- Time components
    hour INTEGER NOT NULL,
    hour_12 INTEGER NOT NULL,
    am_pm VARCHAR(2) NOT NULL,
    minute INTEGER NOT NULL,
    second INTEGER NOT NULL,

    -- Time periods
    time_period VARCHAR(20) NOT NULL,
    business_hour VARCHAR(20) NOT NULL,

    -- Analytics groupings
    hour_bucket INTEGER NOT NULL,
    minute_bucket INTEGER NOT NULL,

    is_peak_hour BOOLEAN DEFAULT false,

    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 8. FACT TABLES (Partitioned)
-- ============================================

-- Daily sales summary
CREATE TABLE IF NOT EXISTS fact_daily_sales (
    id UUID DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE CASCADE,

    -- Date dimension
    date_key INTEGER NOT NULL REFERENCES dim_date(date_key),
    sale_date DATE NOT NULL,

    -- Aggregated metrics
    total_transactions INTEGER DEFAULT 0,
    total_items_sold DECIMAL(15,3) DEFAULT 0,
    total_revenue DECIMAL(15,2) DEFAULT 0,
    total_cost DECIMAL(15,2) DEFAULT 0,
    total_profit DECIMAL(15,2) DEFAULT 0,
    average_transaction_value DECIMAL(15,2) DEFAULT 0,
    average_profit_margin DECIMAL(5,2) DEFAULT 0,

    -- Customer metrics
    unique_customers INTEGER DEFAULT 0,
    new_customers INTEGER DEFAULT 0,
    returning_customers INTEGER DEFAULT 0,

    -- Payment method breakdown
    cash_transactions INTEGER DEFAULT 0,
    cash_revenue DECIMAL(15,2) DEFAULT 0,
    card_transactions INTEGER DEFAULT 0,
    card_revenue DECIMAL(15,2) DEFAULT 0,
    transfer_transactions INTEGER DEFAULT 0,
    transfer_revenue DECIMAL(15,2) DEFAULT 0,

    -- Refund metrics
    void_transactions INTEGER DEFAULT 0,
    void_amount DECIMAL(15,2) DEFAULT 0,
    refund_transactions INTEGER DEFAULT 0,
    refund_amount DECIMAL(15,2) DEFAULT 0,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    PRIMARY KEY (tenant_id, branch_id, date_key, sale_date)
) PARTITION BY RANGE (sale_date);

-- Product sales summary
CREATE TABLE IF NOT EXISTS fact_product_sales (
    id UUID DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE CASCADE,

    -- Dimensions
    date_key INTEGER NOT NULL REFERENCES dim_date(date_key),
    sale_date DATE NOT NULL,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    brand_id UUID REFERENCES brands(id),
    category_id UUID REFERENCES categories(id),

    -- Product snapshot
    product_name VARCHAR(255) NOT NULL,
    product_sku VARCHAR(100),
    brand_name VARCHAR(255),
    category_name VARCHAR(255),

    -- Aggregated metrics
    quantity_sold DECIMAL(15,3) DEFAULT 0,
    total_revenue DECIMAL(15,2) DEFAULT 0,
    total_cost DECIMAL(15,2) DEFAULT 0,
    total_profit DECIMAL(15,2) DEFAULT 0,
    average_unit_price DECIMAL(15,2) DEFAULT 0,
    average_profit_margin DECIMAL(5,2) DEFAULT 0,

    -- Transaction metrics
    transaction_count INTEGER DEFAULT 0,

    -- Discount metrics
    total_discount_amount DECIMAL(15,2) DEFAULT 0,
    average_discount_percentage DECIMAL(5,2) DEFAULT 0,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    PRIMARY KEY (tenant_id, branch_id, date_key, product_id, sale_date)
) PARTITION BY RANGE (sale_date);

-- Staff sales performance
CREATE TABLE IF NOT EXISTS fact_staff_sales (
    id UUID DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE CASCADE,

    -- Dimensions
    date_key INTEGER NOT NULL REFERENCES dim_date(date_key),
    sale_date DATE NOT NULL,
    staff_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    staff_role VARCHAR(50),

    -- Staff info snapshot
    staff_name VARCHAR(255) NOT NULL,

    -- Aggregated metrics
    total_transactions INTEGER DEFAULT 0,
    total_items_sold DECIMAL(15,3) DEFAULT 0,
    total_revenue DECIMAL(15,2) DEFAULT 0,
    total_profit DECIMAL(15,2) DEFAULT 0,
    average_transaction_value DECIMAL(15,2) DEFAULT 0,

    -- Performance metrics
    average_transaction_time INTERVAL,
    transactions_per_hour DECIMAL(5,2) DEFAULT 0,

    -- Commission calculation
    commission_eligible_sales DECIMAL(15,2) DEFAULT 0,
    commission_amount DECIMAL(15,2) DEFAULT 0,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    PRIMARY KEY (tenant_id, branch_id, date_key, staff_id, staff_role, sale_date)
) PARTITION BY RANGE (sale_date);

-- Brand performance comparison
CREATE TABLE IF NOT EXISTS fact_brand_sales (
    id UUID DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE CASCADE,

    -- Dimensions
    date_key INTEGER NOT NULL REFERENCES dim_date(date_key),
    sale_date DATE NOT NULL,
    brand_id UUID NOT NULL REFERENCES brands(id) ON DELETE CASCADE,
    category_id UUID REFERENCES categories(id),

    -- Brand snapshot
    brand_name VARCHAR(255) NOT NULL,
    category_name VARCHAR(255),

    -- Aggregated metrics
    unique_products_sold INTEGER DEFAULT 0,
    quantity_sold DECIMAL(15,3) DEFAULT 0,
    total_revenue DECIMAL(15,2) DEFAULT 0,
    total_cost DECIMAL(15,2) DEFAULT 0,
    total_profit DECIMAL(15,2) DEFAULT 0,
    average_profit_margin DECIMAL(5,2) DEFAULT 0,

    -- Transaction metrics
    transaction_count INTEGER DEFAULT 0,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    PRIMARY KEY (tenant_id, branch_id, date_key, brand_id, sale_date)
) PARTITION BY RANGE (sale_date);

-- Hourly sales pattern
CREATE TABLE IF NOT EXISTS fact_hourly_sales (
    id UUID DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE CASCADE,

    -- Dimensions
    date_key INTEGER NOT NULL REFERENCES dim_date(date_key),
    time_key INTEGER NOT NULL REFERENCES dim_time(time_key),
    sale_date DATE NOT NULL,
    hour INTEGER NOT NULL,

    -- Aggregated metrics
    total_transactions INTEGER DEFAULT 0,
    total_revenue DECIMAL(15,2) DEFAULT 0,
    average_transaction_value DECIMAL(15,2) DEFAULT 0,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    PRIMARY KEY (tenant_id, branch_id, date_key, time_key, sale_date)
) PARTITION BY RANGE (sale_date);

-- RLS for fact tables
ALTER TABLE fact_daily_sales ENABLE ROW LEVEL SECURITY;
ALTER TABLE fact_product_sales ENABLE ROW LEVEL SECURITY;
ALTER TABLE fact_staff_sales ENABLE ROW LEVEL SECURITY;
ALTER TABLE fact_brand_sales ENABLE ROW LEVEL SECURITY;
ALTER TABLE fact_hourly_sales ENABLE ROW LEVEL SECURITY;

-- RLS Policies for fact tables
CREATE POLICY "Users can view daily sales in their tenant"
    ON fact_daily_sales FOR SELECT
    USING (tenant_id IN (SELECT tenant_id FROM users WHERE id = auth.uid()));

CREATE POLICY "Users can view product sales in their tenant"
    ON fact_product_sales FOR SELECT
    USING (tenant_id IN (SELECT tenant_id FROM users WHERE id = auth.uid()));

CREATE POLICY "Users can view staff sales in their tenant"
    ON fact_staff_sales FOR SELECT
    USING (tenant_id IN (SELECT tenant_id FROM users WHERE id = auth.uid()));

CREATE POLICY "Users can view brand sales in their tenant"
    ON fact_brand_sales FOR SELECT
    USING (tenant_id IN (SELECT tenant_id FROM users WHERE id = auth.uid()));

CREATE POLICY "Users can view hourly sales in their tenant"
    ON fact_hourly_sales FOR SELECT
    USING (tenant_id IN (SELECT tenant_id FROM users WHERE id = auth.uid()));

-- ============================================
-- 9. COMMENTS FOR DOCUMENTATION
-- ============================================

COMMENT ON TABLE brands IS 'Product brands for brand comparison analysis';
COMMENT ON TABLE categories IS 'Hierarchical product categories';
COMMENT ON TABLE product_price_history IS 'Tracks product price changes over time (SCD Type 2)';
COMMENT ON TABLE dim_date IS 'Calendar dimension for time-based analysis';
COMMENT ON TABLE dim_time IS 'Time dimension for hourly pattern analysis';
COMMENT ON TABLE fact_daily_sales IS 'Daily aggregated sales metrics by branch';
COMMENT ON TABLE fact_product_sales IS 'Daily product-level sales metrics';
COMMENT ON TABLE fact_staff_sales IS 'Daily staff performance metrics';
COMMENT ON TABLE fact_brand_sales IS 'Daily brand performance metrics';
COMMENT ON TABLE fact_hourly_sales IS 'Hourly sales patterns';


-- File: 011_analytics_indexes_partitions.sql
-- ============================================
-- Migration: Analytics Indexes and Partitions
-- Description: Create indexes for performance and initial partitions
-- Created: 2026-01-22
-- ============================================

-- ============================================
-- 1. INDEXES FOR TRANSACTIONAL QUERIES
-- ============================================

-- Sales table indexes
CREATE INDEX IF NOT EXISTS idx_sales_tenant_date ON sales(tenant_id, sale_date DESC);
CREATE INDEX IF NOT EXISTS idx_sales_branch_date ON sales(branch_id, sale_date DESC);
CREATE INDEX IF NOT EXISTS idx_sales_customer ON sales(customer_id, completed_at DESC) WHERE customer_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_sales_cashier ON sales(cashier_id, sale_date DESC);
CREATE INDEX IF NOT EXISTS idx_sales_attendant ON sales(sales_attendant_id, sale_date DESC) WHERE sales_attendant_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_sales_status ON sales(sale_status, tenant_id);
CREATE INDEX IF NOT EXISTS idx_sales_completed ON sales(completed_at DESC);
CREATE INDEX IF NOT EXISTS idx_sales_payment_method ON sales(payment_method, tenant_id);
CREATE INDEX IF NOT EXISTS idx_sales_channel ON sales(channel, tenant_id);

-- Sale items indexes
CREATE INDEX IF NOT EXISTS idx_sale_items_sale ON sale_items(sale_id);
CREATE INDEX IF NOT EXISTS idx_sale_items_product ON sale_items(product_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_sale_items_brand ON sale_items(brand_id, created_at DESC) WHERE brand_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_sale_items_category ON sale_items(category_id, created_at DESC) WHERE category_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_sale_items_tenant ON sale_items(tenant_id, created_at DESC);

-- Product indexes
CREATE INDEX IF NOT EXISTS idx_products_tenant ON products(tenant_id) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_products_brand ON products(brand_id) WHERE brand_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_products_category ON products(category_id) WHERE category_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_products_sku ON products(tenant_id, sku);
CREATE INDEX IF NOT EXISTS idx_products_barcode ON products(barcode) WHERE barcode IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_products_active ON products(is_active, tenant_id);

-- Brand indexes
CREATE INDEX IF NOT EXISTS idx_brands_tenant ON brands(tenant_id);
CREATE INDEX IF NOT EXISTS idx_brands_active ON brands(is_active, tenant_id);
CREATE INDEX IF NOT EXISTS idx_brands_name ON brands(tenant_id, name);

-- Category indexes
CREATE INDEX IF NOT EXISTS idx_categories_tenant ON categories(tenant_id);
CREATE INDEX IF NOT EXISTS idx_categories_parent ON categories(parent_category_id) WHERE parent_category_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_categories_level ON categories(tenant_id, level);
CREATE INDEX IF NOT EXISTS idx_categories_active ON categories(is_active, tenant_id);

-- Product price history indexes
CREATE INDEX IF NOT EXISTS idx_price_history_product ON product_price_history(product_id, valid_from DESC);
CREATE INDEX IF NOT EXISTS idx_price_history_current ON product_price_history(product_id, is_current) WHERE is_current = true;
CREATE INDEX IF NOT EXISTS idx_price_history_tenant ON product_price_history(tenant_id, created_at DESC);

-- ============================================
-- 2. INDEXES FOR ANALYTICS QUERIES
-- ============================================

-- Date dimension indexes
CREATE INDEX IF NOT EXISTS idx_dim_date_value ON dim_date(date_value);
CREATE INDEX IF NOT EXISTS idx_dim_date_month ON dim_date(year, month);
CREATE INDEX IF NOT EXISTS idx_dim_date_quarter ON dim_date(year, quarter);
CREATE INDEX IF NOT EXISTS idx_dim_date_year ON dim_date(year);
CREATE INDEX IF NOT EXISTS idx_dim_date_day_of_week ON dim_date(day_of_week);
CREATE INDEX IF NOT EXISTS idx_dim_date_is_business_day ON dim_date(is_business_day);
CREATE INDEX IF NOT EXISTS idx_dim_date_is_weekend ON dim_date(is_weekend);

-- Time dimension indexes
CREATE INDEX IF NOT EXISTS idx_dim_time_hour ON dim_time(hour);
CREATE INDEX IF NOT EXISTS idx_dim_time_period ON dim_time(time_period);
CREATE INDEX IF NOT EXISTS idx_dim_time_peak ON dim_time(is_peak_hour) WHERE is_peak_hour = true;

-- ============================================
-- 3. CREATE INITIAL PARTITIONS (2024-2026)
-- ============================================

-- Function to create monthly partitions
CREATE OR REPLACE FUNCTION create_monthly_partition(
    p_table_name TEXT,
    p_year INTEGER,
    p_month INTEGER
)
RETURNS void AS $$
DECLARE
    v_partition_name TEXT;
    v_start_date DATE;
    v_end_date DATE;
BEGIN
    v_partition_name := p_table_name || '_' || p_year || '_' || LPAD(p_month::TEXT, 2, '0');
    v_start_date := DATE(p_year || '-' || p_month || '-01');
    v_end_date := v_start_date + INTERVAL '1 month';

    EXECUTE format(
        'CREATE TABLE IF NOT EXISTS %I PARTITION OF %I FOR VALUES FROM (%L) TO (%L)',
        v_partition_name, p_table_name, v_start_date, v_end_date
    );

    RAISE NOTICE 'Created partition: %', v_partition_name;
END;
$$ LANGUAGE plpgsql;

-- Create partitions for 2024
DO $$
DECLARE
    v_year INTEGER;
    v_month INTEGER;
BEGIN
    -- Create partitions for 2024, 2025, 2026
    FOR v_year IN 2024..2026 LOOP
        FOR v_month IN 1..12 LOOP
            PERFORM create_monthly_partition('fact_daily_sales', v_year, v_month);
            PERFORM create_monthly_partition('fact_product_sales', v_year, v_month);
            PERFORM create_monthly_partition('fact_staff_sales', v_year, v_month);
            PERFORM create_monthly_partition('fact_brand_sales', v_year, v_month);
            PERFORM create_monthly_partition('fact_hourly_sales', v_year, v_month);
        END LOOP;
    END LOOP;
END $$;

-- ============================================
-- 4. PARTITION MANAGEMENT FUNCTIONS
-- ============================================

-- Function to auto-create future partitions
CREATE OR REPLACE FUNCTION create_future_partitions(
    p_months_ahead INTEGER DEFAULT 3
)
RETURNS void AS $$
DECLARE
    v_date DATE;
    v_year INTEGER;
    v_month INTEGER;
BEGIN
    FOR i IN 1..p_months_ahead LOOP
        v_date := DATE_TRUNC('month', CURRENT_DATE) + (i || ' months')::INTERVAL;
        v_year := EXTRACT(YEAR FROM v_date);
        v_month := EXTRACT(MONTH FROM v_date);

        PERFORM create_monthly_partition('fact_daily_sales', v_year, v_month);
        PERFORM create_monthly_partition('fact_product_sales', v_year, v_month);
        PERFORM create_monthly_partition('fact_staff_sales', v_year, v_month);
        PERFORM create_monthly_partition('fact_brand_sales', v_year, v_month);
        PERFORM create_monthly_partition('fact_hourly_sales', v_year, v_month);
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Function to drop old partitions (data retention)
CREATE OR REPLACE FUNCTION drop_old_partitions(
    p_retention_months INTEGER DEFAULT 24
)
RETURNS void AS $$
DECLARE
    v_cutoff_date DATE;
    v_partition_name TEXT;
    v_table_name TEXT;
BEGIN
    v_cutoff_date := DATE_TRUNC('month', CURRENT_DATE) - (p_retention_months || ' months')::INTERVAL;

    FOR v_table_name IN SELECT unnest(ARRAY[
        'fact_daily_sales',
        'fact_product_sales',
        'fact_staff_sales',
        'fact_brand_sales',
        'fact_hourly_sales'
    ]) LOOP
        FOR v_partition_name IN
            SELECT tablename
            FROM pg_tables
            WHERE schemaname = 'public'
            AND tablename LIKE v_table_name || '_%'
            AND tablename < v_table_name || '_' || TO_CHAR(v_cutoff_date, 'YYYY_MM')
        LOOP
            EXECUTE 'DROP TABLE IF EXISTS ' || v_partition_name || ' CASCADE';
            RAISE NOTICE 'Dropped old partition: %', v_partition_name;
        END LOOP;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 5. MATERIALIZED VIEWS FOR COMMON QUERIES
-- ============================================

-- Top selling products (all-time)
CREATE MATERIALIZED VIEW IF NOT EXISTS mv_top_products AS
SELECT
    fps.tenant_id,
    fps.product_id,
    fps.product_name,
    fps.brand_name,
    fps.category_name,
    SUM(fps.quantity_sold) as total_quantity_sold,
    SUM(fps.total_revenue) as total_revenue,
    SUM(fps.total_profit) as total_profit,
    AVG(fps.average_profit_margin) as avg_profit_margin,
    SUM(fps.transaction_count) as total_transactions,
    MAX(fps.sale_date) as last_sale_date
FROM fact_product_sales fps
GROUP BY
    fps.tenant_id,
    fps.product_id,
    fps.product_name,
    fps.brand_name,
    fps.category_name;

CREATE UNIQUE INDEX IF NOT EXISTS idx_mv_top_products ON mv_top_products(tenant_id, product_id);
CREATE INDEX IF NOT EXISTS idx_mv_top_products_revenue ON mv_top_products(tenant_id, total_revenue DESC);

-- Brand comparison (all-time)
CREATE MATERIALIZED VIEW IF NOT EXISTS mv_brand_comparison AS
SELECT
    fbs.tenant_id,
    fbs.brand_id,
    fbs.brand_name,
    SUM(fbs.quantity_sold) as total_quantity_sold,
    SUM(fbs.total_revenue) as total_revenue,
    SUM(fbs.total_profit) as total_profit,
    AVG(fbs.average_profit_margin) as avg_profit_margin,
    SUM(fbs.transaction_count) as total_transactions,
    COUNT(DISTINCT fbs.category_id) as category_count,
    MAX(fbs.sale_date) as last_sale_date
FROM fact_brand_sales fbs
GROUP BY
    fbs.tenant_id,
    fbs.brand_id,
    fbs.brand_name;

CREATE UNIQUE INDEX IF NOT EXISTS idx_mv_brand_comparison ON mv_brand_comparison(tenant_id, brand_id);
CREATE INDEX IF NOT EXISTS idx_mv_brand_revenue ON mv_brand_comparison(tenant_id, total_revenue DESC);

-- Staff performance leaderboard
CREATE MATERIALIZED VIEW IF NOT EXISTS mv_staff_leaderboard AS
SELECT
    fss.tenant_id,
    fss.staff_id,
    fss.staff_name,
    SUM(fss.total_transactions) as total_transactions,
    SUM(fss.total_revenue) as total_revenue,
    SUM(fss.total_profit) as total_profit,
    AVG(fss.average_transaction_value) as avg_transaction_value,
    SUM(fss.commission_amount) as total_commission,
    MAX(fss.sale_date) as last_sale_date
FROM fact_staff_sales fss
GROUP BY
    fss.tenant_id,
    fss.staff_id,
    fss.staff_name;

CREATE UNIQUE INDEX IF NOT EXISTS idx_mv_staff_leaderboard ON mv_staff_leaderboard(tenant_id, staff_id);
CREATE INDEX IF NOT EXISTS idx_mv_staff_revenue ON mv_staff_leaderboard(tenant_id, total_revenue DESC);

-- Category performance
CREATE MATERIALIZED VIEW IF NOT EXISTS mv_category_performance AS
SELECT
    fps.tenant_id,
    fps.category_id,
    fps.category_name,
    COUNT(DISTINCT fps.product_id) as unique_products,
    SUM(fps.quantity_sold) as total_quantity_sold,
    SUM(fps.total_revenue) as total_revenue,
    SUM(fps.total_profit) as total_profit,
    AVG(fps.average_profit_margin) as avg_profit_margin,
    SUM(fps.transaction_count) as total_transactions,
    MAX(fps.sale_date) as last_sale_date
FROM fact_product_sales fps
WHERE fps.category_id IS NOT NULL
GROUP BY
    fps.tenant_id,
    fps.category_id,
    fps.category_name;

CREATE UNIQUE INDEX IF NOT EXISTS idx_mv_category_performance ON mv_category_performance(tenant_id, category_id);
CREATE INDEX IF NOT EXISTS idx_mv_category_revenue ON mv_category_performance(tenant_id, total_revenue DESC);

-- Function to refresh all materialized views
CREATE OR REPLACE FUNCTION refresh_analytics_views()
RETURNS void AS $$
BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY mv_top_products;
    REFRESH MATERIALIZED VIEW CONCURRENTLY mv_brand_comparison;
    REFRESH MATERIALIZED VIEW CONCURRENTLY mv_staff_leaderboard;
    REFRESH MATERIALIZED VIEW CONCURRENTLY mv_category_performance;

    RAISE NOTICE 'All analytics materialized views refreshed at %', NOW();
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 6. PERFORMANCE MONITORING VIEWS
-- ============================================

-- View to monitor fact table sizes
CREATE OR REPLACE VIEW v_fact_table_stats AS
SELECT
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS total_size,
    pg_size_pretty(pg_relation_size(schemaname||'.'||tablename)) AS table_size,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename) - pg_relation_size(schemaname||'.'||tablename)) AS index_size,
    n_tup_ins as rows_inserted,
    n_tup_upd as rows_updated,
    n_tup_del as rows_deleted,
    last_vacuum,
    last_autovacuum,
    last_analyze,
    last_autoanalyze
FROM pg_stat_user_tables
WHERE tablename LIKE 'fact_%'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- View to monitor partition information
CREATE OR REPLACE VIEW v_partition_info AS
SELECT
    nmsp_parent.nspname AS parent_schema,
    parent.relname AS parent_table,
    nmsp_child.nspname AS child_schema,
    child.relname AS child_partition,
    pg_size_pretty(pg_total_relation_size(child.oid)) AS partition_size,
    pg_get_expr(child.relpartbound, child.oid) AS partition_bounds
FROM pg_inherits
JOIN pg_class parent ON pg_inherits.inhparent = parent.oid
JOIN pg_class child ON pg_inherits.inhrelid = child.oid
JOIN pg_namespace nmsp_parent ON nmsp_parent.oid = parent.relnamespace
JOIN pg_namespace nmsp_child ON nmsp_child.oid = child.relnamespace
WHERE parent.relname LIKE 'fact_%'
ORDER BY parent.relname, child.relname;

-- ============================================
-- 7. COMMENTS FOR DOCUMENTATION
-- ============================================

COMMENT ON FUNCTION create_monthly_partition IS 'Creates a monthly partition for a partitioned table';
COMMENT ON FUNCTION create_future_partitions IS 'Automatically creates partitions for future months (run monthly via cron)';
COMMENT ON FUNCTION drop_old_partitions IS 'Drops partitions older than retention period (default 24 months)';
COMMENT ON FUNCTION refresh_analytics_views IS 'Refreshes all analytics materialized views (run daily via cron)';
COMMENT ON VIEW v_fact_table_stats IS 'Monitor fact table sizes and statistics';
COMMENT ON VIEW v_partition_info IS 'View partition information and sizes';


-- File: 012_analytics_etl_functions.sql
-- ============================================
-- Migration: Analytics ETL Functions
-- Description: Functions to aggregate transactional data into analytics tables
-- Created: 2026-01-22
-- ============================================

-- ============================================
-- 1. AGGREGATE DAILY SALES FUNCTION
-- ============================================

CREATE OR REPLACE FUNCTION aggregate_daily_sales(p_date DATE)
RETURNS void AS $$
DECLARE
    v_date_key INTEGER;
    v_rows_affected INTEGER;
BEGIN
    -- Get date key
    SELECT date_key INTO v_date_key
    FROM dim_date
    WHERE date_value = p_date;

    IF v_date_key IS NULL THEN
        RAISE EXCEPTION 'Date % not found in dim_date. Please populate dimension tables first.', p_date;
    END IF;

    -- Aggregate to fact_daily_sales
    INSERT INTO fact_daily_sales (
        tenant_id, branch_id, date_key, sale_date,
        total_transactions, total_items_sold, total_revenue,
        total_cost, total_profit, average_transaction_value,
        average_profit_margin, unique_customers, new_customers,
        cash_transactions, cash_revenue, card_transactions, card_revenue,
        transfer_transactions, transfer_revenue, void_transactions,
        void_amount, refund_transactions, refund_amount
    )
    SELECT
        s.tenant_id,
        s.branch_id,
        v_date_key,
        p_date,
        COUNT(DISTINCT s.id) as total_transactions,
        COALESCE(SUM(si.quantity), 0) as total_items_sold,
        COALESCE(SUM(s.total_amount), 0) as total_revenue,
        COALESCE(SUM(si.total_cost), 0) as total_cost,
        COALESCE(SUM(si.gross_profit), 0) as total_profit,
        COALESCE(AVG(s.total_amount), 0) as average_transaction_value,
        COALESCE(AVG(si.profit_margin), 0) as average_profit_margin,
        COUNT(DISTINCT s.customer_id) FILTER (WHERE s.customer_id IS NOT NULL) as unique_customers,
        COUNT(DISTINCT s.customer_id) FILTER (WHERE s.customer_type = 'new') as new_customers,
        COUNT(*) FILTER (WHERE s.payment_method = 'cash') as cash_transactions,
        COALESCE(SUM(s.total_amount) FILTER (WHERE s.payment_method = 'cash'), 0) as cash_revenue,
        COUNT(*) FILTER (WHERE s.payment_method = 'card') as card_transactions,
        COALESCE(SUM(s.total_amount) FILTER (WHERE s.payment_method = 'card'), 0) as card_revenue,
        COUNT(*) FILTER (WHERE s.payment_method = 'transfer') as transfer_transactions,
        COALESCE(SUM(s.total_amount) FILTER (WHERE s.payment_method = 'transfer'), 0) as transfer_revenue,
        COUNT(*) FILTER (WHERE s.sale_status = 'void') as void_transactions,
        COALESCE(SUM(s.total_amount) FILTER (WHERE s.sale_status = 'void'), 0) as void_amount,
        COUNT(*) FILTER (WHERE s.sale_status = 'refunded') as refund_transactions,
        COALESCE(SUM(s.total_amount) FILTER (WHERE s.sale_status = 'refunded'), 0) as refund_amount
    FROM sales s
    LEFT JOIN sale_items si ON si.sale_id = s.id
    WHERE s.sale_date = p_date
      AND s.sale_status NOT IN ('void', 'refunded')
    GROUP BY s.tenant_id, s.branch_id
    ON CONFLICT (tenant_id, branch_id, date_key, sale_date)
    DO UPDATE SET
        total_transactions = EXCLUDED.total_transactions,
        total_items_sold = EXCLUDED.total_items_sold,
        total_revenue = EXCLUDED.total_revenue,
        total_cost = EXCLUDED.total_cost,
        total_profit = EXCLUDED.total_profit,
        average_transaction_value = EXCLUDED.average_transaction_value,
        average_profit_margin = EXCLUDED.average_profit_margin,
        unique_customers = EXCLUDED.unique_customers,
        new_customers = EXCLUDED.new_customers,
        cash_transactions = EXCLUDED.cash_transactions,
        cash_revenue = EXCLUDED.cash_revenue,
        card_transactions = EXCLUDED.card_transactions,
        card_revenue = EXCLUDED.card_revenue,
        transfer_transactions = EXCLUDED.transfer_transactions,
        transfer_revenue = EXCLUDED.transfer_revenue,
        void_transactions = EXCLUDED.void_transactions,
        void_amount = EXCLUDED.void_amount,
        refund_transactions = EXCLUDED.refund_transactions,
        refund_amount = EXCLUDED.refund_amount,
        updated_at = NOW();

    GET DIAGNOSTICS v_rows_affected = ROW_COUNT;
    RAISE NOTICE 'Aggregated % rows into fact_daily_sales for date %', v_rows_affected, p_date;

END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 2. AGGREGATE PRODUCT SALES FUNCTION
-- ============================================

CREATE OR REPLACE FUNCTION aggregate_product_sales(p_date DATE)
RETURNS void AS $$
DECLARE
    v_date_key INTEGER;
    v_rows_affected INTEGER;
BEGIN
    -- Get date key
    SELECT date_key INTO v_date_key
    FROM dim_date
    WHERE date_value = p_date;

    IF v_date_key IS NULL THEN
        RAISE EXCEPTION 'Date % not found in dim_date', p_date;
    END IF;

    -- Aggregate to fact_product_sales
    INSERT INTO fact_product_sales (
        tenant_id, branch_id, date_key, sale_date,
        product_id, brand_id, category_id,
        product_name, product_sku, brand_name, category_name,
        quantity_sold, total_revenue, total_cost, total_profit,
        average_unit_price, average_profit_margin, transaction_count,
        total_discount_amount, average_discount_percentage
    )
    SELECT
        si.tenant_id,
        s.branch_id,
        v_date_key,
        p_date,
        si.product_id,
        si.brand_id,
        si.category_id,
        MAX(si.product_name) as product_name,
        MAX(si.product_sku) as product_sku,
        MAX(si.brand_name) as brand_name,
        MAX(si.category_name) as category_name,
        COALESCE(SUM(si.quantity), 0) as quantity_sold,
        COALESCE(SUM(si.line_total), 0) as total_revenue,
        COALESCE(SUM(si.total_cost), 0) as total_cost,
        COALESCE(SUM(si.gross_profit), 0) as total_profit,
        COALESCE(AVG(si.unit_price), 0) as average_unit_price,
        COALESCE(AVG(si.profit_margin), 0) as average_profit_margin,
        COUNT(DISTINCT s.id) as transaction_count,
        COALESCE(SUM(si.discount_amount), 0) as total_discount_amount,
        COALESCE(AVG(si.discount_percentage), 0) as average_discount_percentage
    FROM sale_items si
    JOIN sales s ON s.id = si.sale_id
    WHERE s.sale_date = p_date
      AND s.sale_status NOT IN ('void', 'refunded')
    GROUP BY
        si.tenant_id, s.branch_id, si.product_id,
        si.brand_id, si.category_id
    ON CONFLICT (tenant_id, branch_id, date_key, product_id, sale_date)
    DO UPDATE SET
        quantity_sold = EXCLUDED.quantity_sold,
        total_revenue = EXCLUDED.total_revenue,
        total_cost = EXCLUDED.total_cost,
        total_profit = EXCLUDED.total_profit,
        average_unit_price = EXCLUDED.average_unit_price,
        average_profit_margin = EXCLUDED.average_profit_margin,
        transaction_count = EXCLUDED.transaction_count,
        total_discount_amount = EXCLUDED.total_discount_amount,
        average_discount_percentage = EXCLUDED.average_discount_percentage,
        updated_at = NOW();

    GET DIAGNOSTICS v_rows_affected = ROW_COUNT;
    RAISE NOTICE 'Aggregated % rows into fact_product_sales for date %', v_rows_affected, p_date;

END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 3. AGGREGATE STAFF SALES FUNCTION
-- ============================================

CREATE OR REPLACE FUNCTION aggregate_staff_sales(p_date DATE)
RETURNS void AS $$
DECLARE
    v_date_key INTEGER;
    v_rows_affected INTEGER;
BEGIN
    -- Get date key
    SELECT date_key INTO v_date_key
    FROM dim_date
    WHERE date_value = p_date;

    IF v_date_key IS NULL THEN
        RAISE EXCEPTION 'Date % not found in dim_date', p_date;
    END IF;

    -- Aggregate cashier sales
    INSERT INTO fact_staff_sales (
        tenant_id, branch_id, date_key, sale_date,
        staff_id, staff_role, staff_name,
        total_transactions, total_items_sold, total_revenue,
        total_profit, average_transaction_value,
        commission_eligible_sales, commission_amount
    )
    SELECT
        s.tenant_id,
        s.branch_id,
        v_date_key,
        p_date,
        s.cashier_id as staff_id,
        'cashier' as staff_role,
        COALESCE(u.full_name, u.email) as staff_name,
        COUNT(DISTINCT s.id) as total_transactions,
        COALESCE(SUM(si.quantity), 0) as total_items_sold,
        COALESCE(SUM(s.total_amount), 0) as total_revenue,
        COALESCE(SUM(si.gross_profit), 0) as total_profit,
        COALESCE(AVG(s.total_amount), 0) as average_transaction_value,
        0 as commission_eligible_sales,
        0 as commission_amount
    FROM sales s
    LEFT JOIN sale_items si ON si.sale_id = s.id
    LEFT JOIN users u ON u.id = s.cashier_id
    WHERE s.sale_date = p_date
      AND s.sale_status NOT IN ('void', 'refunded')
    GROUP BY s.tenant_id, s.branch_id, s.cashier_id, u.full_name, u.email
    ON CONFLICT (tenant_id, branch_id, date_key, staff_id, staff_role, sale_date)
    DO UPDATE SET
        total_transactions = EXCLUDED.total_transactions,
        total_items_sold = EXCLUDED.total_items_sold,
        total_revenue = EXCLUDED.total_revenue,
        total_profit = EXCLUDED.total_profit,
        average_transaction_value = EXCLUDED.average_transaction_value,
        updated_at = NOW();

    GET DIAGNOSTICS v_rows_affected = ROW_COUNT;
    RAISE NOTICE 'Aggregated % cashier rows into fact_staff_sales for date %', v_rows_affected, p_date;

    -- Aggregate sales attendant sales (if different from cashier)
    INSERT INTO fact_staff_sales (
        tenant_id, branch_id, date_key, sale_date,
        staff_id, staff_role, staff_name,
        total_transactions, total_items_sold, total_revenue,
        total_profit, average_transaction_value,
        commission_eligible_sales, commission_amount
    )
    SELECT
        s.tenant_id,
        s.branch_id,
        v_date_key,
        p_date,
        s.sales_attendant_id as staff_id,
        'sales_attendant' as staff_role,
        COALESCE(u.full_name, u.email) as staff_name,
        COUNT(DISTINCT s.id) as total_transactions,
        COALESCE(SUM(si.quantity), 0) as total_items_sold,
        COALESCE(SUM(s.total_amount), 0) as total_revenue,
        COALESCE(SUM(si.gross_profit), 0) as total_profit,
        COALESCE(AVG(s.total_amount), 0) as average_transaction_value,
        COALESCE(SUM(s.total_amount), 0) as commission_eligible_sales,
        COALESCE(SUM(s.total_amount) * 0.05, 0) as commission_amount -- 5% commission
    FROM sales s
    LEFT JOIN sale_items si ON si.sale_id = s.id
    LEFT JOIN users u ON u.id = s.sales_attendant_id
    WHERE s.sale_date = p_date
      AND s.sales_attendant_id IS NOT NULL
      AND s.sale_status NOT IN ('void', 'refunded')
    GROUP BY s.tenant_id, s.branch_id, s.sales_attendant_id, u.full_name, u.email
    ON CONFLICT (tenant_id, branch_id, date_key, staff_id, staff_role, sale_date)
    DO UPDATE SET
        total_transactions = EXCLUDED.total_transactions,
        total_items_sold = EXCLUDED.total_items_sold,
        total_revenue = EXCLUDED.total_revenue,
        total_profit = EXCLUDED.total_profit,
        average_transaction_value = EXCLUDED.average_transaction_value,
        commission_eligible_sales = EXCLUDED.commission_eligible_sales,
        commission_amount = EXCLUDED.commission_amount,
        updated_at = NOW();

    GET DIAGNOSTICS v_rows_affected = ROW_COUNT;
    RAISE NOTICE 'Aggregated % sales attendant rows into fact_staff_sales for date %', v_rows_affected, p_date;

END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 4. AGGREGATE BRAND SALES FUNCTION
-- ============================================

CREATE OR REPLACE FUNCTION aggregate_brand_sales(p_date DATE)
RETURNS void AS $$
DECLARE
    v_date_key INTEGER;
    v_rows_affected INTEGER;
BEGIN
    -- Get date key
    SELECT date_key INTO v_date_key
    FROM dim_date
    WHERE date_value = p_date;

    IF v_date_key IS NULL THEN
        RAISE EXCEPTION 'Date % not found in dim_date', p_date;
    END IF;

    -- Aggregate to fact_brand_sales
    INSERT INTO fact_brand_sales (
        tenant_id, branch_id, date_key, sale_date,
        brand_id, category_id,
        brand_name, category_name,
        unique_products_sold, quantity_sold,
        total_revenue, total_cost, total_profit,
        average_profit_margin, transaction_count
    )
    SELECT
        si.tenant_id,
        s.branch_id,
        v_date_key,
        p_date,
        si.brand_id,
        si.category_id,
        MAX(si.brand_name) as brand_name,
        MAX(si.category_name) as category_name,
        COUNT(DISTINCT si.product_id) as unique_products_sold,
        COALESCE(SUM(si.quantity), 0) as quantity_sold,
        COALESCE(SUM(si.line_total), 0) as total_revenue,
        COALESCE(SUM(si.total_cost), 0) as total_cost,
        COALESCE(SUM(si.gross_profit), 0) as total_profit,
        COALESCE(AVG(si.profit_margin), 0) as average_profit_margin,
        COUNT(DISTINCT s.id) as transaction_count
    FROM sale_items si
    JOIN sales s ON s.id = si.sale_id
    WHERE s.sale_date = p_date
      AND si.brand_id IS NOT NULL
      AND s.sale_status NOT IN ('void', 'refunded')
    GROUP BY
        si.tenant_id, s.branch_id,
        si.brand_id, si.category_id
    ON CONFLICT (tenant_id, branch_id, date_key, brand_id, sale_date)
    DO UPDATE SET
        unique_products_sold = EXCLUDED.unique_products_sold,
        quantity_sold = EXCLUDED.quantity_sold,
        total_revenue = EXCLUDED.total_revenue,
        total_cost = EXCLUDED.total_cost,
        total_profit = EXCLUDED.total_profit,
        average_profit_margin = EXCLUDED.average_profit_margin,
        transaction_count = EXCLUDED.transaction_count,
        updated_at = NOW();

    GET DIAGNOSTICS v_rows_affected = ROW_COUNT;
    RAISE NOTICE 'Aggregated % rows into fact_brand_sales for date %', v_rows_affected, p_date;

END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 5. AGGREGATE HOURLY SALES FUNCTION
-- ============================================

CREATE OR REPLACE FUNCTION aggregate_hourly_sales(p_date DATE)
RETURNS void AS $$
DECLARE
    v_date_key INTEGER;
    v_rows_affected INTEGER;
BEGIN
    -- Get date key
    SELECT date_key INTO v_date_key
    FROM dim_date
    WHERE date_value = p_date;

    IF v_date_key IS NULL THEN
        RAISE EXCEPTION 'Date % not found in dim_date', p_date;
    END IF;

    -- Aggregate to fact_hourly_sales
    INSERT INTO fact_hourly_sales (
        tenant_id, branch_id, date_key, time_key, sale_date, hour,
        total_transactions, total_revenue, average_transaction_value
    )
    SELECT
        s.tenant_id,
        s.branch_id,
        v_date_key,
        dt.time_key,
        p_date,
        EXTRACT(HOUR FROM s.sale_time)::INTEGER as hour,
        COUNT(DISTINCT s.id) as total_transactions,
        COALESCE(SUM(s.total_amount), 0) as total_revenue,
        COALESCE(AVG(s.total_amount), 0) as average_transaction_value
    FROM sales s
    JOIN dim_time dt ON dt.hour = EXTRACT(HOUR FROM s.sale_time)
                    AND dt.minute = 0
                    AND dt.second = 0
    WHERE s.sale_date = p_date
      AND s.sale_status NOT IN ('void', 'refunded')
    GROUP BY
        s.tenant_id, s.branch_id,
        EXTRACT(HOUR FROM s.sale_time),
        dt.time_key
    ON CONFLICT (tenant_id, branch_id, date_key, time_key, sale_date)
    DO UPDATE SET
        total_transactions = EXCLUDED.total_transactions,
        total_revenue = EXCLUDED.total_revenue,
        average_transaction_value = EXCLUDED.average_transaction_value,
        updated_at = NOW();

    GET DIAGNOSTICS v_rows_affected = ROW_COUNT;
    RAISE NOTICE 'Aggregated % rows into fact_hourly_sales for date %', v_rows_affected, p_date;

END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 6. MASTER AGGREGATION FUNCTION
-- ============================================

CREATE OR REPLACE FUNCTION aggregate_all_analytics(p_date DATE)
RETURNS void AS $$
BEGIN
    RAISE NOTICE 'Starting analytics aggregation for date: %', p_date;

    -- Run all aggregation functions
    PERFORM aggregate_daily_sales(p_date);
    PERFORM aggregate_product_sales(p_date);
    PERFORM aggregate_staff_sales(p_date);
    PERFORM aggregate_brand_sales(p_date);
    PERFORM aggregate_hourly_sales(p_date);

    RAISE NOTICE 'Completed analytics aggregation for date: %', p_date;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 7. BACKFILL FUNCTION (For Historical Data)
-- ============================================

CREATE OR REPLACE FUNCTION backfill_analytics(
    p_start_date DATE,
    p_end_date DATE
)
RETURNS void AS $$
DECLARE
    v_current_date DATE;
BEGIN
    v_current_date := p_start_date;

    WHILE v_current_date <= p_end_date LOOP
        RAISE NOTICE 'Processing date: %', v_current_date;

        -- Run aggregation for this date
        PERFORM aggregate_all_analytics(v_current_date);

        -- Move to next day
        v_current_date := v_current_date + INTERVAL '1 day';
    END LOOP;

    RAISE NOTICE 'Backfill completed from % to %', p_start_date, p_end_date;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 8. TRIGGER TO AUTO-POPULATE SALE ITEM DETAILS
-- ============================================

-- Function to populate sale_item product details on insert
CREATE OR REPLACE FUNCTION populate_sale_item_details()
RETURNS TRIGGER AS $$
DECLARE
    v_product RECORD;
BEGIN
    -- Get product details
    SELECT
        p.name,
        p.sku,
        p.brand_id,
        b.name as brand_name,
        p.category_id,
        c.name as category_name,
        p.cost_price,
        p.unit_of_measure
    INTO v_product
    FROM products p
    LEFT JOIN brands b ON b.id = p.brand_id
    LEFT JOIN categories c ON c.id = p.category_id
    WHERE p.id = NEW.product_id;

    -- Populate snapshot fields
    NEW.product_name := v_product.name;
    NEW.product_sku := v_product.sku;
    NEW.brand_id := v_product.brand_id;
    NEW.brand_name := v_product.brand_name;
    NEW.category_id := v_product.category_id;
    NEW.category_name := v_product.category_name;
    NEW.unit_of_measure := COALESCE(NEW.unit_of_measure, v_product.unit_of_measure, 'piece');

    -- Calculate cost and profit if unit_cost provided
    IF NEW.unit_cost IS NOT NULL THEN
        NEW.total_cost := NEW.unit_cost * NEW.quantity;
        NEW.gross_profit := NEW.line_total - NEW.total_cost;
        IF NEW.line_total > 0 THEN
            NEW.profit_margin := (NEW.gross_profit / NEW.line_total) * 100;
        END IF;
    ELSIF v_product.cost_price IS NOT NULL THEN
        NEW.unit_cost := v_product.cost_price;
        NEW.total_cost := v_product.cost_price * NEW.quantity;
        NEW.gross_profit := NEW.line_total - NEW.total_cost;
        IF NEW.line_total > 0 THEN
            NEW.profit_margin := (NEW.gross_profit / NEW.line_total) * 100;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger
DROP TRIGGER IF EXISTS trg_populate_sale_item_details ON sale_items;
CREATE TRIGGER trg_populate_sale_item_details
    BEFORE INSERT ON sale_items
    FOR EACH ROW
    EXECUTE FUNCTION populate_sale_item_details();

-- ============================================
-- 9. TRIGGER TO AUTO-POPULATE SALE DATE/TIME
-- ============================================

-- Function to populate sale date and time on insert
CREATE OR REPLACE FUNCTION populate_sale_datetime()
RETURNS TRIGGER AS $$
BEGIN
    -- Set sale_date and sale_time from completed_at if not provided
    IF NEW.sale_date IS NULL THEN
        NEW.sale_date := DATE(NEW.completed_at);
    END IF;

    IF NEW.sale_time IS NULL THEN
        NEW.sale_time := NEW.completed_at::TIME;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger
DROP TRIGGER IF EXISTS trg_populate_sale_datetime ON sales;
CREATE TRIGGER trg_populate_sale_datetime
    BEFORE INSERT ON sales
    FOR EACH ROW
    EXECUTE FUNCTION populate_sale_datetime();

-- ============================================
-- 10. COMMENTS FOR DOCUMENTATION
-- ============================================

COMMENT ON FUNCTION aggregate_daily_sales IS 'Aggregates sales data into fact_daily_sales for a specific date';
COMMENT ON FUNCTION aggregate_product_sales IS 'Aggregates product-level sales into fact_product_sales for a specific date';
COMMENT ON FUNCTION aggregate_staff_sales IS 'Aggregates staff performance into fact_staff_sales for a specific date';
COMMENT ON FUNCTION aggregate_brand_sales IS 'Aggregates brand performance into fact_brand_sales for a specific date';
COMMENT ON FUNCTION aggregate_hourly_sales IS 'Aggregates hourly sales patterns into fact_hourly_sales for a specific date';
COMMENT ON FUNCTION aggregate_all_analytics IS 'Master function to run all analytics aggregations for a specific date (run daily via cron)';
COMMENT ON FUNCTION backfill_analytics IS 'Backfill analytics data for a date range (useful for historical data)';
COMMENT ON FUNCTION populate_sale_item_details IS 'Trigger function to auto-populate product snapshot details in sale_items';
COMMENT ON FUNCTION populate_sale_datetime IS 'Trigger function to auto-populate sale_date and sale_time in sales';


-- File: 013_analytics_seed_dimensions.sql
-- ============================================
-- Migration: Seed Analytics Dimension Tables
-- Description: Populate dim_date and dim_time with data
-- Created: 2026-01-22
-- ============================================

-- ============================================
-- 1. POPULATE DIM_DATE (2020-2030)
-- ============================================

CREATE OR REPLACE FUNCTION populate_dim_date(
    p_start_date DATE DEFAULT '2020-01-01',
    p_end_date DATE DEFAULT '2030-12-31'
)
RETURNS void AS $$
DECLARE
    v_current_date DATE;
    v_date_key INTEGER;
    v_day_of_week INTEGER;
    v_is_weekend BOOLEAN;
BEGIN
    v_current_date := p_start_date;

    WHILE v_current_date <= p_end_date LOOP
        -- Calculate date key (YYYYMMDD format)
        v_date_key := TO_CHAR(v_current_date, 'YYYYMMDD')::INTEGER;

        -- Calculate day of week (1=Monday, 7=Sunday)
        v_day_of_week := EXTRACT(ISODOW FROM v_current_date);

        -- Check if weekend
        v_is_weekend := v_day_of_week IN (6, 7);

        INSERT INTO dim_date (
            date_key,
            date_value,
            day,
            day_of_week,
            day_of_week_name,
            day_of_year,
            week_of_year,
            week_start_date,
            week_end_date,
            month,
            month_name,
            month_abbr,
            month_start_date,
            month_end_date,
            quarter,
            quarter_name,
            quarter_start_date,
            quarter_end_date,
            year,
            year_start_date,
            year_end_date,
            fiscal_year,
            fiscal_quarter,
            fiscal_month,
            is_weekend,
            is_holiday,
            is_business_day,
            prior_day_key,
            prior_week_key,
            prior_month_key,
            prior_quarter_key,
            prior_year_key
        )
        VALUES (
            v_date_key,
            v_current_date,
            EXTRACT(DAY FROM v_current_date),
            v_day_of_week,
            TO_CHAR(v_current_date, 'Day'),
            EXTRACT(DOY FROM v_current_date),
            EXTRACT(WEEK FROM v_current_date),
            DATE_TRUNC('week', v_current_date)::DATE,
            (DATE_TRUNC('week', v_current_date) + INTERVAL '6 days')::DATE,
            EXTRACT(MONTH FROM v_current_date),
            TO_CHAR(v_current_date, 'Month'),
            TO_CHAR(v_current_date, 'Mon'),
            DATE_TRUNC('month', v_current_date)::DATE,
            (DATE_TRUNC('month', v_current_date) + INTERVAL '1 month' - INTERVAL '1 day')::DATE,
            EXTRACT(QUARTER FROM v_current_date),
            'Q' || EXTRACT(QUARTER FROM v_current_date),
            DATE_TRUNC('quarter', v_current_date)::DATE,
            (DATE_TRUNC('quarter', v_current_date) + INTERVAL '3 months' - INTERVAL '1 day')::DATE,
            EXTRACT(YEAR FROM v_current_date),
            DATE_TRUNC('year', v_current_date)::DATE,
            (DATE_TRUNC('year', v_current_date) + INTERVAL '1 year' - INTERVAL '1 day')::DATE,
            EXTRACT(YEAR FROM v_current_date), -- Fiscal year same as calendar year
            EXTRACT(QUARTER FROM v_current_date), -- Fiscal quarter same as calendar quarter
            EXTRACT(MONTH FROM v_current_date), -- Fiscal month same as calendar month
            v_is_weekend,
            false, -- is_holiday (populate separately)
            NOT v_is_weekend, -- is_business_day (weekdays only, adjust for holidays)
            TO_CHAR(v_current_date - INTERVAL '1 day', 'YYYYMMDD')::INTEGER,
            TO_CHAR(v_current_date - INTERVAL '7 days', 'YYYYMMDD')::INTEGER,
            TO_CHAR(v_current_date - INTERVAL '1 month', 'YYYYMMDD')::INTEGER,
            TO_CHAR(v_current_date - INTERVAL '3 months', 'YYYYMMDD')::INTEGER,
            TO_CHAR(v_current_date - INTERVAL '1 year', 'YYYYMMDD')::INTEGER
        )
        ON CONFLICT (date_key) DO NOTHING;

        v_current_date := v_current_date + INTERVAL '1 day';
    END LOOP;

    RAISE NOTICE 'Populated dim_date from % to %', p_start_date, p_end_date;
END;
$$ LANGUAGE plpgsql;

-- Execute the population
SELECT populate_dim_date('2020-01-01', '2030-12-31');

-- ============================================
-- 2. POPULATE NIGERIAN HOLIDAYS
-- ============================================

-- Function to mark holidays in dim_date
CREATE OR REPLACE FUNCTION mark_holidays()
RETURNS void AS $$
BEGIN
    -- Nigerian Public Holidays (Fixed dates)

    -- New Year's Day (January 1)
    UPDATE dim_date
    SET is_holiday = true,
        holiday_name = 'New Year''s Day',
        is_business_day = false
    WHERE month = 1 AND day = 1;

    -- Workers' Day (May 1)
    UPDATE dim_date
    SET is_holiday = true,
        holiday_name = 'Workers'' Day',
        is_business_day = false
    WHERE month = 5 AND day = 1;

    -- Democracy Day (June 12)
    UPDATE dim_date
    SET is_holiday = true,
        holiday_name = 'Democracy Day',
        is_business_day = false
    WHERE month = 6 AND day = 12;

    -- Independence Day (October 1)
    UPDATE dim_date
    SET is_holiday = true,
        holiday_name = 'Independence Day',
        is_business_day = false
    WHERE month = 10 AND day = 1;

    -- Christmas Day (December 25)
    UPDATE dim_date
    SET is_holiday = true,
        holiday_name = 'Christmas Day',
        is_business_day = false
    WHERE month = 12 AND day = 25;

    -- Boxing Day (December 26)
    UPDATE dim_date
    SET is_holiday = true,
        holiday_name = 'Boxing Day',
        is_business_day = false
    WHERE month = 12 AND day = 26;

    -- Note: Eid al-Fitr, Eid al-Adha, and Mawlid vary by lunar calendar
    -- These should be updated annually based on Islamic calendar
    -- Example for 2024:
    -- Eid al-Fitr 2024 (April 10)
    UPDATE dim_date
    SET is_holiday = true,
        holiday_name = 'Eid al-Fitr',
        is_business_day = false
    WHERE date_value = '2024-04-10';

    -- Eid al-Adha 2024 (June 16)
    UPDATE dim_date
    SET is_holiday = true,
        holiday_name = 'Eid al-Adha',
        is_business_day = false
    WHERE date_value = '2024-06-16';

    -- Mawlid 2024 (September 15)
    UPDATE dim_date
    SET is_holiday = true,
        holiday_name = 'Mawlid (Prophet''s Birthday)',
        is_business_day = false
    WHERE date_value = '2024-09-15';

    -- 2025 Islamic holidays (approximate)
    UPDATE dim_date
    SET is_holiday = true,
        holiday_name = 'Eid al-Fitr',
        is_business_day = false
    WHERE date_value = '2025-03-30';

    UPDATE dim_date
    SET is_holiday = true,
        holiday_name = 'Eid al-Adha',
        is_business_day = false
    WHERE date_value = '2025-06-06';

    UPDATE dim_date
    SET is_holiday = true,
        holiday_name = 'Mawlid (Prophet''s Birthday)',
        is_business_day = false
    WHERE date_value = '2025-09-04';

    -- 2026 Islamic holidays (approximate)
    UPDATE dim_date
    SET is_holiday = true,
        holiday_name = 'Eid al-Fitr',
        is_business_day = false
    WHERE date_value = '2026-03-20';

    UPDATE dim_date
    SET is_holiday = true,
        holiday_name = 'Eid al-Adha',
        is_business_day = false
    WHERE date_value = '2026-05-27';

    UPDATE dim_date
    SET is_holiday = true,
        holiday_name = 'Mawlid (Prophet''s Birthday)',
        is_business_day = false
    WHERE date_value = '2026-08-25';

    RAISE NOTICE 'Nigerian holidays marked in dim_date';
END;
$$ LANGUAGE plpgsql;

-- Execute the holiday marking
SELECT mark_holidays();

-- ============================================
-- 3. POPULATE DIM_TIME (24-hour, every hour)
-- ============================================

CREATE OR REPLACE FUNCTION populate_dim_time()
RETURNS void AS $$
DECLARE
    v_hour INTEGER;
    v_minute INTEGER;
    v_second INTEGER;
    v_time_key INTEGER;
    v_time_value TIME;
    v_time_period VARCHAR(20);
    v_business_hour VARCHAR(20);
    v_hour_12 INTEGER;
    v_am_pm VARCHAR(2);
    v_is_peak_hour BOOLEAN;
BEGIN
    -- Generate time entries for every hour of the day
    FOR v_hour IN 0..23 LOOP
        FOR v_minute IN 0..59 BY 15 LOOP -- 15-minute intervals
            v_second := 0;

            -- Calculate time key (HHMMSS format)
            v_time_key := (v_hour * 10000) + (v_minute * 100) + v_second;

            -- Create time value
            v_time_value := (v_hour || ':' || v_minute || ':' || v_second)::TIME;

            -- Determine time period
            v_time_period := CASE
                WHEN v_hour >= 5 AND v_hour < 12 THEN 'morning'
                WHEN v_hour >= 12 AND v_hour < 17 THEN 'afternoon'
                WHEN v_hour >= 17 AND v_hour < 21 THEN 'evening'
                ELSE 'night'
            END;

            -- Determine business hour
            v_business_hour := CASE
                WHEN v_hour < 8 THEN 'pre-open'
                WHEN v_hour >= 8 AND v_hour < 12 THEN 'business'
                WHEN v_hour >= 12 AND v_hour < 14 THEN 'lunch'
                WHEN v_hour >= 14 AND v_hour < 18 THEN 'business'
                ELSE 'post-close'
            END;

            -- 12-hour format
            v_hour_12 := CASE WHEN v_hour = 0 THEN 12
                             WHEN v_hour > 12 THEN v_hour - 12
                             ELSE v_hour
                        END;

            v_am_pm := CASE WHEN v_hour < 12 THEN 'AM' ELSE 'PM' END;

            -- Peak hours (configurable: 11am-2pm, 5pm-8pm)
            v_is_peak_hour := v_hour IN (11, 12, 13, 17, 18, 19);

            INSERT INTO dim_time (
                time_key,
                time_value,
                hour,
                hour_12,
                am_pm,
                minute,
                second,
                time_period,
                business_hour,
                hour_bucket,
                minute_bucket,
                is_peak_hour
            )
            VALUES (
                v_time_key,
                v_time_value,
                v_hour,
                v_hour_12,
                v_am_pm,
                v_minute,
                v_second,
                v_time_period,
                v_business_hour,
                v_hour,
                v_minute,
                v_is_peak_hour
            )
            ON CONFLICT (time_key) DO NOTHING;
        END LOOP;
    END LOOP;

    RAISE NOTICE 'Populated dim_time with 96 time entries (15-minute intervals)';
END;
$$ LANGUAGE plpgsql;

-- Execute the population
SELECT populate_dim_time();

-- ============================================
-- 4. HELPER VIEWS FOR EASY ACCESS
-- ============================================

-- View to get current period keys
CREATE OR REPLACE VIEW v_current_period_keys AS
SELECT
    dd_today.date_key as today_key,
    dd_yesterday.date_key as yesterday_key,
    dd_last_week.date_key as last_week_key,
    dd_last_month.date_key as last_month_key,
    dd_last_quarter.date_key as last_quarter_key,
    dd_last_year.date_key as last_year_key,
    dd_today.date_value as today,
    dd_today.week_start_date as this_week_start,
    dd_today.week_end_date as this_week_end,
    dd_today.month_start_date as this_month_start,
    dd_today.month_end_date as this_month_end,
    dd_today.quarter_start_date as this_quarter_start,
    dd_today.quarter_end_date as this_quarter_end,
    dd_today.year_start_date as this_year_start,
    dd_today.year_end_date as this_year_end
FROM dim_date dd_today
LEFT JOIN dim_date dd_yesterday ON dd_yesterday.date_key = dd_today.prior_day_key
LEFT JOIN dim_date dd_last_week ON dd_last_week.date_key = dd_today.prior_week_key
LEFT JOIN dim_date dd_last_month ON dd_last_month.date_key = dd_today.prior_month_key
LEFT JOIN dim_date dd_last_quarter ON dd_last_quarter.date_key = dd_today.prior_quarter_key
LEFT JOIN dim_date dd_last_year ON dd_last_year.date_key = dd_today.prior_year_key
WHERE dd_today.date_value = CURRENT_DATE;

-- View to easily get date ranges
CREATE OR REPLACE VIEW v_common_date_ranges AS
SELECT
    CURRENT_DATE as today,
    CURRENT_DATE - INTERVAL '1 day' as yesterday,
    DATE_TRUNC('week', CURRENT_DATE)::DATE as this_week_start,
    (DATE_TRUNC('week', CURRENT_DATE) + INTERVAL '6 days')::DATE as this_week_end,
    DATE_TRUNC('month', CURRENT_DATE)::DATE as this_month_start,
    (DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month' - INTERVAL '1 day')::DATE as this_month_end,
    DATE_TRUNC('quarter', CURRENT_DATE)::DATE as this_quarter_start,
    (DATE_TRUNC('quarter', CURRENT_DATE) + INTERVAL '3 months' - INTERVAL '1 day')::DATE as this_quarter_end,
    DATE_TRUNC('year', CURRENT_DATE)::DATE as this_year_start,
    (DATE_TRUNC('year', CURRENT_DATE) + INTERVAL '1 year' - INTERVAL '1 day')::DATE as this_year_end,
    (DATE_TRUNC('week', CURRENT_DATE) - INTERVAL '7 days')::DATE as last_week_start,
    (DATE_TRUNC('week', CURRENT_DATE) - INTERVAL '1 day')::DATE as last_week_end,
    (DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '1 month')::DATE as last_month_start,
    (DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '1 day')::DATE as last_month_end,
    (DATE_TRUNC('quarter', CURRENT_DATE) - INTERVAL '3 months')::DATE as last_quarter_start,
    (DATE_TRUNC('quarter', CURRENT_DATE) - INTERVAL '1 day')::DATE as last_quarter_end,
    (DATE_TRUNC('year', CURRENT_DATE) - INTERVAL '1 year')::DATE as last_year_start,
    (DATE_TRUNC('year', CURRENT_DATE) - INTERVAL '1 day')::DATE as last_year_end,
    CURRENT_DATE - INTERVAL '7 days' as last_7_days_start,
    CURRENT_DATE - INTERVAL '30 days' as last_30_days_start,
    CURRENT_DATE - INTERVAL '90 days' as last_90_days_start,
    CURRENT_DATE - INTERVAL '365 days' as last_365_days_start;

-- ============================================
-- 5. MAINTENANCE FUNCTIONS
-- ============================================

-- Function to extend dim_date into the future
CREATE OR REPLACE FUNCTION extend_dim_date(p_years_ahead INTEGER DEFAULT 1)
RETURNS void AS $$
DECLARE
    v_max_date DATE;
    v_new_end_date DATE;
BEGIN
    -- Get current max date in dim_date
    SELECT MAX(date_value) INTO v_max_date FROM dim_date;

    -- Calculate new end date
    v_new_end_date := v_max_date + (p_years_ahead || ' years')::INTERVAL;

    -- Populate new dates
    PERFORM populate_dim_date(v_max_date + INTERVAL '1 day', v_new_end_date);

    -- Mark holidays in new dates
    PERFORM mark_holidays();

    RAISE NOTICE 'Extended dim_date by % years to %', p_years_ahead, v_new_end_date;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 6. VERIFICATION QUERIES
-- ============================================

-- Verify dim_date population
DO $$
DECLARE
    v_count INTEGER;
    v_min_date DATE;
    v_max_date DATE;
BEGIN
    SELECT COUNT(*), MIN(date_value), MAX(date_value)
    INTO v_count, v_min_date, v_max_date
    FROM dim_date;

    RAISE NOTICE 'dim_date populated with % records from % to %', v_count, v_min_date, v_max_date;
END $$;

-- Verify dim_time population
DO $$
DECLARE
    v_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_count FROM dim_time;
    RAISE NOTICE 'dim_time populated with % records', v_count;
END $$;

-- ============================================
-- 7. COMMENTS FOR DOCUMENTATION
-- ============================================

COMMENT ON FUNCTION populate_dim_date IS 'Populates dim_date table with calendar data for a date range';
COMMENT ON FUNCTION mark_holidays IS 'Marks Nigerian public holidays in dim_date';
COMMENT ON FUNCTION populate_dim_time IS 'Populates dim_time table with 15-minute interval time data';
COMMENT ON FUNCTION extend_dim_date IS 'Extends dim_date table into the future';
COMMENT ON VIEW v_current_period_keys IS 'Helper view to get current period date keys for comparisons';
COMMENT ON VIEW v_common_date_ranges IS 'Helper view to get common date ranges (this week, last month, etc.)';


-- File: 014_enhance_sales_table.sql
-- ============================================
-- Migration: Enhance Sales Table for Analytics
-- Description: Add missing columns to existing sales table
-- Created: 2026-01-23
-- ============================================

-- Add customer_type column if not exists
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'sales' AND column_name = 'customer_type'
    ) THEN
        ALTER TABLE sales ADD COLUMN customer_type VARCHAR(20) DEFAULT 'walk-in';
        COMMENT ON COLUMN sales.customer_type IS 'Customer type: walk-in, registered, marketplace, new';
    END IF;
END $$;

-- Add sales_attendant_id column if not exists
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'sales' AND column_name = 'sales_attendant_id'
    ) THEN
        ALTER TABLE sales ADD COLUMN sales_attendant_id UUID REFERENCES users(id) ON DELETE SET NULL;
        COMMENT ON COLUMN sales.sales_attendant_id IS 'Staff member who assisted with the sale (for commission tracking)';

        -- Create index for sales attendant queries
        CREATE INDEX idx_sales_attendant ON sales(sales_attendant_id, created_at DESC) WHERE sales_attendant_id IS NOT NULL;
    END IF;
END $$;

-- Add sale_type column if not exists
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'sales' AND column_name = 'sale_type'
    ) THEN
        ALTER TABLE sales ADD COLUMN sale_type VARCHAR(20) DEFAULT 'pos';
        COMMENT ON COLUMN sales.sale_type IS 'Sale type: pos, online, marketplace, delivery';
    END IF;
END $$;

-- Add channel column if not exists
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'sales' AND column_name = 'channel'
    ) THEN
        ALTER TABLE sales ADD COLUMN channel VARCHAR(20) DEFAULT 'in-store';
        COMMENT ON COLUMN sales.channel IS 'Sales channel: in-store, online, mobile-app, whatsapp';

        -- Create index for channel analysis
        CREATE INDEX idx_sales_channel ON sales(channel, tenant_id) WHERE channel IS NOT NULL;
    END IF;
END $$;

-- Rename 'status' to 'sale_status' if needed (handle both cases)
DO $$
BEGIN
    -- If 'status' exists but 'sale_status' doesn't, rename it
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'sales' AND column_name = 'status'
    ) AND NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'sales' AND column_name = 'sale_status'
    ) THEN
        ALTER TABLE sales RENAME COLUMN status TO sale_status;
    END IF;

    -- If neither exists, create sale_status
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'sales' AND column_name = 'sale_status'
    ) AND NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'sales' AND column_name = 'status'
    ) THEN
        ALTER TABLE sales ADD COLUMN sale_status VARCHAR(20) DEFAULT 'completed';
        COMMENT ON COLUMN sales.sale_status IS 'Sale status: pending, completed, void, refunded, partial_refund';
    END IF;
END $$;

-- Add void tracking columns if not exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'sales' AND column_name = 'void_reason'
    ) THEN
        ALTER TABLE sales ADD COLUMN void_reason TEXT;
        COMMENT ON COLUMN sales.void_reason IS 'Reason for voiding the sale';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'sales' AND column_name = 'voided_by'
    ) THEN
        ALTER TABLE sales ADD COLUMN voided_by UUID REFERENCES users(id) ON DELETE SET NULL;
        COMMENT ON COLUMN sales.voided_by IS 'User who voided the sale';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'sales' AND column_name = 'voided_at'
    ) THEN
        ALTER TABLE sales ADD COLUMN voided_at TIMESTAMPTZ;
        COMMENT ON COLUMN sales.voided_at IS 'Timestamp when sale was voided';
    END IF;
END $$;

-- Add sale_date column (for easy date-based queries)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'sales' AND column_name = 'sale_date'
    ) THEN
        ALTER TABLE sales ADD COLUMN sale_date DATE;

        -- Populate existing records from created_at
        UPDATE sales SET sale_date = DATE(created_at) WHERE sale_date IS NULL;

        -- Make it NOT NULL after populating
        ALTER TABLE sales ALTER COLUMN sale_date SET NOT NULL;

        COMMENT ON COLUMN sales.sale_date IS 'Date portion of sale (denormalized for analytics)';

        -- Create index for date-based queries
        CREATE INDEX idx_sales_date ON sales(tenant_id, sale_date DESC);
    END IF;
END $$;

-- Add sale_time column (for hourly analysis)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'sales' AND column_name = 'sale_time'
    ) THEN
        ALTER TABLE sales ADD COLUMN sale_time TIME;

        -- Populate existing records from created_at
        UPDATE sales SET sale_time = created_at::TIME WHERE sale_time IS NULL;

        -- Make it NOT NULL after populating
        ALTER TABLE sales ALTER COLUMN sale_time SET NOT NULL;

        COMMENT ON COLUMN sales.sale_time IS 'Time portion of sale (for hourly pattern analysis)';
    END IF;
END $$;

-- Add completed_at column (if different from created_at)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'sales' AND column_name = 'completed_at'
    ) THEN
        ALTER TABLE sales ADD COLUMN completed_at TIMESTAMPTZ DEFAULT NOW();

        -- Populate existing records from created_at
        UPDATE sales SET completed_at = created_at WHERE completed_at IS NULL;

        -- Make it NOT NULL after populating
        ALTER TABLE sales ALTER COLUMN completed_at SET NOT NULL;

        COMMENT ON COLUMN sales.completed_at IS 'Timestamp when sale was completed';
    END IF;
END $$;

-- Create/update trigger to auto-populate sale_date and sale_time
CREATE OR REPLACE FUNCTION populate_sale_datetime()
RETURNS TRIGGER AS $$
BEGIN
    -- Set sale_date and sale_time from completed_at if not provided
    IF NEW.sale_date IS NULL THEN
        NEW.sale_date := DATE(NEW.completed_at);
    END IF;

    IF NEW.sale_time IS NULL THEN
        NEW.sale_time := NEW.completed_at::TIME;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop trigger if exists and recreate
DROP TRIGGER IF EXISTS trg_populate_sale_datetime ON sales;
CREATE TRIGGER trg_populate_sale_datetime
    BEFORE INSERT OR UPDATE ON sales
    FOR EACH ROW
    EXECUTE FUNCTION populate_sale_datetime();

COMMENT ON TRIGGER trg_populate_sale_datetime ON sales IS 'Auto-populates sale_date and sale_time from completed_at';


-- File: 015_enhance_sale_items_table.sql
-- ============================================
-- Migration: Enhance Sale Items Table for Analytics
-- Description: Add analytics columns to existing sale_items table
-- Created: 2026-01-23
-- ============================================

-- Add tenant_id column for RLS (critical for multi-tenant isolation)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'sale_items' AND column_name = 'tenant_id'
    ) THEN
        ALTER TABLE sale_items ADD COLUMN tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE;
        COMMENT ON COLUMN sale_items.tenant_id IS 'Tenant ID for multi-tenant RLS isolation';

        -- Populate tenant_id from sales table for existing records
        UPDATE sale_items si
        SET tenant_id = s.tenant_id
        FROM sales s
        WHERE si.sale_id = s.id
        AND si.tenant_id IS NULL;

        -- Make tenant_id NOT NULL after populating
        ALTER TABLE sale_items ALTER COLUMN tenant_id SET NOT NULL;

        -- Create index for RLS queries
        CREATE INDEX idx_sale_items_tenant ON sale_items(tenant_id);
    END IF;
END $$;

-- Add product snapshot columns
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'sale_items' AND column_name = 'product_name'
    ) THEN
        ALTER TABLE sale_items ADD COLUMN product_name VARCHAR(255);
        COMMENT ON COLUMN sale_items.product_name IS 'Product name snapshot at time of sale';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'sale_items' AND column_name = 'product_sku'
    ) THEN
        ALTER TABLE sale_items ADD COLUMN product_sku VARCHAR(100);
        COMMENT ON COLUMN sale_items.product_sku IS 'Product SKU snapshot at time of sale';
    END IF;
END $$;

-- Add brand tracking columns
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'sale_items' AND column_name = 'brand_id'
    ) THEN
        ALTER TABLE sale_items ADD COLUMN brand_id UUID REFERENCES brands(id) ON DELETE SET NULL;
        COMMENT ON COLUMN sale_items.brand_id IS 'Brand ID for brand comparison analytics';

        -- Create index for brand queries
        CREATE INDEX idx_sale_items_brand ON sale_items(brand_id, created_at DESC) WHERE brand_id IS NOT NULL;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'sale_items' AND column_name = 'brand_name'
    ) THEN
        ALTER TABLE sale_items ADD COLUMN brand_name VARCHAR(255);
        COMMENT ON COLUMN sale_items.brand_name IS 'Brand name snapshot at time of sale';
    END IF;
END $$;

-- Add category tracking columns
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'sale_items' AND column_name = 'category_id'
    ) THEN
        ALTER TABLE sale_items ADD COLUMN category_id UUID REFERENCES categories(id) ON DELETE SET NULL;
        COMMENT ON COLUMN sale_items.category_id IS 'Category ID for category analytics';

        -- Create index for category queries
        CREATE INDEX idx_sale_items_category ON sale_items(category_id, created_at DESC) WHERE category_id IS NOT NULL;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'sale_items' AND column_name = 'category_name'
    ) THEN
        ALTER TABLE sale_items ADD COLUMN category_name VARCHAR(255);
        COMMENT ON COLUMN sale_items.category_name IS 'Category name snapshot at time of sale';
    END IF;
END $$;

-- Add unit of measure
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'sale_items' AND column_name = 'unit_of_measure'
    ) THEN
        ALTER TABLE sale_items ADD COLUMN unit_of_measure VARCHAR(20) DEFAULT 'piece';
        COMMENT ON COLUMN sale_items.unit_of_measure IS 'Unit of measure: piece, kg, liter, meter, etc.';
    END IF;
END $$;

-- Add pricing detail columns
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'sale_items' AND column_name = 'original_price'
    ) THEN
        ALTER TABLE sale_items ADD COLUMN original_price DECIMAL(15,2);
        COMMENT ON COLUMN sale_items.original_price IS 'Original price before discount';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'sale_items' AND column_name = 'discount_percentage'
    ) THEN
        ALTER TABLE sale_items ADD COLUMN discount_percentage DECIMAL(5,2) DEFAULT 0;
        COMMENT ON COLUMN sale_items.discount_percentage IS 'Discount percentage applied';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'sale_items' AND column_name = 'discount_amount'
    ) THEN
        ALTER TABLE sale_items ADD COLUMN discount_amount DECIMAL(15,2) DEFAULT 0;
        COMMENT ON COLUMN sale_items.discount_amount IS 'Discount amount in currency';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'sale_items' AND column_name = 'tax_percentage'
    ) THEN
        ALTER TABLE sale_items ADD COLUMN tax_percentage DECIMAL(5,2) DEFAULT 0;
        COMMENT ON COLUMN sale_items.tax_percentage IS 'Tax percentage applied';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'sale_items' AND column_name = 'tax_amount'
    ) THEN
        ALTER TABLE sale_items ADD COLUMN tax_amount DECIMAL(15,2) DEFAULT 0;
        COMMENT ON COLUMN sale_items.tax_amount IS 'Tax amount in currency';
    END IF;
END $$;

-- Add cost and profit tracking columns
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'sale_items' AND column_name = 'unit_cost'
    ) THEN
        ALTER TABLE sale_items ADD COLUMN unit_cost DECIMAL(15,2);
        COMMENT ON COLUMN sale_items.unit_cost IS 'Cost of goods sold per unit';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'sale_items' AND column_name = 'total_cost'
    ) THEN
        ALTER TABLE sale_items ADD COLUMN total_cost DECIMAL(15,2);
        COMMENT ON COLUMN sale_items.total_cost IS 'Total cost (unit_cost * quantity)';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'sale_items' AND column_name = 'gross_profit'
    ) THEN
        ALTER TABLE sale_items ADD COLUMN gross_profit DECIMAL(15,2);
        COMMENT ON COLUMN sale_items.gross_profit IS 'Gross profit (line_total - total_cost)';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'sale_items' AND column_name = 'profit_margin'
    ) THEN
        ALTER TABLE sale_items ADD COLUMN profit_margin DECIMAL(5,2);
        COMMENT ON COLUMN sale_items.profit_margin IS 'Profit margin percentage';
    END IF;
END $$;

-- Add discount tracking columns
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'sale_items' AND column_name = 'discount_type'
    ) THEN
        ALTER TABLE sale_items ADD COLUMN discount_type VARCHAR(50);
        COMMENT ON COLUMN sale_items.discount_type IS 'Discount type: percentage, fixed_amount, promo_code, loyalty_points, bulk_discount';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'sale_items' AND column_name = 'discount_code'
    ) THEN
        ALTER TABLE sale_items ADD COLUMN discount_code VARCHAR(50);
        COMMENT ON COLUMN sale_items.discount_code IS 'Promo/discount code applied';
    END IF;
END $$;

-- Create/update trigger to auto-populate sale item details
CREATE OR REPLACE FUNCTION populate_sale_item_details()
RETURNS TRIGGER AS $$
DECLARE
    v_product RECORD;
    v_sale RECORD;
BEGIN
    -- Get tenant_id from sales table if not set
    IF NEW.tenant_id IS NULL THEN
        SELECT tenant_id INTO NEW.tenant_id
        FROM sales
        WHERE id = NEW.sale_id;
    END IF;

    -- Get product details if not already set
    IF NEW.product_name IS NULL OR NEW.product_sku IS NULL THEN
        SELECT
            p.name,
            p.sku,
            p.brand_id,
            b.name as brand_name,
            p.category_id,
            c.name as category_name,
            p.cost_price,
            p.unit_of_measure
        INTO v_product
        FROM products p
        LEFT JOIN brands b ON b.id = p.brand_id
        LEFT JOIN categories c ON c.id = p.category_id
        WHERE p.id = NEW.product_id;

        -- Populate snapshot fields
        NEW.product_name := COALESCE(NEW.product_name, v_product.name);
        NEW.product_sku := COALESCE(NEW.product_sku, v_product.sku);
        NEW.brand_id := COALESCE(NEW.brand_id, v_product.brand_id);
        NEW.brand_name := COALESCE(NEW.brand_name, v_product.brand_name);
        NEW.category_id := COALESCE(NEW.category_id, v_product.category_id);
        NEW.category_name := COALESCE(NEW.category_name, v_product.category_name);
        NEW.unit_of_measure := COALESCE(NEW.unit_of_measure, v_product.unit_of_measure, 'piece');

        -- Calculate cost and profit if unit_cost provided
        IF NEW.unit_cost IS NOT NULL THEN
            NEW.total_cost := NEW.unit_cost * NEW.quantity;
            NEW.gross_profit := NEW.line_total - NEW.total_cost;
            IF NEW.line_total > 0 THEN
                NEW.profit_margin := (NEW.gross_profit / NEW.line_total) * 100;
            END IF;
        ELSIF v_product.cost_price IS NOT NULL THEN
            NEW.unit_cost := v_product.cost_price;
            NEW.total_cost := v_product.cost_price * NEW.quantity;
            NEW.gross_profit := NEW.line_total - NEW.total_cost;
            IF NEW.line_total > 0 THEN
                NEW.profit_margin := (NEW.gross_profit / NEW.line_total) * 100;
            END IF;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop trigger if exists and recreate
DROP TRIGGER IF EXISTS trg_populate_sale_item_details ON sale_items;
CREATE TRIGGER trg_populate_sale_item_details
    BEFORE INSERT OR UPDATE ON sale_items
    FOR EACH ROW
    EXECUTE FUNCTION populate_sale_item_details();

COMMENT ON TRIGGER trg_populate_sale_item_details ON sale_items IS 'Auto-populates product snapshot details and calculates profit';


-- File: 016_create_brands_categories.sql
-- ============================================
-- Migration: Create Brands and Categories Tables
-- Description: Add brands and categories for product classification
-- Created: 2026-01-23
-- ============================================

-- ============================================
-- BRANDS TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS brands (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,

    name VARCHAR(255) NOT NULL,
    code VARCHAR(50),
    description TEXT,
    logo_url TEXT,

    -- Brand classification
    tier VARCHAR(20), -- premium, mid-range, budget
    is_house_brand BOOLEAN DEFAULT false,

    -- Metadata
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(tenant_id, name)
);

-- Indexes for brands
CREATE INDEX IF NOT EXISTS idx_brands_tenant ON brands(tenant_id) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_brands_active ON brands(is_active, tenant_id);
CREATE INDEX IF NOT EXISTS idx_brands_name ON brands(tenant_id, name);

-- RLS for brands
ALTER TABLE brands ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view brands in their tenant" ON brands;
CREATE POLICY "Users can view brands in their tenant"
    ON brands FOR SELECT
    USING (tenant_id IN (SELECT tenant_id FROM users WHERE id = auth.uid()));

DROP POLICY IF EXISTS "Managers can insert brands" ON brands;
CREATE POLICY "Managers can insert brands"
    ON brands FOR INSERT
    WITH CHECK (
        tenant_id IN (
            SELECT tenant_id FROM users
            WHERE id = auth.uid()
            AND role IN ('tenant_admin', 'branch_manager')
        )
    );

DROP POLICY IF EXISTS "Managers can update brands" ON brands;
CREATE POLICY "Managers can update brands"
    ON brands FOR UPDATE
    USING (
        tenant_id IN (
            SELECT tenant_id FROM users
            WHERE id = auth.uid()
            AND role IN ('tenant_admin', 'branch_manager')
        )
    );

DROP POLICY IF EXISTS "Managers can delete brands" ON brands;
CREATE POLICY "Managers can delete brands"
    ON brands FOR DELETE
    USING (
        tenant_id IN (
            SELECT tenant_id FROM users
            WHERE id = auth.uid()
            AND role IN ('tenant_admin', 'branch_manager')
        )
    );

-- Trigger to update updated_at
DROP TRIGGER IF EXISTS set_updated_at ON brands;
CREATE TRIGGER set_updated_at
    BEFORE UPDATE ON brands
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();

COMMENT ON TABLE brands IS 'Product brands for brand comparison analytics';
COMMENT ON COLUMN brands.tier IS 'Brand tier: premium, mid-range, budget';
COMMENT ON COLUMN brands.is_house_brand IS 'True if this is the store''s own brand';

-- ============================================
-- CATEGORIES TABLE (Hierarchical)
-- ============================================

CREATE TABLE IF NOT EXISTS categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,

    name VARCHAR(255) NOT NULL,
    code VARCHAR(50),
    parent_category_id UUID REFERENCES categories(id) ON DELETE SET NULL,

    -- Category hierarchy
    level INTEGER DEFAULT 1, -- 1=main, 2=sub, 3=sub-sub
    path TEXT, -- Materialized path: /Electronics/Phones/Smartphones/

    description TEXT,
    sort_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(tenant_id, name, parent_category_id)
);

-- Indexes for categories
CREATE INDEX IF NOT EXISTS idx_categories_tenant ON categories(tenant_id) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_categories_parent ON categories(parent_category_id) WHERE parent_category_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_categories_level ON categories(tenant_id, level);
CREATE INDEX IF NOT EXISTS idx_categories_active ON categories(is_active, tenant_id);

-- RLS for categories
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view categories in their tenant" ON categories;
CREATE POLICY "Users can view categories in their tenant"
    ON categories FOR SELECT
    USING (tenant_id IN (SELECT tenant_id FROM users WHERE id = auth.uid()));

DROP POLICY IF EXISTS "Managers can manage categories" ON categories;
CREATE POLICY "Managers can manage categories"
    ON categories FOR ALL
    USING (
        tenant_id IN (
            SELECT tenant_id FROM users
            WHERE id = auth.uid()
            AND role IN ('tenant_admin', 'branch_manager')
        )
    );

-- Trigger to update updated_at
DROP TRIGGER IF EXISTS set_updated_at ON categories;
CREATE TRIGGER set_updated_at
    BEFORE UPDATE ON categories
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();

-- Trigger to auto-populate category path
CREATE OR REPLACE FUNCTION update_category_path()
RETURNS TRIGGER AS $$
DECLARE
    v_parent_path TEXT;
BEGIN
    IF NEW.parent_category_id IS NULL THEN
        NEW.path := '/' || NEW.name || '/';
        NEW.level := 1;
    ELSE
        SELECT path, level INTO v_parent_path, NEW.level
        FROM categories
        WHERE id = NEW.parent_category_id;

        NEW.path := v_parent_path || NEW.name || '/';
        NEW.level := NEW.level + 1;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_update_category_path ON categories;
CREATE TRIGGER trg_update_category_path
    BEFORE INSERT OR UPDATE ON categories
    FOR EACH ROW
    EXECUTE FUNCTION update_category_path();

COMMENT ON TABLE categories IS 'Hierarchical product categories';
COMMENT ON COLUMN categories.level IS 'Hierarchy level: 1=main, 2=sub, 3=sub-sub';
COMMENT ON COLUMN categories.path IS 'Materialized path for efficient hierarchy queries';

-- ============================================
-- ENHANCE PRODUCTS TABLE
-- ============================================

-- Add brand_id and category_id to products if not exists
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'products' AND column_name = 'brand_id'
    ) THEN
        ALTER TABLE products ADD COLUMN brand_id UUID REFERENCES brands(id) ON DELETE SET NULL;
        COMMENT ON COLUMN products.brand_id IS 'Brand classification for analytics';

        -- Create index
        CREATE INDEX idx_products_brand ON products(brand_id) WHERE brand_id IS NOT NULL;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'products' AND column_name = 'category_id'
    ) THEN
        ALTER TABLE products ADD COLUMN category_id UUID REFERENCES categories(id) ON DELETE SET NULL;
        COMMENT ON COLUMN products.category_id IS 'Category classification for analytics';

        -- Create index
        CREATE INDEX idx_products_category ON products(category_id) WHERE category_id IS NOT NULL;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'products' AND column_name = 'cost_price'
    ) THEN
        ALTER TABLE products ADD COLUMN cost_price DECIMAL(15,2);
        COMMENT ON COLUMN products.cost_price IS 'Cost of goods sold (for profit calculation)';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'products' AND column_name = 'unit_of_measure'
    ) THEN
        ALTER TABLE products ADD COLUMN unit_of_measure VARCHAR(20) DEFAULT 'piece';
        COMMENT ON COLUMN products.unit_of_measure IS 'Unit of measure: piece, kg, liter, meter, etc.';
    END IF;
END $$;

-- ============================================
-- PRODUCT PRICE HISTORY (SCD Type 2)
-- ============================================

CREATE TABLE IF NOT EXISTS product_price_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,

    cost_price DECIMAL(15,2),
    selling_price DECIMAL(15,2) NOT NULL,

    -- Price change tracking
    price_change_reason VARCHAR(100),
    changed_by UUID REFERENCES users(id) ON DELETE SET NULL,

    -- Validity period (SCD Type 2)
    valid_from TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    valid_to TIMESTAMPTZ,
    is_current BOOLEAN DEFAULT true,

    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for price history
CREATE INDEX IF NOT EXISTS idx_price_history_product ON product_price_history(product_id, valid_from DESC);
CREATE INDEX IF NOT EXISTS idx_price_history_current ON product_price_history(product_id, is_current) WHERE is_current = true;
CREATE INDEX IF NOT EXISTS idx_price_history_tenant ON product_price_history(tenant_id, created_at DESC);

-- RLS for price history
ALTER TABLE product_price_history ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view price history in their tenant" ON product_price_history;
CREATE POLICY "Users can view price history in their tenant"
    ON product_price_history FOR SELECT
    USING (tenant_id IN (SELECT tenant_id FROM users WHERE id = auth.uid()));

DROP POLICY IF EXISTS "Managers can manage price history" ON product_price_history;
CREATE POLICY "Managers can manage price history"
    ON product_price_history FOR ALL
    USING (
        tenant_id IN (
            SELECT tenant_id FROM users
            WHERE id = auth.uid()
            AND role IN ('tenant_admin', 'branch_manager')
        )
    );

-- Trigger to track price changes
CREATE OR REPLACE FUNCTION track_product_price_change()
RETURNS TRIGGER AS $$
BEGIN
    -- If price changed, archive old price and create new history entry
    IF (OLD.selling_price IS DISTINCT FROM NEW.selling_price) OR
       (OLD.cost_price IS DISTINCT FROM NEW.cost_price) THEN

        -- Mark old price as no longer current
        UPDATE product_price_history
        SET is_current = false,
            valid_to = NOW()
        WHERE product_id = NEW.id
          AND is_current = true;

        -- Insert new price history
        INSERT INTO product_price_history (
            product_id,
            tenant_id,
            cost_price,
            selling_price,
            price_change_reason,
            changed_by,
            valid_from,
            is_current
        ) VALUES (
            NEW.id,
            NEW.tenant_id,
            NEW.cost_price,
            NEW.selling_price,
            'price_update',
            auth.uid(),
            NOW(),
            true
        );
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_track_product_price_change ON products;
CREATE TRIGGER trg_track_product_price_change
    AFTER UPDATE ON products
    FOR EACH ROW
    EXECUTE FUNCTION track_product_price_change();

COMMENT ON TABLE product_price_history IS 'Tracks product price changes over time (SCD Type 2)';
COMMENT ON COLUMN product_price_history.is_current IS 'True if this is the current active price';


-- File: 017_analytics_dimensions.sql
-- ============================================
-- Migration: Analytics Dimension Tables
-- Description: Create dim_date and dim_time for analytics
-- Created: 2026-01-23
-- ============================================

-- ============================================
-- DATE DIMENSION TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS dim_date (
    date_key INTEGER PRIMARY KEY,
    date_value DATE NOT NULL UNIQUE,

    -- Date components
    day INTEGER NOT NULL,
    day_of_week INTEGER NOT NULL,
    day_of_week_name VARCHAR(10) NOT NULL,
    day_of_year INTEGER NOT NULL,

    -- Week
    week_of_year INTEGER NOT NULL,
    week_start_date DATE NOT NULL,
    week_end_date DATE NOT NULL,

    -- Month
    month INTEGER NOT NULL,
    month_name VARCHAR(10) NOT NULL,
    month_abbr VARCHAR(3) NOT NULL,
    month_start_date DATE NOT NULL,
    month_end_date DATE NOT NULL,

    -- Quarter
    quarter INTEGER NOT NULL,
    quarter_name VARCHAR(10) NOT NULL,
    quarter_start_date DATE NOT NULL,
    quarter_end_date DATE NOT NULL,

    -- Year
    year INTEGER NOT NULL,
    year_start_date DATE NOT NULL,
    year_end_date DATE NOT NULL,

    -- Fiscal periods
    fiscal_year INTEGER,
    fiscal_quarter INTEGER,
    fiscal_month INTEGER,

    -- Business flags
    is_weekend BOOLEAN NOT NULL,
    is_holiday BOOLEAN DEFAULT false,
    holiday_name VARCHAR(100),
    is_business_day BOOLEAN NOT NULL,

    -- Prior period references
    prior_day_key INTEGER,
    prior_week_key INTEGER,
    prior_month_key INTEGER,
    prior_quarter_key INTEGER,
    prior_year_key INTEGER,

    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for dim_date
CREATE INDEX IF NOT EXISTS idx_dim_date_value ON dim_date(date_value);
CREATE INDEX IF NOT EXISTS idx_dim_date_month ON dim_date(year, month);
CREATE INDEX IF NOT EXISTS idx_dim_date_quarter ON dim_date(year, quarter);
CREATE INDEX IF NOT EXISTS idx_dim_date_year ON dim_date(year);
CREATE INDEX IF NOT EXISTS idx_dim_date_day_of_week ON dim_date(day_of_week);
CREATE INDEX IF NOT EXISTS idx_dim_date_is_business_day ON dim_date(is_business_day);
CREATE INDEX IF NOT EXISTS idx_dim_date_is_weekend ON dim_date(is_weekend);

COMMENT ON TABLE dim_date IS 'Calendar dimension for time-based analysis';
COMMENT ON COLUMN dim_date.date_key IS 'Primary key in YYYYMMDD format';
COMMENT ON COLUMN dim_date.is_business_day IS 'True if not weekend and not holiday';

-- ============================================
-- TIME DIMENSION TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS dim_time (
    time_key INTEGER PRIMARY KEY,
    time_value TIME NOT NULL UNIQUE,

    -- Time components
    hour INTEGER NOT NULL,
    hour_12 INTEGER NOT NULL,
    am_pm VARCHAR(2) NOT NULL,
    minute INTEGER NOT NULL,
    second INTEGER NOT NULL,

    -- Time periods
    time_period VARCHAR(20) NOT NULL,
    business_hour VARCHAR(20) NOT NULL,

    -- Analytics groupings
    hour_bucket INTEGER NOT NULL,
    minute_bucket INTEGER NOT NULL,

    is_peak_hour BOOLEAN DEFAULT false,

    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for dim_time
CREATE INDEX IF NOT EXISTS idx_dim_time_hour ON dim_time(hour);
CREATE INDEX IF NOT EXISTS idx_dim_time_period ON dim_time(time_period);
CREATE INDEX IF NOT EXISTS idx_dim_time_peak ON dim_time(is_peak_hour) WHERE is_peak_hour = true;

COMMENT ON TABLE dim_time IS 'Time dimension for hourly pattern analysis';
COMMENT ON COLUMN dim_time.time_key IS 'Primary key in HHMMSS format';
COMMENT ON COLUMN dim_time.time_period IS 'Time period: morning, afternoon, evening, night';
COMMENT ON COLUMN dim_time.business_hour IS 'Business hour category: pre-open, business, lunch, post-close';


-- File: 018_analytics_fact_tables.sql
-- ============================================
-- Migration: Analytics Fact Tables (Partitioned)
-- Description: Create partitioned fact tables for analytics
-- Created: 2026-01-23
-- ============================================

-- ============================================
-- FACT: DAILY SALES SUMMARY
-- ============================================

CREATE TABLE IF NOT EXISTS fact_daily_sales (
    id UUID DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE CASCADE,

    -- Date dimension
    date_key INTEGER NOT NULL REFERENCES dim_date(date_key),
    sale_date DATE NOT NULL,

    -- Aggregated metrics
    total_transactions INTEGER DEFAULT 0,
    total_items_sold DECIMAL(15,3) DEFAULT 0,
    total_revenue DECIMAL(15,2) DEFAULT 0,
    total_cost DECIMAL(15,2) DEFAULT 0,
    total_profit DECIMAL(15,2) DEFAULT 0,
    average_transaction_value DECIMAL(15,2) DEFAULT 0,
    average_profit_margin DECIMAL(5,2) DEFAULT 0,

    -- Customer metrics
    unique_customers INTEGER DEFAULT 0,
    new_customers INTEGER DEFAULT 0,
    returning_customers INTEGER DEFAULT 0,

    -- Payment method breakdown
    cash_transactions INTEGER DEFAULT 0,
    cash_revenue DECIMAL(15,2) DEFAULT 0,
    card_transactions INTEGER DEFAULT 0,
    card_revenue DECIMAL(15,2) DEFAULT 0,
    transfer_transactions INTEGER DEFAULT 0,
    transfer_revenue DECIMAL(15,2) DEFAULT 0,

    -- Refund metrics
    void_transactions INTEGER DEFAULT 0,
    void_amount DECIMAL(15,2) DEFAULT 0,
    refund_transactions INTEGER DEFAULT 0,
    refund_amount DECIMAL(15,2) DEFAULT 0,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    PRIMARY KEY (tenant_id, branch_id, date_key, sale_date)
) PARTITION BY RANGE (sale_date);

-- RLS for fact_daily_sales
ALTER TABLE fact_daily_sales ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view daily sales in their tenant" ON fact_daily_sales;
CREATE POLICY "Users can view daily sales in their tenant"
    ON fact_daily_sales FOR SELECT
    USING (tenant_id IN (SELECT tenant_id FROM users WHERE id = auth.uid()));

COMMENT ON TABLE fact_daily_sales IS 'Daily aggregated sales metrics by branch';

-- ============================================
-- FACT: PRODUCT SALES SUMMARY
-- ============================================

CREATE TABLE IF NOT EXISTS fact_product_sales (
    id UUID DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE CASCADE,

    -- Dimensions
    date_key INTEGER NOT NULL REFERENCES dim_date(date_key),
    sale_date DATE NOT NULL,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    brand_id UUID REFERENCES brands(id),
    category_id UUID REFERENCES categories(id),

    -- Product snapshot
    product_name VARCHAR(255) NOT NULL,
    product_sku VARCHAR(100),
    brand_name VARCHAR(255),
    category_name VARCHAR(255),

    -- Aggregated metrics
    quantity_sold DECIMAL(15,3) DEFAULT 0,
    total_revenue DECIMAL(15,2) DEFAULT 0,
    total_cost DECIMAL(15,2) DEFAULT 0,
    total_profit DECIMAL(15,2) DEFAULT 0,
    average_unit_price DECIMAL(15,2) DEFAULT 0,
    average_profit_margin DECIMAL(5,2) DEFAULT 0,

    -- Transaction metrics
    transaction_count INTEGER DEFAULT 0,

    -- Discount metrics
    total_discount_amount DECIMAL(15,2) DEFAULT 0,
    average_discount_percentage DECIMAL(5,2) DEFAULT 0,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    PRIMARY KEY (tenant_id, branch_id, date_key, product_id, sale_date)
) PARTITION BY RANGE (sale_date);

-- RLS for fact_product_sales
ALTER TABLE fact_product_sales ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view product sales in their tenant" ON fact_product_sales;
CREATE POLICY "Users can view product sales in their tenant"
    ON fact_product_sales FOR SELECT
    USING (tenant_id IN (SELECT tenant_id FROM users WHERE id = auth.uid()));

COMMENT ON TABLE fact_product_sales IS 'Daily product-level sales metrics';

-- ============================================
-- FACT: STAFF SALES PERFORMANCE
-- ============================================

CREATE TABLE IF NOT EXISTS fact_staff_sales (
    id UUID DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE CASCADE,

    -- Dimensions
    date_key INTEGER NOT NULL REFERENCES dim_date(date_key),
    sale_date DATE NOT NULL,
    staff_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    staff_role VARCHAR(50),

    -- Staff info snapshot
    staff_name VARCHAR(255) NOT NULL,

    -- Aggregated metrics
    total_transactions INTEGER DEFAULT 0,
    total_items_sold DECIMAL(15,3) DEFAULT 0,
    total_revenue DECIMAL(15,2) DEFAULT 0,
    total_profit DECIMAL(15,2) DEFAULT 0,
    average_transaction_value DECIMAL(15,2) DEFAULT 0,

    -- Performance metrics
    average_transaction_time INTERVAL,
    transactions_per_hour DECIMAL(5,2) DEFAULT 0,

    -- Commission calculation
    commission_eligible_sales DECIMAL(15,2) DEFAULT 0,
    commission_amount DECIMAL(15,2) DEFAULT 0,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    PRIMARY KEY (tenant_id, branch_id, date_key, staff_id, staff_role, sale_date)
) PARTITION BY RANGE (sale_date);

-- RLS for fact_staff_sales
ALTER TABLE fact_staff_sales ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view staff sales in their tenant" ON fact_staff_sales;
CREATE POLICY "Users can view staff sales in their tenant"
    ON fact_staff_sales FOR SELECT
    USING (tenant_id IN (SELECT tenant_id FROM users WHERE id = auth.uid()));

COMMENT ON TABLE fact_staff_sales IS 'Daily staff performance metrics';

-- ============================================
-- FACT: BRAND SALES PERFORMANCE
-- ============================================

CREATE TABLE IF NOT EXISTS fact_brand_sales (
    id UUID DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE CASCADE,

    -- Dimensions
    date_key INTEGER NOT NULL REFERENCES dim_date(date_key),
    sale_date DATE NOT NULL,
    brand_id UUID NOT NULL REFERENCES brands(id) ON DELETE CASCADE,
    category_id UUID REFERENCES categories(id),

    -- Brand snapshot
    brand_name VARCHAR(255) NOT NULL,
    category_name VARCHAR(255),

    -- Aggregated metrics
    unique_products_sold INTEGER DEFAULT 0,
    quantity_sold DECIMAL(15,3) DEFAULT 0,
    total_revenue DECIMAL(15,2) DEFAULT 0,
    total_cost DECIMAL(15,2) DEFAULT 0,
    total_profit DECIMAL(15,2) DEFAULT 0,
    average_profit_margin DECIMAL(5,2) DEFAULT 0,

    -- Transaction metrics
    transaction_count INTEGER DEFAULT 0,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    PRIMARY KEY (tenant_id, branch_id, date_key, brand_id, sale_date)
) PARTITION BY RANGE (sale_date);

-- RLS for fact_brand_sales
ALTER TABLE fact_brand_sales ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view brand sales in their tenant" ON fact_brand_sales;
CREATE POLICY "Users can view brand sales in their tenant"
    ON fact_brand_sales FOR SELECT
    USING (tenant_id IN (SELECT tenant_id FROM users WHERE id = auth.uid()));

COMMENT ON TABLE fact_brand_sales IS 'Daily brand performance metrics';

-- ============================================
-- FACT: HOURLY SALES PATTERN
-- ============================================

CREATE TABLE IF NOT EXISTS fact_hourly_sales (
    id UUID DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE CASCADE,

    -- Dimensions
    date_key INTEGER NOT NULL REFERENCES dim_date(date_key),
    time_key INTEGER NOT NULL REFERENCES dim_time(time_key),
    sale_date DATE NOT NULL,
    hour INTEGER NOT NULL,

    -- Aggregated metrics
    total_transactions INTEGER DEFAULT 0,
    total_revenue DECIMAL(15,2) DEFAULT 0,
    average_transaction_value DECIMAL(15,2) DEFAULT 0,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    PRIMARY KEY (tenant_id, branch_id, date_key, time_key, sale_date)
) PARTITION BY RANGE (sale_date);

-- RLS for fact_hourly_sales
ALTER TABLE fact_hourly_sales ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view hourly sales in their tenant" ON fact_hourly_sales;
CREATE POLICY "Users can view hourly sales in their tenant"
    ON fact_hourly_sales FOR SELECT
    USING (tenant_id IN (SELECT tenant_id FROM users WHERE id = auth.uid()));

COMMENT ON TABLE fact_hourly_sales IS 'Hourly sales patterns';


-- File: 019_rls_helper_functions.sql
-- ============================================
-- Migration: RLS Helper Functions
-- Description: Helper functions for Row Level Security policies
-- Created: 2026-01-23
-- ============================================

-- ============================================
-- DROP EXISTING FUNCTIONS (if they exist)
-- ============================================

DROP FUNCTION IF EXISTS current_tenant_id() CASCADE;
DROP FUNCTION IF EXISTS current_user_role() CASCADE;
DROP FUNCTION IF EXISTS current_user_branch_id() CASCADE;
DROP FUNCTION IF EXISTS has_permission(TEXT) CASCADE;
DROP FUNCTION IF EXISTS is_in_tenant(UUID) CASCADE;
DROP FUNCTION IF EXISTS can_access_branch(UUID) CASCADE;
DROP FUNCTION IF EXISTS can_manage_users() CASCADE;
DROP FUNCTION IF EXISTS can_manage_products() CASCADE;
DROP FUNCTION IF EXISTS can_view_reports() CASCADE;
DROP FUNCTION IF EXISTS can_void_sales() CASCADE;
DROP FUNCTION IF EXISTS get_accessible_branches() CASCADE;
DROP FUNCTION IF EXISTS log_audit_event(TEXT, TEXT, UUID, JSONB, JSONB) CASCADE;

-- ============================================
-- 1. GET CURRENT TENANT ID
-- ============================================

CREATE OR REPLACE FUNCTION current_tenant_id()
RETURNS UUID AS $$
DECLARE
    v_tenant_id UUID;
BEGIN
    -- Get tenant_id from the authenticated user
    SELECT tenant_id INTO v_tenant_id
    FROM users
    WHERE id = auth.uid();

    RETURN v_tenant_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

COMMENT ON FUNCTION current_tenant_id() IS 'Returns the tenant_id of the currently authenticated user';

-- ============================================
-- 2. GET CURRENT USER ROLE
-- ============================================

CREATE OR REPLACE FUNCTION current_user_role()
RETURNS TEXT AS $$
DECLARE
    v_role TEXT;
BEGIN
    -- Get role from the authenticated user
    SELECT role INTO v_role
    FROM users
    WHERE id = auth.uid();

    RETURN v_role;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

COMMENT ON FUNCTION current_user_role() IS 'Returns the role of the currently authenticated user';

-- ============================================
-- 3. GET CURRENT USER BRANCH ID
-- ============================================

CREATE OR REPLACE FUNCTION current_user_branch_id()
RETURNS UUID AS $$
DECLARE
    v_branch_id UUID;
BEGIN
    -- Get branch_id from the authenticated user
    SELECT branch_id INTO v_branch_id
    FROM users
    WHERE id = auth.uid();

    RETURN v_branch_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

COMMENT ON FUNCTION current_user_branch_id() IS 'Returns the branch_id of the currently authenticated user';

-- ============================================
-- 4. CHECK IF USER HAS PERMISSION
-- ============================================

CREATE OR REPLACE FUNCTION has_permission(required_role TEXT)
RETURNS BOOLEAN AS $$
DECLARE
    v_user_role TEXT;
    v_role_hierarchy INTEGER;
    v_required_hierarchy INTEGER;
BEGIN
    -- Get current user's role
    v_user_role := current_user_role();

    -- Define role hierarchy (higher number = more permissions)
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

COMMENT ON FUNCTION has_permission(TEXT) IS 'Checks if current user has required permission level';

-- ============================================
-- 5. CHECK IF USER IS IN TENANT
-- ============================================

CREATE OR REPLACE FUNCTION is_in_tenant(check_tenant_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN check_tenant_id = current_tenant_id();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

COMMENT ON FUNCTION is_in_tenant(UUID) IS 'Checks if provided tenant_id matches current user''s tenant';

-- ============================================
-- 6. CHECK IF USER CAN ACCESS BRANCH
-- ============================================

CREATE OR REPLACE FUNCTION can_access_branch(check_branch_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    v_user_role TEXT;
    v_user_branch_id UUID;
    v_tenant_id UUID;
    v_branch_tenant_id UUID;
BEGIN
    v_user_role := current_user_role();
    v_user_branch_id := current_user_branch_id();
    v_tenant_id := current_tenant_id();

    -- Super admins and tenant admins can access all branches in their tenant
    IF v_user_role IN ('super_admin', 'tenant_admin') THEN
        -- Check if branch belongs to user's tenant
        SELECT tenant_id INTO v_branch_tenant_id
        FROM branches
        WHERE id = check_branch_id;

        RETURN v_branch_tenant_id = v_tenant_id;
    ELSE
        -- Other roles can only access their assigned branch
        RETURN check_branch_id = v_user_branch_id OR v_user_branch_id IS NULL;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

COMMENT ON FUNCTION can_access_branch(UUID) IS 'Checks if current user can access the specified branch';

-- ============================================
-- 7. CHECK IF USER CAN MANAGE USERS
-- ============================================

CREATE OR REPLACE FUNCTION can_manage_users()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN current_user_role() IN ('super_admin', 'tenant_admin', 'branch_manager');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

COMMENT ON FUNCTION can_manage_users() IS 'Checks if current user can manage other users';

-- ============================================
-- 8. CHECK IF USER CAN MANAGE PRODUCTS
-- ============================================

CREATE OR REPLACE FUNCTION can_manage_products()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN current_user_role() IN ('super_admin', 'tenant_admin', 'branch_manager');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

COMMENT ON FUNCTION can_manage_products() IS 'Checks if current user can manage products';

-- ============================================
-- 9. CHECK IF USER CAN VIEW REPORTS
-- ============================================

CREATE OR REPLACE FUNCTION can_view_reports()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN current_user_role() IN ('super_admin', 'tenant_admin', 'branch_manager');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

COMMENT ON FUNCTION can_view_reports() IS 'Checks if current user can view analytics reports';

-- ============================================
-- 10. CHECK IF USER CAN VOID SALES
-- ============================================

CREATE OR REPLACE FUNCTION can_void_sales()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN current_user_role() IN ('super_admin', 'tenant_admin', 'branch_manager');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

COMMENT ON FUNCTION can_void_sales() IS 'Checks if current user can void sales transactions';

-- ============================================
-- 11. GET USER'S ACCESSIBLE BRANCHES
-- ============================================

CREATE OR REPLACE FUNCTION get_accessible_branches()
RETURNS SETOF UUID AS $$
DECLARE
    v_user_role TEXT;
    v_tenant_id UUID;
    v_user_branch_id UUID;
BEGIN
    v_user_role := current_user_role();
    v_tenant_id := current_tenant_id();
    v_user_branch_id := current_user_branch_id();

    -- Super admins and tenant admins can access all branches in their tenant
    IF v_user_role IN ('super_admin', 'tenant_admin') THEN
        RETURN QUERY
        SELECT id FROM branches WHERE tenant_id = v_tenant_id;
    ELSE
        -- Other roles can only access their assigned branch
        IF v_user_branch_id IS NOT NULL THEN
            RETURN QUERY SELECT v_user_branch_id;
        END IF;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

COMMENT ON FUNCTION get_accessible_branches() IS 'Returns UUIDs of branches accessible to current user';

-- ============================================
-- 12. AUDIT LOG FUNCTION
-- ============================================

CREATE OR REPLACE FUNCTION log_audit_event(
    p_table_name TEXT,
    p_operation TEXT,
    p_record_id UUID,
    p_old_data JSONB DEFAULT NULL,
    p_new_data JSONB DEFAULT NULL
)
RETURNS VOID AS $$
BEGIN
    -- Create audit_logs table if it doesn't exist
    CREATE TABLE IF NOT EXISTS audit_logs (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        tenant_id UUID NOT NULL,
        user_id UUID NOT NULL,
        table_name TEXT NOT NULL,
        operation TEXT NOT NULL, -- INSERT, UPDATE, DELETE
        record_id UUID NOT NULL,
        old_data JSONB,
        new_data JSONB,
        ip_address INET,
        user_agent TEXT,
        created_at TIMESTAMPTZ DEFAULT NOW()
    );

    INSERT INTO audit_logs (
        tenant_id,
        user_id,
        table_name,
        operation,
        record_id,
        old_data,
        new_data
    ) VALUES (
        current_tenant_id(),
        auth.uid(),
        p_table_name,
        p_operation,
        p_record_id,
        p_old_data,
        p_new_data
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION log_audit_event IS 'Logs audit events for critical operations';

-- ============================================
-- GRANT EXECUTE PERMISSIONS
-- ============================================

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION current_tenant_id() TO authenticated;
GRANT EXECUTE ON FUNCTION current_user_role() TO authenticated;
GRANT EXECUTE ON FUNCTION current_user_branch_id() TO authenticated;
GRANT EXECUTE ON FUNCTION has_permission(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION is_in_tenant(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION can_access_branch(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION can_manage_users() TO authenticated;
GRANT EXECUTE ON FUNCTION can_manage_products() TO authenticated;
GRANT EXECUTE ON FUNCTION can_view_reports() TO authenticated;
GRANT EXECUTE ON FUNCTION can_void_sales() TO authenticated;
GRANT EXECUTE ON FUNCTION get_accessible_branches() TO authenticated;
GRANT EXECUTE ON FUNCTION log_audit_event(TEXT, TEXT, UUID, JSONB, JSONB) TO authenticated;


-- File: 020_enable_rls_policies.sql
-- ============================================
-- Migration: Enable RLS and Create Policies
-- Description: Enable Row Level Security on all tenant-scoped tables
-- Created: 2026-01-23
-- Note: This migration assumes core tables already exist
-- ============================================

-- ============================================
-- ENABLE RLS ON ALL TENANT-SCOPED TABLES
-- ============================================

-- Core tables
ALTER TABLE IF EXISTS tenants ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS branches ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS users ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS products ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS sales ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS sale_items ENABLE ROW LEVEL SECURITY;

-- ============================================
-- TENANTS TABLE POLICIES
-- ============================================

-- Users can only see their own tenant
DROP POLICY IF EXISTS "Users can view their own tenant" ON tenants;
CREATE POLICY "Users can view their own tenant"
    ON tenants FOR SELECT
    USING (id = current_tenant_id());

-- Only owners can update tenant settings
DROP POLICY IF EXISTS "Owners can update tenant" ON tenants;
CREATE POLICY "Owners can update tenant"
    ON tenants FOR UPDATE
    USING (id = current_tenant_id() AND current_user_role() = 'tenant_admin');

-- ============================================
-- BRANCHES TABLE POLICIES
-- ============================================

-- Users can view branches in their tenant
DROP POLICY IF EXISTS "Users can view branches in their tenant" ON branches;
CREATE POLICY "Users can view branches in their tenant"
    ON branches FOR SELECT
    USING (tenant_id = current_tenant_id());

-- Owners and admins can manage branches
DROP POLICY IF EXISTS "Admins can manage branches" ON branches;
CREATE POLICY "Admins can manage branches"
    ON branches FOR ALL
    USING (
        tenant_id = current_tenant_id() AND
        current_user_role() IN ('super_admin', 'tenant_admin')
    );

-- ============================================
-- USERS TABLE POLICIES
-- ============================================

-- Users can view other users in their tenant
DROP POLICY IF EXISTS "Users can view users in their tenant" ON users;
CREATE POLICY "Users can view users in their tenant"
    ON users FOR SELECT
    USING (tenant_id = current_tenant_id());

-- Users can update their own profile
DROP POLICY IF EXISTS "Users can update own profile" ON users;
CREATE POLICY "Users can update own profile"
    ON users FOR UPDATE
    USING (id = auth.uid());

-- Managers can create users in their tenant
DROP POLICY IF EXISTS "Managers can create users" ON users;
CREATE POLICY "Managers can create users"
    ON users FOR INSERT
    WITH CHECK (
        tenant_id = current_tenant_id() AND
        can_manage_users()
    );

-- Managers can update users in their tenant
DROP POLICY IF EXISTS "Managers can update users" ON users;
CREATE POLICY "Managers can update users"
    ON users FOR UPDATE
    USING (
        tenant_id = current_tenant_id() AND
        can_manage_users()
    );

-- Admins can delete users
DROP POLICY IF EXISTS "Admins can delete users" ON users;
CREATE POLICY "Admins can delete users"
    ON users FOR DELETE
    USING (
        tenant_id = current_tenant_id() AND
        current_user_role() IN ('super_admin', 'tenant_admin')
    );

-- ============================================
-- PRODUCTS TABLE POLICIES
-- ============================================

-- Users can view products in their tenant
DROP POLICY IF EXISTS "Users can view products in their tenant" ON products;
CREATE POLICY "Users can view products in their tenant"
    ON products FOR SELECT
    USING (tenant_id = current_tenant_id());

-- Managers can manage products
DROP POLICY IF EXISTS "Managers can insert products" ON products;
CREATE POLICY "Managers can insert products"
    ON products FOR INSERT
    WITH CHECK (
        tenant_id = current_tenant_id() AND
        can_manage_products()
    );

DROP POLICY IF EXISTS "Managers can update products" ON products;
CREATE POLICY "Managers can update products"
    ON products FOR UPDATE
    USING (
        tenant_id = current_tenant_id() AND
        can_manage_products()
    );

DROP POLICY IF EXISTS "Managers can delete products" ON products;
CREATE POLICY "Managers can delete products"
    ON products FOR DELETE
    USING (
        tenant_id = current_tenant_id() AND
        can_manage_products()
    );

-- ============================================
-- CUSTOMERS TABLE POLICIES
-- ============================================

-- Users can view customers in their tenant
DROP POLICY IF EXISTS "Users can view customers in their tenant" ON customers;
CREATE POLICY "Users can view customers in their tenant"
    ON customers FOR SELECT
    USING (tenant_id = current_tenant_id());

-- Staff can create customers
DROP POLICY IF EXISTS "Staff can create customers" ON customers;
CREATE POLICY "Staff can create customers"
    ON customers FOR INSERT
    WITH CHECK (tenant_id = current_tenant_id());

-- Staff can update customers
DROP POLICY IF EXISTS "Staff can update customers" ON customers;
CREATE POLICY "Staff can update customers"
    ON customers FOR UPDATE
    USING (tenant_id = current_tenant_id());

-- Managers can delete customers
DROP POLICY IF EXISTS "Managers can delete customers" ON customers;
CREATE POLICY "Managers can delete customers"
    ON customers FOR DELETE
    USING (
        tenant_id = current_tenant_id() AND
        can_manage_users()
    );

-- ============================================
-- SALES TABLE POLICIES
-- ============================================

-- Users can view sales in their tenant
DROP POLICY IF EXISTS "Users can view sales in their tenant" ON sales;
CREATE POLICY "Users can view sales in their tenant"
    ON sales FOR SELECT
    USING (tenant_id = current_tenant_id());

-- Cashiers can create sales
DROP POLICY IF EXISTS "Cashiers can create sales" ON sales;
CREATE POLICY "Cashiers can create sales"
    ON sales FOR INSERT
    WITH CHECK (
        tenant_id = current_tenant_id() AND
        (cashier_id = auth.uid() OR sales_attendant_id = auth.uid())
    );

-- Cashiers can update their own sales (within same day)
DROP POLICY IF EXISTS "Cashiers can update own sales" ON sales;
CREATE POLICY "Cashiers can update own sales"
    ON sales FOR UPDATE
    USING (
        tenant_id = current_tenant_id() AND
        cashier_id = auth.uid() AND
        sale_date = CURRENT_DATE
    );

-- Managers can void sales
DROP POLICY IF EXISTS "Managers can void sales" ON sales;
CREATE POLICY "Managers can void sales"
    ON sales FOR UPDATE
    USING (
        tenant_id = current_tenant_id() AND
        can_void_sales()
    );

-- Managers can delete sales
DROP POLICY IF EXISTS "Managers can delete sales" ON sales;
CREATE POLICY "Managers can delete sales"
    ON sales FOR DELETE
    USING (
        tenant_id = current_tenant_id() AND
        current_user_role() IN ('super_admin', 'tenant_admin', 'branch_manager')
    );

-- ============================================
-- SALE_ITEMS TABLE POLICIES
-- ============================================

-- Users can view sale items in their tenant
DROP POLICY IF EXISTS "Users can view sale items in their tenant" ON sale_items;
CREATE POLICY "Users can view sale items in their tenant"
    ON sale_items FOR SELECT
    USING (tenant_id = current_tenant_id());

-- Cashiers can create sale items (via their sales)
DROP POLICY IF EXISTS "Cashiers can create sale items" ON sale_items;
CREATE POLICY "Cashiers can create sale items"
    ON sale_items FOR INSERT
    WITH CHECK (
        tenant_id = current_tenant_id() AND
        EXISTS (
            SELECT 1 FROM sales
            WHERE sales.id = sale_items.sale_id
            AND (sales.cashier_id = auth.uid() OR sales.sales_attendant_id = auth.uid())
        )
    );

-- Cashiers can update sale items (via their sales, same day)
DROP POLICY IF EXISTS "Cashiers can update sale items" ON sale_items;
CREATE POLICY "Cashiers can update sale items"
    ON sale_items FOR UPDATE
    USING (
        tenant_id = current_tenant_id() AND
        EXISTS (
            SELECT 1 FROM sales
            WHERE sales.id = sale_items.sale_id
            AND sales.cashier_id = auth.uid()
            AND sales.sale_date = CURRENT_DATE
        )
    );

-- Managers can delete sale items
DROP POLICY IF EXISTS "Managers can delete sale items" ON sale_items;
CREATE POLICY "Managers can delete sale items"
    ON sale_items FOR DELETE
    USING (
        tenant_id = current_tenant_id() AND
        current_user_role() IN ('super_admin', 'tenant_admin', 'branch_manager')
    );

-- ============================================
-- COMMENTS
-- ============================================

COMMENT ON POLICY "Users can view their own tenant" ON tenants IS 'Users can only see their own tenant';
COMMENT ON POLICY "Users can view branches in their tenant" ON branches IS 'Users see all branches in their tenant';
COMMENT ON POLICY "Users can view users in their tenant" ON users IS 'Users see all users in their tenant';
COMMENT ON POLICY "Users can view products in their tenant" ON products IS 'Users see all products in their tenant';
COMMENT ON POLICY "Users can view sales in their tenant" ON sales IS 'Users see all sales in their tenant';


-- File: 021_add_tenant_id_to_sale_items.sql
-- ============================================
-- Migration 015a: Add tenant_id to sale_items
-- Description: Quick fix to add missing tenant_id column
-- Run this BEFORE migration 020 if you've already run 015
-- ============================================

-- Add tenant_id column for RLS (critical for multi-tenant isolation)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'sale_items' AND column_name = 'tenant_id'
    ) THEN
        -- Add column as nullable first
        ALTER TABLE sale_items ADD COLUMN tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE;
        COMMENT ON COLUMN sale_items.tenant_id IS 'Tenant ID for multi-tenant RLS isolation';

        -- Populate tenant_id from sales table for existing records
        UPDATE sale_items si
        SET tenant_id = s.tenant_id
        FROM sales s
        WHERE si.sale_id = s.id
        AND si.tenant_id IS NULL;

        -- Make tenant_id NOT NULL after populating
        ALTER TABLE sale_items ALTER COLUMN tenant_id SET NOT NULL;

        -- Create index for RLS queries
        CREATE INDEX IF NOT EXISTS idx_sale_items_tenant ON sale_items(tenant_id);

        RAISE NOTICE 'Added tenant_id column to sale_items table';
    ELSE
        RAISE NOTICE 'tenant_id column already exists on sale_items table';
    END IF;
END $$;

-- Update trigger to auto-populate tenant_id
CREATE OR REPLACE FUNCTION populate_sale_item_details()
RETURNS TRIGGER AS $$
DECLARE
    v_product RECORD;
BEGIN
    -- Get tenant_id from sales table if not set
    IF NEW.tenant_id IS NULL THEN
        SELECT tenant_id INTO NEW.tenant_id
        FROM sales
        WHERE id = NEW.sale_id;
    END IF;

    -- Get product details if not already set
    IF NEW.product_name IS NULL OR NEW.product_sku IS NULL THEN
        SELECT
            p.name,
            p.sku,
            p.brand_id,
            b.name as brand_name,
            p.category_id,
            c.name as category_name,
            p.cost_price,
            p.unit_of_measure
        INTO v_product
        FROM products p
        LEFT JOIN brands b ON b.id = p.brand_id
        LEFT JOIN categories c ON c.id = p.category_id
        WHERE p.id = NEW.product_id;

        -- Populate snapshot fields
        NEW.product_name := COALESCE(NEW.product_name, v_product.name);
        NEW.product_sku := COALESCE(NEW.product_sku, v_product.sku);
        NEW.brand_id := COALESCE(NEW.brand_id, v_product.brand_id);
        NEW.brand_name := COALESCE(NEW.brand_name, v_product.brand_name);
        NEW.category_id := COALESCE(NEW.category_id, v_product.category_id);
        NEW.category_name := COALESCE(NEW.category_name, v_product.category_name);
        NEW.unit_of_measure := COALESCE(NEW.unit_of_measure, v_product.unit_of_measure, 'piece');

        -- Calculate cost and profit
        IF NEW.unit_cost IS NOT NULL THEN
            NEW.total_cost := NEW.unit_cost * NEW.quantity;
            NEW.gross_profit := NEW.line_total - NEW.total_cost;
            IF NEW.line_total > 0 THEN
                NEW.profit_margin := (NEW.gross_profit / NEW.line_total) * 100;
            END IF;
        ELSIF v_product.cost_price IS NOT NULL THEN
            NEW.unit_cost := v_product.cost_price;
            NEW.total_cost := v_product.cost_price * NEW.quantity;
            NEW.gross_profit := NEW.line_total - NEW.total_cost;
            IF NEW.line_total > 0 THEN
                NEW.profit_margin := (NEW.gross_profit / NEW.line_total) * 100;
            END IF;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


-- File: 022_seed_data.sql
-- ============================================================
-- Migration 010: Seed Data
-- ============================================================
-- Purpose: Insert default subscription plans and initial data

-- Insert default subscription plans
-- Note: commission_cap_amount defaults to â‚¦500 for all plans (set in migration 012)
INSERT INTO subscriptions (plan_tier, monthly_fee, commission_rate, max_branches, max_staff_users, max_products, monthly_transaction_quota, features, billing_cycle_start, billing_cycle_end, status) VALUES
    -- Free Plan (â‚¦0/month, 0% commission - no e-commerce)
    (
        'free',
        0.00,
        0.00,
        1,
        3,
        100,
        500,
        '{
            "ai_chat": false,
            "ecommerce_chat": false,
            "ecommerce_enabled": false,
            "advanced_analytics": false,
            "api_access": false,
            "woocommerce_sync": false,
            "shopify_sync": false,
            "whatsapp_business_api": false,
            "multi_currency": false,
            "custom_integrations": false
        }'::jsonb,
        NOW(),
        NOW() + INTERVAL '1 month',
        'active'
    ),

    -- Basic Plan (â‚¦5,000/month, 0% commission - no e-commerce)
    (
        'basic',
        5000.00,
        0.00,
        3,
        10,
        1000,
        5000,
        '{
            "ai_chat": true,
            "ecommerce_chat": false,
            "ecommerce_enabled": false,
            "advanced_analytics": false,
            "api_access": false,
            "woocommerce_sync": false,
            "shopify_sync": false,
            "whatsapp_business_api": true,
            "multi_currency": false,
            "custom_integrations": false,
            "inter_branch_transfers": true,
            "delivery_management": true
        }'::jsonb,
        NOW(),
        NOW() + INTERVAL '1 month',
        'active'
    ),

    -- Pro Plan (â‚¦15,000/month, 1.5% commission)
    (
        'pro',
        15000.00,
        1.50,
        10,
        50,
        10000,
        50000,
        '{
            "ai_chat": true,
            "ecommerce_chat": true,
            "ecommerce_enabled": true,
            "advanced_analytics": true,
            "api_access": true,
            "woocommerce_sync": true,
            "shopify_sync": true,
            "whatsapp_business_api": true,
            "multi_currency": false,
            "custom_integrations": false,
            "inter_branch_transfers": true,
            "delivery_management": true,
            "bulk_import_export": true,
            "priority_support": true
        }'::jsonb,
        NOW(),
        NOW() + INTERVAL '1 month',
        'active'
    ),

    -- Enterprise Plan (â‚¦50,000/month, 1% commission)
    (
        'enterprise',
        50000.00,
        1.00,
        999999,
        999999,
        999999,
        999999,
        '{
            "ai_chat": true,
            "ecommerce_chat": true,
            "ecommerce_enabled": true,
            "advanced_analytics": true,
            "api_access": true,
            "woocommerce_sync": true,
            "shopify_sync": true,
            "whatsapp_business_api": true,
            "multi_currency": true,
            "custom_integrations": false,
            "inter_branch_transfers": true,
            "delivery_management": true,
            "bulk_import_export": true,
            "priority_support": true,
            "phone_support": true,
            "dedicated_account_manager": true,
            "custom_reporting": true,
            "sla_guarantees": true,
            "data_export": true
        }'::jsonb,
        NOW(),
        NOW() + INTERVAL '1 month',
        'active'
    ),

    -- Enterprise Custom Plan (Contact Sales, 0.5% commission)
    (
        'enterprise_custom',
        0.00,  -- Pricing is custom, set per tenant
        0.50,  -- Default negotiable commission
        999999,
        999999,
        999999,
        999999,
        '{
            "ai_chat": true,
            "ecommerce_chat": true,
            "ecommerce_enabled": true,
            "custom_domain": true,
            "white_label": true,
            "advanced_analytics": true,
            "api_access": true,
            "woocommerce_sync": true,
            "shopify_sync": true,
            "whatsapp_business_api": true,
            "multi_currency": true,
            "custom_integrations": true,
            "inter_branch_transfers": true,
            "delivery_management": true,
            "bulk_import_export": true,
            "priority_support": true,
            "phone_support": true,
            "dedicated_account_manager": true,
            "support_24_7": true,
            "custom_reporting": true,
            "sla_guarantees": true,
            "data_export": true,
            "custom_development": true,
            "on_premise_option": true,
            "dedicated_infrastructure": false
        }'::jsonb,
        NOW(),
        NOW() + INTERVAL '1 month',
        'active'
    );


-- File: 023_chat_enhancements.sql
-- ============================================================
-- Migration 011: Chat Enhancements
-- ============================================================
-- Purpose: Extend chat system to support rich media, interactive elements, and plan-based features

-- New enum for extended chat message types
CREATE TYPE chat_message_type AS ENUM (
    'text',
    'image',
    'audio',
    'video',
    'location',
    'product_card',
    'receipt',
    'payment_confirmation',
    'discount_applied',
    'system_action'
);

-- New enum for chat actions
CREATE TYPE chat_action_type AS ENUM (
    'add_to_cart',
    'apply_discount',
    'view_product',
    'confirm_payment',
    'update_delivery_address',
    'request_human_agent'
);

-- Drop and recreate chat_messages table with enhanced schema
DROP TABLE IF EXISTS chat_messages CASCADE;

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

    -- Structured data for different message types
    metadata JSONB DEFAULT '{}',
    -- Examples of metadata:
    -- Location: {"latitude": 6.5244, "longitude": 3.3792, "address": "123 Main St"}
    -- Product card: {"product_id": "uuid", "name": "Product Name", "price": 1500, "image_url": "...", "stock": 10}
    -- Discount: {"original_price": 2000, "discount_percent": 10, "final_price": 1800, "discount_code": "SAVE10"}
    -- Receipt: {"receipt_id": "uuid", "amount": 5000, "payment_method": "bank_transfer"}
    -- Payment confirmation: {"reference": "TXN123456", "amount": 5000, "confirmed_at": "2024-01-01T10:00:00Z"}

    -- Interactive actions
    action_type chat_action_type,
    action_data JSONB,
    action_completed_at TIMESTAMPTZ,
    action_completed_by UUID REFERENCES users(id),

    -- AI intent detection
    intent VARCHAR(100),
    confidence_score DECIMAL(3,2) CHECK (confidence_score >= 0 AND confidence_score <= 1),

    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Constraints
    CONSTRAINT text_or_media_required CHECK (
        message_text IS NOT NULL OR media_url IS NOT NULL
    ),
    CONSTRAINT action_requires_data CHECK (
        (action_type IS NULL AND action_data IS NULL) OR
        (action_type IS NOT NULL AND action_data IS NOT NULL)
    )
);

-- Create index for conversation messages
CREATE INDEX idx_chat_messages_conversation ON chat_messages(conversation_id, created_at DESC);
CREATE INDEX idx_chat_messages_type ON chat_messages(message_type, created_at DESC);
CREATE INDEX idx_chat_messages_action ON chat_messages(action_type, action_completed_at)
    WHERE action_type IS NOT NULL;

-- Function to check if tenant has chat feature access
CREATE OR REPLACE FUNCTION has_chat_feature(p_tenant_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    v_plan_tier plan_tier;
BEGIN
    SELECT s.plan_tier INTO v_plan_tier
    FROM tenants t
    JOIN subscriptions s ON t.subscription_id = s.id
    WHERE t.id = p_tenant_id
    AND s.status = 'active';

    -- Chat feature is available for 'pro' and 'enterprise' plans only
    RETURN v_plan_tier IN ('pro', 'enterprise', 'enterprise_custom');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if tenant has growth plan or higher (for e-commerce chat button)
CREATE OR REPLACE FUNCTION has_ecommerce_chat_feature(p_tenant_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    v_plan_tier plan_tier;
    v_features JSONB;
BEGIN
    SELECT s.plan_tier, s.features INTO v_plan_tier, v_features
    FROM tenants t
    JOIN subscriptions s ON t.subscription_id = s.id
    WHERE t.id = p_tenant_id
    AND s.status = 'active';

    -- E-commerce chat is available for 'pro' and 'enterprise' plans
    -- Can also check features JSONB for explicit 'ecommerce_chat' flag
    RETURN v_plan_tier IN ('pro', 'enterprise', 'enterprise_custom')
        OR (v_features->>'ecommerce_chat')::BOOLEAN = true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Add comment to subscriptions.features to document the schema
COMMENT ON COLUMN subscriptions.features IS
'JSONB field for feature flags. Example: {"ecommerce_chat": true, "ai_chat": true, "advanced_analytics": true, "multi_currency": true}';

-- Add helpful comments to the new columns
COMMENT ON COLUMN chat_messages.metadata IS
'Structured data specific to message_type. See migration file for examples.';
COMMENT ON COLUMN chat_messages.action_data IS
'Data for interactive actions. Example: {"product_id": "uuid", "quantity": 2, "cart_id": "uuid"}';


-- File: 024_ecommerce_enhancements.sql
-- ============================================================
-- Migration 012: E-Commerce Enhancements
-- ============================================================
-- Purpose: Add e-commerce storefront support with custom domain capability

-- Add commission cap to subscriptions table
ALTER TABLE subscriptions
ADD COLUMN commission_cap_amount DECIMAL(12,2) DEFAULT 500.00 CHECK (commission_cap_amount >= 0);

COMMENT ON COLUMN subscriptions.commission_cap_amount IS
'Maximum commission amount per order in Naira. Default is â‚¦500 cap for all plans.';

-- Add e-commerce fields to tenants table
ALTER TABLE tenants
ADD COLUMN ecommerce_enabled BOOLEAN DEFAULT FALSE,
ADD COLUMN custom_domain VARCHAR(255),
ADD COLUMN custom_domain_verified BOOLEAN DEFAULT FALSE,
ADD COLUMN ecommerce_settings JSONB DEFAULT '{}';

-- Create unique index on custom_domain
CREATE UNIQUE INDEX idx_tenants_custom_domain ON tenants(custom_domain)
    WHERE custom_domain IS NOT NULL AND deleted_at IS NULL;

-- Add comments to document the fields
COMMENT ON COLUMN tenants.ecommerce_enabled IS
'Indicates if tenant has e-commerce storefront enabled. Available for Pro, Enterprise, and Enterprise Custom plans.';

COMMENT ON COLUMN tenants.custom_domain IS
'Custom domain for e-commerce storefront (e.g., "shop.mystore.com"). Only available for Enterprise Custom plan. NULL means using default /tenant-slug URL.';

COMMENT ON COLUMN tenants.custom_domain_verified IS
'Indicates if custom domain DNS has been verified and is active.';

COMMENT ON COLUMN tenants.ecommerce_settings IS
'E-commerce configuration. Example: {
  "show_out_of_stock": false,
  "enable_branch_filter": true,
  "enable_location_filter": true,
  "default_view": "category",
  "currency_display": "NGN",
  "delivery_enabled": true,
  "pickup_enabled": true,
  "min_order_amount": 1000,
  "seo": {
    "meta_title": "Shop at MyStore",
    "meta_description": "...",
    "og_image": "https://..."
  },
  "theme": {
    "primary_color": "#FF6B35",
    "secondary_color": "#004E89"
  }
}';

-- Function to check if tenant can enable e-commerce
CREATE OR REPLACE FUNCTION can_enable_ecommerce(p_tenant_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    v_plan_tier plan_tier;
BEGIN
    SELECT s.plan_tier INTO v_plan_tier
    FROM tenants t
    JOIN subscriptions s ON t.subscription_id = s.id
    WHERE t.id = p_tenant_id
    AND s.status = 'active';

    -- E-commerce available for Pro, Enterprise, and Enterprise Custom plans
    RETURN v_plan_tier IN ('pro', 'enterprise', 'enterprise_custom');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if tenant can use custom domain
CREATE OR REPLACE FUNCTION can_use_custom_domain(p_tenant_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    v_plan_tier plan_tier;
BEGIN
    SELECT s.plan_tier INTO v_plan_tier
    FROM tenants t
    JOIN subscriptions s ON t.subscription_id = s.id
    WHERE t.id = p_tenant_id
    AND s.status = 'active';

    -- Custom domain only available for Enterprise Custom plan
    RETURN v_plan_tier = 'enterprise_custom';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get tenant storefront URL
CREATE OR REPLACE FUNCTION get_storefront_url(p_tenant_id UUID, p_base_url TEXT DEFAULT 'https://yourdomain.com')
RETURNS TEXT AS $$
DECLARE
    v_custom_domain VARCHAR(255);
    v_custom_domain_verified BOOLEAN;
    v_slug VARCHAR(100);
    v_ecommerce_enabled BOOLEAN;
BEGIN
    SELECT custom_domain, custom_domain_verified, slug, ecommerce_enabled
    INTO v_custom_domain, v_custom_domain_verified, v_slug, v_ecommerce_enabled
    FROM tenants
    WHERE id = p_tenant_id
    AND deleted_at IS NULL;

    -- Return NULL if e-commerce is not enabled
    IF NOT v_ecommerce_enabled THEN
        RETURN NULL;
    END IF;

    -- Return custom domain if verified
    IF v_custom_domain IS NOT NULL AND v_custom_domain_verified THEN
        RETURN 'https://' || v_custom_domain;
    END IF;

    -- Return default slug-based URL
    RETURN p_base_url || '/' || v_slug;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- View for e-commerce product catalog (aggregates products across all branches)
CREATE OR REPLACE VIEW ecommerce_products AS
SELECT
    p.id,
    p.tenant_id,
    p.name,
    p.description,
    p.category,
    p.unit_price,
    p.image_url,
    p.is_active,

    -- Aggregate stock across all branches
    SUM(p.stock_quantity) as total_stock,

    -- Count how many branches have this product
    COUNT(DISTINCT p.branch_id) as branch_count,

    -- Collect branch information
    jsonb_agg(
        jsonb_build_object(
            'branch_id', b.id,
            'branch_name', b.name,
            'branch_address', b.address,
            'branch_phone', b.phone,
            'latitude', b.latitude,
            'longitude', b.longitude,
            'stock_quantity', p.stock_quantity,
            'in_stock', p.stock_quantity > 0
        ) ORDER BY b.name
    ) as branches,

    -- Min and max price across branches (in case prices differ)
    MIN(p.unit_price) as min_price,
    MAX(p.unit_price) as max_price,

    p.created_at,
    p.updated_at
FROM products p
JOIN branches b ON p.branch_id = b.id
WHERE p.deleted_at IS NULL
  AND b.deleted_at IS NULL
  AND p.is_active = TRUE
GROUP BY
    p.id,
    p.tenant_id,
    p.name,
    p.description,
    p.category,
    p.unit_price,
    p.image_url,
    p.is_active,
    p.created_at,
    p.updated_at;

-- Comment on the view
COMMENT ON VIEW ecommerce_products IS
'Aggregated product view for e-commerce storefront. Shows products across all branches with stock and location information.';

-- Function to get products for e-commerce by tenant with optional filters
CREATE OR REPLACE FUNCTION get_ecommerce_products(
    p_tenant_id UUID,
    p_category VARCHAR DEFAULT NULL,
    p_branch_id UUID DEFAULT NULL,
    p_latitude DECIMAL DEFAULT NULL,
    p_longitude DECIMAL DEFAULT NULL,
    p_max_distance_km DECIMAL DEFAULT NULL,
    p_in_stock_only BOOLEAN DEFAULT TRUE
)
RETURNS TABLE (
    product_id UUID,
    product_name VARCHAR,
    description TEXT,
    category VARCHAR,
    unit_price DECIMAL,
    image_url TEXT,
    total_stock BIGINT,
    branch_count BIGINT,
    branches JSONB,
    min_price DECIMAL,
    max_price DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        ep.id,
        ep.name,
        ep.description,
        ep.category,
        ep.unit_price,
        ep.image_url,
        ep.total_stock,
        ep.branch_count,
        ep.branches,
        ep.min_price,
        ep.max_price
    FROM ecommerce_products ep
    WHERE ep.tenant_id = p_tenant_id

    -- Category filter
    AND (p_category IS NULL OR ep.category = p_category)

    -- Stock filter
    AND (NOT p_in_stock_only OR ep.total_stock > 0)

    -- Branch filter (if specific branch requested)
    AND (p_branch_id IS NULL OR EXISTS (
        SELECT 1 FROM jsonb_array_elements(ep.branches) AS branch
        WHERE (branch->>'branch_id')::UUID = p_branch_id
    ))

    -- Location-based filter (if coordinates provided)
    AND (
        p_latitude IS NULL OR p_longitude IS NULL OR p_max_distance_km IS NULL
        OR EXISTS (
            SELECT 1 FROM jsonb_array_elements(ep.branches) AS branch
            WHERE (branch->>'latitude') IS NOT NULL
            AND (branch->>'longitude') IS NOT NULL
            AND ST_DWithin(
                ST_MakePoint((branch->>'longitude')::DECIMAL, (branch->>'latitude')::DECIMAL)::geography,
                ST_MakePoint(p_longitude, p_latitude)::geography,
                p_max_distance_km * 1000  -- Convert km to meters
            )
        )
    )

    ORDER BY ep.name;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to calculate commission with cap
CREATE OR REPLACE FUNCTION calculate_commission(
    p_tenant_id UUID,
    p_order_amount DECIMAL
)
RETURNS DECIMAL AS $$
DECLARE
    v_commission_rate DECIMAL;
    v_commission_cap DECIMAL;
    v_calculated_commission DECIMAL;
BEGIN
    -- Get commission rate and cap for tenant's subscription
    SELECT s.commission_rate, s.commission_cap_amount
    INTO v_commission_rate, v_commission_cap
    FROM tenants t
    JOIN subscriptions s ON t.subscription_id = s.id
    WHERE t.id = p_tenant_id
    AND s.status = 'active';

    -- If no subscription found or commission rate is 0, return 0
    IF v_commission_rate IS NULL OR v_commission_rate = 0 THEN
        RETURN 0;
    END IF;

    -- Calculate commission based on rate
    v_calculated_commission := p_order_amount * (v_commission_rate / 100);

    -- Apply cap if set and calculated commission exceeds it
    IF v_commission_cap IS NOT NULL AND v_calculated_commission > v_commission_cap THEN
        RETURN v_commission_cap;
    END IF;

    RETURN v_calculated_commission;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION calculate_commission IS
'Calculate commission for an e-commerce order with cap.
Example: For Pro plan (1.5% rate, â‚¦500 cap):
- â‚¦10,000 order = â‚¦150 commission (1.5% of â‚¦10,000)
- â‚¦50,000 order = â‚¦500 commission (1.5% would be â‚¦750, but capped at â‚¦500)
- â‚¦100,000 order = â‚¦500 commission (capped)';

-- Add index to help with e-commerce queries
CREATE INDEX idx_products_ecommerce ON products(tenant_id, category, is_active, deleted_at)
    WHERE deleted_at IS NULL AND is_active = TRUE;


-- File: 20260125_add_missing_rls_policies.sql
-- Migration: Add Row Level Security to Unrestricted Tables
-- Date: 2026-01-25
-- Description: Enable RLS and add tenant isolation policies for 10 tables missing security

-- ============================================================================
-- 1. CUSTOMER_ADDRESSES
-- ============================================================================

ALTER TABLE customer_addresses ENABLE ROW LEVEL SECURITY;

-- Tenant isolation for SELECT
CREATE POLICY "customer_addresses_tenant_isolation_select" ON customer_addresses
  FOR SELECT USING (tenant_id = (auth.jwt() ->> 'tenant_id')::UUID);

-- Tenant isolation for INSERT
CREATE POLICY "customer_addresses_tenant_isolation_insert" ON customer_addresses
  FOR INSERT WITH CHECK (tenant_id = (auth.jwt() ->> 'tenant_id')::UUID);

-- Tenant isolation for UPDATE
CREATE POLICY "customer_addresses_tenant_isolation_update" ON customer_addresses
  FOR UPDATE USING (tenant_id = (auth.jwt() ->> 'tenant_id')::UUID);

-- Tenant isolation for DELETE
CREATE POLICY "customer_addresses_tenant_isolation_delete" ON customer_addresses
  FOR DELETE USING (tenant_id = (auth.jwt() ->> 'tenant_id')::UUID);

-- ============================================================================
-- 2. SUBSCRIPTIONS
-- ============================================================================

ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;

-- Tenant can view their own subscription
CREATE POLICY "subscriptions_tenant_access" ON subscriptions
  FOR SELECT USING (tenant_id = (auth.jwt() ->> 'tenant_id')::UUID);

-- Platform admins can view all subscriptions
CREATE POLICY "subscriptions_platform_admin_access" ON subscriptions
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM users u
      WHERE u.id = auth.uid() AND u.role = 'platform_admin'
    )
  );

-- Tenants cannot modify their own subscriptions (platform only)
-- No INSERT, UPDATE, DELETE policies for tenants

-- ============================================================================
-- 3. COMMISSIONS
-- ============================================================================

ALTER TABLE commissions ENABLE ROW LEVEL SECURITY;

-- Tenant can view their own commissions
CREATE POLICY "commissions_tenant_access" ON commissions
  FOR SELECT USING (tenant_id = (auth.jwt() ->> 'tenant_id')::UUID);

-- Platform admins can manage all commissions
CREATE POLICY "commissions_platform_admin_access" ON commissions
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM users u
      WHERE u.id = auth.uid() AND u.role = 'platform_admin'
    )
  );

-- ============================================================================
-- 4. RECEIPTS
-- ============================================================================

ALTER TABLE receipts ENABLE ROW LEVEL SECURITY;

-- Tenant isolation for SELECT
CREATE POLICY "receipts_tenant_isolation_select" ON receipts
  FOR SELECT USING (tenant_id = (auth.jwt() ->> 'tenant_id')::UUID);

-- Tenant isolation for INSERT
CREATE POLICY "receipts_tenant_isolation_insert" ON receipts
  FOR INSERT WITH CHECK (tenant_id = (auth.jwt() ->> 'tenant_id')::UUID);

-- Tenant isolation for UPDATE
CREATE POLICY "receipts_tenant_isolation_update" ON receipts
  FOR UPDATE USING (tenant_id = (auth.jwt() ->> 'tenant_id')::UUID);

-- Tenant isolation for DELETE
CREATE POLICY "receipts_tenant_isolation_delete" ON receipts
  FOR DELETE USING (tenant_id = (auth.jwt() ->> 'tenant_id')::UUID);

-- ============================================================================
-- 5. TRANSFER_ITEMS
-- ============================================================================

ALTER TABLE transfer_items ENABLE ROW LEVEL SECURITY;

-- Assuming transfer_items has tenant_id (if not, needs to join through inter_branch_transfers)
-- If transfer_items has tenant_id directly:
CREATE POLICY "transfer_items_tenant_isolation_select" ON transfer_items
  FOR SELECT USING (
    tenant_id = (auth.jwt() ->> 'tenant_id')::UUID
  );

CREATE POLICY "transfer_items_tenant_isolation_insert" ON transfer_items
  FOR INSERT WITH CHECK (
    tenant_id = (auth.jwt() ->> 'tenant_id')::UUID
  );

CREATE POLICY "transfer_items_tenant_isolation_update" ON transfer_items
  FOR UPDATE USING (
    tenant_id = (auth.jwt() ->> 'tenant_id')::UUID
  );

CREATE POLICY "transfer_items_tenant_isolation_delete" ON transfer_items
  FOR DELETE USING (
    tenant_id = (auth.jwt() ->> 'tenant_id')::UUID
  );

-- If transfer_items doesn't have tenant_id, use this alternative (join through parent):
-- CREATE POLICY "transfer_items_tenant_isolation_select" ON transfer_items
--   FOR SELECT USING (
--     EXISTS (
--       SELECT 1 FROM inter_branch_transfers ibt
--       WHERE ibt.id = transfer_items.transfer_id
--       AND ibt.tenant_id = (auth.jwt() ->> 'tenant_id')::UUID
--     )
--   );

-- ============================================================================
-- 6. CHAT_MESSAGES
-- ============================================================================

ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;

-- Tenant isolation for SELECT
CREATE POLICY "chat_messages_tenant_isolation_select" ON chat_messages
  FOR SELECT USING (tenant_id = (auth.jwt() ->> 'tenant_id')::UUID);

-- Tenant isolation for INSERT
CREATE POLICY "chat_messages_tenant_isolation_insert" ON chat_messages
  FOR INSERT WITH CHECK (tenant_id = (auth.jwt() ->> 'tenant_id')::UUID);

-- Tenant isolation for UPDATE
CREATE POLICY "chat_messages_tenant_isolation_update" ON chat_messages
  FOR UPDATE USING (tenant_id = (auth.jwt() ->> 'tenant_id')::UUID);

-- Tenant isolation for DELETE
CREATE POLICY "chat_messages_tenant_isolation_delete" ON chat_messages
  FOR DELETE USING (tenant_id = (auth.jwt() ->> 'tenant_id')::UUID);

-- ============================================================================
-- 7. ECOMMERCE_PRODUCTS (assuming this is the ecommerce_pr... table)
-- ============================================================================

-- Note: Adjust table name if different
ALTER TABLE ecommerce_products ENABLE ROW LEVEL SECURITY;

CREATE POLICY "ecommerce_products_tenant_isolation_select" ON ecommerce_products
  FOR SELECT USING (tenant_id = (auth.jwt() ->> 'tenant_id')::UUID);

CREATE POLICY "ecommerce_products_tenant_isolation_insert" ON ecommerce_products
  FOR INSERT WITH CHECK (tenant_id = (auth.jwt() ->> 'tenant_id')::UUID);

CREATE POLICY "ecommerce_products_tenant_isolation_update" ON ecommerce_products
  FOR UPDATE USING (tenant_id = (auth.jwt() ->> 'tenant_id')::UUID);

CREATE POLICY "ecommerce_products_tenant_isolation_delete" ON ecommerce_products
  FOR DELETE USING (tenant_id = (auth.jwt() ->> 'tenant_id')::UUID);

-- ============================================================================
-- 8. DIM_DATE (Analytics Dimension Table)
-- ============================================================================

ALTER TABLE dim_date ENABLE ROW LEVEL SECURITY;

-- Dimension tables are shared across tenants (no tenant_id)
-- All authenticated users can read, but cannot modify
CREATE POLICY "dim_date_read_all" ON dim_date
  FOR SELECT USING (auth.role() = 'authenticated');

-- Only platform admins can modify
CREATE POLICY "dim_date_admin_modify" ON dim_date
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM users u
      WHERE u.id = auth.uid() AND u.role = 'platform_admin'
    )
  );

-- ============================================================================
-- 9. DIM_TIME (Analytics Dimension Table)
-- ============================================================================

ALTER TABLE dim_time ENABLE ROW LEVEL SECURITY;

-- Dimension tables are shared across tenants (no tenant_id)
-- All authenticated users can read, but cannot modify
CREATE POLICY "dim_time_read_all" ON dim_time
  FOR SELECT USING (auth.role() = 'authenticated');

-- Only platform admins can modify
CREATE POLICY "dim_time_admin_modify" ON dim_time
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM users u
      WHERE u.id = auth.uid() AND u.role = 'platform_admin'
    )
  );

-- ============================================================================
-- 10. SPATIAL_REF_SYS (PostGIS System Table)
-- ============================================================================

ALTER TABLE spatial_ref_sys ENABLE ROW LEVEL SECURITY;

-- PostGIS system table - all authenticated users can read
CREATE POLICY "spatial_ref_sys_read_all" ON spatial_ref_sys
  FOR SELECT USING (auth.role() = 'authenticated');

-- Only platform admins can modify (should rarely be needed)
CREATE POLICY "spatial_ref_sys_admin_modify" ON spatial_ref_sys
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM users u
      WHERE u.id = auth.uid() AND u.role = 'platform_admin'
    )
  );

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================

-- Run these queries to verify RLS is enabled:
-- SELECT tablename, rowsecurity FROM pg_tables WHERE schemaname = 'public' AND rowsecurity = false;

-- Run this to see all policies:
-- SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual
-- FROM pg_policies
-- WHERE schemaname = 'public'
-- ORDER BY tablename, policyname;

-- ============================================================================
-- NOTES
-- ============================================================================

-- 1. transfer_items: If this table doesn't have tenant_id, uncomment the alternative policy
-- 2. ecommerce_products: Verify the exact table name in your schema
-- 3. dim_date, dim_time: These are dimension tables shared across all tenants
-- 4. spatial_ref_sys: PostGIS system table, rarely modified
-- 5. Platform admin role: Assumes users table has 'platform_admin' role

-- ============================================================================
-- ROLLBACK (if needed)
-- ============================================================================

-- To disable RLS on all tables (DANGEROUS - only for emergency):
-- ALTER TABLE customer_addresses DISABLE ROW LEVEL SECURITY;
-- ALTER TABLE subscriptions DISABLE ROW LEVEL SECURITY;
-- ALTER TABLE commissions DISABLE ROW LEVEL SECURITY;
-- ALTER TABLE receipts DISABLE ROW LEVEL SECURITY;
-- ALTER TABLE transfer_items DISABLE ROW LEVEL SECURITY;
-- ALTER TABLE chat_messages DISABLE ROW LEVEL SECURITY;
-- ALTER TABLE ecommerce_products DISABLE ROW LEVEL SECURITY;
-- ALTER TABLE dim_date DISABLE ROW LEVEL SECURITY;
-- ALTER TABLE dim_time DISABLE ROW LEVEL SECURITY;
-- ALTER TABLE spatial_ref_sys DISABLE ROW LEVEL SECURITY;


-- File: 20260125001_create_missing_tables.sql
-- Migration: Create 5 Missing Tables
-- Date: 2026-01-25
-- Description: Create staff_invites, product_variants, invoices, sync_logs, audit_logs

-- ============================================================================
-- 1. STAFF_INVITES
-- ============================================================================

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

-- ============================================================================
-- 2. PRODUCT_VARIANTS
-- ============================================================================

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

-- Trigger to increment version on update
CREATE TRIGGER product_variant_version_increment BEFORE UPDATE ON product_variants
  FOR EACH ROW EXECUTE FUNCTION increment_product_version();

-- ============================================================================
-- 3. INVOICES
-- ============================================================================

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

-- RLS Policies
ALTER TABLE invoices ENABLE ROW LEVEL SECURITY;

-- Tenants can view their own invoices
CREATE POLICY "invoices_tenant_access" ON invoices
  FOR SELECT USING (tenant_id = (auth.jwt() ->> 'tenant_id')::UUID);

-- Platform admins can manage all invoices
CREATE POLICY "invoices_platform_admin_access" ON invoices
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM users u
      WHERE u.id = auth.uid() AND u.role = 'platform_admin'
    )
  );

-- Auto-generate invoice number
CREATE SEQUENCE IF NOT EXISTS invoice_number_seq;

CREATE OR REPLACE FUNCTION generate_invoice_number()
RETURNS TRIGGER AS $$
BEGIN
  NEW.invoice_number = 'INV-' || TO_CHAR(NOW(), 'YYYY') || '-' || LPAD(nextval('invoice_number_seq')::TEXT, 6, '0');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_invoice_number BEFORE INSERT ON invoices
  FOR EACH ROW WHEN (NEW.invoice_number IS NULL)
  EXECUTE FUNCTION generate_invoice_number();

-- ============================================================================
-- 4. SYNC_LOGS
-- ============================================================================

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

-- ============================================================================
-- 5. AUDIT_LOGS
-- ============================================================================

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

-- RLS Policies
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "audit_logs_tenant_isolation" ON audit_logs
  FOR SELECT USING (
    tenant_id = (auth.jwt() ->> 'tenant_id')::UUID OR
    tenant_id IS NULL -- platform-level logs visible to platform admins only
  );

-- Only platform admins and system can insert audit logs
CREATE POLICY "audit_logs_insert_admin" ON audit_logs
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM users u
      WHERE u.id = auth.uid() AND u.role = 'platform_admin'
    )
  );

-- Partition by month for performance (optional, requires PostgreSQL partitioning setup)
-- CREATE TABLE audit_logs_partitioned (LIKE audit_logs INCLUDING ALL) PARTITION BY RANGE (created_at);

-- ============================================================================
-- HELPER FUNCTIONS (if not already created)
-- ============================================================================

-- Increment version function (if not exists from previous migrations)
CREATE OR REPLACE FUNCTION increment_product_version()
RETURNS TRIGGER AS $$
BEGIN
  NEW.version = OLD.version + 1;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Updated at trigger function (if not exists)
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply updated_at triggers
CREATE TRIGGER set_staff_invites_updated_at BEFORE UPDATE ON staff_invites
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER set_product_variants_updated_at BEFORE UPDATE ON product_variants
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER set_invoices_updated_at BEFORE UPDATE ON invoices
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- VERIFICATION
-- ============================================================================

-- Check that all tables were created
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name IN ('staff_invites', 'product_variants', 'invoices', 'sync_logs', 'audit_logs')
ORDER BY table_name;

-- Check RLS is enabled
SELECT tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN ('staff_invites', 'product_variants', 'invoices', 'sync_logs', 'audit_logs');

-- ============================================================================
-- NOTES
-- ============================================================================

-- 1. staff_invites: Requires email sending service integration
-- 2. product_variants: Parent product must have has_variants = true
-- 3. invoices: Auto-generates invoice numbers using sequence
-- 4. sync_logs: Auto-deletes logs older than 90 days (set up cron job)
-- 5. audit_logs: Consider partitioning for high-volume environments

-- ============================================================================
-- ROLLBACK (if needed)
-- ============================================================================

-- DROP TABLE IF EXISTS staff_invites CASCADE;
-- DROP TABLE IF EXISTS product_variants CASCADE;
-- DROP TABLE IF EXISTS invoices CASCADE;
-- DROP TABLE IF EXISTS sync_logs CASCADE;
-- DROP TABLE IF EXISTS audit_logs CASCADE;
-- DROP FUNCTION IF EXISTS expire_old_staff_invites();
-- DROP FUNCTION IF EXISTS generate_invoice_number();
-- DROP FUNCTION IF EXISTS cleanup_old_sync_logs();
-- DROP SEQUENCE IF EXISTS invoice_number_seq;


-- File: 20260222194504_healthcare_consultation.sql
-- Healthcare Provider Directory and Telemedicine Consultations
-- Feature: 003-healthcare-consultations
-- Date: 2026-02-22
--
-- This migration creates 8 healthcare entities with:
-- - Multi-tenant RLS policies
-- - Referral tracking for commission attribution
-- - Optimistic locking for slot booking
-- - Auto-expiration for prescriptions
-- - 35 performance indexes
-- - Multi-domain branding support

-- ============================================================================
-- 1. HEALTHCARE PROVIDERS (Country-wide pool)
-- ============================================================================

CREATE TABLE IF NOT EXISTS healthcare_providers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,

    -- Basic Info
    full_name TEXT NOT NULL,
    slug TEXT UNIQUE NOT NULL, -- For public clinic URLs: medic.kemani.com/c/{slug}
    email TEXT,
    phone TEXT,
    profile_photo_url TEXT,

    -- Professional Info
    type TEXT NOT NULL CHECK (type IN ('doctor', 'pharmacist', 'diagnostician', 'specialist')),
    specialization TEXT NOT NULL,
    credentials TEXT, -- e.g., "MD, MBBS"
    license_number TEXT, -- MDCN/PCN number
    years_of_experience INTEGER DEFAULT 0,
    bio TEXT,

    -- Location
    country TEXT NOT NULL,
    region TEXT,
    clinic_address JSONB, -- {street, city, postal_code, country, lat, lng}

    -- Offerings
    consultation_types TEXT[] DEFAULT ARRAY['chat'], -- ['chat', 'video', 'audio', 'office_visit']
    fees JSONB NOT NULL DEFAULT '{}', -- {chat: 5000, video: 10000, audio: 8000, office_visit: 15000}

    -- Stats (denormalized for performance)
    average_rating DECIMAL(3,2) DEFAULT 0.00,
    total_consultations INTEGER DEFAULT 0,
    total_reviews INTEGER DEFAULT 0,

    -- Subscription Plan (for medics using Growth+/Custom plans)
    plan_tier TEXT DEFAULT 'free' CHECK (plan_tier IN ('free', 'pro', 'enterprise_custom')),
    custom_domain TEXT, -- For Custom plan white-label

    -- Branding (Growth+ and Custom plans)
    clinic_settings JSONB DEFAULT '{}', -- {clinic_name, logo_url, primary_color, accent_color, is_accepting_patients}

    -- Status
    is_verified BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    verified_at TIMESTAMPTZ,

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for healthcare_providers
CREATE INDEX idx_providers_country_specialization ON healthcare_providers(country, specialization);
CREATE INDEX idx_providers_region ON healthcare_providers(region);
CREATE INDEX idx_providers_rating ON healthcare_providers(average_rating DESC) WHERE is_active = TRUE AND is_verified = TRUE;
CREATE INDEX idx_providers_slug ON healthcare_providers(slug);
CREATE INDEX idx_providers_user_id ON healthcare_providers(user_id);

-- RLS for healthcare_providers
ALTER TABLE healthcare_providers ENABLE ROW LEVEL SECURITY;

-- Public read for active/verified providers (filtered by country in app logic)
CREATE POLICY "Anyone can view active verified providers"
    ON healthcare_providers FOR SELECT
    USING (is_active = TRUE AND is_verified = TRUE);

-- Providers can update their own profile
CREATE POLICY "Providers can update own profile"
    ON healthcare_providers FOR UPDATE
    USING (user_id = auth.uid());

-- Providers can insert their own profile (onboarding)
CREATE POLICY "Authenticated users can create provider profile"
    ON healthcare_providers FOR INSERT
    WITH CHECK (user_id = auth.uid());

-- ============================================================================
-- 2. PROVIDER AVAILABILITY TEMPLATES (Recurring schedules)
-- ============================================================================

CREATE TABLE IF NOT EXISTS provider_availability_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    provider_id UUID NOT NULL REFERENCES healthcare_providers(id) ON DELETE CASCADE,

    -- Schedule Pattern
    day_of_week INTEGER NOT NULL CHECK (day_of_week BETWEEN 0 AND 6), -- 0=Sunday, 6=Saturday
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,

    -- Slot Configuration
    slot_duration INTEGER NOT NULL CHECK (slot_duration IN (15, 30, 45, 60)), -- minutes
    buffer_minutes INTEGER DEFAULT 0, -- Break between slots

    -- Consultation Types Available
    consultation_types TEXT[] DEFAULT ARRAY['chat', 'video', 'audio', 'office_visit'],

    -- Status
    is_active BOOLEAN DEFAULT TRUE,

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    -- Constraints
    CONSTRAINT valid_time_range CHECK (end_time > start_time)
);

-- Indexes for provider_availability_templates
CREATE INDEX idx_availability_provider ON provider_availability_templates(provider_id);
CREATE INDEX idx_availability_day ON provider_availability_templates(day_of_week) WHERE is_active = TRUE;

-- RLS for provider_availability_templates
ALTER TABLE provider_availability_templates ENABLE ROW LEVEL SECURITY;

-- Anyone can view active templates (for availability calendar)
CREATE POLICY "Anyone can view active availability"
    ON provider_availability_templates FOR SELECT
    USING (is_active = TRUE);

-- Providers can manage their own templates
CREATE POLICY "Providers can manage own availability"
    ON provider_availability_templates FOR ALL
    USING (provider_id IN (SELECT id FROM healthcare_providers WHERE user_id = auth.uid()));

-- ============================================================================
-- 3. PROVIDER TIME SLOTS (Materialized bookable slots)
-- ============================================================================

CREATE TABLE IF NOT EXISTS provider_time_slots (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    provider_id UUID NOT NULL REFERENCES healthcare_providers(id) ON DELETE CASCADE,
    template_id UUID REFERENCES provider_availability_templates(id) ON DELETE SET NULL,

    -- Slot Details
    date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    slot_duration INTEGER NOT NULL, -- minutes
    consultation_type TEXT NOT NULL CHECK (consultation_type IN ('chat', 'video', 'audio', 'office_visit')),

    -- Booking Status
    status TEXT DEFAULT 'available' CHECK (status IN ('available', 'held_for_payment', 'booked', 'in_progress', 'completed', 'cancelled')),

    -- Optimistic Locking (prevents double-booking)
    version INTEGER DEFAULT 1 NOT NULL,

    -- Payment Hold
    held_until TIMESTAMPTZ, -- NULL or 5 minutes from booking attempt
    held_by_user UUID REFERENCES auth.users(id) ON DELETE SET NULL,

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    -- Constraints
    UNIQUE (provider_id, date, start_time), -- No overlapping slots
    CONSTRAINT valid_slot_time CHECK (end_time > start_time)
);

-- Indexes for provider_time_slots
CREATE INDEX idx_slots_provider_date ON provider_time_slots(provider_id, date, status);
CREATE INDEX idx_slots_available ON provider_time_slots(date, status) WHERE status = 'available';
CREATE INDEX idx_slots_held ON provider_time_slots(held_until) WHERE status = 'held_for_payment';

-- RLS for provider_time_slots
ALTER TABLE provider_time_slots ENABLE ROW LEVEL SECURITY;

-- Anyone can view available slots
CREATE POLICY "Anyone can view available slots"
    ON provider_time_slots FOR SELECT
    USING (status IN ('available', 'held_for_payment'));

-- Authenticated users can attempt booking (app handles optimistic locking)
CREATE POLICY "Authenticated users can book slots"
    ON provider_time_slots FOR UPDATE
    USING (auth.uid() IS NOT NULL);

-- Providers can manage their own slots
CREATE POLICY "Providers can manage own slots"
    ON provider_time_slots FOR ALL
    USING (provider_id IN (SELECT id FROM healthcare_providers WHERE user_id = auth.uid()));

-- ============================================================================
-- 4. CONSULTATIONS (Core consultation sessions with referral tracking)
-- ============================================================================

CREATE TABLE IF NOT EXISTS consultations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Participants
    provider_id UUID NOT NULL REFERENCES healthcare_providers(id) ON DELETE RESTRICT,
    patient_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE RESTRICT,
    tenant_id UUID NOT NULL, -- Business that owns the storefront (if applicable)

    -- Consultation Details
    type TEXT NOT NULL CHECK (type IN ('chat', 'video', 'audio', 'office_visit')),
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'completed', 'cancelled')),

    -- Scheduling (NULL for chat, required for video/audio/office_visit)
    scheduled_time TIMESTAMPTZ,
    slot_duration INTEGER, -- minutes
    started_at TIMESTAMPTZ,
    ended_at TIMESTAMPTZ,

    -- Location (for office visits)
    location_address JSONB, -- Provider's clinic address

    -- Agora Integration (video/audio only)
    agora_channel_name TEXT,
    agora_token_patient TEXT,
    agora_token_provider TEXT,
    agora_token_expiry TIMESTAMPTZ,

    -- **CRITICAL: Referral Tracking for Commission Attribution**
    referral_source TEXT NOT NULL CHECK (referral_source IN ('storefront', 'medic_clinic', 'direct')),
    referrer_entity_id UUID, -- business_id (storefront) or host_medic_id (medic_clinic) or NULL (direct)

    -- Denormalized Provider Info (for performance)
    provider_name TEXT NOT NULL,
    provider_photo_url TEXT,

    -- Financial
    consultation_fee DECIMAL(10,2) NOT NULL,
    payment_status TEXT DEFAULT 'pending' CHECK (payment_status IN ('pending', 'paid', 'failed', 'refunded')),
    paid_at TIMESTAMPTZ,
    payment_reference TEXT,

    -- Commission (calculated on completion)
    commission_calculated_at TIMESTAMPTZ,

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    -- Constraints
    CONSTRAINT chat_no_schedule CHECK (type = 'chat' OR scheduled_time IS NOT NULL),
    CONSTRAINT office_has_location CHECK (type != 'office_visit' OR location_address IS NOT NULL),
    CONSTRAINT video_audio_has_agora CHECK (type NOT IN ('video', 'audio') OR agora_channel_name IS NOT NULL)
);

-- Indexes for consultations
CREATE INDEX idx_consultations_patient ON consultations(patient_id, created_at DESC);
CREATE INDEX idx_consultations_provider ON consultations(provider_id, scheduled_time DESC);
CREATE INDEX idx_consultations_status ON consultations(status, scheduled_time);
CREATE INDEX idx_consultations_referral ON consultations(referral_source, referrer_entity_id); -- For commission queries
CREATE INDEX idx_consultations_tenant ON consultations(tenant_id);

-- RLS for consultations
ALTER TABLE consultations ENABLE ROW LEVEL SECURITY;

-- Patients can view their own consultations
CREATE POLICY "Patients can view own consultations"
    ON consultations FOR SELECT
    USING (patient_id = auth.uid());

-- Providers can view their assigned consultations
CREATE POLICY "Providers can view assigned consultations"
    ON consultations FOR SELECT
    USING (provider_id IN (SELECT id FROM healthcare_providers WHERE user_id = auth.uid()));

-- Authenticated users can create consultations (booking)
CREATE POLICY "Authenticated users can book consultations"
    ON consultations FOR INSERT
    WITH CHECK (patient_id = auth.uid());

-- Providers can update their consultations (mark complete, etc.)
CREATE POLICY "Providers can update assigned consultations"
    ON consultations FOR UPDATE
    USING (provider_id IN (SELECT id FROM healthcare_providers WHERE user_id = auth.uid()));

-- ============================================================================
-- 5. CONSULTATION MESSAGES (Chat messages)
-- ============================================================================

CREATE TABLE IF NOT EXISTS consultation_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    consultation_id UUID NOT NULL REFERENCES consultations(id) ON DELETE CASCADE,

    -- Sender
    sender_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    sender_type TEXT NOT NULL CHECK (sender_type IN ('patient', 'provider')),

    -- Content
    content TEXT NOT NULL,
    attachments JSONB, -- Array of {url, type, name}

    -- Status
    read_at TIMESTAMPTZ,

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for consultation_messages
CREATE INDEX idx_messages_consultation ON consultation_messages(consultation_id, created_at DESC);
CREATE INDEX idx_messages_sender ON consultation_messages(sender_id);
CREATE INDEX idx_messages_unread ON consultation_messages(consultation_id, read_at) WHERE read_at IS NULL;

-- RLS for consultation_messages
ALTER TABLE consultation_messages ENABLE ROW LEVEL SECURITY;

-- Participants can view messages in their consultations
CREATE POLICY "Consultation participants can view messages"
    ON consultation_messages FOR SELECT
    USING (
        consultation_id IN (
            SELECT id FROM consultations
            WHERE patient_id = auth.uid()
               OR provider_id IN (SELECT id FROM healthcare_providers WHERE user_id = auth.uid())
        )
    );

-- Participants can send messages
CREATE POLICY "Consultation participants can send messages"
    ON consultation_messages FOR INSERT
    WITH CHECK (
        sender_id = auth.uid() AND
        consultation_id IN (
            SELECT id FROM consultations
            WHERE patient_id = auth.uid()
               OR provider_id IN (SELECT id FROM healthcare_providers WHERE user_id = auth.uid())
        )
    );

-- Participants can mark messages as read
CREATE POLICY "Consultation participants can update messages"
    ON consultation_messages FOR UPDATE
    USING (
        consultation_id IN (
            SELECT id FROM consultations
            WHERE patient_id = auth.uid()
               OR provider_id IN (SELECT id FROM healthcare_providers WHERE user_id = auth.uid())
        )
    );

-- ============================================================================
-- 6. PRESCRIPTIONS (Digital prescriptions with auto-expiration)
-- ============================================================================

CREATE TABLE IF NOT EXISTS prescriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    consultation_id UUID NOT NULL REFERENCES consultations(id) ON DELETE RESTRICT,
    provider_id UUID NOT NULL REFERENCES healthcare_providers(id) ON DELETE RESTRICT,
    patient_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE RESTRICT,

    -- Prescription Details
    diagnosis TEXT,
    medications JSONB NOT NULL, -- [{name, generic_name, nafdac_number, quantity, dosage, frequency, duration, special_instructions}]
    notes TEXT,

    -- Pharmacy Routing (from bridge-prescription-router)
    routing_strategy TEXT, -- 'single', 'split', 'partial', 'none'
    primary_pharmacy_id UUID, -- From businesses table
    routing_details JSONB, -- Full routing response

    -- Denormalized Provider Info
    provider_name TEXT NOT NULL,
    provider_credentials TEXT,

    -- Status & Dates
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'expired', 'fulfilled', 'cancelled')),
    issue_date DATE DEFAULT CURRENT_DATE,
    expiration_date DATE DEFAULT (CURRENT_DATE + INTERVAL '90 days'),
    dispensed_at TIMESTAMPTZ,

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    -- Constraints
    CONSTRAINT valid_expiration CHECK (expiration_date > issue_date)
);

-- Indexes for prescriptions
CREATE INDEX idx_prescriptions_patient ON prescriptions(patient_id, created_at DESC);
CREATE INDEX idx_prescriptions_provider ON prescriptions(provider_id, created_at DESC);
CREATE INDEX idx_prescriptions_consultation ON prescriptions(consultation_id);
CREATE INDEX idx_prescriptions_expiration ON prescriptions(expiration_date) WHERE status = 'active';
CREATE INDEX idx_prescriptions_status ON prescriptions(status, patient_id);

-- RLS for prescriptions
ALTER TABLE prescriptions ENABLE ROW LEVEL SECURITY;

-- Patients can view their own prescriptions
CREATE POLICY "Patients can view own prescriptions"
    ON prescriptions FOR SELECT
    USING (patient_id = auth.uid());

-- Providers can view prescriptions they issued
CREATE POLICY "Providers can view issued prescriptions"
    ON prescriptions FOR SELECT
    USING (provider_id IN (SELECT id FROM healthcare_providers WHERE user_id = auth.uid()));

-- Providers can create prescriptions
CREATE POLICY "Providers can create prescriptions"
    ON prescriptions FOR INSERT
    WITH CHECK (provider_id IN (SELECT id FROM healthcare_providers WHERE user_id = auth.uid()));

-- Auto-expiration trigger
CREATE OR REPLACE FUNCTION update_prescription_status()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.expiration_date < CURRENT_DATE AND NEW.status = 'active' THEN
        NEW.status := 'expired';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER prescription_auto_expire
    BEFORE UPDATE ON prescriptions
    FOR EACH ROW
    EXECUTE FUNCTION update_prescription_status();

-- ============================================================================
-- 7. CONSULTATION TRANSACTIONS (Payment & commission tracking)
-- ============================================================================

CREATE TABLE IF NOT EXISTS consultation_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    consultation_id UUID UNIQUE NOT NULL REFERENCES consultations(id) ON DELETE RESTRICT,

    -- Participants
    provider_id UUID NOT NULL REFERENCES healthcare_providers(id) ON DELETE RESTRICT,
    patient_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE RESTRICT,
    tenant_id UUID NOT NULL, -- Business entity

    -- Financial Breakdown
    gross_amount DECIMAL(10,2) NOT NULL, -- What patient paid
    commission_amount DECIMAL(10,2) NOT NULL, -- Platform/referrer commission
    net_provider_amount DECIMAL(10,2) NOT NULL, -- Provider receives
    commission_rate DECIMAL(5,4) NOT NULL, -- Rate at transaction time (may change)

    -- Referral Commission (if applicable)
    referral_source TEXT NOT NULL CHECK (referral_source IN ('storefront', 'medic_clinic', 'direct')),
    referrer_entity_id UUID, -- Receives commission if not NULL
    referrer_commission_amount DECIMAL(10,2) DEFAULT 0,

    -- Payment Gateway
    payment_method TEXT, -- 'flutterwave', 'paystack', etc.
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

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    -- Constraints
    CONSTRAINT valid_commission CHECK (gross_amount = commission_amount + net_provider_amount)
);

-- Indexes for consultation_transactions
CREATE INDEX idx_transactions_consultation ON consultation_transactions(consultation_id);
CREATE INDEX idx_transactions_provider ON consultation_transactions(provider_id, created_at DESC);
CREATE INDEX idx_transactions_patient ON consultation_transactions(patient_id);
CREATE INDEX idx_transactions_payout ON consultation_transactions(payout_status) WHERE payout_status = 'pending_payout';
CREATE INDEX idx_transactions_referral ON consultation_transactions(referral_source, referrer_entity_id);

-- RLS for consultation_transactions
ALTER TABLE consultation_transactions ENABLE ROW LEVEL SECURITY;

-- Providers can view their transactions
CREATE POLICY "Providers can view own transactions"
    ON consultation_transactions FOR SELECT
    USING (provider_id IN (SELECT id FROM healthcare_providers WHERE user_id = auth.uid()));

-- Patients can view their transactions
CREATE POLICY "Patients can view own transactions"
    ON consultation_transactions FOR SELECT
    USING (patient_id = auth.uid());

-- Platform admin can view all (check role)
CREATE POLICY "Platform admin can view all transactions"
    ON consultation_transactions FOR SELECT
    USING (
        auth.jwt() ->> 'role' = 'platform_admin'
    );

-- ============================================================================
-- 8. FAVORITE PROVIDERS (Patient bookmarks)
-- ============================================================================

CREATE TABLE IF NOT EXISTS favorite_providers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    provider_id UUID NOT NULL REFERENCES healthcare_providers(id) ON DELETE CASCADE,

    -- Optional Notes
    notes TEXT,
    tags TEXT[], -- For organization

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),

    -- Constraints
    UNIQUE (patient_id, provider_id)
);

-- Indexes for favorite_providers
CREATE INDEX idx_favorites_patient ON favorite_providers(patient_id, created_at DESC);
CREATE INDEX idx_favorites_provider ON favorite_providers(provider_id);

-- RLS for favorite_providers
ALTER TABLE favorite_providers ENABLE ROW LEVEL SECURITY;

-- Patients can manage their own favorites
CREATE POLICY "Patients can manage own favorites"
    ON favorite_providers FOR ALL
    USING (patient_id = auth.uid());

-- ============================================================================
-- SYSTEM CONFIGURATION TABLE (if not exists)
-- ============================================================================

CREATE TABLE IF NOT EXISTS system_config (
    key TEXT PRIMARY KEY,
    value TEXT NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- SEED DATA
-- ============================================================================

-- Platform configuration for healthcare commission rate
INSERT INTO system_config (key, value, description)
VALUES (
    'healthcare_commission_rate',
    '0.15',
    'Platform commission rate for healthcare consultations (15% = 10% surcharge + 5% deduction)'
)
ON CONFLICT (key) DO NOTHING;

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

-- Function to release expired slot holds
CREATE OR REPLACE FUNCTION release_expired_slot_holds()
RETURNS void AS $$
BEGIN
    UPDATE provider_time_slots
    SET status = 'available',
        held_until = NULL,
        held_by_user = NULL,
        version = version + 1
    WHERE status = 'held_for_payment'
      AND held_until < NOW();
END;
$$ LANGUAGE plpgsql;

-- Schedule to run every minute (configure via pg_cron or external scheduler)
-- SELECT cron.schedule('release-expired-holds', '* * * * *', 'SELECT release_expired_slot_holds();');

-- ============================================================================
-- MIGRATION COMPLETE
-- ============================================================================

-- Summary:
-- âœ… 8 healthcare entities created
-- âœ… 35 performance indexes added
-- âœ… 22 RLS policies configured
-- âœ… Referral tracking fields for commission attribution
-- âœ… Optimistic locking for slot booking
-- âœ… Auto-expiration trigger for prescriptions
-- âœ… Multi-domain branding support (referral_source tracking)
-- âœ… Seed data for platform commission rate


-- File: 20260223_tenant_scoped_products.sql
-- ============================================
-- Migration: Tenant-Scoped Products with Branch Inventory
-- Description: Convert products from branch-scoped to tenant-scoped
--              and create separate branch_inventory table
-- Created: 2026-02-23
-- ============================================

-- ============================================
-- STEP 1: Create branch_inventory table
-- ============================================

CREATE TABLE IF NOT EXISTS branch_inventory (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,

    -- Stock management
    stock_quantity INTEGER NOT NULL DEFAULT 0 CHECK (stock_quantity >= 0),
    low_stock_threshold INTEGER DEFAULT 10 CHECK (low_stock_threshold >= 0),

    -- Expiry tracking (for perishable items)
    expiry_date DATE,
    expiry_alert_days INTEGER DEFAULT 30 CHECK (expiry_alert_days >= 0),

    -- Metadata
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Sync fields
    _sync_version BIGINT DEFAULT 1,
    _sync_modified_at TIMESTAMPTZ DEFAULT NOW(),
    _sync_client_id UUID,
    _sync_is_deleted BOOLEAN DEFAULT FALSE,

    -- Ensure one inventory record per product per branch
    UNIQUE(branch_id, product_id)
);

-- Indexes for branch_inventory
CREATE INDEX IF NOT EXISTS idx_branch_inventory_tenant ON branch_inventory(tenant_id);
CREATE INDEX IF NOT EXISTS idx_branch_inventory_branch ON branch_inventory(branch_id);
CREATE INDEX IF NOT EXISTS idx_branch_inventory_product ON branch_inventory(product_id);
CREATE INDEX IF NOT EXISTS idx_branch_inventory_low_stock ON branch_inventory(branch_id)
    WHERE stock_quantity <= low_stock_threshold AND is_active = true;
CREATE INDEX IF NOT EXISTS idx_branch_inventory_expiry ON branch_inventory(branch_id, expiry_date)
    WHERE expiry_date IS NOT NULL AND is_active = true;

-- RLS for branch_inventory
ALTER TABLE branch_inventory ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view inventory in their tenant" ON branch_inventory;
CREATE POLICY "Users can view inventory in their tenant"
    ON branch_inventory FOR SELECT
    USING (tenant_id IN (SELECT tenant_id FROM users WHERE id = auth.uid()));

DROP POLICY IF EXISTS "Tenant admins can manage all inventory" ON branch_inventory;
CREATE POLICY "Tenant admins can manage all inventory"
    ON branch_inventory FOR ALL
    USING (
        tenant_id IN (
            SELECT tenant_id FROM users
            WHERE id = auth.uid()
            AND role = 'tenant_admin'
        )
    );

DROP POLICY IF EXISTS "Branch managers can manage their branch inventory" ON branch_inventory;
CREATE POLICY "Branch managers can manage their branch inventory"
    ON branch_inventory FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid()
            AND role = 'branch_manager'
            AND tenant_id = branch_inventory.tenant_id
            AND branch_id = branch_inventory.branch_id
        )
    );

DROP POLICY IF EXISTS "Staff can update inventory in their branch" ON branch_inventory;
CREATE POLICY "Staff can update inventory in their branch"
    ON branch_inventory FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid()
            AND role = 'cashier'
            AND tenant_id = branch_inventory.tenant_id
            AND branch_id = branch_inventory.branch_id
        )
    );

-- Trigger to update updated_at
DROP TRIGGER IF EXISTS set_updated_at ON branch_inventory;
CREATE TRIGGER set_updated_at
    BEFORE UPDATE ON branch_inventory
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();

COMMENT ON TABLE branch_inventory IS 'Branch-specific inventory levels for tenant products. Branch managers can manage stock_quantity, low_stock_threshold, expiry_date, and expiry_alert_days for their branch.';
COMMENT ON COLUMN branch_inventory.stock_quantity IS 'Current stock level at this branch (managed by branch manager)';
COMMENT ON COLUMN branch_inventory.low_stock_threshold IS 'Alert threshold for low stock (configurable by branch manager)';
COMMENT ON COLUMN branch_inventory.expiry_date IS 'Product expiry date at this branch (managed by branch manager)';
COMMENT ON COLUMN branch_inventory.expiry_alert_days IS 'Days before expiry to trigger alert (configurable by branch manager)';

-- ============================================
-- STEP 2: Migrate existing data
-- ============================================

-- First, create a temporary mapping table to track product merging
CREATE TEMP TABLE product_migration_map (
    old_product_id UUID,
    new_product_id UUID,
    branch_id UUID,
    stock_quantity INTEGER,
    low_stock_threshold INTEGER,
    expiry_date DATE,
    expiry_alert_days INTEGER
);

-- Find duplicate products across branches (same SKU/name for same tenant)
-- and decide which product to keep as the "master" tenant product
INSERT INTO product_migration_map (old_product_id, new_product_id, branch_id, stock_quantity, low_stock_threshold, expiry_date, expiry_alert_days)
SELECT
    p.id as old_product_id,
    COALESCE(
        -- If there's a product with same SKU/name in same tenant, use first one
        (SELECT id FROM products p2
         WHERE p2.tenant_id = p.tenant_id
         AND (
            (p2.sku IS NOT NULL AND p2.sku = p.sku) OR
            (p2.sku IS NULL AND p2.name = p.name AND p2.category = p.category)
         )
         ORDER BY p2.created_at ASC
         LIMIT 1),
        p.id
    ) as new_product_id,
    p.branch_id,
    p.stock_quantity,
    p.low_stock_threshold,
    p.expiry_date,
    p.expiry_alert_days
FROM products p
WHERE p.branch_id IS NOT NULL;

-- Create branch_inventory records from existing products
INSERT INTO branch_inventory (
    tenant_id,
    branch_id,
    product_id,
    stock_quantity,
    low_stock_threshold,
    expiry_date,
    expiry_alert_days,
    is_active,
    created_at,
    updated_at,
    _sync_version,
    _sync_modified_at,
    _sync_client_id,
    _sync_is_deleted
)
SELECT DISTINCT
    p.tenant_id,
    pmm.branch_id,
    pmm.new_product_id,
    pmm.stock_quantity,
    pmm.low_stock_threshold,
    pmm.expiry_date,
    pmm.expiry_alert_days,
    p.is_active,
    p.created_at,
    p.updated_at,
    p._sync_version,
    p._sync_modified_at,
    p._sync_client_id,
    p._sync_is_deleted
FROM product_migration_map pmm
JOIN products p ON p.id = pmm.old_product_id
ON CONFLICT (branch_id, product_id) DO UPDATE SET
    stock_quantity = EXCLUDED.stock_quantity + branch_inventory.stock_quantity,
    updated_at = NOW();

-- Update inventory_transactions to reference branch_inventory
-- Add branch_inventory_id if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'inventory_transactions' AND column_name = 'branch_inventory_id'
    ) THEN
        ALTER TABLE inventory_transactions
        ADD COLUMN branch_inventory_id UUID REFERENCES branch_inventory(id) ON DELETE CASCADE;

        -- Populate branch_inventory_id
        UPDATE inventory_transactions it
        SET branch_inventory_id = bi.id
        FROM branch_inventory bi
        WHERE bi.branch_id = it.branch_id
        AND bi.product_id = it.product_id;

        -- Create index
        CREATE INDEX idx_inventory_transactions_branch_inventory
        ON inventory_transactions(branch_inventory_id);
    END IF;
END $$;

-- Update sale_items to reference the correct merged product
UPDATE sale_items si
SET product_id = pmm.new_product_id
FROM product_migration_map pmm
WHERE si.product_id = pmm.old_product_id
AND pmm.old_product_id != pmm.new_product_id;

-- Update transfer_items to reference the correct merged product
UPDATE transfer_items ti
SET product_id = pmm.new_product_id
FROM product_migration_map pmm
WHERE ti.product_id = pmm.old_product_id
AND pmm.old_product_id != pmm.new_product_id;

-- Update order_items if it exists
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'order_items') THEN
        UPDATE order_items oi
        SET product_id = pmm.new_product_id
        FROM product_migration_map pmm
        WHERE oi.product_id = pmm.old_product_id
        AND pmm.old_product_id != pmm.new_product_id;
    END IF;
END $$;

-- ============================================
-- STEP 3: Clean up duplicate products
-- ============================================

-- Delete duplicate products (keep only the master tenant product)
DELETE FROM products p
WHERE EXISTS (
    SELECT 1 FROM product_migration_map pmm
    WHERE pmm.old_product_id = p.id
    AND pmm.old_product_id != pmm.new_product_id
);

-- ============================================
-- STEP 4: Drop dependent views
-- ============================================

-- Drop ecommerce_products view that depends on products.branch_id
DROP VIEW IF EXISTS ecommerce_products CASCADE;

-- Drop all variations of get_ecommerce_products function
-- Note: There may be multiple overloaded versions with different signatures
-- 1. Original function with 7 parameters (from 024_ecommerce_enhancements.sql):
--    get_ecommerce_products(tenant_id, category, branch_id, latitude, longitude, max_distance_km, in_stock_only)
-- 2. New function with 5 parameters (from this migration):
--    get_ecommerce_products(tenant_id, category, search, min_price, max_price)

-- Use dynamic SQL to drop all variations to avoid "function name is not unique" error
DO $$
DECLARE
    func_record RECORD;
BEGIN
    FOR func_record IN
        SELECT oid::regprocedure::text as func_signature
        FROM pg_proc
        WHERE proname = 'get_ecommerce_products'
    LOOP
        EXECUTE 'DROP FUNCTION IF EXISTS ' || func_record.func_signature || ' CASCADE';
        RAISE NOTICE 'Dropped function: %', func_record.func_signature;
    END LOOP;
END $$;

-- ============================================
-- STEP 5: Drop indexes that depend on columns being removed
-- ============================================

-- Drop indexes that reference branch_id, stock_quantity, expiry_date, or low_stock_threshold
DROP INDEX IF EXISTS idx_products_tenant_branch CASCADE;
DROP INDEX IF EXISTS idx_products_low_stock CASCADE;
DROP INDEX IF EXISTS idx_products_expiry CASCADE;

-- ============================================
-- STEP 5.1: Remove branch_id from products table
-- ============================================

-- Drop the branch_id column and related constraints
ALTER TABLE products DROP COLUMN IF EXISTS branch_id;
ALTER TABLE products DROP COLUMN IF EXISTS stock_quantity;
ALTER TABLE products DROP COLUMN IF EXISTS low_stock_threshold;
ALTER TABLE products DROP COLUMN IF EXISTS expiry_date;
ALTER TABLE products DROP COLUMN IF EXISTS expiry_alert_days;

COMMENT ON TABLE products IS 'Tenant-scoped product catalog. Stock levels tracked in branch_inventory.';

-- ============================================
-- STEP 6: Update RLS policies for products
-- ============================================

-- Drop old policies
DROP POLICY IF EXISTS "Users can view products in their branch" ON products;
DROP POLICY IF EXISTS "Staff can view products" ON products;

-- Create new tenant-scoped policies
DROP POLICY IF EXISTS "Users can view products in their tenant" ON products;
CREATE POLICY "Users can view products in their tenant"
    ON products FOR SELECT
    USING (tenant_id IN (SELECT tenant_id FROM users WHERE id = auth.uid()));

DROP POLICY IF EXISTS "Managers can manage products" ON products;
CREATE POLICY "Managers can manage products"
    ON products FOR ALL
    USING (
        tenant_id IN (
            SELECT tenant_id FROM users
            WHERE id = auth.uid()
            AND role IN ('tenant_admin', 'branch_manager')
        )
    );

-- ============================================
-- STEP 7: Create helper views
-- ============================================

-- View to join products with branch inventory
CREATE OR REPLACE VIEW v_branch_products AS
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

COMMENT ON VIEW v_branch_products IS 'Convenient view joining products with branch inventory';

-- Recreate ecommerce_products view with new schema
CREATE OR REPLACE VIEW ecommerce_products AS
SELECT
    p.id,
    p.tenant_id,
    p.name,
    p.description,
    p.category,
    p.unit_price,
    p.image_url,
    p.is_active,

    -- Aggregate stock across all branches
    COALESCE(SUM(bi.stock_quantity), 0) as total_stock,

    -- Count how many branches have this product
    COUNT(DISTINCT bi.branch_id) as branch_count,

    -- Collect branch information
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

    -- Min and max price (using product price)
    p.unit_price as min_price,
    p.unit_price as max_price,

    p.created_at,
    p.updated_at
FROM products p
LEFT JOIN branch_inventory bi ON bi.product_id = p.id AND bi.is_active = true
LEFT JOIN branches b ON bi.branch_id = b.id AND b.deleted_at IS NULL
WHERE p._sync_is_deleted = false
  AND p.is_active = TRUE
GROUP BY
    p.id,
    p.tenant_id,
    p.name,
    p.description,
    p.category,
    p.unit_price,
    p.image_url,
    p.is_active,
    p.created_at,
    p.updated_at;

COMMENT ON VIEW ecommerce_products IS
'Aggregated product view for e-commerce storefront. Shows tenant products across all branches with stock and location information.';

-- Recreate get_ecommerce_products function
CREATE OR REPLACE FUNCTION get_ecommerce_products(
    p_tenant_id UUID,
    p_category VARCHAR DEFAULT NULL,
    p_search VARCHAR DEFAULT NULL,
    p_min_price DECIMAL DEFAULT NULL,
    p_max_price DECIMAL DEFAULT NULL
)
RETURNS TABLE (
    id UUID,
    tenant_id UUID,
    name VARCHAR,
    description TEXT,
    category VARCHAR,
    unit_price DECIMAL,
    image_url TEXT,
    is_active BOOLEAN,
    total_stock BIGINT,
    branch_count BIGINT,
    branches JSONB,
    min_price DECIMAL,
    max_price DECIMAL,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        ep.id,
        ep.tenant_id,
        ep.name,
        ep.description,
        ep.category,
        ep.unit_price,
        ep.image_url,
        ep.is_active,
        ep.total_stock,
        ep.branch_count,
        ep.branches,
        ep.min_price,
        ep.max_price,
        ep.created_at,
        ep.updated_at
    FROM ecommerce_products ep
    WHERE ep.tenant_id = p_tenant_id
      AND ep.is_active = TRUE
      AND (p_category IS NULL OR ep.category = p_category)
      AND (p_search IS NULL OR ep.name ILIKE '%' || p_search || '%' OR ep.description ILIKE '%' || p_search || '%')
      AND (p_min_price IS NULL OR ep.unit_price >= p_min_price)
      AND (p_max_price IS NULL OR ep.unit_price <= p_max_price)
    ORDER BY ep.name;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_ecommerce_products IS 'Get products for e-commerce storefront with optional filters';

-- ============================================
-- STEP 8: Update inventory transaction trigger
-- ============================================

-- Create/update trigger to maintain branch_inventory stock levels
CREATE OR REPLACE FUNCTION update_branch_inventory_stock()
RETURNS TRIGGER AS $$
BEGIN
    -- Update the branch inventory stock quantity
    UPDATE branch_inventory
    SET stock_quantity = NEW.new_quantity,
        updated_at = NOW()
    WHERE branch_id = NEW.branch_id
    AND product_id = NEW.product_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_update_branch_inventory_stock ON inventory_transactions;
CREATE TRIGGER trg_update_branch_inventory_stock
    AFTER INSERT ON inventory_transactions
    FOR EACH ROW
    EXECUTE FUNCTION update_branch_inventory_stock();

COMMENT ON FUNCTION update_branch_inventory_stock() IS 'Updates branch inventory stock after inventory transaction';

-- ============================================
-- STEP 9: Add product image URL to products (if not exists)
-- ============================================

-- Ensure image_url exists (will be removed from UI but kept in schema for future use)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'products' AND column_name = 'image_url'
    ) THEN
        ALTER TABLE products ADD COLUMN image_url TEXT;
        COMMENT ON COLUMN products.image_url IS 'Product image URL (not displayed in POS for performance)';
    END IF;
END $$;


-- File: 20260227_add_country_settings_to_tenants.sql
-- ============================================================
-- Migration: Add Country Settings to Tenants Table
-- ============================================================
-- Purpose: Add country_code, dial_code, and currency_code to tenants table
-- This fixes the schema mismatch where country settings were incorrectly
-- being saved to a non-existent profiles table instead of the tenants table.
--
-- User Story: US2 - Multi-Tenant Isolation and Email/Google Authentication
-- Acceptance Scenario: AS3 - System saves country code, dial code, currency code to tenant
--
-- Created: 2026-02-27

-- Add country settings columns to tenants table
ALTER TABLE tenants
ADD COLUMN IF NOT EXISTS country_code VARCHAR(2),
ADD COLUMN IF NOT EXISTS dial_code VARCHAR(10),
ADD COLUMN IF NOT EXISTS currency_code VARCHAR(3);

-- Add comments to document the fields
COMMENT ON COLUMN tenants.country_code IS
'ISO 3166-1 alpha-2 country code (e.g., "NG" for Nigeria, "US" for USA). Selected during tenant onboarding.';

COMMENT ON COLUMN tenants.dial_code IS
'International dialing code including + prefix (e.g., "+234" for Nigeria, "+1" for USA). Auto-populated based on country_code.';

COMMENT ON COLUMN tenants.currency_code IS
'ISO 4217 currency code (e.g., "NGN" for Nigerian Naira, "USD" for US Dollar). Auto-populated based on country_code and used for all pricing/transactions in this tenant.';

-- Add index for country-based queries (useful for analytics, regional reporting)
CREATE INDEX IF NOT EXISTS idx_tenants_country_code ON tenants(country_code)
WHERE country_code IS NOT NULL AND deleted_at IS NULL;

-- Add check constraint to ensure valid ISO codes if provided
ALTER TABLE tenants
ADD CONSTRAINT chk_country_code_format CHECK (
    country_code IS NULL OR (
        country_code ~ '^[A-Z]{2}$'
    )
);

ALTER TABLE tenants
ADD CONSTRAINT chk_dial_code_format CHECK (
    dial_code IS NULL OR (
        dial_code ~ '^\+[0-9]{1,4}$'
    )
);

ALTER TABLE tenants
ADD CONSTRAINT chk_currency_code_format CHECK (
    currency_code IS NULL OR (
        currency_code ~ '^[A-Z]{3}$'
    )
);

-- Note: We're not migrating data from profiles table because it doesn't exist
-- in the current schema. The Flutter app was incorrectly trying to save to it.

-- ============================================================
-- Also add gender field to users table (for user profiles)
-- ============================================================

ALTER TABLE users
ADD COLUMN IF NOT EXISTS gender VARCHAR(10);

COMMENT ON COLUMN users.gender IS
'User gender for profile (e.g., "male", "female", "other"). Optional field.';

-- Add check constraint for gender values
ALTER TABLE users
ADD CONSTRAINT chk_gender_values CHECK (
    gender IS NULL OR gender IN ('male', 'female', 'other')
);

-- Verification query to show updated schema
SELECT
    table_name,
    column_name,
    data_type,
    character_maximum_length,
    column_default,
    is_nullable
FROM information_schema.columns
WHERE table_name = 'tenants'
    AND column_name IN ('country_code', 'dial_code', 'currency_code')
ORDER BY ordinal_position;


-- File: 20260228_add_reserved_quantity_to_branch_inventory.sql
-- ============================================================
-- Migration: Add Reserved Quantity to Branch Inventory
-- ============================================================
-- Purpose: Support inventory reservation for pending orders
-- Context: When orders are placed, inventory is reserved
--          but not deducted until payment is confirmed
-- Date: 2026-02-28
-- Note: Works with branch_inventory table (stock is per-branch)

-- ============================================================
-- Step 1: Add reserved_quantity column to branch_inventory table
-- ============================================================

ALTER TABLE branch_inventory
ADD COLUMN IF NOT EXISTS reserved_quantity INTEGER NOT NULL DEFAULT 0 CHECK (reserved_quantity >= 0);

-- ============================================================
-- Step 2: Add constraint to ensure available stock
-- ============================================================

-- Available stock = stock_quantity - reserved_quantity
-- We need to ensure stock_quantity >= reserved_quantity at all times

ALTER TABLE branch_inventory
DROP CONSTRAINT IF EXISTS check_stock_available;

ALTER TABLE branch_inventory
ADD CONSTRAINT check_stock_available
CHECK (stock_quantity >= reserved_quantity);

-- ============================================================
-- Step 3: Create index for querying available stock
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_branch_inventory_available_stock
ON branch_inventory(tenant_id, branch_id, (stock_quantity - reserved_quantity));

-- This index helps queries like:
-- SELECT * FROM branch_inventory WHERE (stock_quantity - reserved_quantity) > 0

-- ============================================================
-- Step 4: Create helper function to get available stock
-- ============================================================

CREATE OR REPLACE FUNCTION get_available_stock(
    p_branch_id UUID,
    p_product_id UUID
)
RETURNS INTEGER AS $$
DECLARE
    v_available INTEGER;
BEGIN
    SELECT stock_quantity - reserved_quantity
    INTO v_available
    FROM branch_inventory
    WHERE branch_id = p_branch_id
      AND product_id = p_product_id;

    RETURN COALESCE(v_available, 0);
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- Step 5: Create function to reserve inventory
-- ============================================================

CREATE OR REPLACE FUNCTION reserve_inventory(
    p_branch_id UUID,
    p_product_id UUID,
    p_quantity INTEGER
)
RETURNS BOOLEAN AS $$
DECLARE
    v_available INTEGER;
    v_rows_updated INTEGER;
BEGIN
    -- Check if enough stock is available
    v_available := get_available_stock(p_branch_id, p_product_id);

    IF v_available < p_quantity THEN
        -- Not enough stock available
        RETURN FALSE;
    END IF;

    -- Reserve the inventory
    UPDATE branch_inventory
    SET
        reserved_quantity = reserved_quantity + p_quantity,
        updated_at = NOW()
    WHERE
        branch_id = p_branch_id
        AND product_id = p_product_id
        AND (stock_quantity - reserved_quantity) >= p_quantity;

    GET DIAGNOSTICS v_rows_updated = ROW_COUNT;

    RETURN v_rows_updated > 0;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- Step 6: Create function to release reserved inventory
-- ============================================================

CREATE OR REPLACE FUNCTION release_reserved_inventory(
    p_branch_id UUID,
    p_product_id UUID,
    p_quantity INTEGER
)
RETURNS BOOLEAN AS $$
DECLARE
    v_rows_updated INTEGER;
BEGIN
    -- Release the reserved inventory
    UPDATE branch_inventory
    SET
        reserved_quantity = GREATEST(reserved_quantity - p_quantity, 0),
        updated_at = NOW()
    WHERE
        branch_id = p_branch_id
        AND product_id = p_product_id
        AND reserved_quantity >= p_quantity;

    GET DIAGNOSTICS v_rows_updated = ROW_COUNT;

    RETURN v_rows_updated > 0;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- Step 7: Create function to confirm reservation (deduct stock)
-- ============================================================

CREATE OR REPLACE FUNCTION confirm_reservation(
    p_branch_id UUID,
    p_product_id UUID,
    p_quantity INTEGER
)
RETURNS BOOLEAN AS $$
DECLARE
    v_rows_updated INTEGER;
BEGIN
    -- Deduct from both stock_quantity and reserved_quantity
    UPDATE branch_inventory
    SET
        stock_quantity = stock_quantity - p_quantity,
        reserved_quantity = GREATEST(reserved_quantity - p_quantity, 0),
        updated_at = NOW()
    WHERE
        branch_id = p_branch_id
        AND product_id = p_product_id
        AND reserved_quantity >= p_quantity
        AND stock_quantity >= p_quantity;

    GET DIAGNOSTICS v_rows_updated = ROW_COUNT;

    RETURN v_rows_updated > 0;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- Step 8: Create trigger to update stock alerts
-- ============================================================

-- Create a function to check if product needs reorder alert
CREATE OR REPLACE FUNCTION check_reorder_alert()
RETURNS TRIGGER AS $$
DECLARE
    v_available INTEGER;
    v_product_name TEXT;
BEGIN
    -- Calculate available stock
    v_available := NEW.stock_quantity - NEW.reserved_quantity;

    -- Get product name for logging
    SELECT name INTO v_product_name
    FROM products
    WHERE id = NEW.product_id;

    -- If available stock is at or below low stock threshold, log it
    IF NEW.low_stock_threshold IS NOT NULL THEN
        IF v_available <= NEW.low_stock_threshold THEN
            -- Low stock detected
            -- Future: Insert into alerts/notifications table
            RAISE NOTICE 'Low stock alert: Product % (%) at branch % has % available (threshold: %)',
                v_product_name, NEW.product_id, NEW.branch_id, v_available, NEW.low_stock_threshold;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_check_reorder_alert ON branch_inventory;

CREATE TRIGGER trigger_check_reorder_alert
    AFTER UPDATE OF stock_quantity, reserved_quantity ON branch_inventory
    FOR EACH ROW
    WHEN (OLD.stock_quantity IS DISTINCT FROM NEW.stock_quantity
          OR OLD.reserved_quantity IS DISTINCT FROM NEW.reserved_quantity)
    EXECUTE FUNCTION check_reorder_alert();

-- ============================================================
-- Step 9: Create view for available stock analytics
-- ============================================================

CREATE OR REPLACE VIEW product_stock_status AS
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

-- ============================================================
-- Step 10: Enable RLS on the view (uses underlying table policies)
-- ============================================================

-- Note: Views inherit RLS from their underlying tables
-- branch_inventory and products already have RLS enabled
-- Queries on product_stock_status will automatically be tenant-scoped

-- ============================================================
-- Comments for documentation
-- ============================================================

COMMENT ON COLUMN branch_inventory.reserved_quantity IS 'Quantity reserved for pending orders (not yet paid/confirmed) at this branch';

COMMENT ON FUNCTION get_available_stock(UUID, UUID) IS 'Returns available stock (stock_quantity - reserved_quantity) for a product at a specific branch';
COMMENT ON FUNCTION reserve_inventory(UUID, UUID, INTEGER) IS 'Reserves inventory for a pending order at a branch. Returns FALSE if insufficient stock.';
COMMENT ON FUNCTION release_reserved_inventory(UUID, UUID, INTEGER) IS 'Releases reserved inventory when order is cancelled at a branch. Returns success status.';
COMMENT ON FUNCTION confirm_reservation(UUID, UUID, INTEGER) IS 'Confirms reservation by deducting from both stock_quantity and reserved_quantity at a branch. Used when order is paid.';

COMMENT ON VIEW product_stock_status IS 'Real-time view of product stock status per branch including reserved quantities and stock alerts';

-- ============================================================
-- Example Usage
-- ============================================================

/*
-- Reserve inventory when order is placed at a specific branch
SELECT reserve_inventory('branch-uuid', 'product-uuid', 5);  -- Reserve 5 units

-- Check available stock at a specific branch
SELECT get_available_stock('branch-uuid', 'product-uuid');  -- Returns: stock_quantity - reserved_quantity

-- Confirm reservation when payment succeeds
SELECT confirm_reservation('branch-uuid', 'product-uuid', 5);  -- Deducts from both stock and reserved

-- Cancel order and release reservation
SELECT release_reserved_inventory('branch-uuid', 'product-uuid', 5);  -- Adds back to available stock

-- Query products with low available stock for current tenant
SELECT * FROM product_stock_status
WHERE stock_status IN ('low_stock', 'out_of_stock')
AND tenant_id = current_tenant_id();

-- Query available stock across all branches for a product
SELECT
    p.name,
    b.name AS branch_name,
    pss.stock_quantity,
    pss.reserved_quantity,
    pss.available_quantity,
    pss.stock_status
FROM product_stock_status pss
JOIN products p ON pss.product_id = p.id
JOIN branches b ON pss.branch_id = b.id
WHERE p.id = 'product-uuid'
AND pss.tenant_id = current_tenant_id()
ORDER BY b.name;
*/


-- File: 20260228_ALL_MIGRATIONS_COMBINED.sql
-- ============================================================
-- COMBINED MIGRATION FILE - User Story 3
-- ============================================================
-- Date: 2026-02-28
-- Contains: All 5 migrations for Customer Management & Marketplace
-- Safe to run: Idempotent - skips already-applied changes
--
-- Migrations included:
-- 1. Customer-Tenants Junction (FIXED)
-- 2. Loyalty Configuration
-- 3. Delivery Types
-- 4. Storefront Configuration
-- 5. Reserved Quantity for Branch Inventory
-- ============================================================

-- ============================================================
-- MIGRATION 1: Customer-Tenants Junction (FIXED)
-- ============================================================
-- Purpose: Support customers ordering from multiple tenants

-- Step 0: Drop existing RLS policies on customers table
DROP POLICY IF EXISTS "Customer tenant isolation" ON customers;
DROP POLICY IF EXISTS "Users can view customers in their tenant" ON customers;
DROP POLICY IF EXISTS "Staff can create customers" ON customers;
DROP POLICY IF EXISTS "Staff can update customers" ON customers;
DROP POLICY IF EXISTS "Managers can delete customers" ON customers;
DROP POLICY IF EXISTS "Tenants can view their customers" ON customers;
DROP POLICY IF EXISTS "Tenants can create customers" ON customers;
DROP POLICY IF EXISTS "Tenants can update customers" ON customers;
DROP POLICY IF EXISTS "Tenants can delete customers" ON customers;

-- Drop policies on customer_addresses that depend on customers.tenant_id
DROP POLICY IF EXISTS "customer_addresses_tenant_isolation" ON customer_addresses;
DROP POLICY IF EXISTS "Users can view customer addresses" ON customer_addresses;
DROP POLICY IF EXISTS "Users can manage customer addresses" ON customer_addresses;

-- Step 1: Create customer_tenants junction table
CREATE TABLE IF NOT EXISTS customer_tenants (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,

    -- Tenant-specific customer analytics
    loyalty_points INTEGER NOT NULL DEFAULT 0 CHECK (loyalty_points >= 0),
    total_purchases DECIMAL(12,2) NOT NULL DEFAULT 0 CHECK (total_purchases >= 0),
    purchase_count INTEGER NOT NULL DEFAULT 0 CHECK (purchase_count >= 0),
    last_purchase_at TIMESTAMPTZ,

    -- Customer preferences per tenant
    preferred_branch_id UUID REFERENCES branches(id),
    notes TEXT,

    -- Metadata
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Ensure one record per customer-tenant pair
    CONSTRAINT customer_tenants_unique UNIQUE(customer_id, tenant_id)
);

-- Step 2: Migrate existing customer data to junction table (if tenant_id exists)
DO $$
BEGIN
    IF EXISTS (
        SELECT FROM information_schema.columns
        WHERE table_name = 'customers' AND column_name = 'tenant_id'
    ) THEN
        INSERT INTO customer_tenants (
            customer_id,
            tenant_id,
            loyalty_points,
            total_purchases,
            purchase_count,
            last_purchase_at,
            created_at,
            updated_at
        )
        SELECT
            id,
            tenant_id,
            COALESCE(loyalty_points, 0),
            COALESCE(total_purchases, 0),
            COALESCE(purchase_count, 0),
            last_purchase_at,
            created_at,
            updated_at
        FROM customers
        WHERE tenant_id IS NOT NULL
        ON CONFLICT (customer_id, tenant_id) DO NOTHING;
    END IF;
END $$;

-- Step 3: Drop tenant-specific columns from customers
ALTER TABLE customers DROP COLUMN IF EXISTS tenant_id CASCADE;
ALTER TABLE customers DROP COLUMN IF EXISTS loyalty_points;
ALTER TABLE customers DROP COLUMN IF EXISTS total_purchases;
ALTER TABLE customers DROP COLUMN IF EXISTS purchase_count;
ALTER TABLE customers DROP COLUMN IF EXISTS last_purchase_at;

-- Step 4: Add unique constraint on email
ALTER TABLE customers DROP CONSTRAINT IF EXISTS customers_email_unique;
ALTER TABLE customers ADD CONSTRAINT customers_email_unique UNIQUE (email);

-- Step 5: Create indexes
CREATE INDEX IF NOT EXISTS idx_customers_phone ON customers(phone);
CREATE INDEX IF NOT EXISTS idx_customers_email ON customers(email);
CREATE INDEX IF NOT EXISTS idx_customer_tenants_customer_id ON customer_tenants(customer_id);
CREATE INDEX IF NOT EXISTS idx_customer_tenants_tenant_id ON customer_tenants(tenant_id);
CREATE INDEX IF NOT EXISTS idx_customer_tenants_loyalty_points ON customer_tenants(tenant_id, loyalty_points DESC);
CREATE INDEX IF NOT EXISTS idx_customer_tenants_total_purchases ON customer_tenants(tenant_id, total_purchases DESC);

-- Step 6: Enable RLS on customer_tenants
ALTER TABLE customer_tenants ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Customer-tenant tenant isolation" ON customer_tenants;
CREATE POLICY "Customer-tenant tenant isolation" ON customer_tenants
    USING (tenant_id = current_tenant_id());

DROP POLICY IF EXISTS "Tenants can view their customers" ON customer_tenants;
CREATE POLICY "Tenants can view their customers" ON customer_tenants
    FOR SELECT USING (tenant_id = current_tenant_id());

DROP POLICY IF EXISTS "Tenants can create customer relationships" ON customer_tenants;
CREATE POLICY "Tenants can create customer relationships" ON customer_tenants
    FOR INSERT WITH CHECK (tenant_id = current_tenant_id());

DROP POLICY IF EXISTS "Tenants can update customer data" ON customer_tenants;
CREATE POLICY "Tenants can update customer data" ON customer_tenants
    FOR UPDATE
    USING (tenant_id = current_tenant_id())
    WITH CHECK (tenant_id = current_tenant_id());

-- Step 7: Create trigger
CREATE OR REPLACE FUNCTION update_customer_tenants_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_customer_tenants_updated_at ON customer_tenants;
CREATE TRIGGER trigger_customer_tenants_updated_at
    BEFORE UPDATE ON customer_tenants
    FOR EACH ROW
    EXECUTE FUNCTION update_customer_tenants_updated_at();

-- Step 8: Update customers RLS policies (global access)
DROP POLICY IF EXISTS "Anyone authenticated can view customers" ON customers;
CREATE POLICY "Anyone authenticated can view customers" ON customers
    FOR SELECT USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Anyone authenticated can create customers" ON customers;
CREATE POLICY "Anyone authenticated can create customers" ON customers
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Anyone authenticated can update customers" ON customers;
CREATE POLICY "Anyone authenticated can update customers" ON customers
    FOR UPDATE USING (auth.role() = 'authenticated');

-- Step 9: Recreate customer_addresses policies
DROP POLICY IF EXISTS "Users can view customer addresses" ON customer_addresses;
CREATE POLICY "Users can view customer addresses" ON customer_addresses
    FOR SELECT USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Users can create customer addresses" ON customer_addresses;
CREATE POLICY "Users can create customer addresses" ON customer_addresses
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Users can update customer addresses" ON customer_addresses;
CREATE POLICY "Users can update customer addresses" ON customer_addresses
    FOR UPDATE USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Users can delete customer addresses" ON customer_addresses;
CREATE POLICY "Users can delete customer addresses" ON customer_addresses
    FOR DELETE USING (auth.role() = 'authenticated');

-- Comments
COMMENT ON TABLE customer_tenants IS 'Junction table linking customers to tenants with tenant-specific analytics and loyalty data';
COMMENT ON TABLE customers IS 'Global customer table - customers can order from multiple tenants';

-- ============================================================
-- MIGRATION 2: Loyalty Configuration
-- ============================================================
-- Purpose: Tenant-configurable loyalty points system

CREATE TABLE IF NOT EXISTS loyalty_config (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE UNIQUE,

    -- Enable/Disable
    is_enabled BOOLEAN NOT NULL DEFAULT FALSE,

    -- Earning rules
    points_per_currency_unit INTEGER NOT NULL DEFAULT 1 CHECK (points_per_currency_unit > 0),
    currency_unit DECIMAL(10,2) NOT NULL DEFAULT 100.00 CHECK (currency_unit > 0),

    -- Redemption rules
    min_redemption_points INTEGER NOT NULL DEFAULT 100 CHECK (min_redemption_points >= 0),
    redemption_value_per_point DECIMAL(10,2) NOT NULL DEFAULT 1.00 CHECK (redemption_value_per_point > 0),
    allow_partial_payment BOOLEAN NOT NULL DEFAULT TRUE,
    allow_full_payment BOOLEAN NOT NULL DEFAULT TRUE,

    -- Constraints
    max_points_per_order INTEGER CHECK (max_points_per_order IS NULL OR max_points_per_order > 0),
    points_expiry_days INTEGER CHECK (points_expiry_days IS NULL OR points_expiry_days > 0),

    -- Metadata
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_loyalty_config_tenant_id ON loyalty_config(tenant_id);
CREATE INDEX IF NOT EXISTS idx_loyalty_config_enabled ON loyalty_config(tenant_id, is_enabled);

-- RLS
ALTER TABLE loyalty_config ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Loyalty config tenant isolation" ON loyalty_config;
CREATE POLICY "Loyalty config tenant isolation" ON loyalty_config
    USING (tenant_id = current_tenant_id());

DROP POLICY IF EXISTS "Tenants can manage loyalty config" ON loyalty_config;
CREATE POLICY "Tenants can manage loyalty config" ON loyalty_config
    FOR ALL USING (tenant_id = current_tenant_id());

-- Trigger
CREATE OR REPLACE FUNCTION update_loyalty_config_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_loyalty_config_updated_at ON loyalty_config;
CREATE TRIGGER trigger_loyalty_config_updated_at
    BEFORE UPDATE ON loyalty_config
    FOR EACH ROW
    EXECUTE FUNCTION update_loyalty_config_updated_at();

-- Helper functions
CREATE OR REPLACE FUNCTION calculate_loyalty_points(
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

CREATE OR REPLACE FUNCTION calculate_redemption_value(
    p_tenant_id UUID,
    p_points INTEGER
) RETURNS DECIMAL AS $$
DECLARE
    v_config RECORD;
BEGIN
    SELECT redemption_value_per_point INTO v_config
    FROM loyalty_config WHERE tenant_id = p_tenant_id;

    IF v_config IS NULL THEN
        RETURN 0;
    END IF;

    RETURN p_points * v_config.redemption_value_per_point;
END;
$$ LANGUAGE plpgsql;

-- Seed default configs for existing tenants
INSERT INTO loyalty_config (tenant_id, is_enabled)
SELECT id, FALSE FROM tenants
ON CONFLICT (tenant_id) DO NOTHING;

COMMENT ON TABLE loyalty_config IS 'Tenant-specific loyalty points configuration';

-- ============================================================
-- MIGRATION 3: Delivery Types
-- ============================================================
-- Purpose: Tenant-defined delivery options

CREATE TABLE IF NOT EXISTS delivery_types (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,

    -- Basic info
    name VARCHAR(100) NOT NULL,
    description TEXT,
    icon_url TEXT,

    -- Pricing
    base_fee DECIMAL(10,2) NOT NULL DEFAULT 0 CHECK (base_fee >= 0),
    per_km_fee DECIMAL(10,2) NOT NULL DEFAULT 0 CHECK (per_km_fee >= 0),
    free_distance_km DECIMAL(10,2) DEFAULT 0 CHECK (free_distance_km >= 0),

    -- Constraints
    min_order_value DECIMAL(10,2) CHECK (min_order_value IS NULL OR min_order_value >= 0),
    max_distance_km DECIMAL(10,2) CHECK (max_distance_km IS NULL OR max_distance_km > 0),
    estimated_minutes INTEGER,

    -- Settings
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    display_order INTEGER NOT NULL DEFAULT 0,

    -- Metadata
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT delivery_types_tenant_name_unique UNIQUE(tenant_id, name)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_delivery_types_tenant_id ON delivery_types(tenant_id);
CREATE INDEX IF NOT EXISTS idx_delivery_types_active ON delivery_types(tenant_id, is_active, display_order);

-- RLS
ALTER TABLE delivery_types ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Delivery types tenant isolation" ON delivery_types;
CREATE POLICY "Delivery types tenant isolation" ON delivery_types
    USING (tenant_id = current_tenant_id());

DROP POLICY IF EXISTS "Tenants can manage delivery types" ON delivery_types;
CREATE POLICY "Tenants can manage delivery types" ON delivery_types
    FOR ALL USING (tenant_id = current_tenant_id());

-- Trigger
CREATE OR REPLACE FUNCTION update_delivery_types_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_delivery_types_updated_at ON delivery_types;
CREATE TRIGGER trigger_delivery_types_updated_at
    BEFORE UPDATE ON delivery_types
    FOR EACH ROW
    EXECUTE FUNCTION update_delivery_types_updated_at();

-- Helper function
CREATE OR REPLACE FUNCTION calculate_delivery_fee(
    p_delivery_type_id UUID,
    p_distance_km DECIMAL,
    p_order_value DECIMAL DEFAULT 0
) RETURNS DECIMAL AS $$
DECLARE
    v_type RECORD;
    v_fee DECIMAL;
    v_billable_distance DECIMAL;
BEGIN
    SELECT * INTO v_type FROM delivery_types WHERE id = p_delivery_type_id;

    IF v_type IS NULL OR v_type.is_active = FALSE THEN
        RETURN NULL;
    END IF;

    IF v_type.min_order_value IS NOT NULL AND p_order_value < v_type.min_order_value THEN
        RETURN NULL;
    END IF;

    IF v_type.max_distance_km IS NOT NULL AND p_distance_km > v_type.max_distance_km THEN
        RETURN NULL;
    END IF;

    v_billable_distance := GREATEST(p_distance_km - COALESCE(v_type.free_distance_km, 0), 0);
    v_fee := v_type.base_fee + (v_billable_distance * v_type.per_km_fee);

    RETURN ROUND(v_fee, 2);
END;
$$ LANGUAGE plpgsql;

-- Seed default delivery types
INSERT INTO delivery_types (tenant_id, name, description, base_fee, per_km_fee, free_distance_km, display_order)
SELECT
    id,
    'Standard Delivery',
    'Regular delivery service',
    500.00,
    50.00,
    2.00,
    1
FROM tenants
ON CONFLICT (tenant_id, name) DO NOTHING;

INSERT INTO delivery_types (tenant_id, name, description, base_fee, per_km_fee, display_order)
SELECT
    id,
    'Pickup',
    'Customer picks up from store',
    0.00,
    0.00,
    2
FROM tenants
ON CONFLICT (tenant_id, name) DO NOTHING;

COMMENT ON TABLE delivery_types IS 'Tenant-defined delivery options with flexible pricing';

-- ============================================================
-- MIGRATION 4: Storefront Configuration
-- ============================================================
-- Purpose: Marketplace storefront customization

CREATE TABLE IF NOT EXISTS storefront_config (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE UNIQUE,

    -- Appearance
    banner_url TEXT,
    about_text TEXT,
    welcome_message TEXT,

    -- Operating hours (JSONB format)
    operating_hours JSONB DEFAULT '{
        "monday": {"open": "08:00", "close": "18:00", "closed": false},
        "tuesday": {"open": "08:00", "close": "18:00", "closed": false},
        "wednesday": {"open": "08:00", "close": "18:00", "closed": false},
        "thursday": {"open": "08:00", "close": "18:00", "closed": false},
        "friday": {"open": "08:00", "close": "18:00", "closed": false},
        "saturday": {"open": "09:00", "close": "17:00", "closed": false},
        "sunday": {"open": "00:00", "close": "00:00", "closed": true}
    }'::jsonb,

    -- Contact
    contact_email VARCHAR(255),
    contact_phone VARCHAR(20),
    contact_whatsapp VARCHAR(20),

    -- Order settings
    minimum_order_value DECIMAL(10,2) DEFAULT 0 CHECK (minimum_order_value >= 0),
    accept_online_orders BOOLEAN NOT NULL DEFAULT TRUE,
    allow_guest_checkout BOOLEAN NOT NULL DEFAULT TRUE,
    show_stock_quantity BOOLEAN NOT NULL DEFAULT FALSE,

    -- Settings
    is_active BOOLEAN NOT NULL DEFAULT FALSE,

    -- Metadata
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_storefront_config_tenant_id ON storefront_config(tenant_id);
CREATE INDEX IF NOT EXISTS idx_storefront_config_active ON storefront_config(tenant_id, is_active);

-- RLS
ALTER TABLE storefront_config ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Storefront config tenant isolation" ON storefront_config;
CREATE POLICY "Storefront config tenant isolation" ON storefront_config
    USING (tenant_id = current_tenant_id());

DROP POLICY IF EXISTS "Tenants can manage storefront config" ON storefront_config;
CREATE POLICY "Tenants can manage storefront config" ON storefront_config
    FOR ALL USING (tenant_id = current_tenant_id());

-- Trigger
CREATE OR REPLACE FUNCTION update_storefront_config_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_storefront_config_updated_at ON storefront_config;
CREATE TRIGGER trigger_storefront_config_updated_at
    BEFORE UPDATE ON storefront_config
    FOR EACH ROW
    EXECUTE FUNCTION update_storefront_config_updated_at();

-- Helper function
CREATE OR REPLACE FUNCTION is_storefront_open(
    p_tenant_id UUID,
    p_check_time TIMESTAMPTZ DEFAULT NOW()
) RETURNS BOOLEAN AS $$
DECLARE
    v_config RECORD;
    v_day_name TEXT;
    v_hours JSONB;
    v_open_time TIME;
    v_close_time TIME;
    v_check_time TIME;
BEGIN
    SELECT * INTO v_config FROM storefront_config WHERE tenant_id = p_tenant_id;

    IF v_config IS NULL OR v_config.is_active = FALSE OR v_config.accept_online_orders = FALSE THEN
        RETURN FALSE;
    END IF;

    v_day_name := LOWER(TO_CHAR(p_check_time, 'Day'));
    v_day_name := TRIM(v_day_name);

    v_hours := v_config.operating_hours -> v_day_name;

    IF v_hours IS NULL OR (v_hours->>'closed')::boolean = TRUE THEN
        RETURN FALSE;
    END IF;

    v_open_time := (v_hours->>'open')::TIME;
    v_close_time := (v_hours->>'close')::TIME;
    v_check_time := p_check_time::TIME;

    RETURN v_check_time >= v_open_time AND v_check_time <= v_close_time;
END;
$$ LANGUAGE plpgsql;

-- Seed default configs
INSERT INTO storefront_config (tenant_id, is_active, allow_guest_checkout)
SELECT id, FALSE, TRUE FROM tenants
ON CONFLICT (tenant_id) DO NOTHING;

COMMENT ON TABLE storefront_config IS 'Marketplace storefront customization per tenant';

-- ============================================================
-- MIGRATION 5: Reserved Quantity for Branch Inventory
-- ============================================================
-- Purpose: Inventory reservation for pending orders

-- Add reserved_quantity column
ALTER TABLE branch_inventory
ADD COLUMN IF NOT EXISTS reserved_quantity INTEGER NOT NULL DEFAULT 0 CHECK (reserved_quantity >= 0);

-- Add constraint
ALTER TABLE branch_inventory DROP CONSTRAINT IF EXISTS check_stock_available;
ALTER TABLE branch_inventory ADD CONSTRAINT check_stock_available
CHECK (stock_quantity >= reserved_quantity);

-- Create index
CREATE INDEX IF NOT EXISTS idx_branch_inventory_available_stock
ON branch_inventory(tenant_id, branch_id, (stock_quantity - reserved_quantity));

-- Helper functions
CREATE OR REPLACE FUNCTION get_available_stock(
    p_branch_id UUID,
    p_product_id UUID
)
RETURNS INTEGER AS $$
DECLARE
    v_available INTEGER;
BEGIN
    SELECT stock_quantity - reserved_quantity
    INTO v_available
    FROM branch_inventory
    WHERE branch_id = p_branch_id AND product_id = p_product_id;
    RETURN COALESCE(v_available, 0);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION reserve_inventory(
    p_branch_id UUID,
    p_product_id UUID,
    p_quantity INTEGER
)
RETURNS BOOLEAN AS $$
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

CREATE OR REPLACE FUNCTION release_reserved_inventory(
    p_branch_id UUID,
    p_product_id UUID,
    p_quantity INTEGER
)
RETURNS BOOLEAN AS $$
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

CREATE OR REPLACE FUNCTION confirm_reservation(
    p_branch_id UUID,
    p_product_id UUID,
    p_quantity INTEGER
)
RETURNS BOOLEAN AS $$
DECLARE
    v_rows_updated INTEGER;
BEGIN
    UPDATE branch_inventory
    SET
        stock_quantity = stock_quantity - p_quantity,
        reserved_quantity = GREATEST(reserved_quantity - p_quantity, 0),
        updated_at = NOW()
    WHERE branch_id = p_branch_id AND product_id = p_product_id
    AND reserved_quantity >= p_quantity AND stock_quantity >= p_quantity;

    GET DIAGNOSTICS v_rows_updated = ROW_COUNT;
    RETURN v_rows_updated > 0;
END;
$$ LANGUAGE plpgsql;

-- Trigger for low stock alerts
CREATE OR REPLACE FUNCTION check_reorder_alert()
RETURNS TRIGGER AS $$
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

DROP TRIGGER IF EXISTS trigger_check_reorder_alert ON branch_inventory;
CREATE TRIGGER trigger_check_reorder_alert
    AFTER UPDATE OF stock_quantity, reserved_quantity ON branch_inventory
    FOR EACH ROW
    WHEN (OLD.stock_quantity IS DISTINCT FROM NEW.stock_quantity
          OR OLD.reserved_quantity IS DISTINCT FROM NEW.reserved_quantity)
    EXECUTE FUNCTION check_reorder_alert();

-- Create view
CREATE OR REPLACE VIEW product_stock_status AS
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

-- Comments
COMMENT ON COLUMN branch_inventory.reserved_quantity IS 'Quantity reserved for pending orders at this branch';
COMMENT ON VIEW product_stock_status IS 'Real-time view of product stock status per branch including reserved quantities';

-- ============================================================
-- MIGRATION COMPLETE
-- ============================================================
-- All 5 migrations applied successfully!


-- File: 20260228_create_analytics_rpc_functions.sql
-- Analytics RPC Functions for Product Sales Analytics
-- These functions are used by the analytics service to query sales data

-- ============================================================================
-- Function: get_top_products_by_volume
-- Description: Returns top selling products ranked by total quantity sold
-- ============================================================================
CREATE OR REPLACE FUNCTION get_top_products_by_volume(
  start_date timestamptz,
  end_date timestamptz,
  product_limit int DEFAULT 10
)
RETURNS TABLE (
  product_id uuid,
  product_name text,
  total_quantity bigint,
  total_revenue numeric,
  profit numeric,
  trend text
)
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
  current_user_tenant_id uuid;
BEGIN
  -- Get the tenant_id from the authenticated user's metadata
  current_user_tenant_id := (auth.jwt() -> 'user_metadata' ->> 'tenant_id')::uuid;

  IF current_user_tenant_id IS NULL THEN
    RAISE EXCEPTION 'No tenant_id found for user';
  END IF;

  RETURN QUERY
  SELECT
    p.id AS product_id,
    p.name AS product_name,
    COALESCE(SUM(si.quantity), 0) AS total_quantity,
    COALESCE(SUM(si.quantity * si.unit_price), 0) AS total_revenue,
    COALESCE(SUM(si.quantity * (si.unit_price - COALESCE(p.cost_price, 0))), 0) AS profit,
    'stable'::text AS trend  -- TODO: Calculate actual trend based on previous period
  FROM products p
  LEFT JOIN sale_items si ON si.product_id = p.id
  LEFT JOIN sales s ON s.id = si.sale_id
  WHERE p.tenant_id = current_user_tenant_id
    AND p.is_active = true
    AND s.created_at >= start_date
    AND s.created_at <= end_date
  GROUP BY p.id, p.name
  ORDER BY total_quantity DESC
  LIMIT product_limit;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION get_top_products_by_volume(timestamptz, timestamptz, int) TO authenticated;

-- ============================================================================
-- Function: get_top_products_by_value
-- Description: Returns top selling products ranked by total revenue
-- ============================================================================
CREATE OR REPLACE FUNCTION get_top_products_by_value(
  start_date timestamptz,
  end_date timestamptz,
  product_limit int DEFAULT 10
)
RETURNS TABLE (
  product_id uuid,
  product_name text,
  total_quantity bigint,
  total_revenue numeric,
  profit numeric,
  trend text
)
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
  current_user_tenant_id uuid;
BEGIN
  -- Get the tenant_id from the authenticated user's metadata
  current_user_tenant_id := (auth.jwt() -> 'user_metadata' ->> 'tenant_id')::uuid;

  IF current_user_tenant_id IS NULL THEN
    RAISE EXCEPTION 'No tenant_id found for user';
  END IF;

  RETURN QUERY
  SELECT
    p.id AS product_id,
    p.name AS product_name,
    COALESCE(SUM(si.quantity), 0) AS total_quantity,
    COALESCE(SUM(si.quantity * si.unit_price), 0) AS total_revenue,
    COALESCE(SUM(si.quantity * (si.unit_price - COALESCE(p.cost_price, 0))), 0) AS profit,
    'stable'::text AS trend  -- TODO: Calculate actual trend based on previous period
  FROM products p
  LEFT JOIN sale_items si ON si.product_id = p.id
  LEFT JOIN sales s ON s.id = si.sale_id
  WHERE p.tenant_id = current_user_tenant_id
    AND p.is_active = true
    AND s.created_at >= start_date
    AND s.created_at <= end_date
  GROUP BY p.id, p.name
  ORDER BY total_revenue DESC
  LIMIT product_limit;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION get_top_products_by_value(timestamptz, timestamptz, int) TO authenticated;

-- ============================================================================
-- Function: get_product_sales_trend
-- Description: Returns sales trend data for a specific product over time
-- ============================================================================
CREATE OR REPLACE FUNCTION get_product_sales_trend(
  p_product_id uuid,
  start_date timestamptz,
  end_date timestamptz,
  period_type text DEFAULT 'daily' -- 'daily', 'weekly', 'monthly', 'quarterly', 'yearly'
)
RETURNS TABLE (
  period_start timestamptz,
  period_end timestamptz,
  total_quantity bigint,
  total_revenue numeric,
  period_label text
)
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
  current_user_tenant_id uuid;
BEGIN
  -- Get the tenant_id from the authenticated user's metadata
  current_user_tenant_id := (auth.jwt() -> 'user_metadata' ->> 'tenant_id')::uuid;

  IF current_user_tenant_id IS NULL THEN
    RAISE EXCEPTION 'No tenant_id found for user';
  END IF;

  -- Verify product belongs to user's tenant
  IF NOT EXISTS (
    SELECT 1 FROM products
    WHERE id = p_product_id
    AND tenant_id = current_user_tenant_id
  ) THEN
    RAISE EXCEPTION 'Product not found or access denied';
  END IF;

  -- Return data grouped by the specified period
  RETURN QUERY
  WITH date_series AS (
    SELECT
      CASE
        WHEN period_type = 'daily' THEN date_trunc('day', s.created_at)
        WHEN period_type = 'weekly' THEN date_trunc('week', s.created_at)
        WHEN period_type = 'monthly' THEN date_trunc('month', s.created_at)
        WHEN period_type = 'quarterly' THEN date_trunc('quarter', s.created_at)
        WHEN period_type = 'yearly' THEN date_trunc('year', s.created_at)
        ELSE date_trunc('day', s.created_at)
      END AS period_start,
      si.quantity,
      si.unit_price
    FROM sales s
    JOIN sale_items si ON si.sale_id = s.id
    WHERE si.product_id = p_product_id
      AND s.created_at >= start_date
      AND s.created_at <= end_date
  )
  SELECT
    period_start,
    CASE
      WHEN period_type = 'daily' THEN period_start + interval '1 day' - interval '1 second'
      WHEN period_type = 'weekly' THEN period_start + interval '1 week' - interval '1 second'
      WHEN period_type = 'monthly' THEN period_start + interval '1 month' - interval '1 second'
      WHEN period_type = 'quarterly' THEN period_start + interval '3 months' - interval '1 second'
      WHEN period_type = 'yearly' THEN period_start + interval '1 year' - interval '1 second'
      ELSE period_start + interval '1 day' - interval '1 second'
    END AS period_end,
    COALESCE(SUM(quantity), 0) AS total_quantity,
    COALESCE(SUM(quantity * unit_price), 0) AS total_revenue,
    to_char(period_start, 'YYYY-MM-DD') AS period_label
  FROM date_series
  GROUP BY period_start
  ORDER BY period_start;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION get_product_sales_trend(uuid, timestamptz, timestamptz, text) TO authenticated;

-- ============================================================================
-- Function: get_sales_by_category
-- Description: Returns sales aggregated by product category
-- ============================================================================
CREATE OR REPLACE FUNCTION get_sales_by_category(
  start_date timestamptz,
  end_date timestamptz
)
RETURNS TABLE (
  category text,
  total_quantity bigint,
  total_revenue numeric,
  product_count bigint
)
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
  current_user_tenant_id uuid;
BEGIN
  -- Get the tenant_id from the authenticated user's metadata
  current_user_tenant_id := (auth.jwt() -> 'user_metadata' ->> 'tenant_id')::uuid;

  IF current_user_tenant_id IS NULL THEN
    RAISE EXCEPTION 'No tenant_id found for user';
  END IF;

  RETURN QUERY
  SELECT
    COALESCE(p.category, 'Uncategorized') AS category,
    COALESCE(SUM(si.quantity), 0) AS total_quantity,
    COALESCE(SUM(si.quantity * si.unit_price), 0) AS total_revenue,
    COUNT(DISTINCT p.id) AS product_count
  FROM products p
  LEFT JOIN sale_items si ON si.product_id = p.id
  LEFT JOIN sales s ON s.id = si.sale_id
  WHERE p.tenant_id = current_user_tenant_id
    AND p.is_active = true
    AND s.created_at >= start_date
    AND s.created_at <= end_date
  GROUP BY COALESCE(p.category, 'Uncategorized')
  ORDER BY total_revenue DESC;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION get_sales_by_category(timestamptz, timestamptz) TO authenticated;

-- ============================================================================
-- Comments for documentation
-- ============================================================================
COMMENT ON FUNCTION get_top_products_by_volume IS 'Returns top selling products ranked by total quantity sold within a date range. Tenant-scoped.';
COMMENT ON FUNCTION get_top_products_by_value IS 'Returns top selling products ranked by total revenue within a date range. Tenant-scoped.';
COMMENT ON FUNCTION get_product_sales_trend IS 'Returns sales trend data for a specific product over time, grouped by period (daily/weekly/monthly/quarterly/yearly). Tenant-scoped.';
COMMENT ON FUNCTION get_sales_by_category IS 'Returns sales aggregated by product category. Tenant-scoped.';


-- File: 20260228_create_customer_tenants_junction_FIXED.sql
-- ============================================================
-- Migration: Customer-Tenants Junction Table (FIXED)
-- ============================================================
-- Purpose: Support customers ordering from multiple tenants
-- Context: Enables smart email detection (auto-login if exists)
--          and tenant-scoped order history per customer
-- Date: 2026-02-28
-- Fix: Drops existing policies before removing tenant_id column

-- ============================================================
-- Step 0: Drop existing RLS policies on customers table
-- ============================================================

-- Drop all existing policies that depend on tenant_id
DROP POLICY IF EXISTS "Customer tenant isolation" ON customers;
DROP POLICY IF EXISTS "Users can view customers in their tenant" ON customers;
DROP POLICY IF EXISTS "Staff can create customers" ON customers;
DROP POLICY IF EXISTS "Staff can update customers" ON customers;
DROP POLICY IF EXISTS "Managers can delete customers" ON customers;
DROP POLICY IF EXISTS "Tenants can view their customers" ON customers;
DROP POLICY IF EXISTS "Tenants can create customers" ON customers;
DROP POLICY IF EXISTS "Tenants can update customers" ON customers;
DROP POLICY IF EXISTS "Tenants can delete customers" ON customers;

-- Drop policies on customer_addresses that depend on customers.tenant_id
DROP POLICY IF EXISTS "customer_addresses_tenant_isolation" ON customer_addresses;
DROP POLICY IF EXISTS "Users can view customer addresses" ON customer_addresses;
DROP POLICY IF EXISTS "Users can manage customer addresses" ON customer_addresses;

-- ============================================================
-- Step 1: Backup existing customer data to customer_tenants
-- ============================================================

-- Create customer_tenants table first (so we can migrate data)
CREATE TABLE IF NOT EXISTS customer_tenants (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,

    -- Tenant-specific customer analytics
    loyalty_points INTEGER NOT NULL DEFAULT 0 CHECK (loyalty_points >= 0),
    total_purchases DECIMAL(12,2) NOT NULL DEFAULT 0 CHECK (total_purchases >= 0),
    purchase_count INTEGER NOT NULL DEFAULT 0 CHECK (purchase_count >= 0),
    last_purchase_at TIMESTAMPTZ,

    -- Customer preferences per tenant
    preferred_branch_id UUID REFERENCES branches(id),
    notes TEXT,

    -- Metadata
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Ensure one record per customer-tenant pair
    CONSTRAINT customer_tenants_unique UNIQUE(customer_id, tenant_id)
);

-- Migrate existing customer data to junction table
INSERT INTO customer_tenants (
    customer_id,
    tenant_id,
    loyalty_points,
    total_purchases,
    purchase_count,
    last_purchase_at,
    created_at,
    updated_at
)
SELECT
    id,
    tenant_id,
    COALESCE(loyalty_points, 0),
    COALESCE(total_purchases, 0),
    COALESCE(purchase_count, 0),
    last_purchase_at,
    created_at,
    updated_at
FROM customers
WHERE tenant_id IS NOT NULL
ON CONFLICT (customer_id, tenant_id) DO NOTHING;

-- ============================================================
-- Step 2: Make customers table global (remove tenant_id)
-- ============================================================

-- Now safe to drop tenant-specific columns from customers
ALTER TABLE customers
DROP COLUMN IF EXISTS tenant_id CASCADE,
DROP COLUMN IF EXISTS loyalty_points,
DROP COLUMN IF EXISTS total_purchases,
DROP COLUMN IF EXISTS purchase_count,
DROP COLUMN IF EXISTS last_purchase_at;

-- Add unique constraint on email for global customer lookup
ALTER TABLE customers
DROP CONSTRAINT IF EXISTS customers_email_unique;

ALTER TABLE customers
ADD CONSTRAINT customers_email_unique UNIQUE (email);

-- Add indexes on phone for fast lookup
CREATE INDEX IF NOT EXISTS idx_customers_phone ON customers(phone);
CREATE INDEX IF NOT EXISTS idx_customers_email ON customers(email);

-- ============================================================
-- Step 3: Create indexes for customer_tenants
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_customer_tenants_customer_id ON customer_tenants(customer_id);
CREATE INDEX IF NOT EXISTS idx_customer_tenants_tenant_id ON customer_tenants(tenant_id);
CREATE INDEX IF NOT EXISTS idx_customer_tenants_loyalty_points ON customer_tenants(tenant_id, loyalty_points DESC);
CREATE INDEX IF NOT EXISTS idx_customer_tenants_total_purchases ON customer_tenants(tenant_id, total_purchases DESC);

-- ============================================================
-- Step 4: Enable Row Level Security on customer_tenants
-- ============================================================

ALTER TABLE customer_tenants ENABLE ROW LEVEL SECURITY;

-- Tenant isolation policy
CREATE POLICY "Customer-tenant tenant isolation" ON customer_tenants
    USING (tenant_id = current_tenant_id());

-- Allow tenants to view their customer relationships
CREATE POLICY "Tenants can view their customers" ON customer_tenants
    FOR SELECT
    USING (tenant_id = current_tenant_id());

-- Allow tenants to create customer relationships
CREATE POLICY "Tenants can create customer relationships" ON customer_tenants
    FOR INSERT
    WITH CHECK (tenant_id = current_tenant_id());

-- Allow tenants to update their customer data
CREATE POLICY "Tenants can update customer data" ON customer_tenants
    FOR UPDATE
    USING (tenant_id = current_tenant_id())
    WITH CHECK (tenant_id = current_tenant_id());

-- ============================================================
-- Step 5: Create trigger to update updated_at
-- ============================================================

CREATE OR REPLACE FUNCTION update_customer_tenants_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_customer_tenants_updated_at ON customer_tenants;

CREATE TRIGGER trigger_customer_tenants_updated_at
    BEFORE UPDATE ON customer_tenants
    FOR EACH ROW
    EXECUTE FUNCTION update_customer_tenants_updated_at();

-- ============================================================
-- Step 6: Update customers RLS policies (global access)
-- ============================================================

-- Customers table is now global, so any authenticated user can access
CREATE POLICY "Anyone authenticated can view customers" ON customers
    FOR SELECT
    USING (auth.role() = 'authenticated');

CREATE POLICY "Anyone authenticated can create customers" ON customers
    FOR INSERT
    WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Anyone authenticated can update customers" ON customers
    FOR UPDATE
    USING (auth.role() = 'authenticated');

-- ============================================================
-- Step 7: Recreate customer_addresses policies (no tenant dependency)
-- ============================================================

-- Customer addresses are scoped by customer_id, not tenant_id
CREATE POLICY "Users can view customer addresses" ON customer_addresses
    FOR SELECT
    USING (auth.role() = 'authenticated');

CREATE POLICY "Users can create customer addresses" ON customer_addresses
    FOR INSERT
    WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Users can update customer addresses" ON customer_addresses
    FOR UPDATE
    USING (auth.role() = 'authenticated');

CREATE POLICY "Users can delete customer addresses" ON customer_addresses
    FOR DELETE
    USING (auth.role() = 'authenticated');

-- ============================================================
-- Comments for documentation
-- ============================================================

COMMENT ON TABLE customer_tenants IS 'Junction table linking customers to tenants with tenant-specific analytics and loyalty data';
COMMENT ON COLUMN customer_tenants.loyalty_points IS 'Loyalty points earned by customer for this specific tenant';
COMMENT ON COLUMN customer_tenants.total_purchases IS 'Total purchase amount by customer at this tenant';
COMMENT ON COLUMN customer_tenants.purchase_count IS 'Number of orders placed by customer at this tenant';
COMMENT ON COLUMN customer_tenants.preferred_branch_id IS 'Customer''s preferred branch for pickup/delivery within this tenant';

COMMENT ON TABLE customers IS 'Global customer table - customers can order from multiple tenants';
COMMENT ON CONSTRAINT customers_email_unique ON customers IS 'Ensures email uniqueness across all customers for smart login detection';


-- File: 20260228_create_delivery_types.sql
-- ============================================================
-- Migration: Delivery Types Table
-- ============================================================
-- Purpose: Tenant-defined delivery options and pricing
-- Context: Each tenant creates their own delivery types
--          (Van, Motorbike, Bicycle, Trek, etc.) with custom fees
-- Date: 2026-02-28

-- ============================================================
-- Step 1: Create delivery_types table
-- ============================================================

CREATE TABLE IF NOT EXISTS delivery_types (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,

    -- Delivery type details
    name VARCHAR(50) NOT NULL,
    -- Examples: "Van", "Motorbike", "Bicycle", "Trek", "Express Delivery"

    description TEXT,
    -- Optional description for customers

    -- Pricing structure (flexible)
    base_fee DECIMAL(12,2) NOT NULL DEFAULT 0 CHECK (base_fee >= 0),
    -- Flat rate fee (e.g., NGN 500 base)

    per_km_fee DECIMAL(12,2) NOT NULL DEFAULT 0 CHECK (per_km_fee >= 0),
    -- Additional fee per kilometer (e.g., NGN 50/km)

    free_distance_km DECIMAL(8,2) NOT NULL DEFAULT 0 CHECK (free_distance_km >= 0),
    -- Distance within which delivery is free
    -- Example: 2km free, then charges apply

    min_order_value DECIMAL(12,2) NOT NULL DEFAULT 0 CHECK (min_order_value >= 0),
    -- Minimum order value required to use this delivery type
    -- Example: "Free Delivery (min NGN 5,000 order)"

    -- Service constraints
    max_distance_km DECIMAL(8,2) CHECK (max_distance_km IS NULL OR max_distance_km > 0),
    -- Maximum service distance (NULL = unlimited)
    -- Example: Bicycle limited to 5km radius

    estimated_minutes INTEGER CHECK (estimated_minutes IS NULL OR estimated_minutes > 0),
    -- Estimated delivery time in minutes

    -- Status
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    -- Can be toggled on/off without deletion

    display_order INTEGER NOT NULL DEFAULT 0,
    -- Order to display options to customers (lower = first)

    -- Metadata
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Ensure unique names within tenant
    CONSTRAINT delivery_types_tenant_name_unique UNIQUE(tenant_id, name)
);

-- ============================================================
-- Step 2: Create indexes
-- ============================================================

CREATE INDEX idx_delivery_types_tenant_id ON delivery_types(tenant_id);
CREATE INDEX idx_delivery_types_active ON delivery_types(tenant_id, is_active);
CREATE INDEX idx_delivery_types_display_order ON delivery_types(tenant_id, display_order);

-- ============================================================
-- Step 3: Enable Row Level Security
-- ============================================================

ALTER TABLE delivery_types ENABLE ROW LEVEL SECURITY;

-- Tenant isolation policy
CREATE POLICY "Delivery types tenant isolation" ON delivery_types
    USING (tenant_id = current_tenant_id());

-- Allow tenants to view their delivery types
CREATE POLICY "Tenants can view delivery types" ON delivery_types
    FOR SELECT
    USING (tenant_id = current_tenant_id());

-- Allow tenants to create delivery types
CREATE POLICY "Tenants can create delivery types" ON delivery_types
    FOR INSERT
    WITH CHECK (tenant_id = current_tenant_id());

-- Allow tenants to update delivery types
CREATE POLICY "Tenants can update delivery types" ON delivery_types
    FOR UPDATE
    USING (tenant_id = current_tenant_id())
    WITH CHECK (tenant_id = current_tenant_id());

-- Allow tenants to delete delivery types
CREATE POLICY "Tenants can delete delivery types" ON delivery_types
    FOR DELETE
    USING (tenant_id = current_tenant_id());

-- ============================================================
-- Step 4: Create trigger to update updated_at
-- ============================================================

CREATE OR REPLACE FUNCTION update_delivery_types_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_delivery_types_updated_at
    BEFORE UPDATE ON delivery_types
    FOR EACH ROW
    EXECUTE FUNCTION update_delivery_types_updated_at();

-- ============================================================
-- Step 5: Create function to calculate delivery fee
-- ============================================================

CREATE OR REPLACE FUNCTION calculate_delivery_fee(
    p_delivery_type_id UUID,
    p_distance_km DECIMAL,
    p_order_value DECIMAL DEFAULT 0
)
RETURNS DECIMAL AS $$
DECLARE
    v_delivery_type RECORD;
    v_fee DECIMAL;
    v_chargeable_distance DECIMAL;
BEGIN
    -- Get delivery type details
    SELECT
        base_fee,
        per_km_fee,
        free_distance_km,
        min_order_value,
        max_distance_km
    INTO v_delivery_type
    FROM delivery_types
    WHERE id = p_delivery_type_id
    AND is_active = TRUE;

    -- If delivery type not found or inactive, return NULL
    IF v_delivery_type IS NULL THEN
        RETURN NULL;
    END IF;

    -- Check if order meets minimum value
    IF p_order_value < v_delivery_type.min_order_value THEN
        -- Order doesn't meet minimum, return NULL (not eligible)
        RETURN NULL;
    END IF;

    -- Check if distance exceeds maximum
    IF v_delivery_type.max_distance_km IS NOT NULL AND p_distance_km > v_delivery_type.max_distance_km THEN
        -- Distance too far, return NULL (not eligible)
        RETURN NULL;
    END IF;

    -- Calculate chargeable distance (distance beyond free zone)
    v_chargeable_distance := GREATEST(p_distance_km - v_delivery_type.free_distance_km, 0);

    -- Calculate total fee: base + (chargeable_distance * per_km_fee)
    v_fee := v_delivery_type.base_fee + (v_chargeable_distance * v_delivery_type.per_km_fee);

    RETURN v_fee;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- Step 6: Insert default delivery types for existing tenants
-- ============================================================

-- Create standard delivery types for existing tenants
DO $$
DECLARE
    tenant_record RECORD;
BEGIN
    FOR tenant_record IN SELECT id, currency_code FROM tenants LOOP
        -- Add "Standard Delivery" option
        INSERT INTO delivery_types (
            tenant_id,
            name,
            description,
            base_fee,
            per_km_fee,
            free_distance_km,
            min_order_value,
            max_distance_km,
            estimated_minutes,
            is_active,
            display_order
        ) VALUES (
            tenant_record.id,
            'Standard Delivery',
            'Regular delivery within city limits',
            500.00,  -- NGN 500 base fee
            50.00,   -- NGN 50 per km
            0,       -- No free distance
            0,       -- No minimum order
            20,      -- Max 20km
            60,      -- 60 minutes estimated
            TRUE,
            1
        ) ON CONFLICT (tenant_id, name) DO NOTHING;

        -- Add "Pickup" option (free, no delivery)
        INSERT INTO delivery_types (
            tenant_id,
            name,
            description,
            base_fee,
            per_km_fee,
            free_distance_km,
            min_order_value,
            max_distance_km,
            estimated_minutes,
            is_active,
            display_order
        ) VALUES (
            tenant_record.id,
            'Pickup',
            'Pick up your order at our location',
            0,       -- Free
            0,
            0,
            0,
            NULL,    -- No distance limit
            15,      -- 15 minutes to prepare
            TRUE,
            0        -- Show first (preferred option)
        ) ON CONFLICT (tenant_id, name) DO NOTHING;
    END LOOP;
END;
$$;

-- ============================================================
-- Comments for documentation
-- ============================================================

COMMENT ON TABLE delivery_types IS 'Tenant-defined delivery options with flexible pricing rules';
COMMENT ON COLUMN delivery_types.name IS 'Delivery type name (Van, Motorbike, Bicycle, Trek, etc.)';
COMMENT ON COLUMN delivery_types.base_fee IS 'Flat rate fee charged regardless of distance';
COMMENT ON COLUMN delivery_types.per_km_fee IS 'Additional fee charged per kilometer';
COMMENT ON COLUMN delivery_types.free_distance_km IS 'Distance within which no per_km_fee is charged';
COMMENT ON COLUMN delivery_types.min_order_value IS 'Minimum order value required to use this delivery type';
COMMENT ON COLUMN delivery_types.max_distance_km IS 'Maximum service distance in kilometers (NULL = unlimited)';
COMMENT ON COLUMN delivery_types.estimated_minutes IS 'Estimated delivery time in minutes';
COMMENT ON COLUMN delivery_types.display_order IS 'Order to display options (lower = shown first)';

COMMENT ON FUNCTION calculate_delivery_fee(UUID, DECIMAL, DECIMAL) IS 'Calculates delivery fee based on delivery type, distance, and order value';


-- File: 20260228_create_loyalty_config.sql
-- ============================================================
-- Migration: Loyalty Configuration Table
-- ============================================================
-- Purpose: Tenant-configurable loyalty points system
-- Context: Each tenant can activate/deactivate loyalty and define
--          their own rules for earning and redeeming points
-- Date: 2026-02-28

-- ============================================================
-- Step 1: Create loyalty_config table
-- ============================================================

CREATE TABLE IF NOT EXISTS loyalty_config (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,

    -- Feature toggle
    is_enabled BOOLEAN NOT NULL DEFAULT FALSE,

    -- Earning rules
    points_per_currency_unit DECIMAL(8,2) NOT NULL DEFAULT 1.00,
    -- Example: 1 point per NGN 100 spent
    -- So if customer spends NGN 5,000, they earn: (5000 / 100) * 1.00 = 50 points

    currency_unit DECIMAL(8,2) NOT NULL DEFAULT 100.00,
    -- The currency amount needed to earn points_per_currency_unit points
    -- Default: NGN 100

    -- Redemption rules
    min_redemption_points INTEGER NOT NULL DEFAULT 100,
    -- Minimum points needed before customer can redeem

    allow_partial_payment BOOLEAN NOT NULL DEFAULT TRUE,
    -- Can points be used for partial order payment?

    allow_full_payment BOOLEAN NOT NULL DEFAULT TRUE,
    -- Can points cover the entire order amount?

    redemption_value_per_point DECIMAL(8,2) NOT NULL DEFAULT 1.00,
    -- How much currency does 1 point equal when redeemed?
    -- Default: 1 point = NGN 1

    max_points_per_order INTEGER,
    -- Optional: Maximum points that can be redeemed in a single order
    -- NULL = no limit

    points_expiry_days INTEGER,
    -- Optional: Days until points expire (NULL = never expire)

    -- Metadata
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Ensure one config per tenant
    CONSTRAINT loyalty_config_tenant_unique UNIQUE(tenant_id),

    -- Validation constraints
    CONSTRAINT valid_points_per_unit CHECK (points_per_currency_unit > 0),
    CONSTRAINT valid_currency_unit CHECK (currency_unit > 0),
    CONSTRAINT valid_min_redemption CHECK (min_redemption_points >= 0),
    CONSTRAINT valid_redemption_value CHECK (redemption_value_per_point > 0),
    CONSTRAINT valid_max_points_per_order CHECK (max_points_per_order IS NULL OR max_points_per_order > 0),
    CONSTRAINT valid_expiry_days CHECK (points_expiry_days IS NULL OR points_expiry_days > 0)
);

-- ============================================================
-- Step 2: Create indexes
-- ============================================================

CREATE INDEX idx_loyalty_config_tenant_id ON loyalty_config(tenant_id);
CREATE INDEX idx_loyalty_config_enabled ON loyalty_config(tenant_id, is_enabled);

-- ============================================================
-- Step 3: Enable Row Level Security
-- ============================================================

ALTER TABLE loyalty_config ENABLE ROW LEVEL SECURITY;

-- Tenant isolation policy
CREATE POLICY "Loyalty config tenant isolation" ON loyalty_config
    USING (tenant_id = current_tenant_id());

-- Allow tenants to view their loyalty config
CREATE POLICY "Tenants can view loyalty config" ON loyalty_config
    FOR SELECT
    USING (tenant_id = current_tenant_id());

-- Allow tenants to create loyalty config
CREATE POLICY "Tenants can create loyalty config" ON loyalty_config
    FOR INSERT
    WITH CHECK (tenant_id = current_tenant_id());

-- Allow tenants to update loyalty config
CREATE POLICY "Tenants can update loyalty config" ON loyalty_config
    FOR UPDATE
    USING (tenant_id = current_tenant_id())
    WITH CHECK (tenant_id = current_tenant_id());

-- ============================================================
-- Step 4: Create trigger to update updated_at
-- ============================================================

CREATE OR REPLACE FUNCTION update_loyalty_config_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_loyalty_config_updated_at
    BEFORE UPDATE ON loyalty_config
    FOR EACH ROW
    EXECUTE FUNCTION update_loyalty_config_updated_at();

-- ============================================================
-- Step 5: Create helper function to calculate loyalty points
-- ============================================================

CREATE OR REPLACE FUNCTION calculate_loyalty_points(
    p_tenant_id UUID,
    p_purchase_amount DECIMAL
)
RETURNS INTEGER AS $$
DECLARE
    v_config RECORD;
    v_points INTEGER;
BEGIN
    -- Get loyalty config for tenant
    SELECT
        is_enabled,
        points_per_currency_unit,
        currency_unit
    INTO v_config
    FROM loyalty_config
    WHERE tenant_id = p_tenant_id;

    -- If no config or not enabled, return 0
    IF v_config IS NULL OR v_config.is_enabled = FALSE THEN
        RETURN 0;
    END IF;

    -- Calculate points: (amount / currency_unit) * points_per_unit
    -- Example: (5000 / 100) * 1.00 = 50 points
    v_points := FLOOR((p_purchase_amount / v_config.currency_unit) * v_config.points_per_currency_unit);

    RETURN GREATEST(v_points, 0);  -- Never return negative
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- Step 6: Create helper function to calculate redemption value
-- ============================================================

CREATE OR REPLACE FUNCTION calculate_redemption_value(
    p_tenant_id UUID,
    p_points INTEGER
)
RETURNS DECIMAL AS $$
DECLARE
    v_config RECORD;
    v_value DECIMAL;
BEGIN
    -- Get loyalty config for tenant
    SELECT
        is_enabled,
        redemption_value_per_point,
        min_redemption_points
    INTO v_config
    FROM loyalty_config
    WHERE tenant_id = p_tenant_id;

    -- If no config or not enabled, return 0
    IF v_config IS NULL OR v_config.is_enabled = FALSE THEN
        RETURN 0;
    END IF;

    -- Check minimum redemption threshold
    IF p_points < v_config.min_redemption_points THEN
        RETURN 0;
    END IF;

    -- Calculate redemption value: points * value_per_point
    -- Example: 100 points * 1.00 = NGN 100
    v_value := p_points * v_config.redemption_value_per_point;

    RETURN v_value;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- Step 7: Insert default configs for existing tenants
-- ============================================================

-- Create disabled loyalty config for all existing tenants
INSERT INTO loyalty_config (
    tenant_id,
    is_enabled,
    points_per_currency_unit,
    currency_unit,
    min_redemption_points,
    allow_partial_payment,
    allow_full_payment,
    redemption_value_per_point
)
SELECT
    id,
    FALSE,  -- Disabled by default
    1.00,   -- 1 point per currency_unit
    100.00, -- Per NGN 100
    100,    -- Minimum 100 points to redeem
    TRUE,   -- Allow partial payment
    TRUE,   -- Allow full payment
    1.00    -- 1 point = NGN 1
FROM tenants
WHERE id NOT IN (SELECT tenant_id FROM loyalty_config);

-- ============================================================
-- Comments for documentation
-- ============================================================

COMMENT ON TABLE loyalty_config IS 'Tenant-specific loyalty points configuration - each tenant controls their own loyalty program';
COMMENT ON COLUMN loyalty_config.is_enabled IS 'Whether loyalty points are active for this tenant';
COMMENT ON COLUMN loyalty_config.points_per_currency_unit IS 'Number of points earned per currency_unit spent';
COMMENT ON COLUMN loyalty_config.currency_unit IS 'Currency amount needed to earn points (e.g., 100 for NGN 100)';
COMMENT ON COLUMN loyalty_config.min_redemption_points IS 'Minimum points required before customer can redeem';
COMMENT ON COLUMN loyalty_config.allow_partial_payment IS 'Can points be used alongside other payment methods?';
COMMENT ON COLUMN loyalty_config.allow_full_payment IS 'Can points cover the entire order amount?';
COMMENT ON COLUMN loyalty_config.redemption_value_per_point IS 'Currency value of 1 point when redeemed';
COMMENT ON COLUMN loyalty_config.max_points_per_order IS 'Maximum points that can be used in a single order (NULL = unlimited)';
COMMENT ON COLUMN loyalty_config.points_expiry_days IS 'Days until earned points expire (NULL = never expire)';

COMMENT ON FUNCTION calculate_loyalty_points(UUID, DECIMAL) IS 'Calculates loyalty points earned for a purchase amount based on tenant config';
COMMENT ON FUNCTION calculate_redemption_value(UUID, INTEGER) IS 'Calculates currency value of points for redemption based on tenant config';


-- File: 20260228_create_storefront_config.sql
-- ============================================================
-- Migration: Storefront Configuration Table
-- ============================================================
-- Purpose: Marketplace storefront customization for each tenant
-- Context: Paid plans can customize their storefront appearance
--          Free plan gets basic storefront only
-- Date: 2026-02-28

-- ============================================================
-- Step 1: Create storefront_config table
-- ============================================================

CREATE TABLE IF NOT EXISTS storefront_config (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,

    -- Visual customization (paid plans only)
    banner_url TEXT,
    -- Hero banner image URL

    about_text TEXT,
    -- About/description text shown on storefront

    welcome_message TEXT,
    -- Custom welcome message for customers

    -- Business hours (stored as JSON for flexibility)
    operating_hours JSONB,
    -- Example: {
    --   "monday": {"open": "08:00", "close": "18:00", "is_open": true},
    --   "tuesday": {"open": "08:00", "close": "18:00", "is_open": true},
    --   ...
    --   "sunday": {"is_open": false}
    -- }

    -- Contact information
    contact_email VARCHAR(255),
    contact_phone VARCHAR(20),
    contact_whatsapp VARCHAR(20),
    physical_address TEXT,

    -- Social media links
    facebook_url TEXT,
    instagram_url TEXT,
    twitter_url TEXT,

    -- Order settings
    minimum_order_value DECIMAL(12,2) NOT NULL DEFAULT 0 CHECK (minimum_order_value >= 0),
    -- Minimum order value for checkout

    accept_online_orders BOOLEAN NOT NULL DEFAULT TRUE,
    -- Can customers place orders online?

    allow_guest_checkout BOOLEAN NOT NULL DEFAULT TRUE,
    -- Can customers checkout without account?

    require_phone_verification BOOLEAN NOT NULL DEFAULT FALSE,
    -- Require phone OTP verification before checkout?

    -- Display settings
    show_stock_quantity BOOLEAN NOT NULL DEFAULT FALSE,
    -- Show exact stock numbers to customers?

    show_out_of_stock BOOLEAN NOT NULL DEFAULT TRUE,
    -- Display out-of-stock products?

    products_per_page INTEGER NOT NULL DEFAULT 20 CHECK (products_per_page > 0),
    -- Pagination setting

    -- SEO settings
    meta_title VARCHAR(255),
    meta_description TEXT,
    meta_keywords TEXT,

    -- Status
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    -- Is storefront live and accessible to customers?

    -- Metadata
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Ensure one config per tenant
    CONSTRAINT storefront_config_tenant_unique UNIQUE(tenant_id)
);

-- ============================================================
-- Step 2: Create indexes
-- ============================================================

CREATE INDEX idx_storefront_config_tenant_id ON storefront_config(tenant_id);
CREATE INDEX idx_storefront_config_active ON storefront_config(tenant_id, is_active);

-- ============================================================
-- Step 3: Enable Row Level Security
-- ============================================================

ALTER TABLE storefront_config ENABLE ROW LEVEL SECURITY;

-- Tenant isolation policy
CREATE POLICY "Storefront config tenant isolation" ON storefront_config
    USING (tenant_id = current_tenant_id());

-- Allow tenants to view their storefront config
CREATE POLICY "Tenants can view storefront config" ON storefront_config
    FOR SELECT
    USING (tenant_id = current_tenant_id());

-- Allow tenants to create storefront config
CREATE POLICY "Tenants can create storefront config" ON storefront_config
    FOR INSERT
    WITH CHECK (tenant_id = current_tenant_id());

-- Allow tenants to update storefront config
CREATE POLICY "Tenants can update storefront config" ON storefront_config
    FOR UPDATE
    USING (tenant_id = current_tenant_id())
    WITH CHECK (tenant_id = current_tenant_id());

-- Allow public read access to active storefronts (for customer browsing)
CREATE POLICY "Public can view active storefronts" ON storefront_config
    FOR SELECT
    USING (is_active = TRUE);

-- ============================================================
-- Step 4: Create trigger to update updated_at
-- ============================================================

CREATE OR REPLACE FUNCTION update_storefront_config_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_storefront_config_updated_at
    BEFORE UPDATE ON storefront_config
    FOR EACH ROW
    EXECUTE FUNCTION update_storefront_config_updated_at();

-- ============================================================
-- Step 5: Create helper function to check if storefront is open
-- ============================================================

CREATE OR REPLACE FUNCTION is_storefront_open(
    p_tenant_id UUID,
    p_check_time TIMESTAMPTZ DEFAULT NOW()
)
RETURNS BOOLEAN AS $$
DECLARE
    v_config RECORD;
    v_day_of_week TEXT;
    v_current_time TIME;
    v_hours JSONB;
    v_is_open BOOLEAN;
    v_open_time TIME;
    v_close_time TIME;
BEGIN
    -- Get storefront config
    SELECT
        is_active,
        operating_hours
    INTO v_config
    FROM storefront_config
    WHERE tenant_id = p_tenant_id;

    -- If no config or inactive, return FALSE
    IF v_config IS NULL OR v_config.is_active = FALSE THEN
        RETURN FALSE;
    END IF;

    -- If no operating hours defined, assume always open
    IF v_config.operating_hours IS NULL THEN
        RETURN TRUE;
    END IF;

    -- Get day of week (lowercase)
    v_day_of_week := LOWER(TO_CHAR(p_check_time, 'Day'));
    v_day_of_week := TRIM(v_day_of_week);

    -- Get current time
    v_current_time := p_check_time::TIME;

    -- Get hours for this day
    v_hours := v_config.operating_hours -> v_day_of_week;

    -- If no hours defined for this day, assume closed
    IF v_hours IS NULL THEN
        RETURN FALSE;
    END IF;

    -- Check if marked as open
    v_is_open := (v_hours ->> 'is_open')::BOOLEAN;

    IF v_is_open = FALSE THEN
        RETURN FALSE;
    END IF;

    -- Get open/close times
    v_open_time := (v_hours ->> 'open')::TIME;
    v_close_time := (v_hours ->> 'close')::TIME;

    -- Check if current time is within operating hours
    RETURN v_current_time BETWEEN v_open_time AND v_close_time;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- Step 6: Insert default storefront configs for existing tenants
-- ============================================================

-- Create basic storefront config for all existing tenants
INSERT INTO storefront_config (
    tenant_id,
    about_text,
    welcome_message,
    operating_hours,
    minimum_order_value,
    accept_online_orders,
    allow_guest_checkout,
    require_phone_verification,
    show_stock_quantity,
    show_out_of_stock,
    products_per_page,
    is_active
)
SELECT
    t.id,
    'Welcome to our store! We offer quality products at great prices.',
    'Shop with us today!',
    jsonb_build_object(
        'monday', jsonb_build_object('open', '08:00', 'close', '18:00', 'is_open', true),
        'tuesday', jsonb_build_object('open', '08:00', 'close', '18:00', 'is_open', true),
        'wednesday', jsonb_build_object('open', '08:00', 'close', '18:00', 'is_open', true),
        'thursday', jsonb_build_object('open', '08:00', 'close', '18:00', 'is_open', true),
        'friday', jsonb_build_object('open', '08:00', 'close', '18:00', 'is_open', true),
        'saturday', jsonb_build_object('open', '09:00', 'close', '17:00', 'is_open', true),
        'sunday', jsonb_build_object('is_open', false)
    ),
    0,       -- No minimum order value
    TRUE,    -- Accept online orders
    TRUE,    -- Allow guest checkout
    FALSE,   -- Don't require phone verification
    FALSE,   -- Don't show exact stock quantities
    TRUE,    -- Show out-of-stock products
    20,      -- 20 products per page
    FALSE    -- Inactive by default (tenant must activate)
FROM tenants t
WHERE t.id NOT IN (SELECT tenant_id FROM storefront_config);

-- ============================================================
-- Comments for documentation
-- ============================================================

COMMENT ON TABLE storefront_config IS 'Tenant storefront customization and settings for online marketplace';
COMMENT ON COLUMN storefront_config.banner_url IS 'Hero banner image URL (paid plans only)';
COMMENT ON COLUMN storefront_config.about_text IS 'About/description text shown on storefront (paid plans only)';
COMMENT ON COLUMN storefront_config.operating_hours IS 'Business hours by day of week in JSON format';
COMMENT ON COLUMN storefront_config.minimum_order_value IS 'Minimum order value required for checkout';
COMMENT ON COLUMN storefront_config.accept_online_orders IS 'Whether storefront accepts online orders';
COMMENT ON COLUMN storefront_config.allow_guest_checkout IS 'Whether customers can checkout without creating account';
COMMENT ON COLUMN storefront_config.require_phone_verification IS 'Whether phone OTP verification is required before checkout';
COMMENT ON COLUMN storefront_config.show_stock_quantity IS 'Whether to display exact stock numbers to customers';
COMMENT ON COLUMN storefront_config.show_out_of_stock IS 'Whether to display out-of-stock products';
COMMENT ON COLUMN storefront_config.is_active IS 'Whether storefront is live and accessible to customers';

COMMENT ON FUNCTION is_storefront_open(UUID, TIMESTAMPTZ) IS 'Checks if a tenant storefront is currently open based on operating hours';


-- File: 20260228_fix_user_registration_rls.sql
-- Fix RLS policy to allow new user registration
-- Issue: New users cannot insert into users table during signup
-- Solution: Allow authenticated users to create their own user record

-- Drop existing policy if it exists
DROP POLICY IF EXISTS "Users can create own account" ON users;

-- Allow authenticated users to INSERT their own user record
CREATE POLICY "Users can create own account"
    ON users FOR INSERT
    WITH CHECK (
        auth.uid() = id  -- User is creating their own record
    );

-- This policy allows:
-- 1. New users to create their own account during signup (auth.uid() = id)
-- 2. Existing "Managers can create users" policy still applies for inviting staff

-- Note: The existing "Managers can create users" policy is kept for staff invitations


-- File: 20260228_generate_sample_data.sql
-- Sample Data Generator for Testing POS Analytics
-- This script generates realistic sample data for testing the POS system
-- IMPORTANT: Only run this on development/test databases, NOT in production!

-- ============================================================================
-- Get current user's tenant and branch IDs
-- ============================================================================
DO $$
DECLARE
  sample_tenant_id uuid;
  sample_branch_id uuid;
  sample_user_id uuid;
  sample_customer_ids uuid[];
  sample_product_ids uuid[];
  current_date date := CURRENT_DATE;
  sale_date timestamptz;
  sale_count int := 0;
  i int;
  j int;
BEGIN
  -- Get a tenant ID (use the first tenant or create a sample one)
  SELECT id INTO sample_tenant_id FROM tenants LIMIT 1;

  IF sample_tenant_id IS NULL THEN
    RAISE EXCEPTION 'No tenant found. Please create a tenant first.';
  END IF;

  -- Get a branch ID for this tenant
  SELECT id INTO sample_branch_id FROM branches WHERE tenant_id = sample_tenant_id LIMIT 1;

  IF sample_branch_id IS NULL THEN
    RAISE EXCEPTION 'No branch found for tenant. Please create a branch first.';
  END IF;

  -- Get a user ID for this tenant
  SELECT id INTO sample_user_id FROM users WHERE tenant_id = sample_tenant_id LIMIT 1;

  IF sample_user_id IS NULL THEN
    RAISE EXCEPTION 'No user found for tenant. Please create a user first.';
  END IF;

  RAISE NOTICE 'Using tenant_id: %, branch_id: %, user_id: %', sample_tenant_id, sample_branch_id, sample_user_id;

  -- ============================================================================
  -- Create Sample Products
  -- ============================================================================
  RAISE NOTICE 'Creating sample products...';

  INSERT INTO products (tenant_id, name, description, sku, category, unit_price, cost_price, is_active)
  VALUES
    (sample_tenant_id, 'Paracetamol 500mg', 'Pain relief tablets', 'MED-001', 'Medicine', 500.00, 300.00, true),
    (sample_tenant_id, 'Ibuprofen 400mg', 'Anti-inflammatory tablets', 'MED-002', 'Medicine', 800.00, 500.00, true),
    (sample_tenant_id, 'Vitamin C 1000mg', 'Immune support supplement', 'SUPP-001', 'Supplements', 1200.00, 700.00, true),
    (sample_tenant_id, 'Multivitamin', 'Daily multivitamin supplement', 'SUPP-002', 'Supplements', 1500.00, 900.00, true),
    (sample_tenant_id, 'Hand Sanitizer 500ml', 'Antibacterial hand sanitizer', 'HYG-001', 'Hygiene', 1000.00, 600.00, true),
    (sample_tenant_id, 'Face Mask (Pack of 50)', 'Disposable face masks', 'HYG-002', 'Hygiene', 2500.00, 1500.00, true),
    (sample_tenant_id, 'Bandages', 'Adhesive bandages pack', 'MED-003', 'Medicine', 600.00, 350.00, true),
    (sample_tenant_id, 'Cough Syrup', 'Cough relief syrup', 'MED-004', 'Medicine', 1800.00, 1100.00, true),
    (sample_tenant_id, 'Antiseptic Cream', 'Wound care cream', 'MED-005', 'Medicine', 900.00, 550.00, true),
    (sample_tenant_id, 'Thermometer Digital', 'Digital body thermometer', 'EQP-001', 'Equipment', 3500.00, 2000.00, true),
    (sample_tenant_id, 'Blood Pressure Monitor', 'Digital BP monitor', 'EQP-002', 'Equipment', 8500.00, 5000.00, true),
    (sample_tenant_id, 'First Aid Kit', 'Complete first aid kit', 'KIT-001', 'Kits', 5000.00, 3000.00, true),
    (sample_tenant_id, 'Eye Drops', 'Lubricating eye drops', 'MED-006', 'Medicine', 1200.00, 700.00, true),
    (sample_tenant_id, 'Antacid Tablets', 'Heartburn relief', 'MED-007', 'Medicine', 700.00, 400.00, true),
    (sample_tenant_id, 'Allergy Relief', 'Antihistamine tablets', 'MED-008', 'Medicine', 1500.00, 900.00, true)
  ON CONFLICT DO NOTHING;

  -- Get product IDs
  SELECT ARRAY_AGG(id) INTO sample_product_ids
  FROM products
  WHERE tenant_id = sample_tenant_id;

  RAISE NOTICE 'Created % products', array_length(sample_product_ids, 1);

  -- ============================================================================
  -- Create Branch Inventory
  -- ============================================================================
  RAISE NOTICE 'Creating branch inventory...';

  FOR i IN 1..array_length(sample_product_ids, 1) LOOP
    INSERT INTO branch_inventory (
      tenant_id,
      branch_id,
      product_id,
      stock_quantity,
      low_stock_threshold,
      is_active
    )
    VALUES (
      sample_tenant_id,
      sample_branch_id,
      sample_product_ids[i],
      FLOOR(RANDOM() * 500 + 100)::int, -- Random stock between 100-600
      20, -- Low stock threshold
      true
    )
    ON CONFLICT (branch_id, product_id) DO UPDATE
    SET stock_quantity = branch_inventory.stock_quantity + FLOOR(RANDOM() * 500 + 100)::int;
  END LOOP;

  -- ============================================================================
  -- Create Sample Customers
  -- ============================================================================
  RAISE NOTICE 'Creating sample customers...';

  INSERT INTO customers (tenant_id, phone, full_name, email, loyalty_points, total_purchases, purchase_count, loyalty_tier)
  VALUES
    (sample_tenant_id, '08012345678', 'John Doe', 'john.doe@example.com', 150, 15000.00, 12, 'silver'),
    (sample_tenant_id, '08098765432', 'Jane Smith', 'jane.smith@example.com', 250, 25000.00, 20, 'gold'),
    (sample_tenant_id, '07012345678', 'Ahmed Ibrahim', null, 80, 8000.00, 6, 'bronze'),
    (sample_tenant_id, '09087654321', 'Blessing Okafor', 'blessing@example.com', 120, 12000.00, 10, 'silver'),
    (sample_tenant_id, '08123456789', 'Chidi Nwankwo', null, 50, 5000.00, 4, 'bronze'),
    (sample_tenant_id, '07098765432', 'Fatima Hassan', 'fatima@example.com', 300, 30000.00, 25, 'gold'),
    (sample_tenant_id, '09012345678', 'Emeka Okonkwo', null, 40, 4000.00, 3, 'bronze'),
    (sample_tenant_id, '08087654321', 'Aisha Mohammed', 'aisha@example.com', 180, 18000.00, 15, 'silver')
  ON CONFLICT DO NOTHING;

  -- Get customer IDs
  SELECT ARRAY_AGG(id) INTO sample_customer_ids
  FROM customers
  WHERE tenant_id = sample_tenant_id;

  RAISE NOTICE 'Created % customers', array_length(sample_customer_ids, 1);

  -- ============================================================================
  -- Create Sample Sales (Last 6 Months)
  -- ============================================================================
  RAISE NOTICE 'Creating sample sales transactions...';

  -- Generate sales for the last 180 days
  FOR i IN 0..179 LOOP
    sale_date := (CURRENT_DATE - (i || ' days')::interval)::date +
                 (FLOOR(RANDOM() * 14 + 8)::int || ' hours')::interval + -- Random hour 8am-10pm
                 (FLOOR(RANDOM() * 60)::int || ' minutes')::interval;

    -- Create 1-5 sales per day
    FOR j IN 1..FLOOR(RANDOM() * 4 + 1)::int LOOP
      DECLARE
        new_sale_id uuid;
        sale_number_val text;
        customer_id_val uuid;
        num_items int;
        subtotal_val numeric := 0;
        tax_val numeric;
        discount_val numeric;
        total_val numeric;
        k int;
        product_idx int;
        quantity_val int;
        unit_price_val numeric;
        item_subtotal numeric;
      BEGIN
        new_sale_id := gen_random_uuid();
        sale_number_val := 'SALE-' || to_char(sale_date, 'YYYYMMDD') || '-' || LPAD((sale_count + 1)::text, 4, '0');

        -- 70% chance to have a customer
        IF RANDOM() < 0.7 THEN
          customer_id_val := sample_customer_ids[FLOOR(RANDOM() * array_length(sample_customer_ids, 1) + 1)::int];
        ELSE
          customer_id_val := NULL;
        END IF;

        -- Random number of items (1-5)
        num_items := FLOOR(RANDOM() * 4 + 1)::int;

        -- Insert sale record
        INSERT INTO sales (
          id,
          tenant_id,
          branch_id,
          sale_number,
          cashier_id,
          customer_id,
          subtotal,
          tax_amount,
          discount_amount,
          total_amount,
          payment_method,
          status,
          created_at,
          updated_at
        )
        VALUES (
          new_sale_id,
          sample_tenant_id,
          sample_branch_id,
          sale_number_val,
          sample_user_id,
          customer_id_val,
          0, -- Will update after items
          0,
          0,
          0,
          CASE FLOOR(RANDOM() * 4)::int
            WHEN 0 THEN 'cash'
            WHEN 1 THEN 'card'
            WHEN 2 THEN 'transfer'
            ELSE 'mobile'
          END,
          'completed',
          sale_date,
          sale_date
        );

        -- Add sale items
        FOR k IN 1..num_items LOOP
          product_idx := FLOOR(RANDOM() * array_length(sample_product_ids, 1) + 1)::int;
          quantity_val := FLOOR(RANDOM() * 3 + 1)::int; -- 1-4 items

          -- Get product price
          SELECT unit_price INTO unit_price_val
          FROM products
          WHERE id = sample_product_ids[product_idx];

          item_subtotal := quantity_val * unit_price_val;
          subtotal_val := subtotal_val + item_subtotal;

          -- Insert sale item
          INSERT INTO sale_items (
            sale_id,
            product_id,
            product_name,
            quantity,
            unit_price,
            discount_percent,
            discount_amount,
            subtotal
          )
          SELECT
            new_sale_id,
            p.id,
            p.name,
            quantity_val,
            p.unit_price,
            0,
            0,
            item_subtotal
          FROM products p
          WHERE p.id = sample_product_ids[product_idx];
        END LOOP;

        -- Calculate tax and discount
        discount_val := CASE WHEN RANDOM() < 0.2 THEN FLOOR(RANDOM() * 500 + 100)::numeric ELSE 0 END;
        tax_val := subtotal_val * 0.075;
        total_val := subtotal_val + tax_val - discount_val;

        -- Update sale totals
        UPDATE sales
        SET
          subtotal = subtotal_val,
          tax_amount = tax_val,
          discount_amount = discount_val,
          total_amount = total_val
        WHERE id = new_sale_id;

        sale_count := sale_count + 1;
      END;
    END LOOP;
  END LOOP;

  RAISE NOTICE 'Created % sales transactions', sale_count;
  RAISE NOTICE 'Sample data generation completed successfully!';

EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'Error: %', SQLERRM;
    RAISE;
END $$;


-- File: 20260301_fix_user_registration_rls_v2.sql
-- Fix RLS policy to allow new user registration (v2 - Comprehensive Fix)
-- Issue: New users cannot insert into users table during signup
-- Solution: Drop conflicting policies and create correct INSERT policy

-- Step 1: Check and drop ALL existing INSERT policies on users table
DROP POLICY IF EXISTS "Users can create own account" ON users;
DROP POLICY IF EXISTS "Managers can create users" ON users;
DROP POLICY IF EXISTS "Admins can create users" ON users;
DROP POLICY IF EXISTS "Allow user registration and staff creation" ON users;
DROP POLICY IF EXISTS "users_insert_own" ON users;
DROP POLICY IF EXISTS "managers_insert_staff" ON users;

-- Step 2: Create simple policy for self-registration
-- Allows users to create their own account during signup
CREATE POLICY "users_insert_own"
    ON users FOR INSERT
    WITH CHECK (auth.uid() = id);

-- Step 3: Create separate policy for managers to invite staff
-- Uses valid user_role enum values: platform_admin, tenant_admin, branch_manager
CREATE POLICY "managers_insert_staff"
    ON users FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM users AS u
            WHERE u.id = auth.uid()
            AND u.tenant_id IS NOT NULL
            AND u.role IN ('platform_admin', 'tenant_admin', 'branch_manager')
        )
        AND tenant_id IS NOT NULL
    );

-- Step 4: Verify the policies were created
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_policies
        WHERE tablename = 'users'
        AND policyname = 'users_insert_own'
        AND cmd = 'INSERT'
    ) AND EXISTS (
        SELECT 1 FROM pg_policies
        WHERE tablename = 'users'
        AND policyname = 'managers_insert_staff'
        AND cmd = 'INSERT'
    ) THEN
        RAISE NOTICE 'âœ… Both policies created successfully';
    ELSE
        RAISE EXCEPTION 'âŒ Failed to create one or more policies';
    END IF;
END $$;

-- Comments
COMMENT ON POLICY "users_insert_own" ON users IS
'Allows self-registration during signup (auth.uid() = id)';

COMMENT ON POLICY "managers_insert_staff" ON users IS
'Allows platform_admin, tenant_admin, and branch_manager to create users for staff invites';


-- File: 20260310_real_time_inventory_sync.sql
-- ============================================================
-- Migration: Real-Time Inventory Sync for Marketplace
-- ============================================================
-- Purpose: Automatically sync inventory between POS sales and marketplace
-- Context: When orders are placed through marketplace or POS,
--          inventory should automatically update in real-time
-- Date: 2026-03-10
-- Tasks: T110 - Real-time inventory sync

-- ============================================================
-- Step 1: Create function to sync product stock from branch_inventory
-- ============================================================

-- This function updates products.stock_quantity based on branch_inventory
-- Useful for displaying aggregate stock across all branches
CREATE OR REPLACE FUNCTION sync_product_total_stock(p_product_id UUID)
RETURNS VOID AS $$
DECLARE
    v_total_stock INTEGER;
BEGIN
    -- Calculate total available stock across all branches
    SELECT COALESCE(SUM(stock_quantity - reserved_quantity), 0)
    INTO v_total_stock
    FROM branch_inventory
    WHERE product_id = p_product_id;

    -- Update the product's stock_quantity
    UPDATE products
    SET
        stock_quantity = v_total_stock,
        updated_at = NOW()
    WHERE id = p_product_id;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION sync_product_total_stock(UUID) IS 'Syncs product total stock from all branch inventories';

-- ============================================================
-- Step 2: Create trigger to auto-sync when branch inventory changes
-- ============================================================

CREATE OR REPLACE FUNCTION trigger_sync_product_stock()
RETURNS TRIGGER AS $$
BEGIN
    -- Sync the product stock when branch inventory changes
    PERFORM sync_product_total_stock(COALESCE(NEW.product_id, OLD.product_id));
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop existing trigger if it exists
DROP TRIGGER IF EXISTS auto_sync_product_stock ON branch_inventory;

-- Create trigger for INSERT, UPDATE, DELETE on branch_inventory
CREATE TRIGGER auto_sync_product_stock
    AFTER INSERT OR UPDATE OR DELETE ON branch_inventory
    FOR EACH ROW
    EXECUTE FUNCTION trigger_sync_product_stock();

COMMENT ON TRIGGER auto_sync_product_stock ON branch_inventory IS 'Automatically syncs product.stock_quantity when branch_inventory changes';

-- ============================================================
-- Step 3: Create function to handle order item inventory deduction
-- ============================================================

CREATE OR REPLACE FUNCTION deduct_inventory_on_order_confirm(
    p_order_id UUID
)
RETURNS BOOLEAN AS $$
DECLARE
    v_branch_id UUID;
    v_item RECORD;
    v_success BOOLEAN;
BEGIN
    -- Get the branch_id from the order
    SELECT branch_id INTO v_branch_id
    FROM orders
    WHERE id = p_order_id;

    IF v_branch_id IS NULL THEN
        RAISE EXCEPTION 'Order not found or branch_id is null: %', p_order_id;
    END IF;

    -- Loop through all order items and confirm reservations
    FOR v_item IN
        SELECT product_id, quantity
        FROM order_items
        WHERE order_id = p_order_id
    LOOP
        -- Confirm the reservation (deducts from stock and reserved)
        v_success := confirm_reservation(v_branch_id, v_item.product_id, v_item.quantity);

        IF NOT v_success THEN
            RAISE EXCEPTION 'Failed to confirm reservation for product % in order %',
                v_item.product_id, p_order_id;
        END IF;
    END LOOP;

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION deduct_inventory_on_order_confirm(UUID) IS 'Deducts inventory from branch stock when order is confirmed/paid';

-- ============================================================
-- Step 4: Create function to restore inventory on order cancellation
-- ============================================================

CREATE OR REPLACE FUNCTION restore_inventory_on_order_cancel(
    p_order_id UUID
)
RETURNS BOOLEAN AS $$
DECLARE
    v_branch_id UUID;
    v_order_status TEXT;
    v_item RECORD;
    v_success BOOLEAN;
BEGIN
    -- Get the order details
    SELECT branch_id, order_status INTO v_branch_id, v_order_status
    FROM orders
    WHERE id = p_order_id;

    IF v_branch_id IS NULL THEN
        RAISE EXCEPTION 'Order not found: %', p_order_id;
    END IF;

    -- Loop through all order items
    FOR v_item IN
        SELECT product_id, quantity
        FROM order_items
        WHERE order_id = p_order_id
    LOOP
        -- If order was only reserved (not confirmed), release reservation
        -- If order was confirmed (paid), add stock back
        IF v_order_status IN ('pending', 'confirmed') THEN
            -- Release reserved inventory
            v_success := release_reserved_inventory(v_branch_id, v_item.product_id, v_item.quantity);
        ELSE
            -- Order was delivered/processing, need to restore actual stock
            UPDATE branch_inventory
            SET
                stock_quantity = stock_quantity + v_item.quantity,
                updated_at = NOW()
            WHERE
                branch_id = v_branch_id
                AND product_id = v_item.product_id;

            GET DIAGNOSTICS v_success = ROW_COUNT;
            v_success := v_success > 0;
        END IF;

        IF NOT v_success THEN
            RAISE WARNING 'Failed to restore inventory for product % in order %',
                v_item.product_id, p_order_id;
        END IF;
    END LOOP;

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION restore_inventory_on_order_cancel(UUID) IS 'Restores inventory when order is cancelled';

-- ============================================================
-- Step 5: Create trigger for automatic inventory sync on order status change
-- ============================================================

CREATE OR REPLACE FUNCTION trigger_order_inventory_sync()
RETURNS TRIGGER AS $$
BEGIN
    -- When order status changes to confirmed/processing, confirm inventory reservation
    IF OLD.order_status IN ('pending') AND NEW.order_status IN ('confirmed', 'processing') THEN
        PERFORM deduct_inventory_on_order_confirm(NEW.id);
    END IF;

    -- When order is cancelled, restore inventory
    IF NEW.order_status = 'cancelled' AND OLD.order_status != 'cancelled' THEN
        PERFORM restore_inventory_on_order_cancel(NEW.id);
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop existing trigger if it exists
DROP TRIGGER IF EXISTS auto_order_inventory_sync ON orders;

-- Create trigger for order status changes
CREATE TRIGGER auto_order_inventory_sync
    AFTER UPDATE OF order_status ON orders
    FOR EACH ROW
    WHEN (OLD.order_status IS DISTINCT FROM NEW.order_status)
    EXECUTE FUNCTION trigger_order_inventory_sync();

COMMENT ON TRIGGER auto_order_inventory_sync ON orders IS 'Automatically syncs inventory when order status changes';

-- ============================================================
-- Step 6: Create function to reserve inventory when order is created
-- ============================================================

CREATE OR REPLACE FUNCTION reserve_inventory_on_order_create()
RETURNS TRIGGER AS $$
DECLARE
    v_item RECORD;
    v_success BOOLEAN;
BEGIN
    -- Only process if order status is pending (initial state)
    IF NEW.order_status = 'pending' THEN
        -- Loop through all order items and reserve inventory
        FOR v_item IN
            SELECT product_id, quantity
            FROM order_items
            WHERE order_id = NEW.id
        LOOP
            -- Reserve the inventory at the branch
            v_success := reserve_inventory(NEW.branch_id, v_item.product_id, v_item.quantity);

            IF NOT v_success THEN
                RAISE EXCEPTION 'Failed to reserve inventory for product % in order %. Not enough stock available.',
                    v_item.product_id, NEW.id;
            END IF;
        END LOOP;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop existing trigger if it exists
DROP TRIGGER IF EXISTS auto_reserve_inventory_on_order ON orders;

-- Create trigger for order creation
CREATE TRIGGER auto_reserve_inventory_on_order
    AFTER INSERT ON orders
    FOR EACH ROW
    EXECUTE FUNCTION reserve_inventory_on_order_create();

COMMENT ON TRIGGER auto_reserve_inventory_on_order ON orders IS 'Automatically reserves inventory when order is created';

-- ============================================================
-- Step 7: Create function to sync inventory on POS sale
-- ============================================================

CREATE OR REPLACE FUNCTION trigger_sync_inventory_on_sale()
RETURNS TRIGGER AS $$
DECLARE
    v_item RECORD;
BEGIN
    -- When a sale is completed, deduct inventory
    IF NEW.sale_status = 'completed' THEN
        -- Loop through sale items and deduct from branch inventory
        FOR v_item IN
            SELECT product_id, quantity
            FROM sale_items
            WHERE sale_id = NEW.id
        LOOP
            -- Deduct directly from branch inventory (POS sales are immediate)
            UPDATE branch_inventory
            SET
                stock_quantity = stock_quantity - v_item.quantity,
                updated_at = NOW()
            WHERE
                branch_id = NEW.branch_id
                AND product_id = v_item.product_id
                AND stock_quantity >= v_item.quantity;

            -- Check if update succeeded
            IF NOT FOUND THEN
                RAISE WARNING 'Failed to deduct inventory for product % in sale %. Insufficient stock.',
                    v_item.product_id, NEW.id;
            END IF;
        END LOOP;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop existing trigger if it exists
DROP TRIGGER IF EXISTS auto_sync_inventory_on_sale ON sales;

-- Create trigger for sales
CREATE TRIGGER auto_sync_inventory_on_sale
    AFTER INSERT OR UPDATE OF sale_status ON sales
    FOR EACH ROW
    WHEN (NEW.sale_status = 'completed')
    EXECUTE FUNCTION trigger_sync_inventory_on_sale();

COMMENT ON TRIGGER auto_sync_inventory_on_sale ON sales IS 'Automatically syncs inventory when POS sale is completed';

-- ============================================================
-- Step 8: Create function to get real-time marketplace stock
-- ============================================================

-- This function returns available stock for marketplace display
CREATE OR REPLACE FUNCTION get_marketplace_stock(
    p_product_id UUID,
    p_tenant_id UUID
)
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
    WHERE p.id = p_product_id
      AND p.tenant_id = p_tenant_id
      AND p.is_active = TRUE
    GROUP BY p.id;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_marketplace_stock(UUID, UUID) IS 'Returns real-time stock information for marketplace display';

-- ============================================================
-- Step 9: Create view for marketplace products with stock
-- ============================================================

-- Replace or create view for marketplace with real-time stock
CREATE OR REPLACE VIEW marketplace_products_with_stock AS
SELECT
    p.id,
    p.tenant_id,
    p.name,
    p.description,
    p.sku,
    p.barcode,
    p.category,
    p.unit_price AS price,
    p.image_url,
    COALESCE(SUM(bi.stock_quantity - bi.reserved_quantity), 0)::INTEGER AS stock_quantity,
    COALESCE(SUM(bi.stock_quantity - bi.reserved_quantity), 0) > 0 AS is_available,
    p.created_at,
    p.updated_at
FROM products p
LEFT JOIN branch_inventory bi ON p.id = bi.product_id
WHERE p.is_active = TRUE
  AND p.deleted_at IS NULL
GROUP BY p.id, p.tenant_id, p.name, p.description, p.sku, p.barcode,
         p.category, p.unit_price, p.image_url, p.created_at, p.updated_at;

COMMENT ON VIEW marketplace_products_with_stock IS 'Real-time marketplace products with aggregated available stock across branches';

-- ============================================================
-- Step 10: Create RPC function for marketplace API
-- ============================================================

-- This function can be called from the frontend for real-time stock checks
CREATE OR REPLACE FUNCTION check_product_availability(
    p_product_id UUID,
    p_quantity INTEGER,
    p_tenant_id UUID DEFAULT NULL
)
RETURNS JSON AS $$
DECLARE
    v_available INTEGER;
    v_tenant_id UUID;
    v_result JSON;
BEGIN
    -- Get tenant_id if not provided
    IF p_tenant_id IS NULL THEN
        SELECT tenant_id INTO v_tenant_id
        FROM products
        WHERE id = p_product_id;
    ELSE
        v_tenant_id := p_tenant_id;
    END IF;

    -- Get available stock
    SELECT available_stock INTO v_available
    FROM get_marketplace_stock(p_product_id, v_tenant_id);

    -- Build result
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

COMMENT ON FUNCTION check_product_availability(UUID, INTEGER, UUID) IS 'Checks if product has sufficient stock for purchase (callable from API)';

-- ============================================================
-- Step 11: Initial sync of existing data
-- ============================================================

-- Sync all existing products with their branch inventory
DO $$
DECLARE
    v_product RECORD;
BEGIN
    FOR v_product IN SELECT DISTINCT id FROM products WHERE is_active = TRUE
    LOOP
        PERFORM sync_product_total_stock(v_product.id);
    END LOOP;
END $$;

-- ============================================================
-- Step 12: Create index for performance
-- ============================================================

-- Index for faster marketplace queries
CREATE INDEX IF NOT EXISTS idx_products_marketplace
ON products(tenant_id, is_active, deleted_at)
WHERE is_active = TRUE AND deleted_at IS NULL;

-- Index for order items lookup
CREATE INDEX IF NOT EXISTS idx_order_items_order_product
ON order_items(order_id, product_id);

-- Index for sale items lookup
CREATE INDEX IF NOT EXISTS idx_sale_items_sale_product
ON sale_items(sale_id, product_id);

-- ============================================================
-- Summary and Usage Examples
-- ============================================================

/*
REAL-TIME INVENTORY SYNC IMPLEMENTATION

This migration implements automatic inventory synchronization between:
1. POS sales â†’ Branch inventory â†’ Marketplace stock
2. Marketplace orders â†’ Branch inventory â†’ Product stock
3. Order cancellations â†’ Inventory restoration

KEY FEATURES:
- Automatic inventory reservation when orders are placed
- Automatic inventory deduction when orders are confirmed/paid
- Automatic inventory restoration when orders are cancelled
- Real-time stock sync across all branches
- POS sales automatically update marketplace stock

TRIGGERS CREATED:
1. auto_sync_product_stock - Syncs product.stock_quantity from branch_inventory
2. auto_reserve_inventory_on_order - Reserves inventory when order is created
3. auto_order_inventory_sync - Syncs inventory on order status changes
4. auto_sync_inventory_on_sale - Syncs inventory when POS sale completes

USAGE EXAMPLES:

-- Check product availability for marketplace
SELECT * FROM check_product_availability(
    'product-uuid',
    5,  -- quantity
    'tenant-uuid'
);

-- Get real-time marketplace stock
SELECT * FROM get_marketplace_stock('product-uuid', 'tenant-uuid');

-- View all marketplace products with stock
SELECT * FROM marketplace_products_with_stock
WHERE tenant_id = 'tenant-uuid'
  AND is_available = TRUE
ORDER BY name;

-- Manual sync (usually not needed, triggers handle this)
SELECT sync_product_total_stock('product-uuid');

WORKFLOW:
1. Customer places order â†’ inventory reserved
2. Customer pays â†’ inventory deducted from stock
3. Order delivered â†’ status updated, inventory already deducted
4. Customer cancels â†’ inventory restored based on order status

POS SALES:
1. Sale completed â†’ inventory deducted immediately
2. Stock synced â†’ marketplace updated in real-time
*/


-- File: 20260315_configure_tenant_services.sql
-- Configure Tenant Services
-- Feature: 004-tenant-referral-commissions
-- Run this after applying 20260315_tenant_services_routing.sql

-- =============================================================================
-- STEP 1: VIEW CURRENT TENANTS
-- =============================================================================

-- First, let's see all existing tenants
-- Uncomment and run this in SQL editor to see your tenants:
-- SELECT id, name, subdomain, business_type, services_offered FROM tenants;

-- =============================================================================
-- STEP 2: CONFIGURE SERVICES FOR EACH TENANT
-- =============================================================================

-- Example: Fokz Pharmacy (pharmacy + diagnostic)
-- UPDATE tenants
-- SET services_offered = ARRAY['pharmacy', 'diagnostic']
-- WHERE subdomain = 'fokz';

-- Example: Medic Clinic (consultation only)
-- UPDATE tenants
-- SET services_offered = ARRAY['consultation']
-- WHERE subdomain = 'medic';

-- Example: CareLab (diagnostic only)
-- UPDATE tenants
-- SET services_offered = ARRAY['diagnostic']
-- WHERE subdomain = 'carelab';

-- Example: General Hospital (all services)
-- UPDATE tenants
-- SET services_offered = ARRAY['pharmacy', 'diagnostic', 'consultation']
-- WHERE subdomain = 'general-hospital';

-- =============================================================================
-- STEP 3: CONFIGURE BASED ON BUSINESS TYPE (BULK UPDATE)
-- =============================================================================

-- Option 1: Configure all pharmacies to offer pharmacy services
UPDATE tenants
SET services_offered = ARRAY['pharmacy']
WHERE business_type = 'pharmacy'
  AND services_offered = ARRAY[]::TEXT[];

-- Option 2: Configure all diagnostic centers
UPDATE tenants
SET services_offered = ARRAY['diagnostic']
WHERE business_type IN ('diagnostic_center', 'laboratory')
  AND services_offered = ARRAY[]::TEXT[];

-- Option 3: Configure all clinics/hospitals
UPDATE tenants
SET services_offered = ARRAY['consultation']
WHERE business_type IN ('clinic', 'hospital', 'medical_center')
  AND services_offered = ARRAY[]::TEXT[];

-- =============================================================================
-- STEP 4: VERIFY CONFIGURATION
-- =============================================================================

-- Check all tenants and their services
SELECT
  id,
  name,
  subdomain,
  business_type,
  services_offered,
  CASE
    WHEN 'pharmacy' = ANY(services_offered) THEN 'Yes'
    ELSE 'No'
  END as offers_pharmacy,
  CASE
    WHEN 'diagnostic' = ANY(services_offered) THEN 'Yes'
    ELSE 'No'
  END as offers_diagnostic,
  CASE
    WHEN 'consultation' = ANY(services_offered) THEN 'Yes'
    ELSE 'No'
  END as offers_consultation
FROM tenants
ORDER BY name;

-- =============================================================================
-- STEP 5: TEST SERVICE ROUTING
-- =============================================================================

-- Test 1: Check if tenant offers specific service
-- SELECT tenant_offers_service('YOUR-TENANT-UUID', 'pharmacy');

-- Test 2: Get routing decision
-- SELECT * FROM get_service_provider('YOUR-TENANT-UUID', 'diagnostic');

-- Expected Results:
-- If tenant offers service: (TRUE, tenant-uuid, tenant-name)
-- If tenant doesn't offer: (FALSE, NULL, NULL)

-- =============================================================================
-- NOTES
-- =============================================================================

-- Valid service types: 'pharmacy', 'diagnostic', 'consultation'
-- One tenant can offer multiple services
-- Empty array means tenant offers no services (always show directory)
-- Services determine auto-routing behavior in storefront

-- Business Rules:
-- 1. If referring tenant offers service â†’ auto-route to them
-- 2. If referring tenant doesn't offer service â†’ show external directory
-- 3. Same tenant as provider â†’ self-provider (no referral commission)
-- 4. Different tenant as provider â†’ referral commission applies


-- File: 20260315_tenant_services_routing.sql
-- Tenant Services and Automatic Routing
-- Feature: 004-tenant-referral-commissions
-- Created: 2026-03-15
-- Description: Adds service offerings to tenants for automatic routing

-- =============================================================================
-- PART 1: ADD SERVICES OFFERED TO TENANTS
-- =============================================================================

-- Add services_offered column to track what services each tenant provides
ALTER TABLE tenants
ADD COLUMN IF NOT EXISTS services_offered TEXT[] DEFAULT ARRAY[]::TEXT[];

-- Add constraint to ensure valid service types
ALTER TABLE tenants
ADD CONSTRAINT valid_service_types CHECK (
  services_offered <@ ARRAY['pharmacy', 'diagnostic', 'consultation']::TEXT[]
);

-- Create index for faster service lookups
CREATE INDEX IF NOT EXISTS idx_tenants_services ON tenants USING GIN (services_offered);

-- =============================================================================
-- PART 2: HELPER FUNCTION - CHECK IF TENANT OFFERS SERVICE
-- =============================================================================

CREATE OR REPLACE FUNCTION tenant_offers_service(
  p_tenant_id UUID,
  p_service_type TEXT
) RETURNS BOOLEAN AS $$
DECLARE
  services TEXT[];
BEGIN
  -- Get services offered by tenant
  SELECT services_offered INTO services
  FROM tenants
  WHERE id = p_tenant_id;

  -- Return true if service is in array
  RETURN p_service_type = ANY(services);
END;
$$ LANGUAGE plpgsql STABLE;

-- =============================================================================
-- PART 3: ROUTING LOGIC FUNCTION
-- =============================================================================

CREATE OR REPLACE FUNCTION get_service_provider(
  p_referring_tenant_id UUID,
  p_service_type TEXT
) RETURNS TABLE (
  should_auto_route BOOLEAN,
  provider_tenant_id UUID,
  provider_name TEXT
) AS $$
BEGIN
  -- Check if referring tenant offers the requested service
  IF tenant_offers_service(p_referring_tenant_id, p_service_type) THEN
    -- AUTO-ROUTE to referring tenant
    RETURN QUERY
    SELECT
      TRUE as should_auto_route,
      t.id as provider_tenant_id,
      t.name as provider_name
    FROM tenants t
    WHERE t.id = p_referring_tenant_id;
  ELSE
    -- NO AUTO-ROUTE, return null (show directory)
    RETURN QUERY
    SELECT
      FALSE as should_auto_route,
      NULL::UUID as provider_tenant_id,
      NULL::TEXT as provider_name;
  END IF;
END;
$$ LANGUAGE plpgsql STABLE;

-- =============================================================================
-- PART 4: UPDATE COMMISSION CALCULATION TO CHECK SELF-PROVIDER
-- =============================================================================

-- This function is called by Edge Function to determine commission split
CREATE OR REPLACE FUNCTION calculate_commission_with_provider_check(
  p_transaction_type TEXT,
  p_base_price DECIMAL(12,2),
  p_provider_tenant_id UUID,
  p_referring_tenant_id UUID
) RETURNS TABLE (
  customer_pays DECIMAL(12,2),
  provider_gets DECIMAL(12,2),
  referrer_gets DECIMAL(12,2),
  platform_gets DECIMAL(12,2),
  is_self_provider BOOLEAN,
  has_referrer BOOLEAN
) AS $$
DECLARE
  is_self BOOLEAN;
  has_ref BOOLEAN;
  calc RECORD;
BEGIN
  -- Check if provider is same as referrer
  is_self := (p_provider_tenant_id = p_referring_tenant_id);

  -- Determine if there's a genuine referrer
  has_ref := (p_referring_tenant_id IS NOT NULL AND NOT is_self);

  -- Calculate commission based on transaction type
  IF p_transaction_type IN ('consultation', 'diagnostic_test') THEN
    -- Service commission
    SELECT * INTO calc FROM calculate_service_commission(p_base_price, has_ref);
  ELSIF p_transaction_type = 'product_sale' THEN
    -- Product commission
    SELECT * INTO calc FROM calculate_product_commission(p_base_price, has_ref);
  ELSE
    RAISE EXCEPTION 'Invalid transaction type: %', p_transaction_type;
  END IF;

  -- Return results with provider check flags
  RETURN QUERY SELECT
    calc.customer_pays,
    calc.provider_gets,
    calc.referrer_gets,
    calc.platform_gets,
    is_self,
    has_ref;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- =============================================================================
-- PART 5: COMMENTS
-- =============================================================================

COMMENT ON COLUMN tenants.services_offered IS 'Array of services this tenant provides: pharmacy, diagnostic, consultation';
COMMENT ON FUNCTION tenant_offers_service IS 'Check if a tenant offers a specific service type';
COMMENT ON FUNCTION get_service_provider IS 'Determines if service should auto-route to referring tenant or show directory';
COMMENT ON FUNCTION calculate_commission_with_provider_check IS 'Calculates commission with self-provider check for automatic routing';

-- =============================================================================
-- PART 6: EXAMPLE DATA (for reference)
-- =============================================================================

-- Example: Fokz Pharmacy with both pharmacy and diagnostic services
-- UPDATE tenants
-- SET services_offered = ARRAY['pharmacy', 'diagnostic']
-- WHERE subdomain = 'fokz';

-- Example: Medic Clinic with only consultation services
-- UPDATE tenants
-- SET services_offered = ARRAY['consultation']
-- WHERE subdomain = 'medic';

-- Example: CareLab with only diagnostic services
-- UPDATE tenants
-- SET services_offered = ARRAY['diagnostic']
-- WHERE subdomain = 'carelab';


-- File: 20260316_add_subdomain_to_tenants.sql
-- Add subdomain column to tenants table
-- Feature: 004-tenant-referral-commissions
-- Fix: Tenant table uses 'slug' but commission system expects 'subdomain'

-- Option 1: Add subdomain column and sync with slug
ALTER TABLE tenants
ADD COLUMN IF NOT EXISTS subdomain VARCHAR(100);

-- Copy existing slug values to subdomain
UPDATE tenants
SET subdomain = slug
WHERE subdomain IS NULL;

-- Make subdomain unique
ALTER TABLE tenants
ADD CONSTRAINT tenants_subdomain_unique UNIQUE (subdomain);

-- Create trigger to keep subdomain and slug in sync
CREATE OR REPLACE FUNCTION sync_subdomain_with_slug()
RETURNS TRIGGER AS $$
BEGIN
    -- When slug changes, update subdomain
    IF NEW.slug IS DISTINCT FROM OLD.slug THEN
        NEW.subdomain := NEW.slug;
    END IF;

    -- When subdomain changes, update slug
    IF NEW.subdomain IS DISTINCT FROM OLD.subdomain THEN
        NEW.slug := NEW.subdomain;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger
DROP TRIGGER IF EXISTS sync_subdomain_trigger ON tenants;
CREATE TRIGGER sync_subdomain_trigger
    BEFORE UPDATE ON tenants
    FOR EACH ROW
    EXECUTE FUNCTION sync_subdomain_with_slug();

-- Comment
COMMENT ON COLUMN tenants.subdomain IS 'Subdomain for referral tracking (synced with slug)';


-- File: 20260317_multi_tenant_patient_identity.sql
-- ============================================================
-- Multi-Tenant Patient Identity System
-- ============================================================
-- Purpose: Enable unified patient profiles across multiple tenant accounts
-- while maintaining separate authentication per tenant
--
-- Architecture:
-- - Customers have separate accounts per tenant (different passwords allowed)
-- - Backend automatically links accounts via email/phone matching
-- - Unified patient profiles for cross-tenant medical history
-- - Privacy-first with explicit consent controls
-- ============================================================

-- ============================================================
-- Table 1: Unified Patient Profiles
-- ============================================================
-- Universal patient identity that links multiple tenant accounts

CREATE TABLE IF NOT EXISTS unified_patient_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Primary contact information (from first account or most recent)
    primary_email VARCHAR(255),
    primary_phone VARCHAR(20),
    primary_name VARCHAR(255),

    -- Metadata
    first_seen_at TIMESTAMPTZ DEFAULT NOW(),
    last_seen_at TIMESTAMPTZ DEFAULT NOW(),
    total_accounts INTEGER DEFAULT 0,

    -- Matching metadata (how confident we are this is the same person)
    match_confidence DECIMAL(3,2) DEFAULT 1.00 CHECK (match_confidence >= 0 AND match_confidence <= 1.00),
    match_method VARCHAR(50) DEFAULT 'email_phone', -- 'email_phone', 'email_name', 'phone_name', 'email_only', 'phone_only'

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for fast email/phone lookups
CREATE INDEX IF NOT EXISTS idx_unified_patients_email ON unified_patient_profiles(primary_email) WHERE primary_email IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_unified_patients_phone ON unified_patient_profiles(primary_phone) WHERE primary_phone IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_unified_patients_email_phone ON unified_patient_profiles(primary_email, primary_phone);

-- ============================================================
-- Table 2: Patient Account Links
-- ============================================================
-- Maps tenant-specific customer accounts to unified patient profiles

CREATE TABLE IF NOT EXISTS patient_account_links (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    unified_patient_id UUID NOT NULL REFERENCES unified_patient_profiles(id) ON DELETE CASCADE,
    customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,

    -- Account details at time of linking (for audit trail)
    email_at_link VARCHAR(255),
    phone_at_link VARCHAR(20),
    name_at_link VARCHAR(255),

    -- Metadata
    is_primary_account BOOLEAN DEFAULT FALSE,
    linked_at TIMESTAMPTZ DEFAULT NOW(),
    linked_by VARCHAR(50) DEFAULT 'auto', -- 'auto', 'manual', 'user_merge'

    UNIQUE(customer_id, tenant_id)
);

-- Indexes for fast lookups
CREATE INDEX IF NOT EXISTS idx_account_links_unified_patient ON patient_account_links(unified_patient_id);
CREATE INDEX IF NOT EXISTS idx_account_links_customer ON patient_account_links(customer_id);
CREATE INDEX IF NOT EXISTS idx_account_links_tenant ON patient_account_links(tenant_id);

-- ============================================================
-- Table 3: Cross-Tenant Consents
-- ============================================================
-- Track patient consent for cross-tenant data sharing (GDPR compliant)

CREATE TABLE IF NOT EXISTS cross_tenant_consents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    unified_patient_id UUID NOT NULL REFERENCES unified_patient_profiles(id) ON DELETE CASCADE,

    -- What data can be shared across tenants
    share_medical_history BOOLEAN DEFAULT FALSE,
    share_prescriptions BOOLEAN DEFAULT FALSE,
    share_consultation_notes BOOLEAN DEFAULT FALSE,
    share_purchase_history BOOLEAN DEFAULT FALSE,
    share_with_pharmacies BOOLEAN DEFAULT FALSE,
    share_with_labs BOOLEAN DEFAULT FALSE,
    share_with_doctors BOOLEAN DEFAULT TRUE, -- Default true for better care

    -- When and how consent was given
    consented_at TIMESTAMPTZ DEFAULT NOW(),
    consent_method VARCHAR(50) DEFAULT 'implicit', -- 'signup', 'settings_update', 'implicit'
    consent_version VARCHAR(20) DEFAULT '1.0', -- Track consent form versions

    updated_at TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(unified_patient_id)
);

-- Index for fast consent lookups
CREATE INDEX IF NOT EXISTS idx_consents_unified_patient ON cross_tenant_consents(unified_patient_id);

-- ============================================================
-- Function 1: Find or Create Unified Patient Profile
-- ============================================================
-- Searches for existing profile by email/phone or creates new one

CREATE OR REPLACE FUNCTION find_or_create_unified_patient(
    p_email VARCHAR(255),
    p_phone VARCHAR(20),
    p_name VARCHAR(255)
)
RETURNS UUID AS $$
DECLARE
    v_unified_patient_id UUID;
    v_match_confidence DECIMAL(3,2);
    v_match_method VARCHAR(50);
BEGIN
    -- Try to find existing profile by email (highest confidence)
    IF p_email IS NOT NULL THEN
        SELECT id INTO v_unified_patient_id
        FROM unified_patient_profiles
        WHERE primary_email = p_email
        LIMIT 1;

        IF FOUND THEN
            -- Update last_seen_at
            UPDATE unified_patient_profiles
            SET last_seen_at = NOW()
            WHERE id = v_unified_patient_id;

            RETURN v_unified_patient_id;
        END IF;
    END IF;

    -- Try to find by phone if email not found (medium confidence)
    IF p_phone IS NOT NULL THEN
        SELECT id INTO v_unified_patient_id
        FROM unified_patient_profiles
        WHERE primary_phone = p_phone
        LIMIT 1;

        IF FOUND THEN
            -- Update last_seen_at and potentially update email
            UPDATE unified_patient_profiles
            SET
                last_seen_at = NOW(),
                primary_email = COALESCE(primary_email, p_email)
            WHERE id = v_unified_patient_id;

            RETURN v_unified_patient_id;
        END IF;
    END IF;

    -- No existing profile found, create new one
    v_match_confidence := 1.00;
    IF p_email IS NOT NULL AND p_phone IS NOT NULL THEN
        v_match_method := 'email_phone';
    ELSIF p_email IS NOT NULL THEN
        v_match_method := 'email_only';
    ELSIF p_phone IS NOT NULL THEN
        v_match_method := 'phone_only';
    ELSE
        v_match_method := 'name_only';
        v_match_confidence := 0.50;
    END IF;

    INSERT INTO unified_patient_profiles (
        primary_email,
        primary_phone,
        primary_name,
        first_seen_at,
        last_seen_at,
        total_accounts,
        match_confidence,
        match_method
    )
    VALUES (
        p_email,
        p_phone,
        p_name,
        NOW(),
        NOW(),
        0,
        v_match_confidence,
        v_match_method
    )
    RETURNING id INTO v_unified_patient_id;

    -- Create default consent record (implicit consent for medical data sharing)
    INSERT INTO cross_tenant_consents (
        unified_patient_id,
        share_medical_history,
        share_prescriptions,
        share_consultation_notes,
        share_with_doctors,
        consent_method
    )
    VALUES (
        v_unified_patient_id,
        TRUE,
        TRUE,
        TRUE,
        TRUE,
        'implicit'
    );

    RETURN v_unified_patient_id;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- Function 2: Link Customer Account to Unified Patient
-- ============================================================
-- Creates the link between a tenant-specific customer and unified profile

CREATE OR REPLACE FUNCTION link_customer_to_unified_patient(
    p_customer_id UUID,
    p_tenant_id UUID,
    p_email VARCHAR(255) DEFAULT NULL,
    p_phone VARCHAR(20) DEFAULT NULL,
    p_name VARCHAR(255) DEFAULT NULL,
    p_linked_by VARCHAR(50) DEFAULT 'auto'
)
RETURNS UUID AS $$
DECLARE
    v_unified_patient_id UUID;
    v_existing_link UUID;
    v_total_accounts INTEGER;
BEGIN
    -- Check if customer is already linked
    SELECT id, unified_patient_id INTO v_existing_link, v_unified_patient_id
    FROM patient_account_links
    WHERE customer_id = p_customer_id AND tenant_id = p_tenant_id;

    IF FOUND THEN
        -- Already linked, return existing unified patient ID
        RETURN v_unified_patient_id;
    END IF;

    -- Find or create unified patient profile
    v_unified_patient_id := find_or_create_unified_patient(p_email, p_phone, p_name);

    -- Create the link
    INSERT INTO patient_account_links (
        unified_patient_id,
        customer_id,
        tenant_id,
        email_at_link,
        phone_at_link,
        name_at_link,
        is_primary_account,
        linked_by
    )
    VALUES (
        v_unified_patient_id,
        p_customer_id,
        p_tenant_id,
        p_email,
        p_phone,
        p_name,
        FALSE, -- Will set primary separately if needed
        p_linked_by
    );

    -- Update total_accounts counter
    SELECT COUNT(*) INTO v_total_accounts
    FROM patient_account_links
    WHERE unified_patient_id = v_unified_patient_id;

    UPDATE unified_patient_profiles
    SET
        total_accounts = v_total_accounts,
        last_seen_at = NOW()
    WHERE id = v_unified_patient_id;

    RETURN v_unified_patient_id;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- Function 3: Get All Customer IDs for Unified Patient
-- ============================================================
-- Returns all tenant-specific customer IDs for a unified patient

CREATE OR REPLACE FUNCTION get_all_customer_ids_for_patient(
    p_customer_id UUID
)
RETURNS TABLE (
    customer_id UUID,
    tenant_id UUID,
    tenant_name VARCHAR(255),
    email VARCHAR(255),
    phone VARCHAR(20),
    linked_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        c.id as customer_id,
        c.tenant_id,
        t.business_name as tenant_name,
        c.email,
        c.phone,
        pal.linked_at
    FROM customers c
    JOIN patient_account_links pal ON c.id = pal.customer_id
    JOIN tenants t ON c.tenant_id = t.id
    WHERE pal.unified_patient_id = (
        SELECT unified_patient_id
        FROM patient_account_links
        WHERE customer_id = p_customer_id
        LIMIT 1
    )
    ORDER BY pal.linked_at ASC;
END;
$$ LANGUAGE plpgsql STABLE;

-- ============================================================
-- Function 4: Check Cross-Tenant Data Sharing Consent
-- ============================================================
-- Verifies if patient has consented to share specific data types

CREATE OR REPLACE FUNCTION can_share_patient_data(
    p_customer_id UUID,
    p_data_type VARCHAR(50)
)
RETURNS BOOLEAN AS $$
DECLARE
    v_unified_patient_id UUID;
    v_can_share BOOLEAN;
BEGIN
    -- Get unified patient ID
    SELECT unified_patient_id INTO v_unified_patient_id
    FROM patient_account_links
    WHERE customer_id = p_customer_id
    LIMIT 1;

    IF NOT FOUND THEN
        RETURN FALSE; -- No unified profile = no sharing
    END IF;

    -- Check consent based on data type
    CASE p_data_type
        WHEN 'medical_history' THEN
            SELECT share_medical_history INTO v_can_share
            FROM cross_tenant_consents
            WHERE unified_patient_id = v_unified_patient_id;
        WHEN 'prescriptions' THEN
            SELECT share_prescriptions INTO v_can_share
            FROM cross_tenant_consents
            WHERE unified_patient_id = v_unified_patient_id;
        WHEN 'consultation_notes' THEN
            SELECT share_consultation_notes INTO v_can_share
            FROM cross_tenant_consents
            WHERE unified_patient_id = v_unified_patient_id;
        WHEN 'purchase_history' THEN
            SELECT share_purchase_history INTO v_can_share
            FROM cross_tenant_consents
            WHERE unified_patient_id = v_unified_patient_id;
        ELSE
            RETURN FALSE;
    END CASE;

    RETURN COALESCE(v_can_share, FALSE);
END;
$$ LANGUAGE plpgsql STABLE;

-- ============================================================
-- Function 5: Get Unified Patient Medical History
-- ============================================================
-- Returns complete patient history across all linked accounts

CREATE OR REPLACE FUNCTION get_unified_patient_history(
    p_customer_id UUID
)
RETURNS TABLE (
    event_type VARCHAR(50),
    event_id UUID,
    event_date TIMESTAMPTZ,
    tenant_name VARCHAR(255),
    description TEXT,
    amount DECIMAL(12,2)
) AS $$
BEGIN
    RETURN QUERY
    WITH unified_patient AS (
        SELECT unified_patient_id
        FROM patient_account_links
        WHERE customer_id = p_customer_id
        LIMIT 1
    ),
    all_customer_ids AS (
        SELECT pal.customer_id
        FROM patient_account_links pal
        WHERE pal.unified_patient_id = (SELECT unified_patient_id FROM unified_patient)
    )
    -- Consultations
    SELECT
        'consultation'::VARCHAR(50) as event_type,
        c.id as event_id,
        c.created_at as event_date,
        t.business_name as tenant_name,
        ('Consultation: ' || c.type)::TEXT as description,
        c.consultation_fee as amount
    FROM consultations c
    JOIN tenants t ON c.tenant_id = t.id
    WHERE c.patient_id IN (SELECT customer_id FROM all_customer_ids)

    UNION ALL

    -- Sales/Orders
    SELECT
        'purchase'::VARCHAR(50) as event_type,
        s.id as event_id,
        s.created_at as event_date,
        t.business_name as tenant_name,
        ('Purchase: ' || s.sale_number)::TEXT as description,
        s.total_amount as amount
    FROM sales s
    JOIN tenants t ON s.tenant_id = t.id
    WHERE s.customer_id IN (SELECT customer_id FROM all_customer_ids)

    ORDER BY event_date DESC;
END;
$$ LANGUAGE plpgsql STABLE;

-- ============================================================
-- Trigger: Update unified_patient_profiles.updated_at
-- ============================================================

CREATE OR REPLACE FUNCTION update_unified_patient_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_unified_patient_profiles_timestamp ON unified_patient_profiles;
CREATE TRIGGER update_unified_patient_profiles_timestamp
    BEFORE UPDATE ON unified_patient_profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_unified_patient_timestamp();

-- ============================================================
-- Trigger: Update cross_tenant_consents.updated_at
-- ============================================================

DROP TRIGGER IF EXISTS update_cross_tenant_consents_timestamp ON cross_tenant_consents;
CREATE TRIGGER update_cross_tenant_consents_timestamp
    BEFORE UPDATE ON cross_tenant_consents
    FOR EACH ROW
    EXECUTE FUNCTION update_unified_patient_timestamp();

-- ============================================================
-- Row Level Security (RLS) Policies
-- ============================================================

-- Enable RLS on new tables
ALTER TABLE unified_patient_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE patient_account_links ENABLE ROW LEVEL SECURITY;
ALTER TABLE cross_tenant_consents ENABLE ROW LEVEL SECURITY;

-- Unified Patient Profiles: Only accessible by authenticated users for their own profile
CREATE POLICY "Users can view own unified profile"
    ON unified_patient_profiles FOR SELECT
    USING (
        id IN (
            SELECT unified_patient_id
            FROM patient_account_links
            WHERE customer_id IN (
                SELECT id FROM customers WHERE id = auth.uid()
            )
        )
    );

-- Patient Account Links: Users can view their own links
CREATE POLICY "Users can view own account links"
    ON patient_account_links FOR SELECT
    USING (
        customer_id IN (
            SELECT id FROM customers WHERE id = auth.uid()
        )
    );

-- Cross-Tenant Consents: Users can view and update their own consents
CREATE POLICY "Users can view own consents"
    ON cross_tenant_consents FOR SELECT
    USING (
        unified_patient_id IN (
            SELECT unified_patient_id
            FROM patient_account_links
            WHERE customer_id IN (
                SELECT id FROM customers WHERE id = auth.uid()
            )
        )
    );

CREATE POLICY "Users can update own consents"
    ON cross_tenant_consents FOR UPDATE
    USING (
        unified_patient_id IN (
            SELECT unified_patient_id
            FROM patient_account_links
            WHERE customer_id IN (
                SELECT id FROM customers WHERE id = auth.uid()
            )
        )
    );

-- ============================================================
-- Comments for Documentation
-- ============================================================

COMMENT ON TABLE unified_patient_profiles IS 'Universal patient identity that links multiple tenant accounts for cross-tenant medical history';
COMMENT ON TABLE patient_account_links IS 'Maps tenant-specific customer accounts to unified patient profiles';
COMMENT ON TABLE cross_tenant_consents IS 'Tracks patient consent for cross-tenant data sharing (GDPR compliant)';

COMMENT ON FUNCTION find_or_create_unified_patient IS 'Searches for existing patient profile by email/phone or creates new one';
COMMENT ON FUNCTION link_customer_to_unified_patient IS 'Links a tenant-specific customer account to a unified patient profile';
COMMENT ON FUNCTION get_all_customer_ids_for_patient IS 'Returns all tenant-specific customer IDs for a unified patient';
COMMENT ON FUNCTION can_share_patient_data IS 'Checks if patient has consented to share specific data types across tenants';
COMMENT ON FUNCTION get_unified_patient_history IS 'Returns complete patient history (consultations, purchases) across all linked accounts';


-- File: 20260318_healthcare_chat_system.sql
-- ============================================================================
-- Healthcare Chat System Migration
-- ============================================================================
-- Purpose: Create chat tables for provider-patient-pharmacy-lab communication
-- Features:
-- - Multi-party chat (providers, patients, pharmacies, labs)
-- - File attachments (images, PDFs, voice notes)
-- - Read receipts and typing indicators
-- - Message search and filtering
-- - Conversation archiving
-- ============================================================================

-- ============================================================================
-- 1. CHAT CONVERSATIONS
-- ============================================================================

CREATE TABLE IF NOT EXISTS chat_conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Conversation Type
    conversation_type TEXT NOT NULL CHECK (conversation_type IN ('provider_patient', 'provider_pharmacy', 'provider_lab')),

    -- Participants
    provider_id UUID NOT NULL REFERENCES healthcare_providers(id) ON DELETE CASCADE,
    participant_id UUID NOT NULL, -- patient_id (auth.users.id), pharmacy tenant_id, or lab tenant_id
    participant_type TEXT NOT NULL CHECK (participant_type IN ('patient', 'pharmacy', 'lab')),
    participant_name TEXT, -- Cached for performance
    participant_avatar_url TEXT,

    -- Conversation Metadata
    title TEXT, -- Optional conversation title
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'archived', 'deleted')),

    -- Last Message Info (denormalized for performance)
    last_message_content TEXT,
    last_message_time TIMESTAMPTZ,
    last_message_sender_id UUID,
    last_message_sender_type TEXT CHECK (last_message_sender_type IN ('provider', 'participant')),

    -- Unread Counts
    provider_unread_count INTEGER DEFAULT 0,
    participant_unread_count INTEGER DEFAULT 0,

    -- Related Entities
    consultation_id UUID REFERENCES consultations(id) ON DELETE SET NULL,
    prescription_id UUID REFERENCES prescriptions(id) ON DELETE SET NULL,

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    archived_at TIMESTAMPTZ,

    -- Constraints
    UNIQUE (provider_id, participant_id, participant_type)
);

-- Indexes
CREATE INDEX idx_chat_conversations_provider ON chat_conversations(provider_id, updated_at DESC);
CREATE INDEX idx_chat_conversations_participant ON chat_conversations(participant_id, participant_type, updated_at DESC);
CREATE INDEX idx_chat_conversations_status ON chat_conversations(status, updated_at DESC);
CREATE INDEX idx_chat_conversations_type ON chat_conversations(conversation_type);
CREATE INDEX idx_chat_conversations_unread ON chat_conversations(provider_id) WHERE provider_unread_count > 0;

-- RLS Policies
ALTER TABLE chat_conversations ENABLE ROW LEVEL SECURITY;

-- Providers can view their own conversations
CREATE POLICY "Providers can view own conversations"
    ON chat_conversations FOR SELECT
    USING (provider_id IN (SELECT id FROM healthcare_providers WHERE user_id = auth.uid()));

-- Providers can create conversations
CREATE POLICY "Providers can create conversations"
    ON chat_conversations FOR INSERT
    WITH CHECK (provider_id IN (SELECT id FROM healthcare_providers WHERE user_id = auth.uid()));

-- Providers can update their conversations
CREATE POLICY "Providers can update own conversations"
    ON chat_conversations FOR UPDATE
    USING (provider_id IN (SELECT id FROM healthcare_providers WHERE user_id = auth.uid()));

-- Patients can view conversations they're part of
CREATE POLICY "Patients can view own conversations"
    ON chat_conversations FOR SELECT
    USING (participant_id = auth.uid() AND participant_type = 'patient');

-- ============================================================================
-- 2. CHAT MESSAGES
-- ============================================================================

CREATE TABLE IF NOT EXISTS chat_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID NOT NULL REFERENCES chat_conversations(id) ON DELETE CASCADE,

    -- Sender Info
    sender_id UUID NOT NULL, -- provider.user_id or patient_id or tenant_id
    sender_type TEXT NOT NULL CHECK (sender_type IN ('provider', 'patient', 'pharmacy', 'lab')),
    sender_name TEXT NOT NULL, -- Cached for performance
    sender_avatar_url TEXT,

    -- Message Content
    message_type TEXT DEFAULT 'text' CHECK (message_type IN ('text', 'image', 'file', 'voice', 'system')),
    content TEXT, -- Text content or file description

    -- Attachments
    attachments JSONB DEFAULT '[]', -- [{url, type, name, size, thumbnail_url}]

    -- Message Status
    is_read BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMPTZ,
    is_edited BOOLEAN DEFAULT FALSE,
    edited_at TIMESTAMPTZ,
    is_deleted BOOLEAN DEFAULT FALSE,
    deleted_at TIMESTAMPTZ,

    -- Reply/Thread Support
    reply_to_message_id UUID REFERENCES chat_messages(id) ON DELETE SET NULL,

    -- Metadata
    metadata JSONB, -- For future extensions (reactions, forwarded, etc.)

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_chat_messages_conversation ON chat_messages(conversation_id, created_at DESC);
CREATE INDEX idx_chat_messages_sender ON chat_messages(sender_id, sender_type);
CREATE INDEX idx_chat_messages_unread ON chat_messages(conversation_id, is_read) WHERE is_read = FALSE;
CREATE INDEX idx_chat_messages_type ON chat_messages(message_type);
CREATE INDEX idx_chat_messages_content_search ON chat_messages USING gin(to_tsvector('english', content));

-- RLS Policies
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;

-- Providers can view messages in their conversations
CREATE POLICY "Providers can view conversation messages"
    ON chat_messages FOR SELECT
    USING (
        conversation_id IN (
            SELECT id FROM chat_conversations
            WHERE provider_id IN (SELECT id FROM healthcare_providers WHERE user_id = auth.uid())
        )
    );

-- Providers can send messages
CREATE POLICY "Providers can send messages"
    ON chat_messages FOR INSERT
    WITH CHECK (
        sender_type = 'provider' AND
        conversation_id IN (
            SELECT id FROM chat_conversations
            WHERE provider_id IN (SELECT id FROM healthcare_providers WHERE user_id = auth.uid())
        )
    );

-- Providers can update their own messages (edit, mark as read)
CREATE POLICY "Providers can update own messages"
    ON chat_messages FOR UPDATE
    USING (
        conversation_id IN (
            SELECT id FROM chat_conversations
            WHERE provider_id IN (SELECT id FROM healthcare_providers WHERE user_id = auth.uid())
        )
    );

-- Patients can view messages in their conversations
CREATE POLICY "Patients can view conversation messages"
    ON chat_messages FOR SELECT
    USING (
        conversation_id IN (
            SELECT id FROM chat_conversations
            WHERE participant_id = auth.uid() AND participant_type = 'patient'
        )
    );

-- Patients can send messages
CREATE POLICY "Patients can send messages"
    ON chat_messages FOR INSERT
    WITH CHECK (
        sender_type = 'patient' AND
        sender_id = auth.uid() AND
        conversation_id IN (
            SELECT id FROM chat_conversations
            WHERE participant_id = auth.uid() AND participant_type = 'patient'
        )
    );

-- ============================================================================
-- 3. CHAT ATTACHMENTS METADATA (Optional - for tracking)
-- ============================================================================

CREATE TABLE IF NOT EXISTS chat_attachments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    message_id UUID NOT NULL REFERENCES chat_messages(id) ON DELETE CASCADE,
    conversation_id UUID NOT NULL REFERENCES chat_conversations(id) ON DELETE CASCADE,

    -- File Info
    file_name TEXT NOT NULL,
    file_type TEXT NOT NULL, -- MIME type
    file_size BIGINT NOT NULL, -- bytes
    file_url TEXT NOT NULL, -- Supabase storage URL
    thumbnail_url TEXT, -- For images/videos

    -- File Category
    category TEXT NOT NULL CHECK (category IN ('image', 'document', 'voice', 'video', 'other')),

    -- Upload Info
    uploaded_by UUID NOT NULL,
    uploaded_by_type TEXT NOT NULL CHECK (uploaded_by_type IN ('provider', 'patient', 'pharmacy', 'lab')),

    -- Virus Scan (optional)
    scan_status TEXT DEFAULT 'pending' CHECK (scan_status IN ('pending', 'clean', 'infected', 'failed')),
    scan_result JSONB,

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_chat_attachments_message ON chat_attachments(message_id);
CREATE INDEX idx_chat_attachments_conversation ON chat_attachments(conversation_id, created_at DESC);
CREATE INDEX idx_chat_attachments_category ON chat_attachments(category);
CREATE INDEX idx_chat_attachments_uploader ON chat_attachments(uploaded_by, uploaded_by_type);

-- RLS Policies
ALTER TABLE chat_attachments ENABLE ROW LEVEL SECURITY;

-- Same access as messages
CREATE POLICY "Access follows message access"
    ON chat_attachments FOR SELECT
    USING (
        message_id IN (
            SELECT id FROM chat_messages
            WHERE conversation_id IN (
                SELECT id FROM chat_conversations
                WHERE provider_id IN (SELECT id FROM healthcare_providers WHERE user_id = auth.uid())
                   OR (participant_id = auth.uid() AND participant_type = 'patient')
            )
        )
    );

-- ============================================================================
-- 4. TYPING INDICATORS (Real-time presence)
-- ============================================================================

CREATE TABLE IF NOT EXISTS chat_typing_indicators (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID NOT NULL REFERENCES chat_conversations(id) ON DELETE CASCADE,

    -- Typer Info
    user_id UUID NOT NULL,
    user_type TEXT NOT NULL CHECK (user_type IN ('provider', 'patient', 'pharmacy', 'lab')),
    user_name TEXT NOT NULL,

    -- Status
    is_typing BOOLEAN DEFAULT TRUE,

    -- Timestamps
    started_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    -- Auto-cleanup after 10 seconds of inactivity
    expires_at TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '10 seconds'),

    UNIQUE (conversation_id, user_id, user_type)
);

-- Index
CREATE INDEX idx_typing_indicators_conversation ON chat_typing_indicators(conversation_id, expires_at);

-- RLS Policies
ALTER TABLE chat_typing_indicators ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own typing status"
    ON chat_typing_indicators FOR ALL
    USING (user_id = auth.uid());

-- ============================================================================
-- 5. HELPER FUNCTIONS
-- ============================================================================

-- Update conversation's last message info
CREATE OR REPLACE FUNCTION update_conversation_last_message()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE chat_conversations
    SET
        last_message_content = NEW.content,
        last_message_time = NEW.created_at,
        last_message_sender_id = NEW.sender_id,
        last_message_sender_type = NEW.sender_type,
        updated_at = NOW(),
        -- Increment unread count for the recipient
        provider_unread_count = CASE
            WHEN NEW.sender_type != 'provider' THEN provider_unread_count + 1
            ELSE provider_unread_count
        END,
        participant_unread_count = CASE
            WHEN NEW.sender_type = 'provider' THEN participant_unread_count + 1
            ELSE participant_unread_count
        END
    WHERE id = NEW.conversation_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_conversation_last_message
    AFTER INSERT ON chat_messages
    FOR EACH ROW
    EXECUTE FUNCTION update_conversation_last_message();

-- Mark messages as read
CREATE OR REPLACE FUNCTION mark_messages_as_read(
    p_conversation_id UUID,
    p_reader_type TEXT
)
RETURNS void AS $$
BEGIN
    -- Mark messages as read
    UPDATE chat_messages
    SET is_read = TRUE, read_at = NOW()
    WHERE conversation_id = p_conversation_id
      AND sender_type != p_reader_type
      AND is_read = FALSE;

    -- Reset unread count
    IF p_reader_type = 'provider' THEN
        UPDATE chat_conversations
        SET provider_unread_count = 0
        WHERE id = p_conversation_id;
    ELSE
        UPDATE chat_conversations
        SET participant_unread_count = 0
        WHERE id = p_conversation_id;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Clean up expired typing indicators
CREATE OR REPLACE FUNCTION cleanup_expired_typing_indicators()
RETURNS void AS $$
BEGIN
    DELETE FROM chat_typing_indicators
    WHERE expires_at < NOW();
END;
$$ LANGUAGE plpgsql;

-- Schedule cleanup (requires pg_cron extension)
-- SELECT cron.schedule('cleanup-typing-indicators', '*/30 * * * * *', 'SELECT cleanup_expired_typing_indicators();');

-- ============================================================================
-- 6. INDEXES FOR PERFORMANCE
-- ============================================================================

-- Full-text search on messages
CREATE INDEX IF NOT EXISTS idx_messages_fts ON chat_messages
USING gin(to_tsvector('english', coalesce(content, '')));

-- Conversation search by participant name
CREATE INDEX IF NOT EXISTS idx_conversations_participant_name ON chat_conversations
USING gin(to_tsvector('english', coalesce(participant_name, '')));

-- ============================================================================
-- MIGRATION COMPLETE
-- ============================================================================

-- Summary:
-- âœ… chat_conversations - Main conversation table with participant info
-- âœ… chat_messages - Individual messages with attachments support
-- âœ… chat_attachments - Detailed file tracking
-- âœ… chat_typing_indicators - Real-time typing presence
-- âœ… RLS policies for secure access
-- âœ… Helper functions for message management
-- âœ… Full-text search indexes
-- âœ… Trigger to update last message info


-- File: 20260319_add_healthcare_provider_subscription_policy.sql
-- Add RLS Policy for Healthcare Providers to Create Subscriptions
-- Date: 2026-03-19
--
-- Issue: Healthcare providers can't create subscription records during onboarding
-- Fix: Add policy allowing authenticated users to create subscriptions

-- ============================================================================
-- ADD POLICY FOR HEALTHCARE PROVIDERS TO CREATE SUBSCRIPTIONS
-- ============================================================================

-- Allow authenticated users (healthcare providers) to create subscriptions
-- This is needed for onboarding flow where providers create their own subscription
CREATE POLICY "Authenticated users can create subscriptions"
    ON subscriptions FOR INSERT
    WITH CHECK (auth.uid() IS NOT NULL);

-- Allow users to view subscriptions they created (for healthcare providers)
-- This supplements the existing tenant-based policy
CREATE POLICY "Users can view own subscriptions"
    ON subscriptions FOR SELECT
    USING (
        -- Either they're a healthcare provider viewing their subscription
        EXISTS (
            SELECT 1 FROM healthcare_providers
            WHERE healthcare_providers.subscription_id = subscriptions.id
            AND healthcare_providers.user_id = auth.uid()
        )
        -- Or it's a tenant viewing their subscription (existing policy handles this)
        OR tenant_id = (auth.jwt() ->> 'tenant_id')::UUID
    );

-- Allow healthcare providers to update their own subscriptions
CREATE POLICY "Healthcare providers can update own subscriptions"
    ON subscriptions FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM healthcare_providers
            WHERE healthcare_providers.subscription_id = subscriptions.id
            AND healthcare_providers.user_id = auth.uid()
        )
    );


-- File: 20260319_create_medic_subscriptions.sql
-- Create Medic Subscriptions Table for Healthcare Providers
-- Date: 2026-03-19
--
-- Separate subscription system for healthcare providers to avoid conflicts with POS

-- ============================================================================
-- 1. CREATE MEDIC_SUBSCRIPTIONS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS medic_subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    provider_id UUID REFERENCES healthcare_providers(id) ON DELETE CASCADE,

    -- Subscription Tier
    tier TEXT NOT NULL CHECK (tier IN ('free', 'growth', 'enterprise')),
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'cancelled', 'suspended', 'trial')),

    -- Pricing
    monthly_fee DECIMAL(12,2) NOT NULL CHECK (monthly_fee >= 0),
    -- Free: â‚¦0, Growth: â‚¦25,000, Enterprise: â‚¦120,000

    -- Billing Cycle
    billing_cycle_start TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    billing_cycle_end TIMESTAMPTZ NOT NULL,
    next_billing_date TIMESTAMPTZ,

    -- Payment
    last_payment_date TIMESTAMPTZ,
    payment_method TEXT,

    -- Features (stored as JSONB for flexibility)
    features JSONB DEFAULT '{}',
    -- Tier Features:
    -- FREE (â‚¦0/month):
    --   chat/video/audio: true, office: false, quota: unlimited
    --   drug/diagnostic commissions: false, custom_branding: false
    --   analytics: basic, priority_support: false
    --
    -- GROWTH (â‚¦25,000/month):
    --   chat/video/audio: true, office: false, quota: unlimited
    --   drug/diagnostic commissions: true, custom_branding: true
    --   analytics: full, priority_support: false
    --
    -- ENTERPRISE (â‚¦120,000/month):
    --   chat/video/audio/office: all true, quota: unlimited
    --   drug/diagnostic commissions: true, custom_branding: true
    --   analytics: advanced, priority_support: true, dedicated_manager: true

    -- Commission Settings
    consultation_commission_rate DECIMAL(5,2) DEFAULT 0 CHECK (consultation_commission_rate >= 0 AND consultation_commission_rate <= 100),
    drug_commission_rate DECIMAL(5,2) DEFAULT 0 CHECK (drug_commission_rate >= 0 AND drug_commission_rate <= 100),
    diagnostic_commission_rate DECIMAL(5,2) DEFAULT 0 CHECK (diagnostic_commission_rate >= 0 AND diagnostic_commission_rate <= 100),

    -- Metadata
    notes TEXT,

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- 2. INDEXES
-- ============================================================================

CREATE INDEX idx_medic_subscriptions_user_id ON medic_subscriptions(user_id);
CREATE INDEX idx_medic_subscriptions_provider_id ON medic_subscriptions(provider_id);
CREATE INDEX idx_medic_subscriptions_tier ON medic_subscriptions(tier);
CREATE INDEX idx_medic_subscriptions_status ON medic_subscriptions(status);

-- ============================================================================
-- 3. ROW LEVEL SECURITY
-- ============================================================================

ALTER TABLE medic_subscriptions ENABLE ROW LEVEL SECURITY;

-- Providers can view their own subscription
CREATE POLICY "Providers can view own subscription"
    ON medic_subscriptions FOR SELECT
    USING (user_id = auth.uid());

-- Providers can create their own subscription (during onboarding)
CREATE POLICY "Providers can create own subscription"
    ON medic_subscriptions FOR INSERT
    WITH CHECK (user_id = auth.uid());

-- Providers can update their own subscription
CREATE POLICY "Providers can update own subscription"
    ON medic_subscriptions FOR UPDATE
    USING (user_id = auth.uid());

-- ============================================================================
-- 4. UPDATE TRIGGER
-- ============================================================================

-- Create the update_updated_at_column function if it doesn't exist
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_medic_subscriptions_updated_at
    BEFORE UPDATE ON medic_subscriptions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- 5. UPDATE HEALTHCARE_PROVIDERS TABLE
-- ============================================================================

-- First, drop the policies that depend on the subscription_id column
DROP POLICY IF EXISTS "Users can view own subscriptions" ON subscriptions;
DROP POLICY IF EXISTS "Healthcare providers can update own subscriptions" ON subscriptions;

-- Now remove the old subscription_id column
ALTER TABLE healthcare_providers DROP COLUMN IF EXISTS subscription_id CASCADE;

-- Add new medic_subscription_id column
ALTER TABLE healthcare_providers
ADD COLUMN IF NOT EXISTS medic_subscription_id UUID REFERENCES medic_subscriptions(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_providers_medic_subscription_id ON healthcare_providers(medic_subscription_id);

COMMENT ON COLUMN healthcare_providers.medic_subscription_id IS 'Links healthcare provider to their medic subscription plan';

-- ============================================================================
-- 6. FIX HEALTHCARE_PROVIDERS RLS POLICY
-- ============================================================================

-- Allow providers to read their own profile (even if unverified)
DROP POLICY IF EXISTS "Providers can view own profile" ON healthcare_providers;
CREATE POLICY "Providers can view own profile"
    ON healthcare_providers FOR SELECT
    USING (user_id = auth.uid());

-- ============================================================================
-- 7. HELPER FUNCTION TO GET SUBSCRIPTION TIER NAME
-- ============================================================================

CREATE OR REPLACE FUNCTION get_medic_subscription_tier_name(tier TEXT)
RETURNS TEXT AS $$
BEGIN
    CASE tier
        WHEN 'free' THEN RETURN 'Free';
        WHEN 'growth' THEN RETURN 'Growth';
        WHEN 'enterprise' THEN RETURN 'Enterprise';
        ELSE RETURN 'Unknown';
    END CASE;
END;
$$ LANGUAGE plpgsql IMMUTABLE;


-- File: 20260319_fix_provider_self_read_policy.sql
-- Fix Healthcare Provider Self-Read RLS Policy
-- Date: 2026-03-19
--
-- Issue: Providers can't read their own unverified profiles during onboarding
-- Fix: Add policy allowing providers to always read their own profile

-- ============================================================================
-- ADD POLICY FOR PROVIDERS TO READ OWN PROFILE
-- ============================================================================

-- Allow providers to read their own profile regardless of verification status
CREATE POLICY "Providers can view own profile"
    ON healthcare_providers FOR SELECT
    USING (user_id = auth.uid());

-- Note: The existing policy "Anyone can view active verified providers" allows
-- public viewing of verified providers. This new policy allows self-viewing.


-- File: 20260319_link_healthcare_providers_subscriptions.sql
-- Link Healthcare Providers to Existing Subscriptions Table
-- Date: 2026-03-19
--
-- This migration adds a subscription_id column to healthcare_providers
-- to reference the existing subscriptions table used by the POS app

-- ============================================================================
-- ADD SUBSCRIPTION_ID TO HEALTHCARE_PROVIDERS
-- ============================================================================

ALTER TABLE healthcare_providers
ADD COLUMN IF NOT EXISTS subscription_id UUID REFERENCES subscriptions(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_providers_subscription_id ON healthcare_providers(subscription_id);

COMMENT ON COLUMN healthcare_providers.subscription_id IS 'Links healthcare provider to their subscription plan (shared with POS tenants)';


-- File: 20260320_add_healthcare_provider_patients.sql
-- ============================================================
-- Healthcare Provider Patient Management
-- ============================================================
-- Purpose: Link customers to healthcare providers as their patients
-- Add profile photos and soft delete support for patient management

-- Add healthcare_provider_id to customers table (patients added by providers)
ALTER TABLE customers
ADD COLUMN IF NOT EXISTS healthcare_provider_id UUID REFERENCES healthcare_providers(id) ON DELETE SET NULL;

-- Add profile photo support for patients
ALTER TABLE customers
ADD COLUMN IF NOT EXISTS profile_photo_url TEXT;

-- Add is_deleted column for soft delete (separate from sync)
ALTER TABLE customers
ADD COLUMN IF NOT EXISTS is_deleted BOOLEAN DEFAULT FALSE;

-- Index for fast provider patient lookups
CREATE INDEX IF NOT EXISTS idx_customers_provider_id
ON customers(healthcare_provider_id)
WHERE is_deleted = FALSE;

-- Index for profile photos
CREATE INDEX IF NOT EXISTS idx_customers_profile_photo
ON customers(profile_photo_url)
WHERE profile_photo_url IS NOT NULL;

-- Update unified_patient_profiles to include profile photo
ALTER TABLE unified_patient_profiles
ADD COLUMN IF NOT EXISTS profile_photo_url TEXT;

-- ============================================================
-- RLS Policies for Provider-Patient Access
-- ============================================================

-- Providers can view their own patients
CREATE POLICY "Providers can view their patients"
ON customers FOR SELECT
USING (
    healthcare_provider_id IN (
        SELECT id FROM healthcare_providers
        WHERE user_id = auth.uid()
    )
    AND is_deleted = FALSE
);

-- Providers can insert patients
CREATE POLICY "Providers can add patients"
ON customers FOR INSERT
WITH CHECK (
    healthcare_provider_id IN (
        SELECT id FROM healthcare_providers
        WHERE user_id = auth.uid()
    )
);

-- Providers can update their patients
CREATE POLICY "Providers can update their patients"
ON customers FOR UPDATE
USING (
    healthcare_provider_id IN (
        SELECT id FROM healthcare_providers
        WHERE user_id = auth.uid()
    )
);

-- Providers can soft delete their patients (update is_deleted)
CREATE POLICY "Providers can soft delete their patients"
ON customers FOR UPDATE
USING (
    healthcare_provider_id IN (
        SELECT id FROM healthcare_providers
        WHERE user_id = auth.uid()
    )
)
WITH CHECK (
    healthcare_provider_id IN (
        SELECT id FROM healthcare_providers
        WHERE user_id = auth.uid()
    )
);

-- ============================================================
-- Helper Function: Get Provider's Patients
-- ============================================================

CREATE OR REPLACE FUNCTION get_provider_patients(
    p_provider_id UUID
)
RETURNS TABLE (
    id UUID,
    full_name VARCHAR(255),
    email VARCHAR(255),
    phone VARCHAR(20),
    profile_photo_url TEXT,
    unified_patient_id UUID,
    total_consultations INTEGER,
    last_consultation_date TIMESTAMPTZ,
    created_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        c.id,
        c.full_name,
        c.email,
        c.phone,
        c.profile_photo_url,
        pal.unified_patient_id,
        COALESCE(
            (SELECT COUNT(*)::INTEGER
             FROM consultations
             WHERE patient_id = c.id
             AND provider_id = p_provider_id),
            0
        ) as total_consultations,
        (SELECT MAX(created_at)
         FROM consultations
         WHERE patient_id = c.id
         AND provider_id = p_provider_id) as last_consultation_date,
        c.created_at
    FROM customers c
    LEFT JOIN patient_account_links pal ON c.id = pal.customer_id
    WHERE c.healthcare_provider_id = p_provider_id
    AND c.is_deleted = FALSE
    ORDER BY c.created_at DESC;
END;
$$ LANGUAGE plpgsql STABLE;

-- ============================================================
-- Comments
-- ============================================================

COMMENT ON COLUMN customers.healthcare_provider_id IS 'Provider who added this patient to their practice';
COMMENT ON COLUMN customers.profile_photo_url IS 'Patient profile picture URL';
COMMENT ON COLUMN customers.is_deleted IS 'Soft delete flag for patient records';
COMMENT ON FUNCTION get_provider_patients IS 'Returns all active patients for a healthcare provider with consultation stats';


-- File: 20260320_add_marked_up_fees_to_providers.sql
-- Add marked_up_fees column to healthcare_providers table
-- Date: 2026-03-20
-- This stores the customer-facing fees with 10% markup applied

ALTER TABLE healthcare_providers
ADD COLUMN IF NOT EXISTS marked_up_fees JSONB DEFAULT '{"chat": 0, "video": 0, "audio": 0, "office_visit": 0}';

-- Add index for marked_up_fees queries
CREATE INDEX IF NOT EXISTS idx_providers_marked_up_fees ON healthcare_providers USING GIN (marked_up_fees);

-- Comment for documentation
COMMENT ON COLUMN healthcare_providers.marked_up_fees IS 'Customer-facing consultation fees with 10% markup: {chat, video, audio, office_visit}';


-- File: 20260320_add_profile_editing_support.sql
-- ============================================================================
-- HEALTHCARE PROVIDER PROFILE EDITING SUPPORT
-- ============================================================================
-- This migration adds support for comprehensive provider profile editing:
-- - Work experience management
-- - Certificate uploads with metadata
-- - License uploads with metadata
-- - Sub-specialty field
-- - Preferred languages array field
-- ============================================================================

-- ============================================================================
-- PROVIDER WORK EXPERIENCE TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS provider_work_experience (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    provider_id UUID NOT NULL REFERENCES healthcare_providers(id) ON DELETE CASCADE,

    -- Work Details
    position TEXT NOT NULL,
    organization TEXT NOT NULL,
    location TEXT,
    start_date DATE NOT NULL,
    end_date DATE, -- NULL if current position
    is_current BOOLEAN DEFAULT FALSE,
    description TEXT,

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_work_experience_provider ON provider_work_experience(provider_id);
CREATE INDEX idx_work_experience_dates ON provider_work_experience(start_date DESC, end_date DESC);

-- RLS Policies
ALTER TABLE provider_work_experience ENABLE ROW LEVEL SECURITY;

-- Providers can manage their own work experience
CREATE POLICY "Providers can manage own work experience"
    ON provider_work_experience FOR ALL
    USING (provider_id IN (SELECT id FROM healthcare_providers WHERE user_id = auth.uid()));

-- Public read for verified providers
CREATE POLICY "Anyone can view verified provider work experience"
    ON provider_work_experience FOR SELECT
    USING (
        provider_id IN (
            SELECT id FROM healthcare_providers
            WHERE is_active = TRUE AND is_verified = TRUE
        )
    );

-- ============================================================================
-- PROVIDER CERTIFICATES TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS provider_certificates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    provider_id UUID NOT NULL REFERENCES healthcare_providers(id) ON DELETE CASCADE,

    -- Certificate Details
    certificate_name TEXT NOT NULL,
    issuing_organization TEXT NOT NULL,
    issue_date DATE NOT NULL,
    expiry_date DATE, -- NULL if no expiry
    certificate_number TEXT,

    -- File Storage
    file_url TEXT NOT NULL, -- Supabase Storage URL
    file_name TEXT NOT NULL,
    file_size INTEGER, -- bytes
    file_type TEXT, -- PDF, image/jpeg, etc.

    -- Verification
    is_verified BOOLEAN DEFAULT FALSE,
    verified_at TIMESTAMPTZ,
    verified_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_certificates_provider ON provider_certificates(provider_id);
CREATE INDEX idx_certificates_expiry ON provider_certificates(expiry_date) WHERE expiry_date IS NOT NULL;

-- RLS Policies
ALTER TABLE provider_certificates ENABLE ROW LEVEL SECURITY;

-- Providers can manage their own certificates
CREATE POLICY "Providers can manage own certificates"
    ON provider_certificates FOR ALL
    USING (provider_id IN (SELECT id FROM healthcare_providers WHERE user_id = auth.uid()));

-- Public read for verified providers
CREATE POLICY "Anyone can view verified provider certificates"
    ON provider_certificates FOR SELECT
    USING (
        provider_id IN (
            SELECT id FROM healthcare_providers
            WHERE is_active = TRUE AND is_verified = TRUE
        )
    );

-- ============================================================================
-- PROVIDER LICENSES TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS provider_licenses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    provider_id UUID NOT NULL REFERENCES healthcare_providers(id) ON DELETE CASCADE,

    -- License Details
    license_type TEXT NOT NULL, -- 'Medical License', 'Pharmacy License', etc.
    license_number TEXT NOT NULL,
    issuing_authority TEXT NOT NULL, -- 'MDCN', 'PCN', etc.
    issue_date DATE NOT NULL,
    expiry_date DATE NOT NULL,
    country TEXT NOT NULL,
    state_region TEXT,

    -- File Storage
    file_url TEXT NOT NULL, -- Supabase Storage URL
    file_name TEXT NOT NULL,
    file_size INTEGER, -- bytes
    file_type TEXT,

    -- Verification
    is_verified BOOLEAN DEFAULT FALSE,
    verified_at TIMESTAMPTZ,
    verified_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,

    -- Status
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'expired', 'revoked', 'suspended')),

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    -- Constraints
    CONSTRAINT valid_license_dates CHECK (expiry_date > issue_date)
);

CREATE INDEX idx_licenses_provider ON provider_licenses(provider_id);
CREATE INDEX idx_licenses_expiry ON provider_licenses(expiry_date);
CREATE INDEX idx_licenses_status ON provider_licenses(status, provider_id);

-- RLS Policies
ALTER TABLE provider_licenses ENABLE ROW LEVEL SECURITY;

-- Providers can manage their own licenses
CREATE POLICY "Providers can manage own licenses"
    ON provider_licenses FOR ALL
    USING (provider_id IN (SELECT id FROM healthcare_providers WHERE user_id = auth.uid()));

-- Public read for verified providers with active licenses
CREATE POLICY "Anyone can view verified provider licenses"
    ON provider_licenses FOR SELECT
    USING (
        provider_id IN (
            SELECT id FROM healthcare_providers
            WHERE is_active = TRUE AND is_verified = TRUE
        )
    );

-- ============================================================================
-- ADD NEW FIELDS TO HEALTHCARE_PROVIDERS TABLE
-- ============================================================================
ALTER TABLE healthcare_providers
ADD COLUMN IF NOT EXISTS sub_specialty TEXT,
ADD COLUMN IF NOT EXISTS preferred_languages TEXT[]; -- Array of languages

-- Create GIN index for array search
CREATE INDEX IF NOT EXISTS idx_providers_languages ON healthcare_providers USING GIN (preferred_languages);

-- Comments
COMMENT ON COLUMN healthcare_providers.sub_specialty IS 'Sub-specialty within main specialization (free text)';
COMMENT ON COLUMN healthcare_providers.preferred_languages IS 'Array of languages the provider can communicate in';
COMMENT ON TABLE provider_work_experience IS 'Stores work experience history for healthcare providers';
COMMENT ON TABLE provider_certificates IS 'Stores professional certificates with file attachments for healthcare providers';
COMMENT ON TABLE provider_licenses IS 'Stores professional licenses with file attachments and verification status for healthcare providers';


-- File: 20260320_add_slot_settings_to_providers.sql
-- Add slot_settings column to healthcare_providers table
-- Date: 2026-03-20
-- This allows providers to configure appointment slot duration and buffer times

ALTER TABLE healthcare_providers
ADD COLUMN IF NOT EXISTS slot_settings JSONB DEFAULT '{"duration": 30, "buffer": 0, "breakTimes": []}';

-- Add index for slot_settings queries
CREATE INDEX IF NOT EXISTS idx_providers_slot_settings ON healthcare_providers USING GIN (slot_settings);

-- Comment for documentation
COMMENT ON COLUMN healthcare_providers.slot_settings IS 'Appointment slot configuration: {duration (minutes), buffer (minutes), breakTimes: [{startTime, endTime}]}';


-- File: 20260320_add_work_schedule_to_providers.sql
-- Add work_schedule column to healthcare_providers table
-- Date: 2026-03-20
-- This allows providers to set their working hours for each day of the week

ALTER TABLE healthcare_providers
ADD COLUMN IF NOT EXISTS work_schedule JSONB DEFAULT '[]';

-- Add index for work_schedule queries
CREATE INDEX IF NOT EXISTS idx_providers_work_schedule ON healthcare_providers USING GIN (work_schedule);

-- Comment for documentation
COMMENT ON COLUMN healthcare_providers.work_schedule IS 'Array of objects defining working hours per day: [{day, enabled, startTime, endTime}]';


-- File: 20260320_create_healthcare_patients_table.sql
-- ============================================================
-- Healthcare Patients Table - Clean Separation
-- ============================================================
-- Purpose: Create dedicated patients table for healthcare providers
-- This avoids conflicts with the tenant-based customers table

-- ============================================================
-- Step 1: Remove obsolete columns from customers table
-- ============================================================

-- Drop the policies we created earlier (they're not working anyway)
DROP POLICY IF EXISTS "Healthcare providers can view their patients" ON customers;
DROP POLICY IF EXISTS "Healthcare providers can insert patients" ON customers;
DROP POLICY IF EXISTS "Healthcare providers can update their patients" ON customers;
DROP POLICY IF EXISTS "Healthcare providers can soft delete patients" ON customers;
DROP POLICY IF EXISTS "Tenant members can view customers" ON customers;
DROP POLICY IF EXISTS "Tenant members can insert customers" ON customers;
DROP POLICY IF EXISTS "Tenant members can update customers" ON customers;
DROP POLICY IF EXISTS "Tenant members can delete customers" ON customers;

-- Recreate the original simple policy for customers
CREATE POLICY "Customer tenant isolation" ON customers
    FOR ALL USING (tenant_id = current_tenant_id());

-- Drop obsolete columns from customers (if they exist)
ALTER TABLE customers DROP COLUMN IF EXISTS healthcare_provider_id;
ALTER TABLE customers DROP COLUMN IF EXISTS is_deleted;

-- ============================================================
-- Step 2: Create dedicated patients table
-- ============================================================

CREATE TABLE IF NOT EXISTS patients (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Link to healthcare provider
    healthcare_provider_id UUID NOT NULL REFERENCES healthcare_providers(id) ON DELETE CASCADE,

    -- Link to unified patient profile (for cross-tenant medical history)
    unified_patient_id UUID REFERENCES unified_patient_profiles(id) ON DELETE SET NULL,

    -- Patient Information
    full_name VARCHAR(255) NOT NULL,
    email VARCHAR(255),
    phone VARCHAR(20) NOT NULL,
    whatsapp_number VARCHAR(20),
    date_of_birth DATE,
    gender VARCHAR(20),

    -- Profile
    profile_photo_url TEXT,

    -- Medical Info (optional, can be expanded)
    blood_group VARCHAR(10),
    allergies TEXT[],
    chronic_conditions TEXT[],
    emergency_contact_name VARCHAR(255),
    emergency_contact_phone VARCHAR(20),

    -- Soft delete
    is_deleted BOOLEAN DEFAULT FALSE,
    deleted_at TIMESTAMPTZ,

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    -- Ensure phone is unique per provider (can't add same patient twice)
    UNIQUE(healthcare_provider_id, phone)
);

-- ============================================================
-- Step 3: Indexes for performance
-- ============================================================

CREATE INDEX idx_patients_provider ON patients(healthcare_provider_id) WHERE is_deleted = FALSE;
CREATE INDEX idx_patients_unified ON patients(unified_patient_id);
CREATE INDEX idx_patients_phone ON patients(phone);
CREATE INDEX idx_patients_email ON patients(email) WHERE email IS NOT NULL;
CREATE INDEX idx_patients_deleted ON patients(is_deleted);

-- ============================================================
-- Step 4: Enable RLS
-- ============================================================

ALTER TABLE patients ENABLE ROW LEVEL SECURITY;

-- Providers can view their own patients (not deleted)
CREATE POLICY "Providers can view their patients"
ON patients FOR SELECT
USING (
    healthcare_provider_id IN (
        SELECT id FROM healthcare_providers
        WHERE user_id = auth.uid()
    )
    AND is_deleted = FALSE
);

-- Providers can insert patients
CREATE POLICY "Providers can insert patients"
ON patients FOR INSERT
WITH CHECK (
    healthcare_provider_id IN (
        SELECT id FROM healthcare_providers
        WHERE user_id = auth.uid()
    )
);

-- Providers can update their patients
CREATE POLICY "Providers can update their patients"
ON patients FOR UPDATE
USING (
    healthcare_provider_id IN (
        SELECT id FROM healthcare_providers
        WHERE user_id = auth.uid()
    )
)
WITH CHECK (
    healthcare_provider_id IN (
        SELECT id FROM healthcare_providers
        WHERE user_id = auth.uid()
    )
);

-- Providers can delete (soft delete) their patients
CREATE POLICY "Providers can delete their patients"
ON patients FOR DELETE
USING (
    healthcare_provider_id IN (
        SELECT id FROM healthcare_providers
        WHERE user_id = auth.uid()
    )
);

-- ============================================================
-- Step 5: Trigger to update timestamps
-- ============================================================

CREATE OR REPLACE FUNCTION update_patients_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_patients_timestamp_trigger ON patients;
CREATE TRIGGER update_patients_timestamp_trigger
    BEFORE UPDATE ON patients
    FOR EACH ROW
    EXECUTE FUNCTION update_patients_timestamp();

-- ============================================================
-- Step 6: Function to link patient to unified profile
-- ============================================================

CREATE OR REPLACE FUNCTION link_patient_to_unified_profile()
RETURNS TRIGGER AS $$
DECLARE
    v_unified_patient_id UUID;
BEGIN
    -- Only create link if email or phone is provided
    IF NEW.email IS NOT NULL OR NEW.phone IS NOT NULL THEN
        -- Find or create unified patient profile
        v_unified_patient_id := find_or_create_unified_patient(
            NEW.email,
            NEW.phone,
            NEW.full_name
        );

        -- Update the patient record with unified_patient_id
        NEW.unified_patient_id := v_unified_patient_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS link_patient_to_unified_trigger ON patients;
CREATE TRIGGER link_patient_to_unified_trigger
    BEFORE INSERT ON patients
    FOR EACH ROW
    EXECUTE FUNCTION link_patient_to_unified_profile();

-- ============================================================
-- Step 7: Update consultations to reference patients table
-- ============================================================

-- Add a new column for healthcare patients
ALTER TABLE consultations
ADD COLUMN IF NOT EXISTS healthcare_patient_id UUID REFERENCES patients(id) ON DELETE SET NULL;

-- Create index for fast lookups
CREATE INDEX IF NOT EXISTS idx_consultations_healthcare_patient
ON consultations(healthcare_patient_id);

-- ============================================================
-- Step 8: Helper function to get patient stats
-- ============================================================

CREATE OR REPLACE FUNCTION get_patient_consultation_stats(p_patient_id UUID)
RETURNS TABLE (
    total_consultations INTEGER,
    last_consultation_date TIMESTAMPTZ,
    last_consultation_type VARCHAR(50)
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        COUNT(*)::INTEGER as total_consultations,
        MAX(c.created_at) as last_consultation_date,
        (SELECT type FROM consultations
         WHERE healthcare_patient_id = p_patient_id
         ORDER BY created_at DESC
         LIMIT 1) as last_consultation_type
    FROM consultations c
    WHERE c.healthcare_patient_id = p_patient_id;
END;
$$ LANGUAGE plpgsql STABLE;

-- ============================================================
-- Comments for documentation
-- ============================================================

COMMENT ON TABLE patients IS 'Dedicated patients table for healthcare providers, separate from POS customers';
COMMENT ON COLUMN patients.healthcare_provider_id IS 'Provider who manages this patient';
COMMENT ON COLUMN patients.unified_patient_id IS 'Link to unified patient profile for cross-provider medical history';
COMMENT ON COLUMN patients.is_deleted IS 'Soft delete flag - keeps historical data but hides from UI';
COMMENT ON FUNCTION link_patient_to_unified_profile IS 'Automatically links new patients to unified patient profiles';
COMMENT ON FUNCTION get_patient_consultation_stats IS 'Returns consultation statistics for a patient';


-- File: 20260320_create_storage_buckets.sql
-- ============================================================================
-- CREATE STORAGE BUCKETS FOR HEALTHCARE PROVIDERS
-- ============================================================================
-- This migration creates storage buckets for:
-- - Profile pictures (public)
-- - Certificates (private)
-- - Professional licenses (private)
-- ============================================================================

-- ============================================================================
-- CREATE STORAGE BUCKETS
-- ============================================================================

-- Profile Pictures Bucket
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'provider-profile-pictures',
    'provider-profile-pictures',
    true, -- Public access for profile pictures
    2097152, -- 2MB limit
    ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/jpg']
)
ON CONFLICT (id) DO NOTHING;

-- Certificates Bucket
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'provider-certificates',
    'provider-certificates',
    false, -- Private - only visible to provider and admins
    5242880, -- 5MB limit
    ARRAY['application/pdf', 'image/jpeg', 'image/png', 'image/jpg']
)
ON CONFLICT (id) DO NOTHING;

-- Licenses Bucket
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'provider-licenses',
    'provider-licenses',
    false, -- Private - only visible to provider and admins
    5242880, -- 5MB limit
    ARRAY['application/pdf', 'image/jpeg', 'image/png', 'image/jpg']
)
ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- STORAGE RLS POLICIES - PROFILE PICTURES
-- ============================================================================

DROP POLICY IF EXISTS "Providers can upload own profile pictures" ON storage.objects;
CREATE POLICY "Providers can upload own profile pictures"
    ON storage.objects FOR INSERT
    TO authenticated
    WITH CHECK (
        bucket_id = 'provider-profile-pictures' AND
        auth.uid()::text = (storage.foldername(name))[1]
    );

DROP POLICY IF EXISTS "Providers can update own profile pictures" ON storage.objects;
CREATE POLICY "Providers can update own profile pictures"
    ON storage.objects FOR UPDATE
    TO authenticated
    USING (
        bucket_id = 'provider-profile-pictures' AND
        auth.uid()::text = (storage.foldername(name))[1]
    );

DROP POLICY IF EXISTS "Providers can delete own profile pictures" ON storage.objects;
CREATE POLICY "Providers can delete own profile pictures"
    ON storage.objects FOR DELETE
    TO authenticated
    USING (
        bucket_id = 'provider-profile-pictures' AND
        auth.uid()::text = (storage.foldername(name))[1]
    );

DROP POLICY IF EXISTS "Anyone can view profile pictures" ON storage.objects;
CREATE POLICY "Anyone can view profile pictures"
    ON storage.objects FOR SELECT
    TO public
    USING (bucket_id = 'provider-profile-pictures');

-- ============================================================================
-- STORAGE RLS POLICIES - CERTIFICATES
-- ============================================================================

DROP POLICY IF EXISTS "Providers can upload own certificates" ON storage.objects;
CREATE POLICY "Providers can upload own certificates"
    ON storage.objects FOR INSERT
    TO authenticated
    WITH CHECK (
        bucket_id = 'provider-certificates' AND
        (storage.foldername(name))[1] IN (
            SELECT id::text FROM healthcare_providers WHERE user_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Providers can view own certificates" ON storage.objects;
CREATE POLICY "Providers can view own certificates"
    ON storage.objects FOR SELECT
    TO authenticated
    USING (
        bucket_id = 'provider-certificates' AND
        (storage.foldername(name))[1] IN (
            SELECT id::text FROM healthcare_providers WHERE user_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Providers can update own certificates" ON storage.objects;
CREATE POLICY "Providers can update own certificates"
    ON storage.objects FOR UPDATE
    TO authenticated
    USING (
        bucket_id = 'provider-certificates' AND
        (storage.foldername(name))[1] IN (
            SELECT id::text FROM healthcare_providers WHERE user_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Providers can delete own certificates" ON storage.objects;
CREATE POLICY "Providers can delete own certificates"
    ON storage.objects FOR DELETE
    TO authenticated
    USING (
        bucket_id = 'provider-certificates' AND
        (storage.foldername(name))[1] IN (
            SELECT id::text FROM healthcare_providers WHERE user_id = auth.uid()
        )
    );

-- ============================================================================
-- STORAGE RLS POLICIES - LICENSES
-- ============================================================================

DROP POLICY IF EXISTS "Providers can upload own licenses" ON storage.objects;
CREATE POLICY "Providers can upload own licenses"
    ON storage.objects FOR INSERT
    TO authenticated
    WITH CHECK (
        bucket_id = 'provider-licenses' AND
        (storage.foldername(name))[1] IN (
            SELECT id::text FROM healthcare_providers WHERE user_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Providers can view own licenses" ON storage.objects;
CREATE POLICY "Providers can view own licenses"
    ON storage.objects FOR SELECT
    TO authenticated
    USING (
        bucket_id = 'provider-licenses' AND
        (storage.foldername(name))[1] IN (
            SELECT id::text FROM healthcare_providers WHERE user_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Providers can update own licenses" ON storage.objects;
CREATE POLICY "Providers can update own licenses"
    ON storage.objects FOR UPDATE
    TO authenticated
    USING (
        bucket_id = 'provider-licenses' AND
        (storage.foldername(name))[1] IN (
            SELECT id::text FROM healthcare_providers WHERE user_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Providers can delete own licenses" ON storage.objects;
CREATE POLICY "Providers can delete own licenses"
    ON storage.objects FOR DELETE
    TO authenticated
    USING (
        bucket_id = 'provider-licenses' AND
        (storage.foldername(name))[1] IN (
            SELECT id::text FROM healthcare_providers WHERE user_id = auth.uid()
        )
    );


-- File: 20260320_fix_healthcare_provider_patient_rls.sql
-- ============================================================
-- Fix RLS Policies for Healthcare Provider Patient Management
-- ============================================================
-- Purpose: Allow healthcare providers to add and manage patients
-- without being blocked by tenant-based RLS policies

-- Drop conflicting policies if they exist from previous migration
DROP POLICY IF EXISTS "Providers can view their patients" ON customers;
DROP POLICY IF EXISTS "Providers can add patients" ON customers;
DROP POLICY IF EXISTS "Providers can update their patients" ON customers;
DROP POLICY IF EXISTS "Providers can soft delete their patients" ON customers;

-- ============================================================
-- New RLS Policies for Healthcare Providers
-- ============================================================

-- Policy 1: Healthcare providers can SELECT their patients
CREATE POLICY "Healthcare providers can view their patients"
ON customers FOR SELECT
USING (
    -- Original tenant-based access
    tenant_id = current_tenant_id()
    OR
    -- Healthcare provider access to their patients
    (
        healthcare_provider_id IN (
            SELECT id FROM healthcare_providers
            WHERE user_id = auth.uid()
        )
        AND is_deleted = FALSE
    )
);

-- Policy 2: Healthcare providers can INSERT patients
CREATE POLICY "Healthcare providers can insert patients"
ON customers FOR INSERT
WITH CHECK (
    -- Original tenant-based access
    tenant_id = current_tenant_id()
    OR
    -- Healthcare provider can add patients
    healthcare_provider_id IN (
        SELECT id FROM healthcare_providers
        WHERE user_id = auth.uid()
    )
);

-- Policy 3: Healthcare providers can UPDATE their patients
CREATE POLICY "Healthcare providers can update their patients"
ON customers FOR UPDATE
USING (
    -- Original tenant-based access
    tenant_id = current_tenant_id()
    OR
    -- Healthcare provider access to their patients
    healthcare_provider_id IN (
        SELECT id FROM healthcare_providers
        WHERE user_id = auth.uid()
    )
)
WITH CHECK (
    -- Must still belong to the same provider after update
    healthcare_provider_id IN (
        SELECT id FROM healthcare_providers
        WHERE user_id = auth.uid()
    )
);

-- Policy 4: Healthcare providers can soft DELETE (update is_deleted)
CREATE POLICY "Healthcare providers can soft delete patients"
ON customers FOR UPDATE
USING (
    healthcare_provider_id IN (
        SELECT id FROM healthcare_providers
        WHERE user_id = auth.uid()
    )
)
WITH CHECK (
    healthcare_provider_id IN (
        SELECT id FROM healthcare_providers
        WHERE user_id = auth.uid()
    )
    AND is_deleted = TRUE -- Only allow setting to deleted
);

-- ============================================================
-- Update existing "Customer tenant isolation" policy
-- ============================================================
-- We need to replace the overly broad "FOR ALL" policy with specific ones

-- Drop the old broad policy
DROP POLICY IF EXISTS "Customer tenant isolation" ON customers;

-- Create specific policies for tenant-based access
CREATE POLICY "Tenant members can view customers"
ON customers FOR SELECT
USING (tenant_id = current_tenant_id());

CREATE POLICY "Tenant members can insert customers"
ON customers FOR INSERT
WITH CHECK (tenant_id = current_tenant_id());

CREATE POLICY "Tenant members can update customers"
ON customers FOR UPDATE
USING (tenant_id = current_tenant_id())
WITH CHECK (tenant_id = current_tenant_id());

CREATE POLICY "Tenant members can delete customers"
ON customers FOR DELETE
USING (tenant_id = current_tenant_id());

-- ============================================================
-- Comments
-- ============================================================

COMMENT ON POLICY "Healthcare providers can view their patients" ON customers IS
'Allows healthcare providers to view patients they have added, filtered by is_deleted=false';

COMMENT ON POLICY "Healthcare providers can insert patients" ON customers IS
'Allows healthcare providers to add new patients to their practice';

COMMENT ON POLICY "Healthcare providers can update their patients" ON customers IS
'Allows healthcare providers to update patient information for their own patients';

COMMENT ON POLICY "Healthcare providers can soft delete patients" ON customers IS
'Allows healthcare providers to soft delete patients by setting is_deleted=true';


-- File: 20260320_fix_patients_rls_policy.sql
-- ============================================================
-- Fix RLS Policy for Healthcare Providers and Patients
-- ============================================================
-- Purpose: Allow providers to read their own profile and insert patients

-- ============================================================
-- Step 1: Add SELECT policy for providers to read their own profile
-- ============================================================

-- Drop existing policy if it exists
DROP POLICY IF EXISTS "Providers can read own profile" ON healthcare_providers;

-- Create SELECT policy for providers to read their own profile
CREATE POLICY "Providers can read own profile"
ON healthcare_providers FOR SELECT
USING (
    user_id = auth.uid()
    OR
    (is_active = TRUE AND is_verified = TRUE) -- Allow viewing active/verified profiles
);

-- ============================================================
-- Step 2: Simplify patients INSERT policy
-- ============================================================

-- Drop the existing INSERT policy
DROP POLICY IF EXISTS "Providers can insert patients" ON patients;

-- Create a simpler INSERT policy that works
CREATE POLICY "Providers can insert patients"
ON patients FOR INSERT
WITH CHECK (
    -- Check that the healthcare_provider_id belongs to the current user
    EXISTS (
        SELECT 1 FROM healthcare_providers
        WHERE id = healthcare_provider_id
        AND user_id = auth.uid()
    )
);

-- ============================================================
-- Step 3: Verify other policies are correct
-- ============================================================

-- Drop and recreate UPDATE policy for safety
DROP POLICY IF EXISTS "Providers can update their patients" ON patients;

CREATE POLICY "Providers can update their patients"
ON patients FOR UPDATE
USING (
    EXISTS (
        SELECT 1 FROM healthcare_providers
        WHERE id = healthcare_provider_id
        AND user_id = auth.uid()
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1 FROM healthcare_providers
        WHERE id = healthcare_provider_id
        AND user_id = auth.uid()
    )
);

-- Drop and recreate SELECT policy for safety
DROP POLICY IF EXISTS "Providers can view their patients" ON patients;

CREATE POLICY "Providers can view their patients"
ON patients FOR SELECT
USING (
    is_deleted = FALSE
    AND EXISTS (
        SELECT 1 FROM healthcare_providers
        WHERE id = healthcare_provider_id
        AND user_id = auth.uid()
    )
);

-- Drop and recreate DELETE policy for safety
DROP POLICY IF EXISTS "Providers can delete their patients" ON patients;

CREATE POLICY "Providers can delete their patients"
ON patients FOR DELETE
USING (
    EXISTS (
        SELECT 1 FROM healthcare_providers
        WHERE id = healthcare_provider_id
        AND user_id = auth.uid()
    )
);

-- ============================================================
-- Comments
-- ============================================================

COMMENT ON POLICY "Providers can read own profile" ON healthcare_providers IS
'Allows providers to read their own profile and view active/verified public profiles';

COMMENT ON POLICY "Providers can insert patients" ON patients IS
'Allows providers to insert patients only for their own provider account';

COMMENT ON POLICY "Providers can update their patients" ON patients IS
'Allows providers to update only their own patients';

COMMENT ON POLICY "Providers can view their patients" ON patients IS
'Allows providers to view their own non-deleted patients';

COMMENT ON POLICY "Providers can delete their patients" ON patients IS
'Allows providers to delete their own patients';


