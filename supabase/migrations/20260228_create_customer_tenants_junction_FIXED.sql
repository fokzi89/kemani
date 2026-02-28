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
