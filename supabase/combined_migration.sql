-- ============================================================
-- Kemani POS - Combined Database Migration
-- ============================================================
-- Generated: 2026-05-09 03:18:46
-- Total Migrations: 200
--
-- Instructions:
-- 1. Copy this entire file
-- 2. Open Supabase SQL Editor
-- 3. Paste and run
-- ============================================================


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

-- End of 000_update_existing_database.sql


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
DO $$ BEGIN
    CREATE TYPE business_type AS ENUM ('supermarket', 'pharmacy', 'grocery', 'mini_mart', 'restaurant');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE user_role AS ENUM ('platform_admin', 'tenant_admin', 'branch_manager', 'cashier', 'driver');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE payment_method AS ENUM ('cash', 'card', 'bank_transfer', 'mobile_money');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE transaction_type AS ENUM ('sale', 'restock', 'adjustment', 'expiry', 'transfer_out', 'transfer_in');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE transfer_status AS ENUM ('pending', 'in_transit', 'completed', 'cancelled');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE sale_status AS ENUM ('completed', 'voided', 'refunded');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE order_type AS ENUM ('marketplace', 'ecommerce_sync', 'ai_chat');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE order_status AS ENUM ('pending', 'confirmed', 'preparing', 'ready', 'completed', 'cancelled');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE payment_status AS ENUM ('unpaid', 'paid', 'refunded');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE fulfillment_type AS ENUM ('pickup', 'delivery');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE delivery_type AS ENUM ('local_bike', 'local_bicycle', 'intercity');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE delivery_status AS ENUM ('pending', 'assigned', 'picked_up', 'in_transit', 'delivered', 'failed', 'cancelled');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE proof_type AS ENUM ('photo', 'signature', 'recipient_name');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE vehicle_type AS ENUM ('bike', 'bicycle');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE platform_type AS ENUM ('woocommerce', 'shopify', 'custom');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE sync_status AS ENUM ('pending', 'syncing', 'success', 'error');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE chat_status AS ENUM ('active', 'completed', 'escalated', 'abandoned');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE sender_type AS ENUM ('customer', 'ai_agent', 'staff');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE plan_tier AS ENUM ('free', 'basic', 'pro', 'enterprise', 'enterprise_custom');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE subscription_status AS ENUM ('active', 'suspended', 'cancelled');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE settlement_status AS ENUM ('pending', 'invoiced', 'paid');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE message_direction AS ENUM ('outbound', 'inbound');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE message_type AS ENUM ('text', 'template', 'media');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE whatsapp_delivery_status AS ENUM ('pending', 'sent', 'delivered', 'read', 'failed');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE receipt_format AS ENUM ('pdf', 'thermal_print', 'email');
EXCEPTION WHEN duplicate_object THEN null; END $$;

-- End of 001_extensions_and_enums.sql


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

-- End of 002_core_tables.sql


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

    -- Healthcare & Laboratory expansions
    unit_of_measure VARCHAR(20) DEFAULT 'piece',
    product_type TEXT, -- 'medication', 'lab_test', 'retail'
    generic_name TEXT,
    strength TEXT,
    dosage_form TEXT,
    manufacturer TEXT,
    test_name TEXT,
    sample_type TEXT,

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

-- End of 003_product_inventory_tables.sql


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

-- End of 004_customer_sales_tables.sql


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

-- End of 005_order_delivery_tables.sql


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

-- End of 006_additional_tables.sql


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

-- End of 007_indexes.sql


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

-- End of 008_rls_policies.sql


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

-- End of 009_triggers.sql


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

-- End of 010_analytics_schema.sql


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

-- End of 011_analytics_indexes_partitions.sql


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

-- End of 012_analytics_etl_functions.sql


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

-- End of 013_analytics_seed_dimensions.sql


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

-- End of 014_enhance_sales_table.sql


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

-- End of 015_enhance_sale_items_table.sql


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
    name VARCHAR(255) NOT NULL,
    path TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for categories
CREATE INDEX IF NOT EXISTS idx_categories_active ON categories(is_active) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_categories_path ON categories(path);
CREATE INDEX IF NOT EXISTS idx_categories_name ON categories(name);

-- RLS for categories (Global Table)
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public can view categories" ON categories;
CREATE POLICY "Public can view categories"
    ON categories FOR SELECT
    USING (true);

DROP POLICY IF EXISTS "Authenticated users can create categories" ON categories;
CREATE POLICY "Authenticated users can create categories"
    ON categories FOR INSERT
    WITH CHECK (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "Authenticated users can update categories" ON categories;
CREATE POLICY "Authenticated users can update categories"
    ON categories FOR UPDATE
    USING (auth.uid() IS NOT NULL);

-- Trigger to update updated_at
DROP TRIGGER IF EXISTS set_updated_at ON categories;
CREATE TRIGGER set_updated_at
    BEFORE UPDATE ON categories
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();

-- Trigger to auto-populate category path
CREATE OR REPLACE FUNCTION update_category_path()
RETURNS TRIGGER AS $$
BEGIN
    NEW.path := '/' || LOWER(REGEXP_REPLACE(NEW.name, '[^a-zA-Z0-9]+', '-', 'g')) || '/';
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_update_category_path ON categories;
CREATE TRIGGER trg_update_category_path
    BEFORE INSERT OR UPDATE ON categories
    FOR EACH ROW
    EXECUTE FUNCTION update_category_path();

-- Global categories classification
COMMENT ON TABLE categories IS 'Global product categories for classification';
COMMENT ON COLUMN categories.path IS 'Slug-based path for classification queries';

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
    END IF;

    -- Standard project indexes for products
    CREATE INDEX IF NOT EXISTS idx_products_sku ON products(tenant_id, sku) WHERE sku IS NOT NULL AND deleted_at IS NULL;
    CREATE INDEX IF NOT EXISTS idx_products_barcode ON products(tenant_id, barcode) WHERE barcode IS NOT NULL AND deleted_at IS NULL;
    CREATE INDEX IF NOT EXISTS idx_products_name_search ON products USING gin (to_tsvector('english', name));
    CREATE INDEX IF NOT EXISTS idx_products_brand ON products(brand_id) WHERE brand_id IS NOT NULL;

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
    IF (OLD.unit_price IS DISTINCT FROM NEW.unit_price) OR
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
            NEW.unit_price,
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

-- End of 016_create_brands_categories.sql


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

-- End of 017_analytics_dimensions.sql


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

-- End of 018_analytics_fact_tables.sql


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

-- End of 019_rls_helper_functions.sql


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

-- End of 020_enable_rls_policies.sql


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

-- End of 021_add_tenant_id_to_sale_items.sql


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

-- End of 022_seed_data.sql


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

-- End of 023_chat_enhancements.sql


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

-- End of 024_ecommerce_enhancements.sql


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

-- End of 20260125_add_missing_rls_policies.sql


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

-- End of 20260125001_create_missing_tables.sql


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

-- End of 20260222194504_healthcare_consultation.sql


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
    
    -- Healthcare & Laboratory expansions
    p.unit_of_measure,
    p.product_type,
    p.generic_name,
    p.strength,
    p.dosage_form,
    p.manufacturer,
    p.test_name,
    p.sample_type,

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
    p.updated_at,
    
    -- Healthcare & Laboratory expansions
    p.unit_of_measure,
    p.product_type,
    p.generic_name,
    p.strength,
    p.dosage_form,
    p.manufacturer,
    p.test_name,
    p.sample_type
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
    p.updated_at,
    
    -- Essential group by fields
    p.unit_of_measure,
    p.product_type,
    p.generic_name,
    p.strength,
    p.dosage_form,
    p.manufacturer,
    p.test_name,
    p.sample_type;

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

-- End of 20260223_tenant_scoped_products.sql


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

-- End of 20260227_add_country_settings_to_tenants.sql


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

-- End of 20260228_add_reserved_quantity_to_branch_inventory.sql


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

-- End of 20260228_ALL_MIGRATIONS_COMBINED.sql


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

-- End of 20260228_create_analytics_rpc_functions.sql


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

-- End of 20260228_create_customer_tenants_junction_FIXED.sql


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

-- End of 20260228_create_delivery_types.sql


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

-- End of 20260228_create_loyalty_config.sql


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

-- End of 20260228_create_storefront_config.sql


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

-- End of 20260228_fix_user_registration_rls.sql


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

-- End of 20260228_generate_sample_data.sql


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

-- End of 20260301_fix_user_registration_rls_v2.sql


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

-- End of 20260310_real_time_inventory_sync.sql


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

-- End of 20260315_configure_tenant_services.sql


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

-- End of 20260315_tenant_services_routing.sql


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

-- End of 20260316_add_subdomain_to_tenants.sql


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
$$ LANGUAGE plpgsql SECURITY DEFINER;

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
$$ LANGUAGE plpgsql SECURITY DEFINER;

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
$$ LANGUAGE plpgsql SECURITY DEFINER;

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

-- End of 20260317_multi_tenant_patient_identity.sql


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

-- End of 20260318_healthcare_chat_system.sql


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

-- End of 20260319_add_healthcare_provider_subscription_policy.sql


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

-- End of 20260319_create_medic_subscriptions.sql


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

-- End of 20260319_fix_provider_self_read_policy.sql


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

-- End of 20260319_link_healthcare_providers_subscriptions.sql


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

-- End of 20260320_add_healthcare_provider_patients.sql


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

-- End of 20260320_add_marked_up_fees_to_providers.sql


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

-- End of 20260320_add_profile_editing_support.sql


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

-- End of 20260320_add_slot_settings_to_providers.sql


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

-- End of 20260320_add_work_schedule_to_providers.sql


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

-- End of 20260320_create_healthcare_patients_table.sql


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

-- End of 20260320_create_storage_buckets.sql


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

-- End of 20260320_fix_healthcare_provider_patient_rls.sql


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

-- End of 20260320_fix_patients_rls_policy.sql


-- File: 20260323_create_diagnostic_tests_table.sql
-- ============================================================================
-- CREATE DIAGNOSTIC TESTS CATALOG TABLE
-- ============================================================================
-- This table stores a global list of lab tests, imaging, and other 
-- investigations for predictive search when doctors order tests.
-- ============================================================================

CREATE TABLE IF NOT EXISTS diagnostic_tests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Core identification
    name TEXT NOT NULL, -- Full name (e.g., "Complete Blood Count")
    code TEXT,          -- Short code/LOINC (e.g., "CBC")
    category TEXT,      -- Department (e.g., "Hematology", "Radiology")
    
    -- Clinical Context
    specimen_type TEXT,            -- What's collected (e.g., "Blood")
    preparation_instructions TEXT, -- Patient prep (e.g., "Fast for 12 hours")
    description TEXT,              -- What it indicates
    
    -- System fields
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add indexes for fast predictive autocomplete searches
CREATE INDEX IF NOT EXISTS idx_diagnostic_tests_name ON diagnostic_tests USING gin (name gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_diagnostic_tests_code ON diagnostic_tests USING gin (code gin_trgm_ops);

-- ============================================================================
-- TRIGGERS
-- ============================================================================

-- Automatically update the updated_at timestamp
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_diagnostic_tests_updated_at') THEN
        CREATE TRIGGER update_diagnostic_tests_updated_at
            BEFORE UPDATE ON diagnostic_tests
            FOR EACH ROW
            EXECUTE FUNCTION update_updated_at_column();
    END IF;
END $$;

-- ============================================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================================

ALTER TABLE diagnostic_tests ENABLE ROW LEVEL SECURITY;

-- Allow all authenticated users (Doctors/Providers/Patients) to read the catalog
DROP POLICY IF EXISTS "Anyone can view active diagnostic tests" ON diagnostic_tests;
CREATE POLICY "Anyone can view active diagnostic tests"
    ON diagnostic_tests FOR SELECT
    TO authenticated
    USING (is_active = true);

-- Note: INSERT, UPDATE, and DELETE are restricted to Admin/Service Role by default.

-- End of 20260323_create_diagnostic_tests_table.sql


-- File: 20260323_create_drugs_table.sql
-- ============================================================================
-- CREATE DRUGS CATALOG TABLE
-- ============================================================================
-- This table stores a global list of medications to be used in
-- predictive search during prescription creation by doctors.
-- ============================================================================

CREATE TABLE IF NOT EXISTS drugs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Core identification
    name TEXT NOT NULL, -- Primary display name (e.g., "Paracetamol 500mg Tablet")
    generic_name TEXT,  -- Active ingredient (e.g., "Acetaminophen")
    brand_name TEXT,    -- Commercial brand name
    manufacturer TEXT,  -- Producing company
    
    -- Formulation & Dosage
    dosage_form TEXT,   -- Form (e.g., "Tablet", "Syrup", "Injection")
    strength TEXT,      -- Concentration (e.g., "500 mg", "10 mg/ml")
    route_of_administration TEXT,
    dispense_as TEXT, -- How it's dis (e.g., "unit", "pack")
    dispense_quantity INT,
    drug_pic_url TEXT,
    
    -- Medical Information
    description TEXT,
    side_effects TEXT,
    contraindications TEXT,
    
    -- System fields
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add an index on the name for faster predictive autocomplete searches
CREATE INDEX IF NOT EXISTS idx_drugs_name ON drugs USING gin (name gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_drugs_generic_name ON drugs USING gin (generic_name gin_trgm_ops);

-- ============================================================================
-- TRIGGERS
-- ============================================================================

-- Automatically update the updated_at timestamp
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_drugs_updated_at') THEN
        CREATE TRIGGER update_drugs_updated_at
            BEFORE UPDATE ON drugs
            FOR EACH ROW
            EXECUTE FUNCTION update_updated_at_column();
    END IF;
END $$;

-- ============================================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================================

ALTER TABLE drugs ENABLE ROW LEVEL SECURITY;

-- Allow all authenticated users (Doctors/Providers/Patients) to read the drugs list
DROP POLICY IF EXISTS "Anyone can view active drugs" ON drugs;
CREATE POLICY "Anyone can view active drugs"
    ON drugs FOR SELECT
    TO authenticated
    USING (is_active = true);

-- Note: INSERT, UPDATE, and DELETE are intentionally omitted here.
-- Only the Service Role (Supabase Admin) will be able to modify the drug catalog 
-- by default unless explicitly granted.

-- End of 20260323_create_drugs_table.sql


-- File: 20260323_create_prescribed_drugs_table.sql
-- ============================================================================
-- PRESCRIBED DRUGS & PRESCRIPTIONS TABLE UPDATES
-- ============================================================================

-- 1. Modify the existing `prescriptions` table
--    - Drop the old JSONB array for medications
--    - Update the patient_id foreign key constraint to reference the `patients` table instead of `auth.users`

ALTER TABLE prescriptions DROP COLUMN IF EXISTS medications;

-- Dynamically drop the old foreign key constraint if it exists (usually named prescriptions_patient_id_fkey)
ALTER TABLE prescriptions DROP CONSTRAINT IF EXISTS prescriptions_patient_id_fkey;

-- Add the new foreign key referencing the `patients` table
ALTER TABLE prescriptions 
    ADD CONSTRAINT prescriptions_patient_id_fkey 
    FOREIGN KEY (patient_id) REFERENCES patients(id) ON DELETE RESTRICT;

-- ============================================================================
-- 2. CREATE `prescribed_drugs` TABLE
-- ============================================================================
-- This table replaces the old JSONB array, normalizing each drug dispensed 
-- into its own relational row for better tracking and inventory management.

CREATE TABLE IF NOT EXISTS prescribed_drugs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    prescription_id UUID NOT NULL REFERENCES prescriptions(id) ON DELETE CASCADE,
    drug_id UUID REFERENCES drugs(id) ON DELETE SET NULL, -- References the new global drugs catalog
    
    -- Drug Details (Denormalized so the prescription record is immutable even if the catalog changes)
    name TEXT NOT NULL,
    generic_name TEXT,
    
    -- Instructions & Dispensing
    dispense_as TEXT,             -- e.g., "pack", "bottle", "unit"
    dispense_quantity INT,        -- Total amount to give
    dosage TEXT,                  -- e.g., "500mg"
    frequency TEXT,  
    drug_pic_url TEXT,            -- e.g., "Twice daily (BD)"
    duration TEXT,                -- e.g., "5 days"
    special_instructions TEXT,    -- e.g., "Take after meals"
    substitution_allowed BOOLEAN DEFAULT true, -- Allows generic swapping
    
    -- Tracking the status of this specific drug
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'dispensed', 'out_of_stock', 'cancelled')),
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_prescribed_drugs_prescription_id ON prescribed_drugs(prescription_id);
CREATE INDEX IF NOT EXISTS idx_prescribed_drugs_drug_id ON prescribed_drugs(drug_id);

-- ============================================================================
-- TRIGGERS
-- ============================================================================

-- Automatically update the updated_at timestamp
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_prescribed_drugs_updated_at') THEN
        CREATE TRIGGER update_prescribed_drugs_updated_at
            BEFORE UPDATE ON prescribed_drugs
            FOR EACH ROW
            EXECUTE FUNCTION update_updated_at_column();
    END IF;
END $$;

-- ============================================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================================

ALTER TABLE prescribed_drugs ENABLE ROW LEVEL SECURITY;

-- Allow all authenticated users involved to view the prescribed drugs
-- Since this references `prescriptions`, anyone who can see the prescription 
-- should generally be able to see the drugs on it.
DROP POLICY IF EXISTS "Anyone can view prescribed drugs" ON prescribed_drugs;
CREATE POLICY "Anyone can view prescribed drugs"
    ON prescribed_drugs FOR SELECT
    TO authenticated
    USING (true);

-- Doctors can create/insert records
DROP POLICY IF EXISTS "Doctors can insert prescribed drugs" ON prescribed_drugs;
CREATE POLICY "Doctors can insert prescribed drugs"
    ON prescribed_drugs FOR INSERT
    TO authenticated
    WITH CHECK (true);

-- Allow status updates (e.g., pharmacy fulfilling a specific drug)
DROP POLICY IF EXISTS "Authenticated users can update prescribed drugs" ON prescribed_drugs;
CREATE POLICY "Authenticated users can update prescribed drugs"
    ON prescribed_drugs FOR UPDATE
    TO authenticated
    USING (true)
    WITH CHECK (true);

-- End of 20260323_create_prescribed_drugs_table.sql


-- File: 20260323_make_consultation_optional.sql
-- Make consultation_id optional in prescriptions so providers can create 
-- direct prescriptions without an active consultation session.
ALTER TABLE prescriptions ALTER COLUMN consultation_id DROP NOT NULL;

-- End of 20260323_make_consultation_optional.sql


-- File: 20260323_update_prescription_status.sql
-- Drop the constraint that prevents 'draft'
ALTER TABLE prescriptions DROP CONSTRAINT IF EXISTS prescriptions_status_check;

-- Add it back with the 'draft' option
ALTER TABLE prescriptions 
ADD CONSTRAINT prescriptions_status_check 
CHECK (status IN ('draft', 'active', 'expired', 'fulfilled', 'cancelled'));

-- End of 20260323_update_prescription_status.sql


-- File: 20260326_add_prescription_code.sql
-- Add prescription_code to prescriptions table
ALTER TABLE prescriptions ADD COLUMN IF NOT EXISTS prescription_code TEXT;

-- Update the check constraint if we want it to be unique or have a specific format in the future, 
-- but for now just adding the column.

-- End of 20260326_add_prescription_code.sql


-- File: 20260326_fix_prescribed_drugs_rls.sql
-- ============================================================================
-- FIX MISSING DELETE POLICY ON PRESCRIBED DRUGS
-- ============================================================================

-- Without a DELETE policy, the 'sync' logic (delete all then re-insert)
-- in the edit prescription page fails, resulting in duplicated entries.

ALTER TABLE prescribed_drugs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Authenticated users can delete prescribed drugs" ON prescribed_drugs;
CREATE POLICY "Authenticated users can delete prescribed drugs"
    ON prescribed_drugs FOR DELETE
    TO authenticated
    USING (true);

-- End of 20260326_fix_prescribed_drugs_rls.sql


-- File: 20260326_fix_prescriptions_delete_rls.sql
-- ============================================================================
-- FIX MISSING DELETE POLICY ON PRESCRIPTIONS
-- ============================================================================

ALTER TABLE prescriptions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Providers can delete issued prescriptions" ON prescriptions;
CREATE POLICY "Providers can delete issued prescriptions"
    ON prescriptions FOR DELETE
    TO authenticated
    USING (provider_id IN (SELECT id FROM healthcare_providers WHERE user_id = auth.uid()));

-- End of 20260326_fix_prescriptions_delete_rls.sql


-- File: 20260327_create_lab_requests_table.sql
-- ============================================================
-- CREATE LAB REQUESTS TABLES
-- ============================================================

-- 1. Create lab_requests table
CREATE TABLE IF NOT EXISTS lab_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Link to healthcare provider and patient
    healthcare_provider_id UUID NOT NULL REFERENCES healthcare_providers(id) ON DELETE CASCADE,
    patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    
    -- Clinical Context
    clinical_notes TEXT,
    diagnosis TEXT,
    priority TEXT DEFAULT 'normal' CHECK (priority IN ('normal', 'urgent', 'emergency')),
    
    -- Status
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'sample_collected', 'in_progress', 'completed', 'cancelled')),
    
    -- Progress tracking
    is_paid BOOLEAN DEFAULT false,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Create lab_request_items table
CREATE TABLE IF NOT EXISTS lab_request_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    lab_request_id UUID NOT NULL REFERENCES lab_requests(id) ON DELETE CASCADE,
    diagnostic_test_id UUID NOT NULL REFERENCES diagnostic_tests(id) ON DELETE RESTRICT,
    
    -- Item status
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'collected', 'processing', 'completed', 'failed')),
    
    -- Results
    result_text TEXT,
    result_value TEXT,
    result_unit TEXT,
    reference_range TEXT,
    result_file_url TEXT,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Add indexes
CREATE INDEX idx_lab_requests_provider ON lab_requests(healthcare_provider_id);
CREATE INDEX idx_lab_requests_patient ON lab_requests(patient_id);
CREATE INDEX idx_lab_requests_status ON lab_requests(status);
CREATE INDEX idx_lab_request_items_request ON lab_request_items(lab_request_id);
CREATE INDEX idx_lab_request_items_test ON lab_request_items(diagnostic_test_id);

-- 4. Enable RLS
ALTER TABLE lab_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE lab_request_items ENABLE ROW LEVEL SECURITY;

-- 5. RLS Policies
-- Providers can view their own lab requests
CREATE POLICY "Providers can view their lab requests"
ON lab_requests FOR SELECT
USING (
    healthcare_provider_id IN (
        SELECT id FROM healthcare_providers WHERE user_id = auth.uid()
    )
);

-- Providers can insert lab requests
CREATE POLICY "Providers can insert lab requests"
ON lab_requests FOR INSERT
WITH CHECK (
    healthcare_provider_id IN (
        SELECT id FROM healthcare_providers WHERE user_id = auth.uid()
    )
);

-- Similar for items
CREATE POLICY "Providers can view lab request items"
ON lab_request_items FOR SELECT
USING (
    lab_request_id IN (
        SELECT id FROM lab_requests WHERE healthcare_provider_id IN (
            SELECT id FROM healthcare_providers WHERE user_id = auth.uid()
        )
    )
);

CREATE POLICY "Providers can insert lab request items"
ON lab_request_items FOR INSERT
WITH CHECK (
    lab_request_id IN (
        SELECT id FROM lab_requests WHERE healthcare_provider_id IN (
            SELECT id FROM healthcare_providers WHERE user_id = auth.uid()
        )
    )
);

-- End of 20260327_create_lab_requests_table.sql


-- File: 20260327_fix_onboarding_rls.sql
-- ============================================================
-- FIX RLS FOR ONBOARDING (V3)
-- ============================================================
-- Allow new authenticated users to create and see their tenant, branch, and subscription

-- 1. Tenants: Allow INSERT and SELECT by email
ALTER TABLE tenants ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Authenticated users can create tenant" ON tenants;
CREATE POLICY "Authenticated users can create tenant"
    ON tenants FOR INSERT
    TO authenticated
    WITH CHECK (true);

DROP POLICY IF EXISTS "Users can select their own tenant by email" ON tenants;
CREATE POLICY "Users can select their own tenant by email"
    ON tenants FOR SELECT
    TO authenticated
    USING (email = auth.jwt() ->> 'email');

-- 2. Branches: Allow INSERT and SELECT for the tenant they are creating
ALTER TABLE branches ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Authenticated users can create branch" ON branches;
CREATE POLICY "Authenticated users can create branch"
    ON branches FOR INSERT
    TO authenticated
    WITH CHECK (true);

DROP POLICY IF EXISTS "Users can view own branch" ON branches;
CREATE POLICY "Users can view own branch"
    ON branches FOR SELECT
    TO authenticated
    USING (
        tenant_id IN (
            SELECT id FROM tenants WHERE email = auth.jwt() ->> 'email'
        )
    );

-- 3. Subscriptions: Enable RLS and allow insert/select
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Authenticated users can create subscription" ON subscriptions;
CREATE POLICY "Authenticated users can create subscription"
    ON subscriptions FOR INSERT
    TO authenticated
    WITH CHECK (true);

DROP POLICY IF EXISTS "Users can view own subscription" ON subscriptions;
CREATE POLICY "Users can view own subscription"
    ON subscriptions FOR SELECT
    TO authenticated
    USING (
        tenant_id IN (
            SELECT id FROM tenants WHERE email = auth.jwt() ->> 'email'
        )
    );

-- 4. Users: Allow a "SELECT" and "INSERT" for the user themselves
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can view own profile" ON users;
CREATE POLICY "Users can view own profile"
    ON users FOR SELECT
    USING (id = auth.uid());

DROP POLICY IF EXISTS "Users can create own profile" ON users;
CREATE POLICY "Users can create own profile"
    ON users FOR INSERT
    WITH CHECK (id = auth.uid());

-- End of 20260327_fix_onboarding_rls.sql


-- File: 20260328_add_diagnostic_business_type.sql
-- ============================================================
-- ADD NEW BUSINESS TYPES
-- ============================================================

-- Add 'diagnostic_centre' and 'pharmacy_supermarket' to the business_type enum
-- Since Postgres doesn't allow dropping enum values easily, we'll just add the new ones

ALTER TYPE business_type ADD VALUE IF NOT EXISTS 'diagnostic_centre';
ALTER TYPE business_type ADD VALUE IF NOT EXISTS 'pharmacy_supermarket';

-- End of 20260328_add_diagnostic_business_type.sql


-- File: 20260328_add_invitation_token_to_users.sql
-- Add invitation_token and invitation fields to users table
ALTER TABLE users
  ADD COLUMN IF NOT EXISTS invitation_token UUID DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS invitation_expires_at TIMESTAMPTZ DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS invitation_accepted_at TIMESTAMPTZ DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS invited_by UUID REFERENCES users(id) ON DELETE SET NULL;

-- Index for fast token lookups
CREATE INDEX IF NOT EXISTS idx_users_invitation_token ON users(invitation_token) WHERE invitation_token IS NOT NULL;

-- End of 20260328_add_invitation_token_to_users.sql


-- File: 20260328_add_onboarding_done_to_users.sql
-- ============================================================
-- ADD ONBOARDING_DONE FIELD
-- ============================================================

ALTER TABLE users ADD COLUMN IF NOT EXISTS onboarding_done BOOLEAN DEFAULT FALSE;

-- Update existing users with a tenant to be onboarding_done = true
UPDATE users SET onboarding_done = TRUE WHERE tenant_id IS NOT NULL;

-- End of 20260328_add_onboarding_done_to_users.sql


-- File: 20260328_fix_user_onboarding.sql
-- ============================================================
-- FIX RLS FOR ONBOARDING UPSERT
-- ============================================================

-- Allow UPDATE on own profile to support UPSERT during onboarding
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can update own profile" ON users;
CREATE POLICY "Users can update own profile"
    ON users FOR UPDATE
    USING (id = auth.uid())
    WITH CHECK (id = auth.uid());

-- End of 20260328_fix_user_onboarding.sql


-- File: 20260328112500_add_user_advanced_fields.sql
-- Add new profile and permission fields to users table
ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS passcode_hash text null,
  ADD COLUMN IF NOT EXISTS profile_picture_url text null,
  ADD COLUMN IF NOT EXISTS gender character varying(10) null,
  ADD COLUMN IF NOT EXISTS onboarding_completed_at timestamp with time zone null,
  ADD COLUMN IF NOT EXISTS onboarding_done boolean null default false,
  -- Permission flags
  ADD COLUMN IF NOT EXISTS "canManagePOS" boolean not null default false,
  ADD COLUMN IF NOT EXISTS "canManageProducts" boolean not null default false,
  ADD COLUMN IF NOT EXISTS "canManageCustomers" boolean not null default false,
  ADD COLUMN IF NOT EXISTS "canManageOrders" boolean not null default false,
  ADD COLUMN IF NOT EXISTS "canViewMessages" boolean not null default false,
  ADD COLUMN IF NOT EXISTS "canViewAnalytics" boolean not null default false,
  ADD COLUMN IF NOT EXISTS "canManageStaff" boolean not null default false,
  ADD COLUMN IF NOT EXISTS "canManageInventory" boolean not null default false,
  ADD COLUMN IF NOT EXISTS "canManageTransfer" boolean not null default false,
  ADD COLUMN IF NOT EXISTS "canManageBranches" boolean not null default false,
  ADD COLUMN IF NOT EXISTS "canManageRoles" boolean not null default false,
  ADD COLUMN IF NOT EXISTS "canManageScrap" boolean not null default false,
  ADD COLUMN IF NOT EXISTS "canTransferProduct" boolean not null default false,
  ADD COLUMN IF NOT EXISTS "canReturnProducts" boolean not null default false;

-- Add check constraint for gender
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_gender_values' AND conrelid = 'public.users'::regclass
    ) THEN
        ALTER TABLE public.users
            ADD CONSTRAINT chk_gender_values CHECK (
                gender IS NULL OR gender IN ('male', 'female', 'other')
            );
    END IF;
END $$;

-- Indexes for new fields
CREATE INDEX IF NOT EXISTS idx_users_passcode_hash ON public.users USING btree (passcode_hash) WHERE (passcode_hash IS NOT NULL);
CREATE INDEX IF NOT EXISTS idx_users_onboarding_completed ON public.users USING btree (onboarding_completed_at) WHERE (onboarding_completed_at IS NULL);

-- End of 20260328112500_add_user_advanced_fields.sql


-- File: 20260328114500_fix_staff_invitations_rls.sql
-- Enable RLS on staff_invitations
ALTER TABLE public.staff_invitations ENABLE ROW LEVEL SECURITY;

-- Allow anyone with the token to read the invitation (required for the pre-login UI in Incognito)
CREATE POLICY "Allow public read of pending invitations by token"
ON public.staff_invitations
FOR SELECT
TO public
USING (status = 'pending');

-- Allow securely authenticated users to update their own invitation status to 'accepted'
CREATE POLICY "Allow authenticated user to accept invitation"
ON public.staff_invitations
FOR UPDATE
TO authenticated
USING (email = (auth.jwt() ->> 'email') AND status = 'pending')
WITH CHECK (status = 'accepted');

-- Allow admins (who invited) to read and manage all their invitations
CREATE POLICY "Allow tenant admins to view invitations"
ON public.staff_invitations
FOR ALL
TO authenticated
USING (tenant_id IN (
    SELECT tenant_id FROM public.users WHERE id = auth.uid()
));

-- End of 20260328114500_fix_staff_invitations_rls.sql


-- File: 20260328123500_add_location_fields_to_branches.sql
ALTER TABLE public.branches
ADD COLUMN IF NOT EXISTS city VARCHAR(255),
ADD COLUMN IF NOT EXISTS state VARCHAR(255),
ADD COLUMN IF NOT EXISTS country VARCHAR(255);

-- End of 20260328123500_add_location_fields_to_branches.sql


-- File: 20260329141500_healthcare_product_fields.sql
-- Expand Products table with Healthcare fields (Medications and Lab Tests)
-- Date: 2026-03-29
-- Source: User provided schema update

-- Add columns to products table if they don't exist
ALTER TABLE products 
  ADD COLUMN IF NOT EXISTS unit_of_measure VARCHAR(20) DEFAULT 'piece',
  ADD COLUMN IF NOT EXISTS product_type TEXT,
  ADD COLUMN IF NOT EXISTS generic_name TEXT,
  ADD COLUMN IF NOT EXISTS strength TEXT,
  ADD COLUMN IF NOT EXISTS dosage_form TEXT,
  ADD COLUMN IF NOT EXISTS manufacturer TEXT,
  ADD COLUMN IF NOT EXISTS test_name TEXT,
  ADD COLUMN IF NOT EXISTS sample_type TEXT;

-- Comments for the new fields
COMMENT ON COLUMN products.unit_of_measure IS 'Unit of measurement (e.g., piece, box, ml)';
COMMENT ON COLUMN products.product_type IS 'Type categorization (e.g., medication, service, test)';
COMMENT ON COLUMN products.generic_name IS 'Active pharmaceutical ingredient name';
COMMENT ON COLUMN products.strength IS 'Concentration or potency (e.g., 500mg, 10mg/ml)';
COMMENT ON COLUMN products.dosage_form IS 'Physical form (e.g., tablet, syrup, injection)';
COMMENT ON COLUMN products.manufacturer IS 'Producing company or laboratory';
COMMENT ON COLUMN products.test_name IS 'Full descriptive name of laboratory test';
COMMENT ON COLUMN products.sample_type IS 'Specimen requirement for tests (e.g., blood, urine)';

-- Re-syncing triggers and indexes as specified in the provided schema
-- Note: Some of these may already exist, so we use IF NOT EXISTS or DROP/CREATE

-- Indexes as specified in prompt
CREATE INDEX IF NOT EXISTS idx_products_brand ON public.products(brand_id) WHERE (brand_id is not null);
CREATE INDEX IF NOT EXISTS idx_products_category ON public.products(category_id) WHERE (category_id is not null);

-- Ensure sync triggers are active on products (standard project triggers)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'increment_sync_version' AND tgrelid = 'public.products'::regclass) THEN
        CREATE TRIGGER increment_sync_version BEFORE UPDATE ON products
            FOR EACH ROW EXECUTE FUNCTION increment_sync_version();
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'set_updated_at' AND tgrelid = 'public.products'::regclass) THEN
        CREATE TRIGGER set_updated_at BEFORE UPDATE ON products
            FOR EACH ROW EXECUTE FUNCTION update_updated_at();
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_track_product_price_change' AND tgrelid = 'public.products'::regclass) THEN
        CREATE TRIGGER trg_track_product_price_change AFTER UPDATE ON products
            FOR EACH ROW EXECUTE FUNCTION track_product_price_change();
    END IF;
END $$;

-- End of 20260329141500_healthcare_product_fields.sql


-- File: 20260329150000_allow_staff_manage_categories.sql
-- Update Categories RLS to allow staff with POS management privileges to create categories
-- Date: 2026-03-29

DROP POLICY IF EXISTS "Managers can insert categories" ON categories;
CREATE POLICY "Managers and Staff can insert categories"
    ON categories FOR INSERT
    WITH CHECK (
        tenant_id IN (
            SELECT tenant_id FROM users
            WHERE id = auth.uid()
            AND (role IN ('tenant_admin', 'branch_manager') OR canManagePOS = true)
        )
    );

DROP POLICY IF EXISTS "Managers can update categories" ON categories;
CREATE POLICY "Managers and Staff can update categories"
    ON categories FOR UPDATE
    USING (
        tenant_id IN (
            SELECT tenant_id FROM users
            WHERE id = auth.uid()
            AND (role IN ('tenant_admin', 'branch_manager') OR canManagePOS = true)
        )
    );

-- End of 20260329150000_allow_staff_manage_categories.sql


-- File: 20260329150500_fix_category_path_trigger.sql
-- Fix Category Path Trigger Function
-- Removed references to non-existent parent_category_id and level columns
-- Date: 2026-03-29

CREATE OR REPLACE FUNCTION update_category_path()
RETURNS TRIGGER AS $$
BEGIN
    -- Generate a clean slug-based path from the name
    NEW.path := '/' || LOWER(REGEXP_REPLACE(NEW.name, '[^a-zA-Z0-9]+', '-', 'g')) || '/';
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Re-apply trigger to ensure it uses the latest function logic
DROP TRIGGER IF EXISTS trg_update_category_path ON categories;
CREATE TRIGGER trg_update_category_path
    BEFORE INSERT OR UPDATE ON categories
    FOR EACH ROW
    EXECUTE FUNCTION update_category_path();

-- End of 20260329150500_fix_category_path_trigger.sql


-- File: 20260329151500_delete_category_path_trigger.sql
-- Delete Category Path Trigger and Function
-- Transitioning to manual path generation in the application layer
-- Date: 2026-03-29

DROP TRIGGER IF EXISTS trg_update_category_path ON categories;
DROP FUNCTION IF EXISTS update_category_path();

-- End of 20260329151500_delete_category_path_trigger.sql


-- File: 20260329152000_restore_category_path_trigger.sql
-- Restore Category Path Trigger and Function
-- Re-introducing automated hierarchical/slugged path generation in the database
-- Date: 2026-03-29

CREATE OR REPLACE FUNCTION update_category_path()
RETURNS TRIGGER AS $$
BEGIN
    NEW.path := '/' || LOWER(REGEXP_REPLACE(NEW.name, '[^a-zA-Z0-9]+', '-', 'g')) || '/';
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_update_category_path ON categories;
CREATE TRIGGER trg_update_category_path
    BEFORE INSERT OR UPDATE ON categories
    FOR EACH ROW
    EXECUTE FUNCTION update_category_path();

-- End of 20260329152000_restore_category_path_trigger.sql


-- File: 20260329160000_final_category_fix_aggressive.sql
-- Aggressive cleanup and restoration of Category Path Trigger
-- This script ensures no old versions of the trigger or function remain.
-- Date: 2026-03-29

-- 1. Correct the table schema aggressively (ensure no old columns remain)
DO $$ 
BEGIN 
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'categories' AND column_name = 'code') THEN
        ALTER TABLE public.categories DROP COLUMN code;
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'categories' AND column_name = 'description') THEN
        ALTER TABLE public.categories DROP COLUMN description;
    END IF;
END $$;

-- 2. Drop the trigger from the table aggressively
DROP TRIGGER IF EXISTS trg_update_category_path ON public.categories CASCADE;

-- 2. Drop the function with a cascade to remove any dependent objects
DROP FUNCTION IF EXISTS public.update_category_path() CASCADE;

-- 3. Redefine the function cleanly with the NEW flat schema logic
-- Note: NEW.name and NEW.path must exist for this to work.
CREATE OR REPLACE FUNCTION public.update_category_path()
RETURNS TRIGGER AS $$
BEGIN
    -- Log for debugging (found in Supabase logs)
    -- RAISE NOTICE 'Generating path for category: %', NEW.name;
    
    NEW.path := '/' || LOWER(REGEXP_REPLACE(NEW.name, '[^a-zA-Z0-9]+', '-', 'g')) || '/';
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 4. Re-create the trigger on the table
CREATE TRIGGER trg_update_category_path
    BEFORE INSERT OR UPDATE ON public.categories
    FOR EACH ROW
    EXECUTE FUNCTION public.update_category_path();

-- 5. Ensure RLS is still open as requested
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public can view categories" ON public.categories;
CREATE POLICY "Public can view categories" ON public.categories FOR SELECT USING (true);

DROP POLICY IF EXISTS "Authenticated users can create categories" ON public.categories;
CREATE POLICY "Authenticated users can create categories" ON public.categories FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "Authenticated users can update categories" ON public.categories;
CREATE POLICY "Authenticated users can update categories" ON public.categories FOR UPDATE USING (auth.uid() IS NOT NULL);

-- End of 20260329160000_final_category_fix_aggressive.sql


-- File: 20260329161000_drop_obsolete_stock_trigger.sql
-- Drop the obsolete trigger that tries to sync stock to the 'products' table
DROP TRIGGER IF EXISTS auto_sync_product_stock ON branch_inventory;

-- Drop the underlying obsolete function since the 'products' table no longer tracks stock
DROP FUNCTION IF EXISTS trigger_sync_product_stock();

-- End of 20260329161000_drop_obsolete_stock_trigger.sql


-- File: 20260329161500_drop_obsolete_price_trigger.sql
-- Since pricing has migrated off the global 'products' table and into 'branch_inventory',
-- the legacy trigger tracking price changes directly on the 'products' table crashes
-- whenever any product is updated because the 'selling_price'/'unit_price' fields are gone.

-- Drop the obsolete trigger from the 'products' table
DROP TRIGGER IF EXISTS trg_track_product_price_change ON products;

-- Optionally, drop the obsolete function that caused the crash
DROP FUNCTION IF EXISTS track_product_price_change();

-- End of 20260329161500_drop_obsolete_price_trigger.sql


-- File: 20260330000000_create_product_images_bucket.sql
-- ============================================================================
-- CREATE STORAGE BUCKET FOR PRODUCT IMAGES
-- ============================================================================

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'product-images',
    'product-images',
    true, -- Publicly accessible
    5242880, -- 5MB limit
    ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/jpg']
)
ON CONFLICT (id) DO NOTHING;

-- STORAGE RLS POLICIES

-- Anyone can view product images
DROP POLICY IF EXISTS "Anyone can view product images" ON storage.objects;
CREATE POLICY "Anyone can view product images"
    ON storage.objects FOR SELECT
    TO public
    USING (bucket_id = 'product-images');

-- Authenticated users can upload product images
DROP POLICY IF EXISTS "Authenticated users can upload product images" ON storage.objects;
CREATE POLICY "Authenticated users can upload product images"
    ON storage.objects FOR INSERT
    TO authenticated
    WITH CHECK (bucket_id = 'product-images');

-- Authenticated users can update their own uploads or any (simplified for products)
DROP POLICY IF EXISTS "Authenticated users can update product images" ON storage.objects;
CREATE POLICY "Authenticated users can update product images"
    ON storage.objects FOR UPDATE
    TO authenticated
    USING (bucket_id = 'product-images');

-- Authenticated users can delete product images
DROP POLICY IF EXISTS "Authenticated users can delete product images" ON storage.objects;
CREATE POLICY "Authenticated users can delete product images"
    ON storage.objects FOR DELETE
    TO authenticated
    USING (bucket_id = 'product-images');

-- End of 20260330000000_create_product_images_bucket.sql


-- File: 20260330010000_add_batch_support.sql
-- ============================================================
-- Migration: Batch Number and Multi-Inventory Lot Support
-- ============================================================
-- Description: Adds batch_no support and allows multiple inventory 
--              records per product per branch (to track lots).
-- ============================================================

-- 1. Add batch_no column if it doesn't exist
ALTER TABLE branch_inventory
ADD COLUMN IF NOT EXISTS batch_no VARCHAR(100);

-- 2. Refactor unique constraints to allow lot-based tracking
-- Drop the legacy one-record-per-product constraint
ALTER TABLE branch_inventory 
DROP CONSTRAINT IF EXISTS branch_inventory_branch_id_product_id_key;

-- Drop any previous attempts at this constraint
ALTER TABLE branch_inventory
DROP CONSTRAINT IF EXISTS branch_inventory_branch_product_batch_unique;

-- Add new composite unique constraint including batch_no
-- Note: PostgreSQL allows multiple NULLs in UNIQUE constraints, 
-- but we'll use empty string as default to ensure predictability if needed.
ALTER TABLE branch_inventory
ADD CONSTRAINT branch_inventory_branch_product_batch_unique 
UNIQUE (branch_id, product_id, batch_no);

COMMENT ON COLUMN branch_inventory.batch_no IS 'Batch or Lot identifying number for this specific stock entry';

-- End of 20260330010000_add_batch_support.sql


-- File: 20260330020000_add_suppliers_table.sql
-- ============================================================
-- Migration: Add Suppliers Table and Inventory Integration
-- ============================================================
-- Description: Creates a suppliers management table and links 
--              it to branch inventory lots for procurement tracking.
-- ============================================================

-- 1. Create Suppliers table
CREATE TABLE IF NOT EXISTS suppliers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    contact_person VARCHAR(255),
    email VARCHAR(255),
    phone VARCHAR(50),
    address TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. Add supplier_id to branch_inventory
ALTER TABLE branch_inventory
ADD COLUMN IF NOT EXISTS supplier_id UUID REFERENCES suppliers(id) ON DELETE SET NULL;

-- 3. Enable RLS for suppliers
ALTER TABLE suppliers ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view suppliers in their tenant" ON suppliers;
CREATE POLICY "Users can view suppliers in their tenant"
    ON suppliers FOR SELECT
    USING (tenant_id IN (SELECT tenant_id FROM users WHERE id = auth.uid()));

DROP POLICY IF EXISTS "Admins can manage suppliers" ON suppliers;
CREATE POLICY "Admins can manage suppliers"
    ON suppliers FOR ALL
    USING (
        tenant_id IN (
            SELECT tenant_id FROM users
            WHERE id = auth.uid()
            AND role IN ('tenant_admin', 'branch_manager')
        )
    );

-- 4. Sample Data (Optional first entry)
-- INSERT INTO suppliers (tenant_id, name) VALUES ('your-tenant-uuid', 'General Supplier');

COMMENT ON TABLE suppliers IS 'Table for managing product suppliers/vendors.';
COMMENT ON COLUMN branch_inventory.supplier_id IS 'Reference to the supplier from whom this batch was purchased.';

-- End of 20260330020000_add_suppliers_table.sql


-- File: 20260330130000_stock_balance_tracking.sql
-- 1. Update branch_inventory schema (Safely add columns if they don't exist)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'branch_inventory' AND column_name = 'purchase_invoice') THEN
        ALTER TABLE branch_inventory ADD COLUMN purchase_invoice TEXT;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'branch_inventory' AND column_name = 'purchase_code') THEN
        ALTER TABLE branch_inventory ADD COLUMN purchase_code TEXT;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'branch_inventory' AND column_name = 'added_by') THEN
        ALTER TABLE branch_inventory ADD COLUMN added_by TEXT;
    END IF;
END $$;

-- 2. Create product_stock_balance table to track aggregated stock per product/branch
CREATE TABLE IF NOT EXISTS product_stock_balance (
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

-- 3. Trigger function to keep product_stock_balance in sync with branch_inventory batches
-- SECURITY DEFINER allows the trigger to update the rollup table even if the user lacks direct write permissions.
CREATE OR REPLACE FUNCTION sync_product_stock_balance()
RETURNS TRIGGER AS $$
DECLARE
    v_tenant_id UUID;
BEGIN
    -- Get tenant_id from the affected row
    IF (TG_OP = 'DELETE') THEN
        v_tenant_id := OLD.tenant_id;
    ELSE
        v_tenant_id := NEW.tenant_id;
    END IF;

    -- Update or Insert the aggregated balance
    INSERT INTO product_stock_balance (
        tenant_id, 
        branch_id, 
        product_id, 
        stock_balance, 
        reserved_balance,
        available_balance,
        last_updated
    )
    SELECT 
        v_tenant_id,
        COALESCE(NEW.branch_id, OLD.branch_id),
        COALESCE(NEW.product_id, OLD.product_id),
        COALESCE(SUM(stock_quantity), 0),
        COALESCE(SUM(reserved_quantity), 0),
        COALESCE(SUM(stock_quantity - reserved_quantity), 0),
        NOW()
    FROM branch_inventory
    WHERE branch_id = COALESCE(NEW.branch_id, OLD.branch_id)
      AND product_id = COALESCE(NEW.product_id, OLD.product_id)
      AND is_active = true
    ON CONFLICT (branch_id, product_id) 
    DO UPDATE SET 
        stock_balance = EXCLUDED.stock_balance,
        reserved_balance = EXCLUDED.reserved_balance,
        available_balance = EXCLUDED.available_balance,
        last_updated = EXCLUDED.last_updated;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 4. Apply triggers to branch_inventory (Remove then re-add for safety)
DROP TRIGGER IF EXISTS trg_sync_stock_balance ON branch_inventory;
CREATE TRIGGER trg_sync_stock_balance
AFTER INSERT OR UPDATE OR DELETE ON branch_inventory
FOR EACH ROW EXECUTE FUNCTION sync_product_stock_balance();

-- 5. Helper for purchase order sequences
CREATE TABLE IF NOT EXISTS purchase_sequences (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE,
    branch_id UUID REFERENCES branches(id) ON DELETE CASCADE,
    last_serial INTEGER DEFAULT 0,
    UNIQUE(tenant_id, branch_id)
);

-- Enable RLS for the new tables
ALTER TABLE product_stock_balance ENABLE ROW LEVEL SECURITY;
ALTER TABLE purchase_sequences ENABLE ROW LEVEL SECURITY;

-- Product Stock Balance Policies  (Grant ALL to branch members via trigger or direct if needed)
DROP POLICY IF EXISTS "Users can manage stock balance for their branch" ON product_stock_balance;
CREATE POLICY "Users can manage stock balance for their branch" 
ON product_stock_balance FOR ALL
USING (branch_id IN (SELECT branch_id FROM users WHERE id = auth.uid()))
WITH CHECK (branch_id IN (SELECT branch_id FROM users WHERE id = auth.uid()));

-- Purchase Sequences Policies
DROP POLICY IF EXISTS "Users can manage purchase sequences for their branch" ON purchase_sequences;
CREATE POLICY "Users can manage purchase sequences for their branch" 
ON purchase_sequences FOR ALL
USING (branch_id IN (SELECT branch_id FROM users WHERE id = auth.uid()))
WITH CHECK (branch_id IN (SELECT branch_id FROM users WHERE id = auth.uid()));

-- End of 20260330130000_stock_balance_tracking.sql


-- File: 20260331000000_add_cash_received_to_sales.sql
-- Migration: Add missing columns to sales table for POS checkout
-- Created: 2026-03-31

ALTER TABLE public.sales 
ADD COLUMN IF NOT EXISTS cash_received DECIMAL(12,2),
ADD COLUMN IF NOT EXISTS change_given DECIMAL(12,2),
ADD COLUMN IF NOT EXISTS customer_name VARCHAR(255);

-- Also ensure sale_items has consistent columns if any were missed
-- total_price was used in code but subtotal is in schema.
-- We fixed the code to use subtotal, so no change needed here 
-- unless we want to rename it. Keeping subtotal as per schema.

-- End of 20260331000000_add_cash_received_to_sales.sql


-- File: 20260331010000_fix_loyalty_trigger_status.sql
-- Migration: Fix customer loyalty trigger
-- Description: Updates the 'update_customer_loyalty' trigger function to reference 'sale_status' instead of 'status'

CREATE OR REPLACE FUNCTION update_customer_loyalty()
RETURNS TRIGGER AS $$
DECLARE
    points_earned INTEGER;
BEGIN
    -- Fixed: Using 'sale_status' instead of 'status' according to the sales schema definition
    IF NEW.customer_id IS NOT NULL AND NEW.sale_status = 'completed' THEN
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

-- End of 20260331010000_fix_loyalty_trigger_status.sql


-- File: 20260401_allow_public_tenant_view.sql
-- Allow public/anonymous users to view basic tenant information for the storefront
-- This is necessary for slug-based routing to resolve the tenant without authentication
DROP POLICY IF EXISTS "Public can view basic tenant info" ON public.tenants;
CREATE POLICY "Public can view basic tenant info"
  ON public.tenants
  FOR SELECT
  TO public
  USING (deleted_at IS NULL);

-- Allow public/anonymous users to view branch metadata for the storefront
-- Necessary for branch-based product filtering at the storefront
DROP POLICY IF EXISTS "Public can view branches for storefront" ON public.branches;
CREATE POLICY "Public can view branches for storefront"
  ON public.branches
  FOR SELECT
  TO public
  USING (deleted_at IS NULL);

-- Allow public/anonymous users to view products catalog for the storefront
DROP POLICY IF EXISTS "Public can view products for storefront" ON public.products;
CREATE POLICY "Public can view products for storefront"
  ON public.products
  FOR SELECT
  TO public
  USING (is_active IS NOT FALSE AND _sync_is_deleted IS NOT TRUE);

-- Allow public/anonymous users to view branch inventory for the storefront
-- This fulfills the requirement to fetch products via branch_inventory
DROP POLICY IF EXISTS "Public can view inventory for storefront" ON public.branch_inventory;
CREATE POLICY "Public can view inventory for storefront"
  ON public.branch_inventory
  FOR SELECT
  TO public
  USING (is_active IS NOT FALSE AND _sync_is_deleted IS NOT TRUE);

-- Allow authenticated customers to update stock quantities in branch inventory
DROP POLICY IF EXISTS "Customers can update branch inventory" ON public.branch_inventory;
CREATE POLICY "Customers can update branch inventory"
  ON public.branch_inventory
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.customers
      WHERE customers.id = auth.uid()
      AND customers.tenant_id = branch_inventory.tenant_id
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.customers
      WHERE customers.id = auth.uid()
      AND customers.tenant_id = branch_inventory.tenant_id
    )
  );

-- Allow public/anonymous users to view verified healthcare professionals (Relaxed for initial setup)
DROP POLICY IF EXISTS "Public can view healthcare providers" ON public.healthcare_providers;
CREATE POLICY "Public can view healthcare providers"
  ON public.healthcare_providers
  FOR SELECT
  TO public
  USING (is_active IS NOT FALSE);

-- End of 20260401_allow_public_tenant_view.sql


-- File: 20260401140000_add_business_type_to_categories.sql
-- Add 'diagnostics' to business_type enum
ALTER TYPE business_type ADD VALUE IF NOT EXISTS 'diagnostics';

-- Add business_type column to categories
ALTER TABLE categories ADD COLUMN IF NOT EXISTS business_type business_type;

COMMENT ON COLUMN categories.business_type IS 'The type of business this category belongs to (e.g., pharmacy, supermarket, diagnostics).';

-- End of 20260401140000_add_business_type_to_categories.sql


-- File: 20260404_checkout_rpc.sql
-- ============================================
-- Migration: E-Commerce Storefront RPCs for Checkout and Cancellation
-- Description: Adds batch allocation tracking, checkout logic, and cancellation logic
-- ============================================

-- 1. Add batch_allocations to order_items to support accurately releasing reservations
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'order_items' AND column_name = 'batch_allocations'
    ) THEN
        ALTER TABLE order_items ADD COLUMN batch_allocations JSONB DEFAULT '[]'::jsonb;
        COMMENT ON COLUMN order_items.batch_allocations IS 'Array of allocations: {batch_id: "uuid", quantity: number} to track reserved stock for cancellations.';
    END IF;
END $$;

-- 2. Drop existing functions if they exist to prevent signature conflicts
DROP FUNCTION IF EXISTS checkout_storefront_order(UUID, UUID, UUID, order_type, fulfillment_type, DECIMAL, DECIMAL, DECIMAL, DECIMAL, UUID, TEXT, JSONB);
DROP FUNCTION IF EXISTS cancel_storefront_order(UUID);

-- 3. Create checkout_storefront_order RPC
CREATE OR REPLACE FUNCTION checkout_storefront_order(
    p_tenant_id UUID,
    p_branch_id UUID,
    p_customer_id UUID,
    p_order_type order_type,
    p_fulfillment_type fulfillment_type,
    p_subtotal DECIMAL,
    p_delivery_fee DECIMAL,
    p_tax_amount DECIMAL,
    p_total_amount DECIMAL,
    p_delivery_address_id UUID,
    p_special_instructions TEXT,
    p_items JSONB -- Array of { product_id, product_name, quantity, unit_price, subtotal }
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER -- Runs with elevated privileges to securely handle stock
AS $$
DECLARE
    v_order_id UUID;
    v_item RECORD;
    v_batch RECORD;
    v_req_qty INTEGER;
    v_available_qty INTEGER;
    v_allocated_qty INTEGER;
    v_allocations JSONB;
BEGIN
    -- Input validation
    IF p_total_amount != (p_subtotal + p_delivery_fee + p_tax_amount) THEN
        RAISE EXCEPTION 'Total amount does not match subtotal + fees + tax';
    END IF;

    -- Create the order
    INSERT INTO orders (
        tenant_id,
        branch_id,
        order_number,
        customer_id,
        order_type,
        order_status,
        payment_status,
        subtotal,
        delivery_fee,
        tax_amount,
        total_amount,
        fulfillment_type,
        delivery_address_id,
        special_instructions
    ) VALUES (
        p_tenant_id,
        p_branch_id,
        'ORD-' || FLOOR(EXTRACT(EPOCH FROM NOW()))::TEXT || '-' || SUBSTRING(MD5(RANDOM()::TEXT) FROM 1 FOR 4),
        p_customer_id,
        p_order_type,
        'pending'::order_status,
        'unpaid'::payment_status,
        p_subtotal,
        p_delivery_fee,
        p_tax_amount,
        p_total_amount,
        p_fulfillment_type,
        p_delivery_address_id,
        p_special_instructions
    ) RETURNING id INTO v_order_id;

    -- Process each item in the order
    FOR v_item IN SELECT * FROM jsonb_to_recordset(p_items) AS x(
        product_id UUID, product_name TEXT, quantity INTEGER, unit_price DECIMAL, subtotal DECIMAL
    )
    LOOP
        v_req_qty := v_item.quantity;
        v_allocations := '[]'::jsonb;

        -- Perform FIFO Allocation against branch_inventory batches where (stock_quantity - reserved_quantity) > 0
        FOR v_batch IN 
            SELECT id, (stock_quantity - COALESCE(reserved_quantity, 0)) AS available_balance
            FROM branch_inventory
            WHERE branch_id = p_branch_id 
              AND product_id = v_item.product_id 
              AND is_active = true
              AND (stock_quantity - COALESCE(reserved_quantity, 0)) > 0
            ORDER BY expiry_date ASC NULLS LAST, created_at ASC
            FOR UPDATE -- Lock rows to prevent race conditions during concurrent checkouts
        LOOP
            IF v_req_qty <= 0 THEN
                EXIT; -- Allocation complete
            END IF;

            v_available_qty := v_batch.available_balance;
            
            -- Determine how much we can allocate from this batch
            IF v_available_qty >= v_req_qty THEN
                v_allocated_qty := v_req_qty;
            ELSE
                v_allocated_qty := v_available_qty;
            END IF;

            -- Update reserved_quantity for this batch
            UPDATE branch_inventory
            SET reserved_quantity = COALESCE(reserved_quantity, 0) + v_allocated_qty,
                updated_at = NOW()
            WHERE id = v_batch.id;

            -- Record this allocation
            v_allocations := v_allocations || jsonb_build_object(
                'batch_id', v_batch.id,
                'quantity', v_allocated_qty
            );

            v_req_qty := v_req_qty - v_allocated_qty;
        END LOOP;

        -- Check if we successfully fulfilled the requested quantity
        IF v_req_qty > 0 THEN
            RAISE EXCEPTION 'Insufficient stock available for product: % (Missing: %)', v_item.product_name, v_req_qty;
        END IF;

        -- Insert the order_items row with the tracked allocations
        INSERT INTO order_items (
            order_id,
            product_id,
            product_name,
            quantity,
            unit_price,
            subtotal,
            batch_allocations
        ) VALUES (
            v_order_id,
            v_item.product_id,
            v_item.product_name,
            v_item.quantity,
            v_item.unit_price,
            v_item.subtotal,
            v_allocations
        );
    END LOOP;

    RETURN v_order_id;
END;
$$;


-- 4. Create cancel_storefront_order RPC
CREATE OR REPLACE FUNCTION cancel_storefront_order(
    p_order_id UUID
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_order RECORD;
    v_item RECORD;
    v_allocation RECORD;
    v_user_id UUID;
    v_tenant_id UUID;
BEGIN
    v_user_id := auth.uid();
    
    -- Retrieve the order and verify ownership/status
    SELECT * INTO v_order FROM orders WHERE id = p_order_id;
    
    IF v_order.id IS NULL THEN
        RAISE EXCEPTION 'Order not found';
    END IF;

    -- We allow cancellation if it's pending, or by tenants. For simplicity, only check status
    IF v_order.order_status = 'delivered'::order_status THEN
        RAISE EXCEPTION 'Cannot cancel an order that has already been delivered';
    END IF;
    IF v_order.order_status = 'cancelled'::order_status THEN
        RAISE EXCEPTION 'Order is already cancelled';
    END IF;

    -- Update order status
    UPDATE orders 
    SET order_status = 'cancelled'::order_status,
        updated_at = NOW()
    WHERE id = p_order_id;

    -- Loop through order items and un-reserve the allocated batches
    FOR v_item IN SELECT * FROM order_items WHERE order_id = p_order_id
    LOOP
        -- Loop through allocations inside the JSONB array
        FOR v_allocation IN SELECT * FROM jsonb_to_recordset(v_item.batch_allocations) AS x(batch_id UUID, quantity INTEGER)
        LOOP
            -- Decrement reserved_quantity
            UPDATE branch_inventory
            SET reserved_quantity = GREATEST(COALESCE(reserved_quantity, 0) - v_allocation.quantity, 0),
                updated_at = NOW()
            WHERE id = v_allocation.batch_id;
        END LOOP;
    END LOOP;

    RETURN TRUE;
END;
$$;

-- End of 20260404_checkout_rpc.sql


-- File: 20260404222300_healthcare_reviews.sql
-- Migration: Update Healthcare Provider Enhancements
-- Created: 2026-04-04

-- 1. Add missing columns to healthcare_providers table
ALTER TABLE public.healthcare_providers
ADD COLUMN IF NOT EXISTS medic_subscription_id UUID REFERENCES public.medic_subscriptions(id) ON DELETE SET NULL,
ADD COLUMN IF NOT EXISTS work_schedule JSONB DEFAULT '[]'::JSONB,
ADD COLUMN IF NOT EXISTS slot_settings JSONB DEFAULT '{"buffer": 0, "duration": 30, "breakTimes": []}'::JSONB,
ADD COLUMN IF NOT EXISTS marked_up_fees JSONB DEFAULT '{"chat": 0, "audio": 0, "video": 0, "office_visit": 0}'::JSONB,
ADD COLUMN IF NOT EXISTS sub_specialty TEXT,
ADD COLUMN IF NOT EXISTS preferred_languages TEXT[];

-- 2. Create the healthcare_reviews table
CREATE TABLE IF NOT EXISTS public.healthcare_reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    provider_id UUID NOT NULL REFERENCES public.healthcare_providers(id) ON DELETE CASCADE,
    patient_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    consultation_id UUID REFERENCES public.consultations(id) ON DELETE SET NULL,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    comment TEXT,
    is_verified BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    -- Constraints
    CONSTRAINT unique_patient_provider_review UNIQUE (patient_id, provider_id)
);

-- 3. Performance Indexes
CREATE INDEX IF NOT EXISTS idx_reviews_provider_id ON public.healthcare_reviews(provider_id);
CREATE INDEX IF NOT EXISTS idx_reviews_patient_id ON public.healthcare_reviews(patient_id);
CREATE INDEX IF NOT EXISTS idx_reviews_rating ON public.healthcare_reviews(rating);
CREATE INDEX IF NOT EXISTS idx_reviews_created_at ON public.healthcare_reviews(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_providers_medic_subscription_id ON public.healthcare_providers(medic_subscription_id);
CREATE INDEX IF NOT EXISTS idx_providers_work_schedule ON public.healthcare_providers USING GIN (work_schedule);
CREATE INDEX IF NOT EXISTS idx_providers_slot_settings ON public.healthcare_providers USING GIN (slot_settings);
CREATE INDEX IF NOT EXISTS idx_providers_marked_up_fees ON public.healthcare_providers USING GIN (marked_up_fees);
CREATE INDEX IF NOT EXISTS idx_providers_languages ON public.healthcare_providers USING GIN (preferred_languages);

-- 4. Row-Level Security (RLS)
ALTER TABLE public.healthcare_reviews ENABLE ROW LEVEL SECURITY;

-- Public read access for verified reviews
DROP POLICY IF EXISTS "Anyone can view verified reviews" ON public.healthcare_reviews;
CREATE POLICY "Anyone can view verified reviews"
    ON public.healthcare_reviews FOR SELECT
    USING (is_verified = TRUE);

-- Patients can manage their own reviews
DROP POLICY IF EXISTS "Patients can create own reviews" ON public.healthcare_reviews;
CREATE POLICY "Patients can create own reviews"
    ON public.healthcare_reviews FOR INSERT
    WITH CHECK (auth.uid() = patient_id);

DROP POLICY IF EXISTS "Patients can update own reviews" ON public.healthcare_reviews;
CREATE POLICY "Patients can update own reviews"
    ON public.healthcare_reviews FOR UPDATE
    USING (auth.uid() = patient_id);

DROP POLICY IF EXISTS "Patients can delete own reviews" ON public.healthcare_reviews;
CREATE POLICY "Patients can delete own reviews"
    ON public.healthcare_reviews FOR DELETE
    USING (auth.uid() = patient_id);

-- 5. Synchronization Functions & Triggers
-- Automatically update provider stats (average_rating, total_reviews)
CREATE OR REPLACE FUNCTION update_provider_review_stats()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'INSERT') THEN
        UPDATE public.healthcare_providers
        SET 
            total_reviews = total_reviews + 1,
            average_rating = (
                SELECT ROUND(AVG(rating)::NUMERIC, 2)
                FROM public.healthcare_reviews
                WHERE provider_id = NEW.provider_id
            )
        WHERE id = NEW.provider_id;
    ELSIF (TG_OP = 'UPDATE') THEN
        UPDATE public.healthcare_providers
        SET 
            average_rating = (
                SELECT ROUND(AVG(rating)::NUMERIC, 2)
                FROM public.healthcare_reviews
                WHERE provider_id = NEW.provider_id
            )
        WHERE id = NEW.provider_id;
    ELSIF (TG_OP = 'DELETE') THEN
        UPDATE public.healthcare_providers
        SET 
            total_reviews = GREATEST(0, total_reviews - 1),
            average_rating = (
                SELECT COALESCE(ROUND(AVG(rating)::NUMERIC, 2), 0.00)
                FROM public.healthcare_reviews
                WHERE provider_id = OLD.provider_id
            )
        WHERE id = OLD.provider_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create the trigger
DROP TRIGGER IF EXISTS trg_update_provider_stats ON public.healthcare_reviews;
CREATE TRIGGER trg_update_provider_stats
    AFTER INSERT OR UPDATE OR DELETE ON public.healthcare_reviews
    FOR EACH ROW
    EXECUTE FUNCTION update_provider_review_stats();

-- 6. Comments
COMMENT ON TABLE public.healthcare_reviews IS 'Patient reviews and ratings for healthcare providers.';
COMMENT ON COLUMN public.healthcare_reviews.rating IS 'Numerical rating from 1 to 5.';
COMMENT ON COLUMN public.healthcare_reviews.is_verified IS 'Whether the review is verified (e.g. following a completed consultation).';

-- End of 20260404222300_healthcare_reviews.sql


-- File: 20260405173900_doctor_aliases.sql
-- Doctor Aliases Table
-- Creates system-generated aliases for secondary doctors to protect their identity
-- Format: "Afoke A. (Kome Clinic)" - First name + Last initial + (Clinic Name)

-- Create the doctor_aliases table
CREATE TABLE public.doctor_aliases (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  doctor_id uuid NOT NULL REFERENCES public.healthcare_providers (id) ON DELETE CASCADE,
  primary_doctor_id uuid NOT NULL REFERENCES public.healthcare_providers (id) ON DELETE CASCADE,
  alias character varying(100) NOT NULL,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  accepted boolean NOT NULL DEFAULT false,
  clinic_name text NULL,
  CONSTRAINT doctor_aliases_pkey PRIMARY KEY (id),
  CONSTRAINT doctor_aliases_unique_active UNIQUE (doctor_id, primary_doctor_id, is_active)
) TABLESPACE pg_default;

COMMENT ON TABLE public.doctor_aliases IS 'Links secondary doctors to primary doctors with system-generated aliases to protect identity during patient consultations';

-- Index for finding consultants by primary doctor
CREATE INDEX idx_doctor_aliases_primary_doctor 
ON public.doctor_aliases USING btree (primary_doctor_id, is_active) 
WHERE is_active = true;

-- Index for finding primary doctor by consultant
CREATE INDEX idx_doctor_aliases_doctor 
ON public.doctor_aliases USING btree (doctor_id, is_active) 
WHERE is_active = true;

-- Enable RLS
ALTER TABLE public.doctor_aliases ENABLE ROW LEVEL SECURITY;

-- RLS Policies for the table (not for the view)

-- Policy: Primary doctor can see their consultants' aliases
CREATE POLICY "Primary doctor sees consultants" 
ON public.doctor_aliases FOR SELECT 
USING (
  primary_doctor_id IN (
    SELECT id FROM public.healthcare_providers 
    WHERE user_id = auth.uid()
  )
);

-- Policy: Consultant can see their own alias
CREATE POLICY "Consultant sees own alias" 
ON public.doctor_aliases FOR SELECT 
USING (
  doctor_id IN (
    SELECT id FROM public.healthcare_providers 
    WHERE user_id = auth.uid()
  )
);

-- Helper function to generate alias from provider data
-- Format: "FirstName L. (Clinic Name)" e.g., "Afoke A. (Kome Clinic)"
CREATE OR REPLACE FUNCTION public.generate_doctor_alias(
  p_doctor_first_name TEXT,
  p_doctor_last_name TEXT,
  p_clinic_name TEXT
) RETURNS TEXT AS $$
DECLARE
  v_first_name TEXT;
  v_last_initial TEXT;
  v_clean_clinic_name TEXT;
BEGIN
  -- Get first name (full)
  v_first_name := INITCAP(TRIM(p_doctor_first_name));
  
  -- Get last name initial
  v_last_initial := UPPER(LEFT(TRIM(p_doctor_last_name), 1));
  
  -- Clean clinic name: remove special chars, limit to 30 chars
  v_clean_clinic_name := INITCAP(
    TRIM(
      SUBSTRING(
        regexp_replace(p_clinic_name, '[^a-zA-Z0-9\s]', '', 'g'),
        1,
        30
      )
    )
  );
  
  -- Format: Afoke A. (Kome Clinic)
  RETURN v_first_name || ' ' || v_last_initial || '. (' || v_clean_clinic_name || ')';
END;
$$ LANGUAGE plpgsql IMMUTABLE;

COMMENT ON FUNCTION public.generate_doctor_alias IS 'Generates a system alias in format: FirstName L. (Clinic Name)';

-- Function to create alias for a secondary doctor
-- Note: Uses "clinic name" with double quotes to reference column with space
CREATE OR REPLACE FUNCTION public.create_doctor_alias(
  p_doctor_id UUID,
  p_primary_doctor_id UUID
) RETURNS UUID AS $$
DECLARE
  v_alias TEXT;
  v_doctor_first_name TEXT;
  v_doctor_last_name TEXT;
  v_clinic_name TEXT;
  v_alias_id UUID;
BEGIN
  -- Get secondary doctor full name
  SELECT hp.full_name INTO v_doctor_first_name
  FROM public.healthcare_providers hp
  WHERE hp.id = p_doctor_id;

  -- Split name into first and last
  v_doctor_first_name := SPLIT_PART(v_doctor_first_name, ' ', 1);
  v_doctor_last_name := COALESCE(
    SPLIT_PART(v_doctor_first_name, ' ', 2),
    SPLIT_PART(v_doctor_first_name, ' ', 1)
  );

  -- Get clinic name from primary doctor (use quoted column name "clinic name")
  SELECT COALESCE(hp."clinic name", hp.full_name) INTO v_clinic_name
  FROM public.healthcare_providers hp
  WHERE hp.id = p_primary_doctor_id;

  -- Generate alias
  v_alias := public.generate_doctor_alias(
    v_doctor_first_name,
    v_doctor_last_name,
    v_clinic_name
  );

  -- Insert or update alias (idempotent)
  INSERT INTO public.doctor_aliases (
    doctor_id,
    primary_doctor_id,
    alias,
    is_active,
    created_at
  )
  VALUES (
    p_doctor_id,
    p_primary_doctor_id,
    v_alias,
    true,
    NOW()
  )
  ON CONFLICT (doctor_id, primary_doctor_id, is_active) 
  DO UPDATE SET alias = EXCLUDED.alias
  RETURNING id INTO v_alias_id;

  RETURN v_alias_id;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION public.create_doctor_alias IS 'Creates or updates a system-generated alias for a secondary doctor';

-- View to display alias info with provider details (read-only, RLS inherited from base table)
-- Uses quoted column name "clinic name" 
CREATE OR REPLACE VIEW public.doctor_aliases_with_details AS
SELECT
  da.id,
  da.doctor_id,
  da.primary_doctor_id,
  da.alias,
  da.is_active,
  da.created_at,
  -- Provider details from healthcare_providers
  hp.full_name AS doctor_name,
  hp.profile_photo_url,
  hp.specialization,
  hp.sub_specialty,
  hp.years_of_experience,
  hp.consultation_types,
  hp.marked_up_fees AS consultation_fees,
  hp.preferred_languages,
  hp.average_rating,
  hp.total_consultations,
  hp.total_reviews,
  hp.is_verified,
  -- Primary doctor info (using quoted column name "clinic name")
  hp_primary.full_name AS primary_doctor_name,
  COALESCE(hp_primary."clinic name", hp_primary.full_name) AS clinic_name
FROM public.doctor_aliases da
JOIN public.healthcare_providers hp 
  ON da.doctor_id = hp.id
JOIN public.healthcare_providers hp_primary 
  ON da.primary_doctor_id = hp_primary.id
WHERE da.is_active = true;

COMMENT ON VIEW public.doctor_aliases_with_details IS 'Doctor aliases with full provider details for display in consultations';

-- Grant permissions (views don't need RLS policies)
GRANT SELECT ON public.doctor_aliases TO authenticated;
GRANT SELECT ON public.doctor_aliases_with_details TO authenticated;
GRANT SELECT ON public.doctor_aliases TO anon;
GRANT SELECT ON public.doctor_aliases_with_details TO anon;
GRANT EXECUTE ON FUNCTION public.generate_doctor_alias TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_doctor_alias TO authenticated;

-- Add foreign key indexes
CREATE INDEX idx_doctor_aliases_doctor_fkey 
ON public.doctor_aliases USING btree (doctor_id);

CREATE INDEX idx_doctor_aliases_primary_fkey 
ON public.doctor_aliases USING btree (primary_doctor_id);

-- End of 20260405173900_doctor_aliases.sql


-- File: 20260406000000_doctor_strike_logs.sql
-- Doctor Strike Logs Table
-- Logs reasons for strikes given to partner doctors
CREATE TABLE public.doctor_strike_logs (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    doctor_id uuid NOT NULL REFERENCES public.healthcare_providers(id) ON DELETE CASCADE,
    primary_doctor_id uuid NOT NULL REFERENCES public.healthcare_providers(id) ON DELETE CASCADE,
    reason text NOT NULL,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    CONSTRAINT doctor_strike_logs_pkey PRIMARY KEY (id)
);

-- Index for searching log history
CREATE INDEX idx_doctor_strike_logs_doctor ON public.doctor_strike_logs (doctor_id);
CREATE INDEX idx_doctor_strike_logs_primary ON public.doctor_strike_logs (primary_doctor_id);

-- Enable RLS
ALTER TABLE public.doctor_strike_logs ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Primary doctors can see their own logs, admins can see all
CREATE POLICY "Primary doctors see their own strike logs" 
ON public.doctor_strike_logs FOR SELECT 
USING (
    primary_doctor_id IN (
        SELECT id FROM public.healthcare_providers 
        WHERE user_id = auth.uid()
    )
);

CREATE POLICY "Primary doctors can create strike logs"
ON public.doctor_strike_logs FOR INSERT
WITH CHECK (
    primary_doctor_id IN (
        SELECT id FROM public.healthcare_providers 
        WHERE user_id = auth.uid()
    )
);

-- Grant permissions
GRANT ALL ON public.doctor_strike_logs TO authenticated;
GRANT ALL ON public.doctor_strike_logs TO service_role;

-- End of 20260406000000_doctor_strike_logs.sql


-- File: 20260406000001_doctor_aliases_rls.sql
-- 5. PUBLIC SELECT policy (refining existing if any)
DROP POLICY IF EXISTS "Anyone can see healthcare providers" ON public.healthcare_providers;
CREATE POLICY "Anyone can see healthcare providers"
ON public.healthcare_providers FOR SELECT
USING (true);

-- 1. SELECT policies (already exist but refined)
DROP POLICY IF EXISTS "Primary doctor sees consultants" ON public.doctor_aliases;
CREATE POLICY "Primary doctor sees consultants" 
ON public.doctor_aliases FOR SELECT 
USING (
  primary_doctor_id IN (
    SELECT id FROM public.healthcare_providers 
    WHERE user_id = auth.uid()
  )
);

DROP POLICY IF EXISTS "Consultant sees own alias" ON public.doctor_aliases;
CREATE POLICY "Consultant sees own alias" 
ON public.doctor_aliases FOR SELECT 
USING (
  doctor_id IN (
    SELECT id FROM public.healthcare_providers 
    WHERE user_id = auth.uid()
  )
);

-- 2. INSERT policy
-- Allows primary doctor to invite other doctors
DROP POLICY IF EXISTS "Primary doctor can invite consultants" ON public.doctor_aliases;
CREATE POLICY "Primary doctor can invite consultants"
ON public.doctor_aliases FOR INSERT
WITH CHECK (
  primary_doctor_id IN (
    SELECT id FROM public.healthcare_providers 
    WHERE user_id = auth.uid()
  )
);

-- 3. UPDATE policy
-- Allows primary doctor to manage their consultants (e.g. toggle active state)
DROP POLICY IF EXISTS "Primary doctor can update consultants" ON public.doctor_aliases;
CREATE POLICY "Primary doctor can update consultants"
ON public.doctor_aliases FOR UPDATE
USING (
  primary_doctor_id IN (
    SELECT id FROM public.healthcare_providers 
    WHERE user_id = auth.uid()
  )
)
WITH CHECK (
  primary_doctor_id IN (
    SELECT id FROM public.healthcare_providers 
    WHERE user_id = auth.uid()
  )
);

-- 4. DELETE policy
-- Allows primary doctor to remove consultants from their clinic
DROP POLICY IF EXISTS "Primary doctor can delete consultants" ON public.doctor_aliases;
CREATE POLICY "Primary doctor can delete consultants"
ON public.doctor_aliases FOR DELETE
USING (
  primary_doctor_id IN (
    SELECT id FROM public.healthcare_providers 
    WHERE user_id = auth.uid()
  )
);

-- 5. PUBLIC SELECT policy
-- Allows anyone (patients) to see accepted and active consultants for a clinic
DROP POLICY IF EXISTS "Public can see active consultants" ON public.doctor_aliases;
CREATE POLICY "Public can see active consultants"
ON public.doctor_aliases FOR SELECT
USING (accepted = true AND (is_active IS NOT FALSE));

-- Grant the table to authenticated and anon users
GRANT ALL ON public.doctor_aliases TO authenticated;
GRANT SELECT ON public.doctor_aliases TO anon;

-- End of 20260406000001_doctor_aliases_rls.sql


-- File: 20260406000002_normalize_provider_schedule.sql
-- Migration: Refactor Scheduling Fields
-- 1. Add individual columns for duration and buffer to healthcare_providers
ALTER TABLE public.healthcare_providers 
ADD COLUMN IF NOT EXISTS slot_duration_minutes INTEGER DEFAULT 30,
ADD COLUMN IF NOT EXISTS buffer_time_minutes INTEGER DEFAULT 0;

-- 2. Migrate data from slot_settings JSONB if exists
UPDATE public.healthcare_providers
SET 
  slot_duration_minutes = COALESCE((slot_settings->>'duration')::integer, 30),
  buffer_time_minutes = COALESCE((slot_settings->>'buffer')::integer, 0)
WHERE slot_settings IS NOT NULL;

-- 3. Remove the redundant JSONB columns
ALTER TABLE public.healthcare_providers 
DROP COLUMN IF EXISTS work_schedule,
DROP COLUMN IF EXISTS slot_settings;

-- 4. Ensure RLS for the provider_availability_templates table
-- (Assuming the table was just created by the user)
ALTER TABLE public.provider_availability_templates ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Providers can manage their own templates"
ON public.provider_availability_templates
FOR ALL
USING (
  provider_id IN (
    SELECT id FROM public.healthcare_providers WHERE user_id = auth.uid()
  )
);

CREATE POLICY "Anyone can view active availability templates"
ON public.provider_availability_templates
FOR SELECT
USING (is_active = true);

-- End of 20260406000002_normalize_provider_schedule.sql


-- File: 20260406000003_fix_availability_rls.sql
-- Migration: Fix Availability Template RLS
-- Replacing the monolithic 'FOR ALL' policy with explicit ones to ensure DELETE works reliably with subqueries.

-- 1. Drop the old unified policy
DROP POLICY IF EXISTS "Providers can manage their own templates" ON public.provider_availability_templates;
DROP POLICY IF EXISTS "Anyone can view active availability templates" ON public.provider_availability_templates;

-- 2. Add explicit granular policies
CREATE POLICY "Provider Select" ON public.provider_availability_templates
FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM public.healthcare_providers 
    WHERE id = provider_availability_templates.provider_id 
    AND (user_id = auth.uid())
  )
  OR is_active = true
);

CREATE POLICY "Provider Insert" ON public.provider_availability_templates
FOR INSERT
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.healthcare_providers 
    WHERE id = provider_id 
    AND user_id = auth.uid()
  )
);

CREATE POLICY "Provider Update" ON public.provider_availability_templates
FOR UPDATE
USING (
  EXISTS (
    SELECT 1 FROM public.healthcare_providers 
    WHERE id = provider_availability_templates.provider_id 
    AND user_id = auth.uid()
  )
);

CREATE POLICY "Provider Delete" ON public.provider_availability_templates
FOR DELETE
USING (
  EXISTS (
    SELECT 1 FROM public.healthcare_providers 
    WHERE id = provider_availability_templates.provider_id 
    AND user_id = auth.uid()
  )
);

GRANT ALL ON public.provider_availability_templates TO authenticated;
GRANT SELECT ON public.provider_availability_templates TO anon;

-- End of 20260406000003_fix_availability_rls.sql


-- File: 20260406000004_soft_delete_scheduling.sql
-- Migration: Implement Soft-Delete for Availability Templates
-- Adding is_closed column and making provider_id + day_of_week unique for reliable upserting.

-- 1. Add the is_closed column
ALTER TABLE public.provider_availability_templates 
ADD COLUMN IF NOT EXISTS is_closed BOOLEAN DEFAULT FALSE;

-- 2. Add a unique constraint to prevent duplicate day entries for a single provider
-- This allows us to use 'ON CONFLICT' to simply toggle is_closed state.
ALTER TABLE public.provider_availability_templates 
ADD CONSTRAINT unique_provider_day UNIQUE (provider_id, day_of_week);

-- 3. Pre-populate is_closed for existing records that might be logically inactive
UPDATE public.provider_availability_templates 
SET is_closed = NOT is_active 
WHERE is_active IS NOT NULL;

-- End of 20260406000004_soft_delete_scheduling.sql


-- File: 20260406000005_add_day_name_to_templates.sql
-- Migration: Add Human-Readable Day Names to Availability Templates
-- This improves database readability for manual queries and reporting.

ALTER TABLE public.provider_availability_templates 
ADD COLUMN IF NOT EXISTS day_name TEXT;

-- Update existing records with the correct day name based on day_of_week
UPDATE public.provider_availability_templates 
SET day_name = CASE 
    WHEN day_of_week = 0 THEN 'Sunday'
    WHEN day_of_week = 1 THEN 'Monday'
    WHEN day_of_week = 2 THEN 'Tuesday'
    WHEN day_of_week = 3 THEN 'Wednesday'
    WHEN day_of_week = 4 THEN 'Thursday'
    WHEN day_of_week = 5 THEN 'Friday'
    WHEN day_of_week = 6 THEN 'Saturday'
END
WHERE day_name IS NULL;

-- End of 20260406000005_add_day_name_to_templates.sql


-- File: 20260406204500_healthcare_review_replies.sql
-- Migration: Create healthcare_review_replies table
-- Created: 2026-04-06

CREATE TABLE IF NOT EXISTS public.healthcare_review_replies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    review_id UUID NOT NULL REFERENCES public.healthcare_reviews(id) ON DELETE CASCADE,
    provider_id UUID NOT NULL REFERENCES public.healthcare_providers(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    -- Constraints: Only one reply per review
    CONSTRAINT unique_review_reply UNIQUE (review_id)
);

-- Performance Indexes
CREATE INDEX IF NOT EXISTS idx_review_replies_review_id ON public.healthcare_review_replies(review_id);
CREATE INDEX IF NOT EXISTS idx_review_replies_provider_id ON public.healthcare_review_replies(provider_id);

-- Row-Level Security (RLS)
ALTER TABLE public.healthcare_review_replies ENABLE ROW LEVEL SECURITY;

-- Anyone can view replies to verified reviews
DROP POLICY IF EXISTS "Anyone can view replies" ON public.healthcare_review_replies;
CREATE POLICY "Anyone can view replies"
    ON public.healthcare_review_replies FOR SELECT
    USING (EXISTS (
        SELECT 1 FROM public.healthcare_reviews 
        WHERE id = review_id AND is_verified = TRUE
    ));

-- Providers can manage their own replies
DROP POLICY IF EXISTS "Providers can create own replies" ON public.healthcare_review_replies;
CREATE POLICY "Providers can create own replies"
    ON public.healthcare_review_replies FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.healthcare_providers
            WHERE id = provider_id AND user_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Providers can update own replies" ON public.healthcare_review_replies;
CREATE POLICY "Providers can update own replies"
    ON public.healthcare_review_replies FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM public.healthcare_providers
            WHERE id = provider_id AND user_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Providers can delete own replies" ON public.healthcare_review_replies;
CREATE POLICY "Providers can delete own replies"
    ON public.healthcare_review_replies FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM public.healthcare_providers
            WHERE id = provider_id AND user_id = auth.uid()
        )
    );

-- Functions
CREATE OR REPLACE FUNCTION update_review_reply_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger
CREATE TRIGGER trg_update_review_reply_timestamp
    BEFORE UPDATE ON public.healthcare_review_replies
    FOR EACH ROW
    EXECUTE FUNCTION update_review_reply_timestamp();

-- End of 20260406204500_healthcare_review_replies.sql


-- File: 20260406205000_seed_healthcare_reviews.sql
-- Migration: Seed healthcare reviews for testing
-- Created: 2026-04-06

DO $$
DECLARE
    v_provider_id UUID;
    v_patient_id UUID;
    v_count INT;
BEGIN
    -- Get the first provider
    SELECT id INTO v_provider_id FROM public.healthcare_providers LIMIT 1;
    
    IF v_provider_id IS NOT NULL THEN
        -- Check if reviews already exist
        SELECT COUNT(*) INTO v_count FROM public.healthcare_reviews WHERE provider_id = v_provider_id;
        
        IF v_count = 0 THEN
            -- Create a few reviews
            -- We try to find users from auth.users (excluding the provider's user_id if possible)
            FOR i IN 0..4 LOOP
                SELECT id INTO v_patient_id 
                FROM auth.users 
                WHERE id NOT IN (SELECT user_id FROM public.healthcare_providers WHERE id = v_provider_id)
                OFFSET i LIMIT 1;
                
                IF v_patient_id IS NOT NULL THEN
                    INSERT INTO public.healthcare_reviews (
                        provider_id,
                        patient_id,
                        rating,
                        comment,
                        is_verified,
                        created_at
                    )
                    VALUES (
                        v_provider_id,
                        v_patient_id,
                        CASE (i % 5)
                            WHEN 0 THEN 5 
                            WHEN 1 THEN 4 
                            WHEN 2 THEN 5 
                            WHEN 3 THEN 3 
                            ELSE 5 
                        END,
                        CASE (i % 5)
                            WHEN 0 THEN 'Excellent doctor, very attentive and professional. The consultation was thorough.'
                            WHEN 1 THEN 'Good experience overall. The doctor was knowledgeable, though the clinic was quite busy.'
                            WHEN 2 THEN 'Very helpful consultation. All my questions were answered clearly. Highly recommended!'
                            WHEN 3 THEN 'Decent service, but I felt the appointment was a bit rushed.'
                            ELSE 'Five stars! Best medical professional I have visited in a long time.'
                        END,
                        TRUE,
                        NOW() - (i || ' days')::interval
                    )
                    ON CONFLICT (patient_id, provider_id) DO NOTHING;
                END IF;
            END LOOP;
            
            -- Add one sample reply
            DECLARE
                v_review_id UUID;
            BEGIN
                SELECT id INTO v_review_id 
                FROM public.healthcare_reviews 
                WHERE provider_id = v_provider_id 
                LIMIT 1;
                
                IF v_review_id IS NOT NULL THEN
                    INSERT INTO public.healthcare_review_replies (
                        review_id,
                        provider_id,
                        content,
                        created_at
                    )
                    VALUES (
                        v_review_id,
                        v_provider_id,
                        'Thank you so much for your positive feedback! I''m glad I could help with your recovery.',
                        NOW()
                    )
                    ON CONFLICT (review_id) DO NOTHING;
                END IF;
            END;
        END IF;
    END IF;
END $$;

-- End of 20260406205000_seed_healthcare_reviews.sql


-- File: 20260406210000_fix_provider_settings_columns.sql
-- Migration: Add missing provider settings columns and fix constraints
-- 1. Add follow_up_duration to healthcare_providers
ALTER TABLE public.healthcare_providers 
ADD COLUMN IF NOT EXISTS follow_up_duration INTEGER DEFAULT 24;

-- 2. Relax slot_duration check on provider_availability_templates to allow more flexible scheduling
-- First find the existing constraint name if possible, or just drop it if it matches the standard pattern
-- Typical name for inline check is provider_availability_templates_slot_duration_check
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.constraint_column_usage 
        WHERE table_name = 'provider_availability_templates' 
        AND column_name = 'slot_duration'
    ) THEN
        BEGIN
            ALTER TABLE public.provider_availability_templates DROP CONSTRAINT IF EXISTS provider_availability_templates_slot_duration_check;
        EXCEPTION WHEN undefined_object THEN
            -- Ignore if name is different, we can't easily guess it without information_schema
            NULL;
        END;
    END IF;
END $$;

-- Add updated check constraint to support 15, 30, 45, 60, 90, 120 minutes as per UI
-- We also ensure it handles existing values
ALTER TABLE public.provider_availability_templates
ADD CONSTRAINT provider_availability_templates_slot_duration_check_v2 
CHECK (slot_duration IN (15, 30, 45, 60, 90, 120));

-- 3. Ensure RLS for the healthcare_providers table allows updating these new columns
-- (Standard UPDATE policy usually covers all columns, so this is just a sanity check)
-- No changes needed if the existing policy is 'user_id = auth.uid()'

-- End of 20260406210000_fix_provider_settings_columns.sql


-- File: 20260406211500_fix_naming_and_constraints_final.sql
-- Migration: Correct column naming and update constraints
-- 1. Rename "clinic name" to "clinic_name" to avoid spacing issues
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'healthcare_providers' 
        AND column_name = 'clinic name'
    ) THEN
        ALTER TABLE public.healthcare_providers RENAME COLUMN "clinic name" TO clinic_name;
    END IF;
END $$;

-- 2. Ensure follow_up_duration is present (it was in the schema but just in case)
ALTER TABLE public.healthcare_providers 
ADD COLUMN IF NOT EXISTS follow_up_duration INTEGER DEFAULT 24;

-- 3. Update the slot_duration check constraint name to be more robust and allow new values
-- We use a name that is less likely to conflict and handles the new options
ALTER TABLE public.provider_availability_templates 
DROP CONSTRAINT IF EXISTS provider_availability_templates_slot_duration_check;

ALTER TABLE public.provider_availability_templates 
DROP CONSTRAINT IF EXISTS provider_availability_templates_slot_duration_check_v2;

ALTER TABLE public.provider_availability_templates
ADD CONSTRAINT prov_avail_slot_duration_valid 
CHECK (slot_duration IN (15, 30, 45, 60, 90, 120));

-- 4. Set defaults for any NULL values in critical columns to prevent update failures
UPDATE public.healthcare_providers SET strike = 0 WHERE strike IS NULL;
UPDATE public.healthcare_providers SET accept_invite = true WHERE accept_invite IS NULL;
UPDATE public.healthcare_providers SET slot_duration_minutes = 30 WHERE slot_duration_minutes IS NULL;
UPDATE public.healthcare_providers SET buffer_time_minutes = 0 WHERE buffer_time_minutes IS NULL;
UPDATE public.healthcare_providers SET follow_up_duration = 24 WHERE follow_up_duration IS NULL;

-- End of 20260406211500_fix_naming_and_constraints_final.sql


-- File: 20260406211502_allow_booking_slot.sql
-- Allow authenticated users (patients) to insert provider time slots for booking
-- Also ensure they can reserve a slot
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'provider_time_slots' 
        AND policyname = 'Authenticated users can create slots'
    ) THEN
        CREATE POLICY "Authenticated users can create slots"
            ON provider_time_slots FOR INSERT
            WITH CHECK (auth.uid() IS NOT NULL);
    END IF;
END $$;

-- End of 20260406211502_allow_booking_slot.sql


-- File: 20260416000000_add_provider_onboarding_fields.sql
-- Add missing onboarding fields to healthcare_providers table
ALTER TABLE healthcare_providers
ADD COLUMN IF NOT EXISTS license_document_url TEXT;

-- End of 20260416000000_add_provider_onboarding_fields.sql


-- File: 20260417210000_add_idle_timeout_to_providers.sql
-- Add idle_timeout_minutes column to healthcare_providers
ALTER TABLE healthcare_providers 
ADD COLUMN IF NOT EXISTS idle_timeout_minutes INTEGER DEFAULT 30;

-- Add check constraint to cap at 60 minutes and minimum 1 minute
ALTER TABLE healthcare_providers
ADD CONSTRAINT check_idle_timeout_range 
CHECK (idle_timeout_minutes >= 1 AND idle_timeout_minutes <= 60);

-- Comment for documentation
COMMENT ON COLUMN healthcare_providers.idle_timeout_minutes IS 'Inactivity timeout in minutes for auto-logout (min 1, max 60)';

-- End of 20260417210000_add_idle_timeout_to_providers.sql


-- File: 20260417215300_remove_unique_phone_constraint.sql
-- ============================================================
-- Migration: Remove Unique Phone Constraint on Patients
-- ============================================================
-- Purpose: Allow healthcare providers to register multiple patients 
-- with the same phone number (e.g., family members, minors).
-- Also clarifies that patients can already be associated with
-- multiple different providers (the previous constraint was per-provider).

ALTER TABLE patients 
DROP CONSTRAINT IF EXISTS patients_healthcare_provider_id_phone_key;

-- We still keep the index on phone for search performance, 
-- but it is no longer unique.
COMMENT ON TABLE patients IS 'Updated: Removed unique constraint on phone per provider to allow family registration.';

-- End of 20260417215300_remove_unique_phone_constraint.sql


-- File: 20260417223200_fix_patients_rls_visibility.sql
-- ============================================================
-- Migration: Fix Patient Deletion RLS Conflicts
-- ============================================================
-- Purpose: Allow owners to view their own records even if marked as deleted.
-- This ensures that soft-delete updates can be confirmed by the database
-- while maintaining privacy. The UI already filters these out via queries.

-- 1. Drop the old restrictive select policy
DROP POLICY IF EXISTS "Providers can view their patients" ON patients;

-- 2. Create a new select policy that only checks for ownership
CREATE POLICY "Providers can view their patients"
ON patients FOR SELECT
USING (
    healthcare_provider_id IN (
        SELECT id FROM healthcare_providers
        WHERE user_id = auth.uid()
    )
    -- Remove the 'AND is_deleted = FALSE' so providers can see their own deleted records
);

-- Note: The UI query should still explicitly filter with .eq('is_deleted', false)
-- to keep the patient list clean.
COMMENT ON POLICY "Providers can view their patients" ON patients IS 'Allowed owners to see their own records, even if deleted, to prevent soft-delete confirmation hangs.';

-- End of 20260417223200_fix_patients_rls_visibility.sql


-- File: 20260417235800_sync_prescribed_drugs.sql
-- ============================================================================
-- Sync prescribed_drugs table with user specifications
-- ============================================================================

-- 1. Rename drug_id to product_id if it exists
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'prescribed_drugs' AND column_name = 'drug_id'
    ) THEN
        ALTER TABLE prescribed_drugs RENAME COLUMN drug_id TO product_id;
    END IF;
END $$;

-- 2. Drop existing foreign key on product_id/drug_id if it exists to clean up
DO $$
DECLARE
    v_constraint_name TEXT;
BEGIN
    SELECT constraint_name INTO v_constraint_name
    FROM information_schema.key_column_usage
    WHERE table_name = 'prescribed_drugs' AND column_name = 'product_id';
    
    IF v_constraint_name IS NOT NULL THEN
        EXECUTE 'ALTER TABLE prescribed_drugs DROP CONSTRAINT IF EXISTS ' || v_constraint_name;
    END IF;
END $$;

-- 3. Add proper foreign key to products
ALTER TABLE prescribed_drugs 
    ADD CONSTRAINT prescribed_drugs_product_id_fkey 
    FOREIGN KEY (product_id) REFERENCES products(id);

-- 4. Ensure all columns from the user's spec exist
ALTER TABLE prescribed_drugs ADD COLUMN IF NOT EXISTS generic_name TEXT;
ALTER TABLE prescribed_drugs ADD COLUMN IF NOT EXISTS dispense_as TEXT;
ALTER TABLE prescribed_drugs ADD COLUMN IF NOT EXISTS dispense_quantity INTEGER;
ALTER TABLE prescribed_drugs ADD COLUMN IF NOT EXISTS dosage TEXT;
ALTER TABLE prescribed_drugs ADD COLUMN IF NOT EXISTS frequency TEXT;
ALTER TABLE prescribed_drugs ADD COLUMN IF NOT EXISTS drug_pic_url TEXT;
ALTER TABLE prescribed_drugs ADD COLUMN IF NOT EXISTS duration TEXT;
ALTER TABLE prescribed_drugs ADD COLUMN IF NOT EXISTS special_instructions TEXT;
ALTER TABLE prescribed_drugs ADD COLUMN IF NOT EXISTS substitution_allowed BOOLEAN DEFAULT true;
ALTER TABLE prescribed_drugs ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'pending';

-- 5. Update status check constraint
ALTER TABLE prescribed_drugs DROP CONSTRAINT IF EXISTS prescribed_drugs_status_check;
ALTER TABLE prescribed_drugs ADD CONSTRAINT prescribed_drugs_status_check 
    CHECK (status IN ('pending', 'dispensed', 'out_of_stock', 'cancelled'));

-- 6. Ensure updated_at trigger exists
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_prescribed_drugs_updated_at') THEN
        CREATE TRIGGER update_prescribed_drugs_updated_at
            BEFORE UPDATE ON prescribed_drugs
            FOR EACH ROW
            EXECUTE FUNCTION update_updated_at_column();
    END IF;
END $$;

-- End of 20260417235800_sync_prescribed_drugs.sql


-- File: 20260418000000_create_review_reports.sql
-- Migration: Create healthcare_review_reports table
-- Created: 2026-04-18

CREATE TABLE IF NOT EXISTS public.healthcare_review_reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    review_id UUID NOT NULL REFERENCES public.healthcare_reviews(id) ON DELETE CASCADE,
    reporter_id UUID NOT NULL REFERENCES public.healthcare_providers(id) ON DELETE CASCADE,
    reason TEXT NOT NULL,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'reviewed', 'resolved', 'dismissed')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Performance Indexes
CREATE INDEX IF NOT EXISTS idx_review_reports_review_id ON public.healthcare_review_reports(review_id);
CREATE INDEX IF NOT EXISTS idx_review_reports_reporter_id ON public.healthcare_review_reports(reporter_id);

-- Row-Level Security (RLS)
ALTER TABLE public.healthcare_review_reports ENABLE ROW LEVEL SECURITY;

-- Providers can manage their own reports
DROP POLICY IF EXISTS "Providers can create own reports" ON public.healthcare_review_reports;
CREATE POLICY "Providers can create own reports"
    ON public.healthcare_review_reports FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.healthcare_providers
            WHERE id = reporter_id AND user_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Providers can view own reports" ON public.healthcare_review_reports;
CREATE POLICY "Providers can view own reports"
    ON public.healthcare_review_reports FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.healthcare_providers
            WHERE id = reporter_id AND user_id = auth.uid()
        )
    );

-- Functions
CREATE OR REPLACE FUNCTION update_review_report_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger
CREATE TRIGGER trg_update_review_report_timestamp
    BEFORE UPDATE ON public.healthcare_review_reports
    FOR EACH ROW
    EXECUTE FUNCTION update_review_report_timestamp();

-- End of 20260418000000_create_review_reports.sql


-- File: 20260418000001_create_chat_system.sql
-- Harmonized Chat System Migration
-- This aligns with the user's existing schema while adding medical capabilities.

-- 1. Extend Enums (if they don't already have 'medic')
-- We use a DO block to safely add types if they don't exist
DO $$
BEGIN
    -- Check if 'medic' exists in sender_type
    IF NOT EXISTS (SELECT 1 FROM pg_enum e JOIN pg_type t ON e.enumtypid = t.oid WHERE t.typname = 'sender_type' AND e.enumlabel = 'medic') THEN
        ALTER TYPE public.sender_type ADD VALUE 'medic';
    END IF;
    
    -- Check if 'medic' exists in user_type (used by typing indicators in some schemas)
    IF EXISTS (SELECT 1 FROM pg_type WHERE typname = 'user_type') THEN
        IF NOT EXISTS (SELECT 1 FROM pg_enum e JOIN pg_type t ON e.enumtypid = t.oid WHERE t.typname = 'user_type' AND e.enumlabel = 'medic') THEN
            ALTER TYPE public.user_type ADD VALUE 'medic';
        END IF;
    END IF;
END
$$;

-- 2. Ensure Conversations Table supports Consultations
-- The user's snippet provided 'chat_conversations'
ALTER TABLE public.chat_conversations 
ADD COLUMN IF NOT EXISTS consultation_id UUID REFERENCES public.consultations(id) ON DELETE CASCADE,
ADD COLUMN IF NOT EXISTS consultation_code VARCHAR(20);

-- Table structure harmonization (referencing the user's snippet)
-- We assume these tables exist as per user's prompt, but we ensure the columns and links are there.

-- 3. Typing Indicators (Clinical version)
CREATE TABLE IF NOT EXISTS public.chat_typing_indicators (
    id UUID PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
    conversation_id UUID NOT NULL REFERENCES public.chat_conversations(id) ON DELETE CASCADE,
    user_id UUID NOT NULL,
    user_type TEXT NOT NULL CHECK (user_type IN ('medic', 'customer', 'staff', 'ai_agent')),
    is_typing BOOLEAN DEFAULT TRUE,
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '10 seconds'),
    UNIQUE (conversation_id, user_id)
);

-- 4. RLS Policies for Harmonized Schema
ALTER TABLE public.chat_conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_attachments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_typing_indicators ENABLE ROW LEVEL SECURITY;

-- Conversations Access
DROP POLICY IF EXISTS "Participants can view conversations" ON public.chat_conversations;
CREATE POLICY "Participants can view conversations"
ON public.chat_conversations FOR SELECT
USING (
    customer_id = auth.uid() OR 
    auth.uid() IN (SELECT user_id FROM public.healthcare_providers) OR
    tenant_id IN (SELECT tenant_id FROM public.users WHERE id = auth.uid() AND role IN ('tenant_admin', 'platform_admin'))
);

-- Messages Access
DROP POLICY IF EXISTS "Participants can view messages" ON public.chat_messages;
CREATE POLICY "Participants can view messages"
ON public.chat_messages FOR SELECT
USING (
    conversation_id IN (
        SELECT id FROM public.chat_conversations
        WHERE customer_id = auth.uid() OR 
              auth.uid() IN (SELECT user_id FROM public.healthcare_providers)
    )
);

DROP POLICY IF EXISTS "Participants can insert messages" ON public.chat_messages;
CREATE POLICY "Participants can insert messages"
ON public.chat_messages FOR INSERT
WITH CHECK (
    conversation_id IN (
        SELECT id FROM public.chat_conversations
        WHERE customer_id = auth.uid() OR 
              auth.uid() IN (SELECT user_id FROM public.healthcare_providers)
    )
);

-- Trigger to automatically generate consultation_code if it's a medical chat
CREATE OR REPLACE FUNCTION generate_consultation_code()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.consultation_id IS NOT NULL AND NEW.consultation_code IS NULL THEN
        NEW.consultation_code := 'CONS-' || UPPER(SUBSTRING(REPLACE(NEW.consultation_id::text, '-', ''), 1, 4));
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_generate_consultation_code ON public.chat_conversations;
CREATE TRIGGER trigger_generate_consultation_code
    BEFORE INSERT OR UPDATE ON public.chat_conversations
    FOR EACH ROW
    EXECUTE FUNCTION generate_consultation_code();

-- End of 20260418000001_create_chat_system.sql


-- File: 20260418000002_fix_chat_rls_policies.sql
-- Migration: Fix Chat RLS Policies
-- Purpose: Allow medics and patients to initialize and update chat conversations

-- 1. Ensure RLS is enabled
ALTER TABLE public.chat_conversations ENABLE ROW LEVEL SECURITY;

-- 2. INSERT Policy
-- Allows medics to create a conversation if they are part of a registered healthcare provider clinic
DROP POLICY IF EXISTS "Medics can create conversations" ON public.chat_conversations;
CREATE POLICY "Medics can create conversations"
ON public.chat_conversations FOR INSERT
WITH CHECK (
    auth.uid() IN (SELECT user_id FROM public.healthcare_providers)
);

-- 3. SELECT Policy (Harmonized)
-- Allows participants (patient or medic) to view the conversation
DROP POLICY IF EXISTS "Participants can view conversations" ON public.chat_conversations;
CREATE POLICY "Participants can view conversations"
ON public.chat_conversations FOR SELECT
USING (
    customer_id = auth.uid() OR 
    auth.uid() IN (SELECT user_id FROM public.healthcare_providers)
);

-- 4. UPDATE Policy
-- Allows participants to update status or metadata (like last_message_time)
DROP POLICY IF EXISTS "Participants can update conversations" ON public.chat_conversations;
CREATE POLICY "Participants can update conversations"
ON public.chat_conversations FOR UPDATE
USING (
    customer_id = auth.uid() OR 
    auth.uid() IN (SELECT user_id FROM public.healthcare_providers)
);

-- 5. DELETE Policy (Safety)
-- Only admins should delete, but we prevent accidental deletions by standard users
DROP POLICY IF EXISTS "Admins can delete conversations" ON public.chat_conversations;
CREATE POLICY "Admins can delete conversations"
ON public.chat_conversations FOR DELETE
USING (
    auth.uid() IN (SELECT id FROM public.users WHERE role IN ('tenant_admin', 'platform_admin'))
);

-- End of 20260418000002_fix_chat_rls_policies.sql


-- File: 20260418000003_make_chat_columns_nullable.sql
-- Migration: Make Retail Columns Nullable in Chat Conversations
-- Purpose: Support clinical consultations that are not tied to a specific retail tenant or branch

-- 1. Alter tenant_id to be nullable
ALTER TABLE public.chat_conversations 
ALTER COLUMN tenant_id DROP NOT NULL;

-- 2. Alter branch_id to be nullable
ALTER TABLE public.chat_conversations 
ALTER COLUMN branch_id DROP NOT NULL;

-- 3. Alter customer_id to be nullable
-- Clinical patients reference auth.users(id) instead of customers(id)
ALTER TABLE public.chat_conversations 
ALTER COLUMN customer_id DROP NOT NULL;

-- 4. Update RLS policies to handle NULLs if necessary
-- (The existing policies in 20260418000002 already use auth.uid() or healthcare_providers check, so they are robust)

-- 5. Add comments
COMMENT ON COLUMN public.chat_conversations.tenant_id IS 'Optional for clinical chats not tied to a retail tenant';
COMMENT ON COLUMN public.chat_conversations.branch_id IS 'Optional for clinical chats not tied to a retail branch';
COMMENT ON COLUMN public.chat_conversations.customer_id IS 'Optional for clinical chats where patient is identified by auth.uid directly';

-- End of 20260418000003_make_chat_columns_nullable.sql


-- File: 20260418000004_fix_message_constraints.sql
-- Relax constraints for clinical messaging
-- Medical users (clinicians) are authenticated via auth.users but may not have a matching record 
-- in the retail-focused public.users table. We make the sender_id foreign key nullable 
-- or remove the strict link to the retail table if it blocks healthcare functionality.

DO $$
BEGIN
    -- Drop the strict foreign key to retail users if it exists
    IF EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'chat_messages_sender_id_fkey'
    ) THEN
        ALTER TABLE public.chat_messages DROP CONSTRAINT chat_messages_sender_id_fkey;
    END IF;

    -- Add a more flexible link or ensure it's just a UUID for the sender
    -- We keep it as a UUID but don't force it to be in the retail table.
    -- It still links via auth.uid() in RLS policies.
END $$;

-- End of 20260418000004_fix_message_constraints.sql


-- File: 20260419143000_unify_transaction_items.sql
-- ============================================================
-- Migration: Unify Order and Sale Items with Analytics (FINAL VERIFIED)
-- Description: Recreates sale_items with granular analytics and drops order_items.
-- Optimized for: PostgreSQL compatibility and SQL Editor runners.
-- ============================================================

-- 1. CLEANUP: Drop old tables and all their dependencies
DROP TABLE IF EXISTS public.order_items CASCADE;
DROP TABLE IF EXISTS public.sale_items CASCADE;

-- 2. CREATE: Create the Unified sale_items Table
CREATE TABLE public.sale_items (
  id uuid NOT NULL DEFAULT extensions.uuid_generate_v4 (),
  tenant_id uuid NOT NULL,
  sale_id uuid NULL, 
  order_id uuid NULL, 
  inventory_id uuid NULL, 
  product_id uuid NOT NULL,
  product_name character varying(255) NOT NULL,
  product_sku character varying(100) NULL,
  category_id uuid NULL,
  category_name character varying(255) NULL,
  quantity integer NOT NULL,
  unit_of_measure character varying(20) NULL DEFAULT 'piece'::character varying,
  strength text NULL,
  
  -- Price & Discount
  unit_price numeric(12, 2) NOT NULL,
  original_price numeric(15, 2) NULL,
  discount_percent numeric(5, 2) NULL DEFAULT 0,
  discount_amount numeric(12, 2) NULL DEFAULT 0,
  discount_percentage numeric(5, 2) NULL DEFAULT 0,
  discount_type character varying(50) NULL,
  discount_code character varying(50) NULL,
  
  -- Tax
  tax_percentage numeric(5, 2) NULL DEFAULT 0,
  tax_amount numeric(15, 2) NULL DEFAULT 0,
  
  -- Totals
  subtotal numeric(12, 2) NOT NULL,
  
  -- Cost & Profit
  unit_cost numeric(15, 2) NULL,
  total_cost numeric(15, 2) NULL,
  gross_profit numeric(15, 2) NULL,
  profit_margin numeric(5, 2) NULL,
  
  -- Context
  branch_id uuid NULL,
  cashier_id uuid NULL,
  health_care_provider uuid NULL,
  customer_id uuid NULL,
  
  -- Audit
  sale_date timestamp with time zone NOT NULL DEFAULT now(),
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  
  -- Generated Analytics Columns (Stored for performance)
  sale_hour integer GENERATED ALWAYS AS (EXTRACT(HOUR FROM (sale_date AT TIME ZONE 'UTC'))) STORED,
  sale_day integer GENERATED ALWAYS AS (EXTRACT(DAY FROM (sale_date AT TIME ZONE 'UTC'))) STORED,
  sale_week integer GENERATED ALWAYS AS (EXTRACT(WEEK FROM (sale_date AT TIME ZONE 'UTC'))) STORED,
  sale_month integer GENERATED ALWAYS AS (EXTRACT(MONTH FROM (sale_date AT TIME ZONE 'UTC'))) STORED,
  sale_quarter integer GENERATED ALWAYS AS (EXTRACT(QUARTER FROM (sale_date AT TIME ZONE 'UTC'))) STORED,
  sale_year integer GENERATED ALWAYS AS (EXTRACT(YEAR FROM (sale_date AT TIME ZONE 'UTC'))) STORED,

  -- Primary Key
  PRIMARY KEY (id),
  
  -- Foreign Keys
  FOREIGN KEY (tenant_id) REFERENCES tenants (id) ON DELETE CASCADE,
  FOREIGN KEY (sale_id) REFERENCES sales (id) ON DELETE CASCADE,
  FOREIGN KEY (order_id) REFERENCES orders (id) ON DELETE CASCADE,
  FOREIGN KEY (product_id) REFERENCES products (id),
  FOREIGN KEY (inventory_id) REFERENCES branch_inventory (id),
  FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE SET NULL,
  FOREIGN KEY (branch_id) REFERENCES branches (id),
  FOREIGN KEY (cashier_id) REFERENCES users (id),
  FOREIGN KEY (customer_id) REFERENCES customers (id),
  FOREIGN KEY (health_care_provider) REFERENCES healthcare_providers (id),
  
  -- Validations
  CHECK (quantity > 0),
  CHECK (unit_price > 0),
  CHECK (subtotal >= 0),
  CONSTRAINT valid_subtotal_logic CHECK (subtotal = (unit_price * quantity) - discount_amount)
) TABLESPACE pg_default;

-- 3. INDEXES: Create Performance Indices
CREATE INDEX IF NOT EXISTS idx_sale_items_tenant_final ON public.sale_items(tenant_id);
CREATE INDEX IF NOT EXISTS idx_sale_items_branch_final ON public.sale_items(branch_id);
CREATE INDEX IF NOT EXISTS idx_sale_items_created_at_final ON public.sale_items(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_sale_items_category_final ON public.sale_items(category_id) WHERE (category_id IS NOT NULL);
CREATE INDEX IF NOT EXISTS idx_sale_items_product_final ON public.sale_items(product_id);
CREATE INDEX IF NOT EXISTS idx_sale_items_sale_order_final ON public.sale_items(sale_id, order_id);

-- 4. LOGIC: Update Populate Details Function
CREATE OR REPLACE FUNCTION populate_sale_item_details()
RETURNS TRIGGER AS $$
DECLARE
    r_prod RECORD;
    v_branch_id UUID;
    v_tenant_id UUID;
BEGIN
    -- Get product details from catalog
    SELECT p.name, p.barcode as sku, p.category_id, c.name as category_name
    INTO r_prod
    FROM public.products p
    LEFT JOIN public.categories c ON c.id = p.category_id
    WHERE p.id = NEW.product_id;

    -- Get transaction context from Sale or Order
    IF NEW.sale_id IS NOT NULL THEN
        SELECT branch_id, tenant_id INTO v_branch_id, v_tenant_id FROM public.sales WHERE id = NEW.sale_id;
    ELSIF NEW.order_id IS NOT NULL THEN
        SELECT branch_id, tenant_id INTO v_branch_id, v_tenant_id FROM public.orders WHERE id = NEW.order_id;
    END IF;

    -- Populate metadata snapshots if product found
    IF r_prod IS NOT NULL THEN
        NEW.product_name := COALESCE(NEW.product_name, r_prod.name);
        NEW.product_sku := COALESCE(NEW.product_sku, r_prod.sku);
        NEW.category_id := COALESCE(NEW.category_id, r_prod.category_id);
        NEW.category_name := COALESCE(NEW.category_name, r_prod.category_name);
        NEW.unit_of_measure := COALESCE(NEW.unit_of_measure, 'piece');
    END IF;

    -- Populate tenant and branch
    NEW.tenant_id := COALESCE(NEW.tenant_id, v_tenant_id);
    NEW.branch_id := COALESCE(NEW.branch_id, v_branch_id);

    -- Cost & Profit Calculation
    IF NEW.unit_cost IS NOT NULL THEN
        NEW.total_cost := NEW.unit_cost * NEW.quantity;
        NEW.gross_profit := NEW.subtotal - NEW.total_cost;
        IF NEW.subtotal > 0 THEN
            NEW.profit_margin := (NEW.gross_profit / NEW.subtotal) * 100;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 5. TRIGGER: Enable Trigger
DROP TRIGGER IF EXISTS trg_populate_sale_item_details ON public.sale_items;
CREATE TRIGGER trg_populate_sale_item_details
    BEFORE INSERT OR UPDATE ON public.sale_items
    FOR EACH ROW
    EXECUTE FUNCTION populate_sale_item_details();

-- End of 20260419143000_unify_transaction_items.sql


-- File: 20260419200000_update_checkout_rpc_for_unified_items.sql
-- ============================================================
-- Migration: Update Checkout RPC for Unified sale_items Table
-- Description: Rewrites checkout_storefront_order and cancel_storefront_order
--              to use the unified sale_items table instead of the dropped order_items.
-- ============================================================

-- 1. Add batch_allocations to sale_items (used by online orders for stock reservation rollback on cancel)
ALTER TABLE public.sale_items
    ADD COLUMN IF NOT EXISTS batch_allocations JSONB DEFAULT '[]'::jsonb;

COMMENT ON COLUMN public.sale_items.batch_allocations IS
    'For online orders: stores FIFO batch reservation details [{batch_id, quantity}] to allow accurate stock release on cancellation.';

-- 2. Drop old RPC signatures to avoid conflicts
DROP FUNCTION IF EXISTS checkout_storefront_order(UUID, UUID, UUID, order_type, fulfillment_type, DECIMAL, DECIMAL, DECIMAL, DECIMAL, UUID, TEXT, JSONB);
DROP FUNCTION IF EXISTS cancel_storefront_order(UUID);

-- 3. Recreate checkout_storefront_order â€” now inserts into sale_items
CREATE OR REPLACE FUNCTION checkout_storefront_order(
    p_tenant_id UUID,
    p_branch_id UUID,
    p_customer_id UUID,
    p_order_type order_type,
    p_fulfillment_type fulfillment_type,
    p_subtotal DECIMAL,
    p_delivery_fee DECIMAL,
    p_tax_amount DECIMAL,
    p_total_amount DECIMAL,
    p_delivery_address_id UUID,
    p_special_instructions TEXT,
    p_items JSONB -- Array of { product_id, product_name, quantity, unit_price, subtotal }
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_order_id UUID;
    v_item RECORD;
    v_batch RECORD;
    v_req_qty INTEGER;
    v_available_qty INTEGER;
    v_allocated_qty INTEGER;
    v_allocations JSONB;
    v_primary_batch_id UUID;
BEGIN
    -- Validate totals
    IF p_total_amount != (p_subtotal + p_delivery_fee + p_tax_amount) THEN
        RAISE EXCEPTION 'Total amount does not match subtotal + fees + tax';
    END IF;

    -- Create the order header
    INSERT INTO orders (
        tenant_id, branch_id, order_number, customer_id,
        order_type, order_status, payment_status,
        subtotal, delivery_fee, tax_amount, total_amount,
        fulfillment_type, delivery_address_id, special_instructions
    ) VALUES (
        p_tenant_id,
        p_branch_id,
        'ORD-' || FLOOR(EXTRACT(EPOCH FROM NOW()))::TEXT || '-' || SUBSTRING(MD5(RANDOM()::TEXT) FROM 1 FOR 4),
        p_customer_id,
        p_order_type,
        'pending'::order_status,
        'unpaid'::payment_status,
        p_subtotal, p_delivery_fee, p_tax_amount, p_total_amount,
        p_fulfillment_type,
        p_delivery_address_id,
        p_special_instructions
    ) RETURNING id INTO v_order_id;

    -- Process each item: FIFO batch allocation + insert into sale_items
    FOR v_item IN SELECT * FROM jsonb_to_recordset(p_items) AS x(
        product_id UUID, product_name TEXT, quantity INTEGER, unit_price DECIMAL, subtotal DECIMAL
    )
    LOOP
        v_req_qty := v_item.quantity;
        v_allocations := '[]'::jsonb;
        v_primary_batch_id := NULL;

        -- FIFO batch allocation (locks rows to prevent race conditions)
        FOR v_batch IN 
            SELECT id, (stock_quantity - COALESCE(reserved_quantity, 0)) AS available_balance
            FROM branch_inventory
            WHERE branch_id = p_branch_id 
              AND product_id = v_item.product_id 
              AND is_active = true
              AND (stock_quantity - COALESCE(reserved_quantity, 0)) > 0
            ORDER BY expiry_date ASC NULLS LAST, created_at ASC
            FOR UPDATE
        LOOP
            IF v_req_qty <= 0 THEN EXIT; END IF;

            v_available_qty := v_batch.available_balance;
            v_allocated_qty := LEAST(v_available_qty, v_req_qty);

            -- Reserve stock in the batch
            UPDATE branch_inventory
            SET reserved_quantity = COALESCE(reserved_quantity, 0) + v_allocated_qty,
                updated_at = NOW()
            WHERE id = v_batch.id;

            -- Track the primary batch (first FIFO batch) for inventory_id
            IF v_primary_batch_id IS NULL THEN
                v_primary_batch_id := v_batch.id;
            END IF;

            v_allocations := v_allocations || jsonb_build_object(
                'batch_id', v_batch.id,
                'quantity', v_allocated_qty
            );

            v_req_qty := v_req_qty - v_allocated_qty;
        END LOOP;

        -- Raise if stock was insufficient
        IF v_req_qty > 0 THEN
            RAISE EXCEPTION 'Insufficient stock for product: % (short by %)', v_item.product_name, v_req_qty;
        END IF;

        -- Insert into unified sale_items (trigger will auto-populate cost/profit/category)
        INSERT INTO public.sale_items (
            tenant_id,
            order_id,
            branch_id,
            inventory_id,
            product_id,
            product_name,
            quantity,
            unit_price,
            subtotal,
            discount_amount,
            batch_allocations
        ) VALUES (
            p_tenant_id,
            v_order_id,
            p_branch_id,
            v_primary_batch_id,
            v_item.product_id,
            v_item.product_name,
            v_item.quantity,
            v_item.unit_price,
            v_item.subtotal,
            0,
            v_allocations
        );
    END LOOP;

    RETURN v_order_id;
END;
$$;


-- 4. Recreate cancel_storefront_order â€” now reads from sale_items
CREATE OR REPLACE FUNCTION cancel_storefront_order(
    p_order_id UUID
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_order_status order_status;
    v_item RECORD;
    v_allocation RECORD;
BEGIN
    -- Use subquery assignment to avoid SELECT INTO relation confusion
    v_order_status := (SELECT order_status FROM orders WHERE id = p_order_id LIMIT 1);

    IF v_order_status IS NULL THEN
        RAISE EXCEPTION 'Order not found';
    END IF;

    IF v_order_status = 'delivered'::order_status THEN
        RAISE EXCEPTION 'Cannot cancel an order that has already been delivered';
    END IF;

    IF v_order_status = 'cancelled'::order_status THEN
        RAISE EXCEPTION 'Order is already cancelled';
    END IF;

    -- Cancel the order
    UPDATE orders 
    SET order_status = 'cancelled'::order_status, updated_at = NOW()
    WHERE id = p_order_id;

    -- Release reserved stock using batch_allocations from sale_items
    FOR v_item IN SELECT batch_allocations FROM public.sale_items WHERE order_id = p_order_id
    LOOP
        FOR v_allocation IN 
            SELECT * FROM jsonb_to_recordset(v_item.batch_allocations) AS x(batch_id UUID, quantity INTEGER)
        LOOP
            UPDATE branch_inventory
            SET reserved_quantity = GREATEST(COALESCE(reserved_quantity, 0) - v_allocation.quantity, 0),
                updated_at = NOW()
            WHERE id = v_allocation.batch_id;
        END LOOP;
    END LOOP;

    RETURN TRUE;
END;
$$;

-- End of 20260419200000_update_checkout_rpc_for_unified_items.sql


-- File: 20260419210000_sale_items_rls_and_trigger_fix.sql
-- ============================================================
-- Migration: RLS Policies and Corrected Trigger for Unified sale_items
-- Description: Adds RLS policies for the recreated sale_items table
--              and corrects the populate_sale_item_details trigger to
--              match the actual live products table schema.
-- ============================================================

-- 1. Enable RLS
ALTER TABLE public.sale_items ENABLE ROW LEVEL SECURITY;

-- 2. INSERT â€” any authenticated user of the same tenant
CREATE POLICY "sale_items_insert_own_tenant"
ON public.sale_items FOR INSERT TO authenticated
WITH CHECK (
    tenant_id IN (SELECT tenant_id FROM public.users WHERE id = auth.uid())
);

-- 3. SELECT â€” any authenticated user of the same tenant
CREATE POLICY "sale_items_select_own_tenant"
ON public.sale_items FOR SELECT TO authenticated
USING (
    tenant_id IN (SELECT tenant_id FROM public.users WHERE id = auth.uid())
);

-- 4. UPDATE â€” any authenticated user of the same tenant
CREATE POLICY "sale_items_update_own_tenant"
ON public.sale_items FOR UPDATE TO authenticated
USING (
    tenant_id IN (SELECT tenant_id FROM public.users WHERE id = auth.uid())
);

-- 5. DELETE â€” tenant admins and managers only
CREATE POLICY "sale_items_delete_managers"
ON public.sale_items FOR DELETE TO authenticated
USING (
    tenant_id IN (
        SELECT tenant_id FROM public.users
        WHERE id = auth.uid()
        AND role IN ('tenant_admin', 'branch_manager', 'platform_admin')
    )
);

-- 6. Corrected trigger function â€” matches actual live products table schema
--    (products has: name, barcode, category_id â€” NO sku, cost_price, unit_of_measure)
CREATE OR REPLACE FUNCTION populate_sale_item_details()
RETURNS TRIGGER AS $$
DECLARE
    v_prod_name     VARCHAR;
    v_prod_barcode  VARCHAR;
    v_prod_cat_id   UUID;
    v_prod_cat_name VARCHAR;
    v_branch_id     UUID;
    v_tenant_id     UUID;
BEGIN
    v_prod_name    := (SELECT p.name        FROM public.products p WHERE p.id = NEW.product_id LIMIT 1);
    v_prod_barcode := (SELECT p.barcode     FROM public.products p WHERE p.id = NEW.product_id LIMIT 1);
    v_prod_cat_id  := (SELECT p.category_id FROM public.products p WHERE p.id = NEW.product_id LIMIT 1);

    IF v_prod_cat_id IS NOT NULL THEN
        v_prod_cat_name := (SELECT c.name FROM public.categories c WHERE c.id = v_prod_cat_id LIMIT 1);
    END IF;

    IF NEW.sale_id IS NOT NULL THEN
        v_branch_id := (SELECT s.branch_id FROM public.sales s WHERE s.id = NEW.sale_id LIMIT 1);
        v_tenant_id := (SELECT s.tenant_id FROM public.sales s WHERE s.id = NEW.sale_id LIMIT 1);
    ELSIF NEW.order_id IS NOT NULL THEN
        v_branch_id := (SELECT o.branch_id FROM public.orders o WHERE o.id = NEW.order_id LIMIT 1);
        v_tenant_id := (SELECT o.tenant_id FROM public.orders o WHERE o.id = NEW.order_id LIMIT 1);
    END IF;

    NEW.tenant_id       := COALESCE(NEW.tenant_id,       v_tenant_id);
    NEW.branch_id       := COALESCE(NEW.branch_id,       v_branch_id);
    NEW.product_name    := COALESCE(NEW.product_name,    v_prod_name);
    NEW.product_sku     := COALESCE(NEW.product_sku,     v_prod_barcode);
    NEW.category_id     := COALESCE(NEW.category_id,     v_prod_cat_id);
    NEW.category_name   := COALESCE(NEW.category_name,   v_prod_cat_name);
    NEW.unit_of_measure := COALESCE(NEW.unit_of_measure, 'piece');

    -- Cost & profit only if unit_cost is explicitly provided
    IF NEW.unit_cost IS NOT NULL THEN
        NEW.total_cost    := NEW.unit_cost * NEW.quantity;
        NEW.gross_profit  := NEW.subtotal - NEW.total_cost;
        IF NEW.subtotal > 0 THEN
            NEW.profit_margin := (NEW.gross_profit / NEW.subtotal) * 100;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- End of 20260419210000_sale_items_rls_and_trigger_fix.sql


-- File: 20260420100000_add_pom_flag.sql
-- Migration: Add isPOM flag to products and branch_inventory
-- Description: Standardizes the Prescription Only Medicine flag for visibility control.

-- 1. Update products table
ALTER TABLE public.products 
ADD COLUMN IF NOT EXISTS "isPOM" boolean NOT NULL DEFAULT false;

-- 2. Update branch_inventory table
ALTER TABLE public.branch_inventory 
ADD COLUMN IF NOT EXISTS "isPOM" boolean NOT NULL DEFAULT false;

-- 3. Update indices for optimized storefront queries
CREATE INDEX IF NOT EXISTS idx_branch_inventory_not_pom ON public.branch_inventory (tenant_id, branch_id) 
WHERE ("isPOM" = false AND is_active = true AND _sync_is_deleted = false);

CREATE INDEX IF NOT EXISTS idx_products_not_pom ON public.products (is_active) 
WHERE ("isPOM" = false AND deleted_at IS NULL);

-- End of 20260420100000_add_pom_flag.sql


-- File: 20260422000002_fix_doctor_aliases_final_rls.sql
-- Unified RLS Policies for Doctor Aliases
-- Allows both Clinical (Primary Doctors) and Pharmacy (Tenants) partners to manage relationships.

-- 1. DROP OLD POLICIES
DROP POLICY IF EXISTS "Primary doctor sees consultants" ON public.doctor_aliases;
DROP POLICY IF EXISTS "Consultant sees own alias" ON public.doctor_aliases;
DROP POLICY IF EXISTS "Primary doctor can invite consultants" ON public.doctor_aliases;
DROP POLICY IF EXISTS "Primary doctor can update consultants" ON public.doctor_aliases;
DROP POLICY IF EXISTS "Primary doctor can delete consultants" ON public.doctor_aliases;
DROP POLICY IF EXISTS "Public can see active consultants" ON public.doctor_aliases;
DROP POLICY IF EXISTS "Tenants can invite partners" ON public.doctor_aliases;

-- 2. CREATE UNIFIED POLICIES

-- SELECT: Allow stakeholders and public (if accepted)
CREATE POLICY "Select doctor aliases" ON public.doctor_aliases
FOR SELECT TO authenticated, anon
USING (
    -- Public can see accepted/active
    (accepted = true AND is_active = true) OR
    -- Owner/Partner can see all their records
    (
        auth.uid() IN (
            SELECT id FROM public.users 
            WHERE tenant_id = doctor_aliases.tenant_partner
        ) OR
        primary_doctor_id IN (
            SELECT id FROM public.healthcare_providers 
            WHERE user_id = auth.uid()
        ) OR
        doctor_id IN (
            SELECT id FROM public.healthcare_providers 
            WHERE user_id = auth.uid()
        )
    )
);

-- INSERT: Allow primary doctors or tenant admins/staff
CREATE POLICY "Insert doctor aliases" ON public.doctor_aliases
FOR INSERT TO authenticated
WITH CHECK (
    (
        tenant_partner IS NOT NULL AND
        tenant_partner IN (SELECT tenant_id FROM public.users WHERE id = auth.uid())
    ) OR
    (
        primary_doctor_id IS NOT NULL AND
        primary_doctor_id IN (SELECT id FROM public.healthcare_providers WHERE user_id = auth.uid())
    )
);

-- UPDATE: Allow the "inviter" (tenant or primary doctor)
CREATE POLICY "Update doctor aliases" ON public.doctor_aliases
FOR UPDATE TO authenticated
USING (
    (
        tenant_partner IS NOT NULL AND
        tenant_partner IN (SELECT tenant_id FROM public.users WHERE id = auth.uid())
    ) OR
    (
        primary_doctor_id IS NOT NULL AND
        primary_doctor_id IN (SELECT id FROM public.healthcare_providers WHERE user_id = auth.uid())
    )
)
WITH CHECK (
    (
        tenant_partner IS NOT NULL AND
        tenant_partner IN (SELECT tenant_id FROM public.users WHERE id = auth.uid())
    ) OR
    (
        primary_doctor_id IS NOT NULL AND
        primary_doctor_id IN (SELECT id FROM public.healthcare_providers WHERE user_id = auth.uid())
    )
);

-- DELETE: Allow the "inviter"
CREATE POLICY "Delete doctor aliases" ON public.doctor_aliases
FOR DELETE TO authenticated
USING (
    (
        tenant_partner IS NOT NULL AND
        tenant_partner IN (SELECT tenant_id FROM public.users WHERE id = auth.uid())
    ) OR
    (
        primary_doctor_id IS NOT NULL AND
        primary_doctor_id IN (SELECT id FROM public.healthcare_providers WHERE user_id = auth.uid())
    )
);

-- Ensure table has RLS enabled
ALTER TABLE public.doctor_aliases ENABLE ROW LEVEL SECURITY;

-- Refine grants
GRANT ALL ON public.doctor_aliases TO authenticated;
GRANT SELECT ON public.doctor_aliases TO anon;

-- End of 20260422000002_fix_doctor_aliases_final_rls.sql


-- File: 20260422000005_drop_can_manage_scrap.sql
-- Drop the unused canManageScrap privilege from staff permission tables
ALTER TABLE public.users 
DROP COLUMN IF EXISTS "canManageScrap";

ALTER TABLE public.staff_invitations 
DROP COLUMN IF EXISTS "canManageScrap";

-- End of 20260422000005_drop_can_manage_scrap.sql


-- File: 20260423000000_process_sale_return.sql
-- ============================================================
-- Migration: Process Sale Returns
-- Description: Adds RPC to safely process a sale return, updating sales table, sale_items table, and restoring inventory
-- ============================================================

CREATE OR REPLACE FUNCTION process_sale_return(
    p_sale_id UUID,
    p_items JSONB,
    p_staff_id UUID
) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_sale RECORD;
    v_item RECORD;
    v_batch_id UUID;
    v_return_value DECIMAL := 0;
    v_new_subtotal DECIMAL;
    v_new_total DECIMAL;
BEGIN
    -- 1. Fetch sale
    SELECT * INTO v_sale FROM sales WHERE id = p_sale_id FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Sale not found';
    END IF;

    -- 2. Process items
    FOR v_item IN SELECT * FROM jsonb_to_recordset(p_items) AS x(sale_item_id UUID, product_id UUID, return_qty INTEGER)
    LOOP
        -- Process only if return_qty > 0
        IF v_item.return_qty <= 0 THEN
            CONTINUE;
        END IF;

        DECLARE
            v_sale_item RECORD;
            v_previous_stock INTEGER;
            v_new_stock INTEGER;
            v_new_item_qty INTEGER;
            v_new_item_discount DECIMAL;
            v_new_item_subtotal DECIMAL;
        BEGIN
            -- Fetch sale_item
            SELECT * INTO v_sale_item FROM sale_items 
            WHERE id = v_item.sale_item_id AND sale_id = p_sale_id FOR UPDATE;

            IF NOT FOUND THEN
                RAISE EXCEPTION 'Sale item not found %', v_item.sale_item_id;
            END IF;

            IF v_item.return_qty > v_sale_item.quantity THEN
                RAISE EXCEPTION 'Return quantity exceeds purchased quantity';
            END IF;

            -- Calculate proportional refund value (before item update)
            v_return_value := v_return_value + (v_sale_item.unit_price * v_item.return_qty);

            -- Recalculate item fields to satisfy CHECK constraints
            v_new_item_qty := v_sale_item.quantity - v_item.return_qty;
            
            -- Proportional discount reduction
            IF v_sale_item.quantity > 0 THEN
                v_new_item_discount := (v_sale_item.discount_amount * v_new_item_qty) / v_sale_item.quantity;
            ELSE
                v_new_item_discount := 0;
            END IF;
            
            v_new_item_subtotal := (v_sale_item.unit_price * v_new_item_qty) - v_new_item_discount;

            -- Update sale_item with consistent values
            UPDATE public.sale_items 
            SET quantity = v_new_item_qty,
                discount_amount = v_new_item_discount,
                subtotal = v_new_item_subtotal
            WHERE id = v_item.sale_item_id;

            -- Find latest active batch assigned to this branch to restore inventory
            SELECT id INTO v_batch_id
            FROM branch_inventory
            WHERE branch_id = v_sale.branch_id AND product_id = v_item.product_id
            ORDER BY created_at DESC LIMIT 1 FOR UPDATE;

            -- Increment inventory and Log
            IF v_batch_id IS NOT NULL THEN
                -- Capture stock before incrementing
                SELECT stock_quantity INTO v_previous_stock FROM branch_inventory WHERE id = v_batch_id;
                v_new_stock := COALESCE(v_previous_stock, 0) + v_item.return_qty;

                UPDATE branch_inventory
                SET stock_quantity = v_new_stock,
                    updated_at = NOW()
                WHERE id = v_batch_id;

                -- Log transaction securely
                INSERT INTO inventory_transactions (
                    tenant_id, branch_id, product_id, transaction_type, 
                    quantity_delta, previous_quantity, new_quantity, reference_id, reference_type, staff_id, notes
                ) VALUES (
                    v_sale.tenant_id, v_sale.branch_id, v_item.product_id, 'adjustment',
                    v_item.return_qty, v_previous_stock, v_new_stock, p_sale_id, 'sale_return', 
                    p_staff_id, 'Item returned by customer and restored to inventory'
                );
            END IF;
        END;
    END LOOP;

    -- 3. Adjust Sale master totals
    v_new_subtotal := GREATEST(0, v_sale.subtotal - v_return_value);
    
    -- Adjust total_amount identically
    v_new_total := GREATEST(0, v_sale.total_amount - v_return_value);

    IF v_new_subtotal <= 0 THEN
        UPDATE sales 
        SET subtotal = 0, 
            total_amount = GREATEST(0, v_sale.total_amount - v_sale.subtotal), -- Keep tax if any? Or just 0
            sale_status = 'refunded',
            updated_at = NOW()
        WHERE id = p_sale_id;
    ELSE
        UPDATE sales 
        SET subtotal = v_new_subtotal, 
            total_amount = v_new_total,
            updated_at = NOW()
        WHERE id = p_sale_id;
    END IF;

END;
$$;

-- End of 20260423000000_process_sale_return.sql


-- File: 20260423000001_create_chat_storage.sql
-- Migration: Create Chat Attachments Storage
-- Purpose: Enable file uploads (images, PDFs, voice notes) for the chat system

-- 1. Create the bucket
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'chat-attachments',
    'chat-attachments',
    true, -- Publicly accessible (medical data should ideally be private, but for simplicity in storefront we use public URLs)
    10485760, -- 10MB limit
    ARRAY[
        'image/jpeg', 'image/png', 'image/webp', 'image/jpg', 'image/gif',
        'application/pdf',
        'audio/webm', 'audio/mpeg', 'audio/wav', 'audio/ogg', 'audio/mp4', 'audio/aac'
    ]
)
ON CONFLICT (id) DO NOTHING;

-- 2. Storage RLS Policies

-- Anyone can view chat attachments (needed for simple public URL sharing)
DROP POLICY IF EXISTS "Anyone can view chat attachments" ON storage.objects;
CREATE POLICY "Anyone can view chat attachments"
    ON storage.objects FOR SELECT
    TO public
    USING (bucket_id = 'chat-attachments');

-- Authenticated users can upload to their own chat folders
-- We use a folder structure: chat/{conversation_id}/{filename}
DROP POLICY IF EXISTS "Users can upload chat attachments" ON storage.objects;
CREATE POLICY "Users can upload chat attachments"
    ON storage.objects FOR INSERT
    TO authenticated
    WITH CHECK (
        bucket_id = 'chat-attachments' AND
        (storage.foldername(name))[1] = 'chat'
    );

-- Allow deletion by owner if needed (optional)
DROP POLICY IF EXISTS "Users can delete own chat attachments" ON storage.objects;
CREATE POLICY "Users can delete own chat attachments"
    ON storage.objects FOR DELETE
    TO authenticated
    USING (
        bucket_id = 'chat-attachments' AND
        (storage.foldername(name))[1] = 'chat'
    );

-- End of 20260423000001_create_chat_storage.sql


-- File: 20260423000002_enable_chat_typing_realtime.sql
-- Migration: Enable Real-time for Typing Indicators
-- Purpose: Support real-time typing indicators in the chat UI

-- 1. Enable real-time for the table
ALTER PUBLICATION supabase_realtime ADD TABLE chat_typing_indicators;

-- 2. Ensure RLS allows participants to manage their status
-- (Already handled by 20260418000001, but we ensure it's robust here)
DROP POLICY IF EXISTS "Participants can manage typing status" ON public.chat_typing_indicators;
CREATE POLICY "Participants can manage typing status"
ON public.chat_typing_indicators FOR ALL
USING (
    user_id = auth.uid() OR
    conversation_id IN (
        SELECT id FROM public.chat_conversations
        WHERE customer_id = auth.uid() OR 
              auth.uid() IN (SELECT user_id FROM public.healthcare_providers)
    )
);

-- 3. Add a function to automatically refresh expires_at on update
CREATE OR REPLACE FUNCTION refresh_typing_expiry()
RETURNS TRIGGER AS $$
BEGIN
    NEW.expires_at := NOW() + INTERVAL '10 seconds';
    NEW.updated_at := NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_refresh_typing_expiry ON public.chat_typing_indicators;
CREATE TRIGGER trigger_refresh_typing_expiry
    BEFORE UPDATE ON public.chat_typing_indicators
    FOR EACH ROW
    EXECUTE FUNCTION refresh_typing_expiry();

-- End of 20260423000002_enable_chat_typing_realtime.sql


-- File: 20260423010000_update_sale_items_schema.sql
-- ============================================================
-- Migration: Update sale_items with Batch Allocations and Final Constraints
-- Description: Adds missing columns and ensures the schema matches the requested state.
-- ============================================================

-- 1. Add missing columns safely
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'sale_items' AND column_name = 'batch_allocations') THEN
        ALTER TABLE public.sale_items ADD COLUMN batch_allocations jsonb DEFAULT '[]'::jsonb;
    END IF;
END $$;

-- 2. Update/Ensure Constraints
-- First drop existing ones to avoid conflicts if they were named differently
ALTER TABLE public.sale_items DROP CONSTRAINT IF EXISTS sale_items_subtotal_check;
ALTER TABLE public.sale_items DROP CONSTRAINT IF EXISTS valid_subtotal_logic;
ALTER TABLE public.sale_items DROP CONSTRAINT IF EXISTS sale_items_quantity_check;
ALTER TABLE public.sale_items DROP CONSTRAINT IF EXISTS sale_items_unit_price_check;

ALTER TABLE public.sale_items ADD CONSTRAINT sale_items_subtotal_check CHECK (subtotal >= 0);
ALTER TABLE public.sale_items ADD CONSTRAINT valid_subtotal_logic CHECK (subtotal = (unit_price * quantity) - discount_amount);
ALTER TABLE public.sale_items ADD CONSTRAINT sale_items_quantity_check CHECK (quantity > 0);
ALTER TABLE public.sale_items ADD CONSTRAINT sale_items_unit_price_check CHECK (unit_price > 0);

-- 3. Ensure Indexes match requested state
CREATE INDEX IF NOT EXISTS idx_sale_items_tenant_final ON public.sale_items USING btree (tenant_id);
CREATE INDEX IF NOT EXISTS idx_sale_items_branch_final ON public.sale_items USING btree (branch_id);
CREATE INDEX IF NOT EXISTS idx_sale_items_created_at_final ON public.sale_items USING btree (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_sale_items_category_final ON public.sale_items USING btree (category_id) WHERE (category_id IS NOT NULL);
CREATE INDEX IF NOT EXISTS idx_sale_items_product_final ON public.sale_items USING btree (product_id);
CREATE INDEX IF NOT EXISTS idx_sale_items_sale_order_final ON public.sale_items USING btree (sale_id, order_id);

-- 4. Trigger is already handled in 20260419210000_sale_items_rls_and_trigger_fix.sql
-- but we ensure it's still attached.
DROP TRIGGER IF EXISTS trg_populate_sale_item_details ON public.sale_items;
CREATE TRIGGER trg_populate_sale_item_details
    BEFORE INSERT OR UPDATE ON public.sale_items
    FOR EACH ROW
    EXECUTE FUNCTION populate_sale_item_details();

-- End of 20260423010000_update_sale_items_schema.sql


-- File: 20260424000000_add_chat_type_to_conversations.sql
-- Add chatType column to chat_conversations
ALTER TABLE public.chat_conversations 
ADD COLUMN IF NOT EXISTS "chatType" text DEFAULT 'Customer Support' 
CHECK ("chatType" IN ('Customer Support', 'Consultation'));

-- End of 20260424000000_add_chat_type_to_conversations.sql


-- File: 20260424000001_fix_unified_patient_rls.sql
-- ============================================================
-- Fix RLS Policies for Unified Patient Profiles
-- ============================================================
-- Purpose: Allow authenticated users to create their unified profiles and links
-- during the signup or first-time login flow.

-- 1. Unified Patient Profiles
DROP POLICY IF EXISTS "Allow authenticated insert for unified profile" ON unified_patient_profiles;
CREATE POLICY "Allow authenticated insert for unified profile"
ON unified_patient_profiles FOR INSERT
TO authenticated
WITH CHECK (true);

-- 2. Patient Account Links
DROP POLICY IF EXISTS "Users can insert own account links" ON patient_account_links;
CREATE POLICY "Users can insert own account links"
ON patient_account_links FOR INSERT
TO authenticated
WITH CHECK (customer_id = auth.uid());

-- 3. Cross-Tenant Consents
DROP POLICY IF EXISTS "Users can insert own consents" ON cross_tenant_consents;
CREATE POLICY "Users can insert own consents"
ON cross_tenant_consents FOR INSERT
TO authenticated
WITH CHECK (true);

-- Also ensure the SECURITY DEFINER functions are owned by a role that can bypass RLS if possible,
-- but adding policies is safer for general compatibility.

-- End of 20260424000001_fix_unified_patient_rls.sql


-- File: 20260424000002_add_metadata_to_chat_conversations.sql
-- Add metadata column to chat_conversations
ALTER TABLE public.chat_conversations 
ADD COLUMN IF NOT EXISTS metadata JSONB DEFAULT '{}'::jsonb;

-- Add metadata column to chat_messages
ALTER TABLE public.chat_messages 
ADD COLUMN IF NOT EXISTS metadata JSONB DEFAULT '{}'::jsonb;


-- End of 20260424000002_add_metadata_to_chat_conversations.sql


-- File: 20260424000003_fix_chat_insert_rls.sql
-- Allow authenticated customers to create conversations
DROP POLICY IF EXISTS "Customers can create conversations" ON public.chat_conversations;
CREATE POLICY "Customers can create conversations"
ON public.chat_conversations FOR INSERT
TO authenticated
WITH CHECK (customer_id = auth.uid());

-- End of 20260424000003_fix_chat_insert_rls.sql


-- File: 20260425223000_add_location_columns_to_branches.sql
-- Add missing location columns to branches table
ALTER TABLE public.branches
ADD COLUMN IF NOT EXISTS latitude DECIMAL(10,8) CHECK (latitude >= -90 AND latitude <= 90),
ADD COLUMN IF NOT EXISTS longitude DECIMAL(11,8) CHECK (longitude >= -180 AND longitude <= 180);

-- Also add state, city, country if they are somehow missing
ALTER TABLE public.branches
ADD COLUMN IF NOT EXISTS city VARCHAR(255),
ADD COLUMN IF NOT EXISTS state VARCHAR(255),
ADD COLUMN IF NOT EXISTS country VARCHAR(255);

-- End of 20260425223000_add_location_columns_to_branches.sql


-- File: 20260427000000_create_clock_out_rpc.sql
-- ============================================================
-- Migration 20260427000000: Create Clock Out RPC and Attendance RLS
-- ============================================================

-- RLS Policies for staff_attendance
CREATE POLICY "Staff can view own attendance" ON staff_attendance
    FOR SELECT USING (staff_id = auth.uid());

CREATE POLICY "Managers can view branch attendance" ON staff_attendance
    FOR SELECT USING (
        current_user_role() IN ('tenant_admin', 'branch_manager') AND
        tenant_id = current_tenant_id() AND 
        (current_user_role() = 'tenant_admin' OR branch_id = current_user_branch_id())
    );

CREATE POLICY "Staff can insert own attendance" ON staff_attendance
    FOR INSERT WITH CHECK (
        staff_id = auth.uid() AND
        tenant_id = current_tenant_id()
    );

CREATE POLICY "Staff can update own attendance" ON staff_attendance
    FOR UPDATE USING (
        staff_id = auth.uid()
    ) WITH CHECK (
        staff_id = auth.uid()
    );

-- Clock Out RPC
CREATE OR REPLACE FUNCTION clock_out_staff(p_attendance_id UUID)
RETURNS staff_attendance AS $$
DECLARE
    v_attendance staff_attendance;
BEGIN
    UPDATE staff_attendance
    SET 
        clock_out_at = NOW(),
        total_hours = EXTRACT(EPOCH FROM (NOW() - clock_in_at)) / 3600
    WHERE id = p_attendance_id
      AND clock_out_at IS NULL
    RETURNING * INTO v_attendance;

    RETURN v_attendance;
END;
$$ LANGUAGE plpgsql SECURITY INVOKER;

-- End of 20260427000000_create_clock_out_rpc.sql


-- File: 20260427000001_create_branch_shifts.sql
-- ============================================================
-- Migration 20260427000001: Create Branch Shifts and Update Attendance
-- ============================================================

CREATE TABLE branch_shifts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
    shift_name VARCHAR(255) NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    grace_period_minutes INTEGER DEFAULT 0 CHECK (grace_period_minutes >= 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT valid_shift_times CHECK (start_time != end_time)
);

-- RLS policies for branch_shifts
ALTER TABLE branch_shifts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Staff can view branch shifts" ON branch_shifts
    FOR SELECT USING (tenant_id = current_tenant_id());

CREATE POLICY "Managers can manage branch shifts" ON branch_shifts
    FOR ALL USING (
        current_user_role() IN ('tenant_admin', 'branch_manager') AND
        tenant_id = current_tenant_id()
    );

-- Alter staff_attendance
ALTER TABLE staff_attendance
ADD COLUMN IF NOT EXISTS shift_id UUID REFERENCES branch_shifts(id) ON DELETE SET NULL,
ADD COLUMN IF NOT EXISTS shift_status VARCHAR(50) DEFAULT 'on_time' CHECK (shift_status IN ('on_time', 'late', 'out_of_schedule'));

-- Update trigger for updated_at
CREATE TRIGGER set_updated_at BEFORE UPDATE ON branch_shifts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- End of 20260427000001_create_branch_shifts.sql


-- File: 20260427000002_fix_staff_attendance_rls.sql
-- ============================================================
-- Migration 20260427000002: Fix Staff Attendance RLS
-- ============================================================

-- Ensure the policies exist (in case the first migration was missed or failed)
DROP POLICY IF EXISTS "Staff can view own attendance" ON staff_attendance;
CREATE POLICY "Staff can view own attendance" ON staff_attendance
    FOR SELECT USING (staff_id = auth.uid());

DROP POLICY IF EXISTS "Managers can view branch attendance" ON staff_attendance;
CREATE POLICY "Managers can view branch attendance" ON staff_attendance
    FOR SELECT USING (
        current_user_role() IN ('tenant_admin', 'branch_manager') AND
        tenant_id = current_tenant_id() AND 
        (current_user_role() = 'tenant_admin' OR branch_id = current_user_branch_id())
    );

DROP POLICY IF EXISTS "Staff can insert own attendance" ON staff_attendance;
CREATE POLICY "Staff can insert own attendance" ON staff_attendance
    FOR INSERT WITH CHECK (
        staff_id = auth.uid() AND
        tenant_id = current_tenant_id()
    );

DROP POLICY IF EXISTS "Staff can update own attendance" ON staff_attendance;
CREATE POLICY "Staff can update own attendance" ON staff_attendance
    FOR UPDATE USING (
        staff_id = auth.uid()
    ) WITH CHECK (
        staff_id = auth.uid()
    );

-- Clock Out RPC (Redefining it here just to be safe)
CREATE OR REPLACE FUNCTION clock_out_staff(p_attendance_id UUID)
RETURNS staff_attendance AS $$
DECLARE
    v_attendance staff_attendance;
BEGIN
    UPDATE staff_attendance
    SET 
        clock_out_at = NOW(),
        total_hours = EXTRACT(EPOCH FROM (NOW() - clock_in_at)) / 3600
    WHERE id = p_attendance_id
      AND clock_out_at IS NULL
    RETURNING * INTO v_attendance;

    RETURN v_attendance;
END;
$$ LANGUAGE plpgsql SECURITY INVOKER;

-- End of 20260427000002_fix_staff_attendance_rls.sql


-- File: 20260428131000_populate_sale_item_names.sql
-- ============================================================
-- Migration: Populate Sale Item Names
-- Description: Updates the populate_sale_item_details function to fetch and snapshot
--              customer_name, cashier_name, and healthcare_provider_name.
-- ============================================================

CREATE OR REPLACE FUNCTION populate_sale_item_details()
RETURNS TRIGGER AS $$
DECLARE
    r_prod RECORD;
    v_branch_id UUID;
    v_tenant_id UUID;
    v_customer_id UUID;
    v_cashier_id UUID;
    v_customer_name TEXT;
    v_cashier_name TEXT;
    v_provider_name TEXT;
BEGIN
    -- 1. Get product details from catalog
    SELECT p.name, p.barcode as sku, p.category_id, c.name as category_name
    INTO r_prod
    FROM public.products p
    LEFT JOIN public.categories c ON c.id = p.category_id
    WHERE p.id = NEW.product_id;

    -- 2. Get transaction context from Sale or Order if IDs are missing in NEW
    IF NEW.sale_id IS NOT NULL THEN
        SELECT 
            branch_id, tenant_id, customer_id, cashier_id, customer_name
        INTO 
            v_branch_id, v_tenant_id, v_customer_id, v_cashier_id, v_customer_name
        FROM public.sales WHERE id = NEW.sale_id;
    ELSIF NEW.order_id IS NOT NULL THEN
        SELECT 
            branch_id, tenant_id, customer_id
        INTO 
            v_branch_id, v_tenant_id, v_customer_id
        FROM public.orders WHERE id = NEW.order_id;
    END IF;

    -- 3. Consolidate IDs (Priority: NEW > Context from Sale/Order)
    NEW.tenant_id := COALESCE(NEW.tenant_id, v_tenant_id);
    NEW.branch_id := COALESCE(NEW.branch_id, v_branch_id);
    NEW.customer_id := COALESCE(NEW.customer_id, v_customer_id);
    NEW.cashier_id := COALESCE(NEW.cashier_id, v_cashier_id);

    -- 4. Fetch Names for the consolidated IDs if they aren't already provided in NEW
    -- Customer Name
    IF NEW.customer_name IS NULL THEN
        IF NEW.customer_id IS NOT NULL THEN
            SELECT full_name INTO v_customer_name FROM public.customers WHERE id = NEW.customer_id;
            NEW.customer_name := v_customer_name;
        END IF;
        -- Fallback to the name on the sale record if customer_id doesn't yield a name (e.g. walk-in)
        IF NEW.customer_name IS NULL THEN
            NEW.customer_name := v_customer_name; -- This v_customer_name came from the sales table SELECT above
        END IF;
    END IF;

    -- Cashier Name
    IF NEW.cashier_name IS NULL AND NEW.cashier_id IS NOT NULL THEN
        SELECT full_name INTO v_cashier_name FROM public.users WHERE id = NEW.cashier_id;
        NEW.cashier_name := v_cashier_name;
    END IF;

    -- Healthcare Provider Name
    IF NEW.healthcare_provider_name IS NULL AND NEW.health_care_provider IS NOT NULL THEN
        SELECT full_name INTO v_provider_name FROM public.healthcare_providers WHERE id = NEW.health_care_provider;
        NEW.healthcare_provider_name := v_provider_name;
    END IF;

    -- 5. Populate metadata snapshots for product
    IF r_prod IS NOT NULL THEN
        NEW.product_name := COALESCE(NEW.product_name, r_prod.name);
        NEW.product_sku := COALESCE(NEW.product_sku, r_prod.sku);
        NEW.category_id := COALESCE(NEW.category_id, r_prod.category_id);
        NEW.category_name := COALESCE(NEW.category_name, r_prod.category_name);
        NEW.unit_of_measure := COALESCE(NEW.unit_of_measure, 'piece');

        -- 5b. Fetch unit_cost from branch_inventory if missing
        IF NEW.unit_cost IS NULL AND NEW.inventory_id IS NOT NULL THEN
            SELECT cost_price INTO NEW.unit_cost FROM public.branch_inventory WHERE id = NEW.inventory_id;
        END IF;
    END IF;

    -- 6. Cost & Profit Calculation
    IF NEW.unit_cost IS NOT NULL THEN
        NEW.total_cost := NEW.unit_cost * NEW.quantity;
        NEW.gross_profit := NEW.subtotal - NEW.total_cost;
        IF NEW.subtotal > 0 THEN
            NEW.profit_margin := (NEW.gross_profit / NEW.subtotal) * 100;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- End of 20260428131000_populate_sale_item_names.sql


-- File: 20260428133000_fix_users_typos.sql
-- ============================================================
-- Migration: Fix Users Table Typos
-- Description: Renames misspelled columns in the users table to align with the codebase
--              and staff_invitations table.
-- ============================================================

ALTER TABLE public.users RENAME COLUMN "canMangeStaff" TO "canManageStaff";
ALTER TABLE public.users RENAME COLUMN "canReferToDoctor" TO "canReferDoctor";

-- End of 20260428133000_fix_users_typos.sql


-- File: 20260428140000_fix_customer_schema.sql
-- Migration: Fix Customer Schema
-- Description: Adds missing columns to the customers table to match the POS frontend requirements.

ALTER TABLE public.customers
ADD COLUMN IF NOT EXISTS first_name VARCHAR(255),
ADD COLUMN IF NOT EXISTS last_name VARCHAR(255),
ADD COLUMN IF NOT EXISTS address TEXT,
ADD COLUMN IF NOT EXISTS date_of_birth DATE,
ADD COLUMN IF NOT EXISTS notes TEXT,
ADD COLUMN IF NOT EXISTS loyalty_points INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS total_spent DECIMAL(12,2) DEFAULT 0;

-- Simple index for address search
CREATE INDEX IF NOT EXISTS idx_customers_address_search ON public.customers(address) WHERE address IS NOT NULL;

-- Trigger to automatically update full_name from first_name and last_name
CREATE OR REPLACE FUNCTION update_customer_full_name()
RETURNS TRIGGER AS $$
BEGIN
    NEW.full_name := TRIM(CONCAT(NEW.first_name, ' ', NEW.last_name));
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_customer_full_name ON public.customers;
CREATE TRIGGER trigger_update_customer_full_name
    BEFORE INSERT OR UPDATE OF first_name, last_name ON public.customers
    FOR EACH ROW
    EXECUTE FUNCTION update_customer_full_name();

-- End of 20260428140000_fix_customer_schema.sql


-- File: 20260428150000_relax_sale_total_constraint.sql
-- Migration: Relax Sale Total Constraint
-- Description: Changes total_amount check from > 0 to >= 0 to support full returns/refunds.

-- 1. Drop the existing strict constraint
-- The error message confirmed the name is 'sales_total_amount_check'
ALTER TABLE public.sales DROP CONSTRAINT IF EXISTS sales_total_amount_check;

-- 2. Add the relaxed constraint
ALTER TABLE public.sales ADD CONSTRAINT sales_total_amount_check CHECK (total_amount >= 0);

-- 3. Update the item-level quantity constraint if necessary
-- (Currently sale_items.quantity > 0, which is correct as we delete or zero-out items)
-- But in the RPC, we set quantity to 0 for returned items.
-- Let's check sale_items quantity constraint.
ALTER TABLE public.sale_items DROP CONSTRAINT IF EXISTS sale_items_quantity_check;
ALTER TABLE public.sale_items ADD CONSTRAINT sale_items_quantity_check CHECK (quantity >= 0);

-- End of 20260428150000_relax_sale_total_constraint.sql


-- File: 20260428160000_expand_user_roles.sql
-- Migration: Expand User Roles
-- Description: Adds 'pharmacist' and 'doctor' to the user_role enum.

-- Using individual statements as ADD VALUE often fails inside DO blocks or multi-statement transactions
ALTER TYPE public.user_role ADD VALUE IF NOT EXISTS 'pharmacist';
ALTER TYPE public.user_role ADD VALUE IF NOT EXISTS 'doctor';

-- End of 20260428160000_expand_user_roles.sql


-- File: 20260429184500_update_sale_item_population_logic.sql
-- ============================================================
-- Migration: Update Sale Item Population Logic
-- Description: Updates the populate_sale_item_details function to fetch and snapshot
--              city, state, country (from branch) and generic_name (from product).
-- ============================================================

CREATE OR REPLACE FUNCTION populate_sale_item_details()
RETURNS TRIGGER AS $$
DECLARE
    r_prod RECORD;
    v_branch_id UUID;
    v_tenant_id UUID;
    v_customer_id UUID;
    v_cashier_id UUID;
    v_customer_name TEXT;
    v_cashier_name TEXT;
    v_provider_name TEXT;
    v_city TEXT;
    v_state TEXT;
    v_country TEXT;
BEGIN
    -- 1. Get product details from catalog (including generic_name)
    SELECT p.name, p.barcode as sku, p.category_id, c.name as category_name, p.generic_name
    INTO r_prod
    FROM public.products p
    LEFT JOIN public.categories c ON c.id = p.category_id
    WHERE p.id = NEW.product_id;

    -- 2. Get transaction context from Sale or Order if IDs are missing in NEW
    IF NEW.sale_id IS NOT NULL THEN
        SELECT 
            branch_id, tenant_id, customer_id, cashier_id, customer_name
        INTO 
            v_branch_id, v_tenant_id, v_customer_id, v_cashier_id, v_customer_name
        FROM public.sales WHERE id = NEW.sale_id;
    ELSIF NEW.order_id IS NOT NULL THEN
        SELECT 
            branch_id, tenant_id, customer_id
        INTO 
            v_branch_id, v_tenant_id, v_customer_id
        FROM public.orders WHERE id = NEW.order_id;
    END IF;

    -- 3. Consolidate IDs (Priority: NEW > Context from Sale/Order)
    NEW.tenant_id := COALESCE(NEW.tenant_id, v_tenant_id);
    NEW.branch_id := COALESCE(NEW.branch_id, v_branch_id);
    NEW.customer_id := COALESCE(NEW.customer_id, v_customer_id);
    NEW.cashier_id := COALESCE(NEW.cashier_id, v_cashier_id);

    -- 4. Fetch Names and Locations for the consolidated IDs
    -- Customer Name
    IF NEW.customer_name IS NULL THEN
        IF NEW.customer_id IS NOT NULL THEN
            SELECT full_name INTO v_customer_name FROM public.customers WHERE id = NEW.customer_id;
            NEW.customer_name := v_customer_name;
        END IF;
        -- Fallback to the name on the sale record if customer_id doesn't yield a name (e.g. walk-in)
        IF NEW.customer_name IS NULL THEN
            NEW.customer_name := v_customer_name; 
        END IF;
    END IF;

    -- Cashier Name
    IF NEW.cashier_name IS NULL AND NEW.cashier_id IS NOT NULL THEN
        SELECT full_name INTO v_cashier_name FROM public.users WHERE id = NEW.cashier_id;
        NEW.cashier_name := v_cashier_name;
    END IF;

    -- Healthcare Provider Name
    IF NEW.healthcare_provider_name IS NULL AND NEW.health_care_provider IS NOT NULL THEN
        SELECT full_name INTO v_provider_name FROM public.healthcare_providers WHERE id = NEW.health_care_provider;
        NEW.healthcare_provider_name := v_provider_name;
    END IF;

    -- Location Details (from branch)
    IF (NEW.city IS NULL OR NEW.state IS NULL OR NEW.country IS NULL) AND NEW.branch_id IS NOT NULL THEN
        SELECT city, state, country 
        INTO v_city, v_state, v_country 
        FROM public.branches 
        WHERE id = NEW.branch_id;
        
        NEW.city := COALESCE(NEW.city, v_city);
        NEW.state := COALESCE(NEW.state, v_state);
        NEW.country := COALESCE(NEW.country, v_country);
    END IF;

    -- 5. Populate metadata snapshots for product
    IF r_prod IS NOT NULL THEN
        NEW.product_name := COALESCE(NEW.product_name, r_prod.name);
        NEW.product_sku := COALESCE(NEW.product_sku, r_prod.sku);
        NEW.category_id := COALESCE(NEW.category_id, r_prod.category_id);
        NEW.category_name := COALESCE(NEW.category_name, r_prod.category_name);
        NEW.generic_name := COALESCE(NEW.generic_name, r_prod.generic_name);
        NEW.unit_of_measure := COALESCE(NEW.unit_of_measure, 'piece');

        -- 5b. Fetch unit_cost from branch_inventory if missing
        IF NEW.unit_cost IS NULL AND NEW.inventory_id IS NOT NULL THEN
            SELECT cost_price INTO NEW.unit_cost FROM public.branch_inventory WHERE id = NEW.inventory_id;
        END IF;
    END IF;

    -- 6. Cost & Profit Calculation
    IF NEW.unit_cost IS NOT NULL THEN
        NEW.total_cost := NEW.unit_cost * NEW.quantity;
        NEW.gross_profit := NEW.subtotal - NEW.total_cost;
        IF NEW.subtotal > 0 THEN
            NEW.profit_margin := (NEW.gross_profit / NEW.subtotal) * 100;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION populate_sale_item_details IS 'Trigger function to auto-populate product snapshot details, location context, and names in sale_items';

-- End of 20260429184500_update_sale_item_population_logic.sql


-- File: 20260429190000_inventory_and_sale_analytics_sync.sql
-- ============================================================
-- Migration: Inventory and Sale Analytics Sync
-- Description: Snapshots product details into branch_inventory and 
--              updates sale_items trigger to pull generic_name from inventory.
-- ============================================================

-- 1. Ensure products table has necessary analytics columns
ALTER TABLE public.products ADD COLUMN IF NOT EXISTS unit_of_measure VARCHAR(20) DEFAULT 'piece';
ALTER TABLE public.products ADD COLUMN IF NOT EXISTS product_type TEXT;
ALTER TABLE public.products ADD COLUMN IF NOT EXISTS generic_name TEXT;
ALTER TABLE public.products ADD COLUMN IF NOT EXISTS image_url TEXT;

-- 2. Ensure branch_inventory table has snapshot columns
ALTER TABLE public.branch_inventory ADD COLUMN IF NOT EXISTS product_name TEXT;
ALTER TABLE public.branch_inventory ADD COLUMN IF NOT EXISTS sku TEXT;
ALTER TABLE public.branch_inventory ADD COLUMN IF NOT EXISTS barcode TEXT;
ALTER TABLE public.branch_inventory ADD COLUMN IF NOT EXISTS product_type TEXT;
ALTER TABLE public.branch_inventory ADD COLUMN IF NOT EXISTS generic_name TEXT;
ALTER TABLE public.branch_inventory ADD COLUMN IF NOT EXISTS unit_of_measure TEXT;
ALTER TABLE public.branch_inventory ADD COLUMN IF NOT EXISTS image_url TEXT;

-- 3. Ensure sale_items table has location snapshot columns
ALTER TABLE public.sale_items ADD COLUMN IF NOT EXISTS city VARCHAR(100);
ALTER TABLE public.sale_items ADD COLUMN IF NOT EXISTS state VARCHAR(100);
ALTER TABLE public.sale_items ADD COLUMN IF NOT EXISTS country VARCHAR(100);

-- 4. Inventory Trigger Function: Populate snapshots from products
CREATE OR REPLACE FUNCTION populate_branch_inventory_details()
RETURNS TRIGGER AS $$
DECLARE
    r_prod RECORD;
BEGIN
    SELECT name, barcode as sku, barcode, product_type, generic_name, unit_of_measure, image_url
    INTO r_prod
    FROM public.products WHERE id = NEW.product_id;

    IF r_prod IS NOT NULL THEN
        NEW.product_name := COALESCE(NEW.product_name, r_prod.name);
        NEW.sku := COALESCE(NEW.sku, r_prod.sku);
        NEW.barcode := COALESCE(NEW.barcode, r_prod.barcode);
        NEW.product_type := COALESCE(NEW.product_type, r_prod.product_type);
        NEW.unit_of_measure := COALESCE(NEW.unit_of_measure, r_prod.unit_of_measure);
        NEW.image_url := COALESCE(NEW.image_url, r_prod.image_url);
        
        -- Capture generic_name only if it's a drug/medication
        IF r_prod.product_type IN ('drug', 'medication') THEN
            NEW.generic_name := COALESCE(NEW.generic_name, r_prod.generic_name);
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_populate_branch_inventory_details ON public.branch_inventory;
CREATE TRIGGER trg_populate_branch_inventory_details
    BEFORE INSERT ON public.branch_inventory
    FOR EACH ROW
    EXECUTE FUNCTION populate_branch_inventory_details();

COMMENT ON FUNCTION populate_branch_inventory_details() IS 'Auto-populates product snapshots in branch_inventory';


-- 2. Update Sale Item Trigger Function: Pull generic_name from inventory snapshots
CREATE OR REPLACE FUNCTION populate_sale_item_details()
RETURNS TRIGGER AS $$
DECLARE
    r_prod RECORD;
    r_inv RECORD;
    v_branch_id UUID;
    v_tenant_id UUID;
    v_customer_id UUID;
    v_cashier_id UUID;
    v_customer_name TEXT;
    v_cashier_name TEXT;
    v_provider_name TEXT;
BEGIN
    -- 1. Get snapshot details from Branch Inventory if inventory_id is provided
    IF NEW.inventory_id IS NOT NULL THEN
        SELECT product_id, product_name, sku, barcode, product_type, generic_name, selling_price, cost_price
        INTO r_inv
        FROM public.branch_inventory WHERE id = NEW.inventory_id;
        
        IF r_inv IS NOT NULL THEN
            NEW.product_id := COALESCE(NEW.product_id, r_inv.product_id);
            NEW.product_name := COALESCE(NEW.product_name, r_inv.product_name);
            NEW.product_sku := COALESCE(NEW.product_sku, r_inv.sku);
            NEW.generic_name := COALESCE(NEW.generic_name, r_inv.generic_name);
            NEW.unit_cost := COALESCE(NEW.unit_cost, CAST(r_inv.cost_price AS NUMERIC));
        END IF;
    END IF;

    -- 2. Fallback to products catalog if details are still missing (e.g. non-inventory items)
    IF NEW.product_name IS NULL OR (NEW.generic_name IS NULL AND NEW.product_id IS NOT NULL) THEN
        SELECT p.name, p.barcode as sku, p.category_id, c.name as category_name, p.generic_name, p.product_type
        INTO r_prod
        FROM public.products p
        LEFT JOIN public.categories c ON c.id = p.category_id
        WHERE p.id = NEW.product_id;

        IF r_prod IS NOT NULL THEN
            NEW.product_name := COALESCE(NEW.product_name, r_prod.name);
            NEW.product_sku := COALESCE(NEW.product_sku, r_prod.sku);
            NEW.category_id := COALESCE(NEW.category_id, r_prod.category_id);
            NEW.category_name := COALESCE(NEW.category_name, r_prod.category_name);
            
            -- Only pull generic_name if it's a drug and we don't have it yet
            IF NEW.generic_name IS NULL AND r_prod.product_type IN ('drug', 'medication') THEN
                NEW.generic_name := r_prod.generic_name;
            END IF;
        END IF;
    END IF;

    -- 3. Get transaction context from Sale or Order if IDs are missing in NEW
    IF NEW.sale_id IS NOT NULL THEN
        SELECT 
            branch_id, tenant_id, customer_id, cashier_id, customer_name
        INTO 
            v_branch_id, v_tenant_id, v_customer_id, v_cashier_id, v_customer_name
        FROM public.sales WHERE id = NEW.sale_id;
    ELSIF NEW.order_id IS NOT NULL THEN
        SELECT 
            branch_id, tenant_id, customer_id
        INTO 
            v_branch_id, v_tenant_id, v_customer_id
        FROM public.orders WHERE id = NEW.order_id;
    END IF;

    -- 4. Consolidate IDs (Priority: NEW > Context from Sale/Order)
    NEW.tenant_id := COALESCE(NEW.tenant_id, v_tenant_id);
    NEW.branch_id := COALESCE(NEW.branch_id, v_branch_id);
    NEW.customer_id := COALESCE(NEW.customer_id, v_customer_id);
    NEW.cashier_id := COALESCE(NEW.cashier_id, v_cashier_id);

    -- 5. Fetch Names for the consolidated IDs
    -- Customer Name
    IF NEW.customer_name IS NULL THEN
        IF NEW.customer_id IS NOT NULL THEN
            SELECT full_name INTO v_customer_name FROM public.customers WHERE id = NEW.customer_id;
            NEW.customer_name := v_customer_name;
        END IF;
        IF NEW.customer_name IS NULL THEN
            NEW.customer_name := v_customer_name; 
        END IF;
    END IF;

    -- Cashier Name
    IF NEW.cashier_name IS NULL AND NEW.cashier_id IS NOT NULL THEN
        SELECT full_name INTO v_cashier_name FROM public.users WHERE id = NEW.cashier_id;
        NEW.cashier_name := v_cashier_name;
    END IF;

    -- Healthcare Provider Name
    IF NEW.healthcare_provider_name IS NULL AND NEW.health_care_provider IS NOT NULL THEN
        SELECT full_name INTO v_provider_name FROM public.healthcare_providers WHERE id = NEW.health_care_provider;
        NEW.healthcare_provider_name := v_provider_name;
    END IF;

    -- 6. Cost & Profit Calculation
    IF NEW.unit_cost IS NOT NULL THEN
        NEW.total_cost := NEW.unit_cost * NEW.quantity;
        NEW.gross_profit := NEW.subtotal - NEW.total_cost;
        IF NEW.subtotal > 0 THEN
            NEW.profit_margin := (NEW.gross_profit / NEW.subtotal) * 100;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- End of 20260429190000_inventory_and_sale_analytics_sync.sql


-- File: 20260429210000_fix_staff_rls_access.sql
-- 1. Ensure the current_tenant_id helper is robust and bypassing RLS
CREATE OR REPLACE FUNCTION current_tenant_id() 
RETURNS UUID AS $$
    SELECT u.tenant_id FROM public.users u WHERE u.id = auth.uid();
$$ LANGUAGE SQL SECURITY DEFINER;

-- 2. Tenants Table: Allow staff to see their assigned tenant
DROP POLICY IF EXISTS "Users can view own tenant" ON public.tenants;
DROP POLICY IF EXISTS "Users can view their own tenant" ON public.tenants;
DROP POLICY IF EXISTS "Users can select their own tenant by email" ON public.tenants;
DROP POLICY IF EXISTS "Public can view basic tenant info" ON public.tenants;

-- Restore public view for storefront slug resolution
CREATE POLICY "Public can view basic tenant info"
    ON public.tenants FOR SELECT
    USING (deleted_at IS NULL);

-- Add explicit staff access
CREATE POLICY "Staff can view their own tenant"
    ON public.tenants FOR SELECT
    USING (id = current_tenant_id());

-- 3. Branches Table: Allow staff to see branches in their tenant
DROP POLICY IF EXISTS "Tenant branch isolation" ON public.branches;
DROP POLICY IF EXISTS "Users can view branches in their tenant" ON public.branches;
DROP POLICY IF EXISTS "Users can view own branch" ON public.branches;
DROP POLICY IF EXISTS "Public can view branches for storefront" ON public.branches;

CREATE POLICY "Public can view branches for storefront"
    ON public.branches FOR SELECT
    USING (deleted_at IS NULL);

CREATE POLICY "Staff can view branches in their tenant"
    ON public.branches FOR SELECT
    USING (tenant_id = current_tenant_id());

-- 4. Users Table: Allow staff to see colleagues
DROP POLICY IF EXISTS "Users can view users in their tenant" ON public.users;
CREATE POLICY "Users can view users in their tenant"
    ON public.users FOR SELECT
    USING (tenant_id = current_tenant_id());

-- 5. Products Table: Ensure staff can see products
DROP POLICY IF EXISTS "Users can view products in their tenant" ON public.products;
CREATE POLICY "Users can view products in their tenant"
    ON public.products FOR SELECT
    USING (tenant_id = current_tenant_id());

-- End of 20260429210000_fix_staff_rls_access.sql


-- File: 20260429233000_add_service_charge_to_orders.sql
-- ============================================================
-- Migration: Add service_charge to orders
-- Description: Adds service_charge column to orders table and updates the valid_total constraint.
-- ============================================================

-- 1. Add service_charge column
ALTER TABLE public.orders 
ADD COLUMN IF NOT EXISTS service_charge DECIMAL(12,2) DEFAULT 0 CHECK (service_charge >= 0);

-- 2. Update valid_total constraint
ALTER TABLE public.orders DROP CONSTRAINT IF EXISTS valid_total;
ALTER TABLE public.orders ADD CONSTRAINT valid_total CHECK (total_amount = subtotal + delivery_fee + tax_amount + service_charge);

-- 3. Update checkout_storefront_order RPC to support service_charge
CREATE OR REPLACE FUNCTION checkout_storefront_order(
    p_tenant_id UUID,
    p_branch_id UUID,
    p_customer_id UUID,
    p_order_type order_type,
    p_fulfillment_type fulfillment_type,
    p_subtotal DECIMAL,
    p_delivery_fee DECIMAL,
    p_tax_amount DECIMAL,
    p_total_amount DECIMAL,
    p_delivery_address_id UUID,
    p_special_instructions TEXT,
    p_items JSONB, -- Array of { product_id, product_name, quantity, unit_price, subtotal }
    p_service_charge DECIMAL DEFAULT 0
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_order_id UUID;
    v_item RECORD;
    v_batch RECORD;
    v_req_qty INTEGER;
    v_available_qty INTEGER;
    v_allocated_qty INTEGER;
    v_allocations JSONB;
    v_primary_batch_id UUID;
BEGIN
    -- Validate totals (including service charge)
    IF p_total_amount != (p_subtotal + p_delivery_fee + p_tax_amount + p_service_charge) THEN
        RAISE EXCEPTION 'Total amount does not match subtotal + fees + tax + service charge';
    END IF;

    -- Create the order header
    INSERT INTO orders (
        tenant_id, branch_id, order_number, customer_id,
        order_type, order_status, payment_status,
        subtotal, delivery_fee, tax_amount, service_charge, total_amount,
        fulfillment_type, delivery_address_id, special_instructions
    ) VALUES (
        p_tenant_id,
        p_branch_id,
        'ORD-' || FLOOR(EXTRACT(EPOCH FROM NOW()))::TEXT || '-' || SUBSTRING(MD5(RANDOM()::TEXT) FROM 1 FOR 4),
        p_customer_id,
        p_order_type,
        'pending'::order_status,
        'unpaid'::payment_status,
        p_subtotal, p_delivery_fee, p_tax_amount, p_service_charge, p_total_amount,
        p_fulfillment_type,
        p_delivery_address_id,
        p_special_instructions
    ) RETURNING id INTO v_order_id;

    -- Process each item: FIFO batch allocation + insert into sale_items
    FOR v_item IN SELECT * FROM jsonb_to_recordset(p_items) AS x(
        product_id UUID, product_name TEXT, quantity INTEGER, unit_price DECIMAL, subtotal DECIMAL
    )
    LOOP
        v_req_qty := v_item.quantity;
        v_allocations := '[]'::jsonb;
        v_primary_batch_id := NULL;

        -- FIFO batch allocation
        FOR v_batch IN 
            SELECT id, (stock_quantity - COALESCE(reserved_quantity, 0)) AS available_balance
            FROM branch_inventory
            WHERE branch_id = p_branch_id 
              AND product_id = v_item.product_id 
              AND is_active = true
              AND (stock_quantity - COALESCE(reserved_quantity, 0)) > 0
            ORDER BY expiry_date ASC NULLS LAST, created_at ASC
            FOR UPDATE
        LOOP
            IF v_req_qty <= 0 THEN EXIT; END IF;

            v_available_qty := v_batch.available_balance;
            v_allocated_qty := LEAST(v_available_qty, v_req_qty);

            -- Reserve stock in the batch
            UPDATE branch_inventory
            SET reserved_quantity = COALESCE(reserved_quantity, 0) + v_allocated_qty,
                updated_at = NOW()
            WHERE id = v_batch.id;

            IF v_primary_batch_id IS NULL THEN
                v_primary_batch_id := v_batch.id;
            END IF;

            v_allocations := v_allocations || jsonb_build_object(
                'batch_id', v_batch.id,
                'quantity', v_allocated_qty
            );

            v_req_qty := v_req_qty - v_allocated_qty;
        END LOOP;

        IF v_req_qty > 0 THEN
            RAISE EXCEPTION 'Insufficient stock for product: % (short by %)', v_item.product_name, v_req_qty;
        END IF;

        INSERT INTO public.sale_items (
            tenant_id,
            order_id,
            branch_id,
            inventory_id,
            product_id,
            product_name,
            quantity,
            unit_price,
            subtotal,
            discount_amount,
            batch_allocations
        ) VALUES (
            p_tenant_id,
            v_order_id,
            p_branch_id,
            v_primary_batch_id,
            v_item.product_id,
            v_item.product_name,
            v_item.quantity,
            v_item.unit_price,
            v_item.subtotal,
            0,
            v_allocations
        );
    END LOOP;

    RETURN v_order_id;
END;
$$;

-- End of 20260429233000_add_service_charge_to_orders.sql


-- File: 20260430150000_update_checkout_rpc_with_payment_ref.sql
-- ============================================================
-- Migration: Update checkout_storefront_order with Payment Reference
-- Description: Updates the RPC to accept a payment reference and set status to paid.
-- ============================================================

CREATE OR REPLACE FUNCTION checkout_storefront_order(
    p_tenant_id UUID,
    p_branch_id UUID,
    p_customer_id UUID,
    p_order_type order_type,
    p_fulfillment_type fulfillment_type,
    p_subtotal DECIMAL,
    p_delivery_fee DECIMAL,
    p_tax_amount DECIMAL,
    p_total_amount DECIMAL,
    p_delivery_address_id UUID,
    p_special_instructions TEXT,
    p_items JSONB, -- Array of { product_id, product_name, quantity, unit_price, subtotal }
    p_service_charge DECIMAL DEFAULT 0,
    p_payment_reference TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_order_id UUID;
    v_item RECORD;
    v_batch RECORD;
    v_req_qty INTEGER;
    v_available_qty INTEGER;
    v_allocated_qty INTEGER;
    v_allocations JSONB;
    v_primary_batch_id UUID;
BEGIN
    -- Validate totals (including service charge)
    IF p_total_amount != (p_subtotal + p_delivery_fee + p_tax_amount + p_service_charge) THEN
        RAISE EXCEPTION 'Total amount does not match subtotal + fees + tax + service charge';
    END IF;

    -- Create the order header
    INSERT INTO orders (
        tenant_id, branch_id, order_number, customer_id,
        order_type, order_status, payment_status, payment_method, payment_reference,
        subtotal, delivery_fee, tax_amount, service_charge, total_amount,
        fulfillment_type, delivery_address_id, special_instructions
    ) VALUES (
        p_tenant_id,
        p_branch_id,
        'ORD-' || FLOOR(EXTRACT(EPOCH FROM NOW()))::TEXT || '-' || SUBSTRING(MD5(RANDOM()::TEXT) FROM 1 FOR 4),
        p_customer_id,
        p_order_type,
        'pending'::order_status,
        CASE WHEN p_payment_reference IS NOT NULL THEN 'paid'::payment_status ELSE 'unpaid'::payment_status END,
        'card'::payment_method, -- Default to card if payment reference is provided
        p_payment_reference,
        p_subtotal, p_delivery_fee, p_tax_amount, p_service_charge, p_total_amount,
        p_fulfillment_type,
        p_delivery_address_id,
        p_special_instructions
    ) RETURNING id INTO v_order_id;

    -- Process each item: FIFO batch allocation + insert into sale_items
    FOR v_item IN SELECT * FROM jsonb_to_recordset(p_items) AS x(
        product_id UUID, product_name TEXT, quantity INTEGER, unit_price DECIMAL, subtotal DECIMAL
    )
    LOOP
        v_req_qty := v_item.quantity;
        v_allocations := '[]'::jsonb;
        v_primary_batch_id := NULL;

        -- FIFO batch allocation
        FOR v_batch IN 
            SELECT id, (stock_quantity - COALESCE(reserved_quantity, 0)) AS available_balance
            FROM branch_inventory
            WHERE branch_id = p_branch_id 
              AND product_id = v_item.product_id 
              AND is_active = true
              AND (stock_quantity - COALESCE(reserved_quantity, 0)) > 0
            ORDER BY expiry_date ASC NULLS LAST, created_at ASC
            FOR UPDATE
        LOOP
            IF v_req_qty <= 0 THEN EXIT; END IF;

            v_available_qty := v_batch.available_balance;
            v_allocated_qty := LEAST(v_available_qty, v_req_qty);

            -- Reserve stock in the batch
            UPDATE branch_inventory
            SET reserved_quantity = COALESCE(reserved_quantity, 0) + v_allocated_qty,
                updated_at = NOW()
            WHERE id = v_batch.id;

            IF v_primary_batch_id IS NULL THEN
                v_primary_batch_id := v_batch.id;
            END IF;

            v_allocations := v_allocations || jsonb_build_object(
                'batch_id', v_batch.id,
                'quantity', v_allocated_qty
            );

            v_req_qty := v_req_qty - v_allocated_qty;
        END LOOP;

        IF v_req_qty > 0 THEN
            RAISE EXCEPTION 'Insufficient stock for product: % (short by %)', v_item.product_name, v_req_qty;
        END IF;

        INSERT INTO public.sale_items (
            tenant_id,
            order_id,
            branch_id,
            inventory_id,
            product_id,
            product_name,
            quantity,
            unit_price,
            subtotal,
            discount_amount,
            batch_allocations
        ) VALUES (
            p_tenant_id,
            v_order_id,
            p_branch_id,
            v_primary_batch_id,
            v_item.product_id,
            v_item.product_name,
            v_item.quantity,
            v_item.unit_price,
            v_item.subtotal,
            0,
            v_allocations
        );
    END LOOP;

    RETURN v_order_id;
END;
$$;

-- End of 20260430150000_update_checkout_rpc_with_payment_ref.sql


-- File: 20260501073500_add_order_addresses.sql
-- Migration: Add billing and shipping addresses to orders
-- Description: Adds billing_address and shipping_address text columns to orders table.

ALTER TABLE public.orders 
ADD COLUMN IF NOT EXISTS billing_address TEXT,
ADD COLUMN IF NOT EXISTS shipping_address TEXT;

-- Update checkout_storefront_order RPC to support these addresses
CREATE OR REPLACE FUNCTION checkout_storefront_order(
    p_tenant_id UUID,
    p_branch_id UUID,
    p_customer_id UUID,
    p_order_type order_type,
    p_fulfillment_type fulfillment_type,
    p_subtotal DECIMAL,
    p_delivery_fee DECIMAL,
    p_tax_amount DECIMAL,
    p_total_amount DECIMAL,
    p_delivery_address_id UUID,
    p_special_instructions TEXT,
    p_items JSONB, -- Array of { product_id, product_name, quantity, unit_price, subtotal }
    p_service_charge DECIMAL DEFAULT 0,
    p_payment_reference TEXT DEFAULT NULL,
    p_billing_address TEXT DEFAULT NULL,
    p_shipping_address TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_order_id UUID;
    v_item RECORD;
    v_batch RECORD;
    v_req_qty INTEGER;
    v_available_qty INTEGER;
    v_allocated_qty INTEGER;
    v_allocations JSONB;
    v_primary_batch_id UUID;
BEGIN
    -- Validate totals (including service charge)
    IF p_total_amount != (p_subtotal + p_delivery_fee + p_tax_amount + p_service_charge) THEN
        RAISE EXCEPTION 'Total amount does not match subtotal + fees + tax + service charge';
    END IF;

    -- Create the order header
    INSERT INTO orders (
        tenant_id, branch_id, order_number, customer_id,
        order_type, order_status, payment_status, payment_method, payment_reference,
        subtotal, delivery_fee, tax_amount, service_charge, total_amount,
        fulfillment_type, delivery_address_id, special_instructions,
        billing_address, shipping_address
    ) VALUES (
        p_tenant_id,
        p_branch_id,
        'ORD-' || FLOOR(EXTRACT(EPOCH FROM NOW()))::TEXT || '-' || SUBSTRING(MD5(RANDOM()::TEXT) FROM 1 FOR 4),
        p_customer_id,
        p_order_type,
        'pending'::order_status,
        CASE WHEN p_payment_reference IS NOT NULL THEN 'paid'::payment_status ELSE 'unpaid'::payment_status END,
        'card'::payment_method,
        p_payment_reference,
        p_subtotal, p_delivery_fee, p_tax_amount, p_service_charge, p_total_amount,
        p_fulfillment_type,
        p_delivery_address_id,
        p_special_instructions,
        p_billing_address,
        p_shipping_address
    ) RETURNING id INTO v_order_id;

    -- Process each item: FIFO batch allocation
    FOR v_item IN SELECT * FROM jsonb_to_recordset(p_items) AS x(
        product_id UUID, product_name TEXT, quantity INTEGER, unit_price DECIMAL, subtotal DECIMAL
    )
    LOOP
        v_req_qty := v_item.quantity;
        v_allocations := '[]'::jsonb;
        v_primary_batch_id := NULL;

        -- FIFO batch allocation
        FOR v_batch IN 
            SELECT id, (stock_quantity - COALESCE(reserved_quantity, 0)) AS available_balance
            FROM branch_inventory
            WHERE branch_id = p_branch_id 
              AND product_id = v_item.product_id 
              AND is_active = true
              AND (stock_quantity - COALESCE(reserved_quantity, 0)) > 0
            ORDER BY expiry_date ASC NULLS LAST, created_at ASC
            FOR UPDATE
        LOOP
            IF v_req_qty <= 0 THEN EXIT; END IF;

            v_available_qty := v_batch.available_balance;
            v_allocated_qty := LEAST(v_available_qty, v_req_qty);

            -- Reserve stock in the batch
            UPDATE branch_inventory
            SET reserved_quantity = COALESCE(reserved_quantity, 0) + v_allocated_qty,
                updated_at = NOW()
            WHERE id = v_batch.id;

            IF v_primary_batch_id IS NULL THEN
                v_primary_batch_id := v_batch.id;
            END IF;

            v_allocations := v_allocations || jsonb_build_object(
                'batch_id', v_batch.id,
                'quantity', v_allocated_qty
            );

            v_req_qty := v_req_qty - v_allocated_qty;
        END LOOP;

        IF v_req_qty > 0 THEN
            RAISE EXCEPTION 'Insufficient stock for product: % (short by %)', v_item.product_name, v_req_qty;
        END IF;

        INSERT INTO public.sale_items (
            tenant_id,
            order_id,
            branch_id,
            inventory_id,
            product_id,
            product_name,
            quantity,
            unit_price,
            subtotal,
            discount_amount,
            batch_allocations
        ) VALUES (
            p_tenant_id,
            v_order_id,
            p_branch_id,
            v_primary_batch_id,
            v_item.product_id,
            v_item.product_name,
            v_item.quantity,
            v_item.unit_price,
            v_item.subtotal,
            0,
            v_allocations
        );
    END LOOP;

    RETURN v_order_id;
END;
$$;

-- End of 20260501073500_add_order_addresses.sql


-- File: 20260501074300_ai_and_delivery_toggles.sql
-- Migration: Add AI enablement and delivery options
-- Description: Adds AI_is_enabled to tenants and delivery_enabled to branches.

ALTER TABLE public.tenants 
ADD COLUMN IF NOT EXISTS AI_is_enabled BOOLEAN DEFAULT false;

ALTER TABLE public.branches 
ADD COLUMN IF NOT EXISTS delivery_enabled BOOLEAN DEFAULT true;

-- End of 20260501074300_ai_and_delivery_toggles.sql


-- File: 20260501081200_enable_ai_test_tenant.sql
-- Migration: Enable AI for test tenant
-- Description: Sets ai_is_enabled to true for the ade-ventures tenant.

UPDATE public.tenants 
SET ai_is_enabled = true 
WHERE slug = 'ade-ventures' OR name ILIKE '%Ade Ventures%';

-- End of 20260501081200_enable_ai_test_tenant.sql


-- File: 20260502000000_add_product_flags.sql
-- ============================================
-- Migration: Add Product Flags to Branch Inventory
-- Description: Adds is_on_sale, is_featured, and is_new_arrival flags to branch_inventory
--              to support storefront categories.
-- Created: 2026-05-02
-- ============================================

ALTER TABLE branch_inventory 
ADD COLUMN IF NOT EXISTS is_on_sale BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS is_featured BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS is_new_arrival BOOLEAN DEFAULT FALSE;

COMMENT ON COLUMN branch_inventory.is_on_sale IS 'Whether the product is currently on sale in this branch';
COMMENT ON COLUMN branch_inventory.is_featured IS 'Whether the product should be featured on the storefront';
COMMENT ON COLUMN branch_inventory.is_new_arrival IS 'Whether the product is a new arrival';

-- Update the ecommerce_products view to include these flags
-- We use bool_or() to see if ANY branch has the flag set for a product within a tenant
CREATE OR REPLACE VIEW ecommerce_products AS
SELECT
    p.id,
    bi.tenant_id,
    p.name,
    p.description,
    p.category,
    bi.selling_price,
    bi.sale_price,
    p.image_url,
    p.is_active,

    -- Aggregate stock across all branches for this tenant
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
                'in_stock', bi.stock_quantity > 0,
                'is_on_sale', bi.is_on_sale,
                'is_featured', bi.is_featured,
                'is_new_arrival', bi.is_new_arrival,
                'selling_price', bi.selling_price,
                'sale_price', bi.sale_price
            ) ORDER BY b.name
        ) FILTER (WHERE bi.id IS NOT NULL),
        '[]'::jsonb
    ) as branches,

    -- Flags aggregated across branches
    bool_or(bi.is_on_sale) as is_on_sale,
    bool_or(bi.is_featured) as is_featured,
    bool_or(bi.is_new_arrival) as is_new_arrival,

    -- Min and max price (using branch-specific selling_price)
    MIN(bi.selling_price) as min_price,
    MAX(bi.selling_price) as max_price,

    p.created_at,
    p.updated_at,
    
    -- Healthcare & Laboratory expansions
    p.unit_of_measure,
    p.product_type,
    p.generic_name,
    p.strength,
    p.dosage_form,
    p.manufacturer
FROM products p
JOIN branch_inventory bi ON bi.product_id = p.id AND bi.is_active = true
LEFT JOIN branches b ON bi.branch_id = b.id AND b.deleted_at IS NULL
WHERE p._sync_is_deleted = false
  AND p.is_active = TRUE
GROUP BY
    p.id,
    bi.tenant_id,
    p.name,
    p.description,
    p.category,
    bi.selling_price,
    bi.sale_price,
    p.image_url,
    p.is_active,
    p.created_at,
    p.updated_at,
    
    -- Essential group by fields
    p.unit_of_measure,
    p.product_type,
    p.generic_name,
    p.strength,
    p.dosage_form,
    p.manufacturer;

-- End of 20260502000000_add_product_flags.sql


-- File: 20260502010000_promotional_tables.sql
-- ============================================
-- Migration: Promotional Product Tables
-- Description: Creates featured_products and sale_products tables
--              to replace boolean flags for curated lists.
-- Created: 2026-05-02
-- ============================================

CREATE TABLE IF NOT EXISTS featured_products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    inventory_id UUID REFERENCES branch_inventory(id) ON DELETE CASCADE,
    display_order INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(tenant_id, product_id)
);

CREATE TABLE IF NOT EXISTS sale_products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    inventory_id UUID REFERENCES branch_inventory(id) ON DELETE CASCADE,
    sale_price DECIMAL(15, 2),
    discount_percentage DECIMAL(5, 2),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(tenant_id, product_id)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_featured_tenant ON featured_products(tenant_id);
CREATE INDEX IF NOT EXISTS idx_sale_tenant ON sale_products(tenant_id);

-- RLS Policies
ALTER TABLE featured_products ENABLE ROW LEVEL SECURITY;
ALTER TABLE sale_products ENABLE ROW LEVEL SECURITY;

-- Featured Products Policies
DROP POLICY IF EXISTS "Anyone can view featured products" ON featured_products;
CREATE POLICY "Anyone can view featured products" ON featured_products
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "Tenants can manage featured products" ON featured_products;
CREATE POLICY "Tenants can manage featured products" ON featured_products
    FOR ALL USING (tenant_id = (SELECT tenant_id FROM users WHERE id = auth.uid()));

-- Sale Products Policies
DROP POLICY IF EXISTS "Anyone can view sale products" ON sale_products;
CREATE POLICY "Anyone can view sale products" ON sale_products
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "Tenants can manage sale products" ON sale_products;
CREATE POLICY "Tenants can manage sale products" ON sale_products
    FOR ALL USING (tenant_id = (SELECT tenant_id FROM users WHERE id = auth.uid()));

-- Migrate data from branch_inventory flags (one-way)
INSERT INTO featured_products (tenant_id, product_id, inventory_id)
SELECT DISTINCT ON (tenant_id, product_id) tenant_id, product_id, id
FROM branch_inventory
WHERE is_featured = true
ON CONFLICT DO NOTHING;

INSERT INTO sale_products (tenant_id, product_id, inventory_id, sale_price)
SELECT DISTINCT ON (tenant_id, product_id) tenant_id, product_id, id, sale_price
FROM branch_inventory
WHERE is_on_sale = true
ON CONFLICT DO NOTHING;

-- Note: We keep the columns on branch_inventory for now to avoid breaking existing code
-- but we update the view to prioritize the new tables.

CREATE OR REPLACE VIEW ecommerce_products AS
SELECT
    p.id,
    bi.tenant_id,
    p.name,
    p.description,
    p.category,
    bi.selling_price,
    COALESCE(sp.sale_price, bi.sale_price) as sale_price,
    p.image_url,
    p.is_active,

    -- Aggregate stock across all branches for this tenant
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
                'in_stock', bi.stock_quantity > 0,
                'is_on_sale', EXISTS (SELECT 1 FROM sale_products sp2 WHERE sp2.product_id = p.id AND sp2.tenant_id = bi.tenant_id),
                'is_featured', EXISTS (SELECT 1 FROM featured_products fp2 WHERE fp2.product_id = p.id AND fp2.tenant_id = bi.tenant_id),
                'is_new_arrival', bi.is_new_arrival,
                'is_pom', p."isPOM",
                'selling_price', bi.selling_price,
                'sale_price', COALESCE(sp.sale_price, bi.sale_price)
            ) ORDER BY b.name
        ) FILTER (WHERE bi.id IS NOT NULL),
        '[]'::jsonb
    ) as branches,

    -- Flags
    EXISTS (SELECT 1 FROM sale_products sp2 WHERE sp2.product_id = p.id AND sp2.tenant_id = bi.tenant_id) as is_on_sale,
    EXISTS (SELECT 1 FROM featured_products fp2 WHERE fp2.product_id = p.id AND fp2.tenant_id = bi.tenant_id) as is_featured,
    bool_or(bi.is_new_arrival) as is_new_arrival,

    -- Min and max price (using branch-specific selling_price)
    MIN(bi.selling_price) as min_price,
    MAX(bi.selling_price) as max_price,

    p.created_at,
    p.updated_at,
    
    -- Healthcare & Laboratory expansions
    p.unit_of_measure,
    p.product_type,
    p.generic_name,
    p.strength,
    p.dosage_form,
    p.manufacturer
FROM products p
JOIN branch_inventory bi ON bi.product_id = p.id AND bi.is_active = true
LEFT JOIN branches b ON bi.branch_id = b.id AND b.deleted_at IS NULL
LEFT JOIN sale_products sp ON sp.product_id = p.id AND sp.tenant_id = bi.tenant_id
WHERE p._sync_is_deleted = false
  AND p.is_active = TRUE
GROUP BY
    p.id,
    bi.tenant_id,
    p.name,
    p.description,
    p.category,
    bi.selling_price,
    bi.sale_price,
    sp.sale_price,
    p.image_url,
    p.is_active,
    p.created_at,
    p.updated_at,
    p."isPOM",
    p.unit_of_measure,
    p.product_type,
    p.generic_name,
    p.strength,
    p.dosage_form,
    p.manufacturer;

-- End of 20260502010000_promotional_tables.sql


-- File: 20260502020000_tenant_branding_fields.sql
-- ============================================
-- Migration: Tenant Branding Fields
-- Description: Adds logo_url (ensure exists), slogan, hero_title, 
--              hero_subtitle, and about_us to tenants table.
-- Created: 2026-05-02
-- ============================================

ALTER TABLE tenants 
ADD COLUMN IF NOT EXISTS slogan TEXT,
ADD COLUMN IF NOT EXISTS hero_title TEXT,
ADD COLUMN IF NOT EXISTS hero_subtitle TEXT,
ADD COLUMN IF NOT EXISTS about_us TEXT;

-- Update comments for clarity
COMMENT ON COLUMN tenants.logo_url IS 'URL to the tenant business logo';
COMMENT ON COLUMN tenants.slogan IS 'Short company slogan or catchphrase';
COMMENT ON COLUMN tenants.hero_title IS 'Main title displayed on the storefront hero section';
COMMENT ON COLUMN tenants.hero_subtitle IS 'Subtitle or description displayed below the hero title';
COMMENT ON COLUMN tenants.about_us IS 'Detailed information about the business for the footer/about page';

-- End of 20260502020000_tenant_branding_fields.sql


-- File: 20260503000000_final_chat_rls_fix.sql
-- Final Chat and Identity RLS Harmonization
-- Purpose: Resolve 42501 (Permission Denied) errors for images and patient profiles

-- 1. Ensure Storage Visibility for Chat Attachments
-- The 'chat-attachments' bucket is public, but storage.objects policies might be restrictive.
-- We ensure anyone can SELECT objects from this bucket.
DROP POLICY IF EXISTS "Public chat attachments access" ON storage.objects;
CREATE POLICY "Public chat attachments access"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'chat-attachments');

-- 2. Fix Unified Patient Profile Creation
-- During social login, the system tries to link the user to a unified profile.
-- We must allow authenticated users to INSERT their own profile and link.
ALTER TABLE public.unified_patient_profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Authenticated users can create profiles" ON public.unified_patient_profiles;
CREATE POLICY "Authenticated users can create profiles"
ON public.unified_patient_profiles FOR INSERT
TO authenticated
WITH CHECK (true);

DROP POLICY IF EXISTS "Users can view own profiles" ON public.unified_patient_profiles;
CREATE POLICY "Users can view own profiles"
ON public.unified_patient_profiles FOR SELECT
TO authenticated
USING (
    id IN (
        SELECT unified_patient_id FROM public.patient_account_links 
        WHERE customer_id = auth.uid()
    )
);

-- 3. Ensure Chat Messages are visible to the conversation participants
-- Double check policies on chat_messages
DROP POLICY IF EXISTS "Participants can view conversation messages" ON public.chat_messages;
CREATE POLICY "Participants can view conversation messages"
ON public.chat_messages FOR SELECT
TO authenticated
USING (
    conversation_id IN (
        SELECT id FROM public.chat_conversations
        WHERE customer_id = auth.uid() OR 
              auth.uid() IN (SELECT user_id FROM public.healthcare_providers)
    )
);

-- End of 20260503000000_final_chat_rls_fix.sql


-- File: 20260503000001_relax_storage_rls.sql
-- Relax storage.objects policies for chat-attachments to fix upload errors
-- The previous policy using storage.foldername() might have been failing or evaluated incorrectly

-- 1. Allow authenticated users to INSERT into chat-attachments
DROP POLICY IF EXISTS "Users can upload chat attachments" ON storage.objects;
CREATE POLICY "Users can upload chat attachments"
    ON storage.objects FOR INSERT
    TO authenticated
    WITH CHECK (bucket_id = 'chat-attachments');

-- 2. Allow authenticated users to UPDATE their own attachments
DROP POLICY IF EXISTS "Users can update chat attachments" ON storage.objects;
CREATE POLICY "Users can update chat attachments"
    ON storage.objects FOR UPDATE
    TO authenticated
    USING (bucket_id = 'chat-attachments');

-- 3. Ensure SELECT is still public
DROP POLICY IF EXISTS "Public chat attachments access" ON storage.objects;
CREATE POLICY "Public chat attachments access"
    ON storage.objects FOR SELECT
    TO public
    USING (bucket_id = 'chat-attachments');

-- End of 20260503000001_relax_storage_rls.sql


-- File: 20260503010100_update_chat_schema_and_access.sql
-- Migration: Update Chat Schema and Access
-- Purpose: Align chat_conversations with the user's provided schema and allow tenant staff to access chats.

-- 1. Harmonize chat_conversations table
DO $$
BEGIN
    -- Add columns if they don't exist
    ALTER TABLE public.chat_conversations 
    ADD COLUMN IF NOT EXISTS "isConsulatation" boolean NOT NULL DEFAULT false,
    ADD COLUMN IF NOT EXISTS service_provider uuid REFERENCES auth.users(id),
    ADD COLUMN IF NOT EXISTS customer_name text,
    ADD COLUMN IF NOT EXISTS customer_pic text,
    ADD COLUMN IF NOT EXISTS service_provider_name text,
    ADD COLUMN IF NOT EXISTS service_provider_pic text,
    ADD COLUMN IF NOT EXISTS "chatType" text DEFAULT 'Customer Support',
    ADD COLUMN IF NOT EXISTS metadata jsonb DEFAULT '{}'::jsonb;

    -- Ensure chatType constraint exists
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chat_conversations_chatType_check') THEN
        ALTER TABLE public.chat_conversations 
        ADD CONSTRAINT chat_conversations_chatType_check 
        CHECK ("chatType" = ANY (ARRAY['Customer Support'::text, 'Consultation'::text]));
    END IF;
END
$$;

-- 2. Indexes for performance
CREATE INDEX IF NOT EXISTS idx_chat_tenant_branch ON public.chat_conversations (tenant_id, branch_id, started_at DESC);
CREATE INDEX IF NOT EXISTS idx_chat_customer ON public.chat_conversations (customer_id, started_at DESC);
CREATE INDEX IF NOT EXISTS idx_chat_status ON public.chat_conversations (status) WHERE (status = 'active');

-- 3. RLS Policies for chat_conversations
-- Allow participants (customer/medic) AND tenant staff to view/update/create
ALTER TABLE public.chat_conversations ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Participants and staff can view conversations" ON public.chat_conversations;
CREATE POLICY "Participants and staff can view conversations"
ON public.chat_conversations FOR SELECT
TO authenticated
USING (
    customer_id = auth.uid() OR 
    service_provider = auth.uid() OR
    tenant_id IN (SELECT tenant_id FROM public.users WHERE id = auth.uid())
);

DROP POLICY IF EXISTS "Participants and staff can update conversations" ON public.chat_conversations;
CREATE POLICY "Participants and staff can update conversations"
ON public.chat_conversations FOR UPDATE
TO authenticated
USING (
    customer_id = auth.uid() OR 
    service_provider = auth.uid() OR
    tenant_id IN (SELECT tenant_id FROM public.users WHERE id = auth.uid())
);

DROP POLICY IF EXISTS "Participants and staff can insert conversations" ON public.chat_conversations;
CREATE POLICY "Participants and staff can insert conversations"
ON public.chat_conversations FOR INSERT
TO authenticated
WITH CHECK (
    customer_id = auth.uid() OR 
    service_provider = auth.uid() OR
    tenant_id IN (SELECT tenant_id FROM public.users WHERE id = auth.uid())
);

-- 4. RLS Policies for chat_messages
-- Access follows conversation access
ALTER TABLE public.chat_messages ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Participants and staff can view messages" ON public.chat_messages;
CREATE POLICY "Participants and staff can view messages"
ON public.chat_messages FOR SELECT
TO authenticated
USING (
    conversation_id IN (
        SELECT id FROM public.chat_conversations
        WHERE customer_id = auth.uid() OR 
              service_provider = auth.uid() OR
              tenant_id IN (SELECT tenant_id FROM public.users WHERE id = auth.uid())
    )
);

DROP POLICY IF EXISTS "Participants and staff can insert messages" ON public.chat_messages;
CREATE POLICY "Participants and staff can insert messages"
ON public.chat_messages FOR INSERT
TO authenticated
WITH CHECK (
    conversation_id IN (
        SELECT id FROM public.chat_conversations
        WHERE customer_id = auth.uid() OR 
              service_provider = auth.uid() OR
              tenant_id IN (SELECT tenant_id FROM public.users WHERE id = auth.uid())
    )
);

-- End of 20260503010100_update_chat_schema_and_access.sql


-- File: 20260503010200_update_chat_messages_schema.sql
-- Migration: Update Chat Messages Schema for Media Support
-- Purpose: Add columns to support image, video, pdf, and voice attachments as expected by the POS UI.

ALTER TABLE public.chat_messages 
ADD COLUMN IF NOT EXISTS attachment_type text,
ADD COLUMN IF NOT EXISTS attachment_url text,
ADD COLUMN IF NOT EXISTS attachment_name text,
ADD COLUMN IF NOT EXISTS voice_duration integer;

-- Add comment for clarity
COMMENT ON COLUMN public.chat_messages.attachment_type IS 'Type of media: image, video, pdf, or audio/voice';

-- End of 20260503010200_update_chat_messages_schema.sql


-- File: 20260503020000_add_open_chat_status.sql
-- Migration: Add 'open' status to chat_status enum
-- Purpose: Support unassigned chats that staff can join.

ALTER TYPE public.chat_status ADD VALUE IF NOT EXISTS 'open';
ALTER TABLE public.chat_conversations ALTER COLUMN status SET DEFAULT 'open';
UPDATE public.chat_conversations SET status = 'open' WHERE status = 'active' AND service_provider IS NULL;

-- End of 20260503020000_add_open_chat_status.sql


-- File: 20260506000000_purchase_orders_and_preorders.sql
-- ============================================================
-- Migration: Add Purchase Orders and Preorders
-- ============================================================
-- Description: Creates the PO workflow tables, sequence generator,
-- and preorder tracking fields for products/inventory.
-- ============================================================

-- 1. Add tenant settings for PO and Preorders
ALTER TABLE tenants
ADD COLUMN IF NOT EXISTS po_enabled BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS preorders_enabled BOOLEAN DEFAULT FALSE;

-- 2. Create Enums
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'po_status') THEN
        CREATE TYPE po_status AS ENUM ('draft', 'pending', 'partially_received', 'completed', 'cancelled');
    END IF;
END$$;

-- 3. Create PO Number Sequence tracking table
-- A separate table to track the last PO number for each tenant
CREATE TABLE IF NOT EXISTS tenant_po_sequences (
    tenant_id UUID PRIMARY KEY REFERENCES tenants(id) ON DELETE CASCADE,
    last_sequence_number INTEGER DEFAULT 0,
    prefix VARCHAR(10) DEFAULT 'PO-',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE tenant_po_sequences ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view their tenant sequence" ON tenant_po_sequences;
CREATE POLICY "Users can view their tenant sequence"
    ON tenant_po_sequences FOR SELECT
    USING (tenant_id IN (SELECT tenant_id FROM users WHERE id = auth.uid()));

-- Function to generate the next PO number for a tenant
CREATE OR REPLACE FUNCTION generate_po_number(p_tenant_id UUID)
RETURNS VARCHAR
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_next_val INTEGER;
    v_prefix VARCHAR(10);
    v_po_number VARCHAR(50);
BEGIN
    -- Insert tracking record if not exists
    INSERT INTO tenant_po_sequences (tenant_id, last_sequence_number, prefix)
    VALUES (p_tenant_id, 0, 'PO-')
    ON CONFLICT (tenant_id) DO NOTHING;

    -- Update and get next value
    UPDATE tenant_po_sequences
    SET last_sequence_number = last_sequence_number + 1,
        updated_at = NOW()
    WHERE tenant_id = p_tenant_id
    RETURNING last_sequence_number, prefix INTO v_next_val, v_prefix;

    -- Format PO number (e.g., PO-1001)
    -- Padding to 4 digits min
    v_po_number := v_prefix || LPAD(v_next_val::TEXT, 4, '0');
    
    RETURN v_po_number;
END;
$$;

-- 4. Create Purchase Orders Table
CREATE TABLE IF NOT EXISTS purchase_orders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
    supplier_id UUID REFERENCES suppliers(id) ON DELETE SET NULL,
    po_number VARCHAR(50), -- Only set when status changes from draft
    status po_status DEFAULT 'draft',
    total_cost DECIMAL(12,2) DEFAULT 0 CHECK (total_cost >= 0),
    expected_delivery_date DATE,
    notes TEXT,
    created_by UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- RLS for purchase_orders
ALTER TABLE purchase_orders ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view POs in their tenant" ON purchase_orders;
CREATE POLICY "Users can view POs in their tenant"
    ON purchase_orders FOR SELECT
    USING (tenant_id IN (SELECT tenant_id FROM users WHERE id = auth.uid()));

DROP POLICY IF EXISTS "Branch managers can manage POs" ON purchase_orders;
CREATE POLICY "Branch managers can manage POs"
    ON purchase_orders FOR ALL
    USING (
        tenant_id IN (
            SELECT tenant_id FROM users
            WHERE id = auth.uid()
            AND role IN ('tenant_admin', 'branch_manager')
        )
    );

-- 5. Create Purchase Order Items Table
CREATE TABLE IF NOT EXISTS purchase_order_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    po_id UUID NOT NULL REFERENCES purchase_orders(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    expected_qty INTEGER NOT NULL CHECK (expected_qty > 0),
    received_qty INTEGER NOT NULL DEFAULT 0 CHECK (received_qty >= 0),
    unit_cost DECIMAL(12,2) NOT NULL CHECK (unit_cost >= 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- RLS for purchase_order_items
ALTER TABLE purchase_order_items ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view PO items in their tenant" ON purchase_order_items;
CREATE POLICY "Users can view PO items in their tenant"
    ON purchase_order_items FOR SELECT
    USING (po_id IN (SELECT id FROM purchase_orders WHERE tenant_id IN (SELECT tenant_id FROM users WHERE id = auth.uid())));

DROP POLICY IF EXISTS "Branch managers can manage PO items" ON purchase_order_items;
CREATE POLICY "Branch managers can manage PO items"
    ON purchase_order_items FOR ALL
    USING (
        po_id IN (
            SELECT id FROM purchase_orders WHERE tenant_id IN (
                SELECT tenant_id FROM users
                WHERE id = auth.uid()
                AND role IN ('tenant_admin', 'branch_manager')
            )
        )
    );

-- 6. Add preorder fields to products and branch_inventory
ALTER TABLE products
ADD COLUMN IF NOT EXISTS allow_preorder BOOLEAN DEFAULT FALSE;

ALTER TABLE branch_inventory
ADD COLUMN IF NOT EXISTS allow_preorder BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS preorder_quantity INTEGER DEFAULT 0 CHECK (preorder_quantity >= 0);

-- Update triggers for updated_at
CREATE OR REPLACE FUNCTION trigger_set_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS set_updated_at ON tenant_po_sequences;
CREATE TRIGGER set_updated_at
BEFORE UPDATE ON tenant_po_sequences
FOR EACH ROW
EXECUTE FUNCTION trigger_set_timestamp();

DROP TRIGGER IF EXISTS set_updated_at ON purchase_orders;
CREATE TRIGGER set_updated_at
BEFORE UPDATE ON purchase_orders
FOR EACH ROW
EXECUTE FUNCTION trigger_set_timestamp();

DROP TRIGGER IF EXISTS set_updated_at ON purchase_order_items;
CREATE TRIGGER set_updated_at
BEFORE UPDATE ON purchase_order_items
FOR EACH ROW
EXECUTE FUNCTION trigger_set_timestamp();

-- End of 20260506000000_purchase_orders_and_preorders.sql


-- File: 20260506000001_purchase_order_rpcs.sql
-- ============================================================
-- Migration: Purchase Order RPCs (Fixed Schema)
-- ============================================================
-- Description: RPC functions for confirming and receiving POs,
-- and handling preorder fulfillment. Corrected for schema.
-- ============================================================

-- 1. Confirm Purchase Order
CREATE OR REPLACE FUNCTION confirm_purchase_order(p_po_id UUID)
RETURNS purchase_orders
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_po purchase_orders;
BEGIN
    SELECT * INTO v_po FROM purchase_orders WHERE id = p_po_id;
    
    IF v_po.id IS NULL THEN
        RAISE EXCEPTION 'Purchase Order not found';
    END IF;

    IF v_po.status != 'draft' THEN
        RAISE EXCEPTION 'Only draft Purchase Orders can be confirmed';
    END IF;

    -- Generate PO Number
    v_po.po_number := generate_po_number(v_po.tenant_id);
    v_po.status := 'pending';
    v_po.updated_at := NOW();

    UPDATE purchase_orders
    SET po_number = v_po.po_number,
        status = v_po.status,
        updated_at = v_po.updated_at
    WHERE id = p_po_id
    RETURNING * INTO v_po;

    RETURN v_po;
END;
$$;

-- 2. Receive Purchase Order
-- p_received_items: JSONB array of { product_id, received_qty, batch_no, expiry_date, unit_cost, unit_price }
CREATE OR REPLACE FUNCTION receive_purchase_order(
    p_po_id UUID,
    p_received_items JSONB
)
RETURNS purchase_orders
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_po purchase_orders;
    v_item RECORD;
    v_received_item RECORD;
    v_total_preorder_qty INTEGER;
    v_to_fulfill INTEGER;
    v_remaining_received INTEGER;
    v_batch_id UUID;
    v_staff_id UUID;
BEGIN
    -- Get current user ID (staff_id)
    v_staff_id := auth.uid();

    SELECT * INTO v_po FROM purchase_orders WHERE id = p_po_id;
    
    IF v_po.id IS NULL THEN
        RAISE EXCEPTION 'Purchase Order not found';
    END IF;

    IF v_po.status NOT IN ('pending', 'partially_received') THEN
        RAISE EXCEPTION 'Purchase Order must be pending or partially received to receive stock';
    END IF;

    FOR v_received_item IN SELECT * FROM jsonb_to_recordset(p_received_items) AS x(
        product_id UUID, received_qty INTEGER, batch_no TEXT, expiry_date DATE, unit_cost DECIMAL, unit_price DECIMAL
    )
    LOOP
        -- 1. Calculate total preorder_quantity for this product in this branch
        SELECT SUM(preorder_quantity) INTO v_total_preorder_qty
        FROM branch_inventory
        WHERE branch_id = v_po.branch_id AND product_id = v_received_item.product_id;

        v_total_preorder_qty := COALESCE(v_total_preorder_qty, 0);
        
        -- 2. Determine fulfillment
        v_to_fulfill := LEAST(v_received_item.received_qty, v_total_preorder_qty);
        v_remaining_received := v_received_item.received_qty - v_to_fulfill;

        -- 3. Fulfill preorders (decrement preorder_quantity)
        IF v_to_fulfill > 0 THEN
            WITH fulfilled AS (
                SELECT id, LEAST(preorder_quantity, v_to_fulfill) as current_fulfill
                FROM branch_inventory
                WHERE branch_id = v_po.branch_id AND product_id = v_received_item.product_id AND preorder_quantity > 0
                ORDER BY created_at ASC
            )
            UPDATE branch_inventory bi
            SET preorder_quantity = bi.preorder_quantity - f.current_fulfill,
                updated_at = NOW()
            FROM fulfilled f
            WHERE bi.id = f.id;
        END IF;

        -- 4. Create/Update Batch in branch_inventory
        INSERT INTO branch_inventory (
            tenant_id, branch_id, product_id, stock_quantity, 
            batch_no, expiry_date, cost_price, selling_price, 
            purchase_invoice, purchase_code, added_by, 
            is_active
        ) VALUES (
            v_po.tenant_id, v_po.branch_id, v_received_item.product_id, v_remaining_received,
            v_received_item.batch_no, v_received_item.expiry_date, v_received_item.unit_cost, v_received_item.unit_price,
            v_po.po_number, v_po.po_number, v_staff_id::text,
            TRUE
        ) RETURNING id INTO v_batch_id;

        -- 5. Record Inventory Transaction
        INSERT INTO inventory_transactions (
            tenant_id, branch_id, product_id, branch_inventory_id,
            transaction_type, quantity_delta, previous_quantity, new_quantity,
            unit_cost, reference_id, reference_type, staff_id
        ) VALUES (
            v_po.tenant_id, v_po.branch_id, v_received_item.product_id, v_batch_id,
            'restock'::transaction_type, v_received_item.received_qty, 0, v_remaining_received,
            v_received_item.unit_cost, v_po.id, 'purchase_order', v_staff_id
        );

        -- 6. Update purchase_order_items.received_qty
        UPDATE purchase_order_items
        SET received_qty = received_qty + v_received_item.received_qty,
            updated_at = NOW()
        WHERE po_id = p_po_id AND product_id = v_received_item.product_id;

    END LOOP;

    -- 7. Update PO status
    IF NOT EXISTS (
        SELECT 1 FROM purchase_order_items 
        WHERE po_id = p_po_id AND received_qty < expected_qty
    ) THEN
        UPDATE purchase_orders SET status = 'completed', updated_at = NOW() WHERE id = p_po_id;
    ELSE
        UPDATE purchase_orders SET status = 'partially_received', updated_at = NOW() WHERE id = p_po_id;
    END IF;

    SELECT * INTO v_po FROM purchase_orders WHERE id = p_po_id;
    RETURN v_po;
END;
$$;

-- End of 20260506000001_purchase_order_rpcs.sql


-- File: 20260506000002_patch_inventory_functions_for_preorders.sql
-- ============================================================
-- Migration: Patch Inventory Functions for Preorders (Fixed Schema)
-- ============================================================
-- Description: Updates checkout and POS triggers to handle
-- preorder_quantity when stock is insufficient.
-- Corrected for schema where tenant-specific product details (price, allow_preorder)
-- reside in branch_inventory.
-- ============================================================

-- 1. Update checkout_storefront_order to support preorders
CREATE OR REPLACE FUNCTION checkout_storefront_order(
    p_tenant_id UUID,
    p_branch_id UUID,
    p_customer_id UUID,
    p_order_type order_type,
    p_fulfillment_type fulfillment_type,
    p_subtotal DECIMAL,
    p_delivery_fee DECIMAL,
    p_tax_amount DECIMAL,
    p_total_amount DECIMAL,
    p_delivery_address_id UUID,
    p_special_instructions TEXT,
    p_items JSONB, -- Array of { product_id, product_name, quantity, unit_price, subtotal }
    p_service_charge DECIMAL DEFAULT 0,
    p_payment_reference TEXT DEFAULT NULL,
    p_billing_address TEXT DEFAULT NULL,
    p_shipping_address TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_order_id UUID;
    v_item RECORD;
    v_batch RECORD;
    v_req_qty INTEGER;
    v_available_qty INTEGER;
    v_allocated_qty INTEGER;
    v_allocations JSONB;
    v_primary_batch_id UUID;
    v_preorders_enabled BOOLEAN;
    v_allow_preorder BOOLEAN;
BEGIN
    -- Check if preorders are enabled for the tenant
    SELECT preorders_enabled INTO v_preorders_enabled FROM tenants WHERE id = p_tenant_id;

    -- Validate totals
    IF p_total_amount != (p_subtotal + p_delivery_fee + p_tax_amount + p_service_charge) THEN
        RAISE EXCEPTION 'Total amount does not match subtotal + fees + tax + service charge';
    END IF;

    -- Create the order header
    INSERT INTO orders (
        tenant_id, branch_id, order_number, customer_id,
        order_type, order_status, payment_status, payment_method, payment_reference,
        subtotal, delivery_fee, tax_amount, service_charge, total_amount,
        fulfillment_type, delivery_address_id, special_instructions,
        billing_address, shipping_address
    ) VALUES (
        p_tenant_id,
        p_branch_id,
        'ORD-' || FLOOR(EXTRACT(EPOCH FROM NOW()))::TEXT || '-' || SUBSTRING(MD5(RANDOM()::TEXT) FROM 1 FOR 4),
        p_customer_id,
        p_order_type,
        'pending'::order_status,
        CASE WHEN p_payment_reference IS NOT NULL THEN 'paid'::payment_status ELSE 'unpaid'::payment_status END,
        'card'::payment_method,
        p_payment_reference,
        p_subtotal, p_delivery_fee, p_tax_amount, p_service_charge, p_total_amount,
        p_fulfillment_type,
        p_delivery_address_id,
        p_special_instructions,
        p_billing_address,
        p_shipping_address
    ) RETURNING id INTO v_order_id;

    -- Process each item
    FOR v_item IN SELECT * FROM jsonb_to_recordset(p_items) AS x(
        product_id UUID, product_name TEXT, quantity INTEGER, unit_price DECIMAL, subtotal DECIMAL
    )
    LOOP
        v_req_qty := v_item.quantity;
        v_allocations := '[]'::jsonb;
        v_primary_batch_id := NULL;

        -- 1. Try to allocate from stock (FIFO)
        FOR v_batch IN 
            SELECT id, (stock_quantity - COALESCE(reserved_quantity, 0)) AS available_balance, allow_preorder
            FROM branch_inventory
            WHERE branch_id = p_branch_id 
              AND product_id = v_item.product_id 
              AND is_active = true
              AND (stock_quantity - COALESCE(reserved_quantity, 0)) > 0
            ORDER BY expiry_date ASC NULLS LAST, created_at ASC
            FOR UPDATE
        LOOP
            IF v_req_qty <= 0 THEN EXIT; END IF;

            v_available_qty := v_batch.available_balance;
            v_allocated_qty := LEAST(v_available_qty, v_req_qty);

            UPDATE branch_inventory
            SET reserved_quantity = COALESCE(reserved_quantity, 0) + v_allocated_qty,
                updated_at = NOW()
            WHERE id = v_batch.id;

            IF v_primary_batch_id IS NULL THEN
                v_primary_batch_id := v_batch.id;
            END IF;

            v_allocations := v_allocations || jsonb_build_object(
                'batch_id', v_batch.id,
                'quantity', v_allocated_qty,
                'is_preorder', false
            );

            v_req_qty := v_req_qty - v_allocated_qty;
        END LOOP;

        -- 2. Handle remaining as preorder if enabled
        IF v_req_qty > 0 THEN
            -- Check allow_preorder from any branch_inventory record for this product/tenant
            SELECT allow_preorder INTO v_allow_preorder 
            FROM branch_inventory 
            WHERE branch_id = p_branch_id AND product_id = v_item.product_id 
            LIMIT 1;
            
            IF COALESCE(v_preorders_enabled, false) AND COALESCE(v_allow_preorder, false) THEN
                -- Find or create a branch_inventory record to hold the preorder count
                SELECT id INTO v_primary_batch_id 
                FROM branch_inventory 
                WHERE branch_id = p_branch_id AND product_id = v_item.product_id 
                LIMIT 1 FOR UPDATE;

                IF v_primary_batch_id IS NULL THEN
                    INSERT INTO branch_inventory (
                        tenant_id, branch_id, product_id, stock_quantity, preorder_quantity, cost_price
                    ) VALUES (
                        p_tenant_id, p_branch_id, v_item.product_id, 0, v_req_qty, 0
                    ) RETURNING id INTO v_primary_batch_id;
                ELSE
                    UPDATE branch_inventory 
                    SET preorder_quantity = COALESCE(preorder_quantity, 0) + v_req_qty,
                        updated_at = NOW()
                    WHERE id = v_primary_batch_id;
                END IF;

                v_allocations := v_allocations || jsonb_build_object(
                    'batch_id', v_primary_batch_id,
                    'quantity', v_req_qty,
                    'is_preorder', true
                );
                v_req_qty := 0;
            ELSE
                RAISE EXCEPTION 'Insufficient stock for product: % (short by %)', v_item.product_name, v_req_qty;
            END IF;
        END IF;

        INSERT INTO public.sale_items (
            tenant_id, order_id, branch_id, inventory_id,
            product_id, product_name, quantity, unit_price, subtotal,
            discount_amount, batch_allocations
        ) VALUES (
            p_tenant_id, v_order_id, p_branch_id, v_primary_batch_id,
            v_item.product_id, v_item.product_name, v_item.quantity, v_item.unit_price, v_item.subtotal,
            0, v_allocations
        );
    END LOOP;

    RETURN v_order_id;
END;
$$;

-- 2. Update trigger_sync_inventory_on_sale for POS preorders
CREATE OR REPLACE FUNCTION trigger_sync_inventory_on_sale()
RETURNS TRIGGER AS $$
DECLARE
    v_item RECORD;
    v_batch RECORD;
    v_req_qty INTEGER;
    v_available INTEGER;
    v_deducted INTEGER;
    v_preorders_enabled BOOLEAN;
    v_allow_preorder BOOLEAN;
BEGIN
    IF NEW.sale_status = 'completed' THEN
        SELECT preorders_enabled INTO v_preorders_enabled FROM tenants WHERE id = NEW.tenant_id;

        FOR v_item IN
            SELECT product_id, quantity
            FROM sale_items
            WHERE sale_id = NEW.id
        LOOP
            v_req_qty := v_item.quantity;

            -- 1. Deduct from available stock batches first
            FOR v_batch IN 
                SELECT id, stock_quantity 
                FROM branch_inventory 
                WHERE branch_id = NEW.branch_id AND product_id = v_item.product_id AND stock_quantity > 0
                ORDER BY created_at ASC 
                FOR UPDATE
            LOOP
                IF v_req_qty <= 0 THEN EXIT; END IF;
                v_deducted := LEAST(v_batch.stock_quantity, v_req_qty);
                
                UPDATE branch_inventory 
                SET stock_quantity = stock_quantity - v_deducted,
                    updated_at = NOW()
                WHERE id = v_batch.id;
                
                v_req_qty := v_req_qty - v_deducted;
            END LOOP;

            -- 2. Handle remainder as preorder if enabled
            IF v_req_qty > 0 THEN
                SELECT allow_preorder INTO v_allow_preorder 
                FROM branch_inventory 
                WHERE branch_id = NEW.branch_id AND product_id = v_item.product_id 
                LIMIT 1;
                
                IF COALESCE(v_preorders_enabled, false) AND COALESCE(v_allow_preorder, false) THEN
                    -- Update preorder_quantity on any branch record (or create one)
                    UPDATE branch_inventory 
                    SET preorder_quantity = COALESCE(preorder_quantity, 0) + v_req_qty,
                        updated_at = NOW()
                    WHERE id = (SELECT id FROM branch_inventory WHERE branch_id = NEW.branch_id AND product_id = v_item.product_id LIMIT 1 FOR UPDATE);
                    
                    IF NOT FOUND THEN
                        INSERT INTO branch_inventory (
                            tenant_id, branch_id, product_id, stock_quantity, preorder_quantity, cost_price
                        ) VALUES (
                            NEW.tenant_id, NEW.branch_id, v_item.product_id, 0, v_req_qty, 0
                        );
                    END IF;
                ELSE
                    RAISE WARNING 'Insufficient stock for product % in sale %. Stock is 0 and preorders disabled.',
                        v_item.product_id, NEW.id;
                END IF;
            END IF;
        END LOOP;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 3. Update complete_sale_transaction to support preorders
CREATE OR REPLACE FUNCTION complete_sale_transaction(
    p_tenant_id UUID,
    p_branch_id UUID,
    p_cashier_id UUID,
    p_customer_id UUID,
    p_cart_items JSONB,
    p_subtotal DECIMAL,
    p_tax_amount DECIMAL,
    p_discount_amount DECIMAL,
    p_total_amount DECIMAL,
    p_payment_method payment_method,
    p_payment_reference TEXT DEFAULT NULL
)
RETURNS TABLE (
    sale_id UUID,
    sale_number VARCHAR,
    success BOOLEAN,
    error_message TEXT
) AS $$
DECLARE
    v_sale_id UUID;
    v_sale_number VARCHAR;
    v_item JSONB;
    v_product_id UUID;
    v_quantity INTEGER;
    v_available_stock INTEGER;
    v_preorders_enabled BOOLEAN;
    v_allow_preorder BOOLEAN;
    v_req_qty INTEGER;
    v_deducted INTEGER;
    v_batch RECORD;
BEGIN
    -- Check if preorders are enabled for the tenant
    SELECT preorders_enabled INTO v_preorders_enabled FROM tenants WHERE id = p_tenant_id;

    -- Start transaction
    BEGIN
        -- Verify stock availability (unless preorder is allowed)
        FOR v_item IN SELECT * FROM jsonb_array_elements(p_cart_items)
        LOOP
            v_product_id := (v_item->>'product_id')::UUID;
            v_quantity := (v_item->>'quantity')::INTEGER;

            SELECT (stock_quantity - reserved_quantity), allow_preorder 
            INTO v_available_stock, v_allow_preorder
            FROM branch_inventory
            WHERE branch_id = p_branch_id AND product_id = v_product_id;

            IF (v_available_stock IS NULL OR v_available_stock < v_quantity) 
               AND NOT (COALESCE(v_preorders_enabled, false) AND COALESCE(v_allow_preorder, false)) THEN
                RETURN QUERY SELECT
                    NULL::UUID as sale_id,
                    NULL::VARCHAR as sale_number,
                    FALSE as success,
                    'Insufficient stock for product: ' || (v_item->>'product_name') as error_message;
                RETURN;
            END IF;
        END LOOP;

        -- Create sale record
        INSERT INTO sales (
            tenant_id, branch_id, cashier_id, customer_id,
            subtotal, tax_amount, discount_amount, total_amount,
            payment_method, payment_reference, status
        ) VALUES (
            p_tenant_id, p_branch_id, p_cashier_id, p_customer_id,
            p_subtotal, p_tax_amount, p_discount_amount, p_total_amount,
            p_payment_method, p_payment_reference, 'completed'
        )
        RETURNING id, sale_number INTO v_sale_id, v_sale_number;

        -- Insert sale items
        INSERT INTO sale_items (
            sale_id, tenant_id, product_id, product_name, quantity, unit_price, discount_amount, subtotal
        )
        SELECT
            v_sale_id, p_tenant_id, (item->>'product_id')::UUID, item->>'product_name',
            (item->>'quantity')::INTEGER, (item->>'unit_price')::DECIMAL,
            COALESCE((item->>'discount_amount')::DECIMAL, 0), (item->>'subtotal')::DECIMAL
        FROM jsonb_array_elements(p_cart_items) AS item;

        -- Deduct stock / Increment preorders
        FOR v_item IN SELECT * FROM jsonb_array_elements(p_cart_items)
        LOOP
            v_product_id := (v_item->>'product_id')::UUID;
            v_req_qty := (v_item->>'quantity')::INTEGER;

            -- Deduct from available stock batches first
            FOR v_batch IN 
                SELECT id, stock_quantity 
                FROM branch_inventory 
                WHERE branch_id = p_branch_id AND product_id = v_product_id AND stock_quantity > 0
                ORDER BY created_at ASC 
                FOR UPDATE
            LOOP
                IF v_req_qty <= 0 THEN EXIT; END IF;
                v_deducted := LEAST(v_batch.stock_quantity, v_req_qty);
                
                UPDATE branch_inventory 
                SET stock_quantity = stock_quantity - v_deducted,
                    updated_at = NOW()
                WHERE id = v_batch.id;

                -- Create inventory transaction
                INSERT INTO inventory_transactions (
                    tenant_id, branch_id, product_id, branch_inventory_id,
                    transaction_type, quantity_delta, previous_quantity, new_quantity,
                    reference_id, reference_type, staff_id
                ) VALUES (
                    p_tenant_id, p_branch_id, v_product_id, v_batch.id,
                    'sale'::transaction_type, -v_deducted, v_batch.stock_quantity, v_batch.stock_quantity - v_deducted,
                    v_sale_id, 'sale', p_cashier_id
                );
                
                v_req_qty := v_req_qty - v_deducted;
            END LOOP;

            -- Handle remainder as preorder
            IF v_req_qty > 0 THEN
                UPDATE branch_inventory 
                SET preorder_quantity = COALESCE(preorder_quantity, 0) + v_req_qty,
                    updated_at = NOW()
                WHERE id = (SELECT id FROM branch_inventory WHERE branch_id = p_branch_id AND product_id = v_product_id LIMIT 1 FOR UPDATE);
                
                IF NOT FOUND THEN
                    INSERT INTO branch_inventory (
                        tenant_id, branch_id, product_id, stock_quantity, preorder_quantity, cost_price
                    ) VALUES (
                        p_tenant_id, p_branch_id, v_product_id, 0, v_req_qty, 0
                    );
                END IF;

                -- Create inventory transaction for preorder part
                INSERT INTO inventory_transactions (
                    tenant_id, branch_id, product_id,
                    transaction_type, quantity_delta, previous_quantity, new_quantity,
                    reference_id, reference_type, notes, staff_id
                ) VALUES (
                    p_tenant_id, p_branch_id, v_product_id,
                    'sale'::transaction_type, -v_req_qty, 0, 0,
                    v_sale_id, 'sale', 'Preorder recorded', p_cashier_id
                );
            END IF;
        END LOOP;

        RETURN QUERY SELECT v_sale_id, v_sale_number, TRUE, NULL::TEXT;
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT NULL::UUID, NULL::VARCHAR, FALSE, SQLERRM;
    END;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Update search_products_for_pos to include out-of-stock items that allow preorder
CREATE OR REPLACE FUNCTION search_products_for_pos(
    p_tenant_id UUID,
    p_branch_id UUID,
    p_search_term TEXT,
    p_limit INTEGER DEFAULT 20
)
RETURNS TABLE (
    product_id UUID,
    product_name VARCHAR,
    sku VARCHAR,
    barcode VARCHAR,
    category VARCHAR,
    unit_price DECIMAL,
    cost_price DECIMAL,
    image_url TEXT,
    stock_quantity INTEGER,
    reserved_quantity INTEGER,
    available_quantity INTEGER,
    low_stock_threshold INTEGER,
    allow_preorder BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        bi.product_id,
        bi.product_name,
        bi.sku,
        bi.barcode,
        p.category,
        bi.selling_price as unit_price,
        bi.cost_price,
        bi.image_url,
        bi.stock_quantity,
        bi.reserved_quantity,
        (bi.stock_quantity - bi.reserved_quantity) as available_quantity,
        bi.low_stock_threshold,
        bi.allow_preorder
    FROM branch_inventory bi
    JOIN products p ON p.id = bi.product_id
    WHERE bi.tenant_id = p_tenant_id
        AND bi.branch_id = p_branch_id
        AND p.is_active = TRUE
        AND bi.is_active = TRUE
        AND p.deleted_at IS NULL
        AND (
            (bi.stock_quantity - bi.reserved_quantity) > 0
            OR (bi.allow_preorder = TRUE)
        )
        AND (
            bi.product_name ILIKE '%' || p_search_term || '%'
            OR bi.sku ILIKE '%' || p_search_term || '%'
            OR bi.barcode = p_search_term
        )
    ORDER BY bi.product_name
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. Update marketplace_products_with_stock view
-- Using INNER JOIN because we only want products actually listed in a tenant's branch_inventory
CREATE OR REPLACE VIEW marketplace_products_with_stock AS
SELECT
    bi.product_id as id,
    bi.tenant_id,
    bi.product_name as name,
    p.description,
    bi.sku,
    bi.barcode,
    p.category,
    bi.selling_price AS price,
    bi.image_url,
    COALESCE(SUM(bi.stock_quantity - bi.reserved_quantity), 0)::INTEGER AS stock_quantity,
    (COALESCE(SUM(bi.stock_quantity - bi.reserved_quantity), 0) > 0 OR bi.allow_preorder = TRUE) AS is_available,
    bi.allow_preorder,
    p.created_at,
    p.updated_at
FROM branch_inventory bi
JOIN products p ON p.id = bi.product_id
WHERE p.is_active = TRUE
  AND bi.is_active = TRUE
  AND p.deleted_at IS NULL
GROUP BY bi.product_id, bi.tenant_id, bi.product_name, p.description, bi.sku, bi.barcode,
         p.category, bi.selling_price, bi.image_url, bi.allow_preorder, p.created_at, p.updated_at;

-- End of 20260506000002_patch_inventory_functions_for_preorders.sql


-- File: 20260506000003_expense_tracker_system.sql
-- ============================================================
-- Migration: Expense Tracker System
-- ============================================================
-- Description: Implements comprehensive expense tracking, 
-- recurring bills, and delegated financial permissions.
-- ============================================================

-- 1. Update Users Table for Permission Delegation
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS can_manage_expenses BOOLEAN DEFAULT FALSE;

-- 2. Create Enums
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'expense_status') THEN
        CREATE TYPE expense_status AS ENUM ('pending', 'approved', 'rejected', 'paid', 'cancelled');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'recurrence_interval') THEN
        CREATE TYPE recurrence_interval AS ENUM ('none', 'weekly', 'monthly', 'quarterly', 'yearly');
    END IF;
END$$;

-- 3. Create Expense Types Table
CREATE TABLE IF NOT EXISTS expense_types (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE, -- NULL for global defaults
    name VARCHAR(100) NOT NULL,
    is_auto_approve BOOLEAN DEFAULT FALSE,
    is_default BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- RLS for expense_types
ALTER TABLE expense_types ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view relevant expense types" ON expense_types;
CREATE POLICY "Users can view relevant expense types"
    ON expense_types FOR SELECT
    USING (tenant_id IS NULL OR tenant_id IN (SELECT tenant_id FROM users WHERE id = auth.uid()));

DROP POLICY IF EXISTS "Admins can manage expense types" ON expense_types;
CREATE POLICY "Admins can manage expense types"
    ON expense_types FOR ALL
    USING (
        tenant_id IN (SELECT tenant_id FROM users WHERE id = auth.uid() AND role = 'tenant_admin')
    );

-- 4. Create Expenses Table
CREATE TABLE IF NOT EXISTS expenses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
    expense_type_id UUID NOT NULL REFERENCES expense_types(id),
    
    -- Basic Info
    amount DECIMAL(12,2) NOT NULL CHECK (amount >= 0),
    description TEXT NOT NULL,
    expense_date DATE NOT NULL DEFAULT CURRENT_DATE,
    status expense_status DEFAULT 'pending',
    
    -- Tracking
    raised_by UUID NOT NULL REFERENCES users(id),
    approved_by UUID REFERENCES users(id),
    paid_by UUID REFERENCES users(id),
    rejection_reason TEXT,
    
    -- Supplier & PO Link
    supplier_id UUID REFERENCES suppliers(id) ON DELETE SET NULL,
    po_id UUID REFERENCES purchase_orders(id) ON DELETE SET NULL,
    invoice_number VARCHAR(100),
    raised_date DATE,
    due_date DATE,
    payment_terms TEXT,
    
    -- Payment Details
    payment_collected_by TEXT,
    bank_name TEXT,
    bank_account_number TEXT,
    receipt_url TEXT, -- Path to original bill in storage
    payment_evidence_url TEXT, -- Path to proof of payment in storage
    
    -- Recurrence Logic
    is_recurring BOOLEAN DEFAULT FALSE,
    recur_interval recurrence_interval DEFAULT 'none',
    next_recur_date DATE,
    parent_recurring_id UUID REFERENCES expenses(id) ON DELETE SET NULL,
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- RLS for expenses
ALTER TABLE expenses ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view expenses in their tenant" ON expenses;
CREATE POLICY "Users can view expenses in their tenant"
    ON expenses FOR SELECT
    USING (tenant_id IN (SELECT tenant_id FROM users WHERE id = auth.uid()));

DROP POLICY IF EXISTS "Staff can insert expenses" ON expenses;
CREATE POLICY "Staff can insert expenses"
    ON expenses FOR INSERT
    WITH CHECK (tenant_id IN (SELECT tenant_id FROM users WHERE id = auth.uid()));

DROP POLICY IF EXISTS "Admins and managers can update expenses" ON expenses;
CREATE POLICY "Admins and managers can update expenses"
    ON expenses FOR UPDATE
    USING (
        tenant_id IN (
            SELECT tenant_id FROM users 
            WHERE id = auth.uid() 
            AND (role = 'tenant_admin' OR can_manage_expenses = TRUE)
        )
    );

-- 5. Auto-Approval Trigger
CREATE OR REPLACE FUNCTION trigger_auto_approve_expense()
RETURNS TRIGGER AS $$
DECLARE
    v_auto BOOLEAN;
BEGIN
    SELECT is_auto_approve INTO v_auto FROM expense_types WHERE id = NEW.expense_type_id;
    
    IF v_auto THEN
        NEW.status := 'approved';
        NEW.approved_by := NEW.raised_by; -- Self-approved if category allows
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER auto_approve_expense_trigger
BEFORE INSERT ON expenses
FOR EACH ROW
EXECUTE FUNCTION trigger_auto_approve_expense();

-- 6. Seed Default Expense Types
INSERT INTO expense_types (name, is_auto_approve, is_default) VALUES
('Product Purchase', FALSE, TRUE),
('Rent', FALSE, TRUE),
('Utilities', FALSE, TRUE),
('Salaries', FALSE, TRUE),
('Maintenance', FALSE, TRUE),
('Marketing', FALSE, TRUE),
('Internet', TRUE, TRUE),
('Petty Cash', TRUE, TRUE);

-- 7. Recurring Expense Generation Function
-- To be called by a cron job or manual trigger
CREATE OR REPLACE FUNCTION generate_recurring_expenses()
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_count INTEGER := 0;
    v_expense RECORD;
    v_new_date DATE;
BEGIN
    FOR v_expense IN 
        SELECT * FROM expenses 
        WHERE is_recurring = TRUE 
          AND next_recur_date <= CURRENT_DATE
          AND parent_recurring_id IS NULL -- Only original templates
    LOOP
        -- Calculate next date
        v_new_date := CASE v_expense.recur_interval
            WHEN 'weekly' THEN v_expense.next_recur_date + INTERVAL '7 days'
            WHEN 'monthly' THEN v_expense.next_recur_date + INTERVAL '1 month'
            WHEN 'quarterly' THEN v_expense.next_recur_date + INTERVAL '3 months'
            WHEN 'yearly' THEN v_expense.next_recur_date + INTERVAL '1 year'
            ELSE NULL
        END;

        -- Create new pending instance
        INSERT INTO expenses (
            tenant_id, branch_id, expense_type_id, amount, description, 
            expense_date, status, raised_by, supplier_id, po_id, 
            is_recurring, recur_interval, parent_recurring_id
        ) VALUES (
            v_expense.tenant_id, v_expense.branch_id, v_expense.expense_type_id, v_expense.amount, v_expense.description,
            v_expense.next_recur_date, 'pending', v_expense.raised_by, v_expense.supplier_id, v_expense.po_id,
            FALSE, 'none', v_expense.id
        );

        -- Update the template's next date
        UPDATE expenses 
        SET next_recur_date = v_new_date,
            updated_at = NOW()
        WHERE id = v_expense.id;

        v_count := v_count + 1;
    END LOOP;

    RETURN v_count;
END;
$$;

-- Standard updated_at trigger
DROP TRIGGER IF EXISTS set_updated_at ON expense_types;
CREATE TRIGGER set_updated_at BEFORE UPDATE ON expense_types FOR EACH ROW EXECUTE FUNCTION trigger_set_timestamp();

DROP TRIGGER IF EXISTS set_updated_at ON expenses;
CREATE TRIGGER set_updated_at BEFORE UPDATE ON expenses FOR EACH ROW EXECUTE FUNCTION trigger_set_timestamp();

-- End of 20260506000003_expense_tracker_system.sql


-- File: 20260506000004_create_expense_storage.sql
-- ============================================================================
-- CREATE STORAGE BUCKET FOR EXPENSES
-- ============================================================================

-- Expense Documents Bucket (Private)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'expense-documents',
    'expense-documents',
    false, -- Private access
    5242880, -- 5MB limit
    ARRAY['application/pdf', 'image/jpeg', 'image/png', 'image/jpg']
)
ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- STORAGE RLS POLICIES
-- ============================================================================

-- POLICY: Staff can upload documents to their tenant's folder
-- Folder structure: /tenant_id/staff_id/filename.ext
DROP POLICY IF EXISTS "Staff can upload expense documents" ON storage.objects;
CREATE POLICY "Staff can upload expense documents"
    ON storage.objects FOR INSERT
    TO authenticated
    WITH CHECK (
        bucket_id = 'expense-documents' AND
        (storage.foldername(name))[1] IN (SELECT tenant_id::text FROM users WHERE id = auth.uid())
    );

-- POLICY: Users can view documents in their tenant
DROP POLICY IF EXISTS "Users can view tenant expense documents" ON storage.objects;
CREATE POLICY "Users can view tenant expense documents"
    ON storage.objects FOR SELECT
    TO authenticated
    USING (
        bucket_id = 'expense-documents' AND
        (storage.foldername(name))[1] IN (SELECT tenant_id::text FROM users WHERE id = auth.uid())
    );

-- POLICY: Admins/Delegated Staff can delete documents in their tenant
DROP POLICY IF EXISTS "Admins can delete tenant expense documents" ON storage.objects;
CREATE POLICY "Admins can delete tenant expense documents"
    ON storage.objects FOR DELETE
    TO authenticated
    USING (
        bucket_id = 'expense-documents' AND
        (storage.foldername(name))[1] IN (
            SELECT tenant_id::text FROM users 
            WHERE id = auth.uid() 
            AND (role = 'tenant_admin' OR can_manage_expenses = TRUE)
        )
    );

-- End of 20260506000004_create_expense_storage.sql


-- File: 20260507000000_po_receipt_groups.sql
-- ============================================================
-- Migration: Add Purchase Order Receipt Groups
-- ============================================================
-- Description: Creates tables to group PO receiving events, 
--              enabling better history tracking and reporting.
-- ============================================================

-- 1. Create Receipt Groups
CREATE TABLE IF NOT EXISTS purchase_order_receipts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    po_id UUID NOT NULL REFERENCES purchase_orders(id) ON DELETE CASCADE,
    staff_id UUID NOT NULL REFERENCES users(id),
    received_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. Create Receipt Items
CREATE TABLE IF NOT EXISTS purchase_order_receipt_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    receipt_id UUID NOT NULL REFERENCES purchase_order_receipts(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id),
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    unit_cost DECIMAL(12,2) NOT NULL,
    batch_no VARCHAR(100),
    expiry_date DATE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3. RLS Policies
ALTER TABLE purchase_order_receipts ENABLE ROW LEVEL SECURITY;
ALTER TABLE purchase_order_receipt_items ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view PO receipts in their tenant" ON purchase_order_receipts;
CREATE POLICY "Users can view PO receipts in their tenant"
    ON purchase_order_receipts FOR SELECT
    USING (tenant_id IN (SELECT tenant_id FROM users WHERE id = auth.uid()));

DROP POLICY IF EXISTS "Users can view PO receipt items in their tenant" ON purchase_order_receipt_items;
CREATE POLICY "Users can view PO receipt items in their tenant"
    ON purchase_order_receipt_items FOR SELECT
    USING (receipt_id IN (SELECT id FROM purchase_order_receipts WHERE tenant_id IN (SELECT tenant_id FROM users WHERE id = auth.uid())));

-- 4. Update the Receive RPC to include these tables
CREATE OR REPLACE FUNCTION receive_purchase_order(
    p_po_id UUID,
    p_received_items JSONB,
    p_notes TEXT DEFAULT NULL
)
RETURNS purchase_orders
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_po purchase_orders;
    v_item RECORD;
    v_received_item RECORD;
    v_total_preorder_qty INTEGER;
    v_to_fulfill INTEGER;
    v_remaining_received INTEGER;
    v_batch_id UUID;
    v_staff_id UUID;
    v_receipt_id UUID;
BEGIN
    -- Get current user ID (staff_id)
    v_staff_id := auth.uid();

    SELECT * INTO v_po FROM purchase_orders WHERE id = p_po_id;
    
    IF v_po.id IS NULL THEN
        RAISE EXCEPTION 'Purchase Order not found';
    END IF;

    IF v_po.status NOT IN ('pending', 'partially_received') THEN
        RAISE EXCEPTION 'Purchase Order must be pending or partially received to receive stock';
    END IF;

    -- A. Create the Receipt Group record
    INSERT INTO purchase_order_receipts (tenant_id, po_id, staff_id, notes)
    VALUES (v_po.tenant_id, v_po.id, v_staff_id, p_notes)
    RETURNING id INTO v_receipt_id;

    -- B. Process each item
    FOR v_received_item IN SELECT * FROM jsonb_to_recordset(p_received_items) AS x(
        product_id UUID, received_qty INTEGER, batch_no TEXT, expiry_date DATE, unit_cost DECIMAL, unit_price DECIMAL
    )
    LOOP
        -- 1. Create Receipt Item record for history
        INSERT INTO purchase_order_receipt_items (
            receipt_id, product_id, quantity, unit_cost, batch_no, expiry_date
        ) VALUES (
            v_receipt_id, v_received_item.product_id, v_received_item.received_qty, 
            v_received_item.unit_cost, v_received_item.batch_no, v_received_item.expiry_date
        );

        -- 2. Calculate total preorder_quantity for this product in this branch
        SELECT SUM(preorder_quantity) INTO v_total_preorder_qty
        FROM branch_inventory
        WHERE branch_id = v_po.branch_id AND product_id = v_received_item.product_id;

        v_total_preorder_qty := COALESCE(v_total_preorder_qty, 0);
        
        -- 3. Determine fulfillment
        v_to_fulfill := LEAST(v_received_item.received_qty, v_total_preorder_qty);
        v_remaining_received := v_received_item.received_qty - v_to_fulfill;

        -- 4. Fulfill preorders (decrement preorder_quantity)
        IF v_to_fulfill > 0 THEN
            WITH fulfilled AS (
                SELECT id, LEAST(preorder_quantity, v_to_fulfill) as current_fulfill
                FROM branch_inventory
                WHERE branch_id = v_po.branch_id AND product_id = v_received_item.product_id AND preorder_quantity > 0
                ORDER BY created_at ASC
            )
            UPDATE branch_inventory bi
            SET preorder_quantity = bi.preorder_quantity - f.current_fulfill,
                updated_at = NOW()
            FROM fulfilled f
            WHERE bi.id = f.id;
        END IF;

        -- 5. Create/Update Batch in branch_inventory
        INSERT INTO branch_inventory (
            tenant_id, branch_id, product_id, stock_quantity, 
            batch_no, expiry_date, cost_price, selling_price, 
            purchase_invoice, purchase_code, added_by, 
            is_active
        ) VALUES (
            v_po.tenant_id, v_po.branch_id, v_received_item.product_id, v_remaining_received,
            v_received_item.batch_no, v_received_item.expiry_date, v_received_item.unit_cost, v_received_item.unit_price,
            v_po.po_number, v_po.po_number, v_staff_id::text,
            TRUE
        ) RETURNING id INTO v_batch_id;

        -- 6. Record Inventory Transaction
        INSERT INTO inventory_transactions (
            tenant_id, branch_id, product_id, branch_inventory_id,
            transaction_type, quantity_delta, previous_quantity, new_quantity,
            unit_cost, reference_id, reference_type, staff_id
        ) VALUES (
            v_po.tenant_id, v_po.branch_id, v_received_item.product_id, v_batch_id,
            'restock'::transaction_type, v_received_item.received_qty, 0, v_remaining_received,
            v_received_item.unit_cost, v_po.id, 'purchase_order', v_staff_id
        );

        -- 7. Update purchase_order_items.received_qty
        UPDATE purchase_order_items
        SET received_qty = received_qty + v_received_item.received_qty,
            updated_at = NOW()
        WHERE po_id = p_po_id AND product_id = v_received_item.product_id;

    END LOOP;

    -- 8. Update PO status
    IF NOT EXISTS (
        SELECT 1 FROM purchase_order_items 
        WHERE po_id = p_po_id AND received_qty < expected_qty
    ) THEN
        UPDATE purchase_orders SET status = 'completed', updated_at = NOW() WHERE id = p_po_id;
    ELSE
        UPDATE purchase_orders SET status = 'partially_received', updated_at = NOW() WHERE id = p_po_id;
    END IF;

    SELECT * INTO v_po FROM purchase_orders WHERE id = p_po_id;
    RETURN v_po;
END;
$$;

-- End of 20260507000000_po_receipt_groups.sql


-- File: 20260507000001_fix_po_overloading.sql
-- ============================================================
-- Migration: Fix Receive PO Function Overloading
-- ============================================================
-- Description: Drops the legacy 2-parameter receive_purchase_order
--              to resolve PostgREST ambiguity with the new 
--              3-parameter version.
-- ============================================================

-- 1. Drop the legacy version (2 parameters)
DROP FUNCTION IF EXISTS public.receive_purchase_order(UUID, JSONB);

-- 2. Ensure the new version (3 parameters) is correctly defined
-- We recreate it here just to be certain it's the primary one
CREATE OR REPLACE FUNCTION public.receive_purchase_order(
    p_po_id UUID,
    p_received_items JSONB,
    p_notes TEXT DEFAULT NULL
)
RETURNS purchase_orders
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_po purchase_orders;
    v_item RECORD;
    v_received_item RECORD;
    v_total_preorder_qty INTEGER;
    v_to_fulfill INTEGER;
    v_remaining_received INTEGER;
    v_batch_id UUID;
    v_staff_id UUID;
    v_receipt_id UUID;
BEGIN
    -- Get current user ID (staff_id)
    v_staff_id := auth.uid();

    SELECT * INTO v_po FROM purchase_orders WHERE id = p_po_id;
    
    IF v_po.id IS NULL THEN
        RAISE EXCEPTION 'Purchase Order not found';
    END IF;

    IF v_po.status NOT IN ('pending', 'partially_received') THEN
        RAISE EXCEPTION 'Purchase Order must be pending or partially received to receive stock';
    END IF;

    -- A. Create the Receipt Group record
    INSERT INTO purchase_order_receipts (tenant_id, po_id, staff_id, notes)
    VALUES (v_po.tenant_id, v_po.id, v_staff_id, p_notes)
    RETURNING id INTO v_receipt_id;

    -- B. Process each item
    FOR v_received_item IN SELECT * FROM jsonb_to_recordset(p_received_items) AS x(
        product_id UUID, received_qty INTEGER, batch_no TEXT, expiry_date DATE, unit_cost DECIMAL, unit_price DECIMAL
    )
    LOOP
        -- 1. Create Receipt Item record for history
        INSERT INTO purchase_order_receipt_items (
            receipt_id, product_id, quantity, unit_cost, batch_no, expiry_date
        ) VALUES (
            v_receipt_id, v_received_item.product_id, v_received_item.received_qty, 
            v_received_item.unit_cost, v_received_item.batch_no, v_received_item.expiry_date
        );

        -- 2. Calculate total preorder_quantity for this product in this branch
        SELECT SUM(preorder_quantity) INTO v_total_preorder_qty
        FROM branch_inventory
        WHERE branch_id = v_po.branch_id AND product_id = v_received_item.product_id;

        v_total_preorder_qty := COALESCE(v_total_preorder_qty, 0);
        
        -- 3. Determine fulfillment
        v_to_fulfill := LEAST(v_received_item.received_qty, v_total_preorder_qty);
        v_remaining_received := v_received_item.received_qty - v_to_fulfill;

        -- 4. Fulfill preorders (decrement preorder_quantity)
        IF v_to_fulfill > 0 THEN
            WITH fulfilled AS (
                SELECT id, LEAST(preorder_quantity, v_to_fulfill) as current_fulfill
                FROM branch_inventory
                WHERE branch_id = v_po.branch_id AND product_id = v_received_item.product_id AND preorder_quantity > 0
                ORDER BY created_at ASC
            )
            UPDATE branch_inventory bi
            SET preorder_quantity = bi.preorder_quantity - f.current_fulfill,
                updated_at = NOW()
            FROM fulfilled f
            WHERE bi.id = f.id;
        END IF;

        -- 5. Create/Update Batch in branch_inventory
        INSERT INTO branch_inventory (
            tenant_id, branch_id, product_id, stock_quantity, 
            batch_no, expiry_date, cost_price, selling_price, 
            purchase_invoice, purchase_code, added_by, 
            is_active
        ) VALUES (
            v_po.tenant_id, v_po.branch_id, v_received_item.product_id, v_remaining_received,
            v_received_item.batch_no, v_received_item.expiry_date, v_received_item.unit_cost, v_received_item.unit_price,
            v_po.po_number, v_po.po_number, v_staff_id::text,
            TRUE
        ) RETURNING id INTO v_batch_id;

        -- 6. Record Inventory Transaction
        INSERT INTO inventory_transactions (
            tenant_id, branch_id, product_id, branch_inventory_id,
            transaction_type, quantity_delta, previous_quantity, new_quantity,
            unit_cost, reference_id, reference_type, staff_id
        ) VALUES (
            v_po.tenant_id, v_po.branch_id, v_received_item.product_id, v_batch_id,
            'restock'::transaction_type, v_received_item.received_qty, 0, v_remaining_received,
            v_received_item.unit_cost, v_po.id, 'purchase_order', v_staff_id
        );

        -- 7. Update purchase_order_items.received_qty
        UPDATE purchase_order_items
        SET received_qty = received_qty + v_received_item.received_qty,
            updated_at = NOW()
        WHERE po_id = p_po_id AND product_id = v_received_item.product_id;

    END LOOP;

    -- 8. Update PO status
    IF NOT EXISTS (
        SELECT 1 FROM purchase_order_items 
        WHERE po_id = p_po_id AND received_qty < expected_qty
    ) THEN
        UPDATE purchase_orders SET status = 'completed', updated_at = NOW() WHERE id = p_po_id;
    ELSE
        UPDATE purchase_orders SET status = 'partially_received', updated_at = NOW() WHERE id = p_po_id;
    END IF;

    SELECT * INTO v_po FROM purchase_orders WHERE id = p_po_id;
    RETURN v_po;
END;
$$;

-- End of 20260507000001_fix_po_overloading.sql


-- File: 20260507000002_add_is_received_to_receipt_items.sql
-- ============================================================
-- Migration: Add is_received to PO Receipt Items
-- ============================================================
-- Description: Adds is_received column and updates the 
--              receive_purchase_order function to handle it.
-- ============================================================

-- 1. Add column to purchase_order_receipt_items
ALTER TABLE purchase_order_receipt_items 
ADD COLUMN IF NOT EXISTS is_received BOOLEAN DEFAULT FALSE;

-- 2. Update the RPC to handle is_received and ensure expiry_date is handled
CREATE OR REPLACE FUNCTION public.receive_purchase_order(
    p_po_id UUID,
    p_received_items JSONB,
    p_notes TEXT DEFAULT NULL
)
RETURNS purchase_orders
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_po purchase_orders;
    v_item RECORD;
    v_received_item RECORD;
    v_total_preorder_qty INTEGER;
    v_to_fulfill INTEGER;
    v_remaining_received INTEGER;
    v_batch_id UUID;
    v_staff_id UUID;
    v_receipt_id UUID;
BEGIN
    -- Get current user ID (staff_id)
    v_staff_id := auth.uid();

    SELECT * INTO v_po FROM purchase_orders WHERE id = p_po_id;
    
    IF v_po.id IS NULL THEN
        RAISE EXCEPTION 'Purchase Order not found';
    END IF;

    IF v_po.status NOT IN ('pending', 'partially_received') THEN
        RAISE EXCEPTION 'Purchase Order must be pending or partially received to receive stock';
    END IF;

    -- A. Create the Receipt Group record
    INSERT INTO purchase_order_receipts (tenant_id, po_id, staff_id, notes)
    VALUES (v_po.tenant_id, v_po.id, v_staff_id, p_notes)
    RETURNING id INTO v_receipt_id;

    -- B. Process each item
    FOR v_received_item IN SELECT * FROM jsonb_to_recordset(p_received_items) AS x(
        product_id UUID, received_qty INTEGER, batch_no TEXT, expiry_date DATE, unit_cost DECIMAL, unit_price DECIMAL, is_received BOOLEAN
    )
    LOOP
        -- 1. Create Receipt Item record for history
        INSERT INTO purchase_order_receipt_items (
            receipt_id, product_id, quantity, unit_cost, batch_no, expiry_date, is_received
        ) VALUES (
            v_receipt_id, v_received_item.product_id, v_received_item.received_qty, 
            v_received_item.unit_cost, v_received_item.batch_no, v_received_item.expiry_date,
            COALESCE(v_received_item.is_received, TRUE)
        );

        -- 2. Calculate total preorder_quantity for this product in this branch
        SELECT SUM(preorder_quantity) INTO v_total_preorder_qty
        FROM branch_inventory
        WHERE branch_id = v_po.branch_id AND product_id = v_received_item.product_id;

        v_total_preorder_qty := COALESCE(v_total_preorder_qty, 0);
        
        -- 3. Determine fulfillment
        v_to_fulfill := LEAST(v_received_item.received_qty, v_total_preorder_qty);
        v_remaining_received := v_received_item.received_qty - v_to_fulfill;

        -- 4. Fulfill preorders (decrement preorder_quantity)
        IF v_to_fulfill > 0 THEN
            WITH fulfilled AS (
                SELECT id, LEAST(preorder_quantity, v_to_fulfill) as current_fulfill
                FROM branch_inventory
                WHERE branch_id = v_po.branch_id AND product_id = v_received_item.product_id AND preorder_quantity > 0
                ORDER BY created_at ASC
            )
            UPDATE branch_inventory bi
            SET preorder_quantity = bi.preorder_quantity - f.current_fulfill,
                updated_at = NOW()
            FROM fulfilled f
            WHERE bi.id = f.id;
        END IF;

        -- 5. Create/Update Batch in branch_inventory
        INSERT INTO branch_inventory (
            tenant_id, branch_id, product_id, stock_quantity, 
            batch_no, expiry_date, cost_price, selling_price, 
            purchase_invoice, purchase_code, added_by, 
            is_active
        ) VALUES (
            v_po.tenant_id, v_po.branch_id, v_received_item.product_id, v_remaining_received,
            v_received_item.batch_no, v_received_item.expiry_date, v_received_item.unit_cost, v_received_item.unit_price,
            v_po.po_number, v_po.po_number, v_staff_id::text,
            TRUE
        ) RETURNING id INTO v_batch_id;

        -- 6. Record Inventory Transaction
        INSERT INTO inventory_transactions (
            tenant_id, branch_id, product_id, branch_inventory_id,
            transaction_type, quantity_delta, previous_quantity, new_quantity,
            unit_cost, reference_id, reference_type, staff_id
        ) VALUES (
            v_po.tenant_id, v_po.branch_id, v_received_item.product_id, v_batch_id,
            'restock'::transaction_type, v_received_item.received_qty, 0, v_remaining_received,
            v_received_item.unit_cost, v_po.id, 'purchase_order', v_staff_id
        );

        -- 7. Update purchase_order_items.received_qty
        UPDATE purchase_order_items
        SET received_qty = received_qty + v_received_item.received_qty,
            updated_at = NOW()
        WHERE po_id = p_po_id AND product_id = v_received_item.product_id;

    END LOOP;

    -- 8. Update PO status
    IF NOT EXISTS (
        SELECT 1 FROM purchase_order_items 
        WHERE po_id = p_po_id AND received_qty < expected_qty
    ) THEN
        UPDATE purchase_orders SET status = 'completed', updated_at = NOW() WHERE id = p_po_id;
    ELSE
        UPDATE purchase_orders SET status = 'partially_received', updated_at = NOW() WHERE id = p_po_id;
    END IF;

    SELECT * INTO v_po FROM purchase_orders WHERE id = p_po_id;
    RETURN v_po;
END;
$$;

-- End of 20260507000002_add_is_received_to_receipt_items.sql


-- File: 20260507000003_add_po_sync_function.sql
-- ============================================================
-- Migration: Add PO Quantity Sync Function
-- ============================================================
-- Description: Adds a function to recalculate received_qty 
--              from the actual receipt history to fix data
--              inconsistencies.
-- ============================================================

CREATE OR REPLACE FUNCTION public.sync_purchase_order_quantities(p_po_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Reset all received_qty for this PO to 0 first
    UPDATE purchase_order_items
    SET received_qty = 0,
        updated_at = NOW()
    WHERE po_id = p_po_id;

    -- Recalculate from receipt items
    WITH actual_received AS (
        SELECT 
            ri.product_id,
            SUM(ri.quantity) as total_qty
        FROM purchase_order_receipt_items ri
        JOIN purchase_order_receipts r ON ri.receipt_id = r.id
        WHERE r.po_id = p_po_id
        GROUP BY ri.product_id
    )
    UPDATE purchase_order_items poi
    SET received_qty = ar.total_qty,
        updated_at = NOW()
    FROM actual_received ar
    WHERE poi.po_id = p_po_id 
    AND poi.product_id = ar.product_id;

    -- Update PO status based on new quantities
    IF NOT EXISTS (
        SELECT 1 FROM purchase_order_items 
        WHERE po_id = p_po_id AND received_qty < expected_qty
    ) THEN
        UPDATE purchase_orders SET status = 'completed', updated_at = NOW() WHERE id = p_po_id;
    ELSIF EXISTS (
        SELECT 1 FROM purchase_order_items 
        WHERE po_id = p_po_id AND received_qty > 0
    ) THEN
        UPDATE purchase_orders SET status = 'partially_received', updated_at = NOW() WHERE id = p_po_id;
    ELSE
        UPDATE purchase_orders SET status = 'pending', updated_at = NOW() WHERE id = p_po_id;
    END IF;
END;
$$;

-- End of 20260507000003_add_po_sync_function.sql


-- File: 20260507000004_automate_po_sync.sql
-- ============================================================
-- Migration: Automate PO Quantity Tracking via Triggers
-- ============================================================
-- Description: Creates a trigger that automatically updates
--              purchase_order_items.received_qty whenever a
--              receipt item is inserted, updated, or deleted.
-- ============================================================

-- 1. Create the Trigger Function
CREATE OR REPLACE FUNCTION public.fn_sync_po_item_received_qty()
RETURNS TRIGGER AS $$
DECLARE
    v_po_id UUID;
    v_product_id UUID;
BEGIN
    -- Determine the PO ID and Product ID to sync
    IF (TG_OP = 'DELETE') THEN
        v_product_id := OLD.product_id;
        SELECT po_id INTO v_po_id FROM purchase_order_receipts WHERE id = OLD.receipt_id;
    ELSE
        v_product_id := NEW.product_id;
        SELECT po_id INTO v_po_id FROM purchase_order_receipts WHERE id = NEW.receipt_id;
    END IF;

    -- Recalculate total received for this specific product in this PO
    UPDATE purchase_order_items
    SET received_qty = COALESCE((
        SELECT SUM(ri.quantity)
        FROM purchase_order_receipt_items ri
        JOIN purchase_order_receipts r ON ri.receipt_id = r.id
        WHERE r.po_id = v_po_id AND ri.product_id = v_product_id
    ), 0),
    updated_at = NOW()
    WHERE po_id = v_po_id AND product_id = v_product_id;

    -- Update PO status based on the new totals
    IF NOT EXISTS (
        SELECT 1 FROM purchase_order_items 
        WHERE po_id = v_po_id AND received_qty < expected_qty
    ) THEN
        UPDATE purchase_orders SET status = 'completed', updated_at = NOW() WHERE id = v_po_id;
    ELSIF EXISTS (
        SELECT 1 FROM purchase_order_items 
        WHERE po_id = v_po_id AND received_qty > 0
    ) THEN
        UPDATE purchase_orders SET status = 'partially_received', updated_at = NOW() WHERE id = v_po_id;
    ELSE
        UPDATE purchase_orders SET status = 'pending', updated_at = NOW() WHERE id = v_po_id;
    END IF;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- 2. Create the Trigger
DROP TRIGGER IF EXISTS tr_sync_po_item_received_qty ON purchase_order_receipt_items;
CREATE TRIGGER tr_sync_po_item_received_qty
AFTER INSERT OR UPDATE OR DELETE ON purchase_order_receipt_items
FOR EACH ROW
EXECUTE FUNCTION public.fn_sync_po_item_received_qty();

-- 3. Cleanup: Remove the manual update from the main RPC to prevent double processing
-- Note: We keep the sync logic in the trigger for absolute accuracy.
CREATE OR REPLACE FUNCTION public.receive_purchase_order(
    p_po_id UUID,
    p_received_items JSONB,
    p_notes TEXT DEFAULT NULL
)
RETURNS purchase_orders
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_po purchase_orders;
    v_received_item RECORD;
    v_total_preorder_qty INTEGER;
    v_to_fulfill INTEGER;
    v_remaining_received INTEGER;
    v_batch_id UUID;
    v_staff_id UUID;
    v_receipt_id UUID;
BEGIN
    v_staff_id := auth.uid();
    SELECT * INTO v_po FROM purchase_orders WHERE id = p_po_id;
    
    IF v_po.id IS NULL THEN RAISE EXCEPTION 'Purchase Order not found'; END IF;
    IF v_po.status NOT IN ('pending', 'partially_received') THEN
        RAISE EXCEPTION 'Purchase Order must be pending or partially received to receive stock';
    END IF;

    INSERT INTO purchase_order_receipts (tenant_id, po_id, staff_id, notes)
    VALUES (v_po.tenant_id, v_po.id, v_staff_id, p_notes)
    RETURNING id INTO v_receipt_id;

    FOR v_received_item IN SELECT * FROM jsonb_to_recordset(p_received_items) AS x(
        product_id UUID, received_qty INTEGER, batch_no TEXT, expiry_date DATE, unit_cost DECIMAL, unit_price DECIMAL, is_received BOOLEAN
    )
    LOOP
        -- 1. Create Receipt Item (The trigger will now handle updating purchase_order_items)
        INSERT INTO purchase_order_receipt_items (
            receipt_id, product_id, quantity, unit_cost, batch_no, expiry_date, is_received
        ) VALUES (
            v_receipt_id, v_received_item.product_id, v_received_item.received_qty, 
            v_received_item.unit_cost, v_received_item.batch_no, v_received_item.expiry_date,
            COALESCE(v_received_item.is_received, TRUE)
        );

        -- 2. Calculate total preorder_quantity
        SELECT SUM(preorder_quantity) INTO v_total_preorder_qty
        FROM branch_inventory
        WHERE branch_id = v_po.branch_id AND product_id = v_received_item.product_id;
        v_total_preorder_qty := COALESCE(v_total_preorder_qty, 0);
        
        -- 3. Determine fulfillment
        v_to_fulfill := LEAST(v_received_item.received_qty, v_total_preorder_qty);
        v_remaining_received := v_received_item.received_qty - v_to_fulfill;

        -- 4. Fulfill preorders
        IF v_to_fulfill > 0 THEN
            WITH fulfilled AS (
                SELECT id, LEAST(preorder_quantity, v_to_fulfill) as current_fulfill
                FROM branch_inventory
                WHERE branch_id = v_po.branch_id AND product_id = v_received_item.product_id AND preorder_quantity > 0
                ORDER BY created_at ASC
            )
            UPDATE branch_inventory bi
            SET preorder_quantity = bi.preorder_quantity - f.current_fulfill, updated_at = NOW()
            FROM fulfilled f WHERE bi.id = f.id;
        END IF;

        -- 5. Create/Update Batch
        INSERT INTO branch_inventory (
            tenant_id, branch_id, product_id, stock_quantity, 
            batch_no, expiry_date, cost_price, selling_price, 
            purchase_invoice, purchase_code, added_by, is_active
        ) VALUES (
            v_po.tenant_id, v_po.branch_id, v_received_item.product_id, v_remaining_received,
            v_received_item.batch_no, v_received_item.expiry_date, v_received_item.unit_cost, v_received_item.unit_price,
            v_po.po_number, v_po.po_number, v_staff_id::text, TRUE
        ) RETURNING id INTO v_batch_id;

        -- 6. Record Inventory Transaction
        INSERT INTO inventory_transactions (
            tenant_id, branch_id, product_id, branch_inventory_id,
            transaction_type, quantity_delta, previous_quantity, new_quantity,
            unit_cost, reference_id, reference_type, staff_id
        ) VALUES (
            v_po.tenant_id, v_po.branch_id, v_received_item.product_id, v_batch_id,
            'restock'::transaction_type, v_received_item.received_qty, 0, v_remaining_received,
            v_received_item.unit_cost, v_po.id, 'purchase_order', v_staff_id
        );

        -- REMOVED: Manual update of purchase_order_items.received_qty
        -- (Now handled automatically by the trigger on purchase_order_receipt_items)
    END LOOP;

    -- PO Status is also handled by the trigger now
    SELECT * INTO v_po FROM purchase_orders WHERE id = p_po_id;
    RETURN v_po;
END;
$$;

-- 4. Run a one-time sync for all existing POs to ensure consistency
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN SELECT id FROM purchase_orders LOOP
        PERFORM sync_purchase_order_quantities(r.id);
    END LOOP;
END$$;

-- End of 20260507000004_automate_po_sync.sql


-- File: 20260507000005_merge_po_stock.sql
-- ============================================================
-- Migration: Merge PO Receipts into Existing Stock
-- ============================================================
-- Description: Updates receive_purchase_order to add quantities
--              to existing branch_inventory rows for the same
--              product instead of always creating new rows.
-- ============================================================

CREATE OR REPLACE FUNCTION public.receive_purchase_order(
    p_po_id UUID,
    p_received_items JSONB,
    p_notes TEXT DEFAULT NULL
)
RETURNS purchase_orders
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_po purchase_orders;
    v_received_item RECORD;
    v_total_preorder_qty INTEGER;
    v_to_fulfill INTEGER;
    v_remaining_received INTEGER;
    v_batch_id UUID;
    v_staff_id UUID;
    v_receipt_id UUID;
    v_old_qty INTEGER;
BEGIN
    v_staff_id := auth.uid();
    SELECT * INTO v_po FROM purchase_orders WHERE id = p_po_id;
    
    IF v_po.id IS NULL THEN RAISE EXCEPTION 'Purchase Order not found'; END IF;
    IF v_po.status NOT IN ('pending', 'partially_received') THEN
        RAISE EXCEPTION 'Purchase Order must be pending or partially received to receive stock';
    END IF;

    -- 1. Create the Receipt Group for history
    INSERT INTO purchase_order_receipts (tenant_id, po_id, staff_id, notes)
    VALUES (v_po.tenant_id, v_po.id, v_staff_id, p_notes)
    RETURNING id INTO v_receipt_id;

    -- 2. Process each received item
    FOR v_received_item IN SELECT * FROM jsonb_to_recordset(p_received_items) AS x(
        product_id UUID, received_qty INTEGER, batch_no TEXT, expiry_date DATE, unit_cost DECIMAL, unit_price DECIMAL, is_received BOOLEAN
    )
    LOOP
        -- A. Record in receipt history (Trigger handles PO dashboard sync)
        INSERT INTO purchase_order_receipt_items (
            receipt_id, product_id, quantity, unit_cost, batch_no, expiry_date, is_received
        ) VALUES (
            v_receipt_id, v_received_item.product_id, v_received_item.received_qty, 
            v_received_item.unit_cost, v_received_item.batch_no, v_received_item.expiry_date,
            COALESCE(v_received_item.is_received, TRUE)
        );

        -- B. Handle Preorders
        SELECT SUM(preorder_quantity) INTO v_total_preorder_qty
        FROM branch_inventory
        WHERE branch_id = v_po.branch_id AND product_id = v_received_item.product_id;
        v_total_preorder_qty := COALESCE(v_total_preorder_qty, 0);
        
        v_to_fulfill := LEAST(v_received_item.received_qty, v_total_preorder_qty);
        v_remaining_received := v_received_item.received_qty - v_to_fulfill;

        IF v_to_fulfill > 0 THEN
            WITH fulfilled AS (
                SELECT id, LEAST(preorder_quantity, v_to_fulfill) as current_fulfill
                FROM branch_inventory
                WHERE branch_id = v_po.branch_id AND product_id = v_received_item.product_id AND preorder_quantity > 0
                ORDER BY created_at ASC
            )
            UPDATE branch_inventory bi
            SET preorder_quantity = bi.preorder_quantity - f.current_fulfill, updated_at = NOW()
            FROM fulfilled f WHERE bi.id = f.id;
        END IF;

        -- C. Update or Create Branch Inventory (Merging into existing stock)
        SELECT id, stock_quantity INTO v_batch_id, v_old_qty
        FROM branch_inventory
        WHERE branch_id = v_po.branch_id AND product_id = v_received_item.product_id
        ORDER BY created_at DESC -- Merge into most recent if multiples exist
        LIMIT 1;

        IF v_batch_id IS NOT NULL THEN
            -- Merge into existing row
            UPDATE branch_inventory
            SET stock_quantity = stock_quantity + v_remaining_received,
                batch_no = COALESCE(v_received_item.batch_no, batch_no),
                expiry_date = COALESCE(v_received_item.expiry_date, expiry_date),
                cost_price = v_received_item.unit_cost,
                selling_price = v_received_item.unit_price,
                purchase_invoice = v_po.po_number,
                updated_at = NOW()
            WHERE id = v_batch_id;
        ELSE
            -- Create new row if no stock exists for this product in this branch
            v_old_qty := 0;
            INSERT INTO branch_inventory (
                tenant_id, branch_id, product_id, stock_quantity, 
                batch_no, expiry_date, cost_price, selling_price, 
                purchase_invoice, purchase_code, added_by, is_active
            ) VALUES (
                v_po.tenant_id, v_po.branch_id, v_received_item.product_id, v_remaining_received,
                v_received_item.batch_no, v_received_item.expiry_date, v_received_item.unit_cost, v_received_item.unit_price,
                v_po.po_number, v_po.po_number, v_staff_id::text, TRUE
            ) RETURNING id INTO v_batch_id;
        END IF;

        -- D. Record Inventory Transaction
        INSERT INTO inventory_transactions (
            tenant_id, branch_id, product_id, branch_inventory_id,
            transaction_type, quantity_delta, previous_quantity, new_quantity,
            unit_cost, reference_id, reference_type, staff_id
        ) VALUES (
            v_po.tenant_id, v_po.branch_id, v_received_item.product_id, v_batch_id,
            'restock'::transaction_type, v_remaining_received, v_old_qty, v_old_qty + v_remaining_received,
            v_received_item.unit_cost, v_po.id, 'purchase_order', v_staff_id
        );
    END LOOP;

    SELECT * INTO v_po FROM purchase_orders WHERE id = p_po_id;
    RETURN v_po;
END;
$$;

-- End of 20260507000005_merge_po_stock.sql


-- File: 20260507000006_update_inventory_view.sql
-- ============================================================
-- Migration: Update Inventory View with Name and Strength
-- ============================================================
-- Description: Redefines v_branch_products to include all
--              necessary fields for the inventory dashboard,
--              including product name, strength, and batches.
-- ============================================================

CREATE OR REPLACE VIEW public.v_branch_products AS
SELECT
    bi.id as inv_id,
    bi.tenant_id,
    bi.branch_id,
    bi.product_id,
    bi.stock_quantity,
    bi.reserved_quantity,
    bi.batch_no,
    bi.expiry_date,
    bi.low_stock_threshold,
    bi.cost_price,
    bi.selling_price,
    bi."isPOM",
    bi.is_active as inventory_active,
    bi.updated_at,
    
    -- Product details from the master catalog
    p.name as product_name,
    p.sku,
    p.barcode,
    p.image_url,
    p.strength,
    p.product_type,
    p.unit_of_measure,
    p.is_active as product_active,
    
    -- Status flags
    CASE
        WHEN bi.stock_quantity <= bi.low_stock_threshold THEN true
        ELSE false
    END as is_low_stock,
    CASE
        WHEN bi.expiry_date IS NOT NULL
        AND bi.expiry_date <= CURRENT_DATE + INTERVAL '90 days'
        THEN true
        ELSE false
    END as is_expiring_soon
FROM branch_inventory bi
JOIN products p ON bi.product_id = p.id;

COMMENT ON VIEW v_branch_products IS 'Comprehensive view joining branch inventory with product master data';

-- End of 20260507000006_update_inventory_view.sql


-- File: 20260507000007_fix_inventory_snapshots.sql
-- ============================================================
-- Migration: Ensure Product Snapshots in Branch Inventory (FINAL)
-- ============================================================
-- Description: Adds strength column and updates the trigger
--              to ensure product details are synced on every 
--              inventory update (including PO receives).
-- ============================================================

-- 1. Ensure strength column exists in branch_inventory
ALTER TABLE public.branch_inventory 
ADD COLUMN IF NOT EXISTS strength TEXT;

-- 2. Update the populate function to include strength and be more robust
CREATE OR REPLACE FUNCTION public.populate_branch_inventory_details()
RETURNS TRIGGER AS $$
DECLARE
    r_prod RECORD;
BEGIN
    SELECT name, barcode as sku, barcode, product_type, generic_name, unit_of_measure, image_url, strength
    INTO r_prod
    FROM public.products WHERE id = NEW.product_id;

    IF r_prod IS NOT NULL THEN
        NEW.product_name := COALESCE(NEW.product_name, r_prod.name);
        NEW.sku := COALESCE(NEW.sku, r_prod.sku);
        NEW.barcode := COALESCE(NEW.barcode, r_prod.barcode);
        NEW.product_type := COALESCE(NEW.product_type, r_prod.product_type);
        NEW.unit_of_measure := COALESCE(NEW.unit_of_measure, r_prod.unit_of_measure);
        NEW.image_url := COALESCE(NEW.image_url, r_prod.image_url);
        NEW.strength := COALESCE(NEW.strength, r_prod.strength);
        
        IF r_prod.product_type IN ('drug', 'medication') THEN
            NEW.generic_name := COALESCE(NEW.generic_name, r_prod.generic_name);
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 3. Update trigger to fire on INSERT and UPDATE
DROP TRIGGER IF EXISTS trg_populate_branch_inventory_details ON public.branch_inventory;
CREATE TRIGGER trg_populate_branch_inventory_details
    BEFORE INSERT OR UPDATE ON public.branch_inventory
    FOR EACH ROW
    EXECUTE FUNCTION public.populate_branch_inventory_details();

-- 4. Sync existing data
UPDATE public.branch_inventory bi
SET product_name = p.name,
    sku = p.barcode,
    strength = p.strength,
    product_type = p.product_type,
    image_url = p.image_url
FROM public.products p
WHERE bi.product_id = p.id
AND (bi.product_name IS NULL OR bi.strength IS NULL);

-- End of 20260507000007_fix_inventory_snapshots.sql


-- File: 20260507000008_explicit_po_snapshots.sql
-- ============================================================
-- Migration: Explicit Details in PO Receipt
-- ============================================================
-- Description: Updates the receiving RPC to explicitly fetch 
--              and save product name and strength, ensuring
--              high reliability for the inventory dashboard.
-- ============================================================

CREATE OR REPLACE FUNCTION public.receive_purchase_order(
    p_po_id UUID,
    p_received_items JSONB,
    p_notes TEXT DEFAULT NULL
)
RETURNS purchase_orders
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_po purchase_orders;
    v_received_item RECORD;
    v_prod RECORD;
    v_total_preorder_qty INTEGER;
    v_to_fulfill INTEGER;
    v_remaining_received INTEGER;
    v_batch_id UUID;
    v_staff_id UUID;
    v_receipt_id UUID;
    v_old_qty INTEGER;
BEGIN
    v_staff_id := auth.uid();
    SELECT * INTO v_po FROM purchase_orders WHERE id = p_po_id;
    
    IF v_po.id IS NULL THEN RAISE EXCEPTION 'Purchase Order not found'; END IF;
    IF v_po.status NOT IN ('pending', 'partially_received') THEN
        RAISE EXCEPTION 'Purchase Order must be pending or partially received to receive stock';
    END IF;

    -- 1. Create the Receipt Group for history
    INSERT INTO purchase_order_receipts (tenant_id, po_id, staff_id, notes)
    VALUES (v_po.tenant_id, v_po.id, v_staff_id, p_notes)
    RETURNING id INTO v_receipt_id;

    -- 2. Process each received item
    FOR v_received_item IN SELECT * FROM jsonb_to_recordset(p_received_items) AS x(
        product_id UUID, received_qty INTEGER, batch_no TEXT, expiry_date DATE, unit_cost DECIMAL, unit_price DECIMAL, is_received BOOLEAN
    )
    LOOP
        -- Fetch current master product details to ensure snapshots are accurate
        SELECT name, barcode as sku, strength, product_type, image_url 
        INTO v_prod 
        FROM public.products WHERE id = v_received_item.product_id;

        -- A. Record in receipt history (Trigger handles PO dashboard sync)
        INSERT INTO purchase_order_receipt_items (
            receipt_id, product_id, quantity, unit_cost, batch_no, expiry_date, is_received
        ) VALUES (
            v_receipt_id, v_received_item.product_id, v_received_item.received_qty, 
            v_received_item.unit_cost, v_received_item.batch_no, v_received_item.expiry_date,
            COALESCE(v_received_item.is_received, TRUE)
        );

        -- B. Handle Preorders
        SELECT SUM(preorder_quantity) INTO v_total_preorder_qty
        FROM branch_inventory
        WHERE branch_id = v_po.branch_id AND product_id = v_received_item.product_id;
        v_total_preorder_qty := COALESCE(v_total_preorder_qty, 0);
        
        v_to_fulfill := LEAST(v_received_item.received_qty, v_total_preorder_qty);
        v_remaining_received := v_received_item.received_qty - v_to_fulfill;

        IF v_to_fulfill > 0 THEN
            WITH fulfilled AS (
                SELECT id, LEAST(preorder_quantity, v_to_fulfill) as current_fulfill
                FROM branch_inventory
                WHERE branch_id = v_po.branch_id AND product_id = v_received_item.product_id AND preorder_quantity > 0
                ORDER BY created_at ASC
            )
            UPDATE branch_inventory bi
            SET preorder_quantity = bi.preorder_quantity - f.current_fulfill, updated_at = NOW()
            FROM fulfilled f WHERE bi.id = f.id;
        END IF;

        -- C. Update or Create Branch Inventory (Explicitly setting snapshots)
        SELECT id, stock_quantity INTO v_batch_id, v_old_qty
        FROM branch_inventory
        WHERE branch_id = v_po.branch_id AND product_id = v_received_item.product_id
        ORDER BY created_at DESC
        LIMIT 1;

        IF v_batch_id IS NOT NULL THEN
            -- Merge into existing row (Updating all metadata)
            UPDATE branch_inventory
            SET stock_quantity = stock_quantity + v_remaining_received,
                batch_no = COALESCE(v_received_item.batch_no, batch_no),
                expiry_date = COALESCE(v_received_item.expiry_date, expiry_date),
                cost_price = v_received_item.unit_cost,
                selling_price = v_received_item.unit_price,
                purchase_invoice = v_po.po_number,
                -- Snapshot details
                product_name = v_prod.name,
                strength = v_prod.strength,
                sku = v_prod.sku,
                product_type = v_prod.product_type,
                image_url = v_prod.image_url,
                updated_at = NOW()
            WHERE id = v_batch_id;
        ELSE
            -- Create new row (Setting all metadata)
            v_old_qty := 0;
            INSERT INTO branch_inventory (
                tenant_id, branch_id, product_id, stock_quantity, 
                batch_no, expiry_date, cost_price, selling_price, 
                purchase_invoice, purchase_code, added_by, is_active,
                product_name, strength, sku, product_type, image_url
            ) VALUES (
                v_po.tenant_id, v_po.branch_id, v_received_item.product_id, v_remaining_received,
                v_received_item.batch_no, v_received_item.expiry_date, v_received_item.unit_cost, v_received_item.unit_price,
                v_po.po_number, v_po.po_number, v_staff_id::text, TRUE,
                v_prod.name, v_prod.strength, v_prod.sku, v_prod.product_type, v_prod.image_url
            ) RETURNING id INTO v_batch_id;
        END IF;

        -- D. Record Inventory Transaction
        INSERT INTO inventory_transactions (
            tenant_id, branch_id, product_id, branch_inventory_id,
            transaction_type, quantity_delta, previous_quantity, new_quantity,
            unit_cost, reference_id, reference_type, staff_id
        ) VALUES (
            v_po.tenant_id, v_po.branch_id, v_received_item.product_id, v_batch_id,
            'restock'::transaction_type, v_remaining_received, v_old_qty, v_old_qty + v_remaining_received,
            v_received_item.unit_cost, v_po.id, 'purchase_order', v_staff_id
        );
    END LOOP;

    SELECT * INTO v_po FROM purchase_orders WHERE id = p_po_id;
    RETURN v_po;
END;
$$;

-- End of 20260507000008_explicit_po_snapshots.sql


-- File: 20260507000009_po_early_snapshot.sql
-- ============================================================
-- Migration: Early Snapshot for Purchase Orders
-- ============================================================
-- Description: Adds product_name and strength to PO items.
--              Ensures details are captured at order time and
--              carried through to inventory.
-- ============================================================

-- 1. Add snapshot columns to purchase_order_items
ALTER TABLE public.purchase_order_items 
ADD COLUMN IF NOT EXISTS product_name TEXT,
ADD COLUMN IF NOT EXISTS strength TEXT;

-- 2. Create Trigger Function to snapshot details on PO Item creation
CREATE OR REPLACE FUNCTION public.populate_po_item_details()
RETURNS TRIGGER AS $$
BEGIN
    SELECT name, strength 
    INTO NEW.product_name, NEW.strength
    FROM public.products WHERE id = NEW.product_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 3. Create the trigger
DROP TRIGGER IF EXISTS trg_populate_po_item_details ON public.purchase_order_items;
CREATE TRIGGER trg_populate_po_item_details
    BEFORE INSERT ON public.purchase_order_items
    FOR EACH ROW
    EXECUTE FUNCTION public.populate_po_item_details();

-- 4. One-time sync for existing PO items
UPDATE public.purchase_order_items poi
SET product_name = p.name,
    strength = p.strength
FROM public.products p
WHERE poi.product_id = p.id
AND poi.product_name IS NULL;

-- End of 20260507000009_po_early_snapshot.sql


-- File: 20260507000010_po_to_inventory_flow.sql
-- ============================================================
-- Migration: Direct Flow from PO to Inventory
-- ============================================================
-- Description: Updates the receiving RPC to pull snapshots 
--              from purchase_order_items and pass them to 
--              branch_inventory.
-- ============================================================

CREATE OR REPLACE FUNCTION public.receive_purchase_order(
    p_po_id UUID,
    p_received_items JSONB,
    p_notes TEXT DEFAULT NULL
)
RETURNS purchase_orders
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_po purchase_orders;
    v_received_item RECORD;
    v_po_item RECORD; -- Holds the snapshots from the PO
    v_total_preorder_qty INTEGER;
    v_to_fulfill INTEGER;
    v_remaining_received INTEGER;
    v_batch_id UUID;
    v_staff_id UUID;
    v_receipt_id UUID;
    v_old_qty INTEGER;
BEGIN
    v_staff_id := auth.uid();
    SELECT * INTO v_po FROM purchase_orders WHERE id = p_po_id;
    
    IF v_po.id IS NULL THEN RAISE EXCEPTION 'Purchase Order not found'; END IF;
    IF v_po.status NOT IN ('pending', 'partially_received') THEN
        RAISE EXCEPTION 'Purchase Order must be pending or partially received to receive stock';
    END IF;

    -- 1. Create the Receipt Group for history
    INSERT INTO purchase_order_receipts (tenant_id, po_id, staff_id, notes)
    VALUES (v_po.tenant_id, v_po.id, v_staff_id, p_notes)
    RETURNING id INTO v_receipt_id;

    -- 2. Process each received item
    FOR v_received_item IN SELECT * FROM jsonb_to_recordset(p_received_items) AS x(
        product_id UUID, received_qty INTEGER, batch_no TEXT, expiry_date DATE, unit_cost DECIMAL, unit_price DECIMAL, is_received BOOLEAN
    )
    LOOP
        -- Retrieve the snapshots from the Purchase Order Item (Early Snapshot)
        -- Fallback to products catalog ONLY if the PO snapshot is missing
        SELECT poi.product_name, poi.strength, p.barcode as sku, p.product_type, p.image_url
        INTO v_po_item
        FROM purchase_order_items poi
        JOIN products p ON poi.product_id = p.id
        WHERE poi.po_id = p_po_id AND poi.product_id = v_received_item.product_id;

        -- A. Record in receipt history
        INSERT INTO purchase_order_receipt_items (
            receipt_id, product_id, quantity, unit_cost, batch_no, expiry_date, is_received
        ) VALUES (
            v_receipt_id, v_received_item.product_id, v_received_item.received_qty, 
            v_received_item.unit_cost, v_received_item.batch_no, v_received_item.expiry_date,
            COALESCE(v_received_item.is_received, TRUE)
        );

        -- B. Handle Preorders
        SELECT SUM(preorder_quantity) INTO v_total_preorder_qty
        FROM branch_inventory
        WHERE branch_id = v_po.branch_id AND product_id = v_received_item.product_id;
        v_total_preorder_qty := COALESCE(v_total_preorder_qty, 0);
        
        v_to_fulfill := LEAST(v_received_item.received_qty, v_total_preorder_qty);
        v_remaining_received := v_received_item.received_qty - v_to_fulfill;

        IF v_to_fulfill > 0 THEN
            WITH fulfilled AS (
                SELECT id, LEAST(preorder_quantity, v_to_fulfill) as current_fulfill
                FROM branch_inventory
                WHERE branch_id = v_po.branch_id AND product_id = v_received_item.product_id AND preorder_quantity > 0
                ORDER BY created_at ASC
            )
            UPDATE branch_inventory bi
            SET preorder_quantity = bi.preorder_quantity - f.current_fulfill, updated_at = NOW()
            FROM fulfilled f WHERE bi.id = f.id;
        END IF;

        -- C. Update or Create Branch Inventory (Using the flow: PO -> Inventory)
        SELECT id, stock_quantity INTO v_batch_id, v_old_qty
        FROM branch_inventory
        WHERE branch_id = v_po.branch_id AND product_id = v_received_item.product_id
        ORDER BY created_at DESC
        LIMIT 1;

        IF v_batch_id IS NOT NULL THEN
            UPDATE branch_inventory
            SET stock_quantity = stock_quantity + v_remaining_received,
                batch_no = COALESCE(v_received_item.batch_no, batch_no),
                expiry_date = COALESCE(v_received_item.expiry_date, expiry_date),
                cost_price = v_received_item.unit_cost,
                selling_price = v_received_item.unit_price,
                purchase_invoice = v_po.po_number,
                -- Snapshot details passed from PO
                product_name = COALESCE(v_po_item.product_name, product_name),
                strength = COALESCE(v_po_item.strength, strength),
                sku = COALESCE(v_po_item.sku, sku),
                product_type = COALESCE(v_po_item.product_type, product_type),
                image_url = COALESCE(v_po_item.image_url, image_url),
                updated_at = NOW()
            WHERE id = v_batch_id;
        ELSE
            v_old_qty := 0;
            INSERT INTO branch_inventory (
                tenant_id, branch_id, product_id, stock_quantity, 
                batch_no, expiry_date, cost_price, selling_price, 
                purchase_invoice, purchase_code, added_by, is_active,
                product_name, strength, sku, product_type, image_url
            ) VALUES (
                v_po.tenant_id, v_po.branch_id, v_received_item.product_id, v_remaining_received,
                v_received_item.batch_no, v_received_item.expiry_date, v_received_item.unit_cost, v_received_item.unit_price,
                v_po.po_number, v_po.po_number, v_staff_id::text, TRUE,
                v_po_item.product_name, v_po_item.strength, v_po_item.sku, v_po_item.product_type, v_po_item.image_url
            ) RETURNING id INTO v_batch_id;
        END IF;

        -- D. Record Inventory Transaction
        INSERT INTO inventory_transactions (
            tenant_id, branch_id, product_id, branch_inventory_id,
            transaction_type, quantity_delta, previous_quantity, new_quantity,
            unit_cost, reference_id, reference_type, staff_id
        ) VALUES (
            v_po.tenant_id, v_po.branch_id, v_received_item.product_id, v_batch_id,
            'restock'::transaction_type, v_remaining_received, v_old_qty, v_old_qty + v_remaining_received,
            v_received_item.unit_cost, v_po.id, 'purchase_order', v_staff_id
        );
    END LOOP;

    SELECT * INTO v_po FROM purchase_orders WHERE id = p_po_id;
    RETURN v_po;
END;
$$;

-- End of 20260507000010_po_to_inventory_flow.sql


-- File: 20260507000011_cleanup_triggers.sql
-- ============================================================
-- Migration: Cleanup Irrelevant Triggers
-- ============================================================
-- Description: Removes redundant snapshot triggers that have 
--              been replaced by direct RPC logic and early
--              PO snapshots.
-- ============================================================

-- 1. Remove the redundant detail population trigger on branch_inventory
-- Reason: This is now handled directly by the receive_purchase_order RPC
-- for accuracy and to prevent overwriting PO-time snapshots.
DROP TRIGGER IF EXISTS trg_populate_branch_inventory_details ON public.branch_inventory;

-- 2. Optional: Clean up the function if it's not used anywhere else
-- (We'll keep it for now in case other modules rely on it, but the trigger is gone)

-- Note: We are KEEPING these essential triggers:
-- - tr_sync_po_item_received_qty (Essential for PO Dashboard sync)
-- - trg_sync_stock_balance (Essential for real-time inventory totals)
-- - trigger_check_reorder_alert (Essential for low stock notifications)
-- - trg_populate_po_item_details (Essential for the new Early Snapshot logic)

-- End of 20260507000011_cleanup_triggers.sql


-- File: 20260508000000_branch_markups_and_fixes.sql
-- ============================================================
-- Migration: Branch Markups and PO Fixes
-- ============================================================
-- Description: Adds markup configuration to branches and 
--              ensures PO receiving always pulls product details.
-- ============================================================

-- 1. Add markup columns to branches
ALTER TABLE public.branches 
ADD COLUMN IF NOT EXISTS drug_markup DECIMAL(5,2) DEFAULT 30, -- 30% default
ADD COLUMN IF NOT EXISTS supermarket_markup DECIMAL(5,2) DEFAULT 20; -- 20% default

-- 2. Update receiving RPC to be more robust for names and prices
CREATE OR REPLACE FUNCTION public.receive_purchase_order(
    p_po_id UUID,
    p_received_items JSONB,
    p_notes TEXT DEFAULT NULL
)
RETURNS purchase_orders
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_po purchase_orders;
    v_received_item RECORD;
    v_po_item RECORD;
    v_total_preorder_qty INTEGER;
    v_to_fulfill INTEGER;
    v_remaining_received INTEGER;
    v_batch_id UUID;
    v_staff_id UUID;
    v_receipt_id UUID;
    v_old_qty INTEGER;
BEGIN
    v_staff_id := auth.uid();
    SELECT * INTO v_po FROM purchase_orders WHERE id = p_po_id;
    
    IF v_po.id IS NULL THEN RAISE EXCEPTION 'Purchase Order not found'; END IF;
    
    -- 1. Create the Receipt Group
    INSERT INTO purchase_order_receipts (tenant_id, po_id, staff_id, notes)
    VALUES (v_po.tenant_id, v_po.id, v_staff_id, p_notes)
    RETURNING id INTO v_receipt_id;

    -- 2. Process each received item
    FOR v_received_item IN SELECT * FROM jsonb_to_recordset(p_received_items) AS x(
        product_id UUID, received_qty INTEGER, batch_no TEXT, expiry_date DATE, unit_cost DECIMAL, unit_price DECIMAL, is_received BOOLEAN
    )
    LOOP
        -- Robust retrieval of product details (Fallback to products catalog if PO snapshot is missing)
        SELECT 
            COALESCE(poi.product_name, p.name) as product_name, 
            COALESCE(poi.strength, p.strength) as strength, 
            p.barcode as sku, 
            p.product_type, 
            p.image_url,
            p.unit_of_measure
        INTO v_po_item
        FROM products p
        LEFT JOIN purchase_order_items poi ON poi.product_id = p.id AND poi.po_id = p_po_id
        WHERE p.id = v_received_item.product_id;

        -- A. Record in receipt history
        INSERT INTO purchase_order_receipt_items (
            receipt_id, product_id, quantity, unit_cost, batch_no, expiry_date, is_received
        ) VALUES (
            v_receipt_id, v_received_item.product_id, v_received_item.received_qty, 
            v_received_item.unit_cost, v_received_item.batch_no, v_received_item.expiry_date,
            COALESCE(v_received_item.is_received, TRUE)
        );

        -- B. Handle Preorders
        SELECT SUM(preorder_quantity) INTO v_total_preorder_qty
        FROM branch_inventory
        WHERE branch_id = v_po.branch_id AND product_id = v_received_item.product_id;
        v_total_preorder_qty := COALESCE(v_total_preorder_qty, 0);
        
        v_to_fulfill := LEAST(v_received_item.received_qty, v_total_preorder_qty);
        v_remaining_received := v_received_item.received_qty - v_to_fulfill;

        IF v_to_fulfill > 0 THEN
            WITH fulfilled AS (
                SELECT id, LEAST(preorder_quantity, v_to_fulfill) as current_fulfill
                FROM branch_inventory
                WHERE branch_id = v_po.branch_id AND product_id = v_received_item.product_id AND preorder_quantity > 0
                ORDER BY created_at ASC
            )
            UPDATE branch_inventory bi
            SET preorder_quantity = bi.preorder_quantity - f.current_fulfill, updated_at = NOW()
            FROM fulfilled f WHERE bi.id = f.id;
        END IF;

        -- C. Update or Create Branch Inventory
        SELECT id, stock_quantity INTO v_batch_id, v_old_qty
        FROM branch_inventory
        WHERE branch_id = v_po.branch_id AND product_id = v_received_item.product_id
        ORDER BY created_at DESC
        LIMIT 1;

        IF v_batch_id IS NOT NULL THEN
            UPDATE branch_inventory
            SET stock_quantity = stock_quantity + v_remaining_received,
                batch_no = COALESCE(v_received_item.batch_no, batch_no),
                expiry_date = COALESCE(v_received_item.expiry_date, expiry_date),
                cost_price = v_received_item.unit_cost,
                selling_price = COALESCE(v_received_item.unit_price, selling_price),
                purchase_invoice = v_po.po_number,
                -- Snapshot details
                product_name = COALESCE(v_po_item.product_name, product_name),
                strength = COALESCE(v_po_item.strength, strength),
                sku = COALESCE(v_po_item.sku, sku),
                product_type = COALESCE(v_po_item.product_type, product_type),
                image_url = COALESCE(v_po_item.image_url, image_url),
                unit_of_measure = COALESCE(unit_of_measure, v_po_item.unit_of_measure),
                updated_at = NOW()
            WHERE id = v_batch_id;
        ELSE
            v_old_qty := 0;
            INSERT INTO branch_inventory (
                tenant_id, branch_id, product_id, stock_quantity, 
                batch_no, expiry_date, cost_price, selling_price, 
                purchase_invoice, purchase_code, added_by, is_active,
                product_name, strength, sku, product_type, image_url, unit_of_measure
            ) VALUES (
                v_po.tenant_id, v_po.branch_id, v_received_item.product_id, v_remaining_received,
                v_received_item.batch_no, v_received_item.expiry_date, v_received_item.unit_cost, v_received_item.unit_price,
                v_po.po_number, v_po.po_number, v_staff_id::text, TRUE,
                v_po_item.product_name, v_po_item.strength, v_po_item.sku, v_po_item.product_type, v_po_item.image_url, v_po_item.unit_of_measure
            ) RETURNING id INTO v_batch_id;
        END IF;

        -- D. Record Transaction
        INSERT INTO inventory_transactions (
            tenant_id, branch_id, product_id, branch_inventory_id,
            transaction_type, quantity_delta, previous_quantity, new_quantity,
            unit_cost, reference_id, reference_type, staff_id
        ) VALUES (
            v_po.tenant_id, v_po.branch_id, v_received_item.product_id, v_batch_id,
            'restock'::transaction_type, v_remaining_received, v_old_qty, v_old_qty + v_remaining_received,
            v_received_item.unit_cost, v_po.id, 'purchase_order', v_staff_id
        );
    END LOOP;

    SELECT * INTO v_po FROM purchase_orders WHERE id = p_po_id;
    RETURN v_po;
END;
$$;

-- End of 20260508000000_branch_markups_and_fixes.sql


-- File: 20260508000001_fix_po_receiving_error.sql
-- ============================================================
-- Migration: Clean PO Receiving and Branch Markups
-- ============================================================
-- Description: Adds markup config to branches (if missing) 
--              and applies the robust receiving RPC fix.
-- ============================================================

-- 1. Add markup columns to branches table (if not already there)
ALTER TABLE public.branches 
ADD COLUMN IF NOT EXISTS drug_markup DECIMAL(5,2) DEFAULT 30,
ADD COLUMN IF NOT EXISTS supermarket_markup DECIMAL(5,2) DEFAULT 20;

-- 2. Update the receiving RPC with robust metadata and fulfillment logic
CREATE OR REPLACE FUNCTION public.receive_purchase_order(
    p_po_id UUID,
    p_received_items JSONB,
    p_notes TEXT DEFAULT NULL
)
RETURNS purchase_orders
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_po purchase_orders;
    v_received_item RECORD;
    v_po_item RECORD;
    v_total_preorder_qty INTEGER;
    v_to_fulfill INTEGER;
    v_remaining_received INTEGER;
    v_batch_id UUID;
    v_staff_id UUID;
    v_receipt_id UUID;
    v_old_qty INTEGER;
BEGIN
    v_staff_id := auth.uid();
    
    -- Fetch and Lock PO to prevent race conditions
    SELECT * INTO v_po FROM purchase_orders WHERE id = p_po_id FOR UPDATE;
    IF v_po.id IS NULL THEN RAISE EXCEPTION 'Purchase Order not found'; END IF;
    
    -- 1. Create the Receipt Group for history tracking
    INSERT INTO purchase_order_receipts (tenant_id, po_id, staff_id, notes)
    VALUES (v_po.tenant_id, v_po.id, v_staff_id, p_notes)
    RETURNING id INTO v_receipt_id;

    -- 2. Process each received item in the batch
    FOR v_received_item IN SELECT * FROM jsonb_to_recordset(p_received_items) AS x(
        product_id UUID, received_qty INTEGER, batch_no TEXT, expiry_date DATE, unit_cost DECIMAL, unit_price DECIMAL, is_received BOOLEAN
    )
    LOOP
        -- Safely retrieve product details (Fallback to products catalog if PO snapshot is missing)
        SELECT 
            COALESCE(poi.product_name, p.name) as product_name, 
            COALESCE(poi.strength, p.strength) as strength, 
            p.barcode as sku, 
            p.product_type, 
            p.image_url,
            COALESCE(p.unit_of_measure, 'unit') as unit_of_measure
        INTO v_po_item
        FROM products p
        LEFT JOIN purchase_order_items poi ON poi.product_id = p.id AND poi.po_id = p_po_id
        WHERE p.id = v_received_item.product_id;

        -- A. Record Receipt History
        INSERT INTO purchase_order_receipt_items (
            receipt_id, product_id, quantity, unit_cost, batch_no, expiry_date, is_received
        ) VALUES (
            v_receipt_id, v_received_item.product_id, v_received_item.received_qty, 
            v_received_item.unit_cost, v_received_item.batch_no, v_received_item.expiry_date,
            COALESCE(v_received_item.is_received, TRUE)
        );

        -- B. Preorder Fulfillment
        SELECT COALESCE(SUM(preorder_quantity), 0) INTO v_total_preorder_qty
        FROM branch_inventory
        WHERE branch_id = v_po.branch_id AND product_id = v_received_item.product_id;
        
        v_to_fulfill := LEAST(v_received_item.received_qty, v_total_preorder_qty);
        v_remaining_received := v_received_item.received_qty - v_to_fulfill;

        IF v_to_fulfill > 0 THEN
            UPDATE branch_inventory
            SET preorder_quantity = preorder_quantity - sub.fulfill_amt,
                updated_at = NOW()
            FROM (
                SELECT id, LEAST(preorder_quantity, v_to_fulfill) as fulfill_amt
                FROM branch_inventory
                WHERE branch_id = v_po.branch_id AND product_id = v_received_item.product_id AND preorder_quantity > 0
                ORDER BY created_at ASC
                LIMIT 1
            ) sub
            WHERE branch_inventory.id = sub.id;
        END IF;

        -- C. Upsert Inventory Batch (Matches on Branch + Product + Batch #)
        SELECT id, stock_quantity INTO v_batch_id, v_old_qty
        FROM branch_inventory
        WHERE branch_id = v_po.branch_id 
          AND product_id = v_received_item.product_id
          AND COALESCE(batch_no, '') = COALESCE(v_received_item.batch_no, '')
        LIMIT 1;

        IF v_batch_id IS NOT NULL THEN
            UPDATE branch_inventory
            SET stock_quantity = stock_quantity + v_remaining_received,
                expiry_date = COALESCE(v_received_item.expiry_date, expiry_date),
                cost_price = v_received_item.unit_cost,
                selling_price = COALESCE(v_received_item.unit_price, selling_price),
                product_name = COALESCE(v_po_item.product_name, product_name),
                strength = COALESCE(v_po_item.strength, strength),
                sku = COALESCE(v_po_item.sku, sku),
                unit_of_measure = COALESCE(unit_of_measure, v_po_item.unit_of_measure),
                updated_at = NOW()
            WHERE id = v_batch_id;
        ELSE
            v_old_qty := 0;
            INSERT INTO branch_inventory (
                tenant_id, branch_id, product_id, stock_quantity, 
                batch_no, expiry_date, cost_price, selling_price, 
                purchase_invoice, added_by, is_active,
                product_name, strength, sku, product_type, image_url, unit_of_measure
            ) VALUES (
                v_po.tenant_id, v_po.branch_id, v_received_item.product_id, v_remaining_received,
                v_received_item.batch_no, v_received_item.expiry_date, v_received_item.unit_cost, 
                COALESCE(v_received_item.unit_price, v_received_item.unit_cost * 1.3),
                v_po.po_number, v_staff_id::text, TRUE,
                v_po_item.product_name, v_po_item.strength, v_po_item.sku, v_po_item.product_type, v_po_item.image_url, v_po_item.unit_of_measure
            ) RETURNING id INTO v_batch_id;
        END IF;

        -- D. Record Inventory Transaction
        INSERT INTO inventory_transactions (
            tenant_id, branch_id, product_id, branch_inventory_id,
            transaction_type, quantity_delta, previous_quantity, new_quantity,
            unit_cost, reference_id, reference_type, staff_id
        ) VALUES (
            v_po.tenant_id, v_po.branch_id, v_received_item.product_id, v_batch_id,
            'restock'::transaction_type, v_remaining_received, v_old_qty, v_old_qty + v_remaining_received,
            v_received_item.unit_cost, v_po.id, 'purchase_order', v_staff_id
        );
    END LOOP;

    -- Refresh final PO object for return
    SELECT * INTO v_po FROM purchase_orders WHERE id = p_po_id;
    RETURN v_po;
END;
$$;

-- End of 20260508000001_fix_po_receiving_error.sql


-- File: 20260508000002_simplified_po_receiving.sql
-- ============================================================
-- Migration: Flexible PO Receiving with UoM
-- ============================================================
-- Description: Updates the receiving RPC to accept unit_of_measure
--              from the frontend during receipt.
-- ============================================================

CREATE OR REPLACE FUNCTION public.receive_purchase_order(
    p_po_id UUID,
    p_received_items JSONB,
    p_notes TEXT DEFAULT NULL
)
RETURNS purchase_orders
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_po purchase_orders;
    v_received_item RECORD;
    v_po_item RECORD;
    v_total_preorder_qty INTEGER;
    v_to_fulfill INTEGER;
    v_remaining_received INTEGER;
    v_batch_id UUID;
    v_staff_id UUID;
    v_receipt_id UUID;
    v_old_qty INTEGER;
BEGIN
    v_staff_id := auth.uid();
    
    -- 1. Fetch and Lock PO
    SELECT * INTO v_po FROM purchase_orders WHERE id = p_po_id FOR UPDATE;
    IF v_po.id IS NULL THEN RAISE EXCEPTION 'Purchase Order not found'; END IF;
    
    -- 2. Create the Receipt Group
    INSERT INTO purchase_order_receipts (tenant_id, po_id, staff_id, notes)
    VALUES (v_po.tenant_id, v_po.id, v_staff_id, p_notes)
    RETURNING id INTO v_receipt_id;

    -- 3. Process each received item
    FOR v_received_item IN SELECT * FROM jsonb_to_recordset(p_received_items) AS x(
        product_id UUID, 
        received_qty INTEGER, 
        batch_no TEXT, 
        expiry_date DATE, 
        unit_cost DECIMAL, 
        unit_price DECIMAL, 
        is_received BOOLEAN,
        unit_of_measure TEXT
    )
    LOOP
        -- Safely retrieve product details (Fallback to products catalog)
        SELECT 
            COALESCE(poi.product_name, p.name) as product_name, 
            COALESCE(poi.strength, p.strength) as strength, 
            p.barcode as sku, 
            p.product_type, 
            p.image_url
        INTO v_po_item
        FROM products p
        LEFT JOIN purchase_order_items poi ON poi.product_id = p.id AND poi.po_id = p_po_id
        WHERE p.id = v_received_item.product_id;

        -- A. Record Receipt History
        INSERT INTO purchase_order_receipt_items (
            receipt_id, product_id, quantity, unit_cost, batch_no, expiry_date, is_received
        ) VALUES (
            v_receipt_id, v_received_item.product_id, v_received_item.received_qty, 
            v_received_item.unit_cost, v_received_item.batch_no, v_received_item.expiry_date,
            COALESCE(v_received_item.is_received, TRUE)
        );

        -- B. Preorder Fulfillment
        SELECT COALESCE(SUM(preorder_quantity), 0) INTO v_total_preorder_qty
        FROM branch_inventory
        WHERE branch_id = v_po.branch_id AND product_id = v_received_item.product_id;
        
        v_to_fulfill := LEAST(v_received_item.received_qty, v_total_preorder_qty);
        v_remaining_received := v_received_item.received_qty - v_to_fulfill;

        IF v_to_fulfill > 0 THEN
            UPDATE branch_inventory
            SET preorder_quantity = preorder_quantity - sub.fulfill_amt,
                updated_at = NOW()
            FROM (
                SELECT id, LEAST(preorder_quantity, v_to_fulfill) as fulfill_amt
                FROM branch_inventory
                WHERE branch_id = v_po.branch_id AND product_id = v_received_item.product_id AND preorder_quantity > 0
                ORDER BY created_at ASC
                LIMIT 1
            ) sub
            WHERE branch_inventory.id = sub.id;
        END IF;

        -- C. Upsert Inventory Batch
        SELECT id, stock_quantity INTO v_batch_id, v_old_qty
        FROM branch_inventory
        WHERE branch_id = v_po.branch_id 
          AND product_id = v_received_item.product_id
          AND COALESCE(batch_no, '') = COALESCE(v_received_item.batch_no, '')
        LIMIT 1;

        IF v_batch_id IS NOT NULL THEN
            UPDATE branch_inventory
            SET stock_quantity = stock_quantity + v_remaining_received,
                expiry_date = COALESCE(v_received_item.expiry_date, expiry_date),
                cost_price = v_received_item.unit_cost,
                selling_price = COALESCE(v_received_item.unit_price, selling_price),
                product_name = COALESCE(v_po_item.product_name, product_name),
                strength = COALESCE(v_po_item.strength, strength),
                sku = COALESCE(v_po_item.sku, sku),
                unit_of_measure = COALESCE(v_received_item.unit_of_measure, unit_of_measure),
                updated_at = NOW()
            WHERE id = v_batch_id;
        ELSE
            v_old_qty := 0;
            INSERT INTO branch_inventory (
                tenant_id, branch_id, product_id, stock_quantity, 
                batch_no, expiry_date, cost_price, selling_price, 
                purchase_invoice, added_by, is_active,
                product_name, strength, sku, product_type, image_url, unit_of_measure
            ) VALUES (
                v_po.tenant_id, v_po.branch_id, v_received_item.product_id, v_remaining_received,
                v_received_item.batch_no, v_received_item.expiry_date, v_received_item.unit_cost, 
                COALESCE(v_received_item.unit_price, v_received_item.unit_cost * 1.3),
                v_po.po_number, v_staff_id::text, TRUE,
                v_po_item.product_name, v_po_item.strength, v_po_item.sku, v_po_item.product_type, v_po_item.image_url, 
                COALESCE(v_received_item.unit_of_measure, 'unit')
            ) RETURNING id INTO v_batch_id;
        END IF;

        -- D. Record Transaction
        INSERT INTO inventory_transactions (
            tenant_id, branch_id, product_id, branch_inventory_id,
            transaction_type, quantity_delta, previous_quantity, new_quantity,
            unit_cost, reference_id, reference_type, staff_id
        ) VALUES (
            v_po.tenant_id, v_po.branch_id, v_received_item.product_id, v_batch_id,
            'restock'::transaction_type, v_remaining_received, v_old_qty, v_old_qty + v_remaining_received,
            v_received_item.unit_cost, v_po.id, 'purchase_order', v_staff_id
        );
    END LOOP;

    -- Refresh PO status
    SELECT * INTO v_po FROM purchase_orders WHERE id = p_po_id;
    RETURN v_po;
END;
$$;

-- End of 20260508000002_simplified_po_receiving.sql


-- File: 20260508000003_cleanup_redundant_functions.sql
-- ============================================================
-- Migration: Remove Redundant Database Functions
-- ============================================================
-- Description: Drops obsolete functions that have been replaced 
--              by direct RPC logic or newer trigger functions.
-- ============================================================

-- 1. Drop the manual sync function (Replaced by real-time triggers)
DROP FUNCTION IF EXISTS public.sync_purchase_order_quantities(UUID);

-- 2. Drop intermediate trigger functions
DROP FUNCTION IF EXISTS public.fn_sync_po_status();
DROP FUNCTION IF EXISTS public.sync_po_item_received_qty();

-- 3. Drop obsolete inventory population function
-- (The trigger was dropped in a previous migration, now we remove the function)
DROP FUNCTION IF EXISTS public.populate_branch_inventory_details();

-- 4. Optional: Clean up any old versions of the receiving RPC 
-- that might have had different signatures (if any existed)
-- (CREATE OR REPLACE already handles the current one)

COMMENT ON TABLE purchase_order_receipts IS 'Audit trail for stock receipts. Quantities are synced via triggers on receipt items.';

-- End of 20260508000003_cleanup_redundant_functions.sql


-- File: 20260508000004_enforce_stock_merge.sql
-- ============================================================
-- Migration: Enforce Product Stock Merging
-- ============================================================
-- Description: Refines the receiving RPC to strictly merge stock
--              for the same product instead of creating new rows
--              based on batch numbers.
-- ============================================================

CREATE OR REPLACE FUNCTION public.receive_purchase_order(
    p_po_id UUID,
    p_received_items JSONB,
    p_notes TEXT DEFAULT NULL
)
RETURNS purchase_orders
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_po purchase_orders;
    v_received_item RECORD;
    v_po_item RECORD;
    v_total_preorder_qty INTEGER;
    v_to_fulfill INTEGER;
    v_remaining_received INTEGER;
    v_batch_id UUID;
    v_staff_id UUID;
    v_receipt_id UUID;
    v_old_qty INTEGER;
BEGIN
    v_staff_id := auth.uid();
    
    -- 1. Fetch and Lock PO
    SELECT * INTO v_po FROM purchase_orders WHERE id = p_po_id FOR UPDATE;
    IF v_po.id IS NULL THEN RAISE EXCEPTION 'Purchase Order not found'; END IF;
    
    -- 2. Create the Receipt Group
    INSERT INTO purchase_order_receipts (tenant_id, po_id, staff_id, notes)
    VALUES (v_po.tenant_id, v_po.id, v_staff_id, p_notes)
    RETURNING id INTO v_receipt_id;

    -- 3. Process each received item
    FOR v_received_item IN SELECT * FROM jsonb_to_recordset(p_received_items) AS x(
        product_id UUID, 
        received_qty INTEGER, 
        batch_no TEXT, 
        expiry_date DATE, 
        unit_cost DECIMAL, 
        unit_price DECIMAL, 
        is_received BOOLEAN,
        unit_of_measure TEXT
    )
    LOOP
        -- Safely retrieve product details
        SELECT 
            COALESCE(poi.product_name, p.name) as product_name, 
            COALESCE(poi.strength, p.strength) as strength, 
            p.barcode as sku, 
            p.product_type, 
            p.image_url
        INTO v_po_item
        FROM products p
        LEFT JOIN purchase_order_items poi ON poi.product_id = p.id AND poi.po_id = p_po_id
        WHERE p.id = v_received_item.product_id;

        -- A. Record Receipt History
        INSERT INTO purchase_order_receipt_items (
            receipt_id, product_id, quantity, unit_cost, batch_no, expiry_date, is_received
        ) VALUES (
            v_receipt_id, v_received_item.product_id, v_received_item.received_qty, 
            v_received_item.unit_cost, v_received_item.batch_no, v_received_item.expiry_date,
            COALESCE(v_received_item.is_received, TRUE)
        );

        -- B. Preorder Fulfillment
        SELECT COALESCE(SUM(preorder_quantity), 0) INTO v_total_preorder_qty
        FROM branch_inventory
        WHERE branch_id = v_po.branch_id AND product_id = v_received_item.product_id;
        
        v_to_fulfill := LEAST(v_received_item.received_qty, v_total_preorder_qty);
        v_remaining_received := v_received_item.received_qty - v_to_fulfill;

        IF v_to_fulfill > 0 THEN
            UPDATE branch_inventory
            SET preorder_quantity = preorder_quantity - sub.fulfill_amt,
                updated_at = NOW()
            FROM (
                SELECT id, LEAST(preorder_quantity, v_to_fulfill) as fulfill_amt
                FROM branch_inventory
                WHERE branch_id = v_po.branch_id AND product_id = v_received_item.product_id AND preorder_quantity > 0
                ORDER BY created_at ASC
                LIMIT 1
            ) sub
            WHERE branch_inventory.id = sub.id;
        END IF;

        -- C. Merge into Existing Inventory Row (Ignore Batch No for matching to enforce incrementing)
        SELECT id, stock_quantity INTO v_batch_id, v_old_qty
        FROM branch_inventory
        WHERE branch_id = v_po.branch_id 
          AND product_id = v_received_item.product_id
        ORDER BY created_at DESC -- Update the most recent row if multiples exist
        LIMIT 1;

        IF v_batch_id IS NOT NULL THEN
            UPDATE branch_inventory
            SET stock_quantity = stock_quantity + v_remaining_received,
                batch_no = COALESCE(v_received_item.batch_no, batch_no),
                expiry_date = COALESCE(v_received_item.expiry_date, expiry_date),
                cost_price = v_received_item.unit_cost,
                selling_price = COALESCE(v_received_item.unit_price, selling_price),
                product_name = COALESCE(v_po_item.product_name, product_name),
                strength = COALESCE(v_po_item.strength, strength),
                sku = COALESCE(v_po_item.sku, sku),
                unit_of_measure = COALESCE(v_received_item.unit_of_measure, unit_of_measure),
                updated_at = NOW()
            WHERE id = v_batch_id;
        ELSE
            v_old_qty := 0;
            INSERT INTO branch_inventory (
                tenant_id, branch_id, product_id, stock_quantity, 
                batch_no, expiry_date, cost_price, selling_price, 
                purchase_invoice, added_by, is_active,
                product_name, strength, sku, product_type, image_url, unit_of_measure
            ) VALUES (
                v_po.tenant_id, v_po.branch_id, v_received_item.product_id, v_remaining_received,
                v_received_item.batch_no, v_received_item.expiry_date, v_received_item.unit_cost, 
                COALESCE(v_received_item.unit_price, v_received_item.unit_cost * 1.3),
                v_po.po_number, v_staff_id::text, TRUE,
                v_po_item.product_name, v_po_item.strength, v_po_item.sku, v_po_item.product_type, v_po_item.image_url, 
                COALESCE(v_received_item.unit_of_measure, 'unit')
            ) RETURNING id INTO v_batch_id;
        END IF;

        -- D. Record Transaction
        INSERT INTO inventory_transactions (
            tenant_id, branch_id, product_id, branch_inventory_id,
            transaction_type, quantity_delta, previous_quantity, new_quantity,
            unit_cost, reference_id, reference_type, staff_id
        ) VALUES (
            v_po.tenant_id, v_po.branch_id, v_received_item.product_id, v_batch_id,
            'restock'::transaction_type, v_remaining_received, v_old_qty, v_old_qty + v_remaining_received,
            v_received_item.unit_cost, v_po.id, 'purchase_order', v_staff_id
        );
    END LOOP;

    -- Refresh PO status
    SELECT * INTO v_po FROM purchase_orders WHERE id = p_po_id;
    RETURN v_po;
END;
$$;

-- End of 20260508000004_enforce_stock_merge.sql


-- File: 20260508000005_restore_batch_tracking.sql
-- ============================================================
-- Migration: Restore Batch-Level Tracking
-- ============================================================
-- Description: Reverts the receiving RPC to track stock per 
--              Batch Number for regulatory and expiry compliance.
-- ============================================================

CREATE OR REPLACE FUNCTION public.receive_purchase_order(
    p_po_id UUID,
    p_received_items JSONB,
    p_notes TEXT DEFAULT NULL
)
RETURNS purchase_orders
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_po purchase_orders;
    v_received_item RECORD;
    v_po_item RECORD;
    v_total_preorder_qty INTEGER;
    v_to_fulfill INTEGER;
    v_remaining_received INTEGER;
    v_batch_id UUID;
    v_staff_id UUID;
    v_receipt_id UUID;
    v_old_qty INTEGER;
BEGIN
    v_staff_id := auth.uid();
    
    -- 1. Fetch and Lock PO
    SELECT * INTO v_po FROM purchase_orders WHERE id = p_po_id FOR UPDATE;
    IF v_po.id IS NULL THEN RAISE EXCEPTION 'Purchase Order not found'; END IF;
    
    -- 2. Create the Receipt Group
    INSERT INTO purchase_order_receipts (tenant_id, po_id, staff_id, notes)
    VALUES (v_po.tenant_id, v_po.id, v_staff_id, p_notes)
    RETURNING id INTO v_receipt_id;

    -- 3. Process each received item
    FOR v_received_item IN SELECT * FROM jsonb_to_recordset(p_received_items) AS x(
        product_id UUID, 
        received_qty INTEGER, 
        batch_no TEXT, 
        expiry_date DATE, 
        unit_cost DECIMAL, 
        unit_price DECIMAL, 
        is_received BOOLEAN,
        unit_of_measure TEXT
    )
    LOOP
        -- Safely retrieve product details
        SELECT 
            COALESCE(poi.product_name, p.name) as product_name, 
            COALESCE(poi.strength, p.strength) as strength, 
            p.barcode as sku, 
            p.product_type, 
            p.image_url
        INTO v_po_item
        FROM products p
        LEFT JOIN purchase_order_items poi ON poi.product_id = p.id AND poi.po_id = p_po_id
        WHERE p.id = v_received_item.product_id;

        -- A. Record Receipt History
        INSERT INTO purchase_order_receipt_items (
            receipt_id, product_id, quantity, unit_cost, batch_no, expiry_date, is_received
        ) VALUES (
            v_receipt_id, v_received_item.product_id, v_received_item.received_qty, 
            v_received_item.unit_cost, v_received_item.batch_no, v_received_item.expiry_date,
            COALESCE(v_received_item.is_received, TRUE)
        );

        -- B. Preorder Fulfillment
        SELECT COALESCE(SUM(preorder_quantity), 0) INTO v_total_preorder_qty
        FROM branch_inventory
        WHERE branch_id = v_po.branch_id AND product_id = v_received_item.product_id;
        
        v_to_fulfill := LEAST(v_received_item.received_qty, v_total_preorder_qty);
        v_remaining_received := v_received_item.received_qty - v_to_fulfill;

        IF v_to_fulfill > 0 THEN
            UPDATE branch_inventory
            SET preorder_quantity = preorder_quantity - sub.fulfill_amt,
                updated_at = NOW()
            FROM (
                SELECT id, LEAST(preorder_quantity, v_to_fulfill) as fulfill_amt
                FROM branch_inventory
                WHERE branch_id = v_po.branch_id AND product_id = v_received_item.product_id AND preorder_quantity > 0
                ORDER BY created_at ASC
                LIMIT 1
            ) sub
            WHERE branch_inventory.id = sub.id;
        END IF;

        -- C. Upsert Inventory Batch (Matches on Branch + Product + Batch Number)
        -- This ensures regulatory traceability for each batch
        SELECT id, stock_quantity INTO v_batch_id, v_old_qty
        FROM branch_inventory
        WHERE branch_id = v_po.branch_id 
          AND product_id = v_received_item.product_id
          AND COALESCE(batch_no, '') = COALESCE(v_received_item.batch_no, '')
        LIMIT 1;

        IF v_batch_id IS NOT NULL THEN
            UPDATE branch_inventory
            SET stock_quantity = stock_quantity + v_remaining_received,
                expiry_date = COALESCE(v_received_item.expiry_date, expiry_date),
                cost_price = v_received_item.unit_cost,
                selling_price = COALESCE(v_received_item.unit_price, selling_price),
                updated_at = NOW()
            WHERE id = v_batch_id;
        ELSE
            v_old_qty := 0;
            INSERT INTO branch_inventory (
                tenant_id, branch_id, product_id, stock_quantity, 
                batch_no, expiry_date, cost_price, selling_price, 
                purchase_invoice, added_by, is_active,
                product_name, strength, sku, product_type, image_url, unit_of_measure
            ) VALUES (
                v_po.tenant_id, v_po.branch_id, v_received_item.product_id, v_remaining_received,
                v_received_item.batch_no, v_received_item.expiry_date, v_received_item.unit_cost, 
                COALESCE(v_received_item.unit_price, v_received_item.unit_cost * 1.3),
                v_po.po_number, v_staff_id::text, TRUE,
                v_po_item.product_name, v_po_item.strength, v_po_item.sku, v_po_item.product_type, v_po_item.image_url, 
                COALESCE(v_received_item.unit_of_measure, 'unit')
            ) RETURNING id INTO v_batch_id;
        END IF;

        -- D. Record Transaction
        INSERT INTO inventory_transactions (
            tenant_id, branch_id, product_id, branch_inventory_id,
            transaction_type, quantity_delta, previous_quantity, new_quantity,
            unit_cost, reference_id, reference_type, staff_id
        ) VALUES (
            v_po.tenant_id, v_po.branch_id, v_received_item.product_id, v_batch_id,
            'restock'::transaction_type, v_remaining_received, v_old_qty, v_old_qty + v_remaining_received,
            v_received_item.unit_cost, v_po.id, 'purchase_order', v_staff_id
        );
    END LOOP;

    -- Refresh PO status
    SELECT * INTO v_po FROM purchase_orders WHERE id = p_po_id;
    RETURN v_po;
END;
$$;

-- End of 20260508000005_restore_batch_tracking.sql


-- File: 20260508000006_optimize_storefront_batches.sql
-- ============================================================
-- Migration: Optimize Storefront for Batch Tracking
-- ============================================================
-- Description: Updates the ecommerce_products view to aggregate 
--              multiple inventory batches into a single customer 
--              offering with the best price.
-- ============================================================

-- Drop the existing view first to allow changing the column structure
DROP VIEW IF EXISTS ecommerce_products CASCADE;

CREATE OR REPLACE VIEW ecommerce_products AS
SELECT
    p.id,
    bi.tenant_id,
    p.name,
    p.description,
    p.category,
    
    -- Display the lowest available selling price among all batches
    MIN(bi.selling_price) as selling_price,
    
    -- Display the lowest sale price if available
    MIN(COALESCE(sp.sale_price, bi.sale_price)) as sale_price,
    
    p.image_url,
    p.is_active,

    -- Aggregate total stock across all batches and all branches for this tenant
    COALESCE(SUM(bi.stock_quantity), 0) as total_stock,

    -- Count how many unique branches carry this product
    COUNT(DISTINCT bi.branch_id) as branch_count,

    -- Roll up branch details while summing stock per branch
    COALESCE(
        (
            SELECT jsonb_agg(branch_data)
            FROM (
                SELECT 
                    b.id as branch_id,
                    b.name as branch_name,
                    b.address as branch_address,
                    SUM(bi2.stock_quantity) as stock_quantity,
                    SUM(bi2.stock_quantity) > 0 as in_stock,
                    MIN(bi2.selling_price) as selling_price,
                    MIN(COALESCE(sp2.sale_price, bi2.sale_price)) as sale_price
                FROM branches b
                JOIN branch_inventory bi2 ON bi2.branch_id = b.id
                LEFT JOIN sale_products sp2 ON sp2.product_id = p.id AND sp2.tenant_id = bi2.tenant_id
                WHERE bi2.product_id = p.id AND bi2.is_active = true AND b.deleted_at IS NULL
                GROUP BY b.id, b.name, b.address
                ORDER BY b.name
            ) branch_data
        ),
        '[]'::jsonb
    ) as branches,

    -- Global flags
    EXISTS (SELECT 1 FROM sale_products sp3 WHERE sp3.product_id = p.id AND sp3.tenant_id = bi.tenant_id) as is_on_sale,
    EXISTS (SELECT 1 FROM featured_products fp3 WHERE fp3.product_id = p.id AND fp3.tenant_id = bi.tenant_id) as is_featured,
    bool_or(bi.is_new_arrival) as is_new_arrival,
    p."isPOM" as is_pom,

    p.created_at,
    p.updated_at,
    
    -- Catalog metadata
    p.unit_of_measure,
    p.product_type,
    p.generic_name,
    p.strength,
    p.dosage_form,
    p.manufacturer
FROM products p
JOIN branch_inventory bi ON bi.product_id = p.id AND bi.is_active = true
LEFT JOIN sale_products sp ON sp.product_id = p.id AND sp.tenant_id = bi.tenant_id
WHERE p._sync_is_deleted = false
  AND p.is_active = TRUE
GROUP BY
    p.id,
    bi.tenant_id,
    p.name,
    p.description,
    p.category,
    p.image_url,
    p.is_active,
    p.created_at,
    p.updated_at,
    p."isPOM",
    p.unit_of_measure,
    p.product_type,
    p.generic_name,
    p.strength,
    p.dosage_form,
    p.manufacturer;

-- End of 20260508000006_optimize_storefront_batches.sql


-- File: 20260508000007_branch_level_storefront.sql
-- ============================================================
-- Migration: Branch-Level Storefront Aggregation
-- ============================================================
-- Description: Updates the ecommerce_products view to aggregate 
--              batches PER BRANCH instead of per tenant.
-- ============================================================

DROP VIEW IF EXISTS ecommerce_products CASCADE;

CREATE OR REPLACE VIEW ecommerce_products AS
SELECT
    -- Unique ID for the view (Product + Branch)
    (p.id::text || '-' || bi.branch_id::text) as id,
    p.id as product_id,
    bi.tenant_id,
    bi.branch_id,
    b.name as branch_name,
    b.address as branch_address,
    p.name,
    p.description,
    p.category,
    
    -- Lowest price in THIS specific branch
    MIN(bi.selling_price) as selling_price,
    MIN(COALESCE(sp.sale_price, bi.sale_price)) as sale_price,
    
    p.image_url,
    p.is_active,

    -- Total stock in THIS specific branch
    COALESCE(SUM(bi.stock_quantity), 0) as total_stock,

    -- Flags
    EXISTS (SELECT 1 FROM sale_products sp3 WHERE sp3.product_id = p.id AND sp3.tenant_id = bi.tenant_id) as is_on_sale,
    EXISTS (SELECT 1 FROM featured_products fp3 WHERE fp3.product_id = p.id AND fp3.tenant_id = bi.tenant_id) as is_featured,
    bool_or(bi.is_new_arrival) as is_new_arrival,
    p."isPOM" as is_pom,

    p.created_at,
    p.updated_at,
    
    -- Catalog metadata
    p.unit_of_measure,
    p.product_type,
    p.generic_name,
    p.strength,
    p.dosage_form,
    p.manufacturer
FROM products p
JOIN branch_inventory bi ON bi.product_id = p.id AND bi.is_active = true
JOIN branches b ON bi.branch_id = b.id AND b.deleted_at IS NULL
LEFT JOIN sale_products sp ON sp.product_id = p.id AND sp.tenant_id = bi.tenant_id
WHERE p._sync_is_deleted = false
  AND p.is_active = TRUE
GROUP BY
    p.id,
    bi.tenant_id,
    bi.branch_id,
    b.name,
    b.address,
    p.name,
    p.description,
    p.category,
    p.image_url,
    p.is_active,
    p.created_at,
    p.updated_at,
    p."isPOM",
    p.unit_of_measure,
    p.product_type,
    p.generic_name,
    p.strength,
    p.dosage_form,
    p.manufacturer;

-- End of 20260508000007_branch_level_storefront.sql


-- File: 20260508000008_flexible_branch_receiving.sql
-- ============================================================
-- Migration: Flexible Branch Receiving (Part 2)
-- ============================================================
-- Description: Adds branch_id to receipts for better auditing
--              and updates the RPC to support override.
-- ============================================================

-- 1. Ensure the column exists for auditing
ALTER TABLE purchase_order_receipts ADD COLUMN IF NOT EXISTS branch_id UUID REFERENCES branches(id);

-- 2. Update the RPC
CREATE OR REPLACE FUNCTION public.receive_purchase_order(
    p_po_id UUID,
    p_received_items JSONB,
    p_notes TEXT DEFAULT NULL,
    p_branch_id UUID DEFAULT NULL
)
RETURNS purchase_orders
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_po purchase_orders;
    v_target_branch_id UUID;
    v_received_item RECORD;
    v_po_item RECORD;
    v_total_preorder_qty INTEGER;
    v_to_fulfill INTEGER;
    v_remaining_received INTEGER;
    v_batch_id UUID;
    v_staff_id UUID;
    v_receipt_id UUID;
    v_old_qty INTEGER;
BEGIN
    v_staff_id := auth.uid();
    SELECT * INTO v_po FROM purchase_orders WHERE id = p_po_id;
    v_target_branch_id := COALESCE(p_branch_id, v_po.branch_id);

    INSERT INTO purchase_order_receipts (tenant_id, po_id, staff_id, notes, branch_id)
    VALUES (v_po.tenant_id, v_po.id, v_staff_id, p_notes, v_target_branch_id)
    RETURNING id INTO v_receipt_id;

    FOR v_received_item IN SELECT * FROM jsonb_to_recordset(p_received_items) AS x(
        product_id UUID, received_qty INTEGER, batch_no TEXT, expiry_date DATE, 
        unit_cost DECIMAL, unit_price DECIMAL, is_received BOOLEAN, unit_of_measure TEXT
    )
    LOOP
        SELECT COALESCE(poi.product_name, p.name) as product_name, COALESCE(poi.strength, p.strength) as strength, 
               p.barcode as sku, p.product_type, p.image_url
        INTO v_po_item FROM products p 
        LEFT JOIN purchase_order_items poi ON poi.product_id = p.id AND poi.po_id = p_po_id
        WHERE p.id = v_received_item.product_id;

        INSERT INTO purchase_order_receipt_items (receipt_id, product_id, quantity, unit_cost, batch_no, expiry_date, is_received)
        VALUES (v_receipt_id, v_received_item.product_id, v_received_item.received_qty, v_received_item.unit_cost, v_received_item.batch_no, v_received_item.expiry_date, COALESCE(v_received_item.is_received, TRUE));

        SELECT COALESCE(SUM(preorder_quantity), 0) INTO v_total_preorder_qty FROM branch_inventory WHERE branch_id = v_target_branch_id AND product_id = v_received_item.product_id;
        v_to_fulfill := LEAST(v_received_item.received_qty, v_total_preorder_qty);
        v_remaining_received := v_received_item.received_qty - v_to_fulfill;

        IF v_to_fulfill > 0 THEN
            UPDATE branch_inventory SET preorder_quantity = preorder_quantity - sub.fulfill_amt, updated_at = NOW()
            FROM (SELECT id, LEAST(preorder_quantity, v_to_fulfill) as fulfill_amt FROM branch_inventory WHERE branch_id = v_target_branch_id AND product_id = v_received_item.product_id AND preorder_quantity > 0 ORDER BY created_at ASC LIMIT 1) sub
            WHERE branch_inventory.id = sub.id;
        END IF;

        SELECT id, stock_quantity INTO v_batch_id, v_old_qty FROM branch_inventory WHERE branch_id = v_target_branch_id AND product_id = v_received_item.product_id AND COALESCE(batch_no, '') = COALESCE(v_received_item.batch_no, '') LIMIT 1;

        IF v_batch_id IS NOT NULL THEN
            UPDATE branch_inventory SET stock_quantity = stock_quantity + v_remaining_received, expiry_date = COALESCE(v_received_item.expiry_date, expiry_date), cost_price = v_received_item.unit_cost, selling_price = COALESCE(v_received_item.unit_price, selling_price), updated_at = NOW() WHERE id = v_batch_id;
        ELSE
            v_old_qty := 0;
            INSERT INTO branch_inventory (tenant_id, branch_id, product_id, stock_quantity, batch_no, expiry_date, cost_price, selling_price, purchase_invoice, added_by, is_active, product_name, strength, sku, product_type, image_url, unit_of_measure)
            VALUES (v_po.tenant_id, v_target_branch_id, v_received_item.product_id, v_remaining_received, v_received_item.batch_no, v_received_item.expiry_date, v_received_item.unit_cost, COALESCE(v_received_item.unit_price, v_received_item.unit_cost * 1.3), v_po.po_number, v_staff_id::text, TRUE, v_po_item.product_name, v_po_item.strength, v_po_item.sku, v_po_item.product_type, v_po_item.image_url, COALESCE(v_received_item.unit_of_measure, 'unit'))
            RETURNING id INTO v_batch_id;
        END IF;

        INSERT INTO inventory_transactions (tenant_id, branch_id, product_id, branch_inventory_id, transaction_type, quantity_delta, previous_quantity, new_quantity, unit_cost, reference_id, reference_type, staff_id)
        VALUES (v_po.tenant_id, v_target_branch_id, v_received_item.product_id, v_batch_id, 'restock'::transaction_type, v_remaining_received, v_old_qty, v_old_qty + v_remaining_received, v_received_item.unit_cost, v_po.id, 'purchase_order', v_staff_id);
    END LOOP;
    SELECT * INTO v_po FROM purchase_orders WHERE id = p_po_id;
    RETURN v_po;
END;
$$;

-- End of 20260508000008_flexible_branch_receiving.sql


-- File: 20260508000009_final_cleanup.sql
-- ============================================================
-- Migration: Final Legacy Function Cleanup
-- ============================================================
-- Description: Removes the last remaining redundant functions 
--              to ensure the new trigger-based architecture 
--              is the sole source of truth.
-- ============================================================

-- 1. Remove manual sync function (Now handled by triggers)
DROP FUNCTION IF EXISTS public.sync_purchase_order_quantities(UUID);

-- 2. Remove legacy inventory detail function (Now handled by the Receiving RPC)
DROP FUNCTION IF EXISTS public.populate_branch_inventory_details();

-- 3. Cleanup: Ensure any old status triggers are also gone
DROP TRIGGER IF EXISTS tr_sync_po_status ON purchase_order_receipt_items;
DROP FUNCTION IF EXISTS public.fn_sync_po_status();

-- 4. Audit Note
COMMENT ON FUNCTION public.receive_purchase_order IS 'Primary RPC for receiving PO stock. Handles batch tracking, markup, UoM, and fulfillment.';

-- End of 20260508000009_final_cleanup.sql


-- File: 20260508000010_pharmacist_mode.sql
-- Migration: Add Pharmacist Mode to Tenants
-- Replaces freelance_pharmacist_enable with pharmacist_mode enum

-- 1. Remove old boolean column if it exists
ALTER TABLE public.tenants DROP COLUMN IF EXISTS freelance_pharmacist_enable;

-- 2. Add pharmacist_mode column
ALTER TABLE public.tenants ADD COLUMN IF NOT EXISTS pharmacist_mode TEXT NOT NULL DEFAULT 'Inhouse';

-- 3. Add constraint for mode
ALTER TABLE public.tenants DROP CONSTRAINT IF EXISTS tenants_pharmacist_mode_check;
ALTER TABLE public.tenants ADD CONSTRAINT tenants_pharmacist_mode_check 
CHECK (pharmacist_mode IN ('Inhouse', 'Freelance', 'Both'));

-- 4. Set default for existing tenants based on doctor partnership
UPDATE public.tenants SET pharmacist_mode = 'Both' WHERE "allowDoctorPartnerShip" = true;
UPDATE public.tenants SET pharmacist_mode = 'Inhouse' WHERE "allowDoctorPartnerShip" = false;

-- 5. Create a unified view for pharmacists (Staff + Partners)
CREATE OR REPLACE VIEW public.available_pharmacists AS
-- Staff Pharmacists
SELECT 
    u.id as id,
    u.id as user_id,
    u.full_name as display_name,
    u.avatar_url as photo_url,
    'Pharmacist' as specialization,
    u.tenant_id,
    'Inhouse' as provider_type,
    NULL::uuid as provider_id,
    5.0 as average_rating,
    0 as total_reviews,
    5 as years_of_experience,
    true as is_verified,
    (SELECT count(*)::int FROM public.chat_conversations WHERE service_provider = u.id AND status = 'active') as active_chats_count,
    (u.deleted_at IS NULL) as is_active
FROM public.users u
WHERE u.role = 'pharmacist'

UNION ALL

-- Freelance Pharmacists
SELECT 
    da.id as id,
    p.user_id,
    da.alias as display_name,
    p.profile_photo_url as photo_url,
    p.specialization,
    da.tenant_partner as tenant_id,
    'Freelance' as provider_type,
    p.id as provider_id,
    COALESCE(p.average_rating, 0.0) as average_rating,
    COALESCE(p.total_reviews, 0) as total_reviews,
    COALESCE(p.years_of_experience, 0) as years_of_experience,
    p.is_verified,
    (SELECT count(*)::int FROM public.chat_conversations WHERE service_provider = p.user_id AND status = 'active') as active_chats_count,
    da.is_active
FROM public.doctor_aliases da
JOIN public.healthcare_providers p ON da.doctor_id = p.id
WHERE da.accepted = true AND p.type = 'pharmacist';

GRANT SELECT ON public.available_pharmacists TO authenticated;
GRANT SELECT ON public.available_pharmacists TO anon;

COMMENT ON COLUMN public.tenants.pharmacist_mode IS 'Determines who handles pharmacy consultations: Inhouse staff, Freelance partners, or Both.';

-- End of 20260508000010_pharmacist_mode.sql


-- File: 20260508000011_prescription_commissions.sql
-- Migration: Prescription Commissions
-- Tracks fees for freelance pharmacist consultations

ALTER TABLE public.prescriptions 
ADD COLUMN IF NOT EXISTS is_freelance BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS commission_rate DECIMAL(5,4) DEFAULT 0.0550, -- 5.5%
ADD COLUMN IF NOT EXISTS platform_fee_rate DECIMAL(5,4) DEFAULT 0.0100, -- 1.0%
ADD COLUMN IF NOT EXISTS medic_payout_rate DECIMAL(5,4) DEFAULT 0.0450; -- 4.5%

COMMENT ON COLUMN public.prescriptions.is_freelance IS 'True if issued by a freelance pharmacist, triggering the 5.5% fee.';
COMMENT ON COLUMN public.prescriptions.commission_rate IS 'Total prescription fee rate (e.g., 0.0550 for 5.5%).';
COMMENT ON COLUMN public.prescriptions.platform_fee_rate IS 'Platform share of the commission (e.g., 0.0100 for 1%).';
COMMENT ON COLUMN public.prescriptions.medic_payout_rate IS 'Medic share of the commission (e.g., 0.0450 for 4.5%).';

-- End of 20260508000011_prescription_commissions.sql


-- File: 20260508000012_chat_queue_system.sql
-- Migration: Chat Queue System
-- Implements one-at-a-time consultation logic

-- 1. Handle dependencies and alter status column
DO $$
BEGIN
    -- Drop all dependencies first
    DROP VIEW IF EXISTS public.available_pharmacists;
    DROP INDEX IF EXISTS public.idx_chat_conversations_status;
    DROP INDEX IF EXISTS public.idx_chat_status;

    -- Remove default to avoid type mismatch during alter
    ALTER TABLE public.chat_conversations ALTER COLUMN status DROP DEFAULT;

    -- Alter column to TEXT with explicit cast
    -- We use varchar first then text as a workaround for some PG versions if needed
    ALTER TABLE public.chat_conversations 
    ALTER COLUMN status TYPE TEXT USING status::text;
    
    -- Restore default
    ALTER TABLE public.chat_conversations ALTER COLUMN status SET DEFAULT 'active';

    -- Update/Add check constraints
    ALTER TABLE public.chat_conversations DROP CONSTRAINT IF EXISTS chat_conversations_status_check;
    ALTER TABLE public.chat_conversations DROP CONSTRAINT IF EXISTS chat_conversations_status_check1;
    
    -- Re-add the constraint as TEXT check
    ALTER TABLE public.chat_conversations ADD CONSTRAINT chat_conversations_status_check 
    CHECK (status IN ('active', 'waiting', 'completed', 'archived', 'deleted', 'escalated', 'abandoned', 'open'));

    -- Re-create the index
    CREATE INDEX idx_chat_conversations_status ON public.chat_conversations(status);
END $$;

-- 2. Recreate the available_pharmacists view
CREATE OR REPLACE VIEW public.available_pharmacists AS
-- Staff Pharmacists
SELECT 
    u.id as id,
    u.id as user_id,
    u.full_name as display_name,
    u.avatar_url as photo_url,
    'Pharmacist' as specialization,
    u.tenant_id,
    'Inhouse' as provider_type,
    NULL::uuid as provider_id,
    5.0 as average_rating,
    0 as total_reviews,
    5 as years_of_experience,
    true as is_verified,
    (SELECT count(*)::int FROM public.chat_conversations WHERE service_provider = u.id AND status = 'active') as active_chats_count,
    (u.deleted_at IS NULL) as is_active
FROM public.users u
WHERE u.role = 'pharmacist'

UNION ALL

-- Freelance Pharmacists
SELECT 
    da.id as id,
    p.user_id,
    da.alias as display_name,
    p.profile_photo_url as photo_url,
    p.specialization,
    da.tenant_partner as tenant_id,
    'Freelance' as provider_type,
    p.id as provider_id,
    COALESCE(p.average_rating, 0.0) as average_rating,
    COALESCE(p.total_reviews, 0) as total_reviews,
    COALESCE(p.years_of_experience, 0) as years_of_experience,
    p.is_verified,
    (SELECT count(*)::int FROM public.chat_conversations WHERE service_provider = p.user_id AND status = 'active') as active_chats_count,
    da.is_active
FROM public.doctor_aliases da
JOIN public.healthcare_providers p ON da.doctor_id = p.id
WHERE da.accepted = true AND p.type = 'pharmacist';

-- 3. Function to get queue position
CREATE OR REPLACE FUNCTION public.get_chat_queue_position(p_conversation_id UUID)
RETURNS INTEGER AS $$
DECLARE
    v_provider_id UUID;
    v_created_at TIMESTAMPTZ;
    v_pos INTEGER;
BEGIN
    -- Get conversation details
    SELECT service_provider, created_at INTO v_provider_id, v_created_at
    FROM public.chat_conversations
    WHERE id = p_conversation_id;

    IF v_provider_id IS NULL THEN RETURN 0; END IF;

    -- Count how many 'waiting' chats for this provider were created before this one
    SELECT count(*)::int + 1 INTO v_pos
    FROM public.chat_conversations
    WHERE service_provider = v_provider_id
      AND status = 'waiting'
      AND created_at <= v_created_at;

    RETURN v_pos;
END;
$$ LANGUAGE plpgsql STABLE;

-- 4. Trigger to automatically queue if provider is busy
CREATE OR REPLACE FUNCTION public.handle_chat_queue_on_create()
RETURNS TRIGGER AS $$
DECLARE
    v_active_count INTEGER;
BEGIN
    -- Only apply if a specific service provider is assigned
    IF NEW.service_provider IS NOT NULL THEN
        -- Check if provider has any active chats
        SELECT count(*)::int INTO v_active_count
        FROM public.chat_conversations
        WHERE service_provider = NEW.service_provider
          AND status = 'active';

        -- If busy, move to waiting
        IF v_active_count > 0 AND NEW.status = 'active' THEN
            NEW.status := 'waiting';
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_handle_chat_queue_on_create ON public.chat_conversations;
CREATE TRIGGER trigger_handle_chat_queue_on_create
    BEFORE INSERT ON public.chat_conversations
    FOR EACH ROW
    EXECUTE FUNCTION handle_chat_queue_on_create();

-- End of 20260508000012_chat_queue_system.sql


-- File: 20260508000012_order_prescription_fee.sql
-- Migration: Add Prescription Fee to Orders
-- Tracks the 5.5% commission for freelance pharmacist consultations

ALTER TABLE public.orders 
ADD COLUMN IF NOT EXISTS prescription_fee DECIMAL(10,2) DEFAULT 0.00;

COMMENT ON COLUMN public.orders.prescription_fee IS 'Total fee for freelance pharmacist prescriptions (5.5%).';

-- End of 20260508000012_order_prescription_fee.sql


-- File: 20260508000013_checkout_prescription_fee_logic.sql
-- Migration: Update checkout_storefront_order with Prescription Fee Logic
-- Automatically calculates and applies 5.5% fee for freelance pharmacist prescriptions

CREATE OR REPLACE FUNCTION checkout_storefront_order(
    p_tenant_id UUID,
    p_branch_id UUID,
    p_customer_id UUID,
    p_order_type order_type,
    p_fulfillment_type fulfillment_type,
    p_subtotal DECIMAL,
    p_delivery_fee DECIMAL,
    p_tax_amount DECIMAL,
    p_total_amount DECIMAL,
    p_delivery_address_id UUID,
    p_special_instructions TEXT,
    p_items JSONB, -- Array of { product_id, product_name, quantity, unit_price, subtotal, prescription_id }
    p_service_charge DECIMAL DEFAULT 0,
    p_payment_reference TEXT DEFAULT NULL,
    p_billing_address TEXT DEFAULT NULL,
    p_shipping_address TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_order_id UUID;
    v_item RECORD;
    v_batch RECORD;
    v_req_qty INTEGER;
    v_available_qty INTEGER;
    v_allocated_qty INTEGER;
    v_allocations JSONB;
    v_primary_batch_id UUID;
    v_preorders_enabled BOOLEAN;
    v_allow_preorder BOOLEAN;
    v_prescription_fee DECIMAL := 0;
    v_is_freelance_pres BOOLEAN;
BEGIN
    -- Check if preorders are enabled for the tenant
    SELECT preorders_enabled INTO v_preorders_enabled FROM tenants WHERE id = p_tenant_id;

    -- 1. Pre-calculate Prescription Fees from items
    FOR v_item IN SELECT * FROM jsonb_to_recordset(p_items) AS x(
        product_id UUID, subtotal DECIMAL, prescription_id UUID
    )
    LOOP
        IF v_item.prescription_id IS NOT NULL THEN
            SELECT is_freelance INTO v_is_freelance_pres 
            FROM prescriptions 
            WHERE id = v_item.prescription_id;
            
            IF v_is_freelance_pres = TRUE THEN
                v_prescription_fee := v_prescription_fee + (v_item.subtotal * 0.055);
            END IF;
        END IF;
    END LOOP;

    -- Validate totals (including prescription fee)
    -- We allow a small epsilon for floating point rounding in fee calculation
    IF ABS(p_total_amount - (p_subtotal + p_delivery_fee + p_tax_amount + p_service_charge + v_prescription_fee)) > 0.01 THEN
        RAISE EXCEPTION 'Total amount % does not match subtotal % + fees % + tax % + service charge % + prescription fee %', 
            p_total_amount, p_subtotal, p_delivery_fee, p_tax_amount, p_service_charge, v_prescription_fee;
    END IF;

    -- Create the order header
    INSERT INTO orders (
        tenant_id, branch_id, order_number, customer_id,
        order_type, order_status, payment_status, payment_method, payment_reference,
        subtotal, delivery_fee, tax_amount, service_charge, prescription_fee, total_amount,
        fulfillment_type, delivery_address_id, special_instructions,
        billing_address, shipping_address
    ) VALUES (
        p_tenant_id,
        p_branch_id,
        'ORD-' || FLOOR(EXTRACT(EPOCH FROM NOW()))::TEXT || '-' || SUBSTRING(MD5(RANDOM()::TEXT) FROM 1 FOR 4),
        p_customer_id,
        p_order_type,
        'pending'::order_status,
        CASE WHEN p_payment_reference IS NOT NULL THEN 'paid'::payment_status ELSE 'unpaid'::payment_status END,
        'card'::payment_method,
        p_payment_reference,
        p_subtotal, p_delivery_fee, p_tax_amount, p_service_charge, v_prescription_fee, p_total_amount,
        p_fulfillment_type,
        p_delivery_address_id,
        p_special_instructions,
        p_billing_address,
        p_shipping_address
    ) RETURNING id INTO v_order_id;

    -- Process each item
    FOR v_item IN SELECT * FROM jsonb_to_recordset(p_items) AS x(
        product_id UUID, product_name TEXT, quantity INTEGER, unit_price DECIMAL, subtotal DECIMAL, prescription_id UUID
    )
    LOOP
        v_req_qty := v_item.quantity;
        v_allocations := '[]'::jsonb;
        v_primary_batch_id := NULL;

        -- Allocation Logic (FIFO)
        FOR v_batch IN 
            SELECT id, (stock_quantity - COALESCE(reserved_quantity, 0)) AS available_balance
            FROM branch_inventory
            WHERE branch_id = p_branch_id 
              AND product_id = v_item.product_id 
              AND is_active = true
              AND (stock_quantity - COALESCE(reserved_quantity, 0)) > 0
            ORDER BY expiry_date ASC NULLS LAST, created_at ASC
            FOR UPDATE
        LOOP
            IF v_req_qty <= 0 THEN EXIT; END IF;

            v_available_qty := v_batch.available_balance;
            v_allocated_qty := LEAST(v_available_qty, v_req_qty);

            UPDATE branch_inventory
            SET reserved_quantity = COALESCE(reserved_quantity, 0) + v_allocated_qty,
                updated_at = NOW()
            WHERE id = v_batch.id;

            IF v_primary_batch_id IS NULL THEN
                v_primary_batch_id := v_batch.id;
            END IF;

            v_allocations := v_allocations || jsonb_build_object(
                'batch_id', v_batch.id,
                'quantity', v_allocated_qty,
                'is_preorder', false
            );

            v_req_qty := v_req_qty - v_allocated_qty;
        END LOOP;

        -- Preorder Logic
        IF v_req_qty > 0 THEN
            SELECT allow_preorder INTO v_allow_preorder 
            FROM branch_inventory 
            WHERE branch_id = p_branch_id AND product_id = v_item.product_id 
            LIMIT 1;
            
            IF COALESCE(v_preorders_enabled, false) AND COALESCE(v_allow_preorder, false) THEN
                SELECT id INTO v_primary_batch_id 
                FROM branch_inventory 
                WHERE branch_id = p_branch_id AND product_id = v_item.product_id 
                LIMIT 1 FOR UPDATE;

                IF v_primary_batch_id IS NULL THEN
                    INSERT INTO branch_inventory (
                        tenant_id, branch_id, product_id, stock_quantity, preorder_quantity, cost_price
                    ) VALUES (
                        p_tenant_id, p_branch_id, v_item.product_id, 0, v_req_qty, 0
                    ) RETURNING id INTO v_primary_batch_id;
                ELSE
                    UPDATE branch_inventory 
                    SET preorder_quantity = COALESCE(preorder_quantity, 0) + v_req_qty,
                        updated_at = NOW()
                    WHERE id = v_primary_batch_id;
                END IF;

                v_allocations := v_allocations || jsonb_build_object(
                    'batch_id', v_primary_batch_id,
                    'quantity', v_req_qty,
                    'is_preorder', true
                );
                v_req_qty := 0;
            ELSE
                RAISE EXCEPTION 'Insufficient stock for product: % (short by %)', v_item.product_name, v_req_qty;
            END IF;
        END IF;

        INSERT INTO public.sale_items (
            tenant_id, order_id, branch_id, inventory_id,
            product_id, product_name, quantity, unit_price, subtotal,
            discount_amount, batch_allocations, prescription_id
        ) VALUES (
            p_tenant_id, v_order_id, p_branch_id, v_primary_batch_id,
            v_item.product_id, v_item.product_name, v_item.quantity, v_item.unit_price, v_item.subtotal,
            0, v_allocations, v_item.prescription_id
        );
    END LOOP;

    RETURN v_order_id;
END;
$$;

-- End of 20260508000013_checkout_prescription_fee_logic.sql


-- File: 20260508000014_fix_doctor_aliases_schema.sql
-- Migration: Fix Doctor Aliases Schema
-- Adds tenant_partner and ensures created_at and other fields are in the view

-- 1. Add tenant_partner to doctor_aliases table
ALTER TABLE public.doctor_aliases ADD COLUMN IF NOT EXISTS tenant_partner UUID REFERENCES public.tenants(id) ON DELETE CASCADE;

-- 2. Backfill tenant_partner if possible (optional, but good for existing data)
-- If we assume primary_doctor_id's tenant is the intended partner
UPDATE public.doctor_aliases da
SET tenant_partner = u.tenant_id
FROM public.healthcare_providers hp
JOIN public.users u ON hp.user_id = u.id
WHERE da.primary_doctor_id = hp.id AND da.tenant_partner IS NULL;

-- 3. Recreate the view to include all necessary fields
CREATE OR REPLACE VIEW public.doctor_aliases_with_details AS
SELECT
  da.id,
  da.doctor_id,
  da.primary_doctor_id,
  da.tenant_partner,
  da.alias as display_name, -- renamed for consistency with other views
  da.alias,
  da.is_active,
  da.created_at,
  da.accepted,
  -- Provider details from healthcare_providers
  hp.full_name AS doctor_name,
  hp.profile_photo_url,
  hp.specialization,
  hp.sub_specialty,
  hp.years_of_experience,
  hp.consultation_types,
  hp.marked_up_fees AS consultation_fees,
  hp.preferred_languages,
  hp.average_rating,
  hp.total_consultations,
  hp.total_reviews,
  hp.is_verified,
  -- Primary doctor info
  hp_primary.full_name AS primary_doctor_name,
  COALESCE(hp_primary."clinic name", hp_primary.full_name) AS clinic_name
FROM public.doctor_aliases da
JOIN public.healthcare_providers hp ON da.doctor_id = hp.id
LEFT JOIN public.healthcare_providers hp_primary ON da.primary_doctor_id = hp_primary.id;

-- 4. Ensure RLS allows the tenant to see their aliases
DROP POLICY IF EXISTS "Tenants can see their partners" ON public.doctor_aliases;
CREATE POLICY "Tenants can see their partners" 
ON public.doctor_aliases FOR SELECT 
USING (
  tenant_partner IN (
    SELECT tenant_id FROM public.users 
    WHERE id = auth.uid()
  )
);

-- End of 20260508000014_fix_doctor_aliases_schema.sql


-- File: 20260508000014_sale_items_prescription_link.sql
-- Migration: Link Sale Items to Prescriptions
-- Enables tracking which items in a sale were authorized by which prescription

ALTER TABLE public.sale_items 
ADD COLUMN IF NOT EXISTS prescription_id UUID REFERENCES public.prescriptions(id) ON DELETE SET NULL;

COMMENT ON COLUMN public.sale_items.prescription_id IS 'Link to the prescription that authorized this drug sale.';

-- End of 20260508000014_sale_items_prescription_link.sql


-- File: 20260508000015_healthcare_commissions_v2.sql
-- Migration: Healthcare Commissions V2
-- Formalizes 5.5% prescription fee for all partners and 10% consultation fee for tenants

-- 1. Update prescriptions to reflect all partners (not just pharmacists)
COMMENT ON COLUMN public.prescriptions.is_freelance IS 'True if issued by a freelance partner (doctor or pharmacist), triggering the 5.5% fee.';

-- 2. Add consultation commission tracking to consultations table
ALTER TABLE public.consultations 
ADD COLUMN IF NOT EXISTS tenant_commission_rate DECIMAL(5,4) DEFAULT 0.0000,
ADD COLUMN IF NOT EXISTS tenant_commission_amount DECIMAL(10,2) DEFAULT 0.00;

COMMENT ON COLUMN public.consultations.tenant_commission_rate IS 'Rate of consultation fee that goes to the tenant (e.g., 0.1000 for 10%).';
COMMENT ON COLUMN public.consultations.tenant_commission_amount IS 'Calculated amount from the consultation fee that goes to the tenant.';

-- 3. Trigger to automatically set commission rate for doctors
CREATE OR REPLACE FUNCTION public.calculate_consultation_commissions()
RETURNS TRIGGER AS $$
DECLARE
    v_provider_type TEXT;
BEGIN
    -- Get provider type
    SELECT type INTO v_provider_type
    FROM public.healthcare_providers
    WHERE id = NEW.provider_id;

    -- If referred by storefront and provider is a doctor, set 10% commission
    IF NEW.referral_source = 'storefront' AND v_provider_type = 'doctor' THEN
        NEW.tenant_commission_rate := 0.1000;
        NEW.tenant_commission_amount := NEW.consultation_fee * 0.1000;
    ELSE
        NEW.tenant_commission_rate := 0.0000;
        NEW.tenant_commission_amount := 0.00;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_calculate_consultation_commissions ON public.consultations;
CREATE TRIGGER trigger_calculate_consultation_commissions
    BEFORE INSERT OR UPDATE OF consultation_fee, referral_source ON public.consultations
    FOR EACH ROW
    EXECUTE FUNCTION calculate_consultation_commissions();

-- 4. ENSURE DOCTOR_ALIASES TABLE AND VIEW ARE UPDATED
-- Safety check for the column
ALTER TABLE public.doctor_aliases ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW();

-- Drop view to refresh schema
DROP VIEW IF EXISTS public.doctor_aliases_with_details;

-- We use a dynamic approach for the view to handle potentially missing clinic_name column
DO $$
BEGIN
    EXECUTE 'CREATE OR REPLACE VIEW public.doctor_aliases_with_details AS
    SELECT
      da.id,
      da.doctor_id,
      da.primary_doctor_id,
      da.tenant_partner,
      da.alias as display_name,
      da.alias,
      da.is_active,
      da.created_at,
      da.accepted,
      -- Provider details
      hp.full_name AS doctor_name,
      hp.profile_photo_url,
      hp.specialization,
      hp.sub_specialty,
      hp.years_of_experience,
      hp.average_rating,
      hp.is_verified,
      -- Primary doctor info
      hp_primary.full_name AS primary_doctor_name,
      ' || 
      CASE WHEN EXISTS (
          SELECT 1 FROM information_schema.columns 
          WHERE table_name = 'healthcare_providers' AND column_name = 'clinic_name'
      ) THEN 'COALESCE(hp_primary.clinic_name, hp_primary.full_name)'
      ELSE 'hp_primary.full_name' 
      END || ' AS clinic_name
    FROM public.doctor_aliases da
    JOIN public.healthcare_providers hp ON da.doctor_id = hp.id
    LEFT JOIN public.healthcare_providers hp_primary ON da.primary_doctor_id = hp_primary.id';
END $$;

GRANT SELECT ON public.doctor_aliases_with_details TO authenticated;
GRANT SELECT ON public.doctor_aliases_with_details TO anon;

-- End of 20260508000015_healthcare_commissions_v2.sql


-- File: 20260508000016_fix_po_receiving_calculations.sql
-- ============================================================
-- Migration: Simplified PO Receiving (No Pre-orders)
-- ============================================================
-- Description: 
-- 1. Removes all pre-order fulfillment logic.
-- 2. Strictly increments stock_quantity for received items.
-- 3. Maintains batch tracking for regulatory compliance.
-- ============================================================

-- 1. Update the receiving RPC
DO $$ 
DECLARE 
    r RECORD;
BEGIN
    FOR r IN (SELECT oid::regprocedure as sig FROM pg_proc WHERE proname = 'receive_purchase_order' AND pronamespace = 'public'::regnamespace) LOOP
        EXECUTE 'DROP FUNCTION ' || r.sig || ' CASCADE';
    END LOOP;
END $$;

CREATE OR REPLACE FUNCTION public.receive_purchase_order(
    p_po_id UUID,
    p_received_items JSONB,
    p_notes TEXT DEFAULT NULL,
    p_branch_id UUID DEFAULT NULL
)
RETURNS purchase_orders
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_po purchase_orders;
    v_target_branch_id UUID;
    v_received_item RECORD;
    v_po_item RECORD;
    v_batch_id UUID;
    v_staff_id UUID;
    v_receipt_id UUID;
    v_old_qty INTEGER := 0;
BEGIN
    -- 1. Basic Setup
    v_staff_id := auth.uid();
    SELECT * INTO v_po FROM purchase_orders WHERE id = p_po_id FOR UPDATE;
    IF v_po.id IS NULL THEN RAISE EXCEPTION 'Purchase Order not found'; END IF;
    
    v_target_branch_id := COALESCE(p_branch_id, v_po.branch_id);

    -- 2. Create the Receipt Group record
    INSERT INTO purchase_order_receipts (tenant_id, po_id, staff_id, notes, branch_id)
    VALUES (v_po.tenant_id, v_po.id, v_staff_id, p_notes, v_target_branch_id)
    RETURNING id INTO v_receipt_id;

    -- 3. Process each item
    FOR v_received_item IN SELECT * FROM jsonb_to_recordset(p_received_items) AS x(
        product_id UUID, received_qty INTEGER, batch_no TEXT, expiry_date DATE, 
        unit_cost DECIMAL, unit_price DECIMAL, is_received BOOLEAN, unit_of_measure TEXT
    )
    LOOP
        -- Skip items with zero quantity
        IF COALESCE(v_received_item.received_qty, 0) = 0 THEN
            CONTINUE;
        END IF;

        -- Reset loop variables
        v_batch_id := NULL;
        v_old_qty := 0;
        v_po_item := NULL;

        -- A. Fetch Product/PO Item Details
        SELECT COALESCE(poi.product_name, p.name) as product_name, 
               COALESCE(poi.strength, p.strength) as strength, 
               p.barcode as sku, p.product_type, p.image_url
        INTO v_po_item 
        FROM products p 
        LEFT JOIN purchase_order_items poi ON poi.product_id = p.id AND poi.po_id = p_po_id
        WHERE p.id = v_received_item.product_id;

        -- B. Record Receipt Item
        INSERT INTO purchase_order_receipt_items (
            receipt_id, product_id, quantity, unit_cost, batch_no, expiry_date, is_received
        ) VALUES (
            v_receipt_id, v_received_item.product_id, v_received_item.received_qty, 
            v_received_item.unit_cost, v_received_item.batch_no, v_received_item.expiry_date,
            COALESCE(v_received_item.is_received, TRUE)
        );

        -- C. Upsert Inventory Batch (Direct Stock Update)
        SELECT id, stock_quantity INTO v_batch_id, v_old_qty 
        FROM branch_inventory 
        WHERE branch_id = v_target_branch_id 
          AND product_id = v_received_item.product_id 
          AND COALESCE(batch_no, '') = COALESCE(v_received_item.batch_no, '') 
        LIMIT 1;

        IF v_batch_id IS NOT NULL THEN
            UPDATE branch_inventory 
            SET stock_quantity = stock_quantity + v_received_item.received_qty,
                expiry_date = COALESCE(v_received_item.expiry_date, expiry_date),
                cost_price = COALESCE(v_received_item.unit_cost, cost_price),
                updated_at = NOW()
            WHERE id = v_batch_id;
        ELSE
            INSERT INTO branch_inventory (
                tenant_id, branch_id, product_id, stock_quantity, batch_no, expiry_date, 
                cost_price, selling_price, purchase_invoice, added_by, is_active, 
                product_name, strength, sku, product_type, image_url, unit_of_measure
            ) VALUES (
                v_po.tenant_id, v_target_branch_id, v_received_item.product_id, v_received_item.received_qty, 
                v_received_item.batch_no, v_received_item.expiry_date, v_received_item.unit_cost, 
                COALESCE(v_received_item.unit_price, v_received_item.unit_cost * 1.3), 
                v_po.po_number, v_staff_id::text, TRUE, 
                v_po_item.product_name, v_po_item.strength, v_po_item.sku, v_po_item.product_type, v_po_item.image_url, 
                COALESCE(v_received_item.unit_of_measure, 'unit')
            ) RETURNING id INTO v_batch_id;
        END IF;

        -- D. Record Transaction
        INSERT INTO inventory_transactions (
            tenant_id, branch_id, product_id, branch_inventory_id, transaction_type, 
            quantity_delta, previous_quantity, new_quantity, unit_cost, 
            reference_id, reference_type, staff_id
        ) VALUES (
            v_po.tenant_id, v_target_branch_id, v_received_item.product_id, v_batch_id, 
            'restock'::transaction_type, v_received_item.received_qty, COALESCE(v_old_qty, 0), COALESCE(v_old_qty, 0) + v_received_item.received_qty, 
            v_received_item.unit_cost, v_po.id, 'purchase_order', v_staff_id
        );
    END LOOP;

    -- 4. Sync PO status
    UPDATE purchase_orders SET updated_at = NOW() WHERE id = p_po_id;
    
    SELECT * INTO v_po FROM purchase_orders WHERE id = p_po_id;
    RETURN v_po;
END;
$$;

-- End of 20260508000016_fix_po_receiving_calculations.sql


-- File: 20260508000017_modernize_inventory_cleanup.sql
-- ============================================================
-- Migration: Modernize Product Architecture & Cleanup Redundancy
-- ============================================================
-- Description: 
-- 1. Drops redundant stock_quantity column from products table.
-- 2. Drops legacy sync triggers and functions.
-- 3. Modernizes the ecommerce_products view to use the new 
--    multi-branch inventory architecture without grouping errors.
-- ============================================================

-- 1. Drop Legacy Triggers and Functions
DROP TRIGGER IF EXISTS auto_sync_product_stock ON branch_inventory;
DROP FUNCTION IF EXISTS public.sync_product_total_stock();
DROP FUNCTION IF EXISTS public.trigger_sync_product_stock();

-- Also drop the rogue trigger that fires on inventory_transactions INSERT and
-- overwrites ALL batches for a product with the same stock_quantity (no batch filter).
-- This conflicts with the multi-batch receive_purchase_order RPC.
DROP TRIGGER IF EXISTS trg_update_branch_inventory_stock ON inventory_transactions;
DROP FUNCTION IF EXISTS public.update_branch_inventory_stock();

-- 2. Modernize the E-commerce View
-- We drop the view first because CREATE OR REPLACE does not allow changing 
-- the column structure (shape) of an existing view.
DROP VIEW IF EXISTS public.ecommerce_products CASCADE;
CREATE VIEW public.ecommerce_products AS
SELECT
    p.id,
    -- Safely get tenant_id from related tables if it's missing on the master table
    COALESCE(
        (SELECT tenant_id FROM public.product_stock_balance WHERE product_id = p.id LIMIT 1),
        (SELECT tenant_id FROM public.branches LIMIT 1)
    ) as tenant_id,
    p.name,
    p.description,
    p.category,
    p.image_url,
    p.is_active,

    -- Aggregate stock via subquery
    (SELECT COALESCE(SUM(stock_balance), 0)::BIGINT 
     FROM public.product_stock_balance 
     WHERE product_id = p.id) as total_stock,

    -- Count branches via subquery
    (SELECT COUNT(DISTINCT branch_id) 
     FROM public.product_stock_balance 
     WHERE product_id = p.id AND stock_balance > 0) as branch_count,

    -- Collect detailed branch information
    (SELECT COALESCE(
        jsonb_agg(
            jsonb_build_object(
                'branch_id', b.id,
                'branch_name', b.name,
                'branch_address', b.address,
                'branch_phone', b.phone,
                'latitude', b.latitude,
                'longitude', b.longitude,
                'stock_quantity', psb.stock_balance,
                'selling_price', (SELECT MIN(selling_price) FROM public.branch_inventory bi WHERE bi.product_id = p.id AND bi.branch_id = b.id),
                'in_stock', psb.stock_balance > 0
            ) ORDER BY b.name
        ), 
        '[]'::jsonb
     )
     FROM public.product_stock_balance psb
     JOIN public.branches b ON psb.branch_id = b.id
     WHERE psb.product_id = p.id AND b.deleted_at IS NULL
    ) as branches,

    -- Min and max price via subqueries
    COALESCE((SELECT MIN(selling_price) FROM public.branch_inventory WHERE product_id = p.id AND is_active = true), 0) as min_price,
    COALESCE((SELECT MAX(selling_price) FROM public.branch_inventory WHERE product_id = p.id AND is_active = true), 0) as max_price,

    p.created_at,
    p.updated_at
FROM public.products p
WHERE p.deleted_at IS NULL
  AND p.is_active = TRUE;

-- 3. Update the E-commerce helper function
CREATE OR REPLACE FUNCTION public.get_ecommerce_products(
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
        ep.min_price as unit_price, -- Backward compatibility
        ep.image_url,
        ep.total_stock,
        ep.branch_count,
        ep.branches,
        ep.min_price,
        ep.max_price
    FROM public.ecommerce_products ep
    WHERE ep.tenant_id = p_tenant_id

    -- Category filter
    AND (p_category IS NULL OR ep.category = p_category)

    -- Stock filter
    AND (NOT p_in_stock_only OR ep.total_stock > 0)

    -- Branch filter
    AND (p_branch_id IS NULL OR EXISTS (
        SELECT 1 FROM jsonb_array_elements(ep.branches) AS branch
        WHERE (branch->>'branch_id')::UUID = p_branch_id
    ))

    -- Location filter
    AND (
        p_latitude IS NULL OR p_longitude IS NULL OR p_max_distance_km IS NULL
        OR EXISTS (
            SELECT 1 FROM jsonb_array_elements(ep.branches) AS branch
            WHERE (branch->>'latitude') IS NOT NULL
            AND (branch->>'longitude') IS NOT NULL
            AND (
                ST_DWithin(
                    ST_MakePoint((branch->>'longitude')::DECIMAL, (branch->>'latitude')::DECIMAL)::geography,
                    ST_MakePoint(p_longitude, p_latitude)::geography,
                    p_max_distance_km * 1000
                )
            )
        )
    )

    ORDER BY ep.name;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Drop Redundant Columns from products table
-- We do this LAST to ensure views have been updated first.
ALTER TABLE public.products DROP COLUMN IF EXISTS stock_quantity;
ALTER TABLE public.products DROP COLUMN IF EXISTS branch_id;
ALTER TABLE public.products DROP COLUMN IF EXISTS low_stock_threshold;
ALTER TABLE public.products DROP COLUMN IF EXISTS expiry_date;
ALTER TABLE public.products DROP COLUMN IF EXISTS cost_price;
ALTER TABLE public.products DROP COLUMN IF EXISTS unit_price;

-- 5. Final Audit Note
COMMENT ON VIEW ecommerce_products IS 'Aggregated product view for e-commerce storefront, modernized to use subqueries for maximum compatibility.';

-- End of 20260508000017_modernize_inventory_cleanup.sql


-- File: 20260508000018_recalculate_inventory_levels.sql
-- ============================================================
-- Migration: Recalculate Inventory Levels (Simplified)
-- ============================================================

DO $$
DECLARE
    v_row RECORD;
    v_actual_in INTEGER;
    v_actual_out INTEGER;
    v_actual_stock INTEGER;
BEGIN
    RAISE NOTICE 'Starting simplified inventory audit...';

    -- 1. Fix Stock Quantity Discrepancies
    FOR v_row IN 
        SELECT id, product_id, branch_id, batch_no, stock_quantity 
        FROM branch_inventory
    LOOP
        -- Calculate Total Received
        SELECT COALESCE(SUM(ri.quantity), 0) INTO v_actual_in
        FROM purchase_order_receipt_items ri
        JOIN purchase_order_receipts r ON ri.receipt_id = r.id
        WHERE r.branch_id = v_row.branch_id 
          AND ri.product_id = v_row.product_id
          AND COALESCE(ri.batch_no, '') = COALESCE(v_row.batch_no, '')
          AND COALESCE(ri.is_received, TRUE) = TRUE;

        -- Calculate Total Sold
        SELECT COALESCE(SUM(si.quantity), 0) INTO v_actual_out
        FROM sale_items si
        JOIN sales s ON si.sale_id = s.id
        WHERE si.inventory_id = v_row.id
          AND s.sale_status = 'completed';

        v_actual_stock := v_actual_in - v_actual_out;
        
        -- Update the row, clearing preorder and reserved buckets
        UPDATE branch_inventory 
        SET stock_quantity = GREATEST(v_actual_stock, 0),
            preorder_quantity = 0,
            reserved_quantity = 0,
            updated_at = NOW()
        WHERE id = v_row.id;
    END LOOP;

    RAISE NOTICE 'Inventory audit completed. Pre-orders cleared.';
END$$;

-- End of 20260508000018_recalculate_inventory_levels.sql


-- File: 20260508000019_repair_rpc.sql
-- ============================================================
-- Migration: Simplified Repair RPC (No Pre-orders)
-- ============================================================

CREATE OR REPLACE FUNCTION public.repair_inventory_levels()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_row RECORD;
    v_actual_in INTEGER;
    v_actual_out INTEGER;
    v_actual_stock INTEGER;
    v_count INTEGER := 0;
BEGIN
    -- Fix Stock Quantity Discrepancies
    FOR v_row IN 
        SELECT id, product_id, branch_id, batch_no, stock_quantity 
        FROM branch_inventory
    LOOP
        -- Calculate Total Received
        SELECT COALESCE(SUM(ri.quantity), 0) INTO v_actual_in
        FROM purchase_order_receipt_items ri
        JOIN purchase_order_receipts r ON ri.receipt_id = r.id
        WHERE r.branch_id = v_row.branch_id 
          AND ri.product_id = v_row.product_id
          AND COALESCE(ri.batch_no, '') = COALESCE(v_row.batch_no, '')
          AND COALESCE(ri.is_received, TRUE) = TRUE;

        -- Calculate Total Sold
        SELECT COALESCE(SUM(si.quantity), 0) INTO v_actual_out
        FROM sale_items si
        JOIN sales s ON si.sale_id = s.id
        WHERE si.inventory_id = v_row.id
          AND s.sale_status = 'completed';

        v_actual_stock := v_actual_in - v_actual_out;
        
        -- Update the row â€” physical stock only
        UPDATE branch_inventory 
        SET stock_quantity = GREATEST(v_actual_stock, 0),
            updated_at = NOW()
        WHERE id = v_row.id;
        
        v_count := v_count + 1;
    END LOOP;

    RETURN jsonb_build_object('success', true, 'repaired_rows', v_count, 'message', 'Inventory levels recalculated from physical receipts.');
END;
$$;

-- End of 20260508000019_repair_rpc.sql


-- File: 20260508000020_purge_preorders.sql
-- ============================================================
-- Migration: Purge Pre-order Feature
-- ============================================================
-- Description: 
-- 1. Drops preorder-related columns from branch_inventory.
-- 2. Drops preorder-related columns from products.
-- 3. Removes preorder settings from tenants.
-- ============================================================

-- Drop views that depend on preorder columns FIRST to avoid dependency errors
DROP VIEW IF EXISTS marketplace_products_with_stock;
DROP VIEW IF EXISTS product_stock_summary;

DO $$
BEGIN
    -- 1. Remove from branch_inventory
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'branch_inventory' AND column_name = 'preorder_quantity') THEN
        ALTER TABLE branch_inventory DROP COLUMN preorder_quantity;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'branch_inventory' AND column_name = 'allow_preorder') THEN
        ALTER TABLE branch_inventory DROP COLUMN allow_preorder;
    END IF;

    -- 2. Remove from products
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'products' AND column_name = 'allow_preorder') THEN
        ALTER TABLE products DROP COLUMN allow_preorder;
    END IF;

    -- 3. Remove from tenants
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'tenants' AND column_name = 'preorders_enabled') THEN
        ALTER TABLE tenants DROP COLUMN preorders_enabled;
    END IF;
END $$;

-- Recreate v_branch_products view without any preorder columns
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



-- End of 20260508000020_purge_preorders.sql


-- File: 20260508000021_purge_preorder_from_checkout_functions.sql
-- ============================================================
-- Migration: Purge Pre-order Logic from Checkout & POS Functions
-- ============================================================
-- Description:
-- 1. Rewrites checkout_storefront_order to use physical stock only.
--    No more preorders_enabled / allow_preorder checks.
-- 2. Rewrites complete_sale_transaction (POS) identically.
-- 3. Fixes search_products_for_pos â€” no longer exposes allow_preorder.
-- 4. Drops the now-obsolete get_available_stock, reserve_inventory,
--    release_reservation, confirm_reservation helpers if they exist.
-- ============================================================

-- â”€â”€ 1. CHECKOUT (Storefront) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
CREATE OR REPLACE FUNCTION checkout_storefront_order(
    p_tenant_id UUID,
    p_branch_id UUID,
    p_customer_id UUID,
    p_order_type order_type,
    p_fulfillment_type fulfillment_type,
    p_subtotal DECIMAL,
    p_delivery_fee DECIMAL,
    p_tax_amount DECIMAL,
    p_total_amount DECIMAL,
    p_delivery_address_id UUID,
    p_special_instructions TEXT,
    p_items JSONB,
    p_service_charge DECIMAL DEFAULT 0,
    p_payment_reference TEXT DEFAULT NULL,
    p_billing_address TEXT DEFAULT NULL,
    p_shipping_address TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_order_id UUID;
    v_item RECORD;
    v_batch RECORD;
    v_req_qty INTEGER;
    v_allocated_qty INTEGER;
    v_allocations JSONB;
    v_primary_batch_id UUID;
BEGIN
    -- Validate totals
    IF p_total_amount != (p_subtotal + p_delivery_fee + p_tax_amount + p_service_charge) THEN
        RAISE EXCEPTION 'Total amount does not match subtotal + fees + tax + service charge';
    END IF;

    -- Create the order header
    INSERT INTO orders (
        tenant_id, branch_id, order_number, customer_id,
        order_type, order_status, payment_status, payment_method, payment_reference,
        subtotal, delivery_fee, tax_amount, service_charge, total_amount,
        fulfillment_type, delivery_address_id, special_instructions,
        billing_address, shipping_address
    ) VALUES (
        p_tenant_id,
        p_branch_id,
        'ORD-' || FLOOR(EXTRACT(EPOCH FROM NOW()))::TEXT || '-' || SUBSTRING(MD5(RANDOM()::TEXT) FROM 1 FOR 4),
        p_customer_id,
        p_order_type,
        'pending'::order_status,
        CASE WHEN p_payment_reference IS NOT NULL THEN 'paid'::payment_status ELSE 'unpaid'::payment_status END,
        'card'::payment_method,
        p_payment_reference,
        p_subtotal, p_delivery_fee, p_tax_amount, p_service_charge, p_total_amount,
        p_fulfillment_type,
        p_delivery_address_id,
        p_special_instructions,
        p_billing_address,
        p_shipping_address
    ) RETURNING id INTO v_order_id;

    -- Process each item
    FOR v_item IN SELECT * FROM jsonb_to_recordset(p_items) AS x(
        product_id UUID, product_name TEXT, quantity INTEGER, unit_price DECIMAL, subtotal DECIMAL
    )
    LOOP
        v_req_qty := v_item.quantity;
        v_allocations := '[]'::jsonb;
        v_primary_batch_id := NULL;

        -- Allocate from physical stock (FIFO by expiry then age)
        FOR v_batch IN 
            SELECT id, stock_quantity AS available_balance
            FROM branch_inventory
            WHERE branch_id = p_branch_id 
              AND product_id = v_item.product_id 
              AND is_active = true
              AND stock_quantity > 0
            ORDER BY expiry_date ASC NULLS LAST, created_at ASC
            FOR UPDATE
        LOOP
            IF v_req_qty <= 0 THEN EXIT; END IF;

            v_allocated_qty := LEAST(v_batch.available_balance, v_req_qty);

            IF v_primary_batch_id IS NULL THEN
                v_primary_batch_id := v_batch.id;
            END IF;

            v_allocations := v_allocations || jsonb_build_object(
                'batch_id', v_batch.id,
                'quantity', v_allocated_qty,
                'is_preorder', false
            );

            v_req_qty := v_req_qty - v_allocated_qty;
        END LOOP;

        -- Reject the order if stock is insufficient (no preorders)
        IF v_req_qty > 0 THEN
            RAISE EXCEPTION 'Insufficient stock for product: % (short by %)', v_item.product_name, v_req_qty;
        END IF;

        INSERT INTO public.sale_items (
            tenant_id, order_id, branch_id, inventory_id,
            product_id, product_name, quantity, unit_price, subtotal,
            discount_amount, batch_allocations
        ) VALUES (
            p_tenant_id, v_order_id, p_branch_id, v_primary_batch_id,
            v_item.product_id, v_item.product_name, v_item.quantity, v_item.unit_price, v_item.subtotal,
            0, v_allocations
        );
    END LOOP;

    RETURN v_order_id;
END;
$$;

-- â”€â”€ 2. COMPLETE SALE (POS) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
CREATE OR REPLACE FUNCTION complete_sale_transaction(
    p_tenant_id UUID,
    p_branch_id UUID,
    p_cashier_id UUID,
    p_customer_id UUID,
    p_cart_items JSONB,
    p_subtotal DECIMAL,
    p_tax_amount DECIMAL,
    p_discount_amount DECIMAL,
    p_total_amount DECIMAL,
    p_payment_method payment_method,
    p_payment_reference TEXT DEFAULT NULL
)
RETURNS TABLE (
    sale_id UUID,
    sale_number VARCHAR,
    success BOOLEAN,
    error_message TEXT
) AS $$
DECLARE
    v_sale_id UUID;
    v_sale_number VARCHAR;
    v_item JSONB;
    v_product_id UUID;
    v_quantity INTEGER;
    v_available_stock INTEGER;
    v_req_qty INTEGER;
    v_deducted INTEGER;
    v_batch RECORD;
BEGIN
    BEGIN
        -- Verify physical stock availability for every item
        FOR v_item IN SELECT * FROM jsonb_array_elements(p_cart_items)
        LOOP
            v_product_id := (v_item->>'product_id')::UUID;
            v_quantity := (v_item->>'quantity')::INTEGER;

            SELECT COALESCE(SUM(stock_quantity), 0)
            INTO v_available_stock
            FROM branch_inventory
            WHERE branch_id = p_branch_id AND product_id = v_product_id AND is_active = true;

            IF v_available_stock < v_quantity THEN
                RETURN QUERY SELECT
                    NULL::UUID, NULL::VARCHAR, FALSE,
                    'Insufficient stock for product: ' || (v_item->>'product_name');
                RETURN;
            END IF;
        END LOOP;

        -- Create sale record
        INSERT INTO sales (
            tenant_id, branch_id, cashier_id, customer_id,
            subtotal, tax_amount, discount_amount, total_amount,
            payment_method, payment_reference, status
        ) VALUES (
            p_tenant_id, p_branch_id, p_cashier_id, p_customer_id,
            p_subtotal, p_tax_amount, p_discount_amount, p_total_amount,
            p_payment_method, p_payment_reference, 'completed'
        )
        RETURNING id, sale_number INTO v_sale_id, v_sale_number;

        -- Insert sale items
        INSERT INTO sale_items (
            sale_id, tenant_id, product_id, product_name, quantity, unit_price, discount_amount, subtotal
        )
        SELECT
            v_sale_id, p_tenant_id, (item->>'product_id')::UUID, item->>'product_name',
            (item->>'quantity')::INTEGER, (item->>'unit_price')::DECIMAL,
            COALESCE((item->>'discount_amount')::DECIMAL, 0), (item->>'subtotal')::DECIMAL
        FROM jsonb_array_elements(p_cart_items) AS item;

        -- Deduct physical stock (FIFO)
        FOR v_item IN SELECT * FROM jsonb_array_elements(p_cart_items)
        LOOP
            v_product_id := (v_item->>'product_id')::UUID;
            v_req_qty := (v_item->>'quantity')::INTEGER;

            FOR v_batch IN 
                SELECT id, stock_quantity 
                FROM branch_inventory 
                WHERE branch_id = p_branch_id AND product_id = v_product_id 
                  AND is_active = true AND stock_quantity > 0
                ORDER BY expiry_date ASC NULLS LAST, created_at ASC
                FOR UPDATE
            LOOP
                IF v_req_qty <= 0 THEN EXIT; END IF;
                v_deducted := LEAST(v_batch.stock_quantity, v_req_qty);
                
                UPDATE branch_inventory 
                SET stock_quantity = stock_quantity - v_deducted, updated_at = NOW()
                WHERE id = v_batch.id;

                INSERT INTO inventory_transactions (
                    tenant_id, branch_id, product_id, branch_inventory_id,
                    transaction_type, quantity_delta, previous_quantity, new_quantity,
                    reference_id, reference_type, staff_id
                ) VALUES (
                    p_tenant_id, p_branch_id, v_product_id, v_batch.id,
                    'sale'::transaction_type, -v_deducted, v_batch.stock_quantity, v_batch.stock_quantity - v_deducted,
                    v_sale_id, 'sale', p_cashier_id
                );
                
                v_req_qty := v_req_qty - v_deducted;
            END LOOP;
        END LOOP;

        RETURN QUERY SELECT v_sale_id, v_sale_number, TRUE, NULL::TEXT;
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT NULL::UUID, NULL::VARCHAR, FALSE, SQLERRM;
    END;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- â”€â”€ 3. SEARCH PRODUCTS FOR POS (remove allow_preorder) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- Must DROP first because the OUT parameter list changed (removed reserved_quantity, allow_preorder)
DROP FUNCTION IF EXISTS search_products_for_pos(UUID, UUID, TEXT, INTEGER);
CREATE OR REPLACE FUNCTION search_products_for_pos(
    p_tenant_id UUID,
    p_branch_id UUID,
    p_search_term TEXT,
    p_limit INTEGER DEFAULT 20
)
RETURNS TABLE (
    product_id UUID,
    product_name VARCHAR,
    sku VARCHAR,
    barcode VARCHAR,
    category VARCHAR,
    unit_price DECIMAL,
    cost_price DECIMAL,
    image_url TEXT,
    stock_quantity INTEGER,
    available_quantity INTEGER,
    low_stock_threshold INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        bi.product_id,
        bi.product_name,
        bi.sku,
        bi.barcode,
        p.category,
        bi.selling_price AS unit_price,
        bi.cost_price,
        bi.image_url,
        COALESCE(SUM(bi.stock_quantity), 0)::INTEGER AS stock_quantity,
        COALESCE(SUM(bi.stock_quantity), 0)::INTEGER AS available_quantity,
        COALESCE(MAX(bi.low_stock_threshold), 10) AS low_stock_threshold
    FROM branch_inventory bi
    JOIN products p ON p.id = bi.product_id
    WHERE bi.tenant_id = p_tenant_id
        AND bi.branch_id = p_branch_id
        AND p.is_active = TRUE
        AND bi.is_active = TRUE
        AND bi.stock_quantity > 0
        AND (
            bi.product_name ILIKE '%' || p_search_term || '%'
            OR bi.sku ILIKE '%' || p_search_term || '%'
            OR bi.barcode = p_search_term
        )
    GROUP BY bi.product_id, bi.product_name, bi.sku, bi.barcode, p.category,
             bi.selling_price, bi.cost_price, bi.image_url
    ORDER BY bi.product_name
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- â”€â”€ 4. DROP LEGACY RESERVATION HELPERS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
DROP FUNCTION IF EXISTS get_available_stock(UUID, UUID);
DROP FUNCTION IF EXISTS reserve_inventory(UUID, UUID, INTEGER);
DROP FUNCTION IF EXISTS release_reservation(UUID, UUID, INTEGER);
DROP FUNCTION IF EXISTS confirm_reservation(UUID, UUID, INTEGER);

-- â”€â”€ 5. RESTORE CLEAN INVENTORY SYNC TRIGGER (no preorders) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- Overwrites the preorder-patched version from 20260506000002.
CREATE OR REPLACE FUNCTION trigger_sync_inventory_on_sale()
RETURNS TRIGGER AS $$
DECLARE
    v_item RECORD;
BEGIN
    IF NEW.sale_status = 'completed' THEN
        FOR v_item IN
            SELECT product_id, quantity
            FROM sale_items
            WHERE sale_id = NEW.id
        LOOP
            -- Deduct from branch inventory (FIFO by oldest batch)
            UPDATE branch_inventory
            SET stock_quantity = stock_quantity - v_item.quantity,
                updated_at = NOW()
            WHERE id = (
                SELECT id FROM branch_inventory
                WHERE branch_id = NEW.branch_id
                  AND product_id = v_item.product_id
                  AND stock_quantity >= v_item.quantity
                ORDER BY expiry_date ASC NULLS LAST, created_at ASC
                LIMIT 1
                FOR UPDATE
            );

            IF NOT FOUND THEN
                RAISE WARNING 'Insufficient stock for product % in sale %. Inventory not deducted.',
                    v_item.product_id, NEW.id;
            END IF;
        END LOOP;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


-- End of 20260508000021_purge_preorder_from_checkout_functions.sql


-- File: 20260509000001_reintroduce_preorders.sql
-- ============================================================
-- Migration: Reintroduce Pre-order Schema (Clean Architecture)
-- ============================================================
-- Pre-orders are now:
--   - Tenant-gated  : tenants.preorders_enabled
--   - Per-product   : branch_inventory.allow_preorder
--   - Limit-capped  : branch_inventory.preorder_limit (NULL = unlimited)
--   - Demand-tracked: branch_inventory.preorder_quantity
--   - Order-tagged  : orders.is_preorder_order, sale_items.is_preorder
--   - Staff-notified: staff_notifications table
-- ============================================================

-- â”€â”€ 1. branch_inventory columns â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'branch_inventory' AND column_name = 'allow_preorder') THEN
        ALTER TABLE branch_inventory ADD COLUMN allow_preorder BOOLEAN NOT NULL DEFAULT false;
        COMMENT ON COLUMN branch_inventory.allow_preorder
            IS 'When true, out-of-stock units can be pre-ordered by customers.';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'branch_inventory' AND column_name = 'preorder_quantity') THEN
        ALTER TABLE branch_inventory ADD COLUMN preorder_quantity INTEGER NOT NULL DEFAULT 0;
        COMMENT ON COLUMN branch_inventory.preorder_quantity
            IS 'Live demand counter â€” units currently committed to pre-orders.';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'branch_inventory' AND column_name = 'preorder_limit') THEN
        ALTER TABLE branch_inventory ADD COLUMN preorder_limit INTEGER DEFAULT NULL;
        COMMENT ON COLUMN branch_inventory.preorder_limit
            IS 'Max units that can be pre-ordered. NULL = unlimited.';
    END IF;
END $$;

-- â”€â”€ 2. tenants column â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'tenants' AND column_name = 'preorders_enabled') THEN
        ALTER TABLE tenants ADD COLUMN preorders_enabled BOOLEAN NOT NULL DEFAULT false;
        COMMENT ON COLUMN tenants.preorders_enabled
            IS 'Global on/off switch for the pre-order feature.';
    END IF;
END $$;

-- â”€â”€ 3. orders column â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'orders' AND column_name = 'is_preorder_order') THEN
        ALTER TABLE orders ADD COLUMN is_preorder_order BOOLEAN NOT NULL DEFAULT false;
        COMMENT ON COLUMN orders.is_preorder_order
            IS 'True when this order contains only pre-order items (split from a mixed cart).';
    END IF;
END $$;

-- â”€â”€ 4. sale_items column â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'sale_items' AND column_name = 'is_preorder') THEN
        ALTER TABLE sale_items ADD COLUMN is_preorder BOOLEAN NOT NULL DEFAULT false;
        COMMENT ON COLUMN sale_items.is_preorder
            IS 'True when this line item was placed as a pre-order (no physical stock deducted at order time).';
    END IF;
END $$;

-- â”€â”€ 5. staff_notifications table â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
CREATE TABLE IF NOT EXISTS public.staff_notifications (
    id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id   UUID        NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
    branch_id   UUID        REFERENCES public.branches(id) ON DELETE SET NULL,
    type        TEXT        NOT NULL,          -- e.g. 'preorder_fulfilled', 'low_stock'
    title       TEXT        NOT NULL,
    body        TEXT        NOT NULL,
    metadata    JSONB       NOT NULL DEFAULT '{}',
    is_read     BOOLEAN     NOT NULL DEFAULT false,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_staff_notifications_tenant_unread
    ON public.staff_notifications (tenant_id, is_read, created_at DESC);

ALTER TABLE public.staff_notifications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Staff can view own tenant notifications" ON public.staff_notifications;
CREATE POLICY "Staff can view own tenant notifications"
    ON public.staff_notifications FOR SELECT
    USING (
        tenant_id IN (
            SELECT tenant_id FROM public.users WHERE id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Staff can update own tenant notifications" ON public.staff_notifications;
CREATE POLICY "Staff can update own tenant notifications"
    ON public.staff_notifications FOR UPDATE
    USING (
        tenant_id IN (
            SELECT tenant_id FROM public.users WHERE id = auth.uid()
        )
    );

-- â”€â”€ 6. marketplace_products_with_stock view â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
DROP VIEW IF EXISTS public.marketplace_products_with_stock;
CREATE VIEW public.marketplace_products_with_stock AS
SELECT
    p.id                                                AS product_id,
    p.name                                              AS product_name,
    p.description,
    p.category,
    p.image_url,
    p.generic_name,
    p.strength,
    p.dosage_form,
    p.manufacturer,
    p.product_type,
    p.is_active,
    bi.tenant_id,
    bi.branch_id,
    bi.id                                               AS inventory_id,
    bi.stock_quantity,
    bi.selling_price,
    bi.low_stock_threshold,
    bi.expiry_date,
    bi.unit_of_measure,
    bi.allow_preorder,
    bi.preorder_quantity,
    bi.preorder_limit,
    (bi.stock_quantity > 0 OR bi.allow_preorder = true) AS is_available,
    CASE
        WHEN bi.stock_quantity <= bi.low_stock_threshold THEN true
        ELSE false
    END AS is_low_stock
FROM public.products p
JOIN public.branch_inventory bi ON bi.product_id = p.id
WHERE p._sync_is_deleted = false
  AND p.is_active = true
  AND bi._sync_is_deleted = false
  AND bi.is_active = true;

-- End of 20260509000001_reintroduce_preorders.sql


-- File: 20260509000002_preorder_rpcs.sql
-- ============================================================
-- Migration: Pre-order RPCs
-- ============================================================
-- 1. checkout_storefront_order  â€” adds p_is_preorder_order mode
-- 2. receive_purchase_order     â€” auto-fulfils pre-orders on receipt
--                                 + inserts staff_notifications
-- ============================================================

-- â”€â”€ 1. CHECKOUT (Storefront) â€” with pre-order support â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- Must DROP first because we are changing the parameter list
DROP FUNCTION IF EXISTS checkout_storefront_order(
    UUID, UUID, UUID, order_type, fulfillment_type,
    DECIMAL, DECIMAL, DECIMAL, DECIMAL,
    UUID, TEXT, JSONB, DECIMAL, TEXT, TEXT, TEXT
);

CREATE OR REPLACE FUNCTION checkout_storefront_order(
    p_tenant_id             UUID,
    p_branch_id             UUID,
    p_customer_id           UUID,
    p_order_type            order_type,
    p_fulfillment_type      fulfillment_type,
    p_subtotal              DECIMAL,
    p_delivery_fee          DECIMAL,
    p_tax_amount            DECIMAL,
    p_total_amount          DECIMAL,
    p_delivery_address_id   UUID,
    p_special_instructions  TEXT,
    p_items                 JSONB,
    p_service_charge        DECIMAL  DEFAULT 0,
    p_payment_reference     TEXT     DEFAULT NULL,
    p_billing_address       TEXT     DEFAULT NULL,
    p_shipping_address      TEXT     DEFAULT NULL,
    p_is_preorder_order     BOOLEAN  DEFAULT false   -- NEW: true = pre-order checkout
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_order_id          UUID;
    v_item              RECORD;
    v_batch             RECORD;
    v_req_qty           INTEGER;
    v_allocated_qty     INTEGER;
    v_allocations       JSONB;
    v_primary_batch_id  UUID;
    -- pre-order guards
    v_preorders_enabled BOOLEAN;
    v_allow_preorder    BOOLEAN;
    v_preorder_limit    INTEGER;
    v_current_preorder  INTEGER;
    v_bi_id             UUID;
    v_product_name      TEXT;
BEGIN
    -- â”€â”€ Validate totals â”€â”€
    IF p_total_amount != (p_subtotal + p_delivery_fee + p_tax_amount + p_service_charge) THEN
        RAISE EXCEPTION 'Total amount does not match subtotal + fees + tax + service charge';
    END IF;

    -- â”€â”€ Create order header â”€â”€
    INSERT INTO orders (
        tenant_id, branch_id, order_number, customer_id,
        order_type, order_status, payment_status, payment_method, payment_reference,
        subtotal, delivery_fee, tax_amount, service_charge, total_amount,
        fulfillment_type, delivery_address_id, special_instructions,
        billing_address, shipping_address, is_preorder_order
    ) VALUES (
        p_tenant_id,
        p_branch_id,
        'ORD-' || FLOOR(EXTRACT(EPOCH FROM NOW()))::TEXT || '-' || SUBSTRING(MD5(RANDOM()::TEXT) FROM 1 FOR 4),
        p_customer_id,
        p_order_type,
        'pending'::order_status,
        CASE WHEN p_payment_reference IS NOT NULL THEN 'paid'::payment_status ELSE 'unpaid'::payment_status END,
        'card'::payment_method,
        p_payment_reference,
        p_subtotal, p_delivery_fee, p_tax_amount, p_service_charge, p_total_amount,
        p_fulfillment_type,
        p_delivery_address_id,
        p_special_instructions,
        p_billing_address,
        p_shipping_address,
        p_is_preorder_order
    ) RETURNING id INTO v_order_id;

    -- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
    -- BRANCH A: Physical stock checkout (normal order)
    -- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
    IF NOT p_is_preorder_order THEN

        FOR v_item IN SELECT * FROM jsonb_to_recordset(p_items) AS x(
            product_id UUID, product_name TEXT, quantity INTEGER,
            unit_price DECIMAL, subtotal DECIMAL
        )
        LOOP
            v_req_qty          := v_item.quantity;
            v_allocations      := '[]'::jsonb;
            v_primary_batch_id := NULL;

            -- FIFO allocation by expiry then insertion date
            FOR v_batch IN
                SELECT id, stock_quantity AS available_balance
                FROM branch_inventory
                WHERE branch_id = p_branch_id
                  AND product_id = v_item.product_id
                  AND is_active = true
                  AND stock_quantity > 0
                ORDER BY expiry_date ASC NULLS LAST, created_at ASC
                FOR UPDATE
            LOOP
                IF v_req_qty <= 0 THEN EXIT; END IF;

                v_allocated_qty := LEAST(v_batch.available_balance, v_req_qty);

                IF v_primary_batch_id IS NULL THEN
                    v_primary_batch_id := v_batch.id;
                END IF;

                UPDATE branch_inventory
                   SET stock_quantity = stock_quantity - v_allocated_qty
                 WHERE id = v_batch.id;

                v_allocations := v_allocations || jsonb_build_object(
                    'batch_id',    v_batch.id,
                    'quantity',    v_allocated_qty,
                    'is_preorder', false
                );

                v_req_qty := v_req_qty - v_allocated_qty;
            END LOOP;

            IF v_req_qty > 0 THEN
                RAISE EXCEPTION 'Insufficient stock for product: % (short by %)',
                      v_item.product_name, v_req_qty;
            END IF;

            INSERT INTO public.sale_items (
                tenant_id, order_id, branch_id, inventory_id,
                product_id, product_name, quantity, unit_price, subtotal,
                discount_amount, batch_allocations, is_preorder
            ) VALUES (
                p_tenant_id, v_order_id, p_branch_id, v_primary_batch_id,
                v_item.product_id, v_item.product_name,
                v_item.quantity, v_item.unit_price, v_item.subtotal,
                0, v_allocations, false
            );
        END LOOP;

    -- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
    -- BRANCH B: Pre-order checkout
    -- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
    ELSE

        -- Load tenant global switch once
        SELECT preorders_enabled INTO v_preorders_enabled
          FROM tenants WHERE id = p_tenant_id;

        IF NOT COALESCE(v_preorders_enabled, false) THEN
            RAISE EXCEPTION 'Pre-orders are not enabled for this store.';
        END IF;

        FOR v_item IN SELECT * FROM jsonb_to_recordset(p_items) AS x(
            product_id UUID, product_name TEXT, quantity INTEGER,
            unit_price DECIMAL, subtotal DECIMAL
        )
        LOOP
            -- Get the inventory row for this product in this branch
            SELECT id, allow_preorder, preorder_quantity, preorder_limit
              INTO v_bi_id, v_allow_preorder, v_current_preorder, v_preorder_limit
              FROM branch_inventory
             WHERE branch_id = p_branch_id AND product_id = v_item.product_id
               AND is_active = true
             LIMIT 1;

            IF v_bi_id IS NULL THEN
                RAISE EXCEPTION 'Product % is not listed in this branch.',
                      v_item.product_name;
            END IF;

            IF NOT COALESCE(v_allow_preorder, false) THEN
                RAISE EXCEPTION 'Pre-order is not enabled for product: %',
                      v_item.product_name;
            END IF;

            -- Enforce preorder_limit if set
            IF v_preorder_limit IS NOT NULL THEN
                IF (v_current_preorder + v_item.quantity) > v_preorder_limit THEN
                    RAISE EXCEPTION
                        'Pre-order limit reached for %: only % more unit(s) can be pre-ordered.',
                        v_item.product_name,
                        GREATEST(v_preorder_limit - v_current_preorder, 0);
                END IF;
            END IF;

            -- Increment demand counter
            UPDATE branch_inventory
               SET preorder_quantity = preorder_quantity + v_item.quantity
             WHERE id = v_bi_id;

            INSERT INTO public.sale_items (
                tenant_id, order_id, branch_id, inventory_id,
                product_id, product_name, quantity, unit_price, subtotal,
                discount_amount, batch_allocations, is_preorder
            ) VALUES (
                p_tenant_id, v_order_id, p_branch_id, v_bi_id,
                v_item.product_id, v_item.product_name,
                v_item.quantity, v_item.unit_price, v_item.subtotal,
                0, '[]'::jsonb, true
            );
        END LOOP;

    END IF;

    RETURN v_order_id;
END;
$$;


-- â”€â”€ 2. RECEIVE PURCHASE ORDER â€” with pre-order auto-fulfilment â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
CREATE OR REPLACE FUNCTION public.receive_purchase_order(
    p_po_id         UUID,
    p_received_items JSONB,
    p_notes         TEXT    DEFAULT NULL,
    p_branch_id     UUID    DEFAULT NULL
)
RETURNS purchase_orders
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_po            purchase_orders;
    v_target_branch_id UUID;
    v_received_item RECORD;
    v_po_item       RECORD;
    v_batch_id      UUID;
    v_staff_id      UUID;
    v_receipt_id    UUID;
    v_old_qty       INTEGER;
    -- pre-order fulfilment
    v_preorder_qty  INTEGER;
    v_to_fulfill    INTEGER;
    v_product_name  TEXT;
BEGIN
    v_staff_id := auth.uid();

    SELECT * INTO v_po FROM purchase_orders WHERE id = p_po_id FOR UPDATE;
    IF v_po.id IS NULL THEN
        RAISE EXCEPTION 'Purchase Order not found';
    END IF;

    v_target_branch_id := COALESCE(p_branch_id, v_po.branch_id);

    INSERT INTO purchase_order_receipts (tenant_id, po_id, staff_id, notes, branch_id)
    VALUES (v_po.tenant_id, v_po.id, v_staff_id, p_notes, v_target_branch_id)
    RETURNING id INTO v_receipt_id;

    FOR v_received_item IN SELECT * FROM jsonb_to_recordset(p_received_items) AS x(
        product_id UUID, received_qty INTEGER, batch_no TEXT, expiry_date DATE,
        unit_cost DECIMAL, unit_price DECIMAL, is_received BOOLEAN, unit_of_measure TEXT
    )
    LOOP
        IF COALESCE(v_received_item.received_qty, 0) = 0 THEN CONTINUE; END IF;

        v_batch_id := NULL;
        v_old_qty  := 0;

        -- Fetch product meta from PO items
        SELECT COALESCE(poi.product_name, p.name)       AS product_name,
               COALESCE(poi.strength,     p.strength)   AS strength,
               p.barcode                                AS sku,
               p.product_type,
               p.image_url
          INTO v_po_item
          FROM products p
          LEFT JOIN purchase_order_items poi
            ON poi.product_id = p.id AND poi.po_id = p_po_id
         WHERE p.id = v_received_item.product_id;

        v_product_name := v_po_item.product_name;

        -- Record the receipt line
        INSERT INTO purchase_order_receipt_items (
            receipt_id, product_id, quantity, unit_cost, batch_no,
            expiry_date, is_received
        ) VALUES (
            v_receipt_id, v_received_item.product_id,
            v_received_item.received_qty, v_received_item.unit_cost,
            v_received_item.batch_no, v_received_item.expiry_date,
            COALESCE(v_received_item.is_received, TRUE)
        );

        -- â”€â”€ Upsert inventory batch â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        SELECT id, stock_quantity INTO v_batch_id, v_old_qty
          FROM branch_inventory
         WHERE branch_id = v_target_branch_id
           AND product_id = v_received_item.product_id
           AND COALESCE(batch_no, '') = COALESCE(v_received_item.batch_no, '')
         LIMIT 1;

        IF v_batch_id IS NOT NULL THEN
            UPDATE branch_inventory
               SET stock_quantity = stock_quantity + v_received_item.received_qty,
                   expiry_date    = COALESCE(v_received_item.expiry_date, expiry_date),
                   cost_price     = COALESCE(v_received_item.unit_cost,   cost_price),
                   updated_at     = NOW()
             WHERE id = v_batch_id;
        ELSE
            INSERT INTO branch_inventory (
                tenant_id, branch_id, product_id, stock_quantity, batch_no,
                expiry_date, cost_price, selling_price, purchase_invoice,
                added_by, is_active, product_name, strength, sku,
                product_type, image_url, unit_of_measure
            ) VALUES (
                v_po.tenant_id, v_target_branch_id, v_received_item.product_id,
                v_received_item.received_qty,
                v_received_item.batch_no, v_received_item.expiry_date,
                v_received_item.unit_cost,
                COALESCE(v_received_item.unit_price, v_received_item.unit_cost * 1.3),
                v_po.po_number, v_staff_id::text, TRUE,
                v_po_item.product_name, v_po_item.strength, v_po_item.sku,
                v_po_item.product_type, v_po_item.image_url,
                COALESCE(v_received_item.unit_of_measure, 'unit')
            ) RETURNING id INTO v_batch_id;
        END IF;

        -- â”€â”€ Log inventory transaction â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        INSERT INTO inventory_transactions (
            tenant_id, branch_id, product_id, branch_inventory_id,
            transaction_type, quantity_delta, previous_quantity, new_quantity,
            unit_cost, reference_id, reference_type, staff_id
        ) VALUES (
            v_po.tenant_id, v_target_branch_id, v_received_item.product_id, v_batch_id,
            'restock'::transaction_type, v_received_item.received_qty,
            COALESCE(v_old_qty, 0),
            COALESCE(v_old_qty, 0) + v_received_item.received_qty,
            v_received_item.unit_cost, v_po.id, 'purchase_order', v_staff_id
        );

        -- â”€â”€ Auto-fulfil outstanding pre-orders â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        -- Sum ALL pre-order demand for this product in this branch
        SELECT COALESCE(SUM(preorder_quantity), 0) INTO v_preorder_qty
          FROM branch_inventory
         WHERE branch_id = v_target_branch_id
           AND product_id = v_received_item.product_id;

        IF v_preorder_qty > 0 THEN
            v_to_fulfill := LEAST(v_preorder_qty, v_received_item.received_qty);

            -- Decrement demand counter proportionally across rows for this product
            UPDATE branch_inventory
               SET preorder_quantity = GREATEST(
                       preorder_quantity - LEAST(preorder_quantity, v_to_fulfill),
                       0
                   )
             WHERE branch_id = v_target_branch_id
               AND product_id = v_received_item.product_id
               AND preorder_quantity > 0;

            -- Notify staff
            INSERT INTO staff_notifications (
                tenant_id, branch_id, type, title, body, metadata
            ) VALUES (
                v_po.tenant_id,
                v_target_branch_id,
                'preorder_fulfilled',
                'Pre-orders Ready for Collection',
                format(
                    '%s unit(s) of "%s" are now in stock and satisfy outstanding pre-orders. Please contact the customers.',
                    v_to_fulfill,
                    v_product_name
                ),
                jsonb_build_object(
                    'product_id',              v_received_item.product_id,
                    'product_name',            v_product_name,
                    'fulfilled_qty',           v_to_fulfill,
                    'remaining_preorder_qty',  v_preorder_qty - v_to_fulfill,
                    'po_id',                   v_po.id
                )
            );
        END IF;

    END LOOP;

    -- Update PO timestamp
    UPDATE purchase_orders SET updated_at = NOW() WHERE id = p_po_id;
    SELECT * INTO v_po FROM purchase_orders WHERE id = p_po_id;
    RETURN v_po;
END;
$$;

-- End of 20260509000002_preorder_rpcs.sql


-- File: 20260509000003_update_ecommerce_products_view.sql
-- ============================================================
-- Migration: Update ecommerce_products view for Pre-orders
-- ============================================================
-- Description: Adds allow_preorder, preorder_quantity, and 
--              preorder_limit to the branch-level storefront view.
--              Updated to use direct flags from branch_inventory.
-- ============================================================

DROP VIEW IF EXISTS ecommerce_products CASCADE;

CREATE OR REPLACE VIEW ecommerce_products AS
SELECT
    -- Unique ID for the view (Product + Branch)
    (p.id::text || '-' || bi.branch_id::text) as id,
    p.id as product_id,
    bi.tenant_id,
    bi.branch_id,
    b.name as branch_name,
    b.address as branch_address,
    p.name,
    p.description,
    p.category,
    
    -- Pricing from THIS specific branch
    MIN(bi.selling_price) as selling_price,
    MIN(bi.sale_price) as sale_price,
    
    p.image_url,
    p.is_active,

    -- Total stock in THIS specific branch
    COALESCE(SUM(bi.stock_quantity), 0) as total_stock,

    -- Pre-order fields aggregated across batches
    bool_or(bi.allow_preorder) as allow_preorder,
    COALESCE(SUM(bi.preorder_quantity), 0) as preorder_quantity,
    MAX(bi.preorder_limit) as preorder_limit,

    -- Promotional Flags (Direct from branch_inventory)
    bool_or(bi.is_on_sale) as is_on_sale,
    bool_or(bi.is_featured) as is_featured,
    bool_or(bi.is_new_arrival) as is_new_arrival,
    p."isPOM" as is_pom,

    p.created_at,
    p.updated_at,
    
    -- Catalog metadata
    p.unit_of_measure,
    p.product_type,
    p.generic_name,
    p.strength,
    p.dosage_form,
    p.manufacturer
FROM products p
JOIN branch_inventory bi ON bi.product_id = p.id AND bi.is_active = true
JOIN branches b ON bi.branch_id = b.id AND b.deleted_at IS NULL
WHERE p._sync_is_deleted = false
  AND p.is_active = TRUE
GROUP BY
    p.id,
    bi.tenant_id,
    bi.branch_id,
    b.name,
    b.address,
    p.name,
    p.description,
    p.category,
    p.image_url,
    p.is_active,
    p.created_at,
    p.updated_at,
    p."isPOM",
    p.unit_of_measure,
    p.product_type,
    p.generic_name,
    p.strength,
    p.dosage_form,
    p.manufacturer;

-- End of 20260509000003_update_ecommerce_products_view.sql


-- File: check_cols.sql
DO $$
DECLARE
    col_exists BOOLEAN;
BEGIN
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'branch_inventory' AND column_name = 'image_url'
    ) INTO col_exists;
    
    IF NOT col_exists THEN
        RAISE NOTICE 'image_url does not exist in branch_inventory';
    ELSE
        RAISE NOTICE 'image_url exists in branch_inventory';
    END IF;
END $$;

-- End of check_cols.sql

