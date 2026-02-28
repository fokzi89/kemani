-- ============================================================
-- Migration: Add Reserved Quantity to Branch Inventory
-- ============================================================
-- Purpose: Support inventory reservation for pending orders
-- Context: When orders are placed, inventory is reserved
--          but not deducted until payment is confirmed
-- Date: 2026-02-28
-- Note: Works with branch_inventory table (stock is per-branch)

-- ============================================================
-- Step 1: Add reserved_quantity column to branch_inventory table
-- ============================================================

ALTER TABLE branch_inventory
ADD COLUMN IF NOT EXISTS reserved_quantity INTEGER NOT NULL DEFAULT 0 CHECK (reserved_quantity >= 0);

-- ============================================================
-- Step 2: Add constraint to ensure available stock
-- ============================================================

-- Available stock = stock_quantity - reserved_quantity
-- We need to ensure stock_quantity >= reserved_quantity at all times

ALTER TABLE branch_inventory
DROP CONSTRAINT IF EXISTS check_stock_available;

ALTER TABLE branch_inventory
ADD CONSTRAINT check_stock_available
CHECK (stock_quantity >= reserved_quantity);

-- ============================================================
-- Step 3: Create index for querying available stock
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_branch_inventory_available_stock
ON branch_inventory(tenant_id, branch_id, (stock_quantity - reserved_quantity));

-- This index helps queries like:
-- SELECT * FROM branch_inventory WHERE (stock_quantity - reserved_quantity) > 0

-- ============================================================
-- Step 4: Create helper function to get available stock
-- ============================================================

CREATE OR REPLACE FUNCTION get_available_stock(
    p_branch_id UUID,
    p_product_id UUID
)
RETURNS INTEGER AS $$
DECLARE
    v_available INTEGER;
BEGIN
    SELECT stock_quantity - reserved_quantity
    INTO v_available
    FROM branch_inventory
    WHERE branch_id = p_branch_id
      AND product_id = p_product_id;

    RETURN COALESCE(v_available, 0);
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- Step 5: Create function to reserve inventory
-- ============================================================

CREATE OR REPLACE FUNCTION reserve_inventory(
    p_branch_id UUID,
    p_product_id UUID,
    p_quantity INTEGER
)
RETURNS BOOLEAN AS $$
DECLARE
    v_available INTEGER;
    v_rows_updated INTEGER;
BEGIN
    -- Check if enough stock is available
    v_available := get_available_stock(p_branch_id, p_product_id);

    IF v_available < p_quantity THEN
        -- Not enough stock available
        RETURN FALSE;
    END IF;

    -- Reserve the inventory
    UPDATE branch_inventory
    SET
        reserved_quantity = reserved_quantity + p_quantity,
        updated_at = NOW()
    WHERE
        branch_id = p_branch_id
        AND product_id = p_product_id
        AND (stock_quantity - reserved_quantity) >= p_quantity;

    GET DIAGNOSTICS v_rows_updated = ROW_COUNT;

    RETURN v_rows_updated > 0;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- Step 6: Create function to release reserved inventory
-- ============================================================

CREATE OR REPLACE FUNCTION release_reserved_inventory(
    p_branch_id UUID,
    p_product_id UUID,
    p_quantity INTEGER
)
RETURNS BOOLEAN AS $$
DECLARE
    v_rows_updated INTEGER;
BEGIN
    -- Release the reserved inventory
    UPDATE branch_inventory
    SET
        reserved_quantity = GREATEST(reserved_quantity - p_quantity, 0),
        updated_at = NOW()
    WHERE
        branch_id = p_branch_id
        AND product_id = p_product_id
        AND reserved_quantity >= p_quantity;

    GET DIAGNOSTICS v_rows_updated = ROW_COUNT;

    RETURN v_rows_updated > 0;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- Step 7: Create function to confirm reservation (deduct stock)
-- ============================================================

CREATE OR REPLACE FUNCTION confirm_reservation(
    p_branch_id UUID,
    p_product_id UUID,
    p_quantity INTEGER
)
RETURNS BOOLEAN AS $$
DECLARE
    v_rows_updated INTEGER;
BEGIN
    -- Deduct from both stock_quantity and reserved_quantity
    UPDATE branch_inventory
    SET
        stock_quantity = stock_quantity - p_quantity,
        reserved_quantity = GREATEST(reserved_quantity - p_quantity, 0),
        updated_at = NOW()
    WHERE
        branch_id = p_branch_id
        AND product_id = p_product_id
        AND reserved_quantity >= p_quantity
        AND stock_quantity >= p_quantity;

    GET DIAGNOSTICS v_rows_updated = ROW_COUNT;

    RETURN v_rows_updated > 0;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- Step 8: Create trigger to update stock alerts
-- ============================================================

-- Create a function to check if product needs reorder alert
CREATE OR REPLACE FUNCTION check_reorder_alert()
RETURNS TRIGGER AS $$
DECLARE
    v_available INTEGER;
    v_product_name TEXT;
BEGIN
    -- Calculate available stock
    v_available := NEW.stock_quantity - NEW.reserved_quantity;

    -- Get product name for logging
    SELECT name INTO v_product_name
    FROM products
    WHERE id = NEW.product_id;

    -- If available stock is at or below low stock threshold, log it
    IF NEW.low_stock_threshold IS NOT NULL THEN
        IF v_available <= NEW.low_stock_threshold THEN
            -- Low stock detected
            -- Future: Insert into alerts/notifications table
            RAISE NOTICE 'Low stock alert: Product % (%) at branch % has % available (threshold: %)',
                v_product_name, NEW.product_id, NEW.branch_id, v_available, NEW.low_stock_threshold;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_check_reorder_alert ON branch_inventory;

CREATE TRIGGER trigger_check_reorder_alert
    AFTER UPDATE OF stock_quantity, reserved_quantity ON branch_inventory
    FOR EACH ROW
    WHEN (OLD.stock_quantity IS DISTINCT FROM NEW.stock_quantity
          OR OLD.reserved_quantity IS DISTINCT FROM NEW.reserved_quantity)
    EXECUTE FUNCTION check_reorder_alert();

-- ============================================================
-- Step 9: Create view for available stock analytics
-- ============================================================

CREATE OR REPLACE VIEW product_stock_status AS
SELECT
    p.id AS product_id,
    p.tenant_id,
    bi.branch_id,
    p.name AS product_name,
    p.sku,
    p.barcode,
    bi.stock_quantity,
    bi.reserved_quantity,
    (bi.stock_quantity - bi.reserved_quantity) AS available_quantity,
    bi.low_stock_threshold,
    CASE
        WHEN (bi.stock_quantity - bi.reserved_quantity) <= 0 THEN 'out_of_stock'
        WHEN bi.low_stock_threshold IS NOT NULL
             AND (bi.stock_quantity - bi.reserved_quantity) <= bi.low_stock_threshold THEN 'low_stock'
        ELSE 'in_stock'
    END AS stock_status,
    p.unit_price AS selling_price,
    p.cost_price,
    (p.cost_price * bi.stock_quantity) AS total_stock_value,
    bi.expiry_date,
    CASE
        WHEN bi.expiry_date IS NULL THEN NULL
        WHEN bi.expiry_date < CURRENT_DATE THEN 'expired'
        WHEN bi.expiry_date < (CURRENT_DATE + bi.expiry_alert_days) THEN 'expiring_soon'
        ELSE 'valid'
    END AS expiry_status,
    bi.expiry_alert_days,
    p.is_active,
    bi.created_at,
    bi.updated_at
FROM products p
INNER JOIN branch_inventory bi ON p.id = bi.product_id
WHERE p.is_active = TRUE;

-- ============================================================
-- Step 10: Enable RLS on the view (uses underlying table policies)
-- ============================================================

-- Note: Views inherit RLS from their underlying tables
-- branch_inventory and products already have RLS enabled
-- Queries on product_stock_status will automatically be tenant-scoped

-- ============================================================
-- Comments for documentation
-- ============================================================

COMMENT ON COLUMN branch_inventory.reserved_quantity IS 'Quantity reserved for pending orders (not yet paid/confirmed) at this branch';

COMMENT ON FUNCTION get_available_stock(UUID, UUID) IS 'Returns available stock (stock_quantity - reserved_quantity) for a product at a specific branch';
COMMENT ON FUNCTION reserve_inventory(UUID, UUID, INTEGER) IS 'Reserves inventory for a pending order at a branch. Returns FALSE if insufficient stock.';
COMMENT ON FUNCTION release_reserved_inventory(UUID, UUID, INTEGER) IS 'Releases reserved inventory when order is cancelled at a branch. Returns success status.';
COMMENT ON FUNCTION confirm_reservation(UUID, UUID, INTEGER) IS 'Confirms reservation by deducting from both stock_quantity and reserved_quantity at a branch. Used when order is paid.';

COMMENT ON VIEW product_stock_status IS 'Real-time view of product stock status per branch including reserved quantities and stock alerts';

-- ============================================================
-- Example Usage
-- ============================================================

/*
-- Reserve inventory when order is placed at a specific branch
SELECT reserve_inventory('branch-uuid', 'product-uuid', 5);  -- Reserve 5 units

-- Check available stock at a specific branch
SELECT get_available_stock('branch-uuid', 'product-uuid');  -- Returns: stock_quantity - reserved_quantity

-- Confirm reservation when payment succeeds
SELECT confirm_reservation('branch-uuid', 'product-uuid', 5);  -- Deducts from both stock and reserved

-- Cancel order and release reservation
SELECT release_reserved_inventory('branch-uuid', 'product-uuid', 5);  -- Adds back to available stock

-- Query products with low available stock for current tenant
SELECT * FROM product_stock_status
WHERE stock_status IN ('low_stock', 'out_of_stock')
AND tenant_id = current_tenant_id();

-- Query available stock across all branches for a product
SELECT
    p.name,
    b.name AS branch_name,
    pss.stock_quantity,
    pss.reserved_quantity,
    pss.available_quantity,
    pss.stock_status
FROM product_stock_status pss
JOIN products p ON pss.product_id = p.id
JOIN branches b ON pss.branch_id = b.id
WHERE p.id = 'product-uuid'
AND pss.tenant_id = current_tenant_id()
ORDER BY b.name;
*/
