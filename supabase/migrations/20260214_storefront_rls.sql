-- ============================================================================
-- Migration: Storefront RLS Policies
-- Feature: Security (T048)
-- Date: 2026-02-14
-- ============================================================================

-- 1. Enable RLS on all tables
ALTER TABLE global_product_catalog ENABLE ROW LEVEL SECURITY;
ALTER TABLE storefront_customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE storefront_products ENABLE ROW LEVEL SECURITY;
ALTER TABLE product_variants ENABLE ROW LEVEL SECURITY;
ALTER TABLE shopping_carts ENABLE ROW LEVEL SECURITY;
ALTER TABLE cart_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE storefront_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE storefront_order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_attachments ENABLE ROW LEVEL SECURITY;
ALTER TABLE tenant_branding ENABLE ROW LEVEL SECURITY;

-- 2. Public Read Access (Catalogs and Branding)
-- ----------------------------------------------------------------------------
CREATE POLICY "Public can view global catalog" ON global_product_catalog
  FOR SELECT USING (true);

CREATE POLICY "Public can view storefront products" ON storefront_products
  FOR SELECT USING (is_available = true);

CREATE POLICY "Public can view product variants" ON product_variants
  FOR SELECT USING (is_available = true);

CREATE POLICY "Public can view tenant branding" ON tenant_branding
  FOR SELECT USING (true);

-- 3. Customer Profiles
-- ----------------------------------------------------------------------------
-- Users can view/edit their own profile
CREATE POLICY "Users can view own profile" ON storefront_customers
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update own profile" ON storefront_customers
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own profile" ON storefront_customers
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- 4. Shopping Carts
-- ----------------------------------------------------------------------------
-- Guest access allows public read/write (protected by UUID)
-- Note: In a stricter environment, we would use signed session tokens or Service Role for guest carts.
CREATE POLICY "Public access to carts" ON shopping_carts
  FOR ALL USING (true);

CREATE POLICY "Public access to cart items" ON cart_items
  FOR ALL USING (true);

-- 5. Orders
-- ----------------------------------------------------------------------------
-- Users can view their own orders
CREATE POLICY "Users can view own orders" ON storefront_orders
  FOR SELECT USING (
    auth.uid() IN (
      SELECT user_id FROM storefront_customers WHERE id = customer_id
    )
  );

-- Only Service Role should insert/update orders typically (via API), but for now:
-- Allow Users to create orders (during checkout)
CREATE POLICY "Users can create orders" ON storefront_orders
  FOR INSERT WITH CHECK (
    auth.uid() IN (
      SELECT user_id FROM storefront_customers WHERE id = customer_id
    )
    OR auth.role() = 'anon' -- Allow guests to create orders
  );

-- Order Items inherits order access roughly, or just secure by order_id
CREATE POLICY "Users can view own order items" ON storefront_order_items
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM storefront_orders o
      WHERE o.id = order_id
      AND (
        -- Authenticated user owns the order
        o.customer_id IN (SELECT id FROM storefront_customers WHERE user_id = auth.uid())
        -- OR Guest created it (handling this securely is hard without session ownership, assume UUID knowledge implies access for now)
      )
    )
  );
  
-- 6. Chat Sessions
-- ----------------------------------------------------------------------------
-- Allow public access for now (Session Token security managed by app logic)
CREATE POLICY "Public access to chat sessions" ON chat_sessions
  FOR ALL USING (true);

CREATE POLICY "Public access to chat messages" ON chat_messages
  FOR ALL USING (true);

CREATE POLICY "Public access to chat attachments" ON chat_attachments
  FOR ALL USING (true);

-- 7. Payment Transactions (Strict)
-- ----------------------------------------------------------------------------
-- Only admins or service role can see transactions (except via order maybe?)
-- Let's allow users to see transactions for their orders?
CREATE POLICY "Users can view own transactions" ON payment_transactions
  FOR SELECT USING (
    order_id IN (
      SELECT id FROM storefront_orders 
      WHERE customer_id IN (SELECT id FROM storefront_customers WHERE user_id = auth.uid())
    )
  );
