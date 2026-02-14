# Data Model: Ecommerce Storefront

**Feature**: 002-ecommerce-storefront
**Date**: 2026-02-11
**Database**: Supabase PostgreSQL

## Overview

This data model defines all database entities for the ecommerce storefront feature. The design emphasizes:
- Multi-tenancy with Row Level Security (RLS)
- Separate cart per branch (as specified)
- Plan-based feature access (Free, Growth, Business)
- Chat attachment storage with security
- Payment transaction audit trail

---

## Entity Relationship Diagram

```
customers ──┬─> orders ──> order_items ──> storefront_products
            │                               (synced from products)
            │
            └─> shopping_carts ──> cart_items ──> storefront_products
            │
            └─> chat_sessions ──> chat_messages ──> chat_attachments
                                                     (Supabase Storage)

orders ──> payment_transactions (Paystack)

tenants ──> branches ──> storefront_products
                     └─> shopping_carts
                     └─> chat_sessions
```

---

## Tables

### 1. customers

Stores customer information for storefront users. Linked to `auth.users` for authentication.

```sql
CREATE TABLE customers (
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

CREATE INDEX idx_customers_user_id ON customers(user_id);
CREATE INDEX idx_customers_phone ON customers(phone); -- For guest lookup
CREATE INDEX idx_customers_email ON customers(email);

-- RLS Policy: Customers can only see their own data
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;

CREATE POLICY customers_select_own ON customers
  FOR SELECT USING (
    user_id = auth.uid() OR
    id IN (SELECT customer_id FROM orders WHERE session_id = current_setting('app.session_id', TRUE))
  );

CREATE POLICY customers_update_own ON customers
  FOR UPDATE USING (user_id = auth.uid());
```

**Validation Rules**:
- Phone number required, must be 10-15 digits
- Email optional for guests, required for authenticated users
- Delivery address stored as JSONB for flexibility

---

### 2. storefront_products

Denormalized product data synced from POS `products` table. Optimized for storefront queries.

```sql
CREATE TABLE storefront_products (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

  -- Source Reference
  product_id UUID NOT NULL, -- Reference to POS products table
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE CASCADE,

  -- Product Information
  name TEXT NOT NULL,
  description TEXT,
  category TEXT NOT NULL,
  sku TEXT NOT NULL,

  -- Pricing
  price DECIMAL(10, 2) NOT NULL,
  compare_at_price DECIMAL(10, 2), -- Original price for discounts

  -- Inventory
  stock_quantity INTEGER NOT NULL DEFAULT 0,
  low_stock_threshold INTEGER DEFAULT 10,
  is_available BOOLEAN NOT NULL DEFAULT TRUE,

  -- Media
  images TEXT[], -- Array of image URLs (Supabase Storage)
  primary_image TEXT,

  -- Variants (if applicable)
  has_variants BOOLEAN DEFAULT FALSE,

  -- SEO
  slug TEXT NOT NULL, -- URL-friendly name
  meta_title TEXT,
  meta_description TEXT,

  -- Metadata
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  synced_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), -- Last sync from POS

  -- Constraints
  CONSTRAINT price_positive CHECK (price >= 0),
  CONSTRAINT stock_non_negative CHECK (stock_quantity >= 0),
  CONSTRAINT unique_product_branch UNIQUE (product_id, branch_id)
);

CREATE INDEX idx_storefront_products_branch ON storefront_products(branch_id);
CREATE INDEX idx_storefront_products_tenant ON storefront_products(tenant_id);
CREATE INDEX idx_storefront_products_category ON storefront_products(category);
CREATE INDEX idx_storefront_products_slug ON storefront_products(slug);
CREATE INDEX idx_storefront_products_available ON storefront_products(is_available) WHERE is_available = TRUE;

-- Full-text search index
CREATE INDEX idx_storefront_products_search ON storefront_products
  USING gin(to_tsvector('english', name || ' ' || COALESCE(description, '')));

-- RLS Policy: Public read access (storefront is public)
ALTER TABLE storefront_products ENABLE ROW LEVEL SECURITY;

CREATE POLICY storefront_products_select_all ON storefront_products
  FOR SELECT USING (is_available = TRUE);
```

**Sync Strategy**:
- Trigger on POS `products` table updates `storefront_products` via Supabase Edge Function
- Denormalized for performance (no joins needed in storefront queries)

---

### 3. product_variants

Product variations (size, color, etc.) for products with options.

```sql
CREATE TABLE product_variants (
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

CREATE INDEX idx_product_variants_product ON product_variants(product_id);
CREATE INDEX idx_product_variants_available ON product_variants(is_available) WHERE is_available = TRUE;

-- RLS Policy: Same as products (public read)
ALTER TABLE product_variants ENABLE ROW LEVEL SECURITY;

CREATE POLICY product_variants_select_all ON product_variants
  FOR SELECT USING (is_available = TRUE);
```

---

### 4. shopping_carts

Ephemeral shopping carts (separate per branch as specified).

```sql
CREATE TABLE shopping_carts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

  -- Owner
  customer_id UUID REFERENCES customers(id) ON DELETE CASCADE,
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

CREATE INDEX idx_shopping_carts_customer ON shopping_carts(customer_id);
CREATE INDEX idx_shopping_carts_session ON shopping_carts(session_id);
CREATE INDEX idx_shopping_carts_branch ON shopping_carts(branch_id);
CREATE INDEX idx_shopping_carts_expires ON shopping_carts(expires_at);

-- RLS Policy: Users can only access their own carts
ALTER TABLE shopping_carts ENABLE ROW LEVEL SECURITY;

CREATE POLICY shopping_carts_select_own ON shopping_carts
  FOR SELECT USING (
    customer_id IS NOT NULL AND customer_id IN (SELECT id FROM customers WHERE user_id = auth.uid())
    OR
    session_id = current_setting('app.session_id', TRUE)
  );
```

**Business Rules**:
- One cart per customer per branch (separate carts for each branch)
- Guest carts identified by session_id (cookie)
- Carts expire after 7 days of inactivity
- Background job cleans up expired carts

---

### 5. cart_items

Items within shopping carts.

```sql
CREATE TABLE cart_items (
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

CREATE INDEX idx_cart_items_cart ON cart_items(cart_id);
CREATE INDEX idx_cart_items_product ON cart_items(product_id);

-- RLS Policy: Same as cart (users access their own cart items)
ALTER TABLE cart_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY cart_items_select_own ON cart_items
  FOR SELECT USING (
    cart_id IN (SELECT id FROM shopping_carts WHERE
      (customer_id IS NOT NULL AND customer_id IN (SELECT id FROM customers WHERE user_id = auth.uid()))
      OR session_id = current_setting('app.session_id', TRUE)
    )
  );
```

---

### 6. orders

Customer orders (created at checkout, updated after payment).

```sql
CREATE TABLE orders (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

  -- Order Number (human-readable)
  order_number TEXT NOT NULL UNIQUE, -- e.g., "ORD-2024-00001"

  -- Customer
  customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE RESTRICT,

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

CREATE INDEX idx_orders_customer ON orders(customer_id);
CREATE INDEX idx_orders_branch ON orders(branch_id);
CREATE INDEX idx_orders_tenant ON orders(tenant_id);
CREATE INDEX idx_orders_payment_status ON orders(payment_status);
CREATE INDEX idx_orders_order_status ON orders(order_status);
CREATE INDEX idx_orders_paystack_ref ON orders(paystack_reference);
CREATE INDEX idx_orders_created_at ON orders(created_at DESC);

-- RLS Policy: Customers see their own orders, tenant admins see all
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;

CREATE POLICY orders_select_own ON orders
  FOR SELECT USING (
    customer_id IN (SELECT id FROM customers WHERE user_id = auth.uid())
  );
```

**Business Rules**:
- Order created when customer initiates checkout (before payment)
- `payment_status='pending'` until Paystack webhook confirms payment
- `order_status` updated independently of payment (fulfillment workflow)
- Fee calculation: `total_amount = subtotal + (delivery_base_fee + 100) + 50 + 100`
- Platform commission: N50 charged to customer (in order), N50 deducted from merchant revenue (in settlement)

---

### 7. order_items

Line items within orders.

```sql
CREATE TABLE order_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

  -- Order Reference
  order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,

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

CREATE INDEX idx_order_items_order ON order_items(order_id);
CREATE INDEX idx_order_items_product ON order_items(product_id);

-- RLS Policy: Same as orders
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY order_items_select_own ON order_items
  FOR SELECT USING (
    order_id IN (SELECT id FROM orders WHERE customer_id IN (SELECT id FROM customers WHERE user_id = auth.uid()))
  );
```

---

### 8. payment_transactions

Audit trail for Paystack payments.

```sql
CREATE TABLE payment_transactions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

  -- Order Reference
  order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,

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

CREATE INDEX idx_payment_transactions_order ON payment_transactions(order_id);
CREATE INDEX idx_payment_transactions_reference ON payment_transactions(paystack_reference);
CREATE INDEX idx_payment_transactions_status ON payment_transactions(status);

-- RLS Policy: Only tenant admins can see payment transactions
ALTER TABLE payment_transactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY payment_transactions_select_admin ON payment_transactions
  FOR SELECT USING (FALSE); -- Admin-only (not accessible to customers)
```

**Security**: Payment transactions are admin-only. Customers see payment status in `orders` table.

---

### 9. chat_sessions

Live chat sessions between customers and agents/AI.

```sql
CREATE TABLE chat_sessions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

  -- Participants
  customer_id UUID REFERENCES customers(id) ON DELETE CASCADE,
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

CREATE INDEX idx_chat_sessions_customer ON chat_sessions(customer_id);
CREATE INDEX idx_chat_sessions_branch ON chat_sessions(branch_id);
CREATE INDEX idx_chat_sessions_agent ON chat_sessions(agent_id);
CREATE INDEX idx_chat_sessions_status ON chat_sessions(status);
CREATE INDEX idx_chat_sessions_created_at ON chat_sessions(created_at DESC);

-- RLS Policy: Customers see their own sessions, agents see assigned sessions
ALTER TABLE chat_sessions ENABLE ROW LEVEL SECURITY;

CREATE POLICY chat_sessions_select_own ON chat_sessions
  FOR SELECT USING (
    customer_id IN (SELECT id FROM customers WHERE user_id = auth.uid())
    OR session_token = current_setting('app.session_token', TRUE)
    OR agent_id = auth.uid()
  );
```

---

### 10. chat_messages

Messages within chat sessions.

```sql
CREATE TABLE chat_messages (
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

CREATE INDEX idx_chat_messages_session ON chat_messages(session_id);
CREATE INDEX idx_chat_messages_created_at ON chat_messages(created_at);
CREATE INDEX idx_chat_messages_product ON chat_messages(product_id);

-- RLS Policy: Same as chat_sessions
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY chat_messages_select_own ON chat_messages
  FOR SELECT USING (
    session_id IN (SELECT id FROM chat_sessions WHERE
      customer_id IN (SELECT id FROM customers WHERE user_id = auth.uid())
      OR session_token = current_setting('app.session_token', TRUE)
      OR agent_id = auth.uid()
    )
  );
```

---

### 11. chat_attachments

File attachments in chat messages (references Supabase Storage).

```sql
CREATE TABLE chat_attachments (
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

CREATE INDEX idx_chat_attachments_message ON chat_attachments(message_id);
CREATE INDEX idx_chat_attachments_session ON chat_attachments(session_id);
CREATE INDEX idx_chat_attachments_uploaded_at ON chat_attachments(uploaded_at);

-- RLS Policy: Same as chat_messages
ALTER TABLE chat_attachments ENABLE ROW LEVEL SECURITY;

CREATE POLICY chat_attachments_select_own ON chat_attachments
  FOR SELECT USING (
    session_id IN (SELECT id FROM chat_sessions WHERE
      customer_id IN (SELECT id FROM customers WHERE user_id = auth.uid())
      OR session_token = current_setting('app.session_token', TRUE)
      OR agent_id = auth.uid()
    )
  );
```

**Storage Structure** (Supabase Storage):
```
chat-attachments/
└── {tenant_id}/
    └── {session_id}/
        ├── {message_id}-image.jpg
        ├── {message_id}-voice.webm
        └── {message_id}-document.pdf
```

---

### 12. tenant_branding (PWA Support)

Stores tenant branding information for PWA icon and manifest generation.

```sql
CREATE TABLE tenant_branding (
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

CREATE INDEX idx_tenant_branding_tenant ON tenant_branding(tenant_id);
CREATE INDEX idx_tenant_branding_branch ON tenant_branding(branch_id);

-- RLS Policy: Public read (for PWA generation)
ALTER TABLE tenant_branding ENABLE ROW LEVEL SECURITY;

CREATE POLICY tenant_branding_select_all ON tenant_branding
  FOR SELECT USING (TRUE); -- Public read for storefront

CREATE POLICY tenant_branding_update_admin ON tenant_branding
  FOR UPDATE USING (
    tenant_id IN (SELECT tenant_id FROM staff WHERE user_id = auth.uid() AND role = 'admin')
  );
```

**Business Rules**:
- If `logo_url` is provided, use it for PWA icons
- If `logo_url` is NULL, generate icon from first letter of `business_name` with `brand_color` background
- Each branch can have custom branding or inherit from tenant
- `brand_color` is used for PWA theme color and icon background

---

## Supabase Storage Buckets

### chat-attachments

```sql
-- Create storage bucket
INSERT INTO storage.buckets (id, name, public)
VALUES ('chat-attachments', 'chat-attachments', false);

-- RLS Policy for storage
CREATE POLICY chat_attachments_upload ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'chat-attachments' AND
    auth.uid() IS NOT NULL
  );

CREATE POLICY chat_attachments_select ON storage.objects
  FOR SELECT TO authenticated
  USING (
    bucket_id = 'chat-attachments' AND
    -- Only participants of the chat session can access
    (storage.foldername(name))[2] IN (
      SELECT id::text FROM chat_sessions WHERE
        customer_id IN (SELECT id FROM customers WHERE user_id = auth.uid())
        OR agent_id = auth.uid()
    )
  );
```

---

## Database Functions

### 1. auto_update_timestamp()

Automatically updates `updated_at` column on row modification.

```sql
CREATE OR REPLACE FUNCTION auto_update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to all tables with updated_at
CREATE TRIGGER update_customers_timestamp
  BEFORE UPDATE ON customers
  FOR EACH ROW EXECUTE FUNCTION auto_update_timestamp();

CREATE TRIGGER update_storefront_products_timestamp
  BEFORE UPDATE ON storefront_products
  FOR EACH ROW EXECUTE FUNCTION auto_update_timestamp();

-- ... apply to other tables
```

### 2. calculate_order_total()

Calculates order total with fees.

```sql
CREATE OR REPLACE FUNCTION calculate_order_total(
  p_subtotal DECIMAL,
  p_delivery_base_fee DECIMAL
)
RETURNS DECIMAL AS $$
BEGIN
  -- Total = subtotal + (delivery_base_fee + 100) + platform_commission(50) + transaction_fee(100)
  RETURN p_subtotal + (p_delivery_base_fee + 100.00) + 50.00 + 100.00;
END;
$$ LANGUAGE plpgsql IMMUTABLE;
```

### 3. generate_order_number()

Generates unique order number.

```sql
CREATE OR REPLACE FUNCTION generate_order_number()
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
  FROM orders
  WHERE order_number LIKE 'ORD-' || v_year || '-%';

  v_order_number := 'ORD-' || v_year || '-' || LPAD(v_sequence::TEXT, 6, '0');

  RETURN v_order_number;
END;
$$ LANGUAGE plpgsql;

-- Trigger to auto-generate order number
CREATE OR REPLACE FUNCTION set_order_number()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.order_number IS NULL THEN
    NEW.order_number := generate_order_number();
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER generate_order_number_trigger
  BEFORE INSERT ON orders
  FOR EACH ROW EXECUTE FUNCTION set_order_number();
```

---

## Validation Rules Summary

| Table | Field | Validation |
|-------|-------|------------|
| customers | phone | Regex: `^\+?[0-9]{10,15}$` |
| customers | email | Regex: `^[^@]+@[^@]+\.[^@]+$` (optional) |
| storefront_products | price | >= 0 |
| storefront_products | stock_quantity | >= 0 |
| cart_items | quantity | > 0 |
| orders | payment_status | IN ('pending', 'paid', 'failed', 'refunded') |
| orders | order_status | IN ('pending', 'confirmed', 'preparing', 'ready', 'dispatched', 'delivered', 'cancelled') |
| orders | delivery_method | IN ('self_pickup', 'bicycle', 'motorbike', 'platform') |
| orders | amounts | All >= 0 |
| chat_attachments | file_size | Image: <=5MB, PDF: <=10MB, Voice: <=5MB |

---

## Indexes for Performance

**Critical Indexes** (already included above):
- `customers(user_id)`, `customers(phone)` - Fast authentication & guest lookup
- `storefront_products(branch_id)`, `storefront_products(tenant_id)` - Filtering by branch/tenant
- Full-text search on `storefront_products(name, description)` - Product search
- `orders(customer_id)`, `orders(paystack_reference)` - Order lookup
- `chat_sessions(customer_id)`, `chat_sessions(agent_id)` - Chat routing
- `chat_messages(session_id, created_at)` - Message history

---

## Migration Strategy

1. **Phase 1**: Create all tables without RLS (development)
2. **Phase 2**: Add RLS policies and test with multiple tenants
3. **Phase 3**: Create indexes after initial data load
4. **Phase 4**: Add triggers and functions
5. **Phase 5**: Set up Supabase Storage buckets and policies

**Rollback Plan**: Each migration has corresponding `DOWN` migration to drop tables in reverse order.

---

**Data Model Complete** | **Next**: API Contracts
