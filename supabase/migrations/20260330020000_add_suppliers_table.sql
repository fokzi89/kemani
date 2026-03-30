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
