-- ============================================================================
-- Create 5 Missing Tables - Simplified Version
-- ============================================================================
-- Tables: staff_invites, product_variants, invoices, sync_logs, audit_logs
-- ============================================================================

-- ============================================================================
-- 1. STAFF_INVITES
-- ============================================================================
CREATE TABLE IF NOT EXISTS staff_invites (
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

  created_by_user_id UUID REFERENCES users(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_staff_invites_tenant_id ON staff_invites(tenant_id);
CREATE INDEX IF NOT EXISTS idx_staff_invites_email ON staff_invites(email);
CREATE INDEX IF NOT EXISTS idx_staff_invites_status ON staff_invites(status);

ALTER TABLE staff_invites ENABLE ROW LEVEL SECURITY;
CREATE POLICY "staff_invites_tenant_isolation" ON staff_invites
  FOR ALL USING (tenant_id = (auth.jwt() ->> 'tenant_id')::UUID);

-- ============================================================================
-- 2. PRODUCT_VARIANTS
-- ============================================================================
CREATE TABLE IF NOT EXISTS product_variants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,

  variant_name VARCHAR(255) NOT NULL,
  variant_attributes JSONB NOT NULL DEFAULT '{}'::jsonb,

  sku VARCHAR(100),
  barcode VARCHAR(100),

  selling_price DECIMAL(15, 2),
  cost_price DECIMAL(15, 2),
  current_stock INTEGER DEFAULT 0,

  image_url TEXT,
  status VARCHAR(20) DEFAULT 'active',

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_product_variants_tenant_id ON product_variants(tenant_id);
CREATE INDEX IF NOT EXISTS idx_product_variants_product_id ON product_variants(product_id);
CREATE INDEX IF NOT EXISTS idx_product_variants_sku ON product_variants(sku);

ALTER TABLE product_variants ENABLE ROW LEVEL SECURITY;
CREATE POLICY "product_variants_tenant_isolation" ON product_variants
  FOR ALL USING (tenant_id = (auth.jwt() ->> 'tenant_id')::UUID);

-- ============================================================================
-- 3. INVOICES
-- ============================================================================
CREATE TABLE IF NOT EXISTS invoices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,

  invoice_number VARCHAR(50) NOT NULL UNIQUE,
  invoice_date DATE NOT NULL,
  due_date DATE NOT NULL,

  billing_period_start DATE NOT NULL,
  billing_period_end DATE NOT NULL,

  subscription_fee DECIMAL(15, 2) DEFAULT 0,
  commission_total DECIMAL(15, 2) DEFAULT 0,
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

CREATE INDEX IF NOT EXISTS idx_invoices_tenant_id ON invoices(tenant_id);
CREATE INDEX IF NOT EXISTS idx_invoices_invoice_number ON invoices(invoice_number);
CREATE INDEX IF NOT EXISTS idx_invoices_payment_status ON invoices(payment_status);

ALTER TABLE invoices ENABLE ROW LEVEL SECURITY;
CREATE POLICY "invoices_tenant_access" ON invoices
  FOR SELECT USING (tenant_id = (auth.jwt() ->> 'tenant_id')::UUID);

-- ============================================================================
-- 4. SYNC_LOGS
-- ============================================================================
CREATE TABLE IF NOT EXISTS sync_logs (
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

  triggered_by VARCHAR(50),
  triggered_by_user_id UUID REFERENCES users(id),

  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_sync_logs_tenant_id ON sync_logs(tenant_id);
CREATE INDEX IF NOT EXISTS idx_sync_logs_connection_id ON sync_logs(connection_id);
CREATE INDEX IF NOT EXISTS idx_sync_logs_status ON sync_logs(status);
CREATE INDEX IF NOT EXISTS idx_sync_logs_created_at ON sync_logs(created_at DESC);

ALTER TABLE sync_logs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "sync_logs_tenant_isolation" ON sync_logs
  FOR ALL USING (tenant_id = (auth.jwt() ->> 'tenant_id')::UUID);

-- ============================================================================
-- 5. AUDIT_LOGS
-- ============================================================================
CREATE TABLE IF NOT EXISTS audit_logs (
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

CREATE INDEX IF NOT EXISTS idx_audit_logs_tenant_id ON audit_logs(tenant_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_user_id ON audit_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_action ON audit_logs(action);
CREATE INDEX IF NOT EXISTS idx_audit_logs_entity ON audit_logs(entity_type, entity_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_created_at ON audit_logs(created_at DESC);

ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "audit_logs_tenant_isolation" ON audit_logs
  FOR SELECT USING (
    tenant_id = (auth.jwt() ->> 'tenant_id')::UUID OR
    tenant_id IS NULL
  );

-- ============================================================================
-- SUCCESS! All 5 tables created with RLS enabled
-- ============================================================================
