-- 1. Update branch_inventory schema (Safely add columns if they don't exist)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'branch_inventory' AND column_name = 'purchase_invoice') THEN
        ALTER TABLE branch_inventory ADD COLUMN purchase_invoice TEXT;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'branch_inventory' AND column_name = 'purchase_code') THEN
        ALTER TABLE branch_inventory ADD COLUMN purchase_code TEXT;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'branch_inventory' AND column_name = 'added_by') THEN
        ALTER TABLE branch_inventory ADD COLUMN added_by TEXT;
    END IF;
END $$;

-- 2. Create product_stock_balance table to track aggregated stock per product/branch
CREATE TABLE IF NOT EXISTS product_stock_balance (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE,
    branch_id UUID REFERENCES branches(id) ON DELETE CASCADE,
    product_id UUID REFERENCES products(id) ON DELETE CASCADE,
    stock_balance DECIMAL(12,2) DEFAULT 0,
    low_stock_threshold DECIMAL(12,2) DEFAULT 5,
    last_updated TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(branch_id, product_id)
);

-- 3. Trigger function to keep product_stock_balance in sync with branch_inventory batches
-- SECURITY DEFINER allows the trigger to update the rollup table even if the user lacks direct write permissions.
CREATE OR REPLACE FUNCTION sync_product_stock_balance()
RETURNS TRIGGER AS $$
DECLARE
    v_tenant_id UUID;
BEGIN
    -- Get tenant_id from the affected row
    IF (TG_OP = 'DELETE') THEN
        v_tenant_id := OLD.tenant_id;
    ELSE
        v_tenant_id := NEW.tenant_id;
    END IF;

    -- Update or Insert the aggregated balance
    INSERT INTO product_stock_balance (tenant_id, branch_id, product_id, stock_balance, last_updated)
    SELECT 
        v_tenant_id,
        COALESCE(NEW.branch_id, OLD.branch_id),
        COALESCE(NEW.product_id, OLD.product_id),
        COALESCE(SUM(stock_quantity), 0),
        NOW()
    FROM branch_inventory
    WHERE branch_id = COALESCE(NEW.branch_id, OLD.branch_id)
      AND product_id = COALESCE(NEW.product_id, OLD.product_id)
      AND is_active = true
    ON CONFLICT (branch_id, product_id) 
    DO UPDATE SET 
        stock_balance = EXCLUDED.stock_balance,
        last_updated = EXCLUDED.last_updated;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 4. Apply triggers to branch_inventory (Remove then re-add for safety)
DROP TRIGGER IF EXISTS trg_sync_stock_balance ON branch_inventory;
CREATE TRIGGER trg_sync_stock_balance
AFTER INSERT OR UPDATE OR DELETE ON branch_inventory
FOR EACH ROW EXECUTE FUNCTION sync_product_stock_balance();

-- 5. Helper for purchase order sequences
CREATE TABLE IF NOT EXISTS purchase_sequences (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE,
    branch_id UUID REFERENCES branches(id) ON DELETE CASCADE,
    last_serial INTEGER DEFAULT 0,
    UNIQUE(tenant_id, branch_id)
);

-- Enable RLS for the new tables
ALTER TABLE product_stock_balance ENABLE ROW LEVEL SECURITY;
ALTER TABLE purchase_sequences ENABLE ROW LEVEL SECURITY;

-- Product Stock Balance Policies  (Grant ALL to branch members via trigger or direct if needed)
DROP POLICY IF EXISTS "Users can manage stock balance for their branch" ON product_stock_balance;
CREATE POLICY "Users can manage stock balance for their branch" 
ON product_stock_balance FOR ALL
USING (branch_id IN (SELECT branch_id FROM users WHERE id = auth.uid()))
WITH CHECK (branch_id IN (SELECT branch_id FROM users WHERE id = auth.uid()));

-- Purchase Sequences Policies
DROP POLICY IF EXISTS "Users can manage purchase sequences for their branch" ON purchase_sequences;
CREATE POLICY "Users can manage purchase sequences for their branch" 
ON purchase_sequences FOR ALL
USING (branch_id IN (SELECT branch_id FROM users WHERE id = auth.uid()))
WITH CHECK (branch_id IN (SELECT branch_id FROM users WHERE id = auth.uid()));
