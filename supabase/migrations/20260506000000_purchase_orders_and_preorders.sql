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
