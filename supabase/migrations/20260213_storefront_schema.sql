-- ============================================================================
-- Migration: Ecommerce Storefront Schema
-- Feature: 002-ecommerce-storefront
-- Date: 2026-02-13
-- ============================================================================
-- Creates 12 tables for the customer-facing ecommerce storefront:
-- - storefront_customers (online customer profiles)
-- - storefront_products (denormalized products from POS)
-- - product_variants (size/color variations)
-- - shopping_carts (per-branch carts)
-- - cart_items (cart line items)
-- - storefront_orders (customer orders)
-- - storefront_order_items (order line items)
-- - payment_transactions (Paystack audit trail)
-- - chat_sessions (live/AI chat)
-- - chat_messages (message history)
-- - chat_attachments (file uploads)
-- - tenant_branding (PWA icons and theme)
-- ============================================================================
-- NOTE: Uses "storefront_" prefix to avoid conflicts with existing POS tables
-- ============================================================================

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- TABLES
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 0. global_product_catalog (NEW: Platform-wide product catalog)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS global_product_catalog (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

  -- Business Type Classification
  business_type TEXT NOT NULL, -- 'pharmacy', 'grocery', 'fashion', 'restaurant', 'electronics', etc.

  -- Product Information (standardized)
  name TEXT NOT NULL,
  description TEXT,
  category TEXT NOT NULL, -- Sub-category within business type
  brand TEXT,

  -- Identifiers
  barcode TEXT, -- UPC/EAN barcode
  sku_prefix TEXT, -- Standard SKU prefix

  -- Media (stored once, shared by all tenants)
  images TEXT[], -- Array of image URLs (Supabase Storage)
  primary_image TEXT,

  -- Specifications (JSONB for flexibility)
  specifications JSONB, -- { "dosage": "500mg", "volume": "1L", "size": "XL" }

  -- SEO
  slug TEXT NOT NULL UNIQUE, -- URL-friendly name
  meta_title TEXT,
  meta_description TEXT,

  -- Curation
  is_verified BOOLEAN DEFAULT FALSE, -- Platform-verified product
  is_active BOOLEAN DEFAULT TRUE,

  -- Metadata
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id), -- Admin who added this

  -- Constraints
  CONSTRAINT valid_business_type CHECK (business_type IN (
    'pharmacy', 'grocery', 'fashion', 'restaurant', 'electronics',
    'beauty', 'hardware', 'bookstore', 'general'
  ))
);

-- Ensure critical columns exist
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                 WHERE table_name = 'global_product_catalog'
                 AND column_name = 'business_type') THEN
    ALTER TABLE global_product_catalog ADD COLUMN business_type TEXT NOT NULL DEFAULT 'general';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                 WHERE table_name = 'global_product_catalog'
                 AND column_name = 'is_active') THEN
    ALTER TABLE global_product_catalog ADD COLUMN is_active BOOLEAN DEFAULT TRUE;
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_global_catalog_business_type ON global_product_catalog(business_type);
CREATE INDEX IF NOT EXISTS idx_global_catalog_category ON global_product_catalog(category);
CREATE INDEX IF NOT EXISTS idx_global_catalog_barcode ON global_product_catalog(barcode);
CREATE INDEX IF NOT EXISTS idx_global_catalog_active ON global_product_catalog(is_active) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_global_catalog_verified ON global_product_catalog(is_verified) WHERE is_verified = TRUE;

-- Full-text search on global catalog
CREATE INDEX IF NOT EXISTS idx_global_catalog_search ON global_product_catalog
  USING gin(to_tsvector('english', name || ' ' || COALESCE(description, '') || ' ' || COALESCE(brand, '')));

COMMENT ON TABLE global_product_catalog IS 'Platform-wide product catalog shared across all tenants. Products defined once, referenced by tenant inventory.';

-- ----------------------------------------------------------------------------
-- Add business_type to tenants table (if not exists)
-- ----------------------------------------------------------------------------
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                 WHERE table_name = 'tenants'
                 AND column_name = 'business_type') THEN
    ALTER TABLE tenants ADD COLUMN business_type TEXT DEFAULT 'general';

    -- Add constraint to match global catalog business types
    ALTER TABLE tenants ADD CONSTRAINT valid_business_type CHECK (business_type IN (
      'pharmacy', 'grocery', 'fashion', 'restaurant', 'electronics',
      'beauty', 'hardware', 'bookstore', 'general'
    ));

    CREATE INDEX idx_tenants_business_type ON tenants(business_type);
  END IF;
END $$;

COMMENT ON COLUMN tenants.business_type IS 'Business type determines which products from global catalog are shown to this tenant';

-- ----------------------------------------------------------------------------
-- 1. storefront_customers (renamed from customers)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS storefront_customers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

  -- Authentication
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE, -- NULL for guest customers
  email TEXT,
  phone TEXT NOT NULL, -- Primary identifier for guests

  -- Profile
  name TEXT NOT NULL,

  -- Delivery Information
  delivery_address JSONB, -- { street, city, state, postal_code, landmark }
  delivery_coordinates POINT, -- Lat/lng for delivery fee calculation

  -- Metadata
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  last_order_at TIMESTAMPTZ,
  total_orders INTEGER DEFAULT 0,

  -- Constraints
  CONSTRAINT phone_format CHECK (phone ~ '^\+?[0-9]{10,15}$'),
  CONSTRAINT email_format CHECK (email ~ '^[^@]+@[^@]+\.[^@]+$' OR email IS NULL)
);

CREATE INDEX IF NOT EXISTS idx_storefront_customers_user_id ON storefront_customers(user_id);
CREATE INDEX IF NOT EXISTS idx_storefront_customers_phone ON storefront_customers(phone);
CREATE INDEX IF NOT EXISTS idx_storefront_customers_email ON storefront_customers(email);

COMMENT ON TABLE storefront_customers IS 'Customer profiles for online storefront (authenticated and guest)';

-- ----------------------------------------------------------------------------
-- 2. storefront_products (Tenant Inventory - references global catalog)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS storefront_products (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

  -- Reference to Global Catalog
  catalog_product_id UUID REFERENCES global_product_catalog(id) ON DELETE RESTRICT,

  -- Tenant/Branch Assignment
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE CASCADE,

  -- POS System Reference (for legacy compatibility)
  product_id UUID, -- Reference to POS products table (optional)

  -- Tenant-specific SKU
  sku TEXT NOT NULL, -- Tenant's custom SKU

  -- Pricing (tenant-controlled)
  price DECIMAL(10, 2) NOT NULL,
  compare_at_price DECIMAL(10, 2), -- Original price for discounts
  cost_price DECIMAL(10, 2), -- For profit calculations

  -- Inventory (branch-controlled)
  stock_quantity INTEGER NOT NULL DEFAULT 0,
  low_stock_threshold INTEGER DEFAULT 10,
  is_available BOOLEAN NOT NULL DEFAULT TRUE, -- Branch can disable products

  -- Tenant Overrides (optional - overrides global catalog data)
  custom_name TEXT, -- If tenant wants different name
  custom_description TEXT, -- If tenant wants different description
  custom_images TEXT[], -- If tenant wants different images

  -- Variants (if applicable)
  has_variants BOOLEAN DEFAULT FALSE,

  -- Metadata
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  synced_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), -- Last sync from POS

  -- Constraints
  CONSTRAINT price_positive CHECK (price >= 0),
  CONSTRAINT stock_non_negative CHECK (stock_quantity >= 0),
  CONSTRAINT unique_catalog_branch UNIQUE (catalog_product_id, branch_id),
  CONSTRAINT unique_sku_tenant UNIQUE (sku, tenant_id)
);

-- Ensure critical columns exist
DO $$
DECLARE
  v_table_exists BOOLEAN;
BEGIN
  -- Check if table exists
  SELECT EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_name = 'storefront_products'
  ) INTO v_table_exists;

  -- Only try to add columns if table exists
  IF v_table_exists THEN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'storefront_products'
                   AND column_name = 'catalog_product_id') THEN
      ALTER TABLE storefront_products ADD COLUMN catalog_product_id UUID;
      ALTER TABLE storefront_products ADD CONSTRAINT fk_storefront_products_catalog
        FOREIGN KEY (catalog_product_id) REFERENCES global_product_catalog(id) ON DELETE RESTRICT;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'storefront_products'
                   AND column_name = 'is_available') THEN
      ALTER TABLE storefront_products ADD COLUMN is_available BOOLEAN NOT NULL DEFAULT TRUE;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'storefront_products'
                   AND column_name = 'sku') THEN
      ALTER TABLE storefront_products ADD COLUMN sku TEXT NOT NULL DEFAULT gen_random_uuid()::text;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'storefront_products'
                   AND column_name = 'price') THEN
      ALTER TABLE storefront_products ADD COLUMN price DECIMAL(10, 2) NOT NULL DEFAULT 0;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'storefront_products'
                   AND column_name = 'stock_quantity') THEN
      ALTER TABLE storefront_products ADD COLUMN stock_quantity INTEGER NOT NULL DEFAULT 0;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'storefront_products'
                   AND column_name = 'product_id') THEN
      ALTER TABLE storefront_products ADD COLUMN product_id UUID;
      -- Note: No foreign key constraint added here since POS products table might vary
    END IF;
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_storefront_products_catalog ON storefront_products(catalog_product_id);
CREATE INDEX IF NOT EXISTS idx_storefront_products_branch ON storefront_products(branch_id);
CREATE INDEX IF NOT EXISTS idx_storefront_products_tenant ON storefront_products(tenant_id);
CREATE INDEX IF NOT EXISTS idx_storefront_products_sku ON storefront_products(sku, tenant_id);
CREATE INDEX IF NOT EXISTS idx_storefront_products_available ON storefront_products(is_available) WHERE is_available = TRUE;

COMMENT ON TABLE storefront_products IS 'Tenant inventory - references global product catalog with branch-specific stock and pricing';

-- ----------------------------------------------------------------------------
-- 3. product_variants
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS product_variants (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

  -- Product Reference
  product_id UUID NOT NULL REFERENCES storefront_products(id) ON DELETE CASCADE,

  -- Variant Details
  variant_name TEXT NOT NULL, -- e.g., "Large / Red"
  options JSONB NOT NULL, -- { "size": "Large", "color": "Red" }
  sku TEXT NOT NULL UNIQUE,

  -- Pricing (can differ from base product)
  price_adjustment DECIMAL(10, 2) DEFAULT 0, -- Added to base price

  -- Inventory
  stock_quantity INTEGER NOT NULL DEFAULT 0,
  is_available BOOLEAN NOT NULL DEFAULT TRUE,

  -- Media
  image_url TEXT, -- Variant-specific image

  -- Metadata
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  -- Constraints
  CONSTRAINT stock_non_negative CHECK (stock_quantity >= 0)
);

-- Add missing columns if table exists from previous failed run
DO $$
DECLARE
  v_table_exists BOOLEAN;
BEGIN
  -- Check if table exists
  SELECT EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_name = 'product_variants'
  ) INTO v_table_exists;

  -- Only try to add columns if table exists
  IF v_table_exists THEN
    -- Add product_id if it doesn't exist (nullable first to handle existing rows)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'product_variants'
                   AND column_name = 'product_id') THEN
      -- Add as nullable first
      ALTER TABLE product_variants ADD COLUMN product_id UUID;
      -- Add foreign key constraint separately
      ALTER TABLE product_variants ADD CONSTRAINT fk_product_variants_product
        FOREIGN KEY (product_id) REFERENCES storefront_products(id) ON DELETE CASCADE;
    END IF;

    -- Add is_available if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'product_variants'
                   AND column_name = 'is_available') THEN
      ALTER TABLE product_variants ADD COLUMN is_available BOOLEAN NOT NULL DEFAULT TRUE;
    END IF;

    -- Add other potentially missing columns
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'product_variants'
                   AND column_name = 'variant_name') THEN
      ALTER TABLE product_variants ADD COLUMN variant_name TEXT DEFAULT 'Default';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'product_variants'
                   AND column_name = 'options') THEN
      ALTER TABLE product_variants ADD COLUMN options JSONB DEFAULT '{}'::jsonb;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'product_variants'
                   AND column_name = 'sku') THEN
      ALTER TABLE product_variants ADD COLUMN sku TEXT DEFAULT gen_random_uuid()::text;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'product_variants'
                   AND column_name = 'stock_quantity') THEN
      ALTER TABLE product_variants ADD COLUMN stock_quantity INTEGER NOT NULL DEFAULT 0;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'product_variants'
                   AND column_name = 'price_adjustment') THEN
      ALTER TABLE product_variants ADD COLUMN price_adjustment DECIMAL(10, 2) DEFAULT 0;
    END IF;
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_product_variants_product ON product_variants(product_id);
CREATE INDEX IF NOT EXISTS idx_product_variants_available ON product_variants(is_available) WHERE is_available = TRUE;

COMMENT ON TABLE product_variants IS 'Product variations (size, color, etc.)';

-- ----------------------------------------------------------------------------
-- 4. shopping_carts
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS shopping_carts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

  -- Owner
  customer_id UUID REFERENCES storefront_customers(id) ON DELETE CASCADE,
  session_id TEXT NOT NULL, -- For guest carts (anonymous session)

  -- Branch Scope (IMPORTANT: carts are per-branch)
  branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,

  -- Metadata
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expires_at TIMESTAMPTZ NOT NULL DEFAULT (NOW() + INTERVAL '7 days'),

  -- Constraints
  CONSTRAINT unique_customer_branch_cart UNIQUE (customer_id, branch_id),
  CONSTRAINT unique_session_branch_cart UNIQUE (session_id, branch_id)
);

-- Ensure session_id column exists
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                 WHERE table_name = 'shopping_carts'
                 AND column_name = 'session_id') THEN
    ALTER TABLE shopping_carts ADD COLUMN session_id TEXT NOT NULL DEFAULT 'anonymous';
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_shopping_carts_customer ON shopping_carts(customer_id);
CREATE INDEX IF NOT EXISTS idx_shopping_carts_session ON shopping_carts(session_id);
CREATE INDEX IF NOT EXISTS idx_shopping_carts_branch ON shopping_carts(branch_id);
CREATE INDEX IF NOT EXISTS idx_shopping_carts_expires ON shopping_carts(expires_at);

COMMENT ON TABLE shopping_carts IS 'Ephemeral shopping carts (separate per branch, 7-day expiry)';

-- ----------------------------------------------------------------------------
-- 5. cart_items
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS cart_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

  -- Cart Reference
  cart_id UUID NOT NULL REFERENCES shopping_carts(id) ON DELETE CASCADE,

  -- Product Reference
  product_id UUID NOT NULL REFERENCES storefront_products(id) ON DELETE CASCADE,
  variant_id UUID REFERENCES product_variants(id) ON DELETE SET NULL,

  -- Quantity
  quantity INTEGER NOT NULL DEFAULT 1,

  -- Price Snapshot (at time of adding to cart)
  unit_price DECIMAL(10, 2) NOT NULL,

  -- Metadata
  added_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  -- Constraints
  CONSTRAINT quantity_positive CHECK (quantity > 0),
  CONSTRAINT unique_cart_product UNIQUE (cart_id, product_id, variant_id)
);

-- Ensure critical columns exist in cart_items
DO $$
DECLARE
  v_table_exists BOOLEAN;
BEGIN
  SELECT EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_name = 'cart_items'
  ) INTO v_table_exists;

  IF v_table_exists THEN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'cart_items'
                   AND column_name = 'product_id') THEN
      ALTER TABLE cart_items ADD COLUMN product_id UUID;
      ALTER TABLE cart_items ADD CONSTRAINT fk_cart_items_product
        FOREIGN KEY (product_id) REFERENCES storefront_products(id) ON DELETE CASCADE;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'cart_items'
                   AND column_name = 'cart_id') THEN
      ALTER TABLE cart_items ADD COLUMN cart_id UUID;
      ALTER TABLE cart_items ADD CONSTRAINT fk_cart_items_cart
        FOREIGN KEY (cart_id) REFERENCES shopping_carts(id) ON DELETE CASCADE;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'cart_items'
                   AND column_name = 'quantity') THEN
      ALTER TABLE cart_items ADD COLUMN quantity INTEGER NOT NULL DEFAULT 1;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'cart_items'
                   AND column_name = 'unit_price') THEN
      ALTER TABLE cart_items ADD COLUMN unit_price DECIMAL(10, 2) NOT NULL DEFAULT 0;
    END IF;
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_cart_items_cart ON cart_items(cart_id);
CREATE INDEX IF NOT EXISTS idx_cart_items_product ON cart_items(product_id);

COMMENT ON TABLE cart_items IS 'Line items within shopping carts';

-- ----------------------------------------------------------------------------
-- 6. storefront_orders (renamed from orders)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS storefront_orders (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

  -- Order Number (human-readable)
  order_number TEXT NOT NULL UNIQUE, -- e.g., "ORD-2026-000001"

  -- Customer
  customer_id UUID NOT NULL REFERENCES storefront_customers(id) ON DELETE RESTRICT,

  -- Branch/Tenant
  branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE RESTRICT,
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE RESTRICT,

  -- Delivery Information
  delivery_name TEXT NOT NULL,
  delivery_phone TEXT NOT NULL,
  delivery_address JSONB, -- NULL for Self Pickup
  delivery_coordinates POINT,
  delivery_method TEXT NOT NULL, -- 'self_pickup', 'bicycle', 'motorbike', 'platform'
  delivery_instructions TEXT,

  -- Pricing Breakdown
  subtotal DECIMAL(10, 2) NOT NULL, -- Sum of product prices
  delivery_base_fee DECIMAL(10, 2) NOT NULL DEFAULT 0, -- Calculated delivery fee
  delivery_fee_addition DECIMAL(10, 2) NOT NULL DEFAULT 100.00, -- Fixed N100 addition
  platform_commission DECIMAL(10, 2) NOT NULL DEFAULT 50.00, -- Fixed N50 commission (customer portion)
  transaction_fee DECIMAL(10, 2) NOT NULL DEFAULT 100.00, -- Fixed N100 transaction fee
  total_amount DECIMAL(10, 2) NOT NULL, -- subtotal + (delivery_base_fee + 100) + 50 + 100

  -- Payment Status
  payment_status TEXT NOT NULL DEFAULT 'pending', -- 'pending', 'paid', 'failed', 'refunded'
  payment_method TEXT, -- From Paystack (card, bank_transfer, ussd)
  paystack_reference TEXT UNIQUE, -- Paystack transaction reference

  -- Order Status
  order_status TEXT NOT NULL DEFAULT 'pending', -- 'pending', 'confirmed', 'preparing', 'ready', 'dispatched', 'delivered', 'cancelled'

  -- Metadata
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  paid_at TIMESTAMPTZ,
  confirmed_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,

  -- Constraints
  CONSTRAINT valid_payment_status CHECK (payment_status IN ('pending', 'paid', 'failed', 'refunded')),
  CONSTRAINT valid_order_status CHECK (order_status IN ('pending', 'confirmed', 'preparing', 'ready', 'dispatched', 'delivered', 'cancelled')),
  CONSTRAINT valid_delivery_method CHECK (delivery_method IN ('self_pickup', 'bicycle', 'motorbike', 'platform')),
  CONSTRAINT amounts_positive CHECK (subtotal >= 0 AND total_amount >= 0)
);

CREATE INDEX IF NOT EXISTS idx_storefront_orders_customer ON storefront_orders(customer_id);
CREATE INDEX IF NOT EXISTS idx_storefront_orders_branch ON storefront_orders(branch_id);
CREATE INDEX IF NOT EXISTS idx_storefront_orders_tenant ON storefront_orders(tenant_id);
CREATE INDEX IF NOT EXISTS idx_storefront_orders_payment_status ON storefront_orders(payment_status);
CREATE INDEX IF NOT EXISTS idx_storefront_orders_order_status ON storefront_orders(order_status);
CREATE INDEX IF NOT EXISTS idx_storefront_orders_paystack_ref ON storefront_orders(paystack_reference);
CREATE INDEX IF NOT EXISTS idx_storefront_orders_created_at ON storefront_orders(created_at DESC);

COMMENT ON TABLE storefront_orders IS 'Customer orders from online storefront with fee breakdown';

-- ----------------------------------------------------------------------------
-- 7. storefront_order_items (renamed from order_items)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS storefront_order_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

  -- Order Reference
  order_id UUID NOT NULL REFERENCES storefront_orders(id) ON DELETE CASCADE,

  -- Product Snapshot (at time of purchase)
  product_id UUID NOT NULL REFERENCES storefront_products(id) ON DELETE RESTRICT,
  variant_id UUID REFERENCES product_variants(id) ON DELETE SET NULL,
  product_name TEXT NOT NULL,
  product_sku TEXT NOT NULL,
  variant_name TEXT, -- e.g., "Large / Red"

  -- Pricing
  unit_price DECIMAL(10, 2) NOT NULL,
  quantity INTEGER NOT NULL,
  line_total DECIMAL(10, 2) NOT NULL, -- unit_price * quantity

  -- Metadata
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  -- Constraints
  CONSTRAINT quantity_positive CHECK (quantity > 0),
  CONSTRAINT prices_positive CHECK (unit_price >= 0 AND line_total >= 0)
);

CREATE INDEX IF NOT EXISTS idx_storefront_order_items_order ON storefront_order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_storefront_order_items_product ON storefront_order_items(product_id);

COMMENT ON TABLE storefront_order_items IS 'Line items within storefront orders (product snapshot)';

-- ----------------------------------------------------------------------------
-- 8. payment_transactions
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS payment_transactions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

  -- Order Reference
  order_id UUID NOT NULL REFERENCES storefront_orders(id) ON DELETE CASCADE,

  -- Paystack Details
  paystack_reference TEXT NOT NULL UNIQUE,
  paystack_access_code TEXT,
  paystack_transaction_id TEXT,

  -- Payment Information
  amount DECIMAL(10, 2) NOT NULL, -- Amount in Naira
  currency TEXT NOT NULL DEFAULT 'NGN',
  payment_method TEXT, -- card, bank_transfer, ussd
  payment_channel TEXT, -- visa, mastercard, verve, bank

  -- Status
  status TEXT NOT NULL, -- 'pending', 'success', 'failed', 'abandoned'
  gateway_response TEXT, -- Paystack response message

  -- Webhook Data
  webhook_payload JSONB, -- Full Paystack webhook payload
  webhook_signature TEXT,
  webhook_received_at TIMESTAMPTZ,

  -- Metadata
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  verified_at TIMESTAMPTZ,

  -- Constraints
  CONSTRAINT valid_status CHECK (status IN ('pending', 'success', 'failed', 'abandoned')),
  CONSTRAINT amount_positive CHECK (amount > 0)
);

CREATE INDEX IF NOT EXISTS idx_payment_transactions_order ON payment_transactions(order_id);
CREATE INDEX IF NOT EXISTS idx_payment_transactions_reference ON payment_transactions(paystack_reference);
CREATE INDEX IF NOT EXISTS idx_payment_transactions_status ON payment_transactions(status);

COMMENT ON TABLE payment_transactions IS 'Paystack payment audit trail (admin-only access)';

-- ----------------------------------------------------------------------------
-- 9. chat_sessions
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS chat_sessions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

  -- Participants
  customer_id UUID REFERENCES storefront_customers(id) ON DELETE CASCADE,
  session_token TEXT NOT NULL, -- For guest customers

  -- Branch/Tenant
  branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,

  -- Agent Assignment
  agent_id UUID REFERENCES auth.users(id) ON DELETE SET NULL, -- Live agent (NULL if AI)
  agent_type TEXT NOT NULL DEFAULT 'live', -- 'live', 'ai', 'owner' (for Free plan)

  -- Status
  status TEXT NOT NULL DEFAULT 'active', -- 'active', 'resolved', 'abandoned'

  -- Metadata
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  last_message_at TIMESTAMPTZ,
  resolved_at TIMESTAMPTZ,

  -- Constraints
  CONSTRAINT valid_status CHECK (status IN ('active', 'resolved', 'abandoned')),
  CONSTRAINT valid_agent_type CHECK (agent_type IN ('live', 'ai', 'owner'))
);

-- Ensure session_token column exists
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                 WHERE table_name = 'chat_sessions'
                 AND column_name = 'session_token') THEN
    ALTER TABLE chat_sessions ADD COLUMN session_token TEXT NOT NULL DEFAULT 'guest';
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_chat_sessions_customer ON chat_sessions(customer_id);
CREATE INDEX IF NOT EXISTS idx_chat_sessions_branch ON chat_sessions(branch_id);
CREATE INDEX IF NOT EXISTS idx_chat_sessions_agent ON chat_sessions(agent_id);
CREATE INDEX IF NOT EXISTS idx_chat_sessions_status ON chat_sessions(status);
CREATE INDEX IF NOT EXISTS idx_chat_sessions_created_at ON chat_sessions(created_at DESC);

COMMENT ON TABLE chat_sessions IS 'Live/AI chat sessions between customers and agents';

-- ----------------------------------------------------------------------------
-- 10. chat_messages
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS chat_messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

  -- Session Reference
  session_id UUID NOT NULL REFERENCES chat_sessions(id) ON DELETE CASCADE,

  -- Sender
  sender_type TEXT NOT NULL, -- 'customer', 'agent', 'ai'
  sender_id UUID, -- customer_id or auth.users.id (NULL for AI)
  sender_name TEXT NOT NULL,

  -- Message Content
  message_type TEXT NOT NULL DEFAULT 'text', -- 'text', 'image', 'voice', 'pdf', 'product_card'
  content TEXT NOT NULL, -- Text message or URL/reference for media

  -- Product Reference (for product_card type)
  product_id UUID REFERENCES storefront_products(id) ON DELETE SET NULL,

  -- Metadata
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  read_at TIMESTAMPTZ,

  -- Constraints
  CONSTRAINT valid_sender_type CHECK (sender_type IN ('customer', 'agent', 'ai')),
  CONSTRAINT valid_message_type CHECK (message_type IN ('text', 'image', 'voice', 'pdf', 'product_card'))
);

-- Ensure session_id column exists
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                 WHERE table_name = 'chat_messages'
                 AND column_name = 'session_id') THEN
    -- Get a sample chat_sessions id if exists, otherwise use a dummy UUID
    EXECUTE 'ALTER TABLE chat_messages ADD COLUMN session_id UUID REFERENCES chat_sessions(id) ON DELETE CASCADE';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                 WHERE table_name = 'chat_messages'
                 AND column_name = 'product_id') THEN
    ALTER TABLE chat_messages ADD COLUMN product_id UUID REFERENCES storefront_products(id) ON DELETE SET NULL;
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_chat_messages_session ON chat_messages(session_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_created_at ON chat_messages(created_at);
CREATE INDEX IF NOT EXISTS idx_chat_messages_product ON chat_messages(product_id);

COMMENT ON TABLE chat_messages IS 'Messages within chat sessions';

-- ----------------------------------------------------------------------------
-- 11. chat_attachments
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS chat_attachments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

  -- Message Reference
  message_id UUID NOT NULL REFERENCES chat_messages(id) ON DELETE CASCADE,
  session_id UUID NOT NULL REFERENCES chat_sessions(id) ON DELETE CASCADE,

  -- File Information
  file_type TEXT NOT NULL, -- 'image', 'voice', 'pdf'
  file_name TEXT NOT NULL,
  file_size INTEGER NOT NULL, -- Bytes
  mime_type TEXT NOT NULL,

  -- Storage Reference
  storage_bucket TEXT NOT NULL DEFAULT 'chat-attachments',
  storage_path TEXT NOT NULL, -- Path in Supabase Storage
  storage_url TEXT NOT NULL, -- Signed URL or public URL

  -- Metadata
  uploaded_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  uploaded_by UUID NOT NULL, -- customer_id or agent_id

  -- Constraints
  CONSTRAINT valid_file_type CHECK (file_type IN ('image', 'voice', 'pdf')),
  CONSTRAINT file_size_limit CHECK (
    (file_type = 'image' AND file_size <= 5242880) OR -- 5MB
    (file_type = 'pdf' AND file_size <= 10485760) OR -- 10MB
    (file_type = 'voice' AND file_size <= 5242880) -- 5MB (approx 2min audio)
  )
);

-- Ensure session_id column exists
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                 WHERE table_name = 'chat_attachments'
                 AND column_name = 'session_id') THEN
    EXECUTE 'ALTER TABLE chat_attachments ADD COLUMN session_id UUID REFERENCES chat_sessions(id) ON DELETE CASCADE';
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_chat_attachments_message ON chat_attachments(message_id);
CREATE INDEX IF NOT EXISTS idx_chat_attachments_session ON chat_attachments(session_id);
CREATE INDEX IF NOT EXISTS idx_chat_attachments_uploaded_at ON chat_attachments(uploaded_at);

COMMENT ON TABLE chat_attachments IS 'File attachments in chat messages (Supabase Storage references)';

-- ----------------------------------------------------------------------------
-- 12. tenant_branding
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS tenant_branding (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

  -- Tenant Reference
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  branch_id UUID REFERENCES branches(id) ON DELETE CASCADE, -- NULL for tenant-wide branding

  -- Branding
  business_name TEXT NOT NULL,
  logo_url TEXT, -- Supabase Storage URL (if uploaded)
  brand_color TEXT NOT NULL DEFAULT '#0ea5e9', -- Hex color for PWA theme
  background_color TEXT NOT NULL DEFAULT '#ffffff',

  -- Metadata
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  -- Constraints
  CONSTRAINT unique_branch_branding UNIQUE (branch_id),
  CONSTRAINT valid_hex_color CHECK (
    brand_color ~ '^#[0-9A-Fa-f]{6}$' AND
    background_color ~ '^#[0-9A-Fa-f]{6}$'
  )
);

CREATE INDEX IF NOT EXISTS idx_tenant_branding_tenant ON tenant_branding(tenant_id);
CREATE INDEX IF NOT EXISTS idx_tenant_branding_branch ON tenant_branding(branch_id);

COMMENT ON TABLE tenant_branding IS 'Tenant branding for PWA icon and manifest generation';

-- ============================================================================
-- HELPER VIEWS
-- ============================================================================

-- ----------------------------------------------------------------------------
-- View: storefront_products_with_catalog
-- Joins tenant inventory with global catalog data
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW storefront_products_with_catalog AS
SELECT
  sp.id,
  sp.tenant_id,
  sp.branch_id,
  sp.catalog_product_id,

  -- Product info (from catalog or custom override)
  COALESCE(sp.custom_name, gc.name) as name,
  COALESCE(sp.custom_description, gc.description) as description,
  COALESCE(sp.custom_images, gc.images) as images,
  COALESCE(sp.custom_images[1], gc.primary_image) as primary_image,
  gc.category,
  gc.brand,
  gc.barcode,
  gc.business_type,
  gc.specifications,

  -- Tenant inventory data
  sp.sku,
  sp.price,
  sp.compare_at_price,
  sp.cost_price,
  sp.stock_quantity,
  sp.low_stock_threshold,
  sp.is_available,
  sp.has_variants,

  -- Metadata
  sp.created_at,
  sp.updated_at,
  sp.synced_at
FROM storefront_products sp
LEFT JOIN global_product_catalog gc ON sp.catalog_product_id = gc.id
WHERE sp.is_available = TRUE;

COMMENT ON VIEW storefront_products_with_catalog IS 'Storefront products enriched with global catalog data';

-- ============================================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- global_product_catalog
-- ----------------------------------------------------------------------------
ALTER TABLE global_product_catalog ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS global_catalog_select_all ON global_product_catalog;
CREATE POLICY global_catalog_select_all ON global_product_catalog
  FOR SELECT USING (is_active = TRUE);

DROP POLICY IF EXISTS global_catalog_insert_admin ON global_product_catalog;
CREATE POLICY global_catalog_insert_admin ON global_product_catalog
  FOR INSERT WITH CHECK (
    -- Only platform admins can add to global catalog
    EXISTS (SELECT 1 FROM auth.users WHERE id = auth.uid() AND raw_user_meta_data->>'role' = 'platform_admin')
  );

DROP POLICY IF EXISTS global_catalog_update_admin ON global_product_catalog;
CREATE POLICY global_catalog_update_admin ON global_product_catalog
  FOR UPDATE USING (
    EXISTS (SELECT 1 FROM auth.users WHERE id = auth.uid() AND raw_user_meta_data->>'role' = 'platform_admin')
  );

-- ----------------------------------------------------------------------------
-- storefront_customers
-- ----------------------------------------------------------------------------
ALTER TABLE storefront_customers ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS storefront_customers_select_own ON storefront_customers;
CREATE POLICY storefront_customers_select_own ON storefront_customers
  FOR SELECT USING (
    user_id = auth.uid()
  );

DROP POLICY IF EXISTS storefront_customers_insert_own ON storefront_customers;
CREATE POLICY storefront_customers_insert_own ON storefront_customers
  FOR INSERT WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS storefront_customers_update_own ON storefront_customers;
CREATE POLICY storefront_customers_update_own ON storefront_customers
  FOR UPDATE USING (user_id = auth.uid());

-- ----------------------------------------------------------------------------
-- storefront_products
-- ----------------------------------------------------------------------------
ALTER TABLE storefront_products ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS storefront_products_select_all ON storefront_products;
CREATE POLICY storefront_products_select_all ON storefront_products
  FOR SELECT USING (is_available = TRUE);

-- ----------------------------------------------------------------------------
-- product_variants
-- ----------------------------------------------------------------------------
ALTER TABLE product_variants ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS product_variants_select_all ON product_variants;
CREATE POLICY product_variants_select_all ON product_variants
  FOR SELECT USING (is_available = TRUE);

-- ----------------------------------------------------------------------------
-- shopping_carts
-- ----------------------------------------------------------------------------
ALTER TABLE shopping_carts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS shopping_carts_all ON shopping_carts;
CREATE POLICY shopping_carts_all ON shopping_carts
  FOR ALL USING (
    (customer_id IS NOT NULL AND customer_id IN (SELECT id FROM storefront_customers WHERE user_id = auth.uid()))
    OR
    (customer_id IS NULL AND session_id IS NOT NULL)
  );

-- ----------------------------------------------------------------------------
-- cart_items
-- ----------------------------------------------------------------------------
ALTER TABLE cart_items ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS cart_items_all ON cart_items;
CREATE POLICY cart_items_all ON cart_items
  FOR ALL USING (
    cart_id IN (
      SELECT id FROM shopping_carts WHERE
        (customer_id IN (SELECT id FROM storefront_customers WHERE user_id = auth.uid()))
        OR (customer_id IS NULL)
    )
  );

-- ----------------------------------------------------------------------------
-- storefront_orders
-- ----------------------------------------------------------------------------
ALTER TABLE storefront_orders ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS storefront_orders_select_own ON storefront_orders;
CREATE POLICY storefront_orders_select_own ON storefront_orders
  FOR SELECT USING (
    customer_id IN (SELECT id FROM storefront_customers WHERE user_id = auth.uid())
  );

-- ----------------------------------------------------------------------------
-- storefront_order_items
-- ----------------------------------------------------------------------------
ALTER TABLE storefront_order_items ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS storefront_order_items_select_own ON storefront_order_items;
CREATE POLICY storefront_order_items_select_own ON storefront_order_items
  FOR SELECT USING (
    order_id IN (SELECT id FROM storefront_orders WHERE customer_id IN (SELECT id FROM storefront_customers WHERE user_id = auth.uid()))
  );

-- ----------------------------------------------------------------------------
-- payment_transactions
-- ----------------------------------------------------------------------------
ALTER TABLE payment_transactions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS payment_transactions_select_admin ON payment_transactions;
CREATE POLICY payment_transactions_select_admin ON payment_transactions
  FOR SELECT USING (FALSE); -- Admin-only (not accessible to customers)

-- ----------------------------------------------------------------------------
-- chat_sessions
-- ----------------------------------------------------------------------------
ALTER TABLE chat_sessions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS chat_sessions_all ON chat_sessions;
CREATE POLICY chat_sessions_all ON chat_sessions
  FOR ALL USING (
    (customer_id IN (SELECT id FROM storefront_customers WHERE user_id = auth.uid()))
    OR (agent_id = auth.uid())
    OR (customer_id IS NULL)
  );

-- ----------------------------------------------------------------------------
-- chat_messages
-- ----------------------------------------------------------------------------
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS chat_messages_all ON chat_messages;
CREATE POLICY chat_messages_all ON chat_messages
  FOR ALL USING (
    session_id IN (
      SELECT id FROM chat_sessions WHERE
        (customer_id IN (SELECT id FROM storefront_customers WHERE user_id = auth.uid()))
        OR (agent_id = auth.uid())
        OR (customer_id IS NULL)
    )
  );

-- ----------------------------------------------------------------------------
-- chat_attachments
-- ----------------------------------------------------------------------------
ALTER TABLE chat_attachments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS chat_attachments_all ON chat_attachments;
CREATE POLICY chat_attachments_all ON chat_attachments
  FOR ALL USING (
    session_id IN (
      SELECT id FROM chat_sessions WHERE
        (customer_id IN (SELECT id FROM storefront_customers WHERE user_id = auth.uid()))
        OR (agent_id = auth.uid())
        OR (customer_id IS NULL)
    )
  );

-- ----------------------------------------------------------------------------
-- tenant_branding
-- ----------------------------------------------------------------------------
ALTER TABLE tenant_branding ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS tenant_branding_select_all ON tenant_branding;
CREATE POLICY tenant_branding_select_all ON tenant_branding
  FOR SELECT USING (TRUE); -- Public read for storefront

DROP POLICY IF EXISTS tenant_branding_update_admin ON tenant_branding;
CREATE POLICY tenant_branding_update_admin ON tenant_branding
  FOR UPDATE USING (
    tenant_id IN (SELECT tenant_id FROM users WHERE id = auth.uid() AND role = 'tenant_admin')
  );

-- ============================================================================
-- DATABASE FUNCTIONS
-- ============================================================================

-- ----------------------------------------------------------------------------
-- auto_update_timestamp()
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION auto_update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to all tables with updated_at (only if trigger doesn't exist)
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_storefront_customers_timestamp') THEN
    CREATE TRIGGER update_storefront_customers_timestamp
      BEFORE UPDATE ON storefront_customers
      FOR EACH ROW EXECUTE FUNCTION auto_update_timestamp();
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_storefront_products_timestamp') THEN
    CREATE TRIGGER update_storefront_products_timestamp
      BEFORE UPDATE ON storefront_products
      FOR EACH ROW EXECUTE FUNCTION auto_update_timestamp();
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_product_variants_timestamp') THEN
    CREATE TRIGGER update_product_variants_timestamp
      BEFORE UPDATE ON product_variants
      FOR EACH ROW EXECUTE FUNCTION auto_update_timestamp();
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_shopping_carts_timestamp') THEN
    CREATE TRIGGER update_shopping_carts_timestamp
      BEFORE UPDATE ON shopping_carts
      FOR EACH ROW EXECUTE FUNCTION auto_update_timestamp();
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_cart_items_timestamp') THEN
    CREATE TRIGGER update_cart_items_timestamp
      BEFORE UPDATE ON cart_items
      FOR EACH ROW EXECUTE FUNCTION auto_update_timestamp();
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_storefront_orders_timestamp') THEN
    CREATE TRIGGER update_storefront_orders_timestamp
      BEFORE UPDATE ON storefront_orders
      FOR EACH ROW EXECUTE FUNCTION auto_update_timestamp();
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_payment_transactions_timestamp') THEN
    CREATE TRIGGER update_payment_transactions_timestamp
      BEFORE UPDATE ON payment_transactions
      FOR EACH ROW EXECUTE FUNCTION auto_update_timestamp();
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_chat_sessions_timestamp') THEN
    CREATE TRIGGER update_chat_sessions_timestamp
      BEFORE UPDATE ON chat_sessions
      FOR EACH ROW EXECUTE FUNCTION auto_update_timestamp();
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_tenant_branding_timestamp') THEN
    CREATE TRIGGER update_tenant_branding_timestamp
      BEFORE UPDATE ON tenant_branding
      FOR EACH ROW EXECUTE FUNCTION auto_update_timestamp();
  END IF;
END $$;

-- ----------------------------------------------------------------------------
-- calculate_order_total()
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION calculate_storefront_order_total(
  p_subtotal DECIMAL,
  p_delivery_base_fee DECIMAL
)
RETURNS DECIMAL AS $$
BEGIN
  -- Total = subtotal + (delivery_base_fee + 100) + platform_commission(50) + transaction_fee(100)
  RETURN p_subtotal + (p_delivery_base_fee + 100.00) + 50.00 + 100.00;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

COMMENT ON FUNCTION calculate_storefront_order_total IS 'Calculates storefront order total with delivery, platform, and transaction fees';

-- ----------------------------------------------------------------------------
-- generate_storefront_order_number()
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION generate_storefront_order_number()
RETURNS TEXT AS $$
DECLARE
  v_year TEXT;
  v_sequence INTEGER;
  v_order_number TEXT;
BEGIN
  v_year := EXTRACT(YEAR FROM NOW())::TEXT;

  -- Get next sequence number for this year
  SELECT COALESCE(MAX(CAST(SUBSTRING(order_number FROM 10) AS INTEGER)), 0) + 1
  INTO v_sequence
  FROM storefront_orders
  WHERE order_number LIKE 'ORD-' || v_year || '-%';

  v_order_number := 'ORD-' || v_year || '-' || LPAD(v_sequence::TEXT, 6, '0');

  RETURN v_order_number;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION generate_storefront_order_number IS 'Generates unique storefront order number (e.g., ORD-2026-000001)';

-- ----------------------------------------------------------------------------
-- search_global_catalog()
-- Search global catalog filtered by business type
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION search_global_catalog(
  p_business_type TEXT,
  p_search_query TEXT DEFAULT NULL,
  p_category TEXT DEFAULT NULL,
  p_verified_only BOOLEAN DEFAULT FALSE
)
RETURNS TABLE (
  id UUID,
  name TEXT,
  description TEXT,
  category TEXT,
  brand TEXT,
  barcode TEXT,
  primary_image TEXT,
  specifications JSONB,
  is_verified BOOLEAN
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    gc.id,
    gc.name,
    gc.description,
    gc.category,
    gc.brand,
    gc.barcode,
    gc.primary_image,
    gc.specifications,
    gc.is_verified
  FROM global_product_catalog gc
  WHERE gc.is_active = TRUE
    AND gc.business_type = p_business_type
    AND (p_category IS NULL OR gc.category = p_category)
    AND (NOT p_verified_only OR gc.is_verified = TRUE)
    AND (
      p_search_query IS NULL OR
      to_tsvector('english', gc.name || ' ' || COALESCE(gc.description, '') || ' ' || COALESCE(gc.brand, ''))
      @@ plainto_tsquery('english', p_search_query)
    )
  ORDER BY
    gc.is_verified DESC, -- Verified products first
    gc.name ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION search_global_catalog IS 'Search global product catalog filtered by business type. Used by tenants to find products to add to their inventory.';

-- ----------------------------------------------------------------------------
-- search_catalog_for_tenant()
-- Search catalog automatically filtered by tenant's business type
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION search_catalog_for_tenant(
  p_tenant_id UUID,
  p_search_query TEXT DEFAULT NULL,
  p_category TEXT DEFAULT NULL,
  p_verified_only BOOLEAN DEFAULT TRUE
)
RETURNS TABLE (
  id UUID,
  name TEXT,
  description TEXT,
  category TEXT,
  brand TEXT,
  barcode TEXT,
  primary_image TEXT,
  specifications JSONB,
  is_verified BOOLEAN,
  already_in_inventory BOOLEAN
) AS $$
DECLARE
  v_business_type TEXT;
BEGIN
  -- Get tenant's business type
  SELECT business_type INTO v_business_type
  FROM tenants
  WHERE tenants.id = p_tenant_id;

  -- If business_type not set, default to 'general'
  IF v_business_type IS NULL THEN
    v_business_type := 'general';
  END IF;

  RETURN QUERY
  SELECT
    gc.id,
    gc.name,
    gc.description,
    gc.category,
    gc.brand,
    gc.barcode,
    gc.primary_image,
    gc.specifications,
    gc.is_verified,
    -- Check if product is already in tenant's inventory
    EXISTS(
      SELECT 1 FROM storefront_products sp
      WHERE sp.catalog_product_id = gc.id
      AND sp.tenant_id = p_tenant_id
    ) as already_in_inventory
  FROM global_product_catalog gc
  WHERE gc.is_active = TRUE
    AND gc.business_type = v_business_type
    AND (p_category IS NULL OR gc.category = p_category)
    AND (NOT p_verified_only OR gc.is_verified = TRUE)
    AND (
      p_search_query IS NULL OR
      to_tsvector('english', gc.name || ' ' || COALESCE(gc.description, '') || ' ' || COALESCE(gc.brand, ''))
      @@ plainto_tsquery('english', p_search_query)
    )
  ORDER BY
    gc.is_verified DESC, -- Verified products first
    gc.name ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION search_catalog_for_tenant IS 'Search catalog filtered by tenant business type. Shows if product is already in tenant inventory.';

-- Trigger to auto-generate order number
CREATE OR REPLACE FUNCTION set_storefront_order_number()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.order_number IS NULL THEN
    NEW.order_number := generate_storefront_order_number();
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'generate_storefront_order_number_trigger') THEN
    CREATE TRIGGER generate_storefront_order_number_trigger
      BEFORE INSERT ON storefront_orders
      FOR EACH ROW EXECUTE FUNCTION set_storefront_order_number();
  END IF;
END $$;

-- ============================================================================
-- SUPABASE STORAGE BUCKETS
-- ============================================================================

-- Create chat-attachments bucket (private)
INSERT INTO storage.buckets (id, name, public)
VALUES ('chat-attachments', 'chat-attachments', false)
ON CONFLICT (id) DO NOTHING;

-- RLS Policy for storage uploads (drop and recreate to avoid conflicts)
DROP POLICY IF EXISTS chat_attachments_upload ON storage.objects;
CREATE POLICY chat_attachments_upload ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'chat-attachments' AND
    auth.uid() IS NOT NULL
  );

-- RLS Policy for storage access (only chat participants)
DROP POLICY IF EXISTS chat_attachments_select ON storage.objects;
CREATE POLICY chat_attachments_select ON storage.objects
  FOR SELECT TO authenticated
  USING (
    bucket_id = 'chat-attachments' AND
    -- Only participants of the chat session can access
    (storage.foldername(name))[2] IN (
      SELECT id::text FROM chat_sessions WHERE
        customer_id IN (SELECT id FROM storefront_customers WHERE user_id = auth.uid())
        OR agent_id = auth.uid()
    )
  );

-- ============================================================================
-- MIGRATION COMPLETE
-- ============================================================================
-- Created 13 tables, indexes, RLS policies, triggers, functions, and storage
-- Tables use "storefront_" prefix to avoid conflicts with existing POS tables
--
-- ============================================================================
-- NEW: Global Product Catalog Architecture
-- ============================================================================
--
-- TABLE HIERARCHY:
-- ----------------
-- global_product_catalog (platform-wide, one product = one row)
--   ↓ (referenced by)
-- storefront_products (tenant inventory: stock + pricing)
--   ↓ (referenced by)
-- ├── product_variants (size/color options)
-- ├── cart_items (shopping cart line items)
-- ├── storefront_order_items (order line items)
-- └── chat_messages (product cards in chat)
--
-- TENANT FILTERING:
-- -----------------
-- tenants.business_type = 'pharmacy'
--   ↓ (automatically filters)
-- global_product_catalog WHERE business_type = 'pharmacy'
--
-- KEY TABLES:
-- -----------
-- 1. global_product_catalog - Platform-wide shared product definitions
--    - business_type: 'pharmacy', 'grocery', 'fashion', etc.
--    - Images stored ONCE (huge cost savings)
--    - is_verified: Platform-curated products
--
-- 2. storefront_products - Tenant inventory
--    - catalog_product_id: References global catalog
--    - price, stock_quantity: Tenant-controlled
--    - custom_name, custom_images: Optional overrides
--
-- 3. tenants (enhanced)
--    - business_type: Determines which products shown to tenant
--
-- HELPER FUNCTIONS:
-- -----------------
-- 1. search_global_catalog(business_type, query)
--    - Search catalog by business type
--
-- 2. search_catalog_for_tenant(tenant_id, query)
--    - Automatically filters by tenant's business_type
--    - Shows if product already in tenant inventory
--
-- 3. storefront_products_with_catalog (VIEW)
--    - Joins inventory + catalog data
--    - Returns enriched product info for storefront
--
-- ============================================================================
-- USAGE EXAMPLES
-- ============================================================================
--
-- Example 1: Platform admin adds product to catalog
-- ---------------------------------------------------
-- INSERT INTO global_product_catalog (
--   business_type, name, description, category, barcode, primary_image
-- ) VALUES (
--   'pharmacy', 'Paracetamol 500mg', 'Pain relief tablets', 'Analgesics',
--   '5012345678900', 'https://storage.../paracetamol.jpg'
-- );
--
-- Example 2: Pharmacy tenant searches for products
-- -------------------------------------------------
-- SELECT * FROM search_catalog_for_tenant(
--   'tenant-uuid',
--   'paracetamol'
-- );
-- -- Returns: Paracetamol products + already_in_inventory flag
--
-- Example 3: Pharmacy adds product to inventory
-- ----------------------------------------------
-- INSERT INTO storefront_products (
--   catalog_product_id, tenant_id, branch_id, sku, price, stock_quantity
-- ) VALUES (
--   'catalog-product-uuid', 'tenant-uuid', 'branch-uuid',
--   'PARA-500', 500.00, 100
-- );
--
-- Example 4: Customer views storefront
-- -------------------------------------
-- SELECT * FROM storefront_products_with_catalog
-- WHERE branch_id = 'branch-uuid' AND is_available = TRUE;
-- -- Returns: Products with catalog data (name, images) + inventory (price, stock)
--
-- ============================================================================
-- BENEFITS
-- ============================================================================
--
-- 1. COST SAVINGS
--    - Images stored ONCE (not per tenant)
--    - Example: 1,000 tenants × 100 products = 100,000 image rows
--              vs. 100 products in global catalog
--
-- 2. CONSISTENCY
--    - Standardized product data (barcodes, names, specs)
--    - Platform-verified products (is_verified flag)
--
-- 3. EASY ONBOARDING
--    - New tenants search & add products (no manual entry)
--    - Business type filtering (pharmacies only see drugs)
--
-- 4. FLEXIBILITY
--    - Tenants can override: custom_name, custom_images
--    - Tenants control: pricing, stock, availability
--
-- ============================================================================
-- Next: Apply this migration to Supabase SQL Editor
-- ============================================================================
