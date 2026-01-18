-- ============================================================
-- Kemani POS Platform - Supabase Database Schema
-- ============================================================
-- Version: 1.0.0
-- Created: 2026-01-17
-- Description: Complete schema for multi-tenant POS platform with
--              offline-first sync, branch management, and RLS policies

-- ============================================================
-- EXTENSIONS
-- ============================================================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";         -- UUID generation
CREATE EXTENSION IF NOT EXISTS "pg_trgm";           -- Full-text search
CREATE EXTENSION IF NOT EXISTS "postgis";           -- Geospatial queries
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements"; -- Performance monitoring

-- ============================================================
-- ENUMS
-- ============================================================
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
CREATE TYPE plan_tier AS ENUM ('free', 'basic', 'pro', 'enterprise');
CREATE TYPE subscription_status AS ENUM ('active', 'suspended', 'cancelled');
CREATE TYPE settlement_status AS ENUM ('pending', 'invoiced', 'paid');
CREATE TYPE message_direction AS ENUM ('outbound', 'inbound');
CREATE TYPE message_type AS ENUM ('text', 'template', 'media');
CREATE TYPE whatsapp_delivery_status AS ENUM ('pending', 'sent', 'delivered', 'read', 'failed');
CREATE TYPE receipt_format AS ENUM ('pdf', 'thermal_print', 'email');

-- ============================================================
-- TABLES
-- ============================================================

-- ------------------------------------------------------------
-- Subscriptions (created first as referenced by tenants)
-- ------------------------------------------------------------
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

-- ------------------------------------------------------------
-- Tenants
-- ------------------------------------------------------------
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

-- Update subscription to link tenant
ALTER TABLE subscriptions ADD COLUMN tenant_id UUID UNIQUE REFERENCES tenants(id);

-- ------------------------------------------------------------
-- Branches
-- ------------------------------------------------------------
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

-- ------------------------------------------------------------
-- Users (linked to auth.users)
-- ------------------------------------------------------------
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

-- ------------------------------------------------------------
-- Products
-- ------------------------------------------------------------
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

    -- Sync metadata for offline-first
    _sync_version BIGINT DEFAULT 1,
    _sync_modified_at TIMESTAMPTZ DEFAULT NOW(),
    _sync_client_id UUID,
    _sync_is_deleted BOOLEAN DEFAULT FALSE
);

-- ------------------------------------------------------------
-- Inventory Transactions
-- ------------------------------------------------------------
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

-- ------------------------------------------------------------
-- Inter-Branch Transfers
-- ------------------------------------------------------------
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

-- ------------------------------------------------------------
-- Customers
-- ------------------------------------------------------------
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

    -- Sync metadata
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

-- ------------------------------------------------------------
-- Sales
-- ------------------------------------------------------------
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

    -- Sync metadata
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

-- ------------------------------------------------------------
-- Orders
-- ------------------------------------------------------------
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

    -- Sync metadata
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

-- ------------------------------------------------------------
-- Riders
-- ------------------------------------------------------------
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

-- ------------------------------------------------------------
-- Deliveries
-- ------------------------------------------------------------
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

    -- Sync metadata
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

-- ------------------------------------------------------------
-- Staff Attendance
-- ------------------------------------------------------------
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

-- ------------------------------------------------------------
-- E-Commerce Connections
-- ------------------------------------------------------------
CREATE TABLE ecommerce_connections (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    platform_type platform_type NOT NULL,
    platform_name VARCHAR(100),
    store_url TEXT NOT NULL,
    api_key TEXT NOT NULL, -- Encrypt using Supabase Vault
    api_secret TEXT,        -- Encrypt using Supabase Vault
    sync_enabled BOOLEAN DEFAULT TRUE,
    sync_interval_minutes INTEGER DEFAULT 15 CHECK (sync_interval_minutes > 0),
    last_sync_at TIMESTAMPTZ,
    sync_status sync_status DEFAULT 'pending',
    sync_error TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ------------------------------------------------------------
-- Chat Conversations
-- ------------------------------------------------------------
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

-- ------------------------------------------------------------
-- Commissions
-- ------------------------------------------------------------
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

-- ------------------------------------------------------------
-- WhatsApp Messages
-- ------------------------------------------------------------
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

-- ------------------------------------------------------------
-- Receipts
-- ------------------------------------------------------------
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

-- ============================================================
-- INDEXES
-- ============================================================

-- Tenants
CREATE INDEX idx_tenants_slug ON tenants(slug);
CREATE INDEX idx_tenants_email ON tenants(email) WHERE email IS NOT NULL;
CREATE INDEX idx_tenants_deleted ON tenants(deleted_at) WHERE deleted_at IS NULL;

-- Branches
CREATE INDEX idx_branches_tenant ON branches(tenant_id, deleted_at) WHERE deleted_at IS NULL;
CREATE INDEX idx_branches_location ON branches USING GIST(ST_MakePoint(longitude, latitude)::geography)
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

-- ============================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================================

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

-- ============================================================
-- TRIGGERS
-- ============================================================

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
        -- 1 point per ₦100 spent (from clarifications)
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

-- ============================================================
-- SEED DATA
-- ============================================================

-- Insert default subscription plans
INSERT INTO subscriptions (plan_tier, monthly_fee, commission_rate, max_branches, max_staff_users, max_products, monthly_transaction_quota, features, billing_cycle_start, billing_cycle_end) VALUES
    ('free', 0, 5.0, 1, 3, 100, 500, '{"ai_chat": false, "analytics_basic": true, "whatsapp": false}'::jsonb, NOW(), NOW() + INTERVAL '1 month'),
    ('basic', 5000, 2.5, 3, 10, 1000, 2000, '{"ai_chat": false, "analytics_advanced": true, "whatsapp": true, "ecommerce_sync": true}'::jsonb, NOW(), NOW() + INTERVAL '1 month'),
    ('pro', 15000, 1.5, 10, 50, 10000, 10000, '{"ai_chat": true, "analytics_advanced": true, "whatsapp": true, "ecommerce_sync": true, "multi_branch": true}'::jsonb, NOW(), NOW() + INTERVAL '1 month'),
    ('enterprise', 50000, 1.0, 999, 999, 999999, 999999, '{"ai_chat": true, "analytics_advanced": true, "whatsapp": true, "ecommerce_sync": true, "multi_branch": true, "dedicated_support": true}'::jsonb, NOW(), NOW() + INTERVAL '1 month');

-- ============================================================
-- NOTES
-- ============================================================
-- 1. Encrypt sensitive fields (api_key, api_secret) using Supabase Vault
-- 2. Configure PowerSync sync rules to filter by tenant_id and branch_id
-- 3. Set up Supabase Realtime for order/delivery status updates
-- 4. Configure storage buckets for product images, receipts, delivery proofs
-- 5. Add database backups (point-in-time recovery enabled)
-- 6. Monitor RLS policy performance with pg_stat_statements
-- 7. Consider partitioning large tables (sales, inventory_transactions) by date
