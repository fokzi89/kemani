-- Add AI Chat Add-on fields to subscriptions
ALTER TABLE subscriptions 
ADD COLUMN IF NOT EXISTS ai_addon_enabled BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS ai_addon_price DECIMAL(10,2) DEFAULT 0;

-- Create Catalog Products table
CREATE TABLE IF NOT EXISTS catalog_products (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE, -- Null for global products, set for tenant-specific master products
    name VARCHAR(255) NOT NULL,
    description TEXT,
    sku VARCHAR(100),
    barcode VARCHAR(100),
    category VARCHAR(100),
    image_url TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Add reference to products table
ALTER TABLE products
ADD COLUMN IF NOT EXISTS catalog_product_id UUID REFERENCES catalog_products(id) ON DELETE SET NULL;

-- Index for faster lookups
CREATE INDEX IF NOT EXISTS idx_catalog_products_tenant ON catalog_products(tenant_id);
CREATE INDEX IF NOT EXISTS idx_products_catalog_id ON products(catalog_product_id);

-- RLS Policies for catalog_products

-- Enable RLS
ALTER TABLE catalog_products ENABLE ROW LEVEL SECURITY;

-- 1. Read Policy:
-- Global products (tenant_id IS NULL) are readable by everyone authenticated.
-- Tenant products are readable by users of that tenant.
CREATE POLICY "Catalog products are viewable by authenticated users"
ON catalog_products FOR SELECT
USING (
    tenant_id IS NULL 
    OR 
    tenant_id IN (
        SELECT tenant_id FROM users WHERE auth.uid() = users.id
    )
    OR
    EXISTS (
        -- Allow System Admins to see everything (if you have a system admin role)
        SELECT 1 FROM users 
        WHERE auth.uid() = users.id AND role = 'system_admin'
    )
);

-- 2. Write Policy:
-- Only System Admins can write global products.
-- Tenant Admins can write their own tenant products.
CREATE POLICY "System Admins can manage global products"
ON catalog_products FOR ALL
USING (
    (tenant_id IS NULL) AND 
    EXISTS (
        SELECT 1 FROM users 
        WHERE auth.uid() = users.id AND role = 'system_admin'
    )
);

CREATE POLICY "Tenant Admins can manage their tenant catalog"
ON catalog_products FOR ALL
USING (
    tenant_id IN (
        SELECT tenant_id FROM users WHERE auth.uid() = users.id AND role IN ('owner', 'admin')
    )
);
