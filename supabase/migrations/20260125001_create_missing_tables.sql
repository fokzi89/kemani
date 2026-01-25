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
