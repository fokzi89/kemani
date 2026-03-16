-- ============================================================
-- Migration: Real-Time Inventory Sync for Marketplace
-- ============================================================
-- Purpose: Automatically sync inventory between POS sales and marketplace
-- Context: When orders are placed through marketplace or POS,
--          inventory should automatically update in real-time
-- Date: 2026-03-10
-- Tasks: T110 - Real-time inventory sync

-- ============================================================
-- Step 1: Create function to sync product stock from branch_inventory
-- ============================================================

-- This function updates products.stock_quantity based on branch_inventory
-- Useful for displaying aggregate stock across all branches
CREATE OR REPLACE FUNCTION sync_product_total_stock(p_product_id UUID)
RETURNS VOID AS $$
DECLARE
    v_total_stock INTEGER;
BEGIN
    -- Calculate total available stock across all branches
    SELECT COALESCE(SUM(stock_quantity - reserved_quantity), 0)
    INTO v_total_stock
    FROM branch_inventory
    WHERE product_id = p_product_id;

    -- Update the product's stock_quantity
    UPDATE products
    SET
        stock_quantity = v_total_stock,
        updated_at = NOW()
    WHERE id = p_product_id;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION sync_product_total_stock(UUID) IS 'Syncs product total stock from all branch inventories';

-- ============================================================
-- Step 2: Create trigger to auto-sync when branch inventory changes
-- ============================================================

CREATE OR REPLACE FUNCTION trigger_sync_product_stock()
RETURNS TRIGGER AS $$
BEGIN
    -- Sync the product stock when branch inventory changes
    PERFORM sync_product_total_stock(COALESCE(NEW.product_id, OLD.product_id));
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop existing trigger if it exists
DROP TRIGGER IF EXISTS auto_sync_product_stock ON branch_inventory;

-- Create trigger for INSERT, UPDATE, DELETE on branch_inventory
CREATE TRIGGER auto_sync_product_stock
    AFTER INSERT OR UPDATE OR DELETE ON branch_inventory
    FOR EACH ROW
    EXECUTE FUNCTION trigger_sync_product_stock();

COMMENT ON TRIGGER auto_sync_product_stock ON branch_inventory IS 'Automatically syncs product.stock_quantity when branch_inventory changes';

-- ============================================================
-- Step 3: Create function to handle order item inventory deduction
-- ============================================================

CREATE OR REPLACE FUNCTION deduct_inventory_on_order_confirm(
    p_order_id UUID
)
RETURNS BOOLEAN AS $$
DECLARE
    v_branch_id UUID;
    v_item RECORD;
    v_success BOOLEAN;
BEGIN
    -- Get the branch_id from the order
    SELECT branch_id INTO v_branch_id
    FROM orders
    WHERE id = p_order_id;

    IF v_branch_id IS NULL THEN
        RAISE EXCEPTION 'Order not found or branch_id is null: %', p_order_id;
    END IF;

    -- Loop through all order items and confirm reservations
    FOR v_item IN
        SELECT product_id, quantity
        FROM order_items
        WHERE order_id = p_order_id
    LOOP
        -- Confirm the reservation (deducts from stock and reserved)
        v_success := confirm_reservation(v_branch_id, v_item.product_id, v_item.quantity);

        IF NOT v_success THEN
            RAISE EXCEPTION 'Failed to confirm reservation for product % in order %',
                v_item.product_id, p_order_id;
        END IF;
    END LOOP;

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION deduct_inventory_on_order_confirm(UUID) IS 'Deducts inventory from branch stock when order is confirmed/paid';

-- ============================================================
-- Step 4: Create function to restore inventory on order cancellation
-- ============================================================

CREATE OR REPLACE FUNCTION restore_inventory_on_order_cancel(
    p_order_id UUID
)
RETURNS BOOLEAN AS $$
DECLARE
    v_branch_id UUID;
    v_order_status TEXT;
    v_item RECORD;
    v_success BOOLEAN;
BEGIN
    -- Get the order details
    SELECT branch_id, order_status INTO v_branch_id, v_order_status
    FROM orders
    WHERE id = p_order_id;

    IF v_branch_id IS NULL THEN
        RAISE EXCEPTION 'Order not found: %', p_order_id;
    END IF;

    -- Loop through all order items
    FOR v_item IN
        SELECT product_id, quantity
        FROM order_items
        WHERE order_id = p_order_id
    LOOP
        -- If order was only reserved (not confirmed), release reservation
        -- If order was confirmed (paid), add stock back
        IF v_order_status IN ('pending', 'confirmed') THEN
            -- Release reserved inventory
            v_success := release_reserved_inventory(v_branch_id, v_item.product_id, v_item.quantity);
        ELSE
            -- Order was delivered/processing, need to restore actual stock
            UPDATE branch_inventory
            SET
                stock_quantity = stock_quantity + v_item.quantity,
                updated_at = NOW()
            WHERE
                branch_id = v_branch_id
                AND product_id = v_item.product_id;

            GET DIAGNOSTICS v_success = ROW_COUNT;
            v_success := v_success > 0;
        END IF;

        IF NOT v_success THEN
            RAISE WARNING 'Failed to restore inventory for product % in order %',
                v_item.product_id, p_order_id;
        END IF;
    END LOOP;

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION restore_inventory_on_order_cancel(UUID) IS 'Restores inventory when order is cancelled';

-- ============================================================
-- Step 5: Create trigger for automatic inventory sync on order status change
-- ============================================================

CREATE OR REPLACE FUNCTION trigger_order_inventory_sync()
RETURNS TRIGGER AS $$
BEGIN
    -- When order status changes to confirmed/processing, confirm inventory reservation
    IF OLD.order_status IN ('pending') AND NEW.order_status IN ('confirmed', 'processing') THEN
        PERFORM deduct_inventory_on_order_confirm(NEW.id);
    END IF;

    -- When order is cancelled, restore inventory
    IF NEW.order_status = 'cancelled' AND OLD.order_status != 'cancelled' THEN
        PERFORM restore_inventory_on_order_cancel(NEW.id);
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop existing trigger if it exists
DROP TRIGGER IF EXISTS auto_order_inventory_sync ON orders;

-- Create trigger for order status changes
CREATE TRIGGER auto_order_inventory_sync
    AFTER UPDATE OF order_status ON orders
    FOR EACH ROW
    WHEN (OLD.order_status IS DISTINCT FROM NEW.order_status)
    EXECUTE FUNCTION trigger_order_inventory_sync();

COMMENT ON TRIGGER auto_order_inventory_sync ON orders IS 'Automatically syncs inventory when order status changes';

-- ============================================================
-- Step 6: Create function to reserve inventory when order is created
-- ============================================================

CREATE OR REPLACE FUNCTION reserve_inventory_on_order_create()
RETURNS TRIGGER AS $$
DECLARE
    v_item RECORD;
    v_success BOOLEAN;
BEGIN
    -- Only process if order status is pending (initial state)
    IF NEW.order_status = 'pending' THEN
        -- Loop through all order items and reserve inventory
        FOR v_item IN
            SELECT product_id, quantity
            FROM order_items
            WHERE order_id = NEW.id
        LOOP
            -- Reserve the inventory at the branch
            v_success := reserve_inventory(NEW.branch_id, v_item.product_id, v_item.quantity);

            IF NOT v_success THEN
                RAISE EXCEPTION 'Failed to reserve inventory for product % in order %. Not enough stock available.',
                    v_item.product_id, NEW.id;
            END IF;
        END LOOP;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop existing trigger if it exists
DROP TRIGGER IF EXISTS auto_reserve_inventory_on_order ON orders;

-- Create trigger for order creation
CREATE TRIGGER auto_reserve_inventory_on_order
    AFTER INSERT ON orders
    FOR EACH ROW
    EXECUTE FUNCTION reserve_inventory_on_order_create();

COMMENT ON TRIGGER auto_reserve_inventory_on_order ON orders IS 'Automatically reserves inventory when order is created';

-- ============================================================
-- Step 7: Create function to sync inventory on POS sale
-- ============================================================

CREATE OR REPLACE FUNCTION trigger_sync_inventory_on_sale()
RETURNS TRIGGER AS $$
DECLARE
    v_item RECORD;
BEGIN
    -- When a sale is completed, deduct inventory
    IF NEW.sale_status = 'completed' THEN
        -- Loop through sale items and deduct from branch inventory
        FOR v_item IN
            SELECT product_id, quantity
            FROM sale_items
            WHERE sale_id = NEW.id
        LOOP
            -- Deduct directly from branch inventory (POS sales are immediate)
            UPDATE branch_inventory
            SET
                stock_quantity = stock_quantity - v_item.quantity,
                updated_at = NOW()
            WHERE
                branch_id = NEW.branch_id
                AND product_id = v_item.product_id
                AND stock_quantity >= v_item.quantity;

            -- Check if update succeeded
            IF NOT FOUND THEN
                RAISE WARNING 'Failed to deduct inventory for product % in sale %. Insufficient stock.',
                    v_item.product_id, NEW.id;
            END IF;
        END LOOP;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop existing trigger if it exists
DROP TRIGGER IF EXISTS auto_sync_inventory_on_sale ON sales;

-- Create trigger for sales
CREATE TRIGGER auto_sync_inventory_on_sale
    AFTER INSERT OR UPDATE OF sale_status ON sales
    FOR EACH ROW
    WHEN (NEW.sale_status = 'completed')
    EXECUTE FUNCTION trigger_sync_inventory_on_sale();

COMMENT ON TRIGGER auto_sync_inventory_on_sale ON sales IS 'Automatically syncs inventory when POS sale is completed';

-- ============================================================
-- Step 8: Create function to get real-time marketplace stock
-- ============================================================

-- This function returns available stock for marketplace display
CREATE OR REPLACE FUNCTION get_marketplace_stock(
    p_product_id UUID,
    p_tenant_id UUID
)
RETURNS TABLE (
    product_id UUID,
    total_stock INTEGER,
    reserved_stock INTEGER,
    available_stock INTEGER,
    is_available BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        p.id AS product_id,
        COALESCE(SUM(bi.stock_quantity), 0)::INTEGER AS total_stock,
        COALESCE(SUM(bi.reserved_quantity), 0)::INTEGER AS reserved_stock,
        COALESCE(SUM(bi.stock_quantity - bi.reserved_quantity), 0)::INTEGER AS available_stock,
        COALESCE(SUM(bi.stock_quantity - bi.reserved_quantity), 0) > 0 AS is_available
    FROM products p
    LEFT JOIN branch_inventory bi ON p.id = bi.product_id
    WHERE p.id = p_product_id
      AND p.tenant_id = p_tenant_id
      AND p.is_active = TRUE
    GROUP BY p.id;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_marketplace_stock(UUID, UUID) IS 'Returns real-time stock information for marketplace display';

-- ============================================================
-- Step 9: Create view for marketplace products with stock
-- ============================================================

-- Replace or create view for marketplace with real-time stock
CREATE OR REPLACE VIEW marketplace_products_with_stock AS
SELECT
    p.id,
    p.tenant_id,
    p.name,
    p.description,
    p.sku,
    p.barcode,
    p.category,
    p.unit_price AS price,
    p.image_url,
    COALESCE(SUM(bi.stock_quantity - bi.reserved_quantity), 0)::INTEGER AS stock_quantity,
    COALESCE(SUM(bi.stock_quantity - bi.reserved_quantity), 0) > 0 AS is_available,
    p.created_at,
    p.updated_at
FROM products p
LEFT JOIN branch_inventory bi ON p.id = bi.product_id
WHERE p.is_active = TRUE
  AND p.deleted_at IS NULL
GROUP BY p.id, p.tenant_id, p.name, p.description, p.sku, p.barcode,
         p.category, p.unit_price, p.image_url, p.created_at, p.updated_at;

COMMENT ON VIEW marketplace_products_with_stock IS 'Real-time marketplace products with aggregated available stock across branches';

-- ============================================================
-- Step 10: Create RPC function for marketplace API
-- ============================================================

-- This function can be called from the frontend for real-time stock checks
CREATE OR REPLACE FUNCTION check_product_availability(
    p_product_id UUID,
    p_quantity INTEGER,
    p_tenant_id UUID DEFAULT NULL
)
RETURNS JSON AS $$
DECLARE
    v_available INTEGER;
    v_tenant_id UUID;
    v_result JSON;
BEGIN
    -- Get tenant_id if not provided
    IF p_tenant_id IS NULL THEN
        SELECT tenant_id INTO v_tenant_id
        FROM products
        WHERE id = p_product_id;
    ELSE
        v_tenant_id := p_tenant_id;
    END IF;

    -- Get available stock
    SELECT available_stock INTO v_available
    FROM get_marketplace_stock(p_product_id, v_tenant_id);

    -- Build result
    v_result := json_build_object(
        'product_id', p_product_id,
        'available_stock', COALESCE(v_available, 0),
        'requested_quantity', p_quantity,
        'is_available', COALESCE(v_available, 0) >= p_quantity,
        'message', CASE
            WHEN COALESCE(v_available, 0) >= p_quantity THEN 'Product available'
            WHEN COALESCE(v_available, 0) > 0 THEN format('Only %s units available', v_available)
            ELSE 'Product out of stock'
        END
    );

    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION check_product_availability(UUID, INTEGER, UUID) IS 'Checks if product has sufficient stock for purchase (callable from API)';

-- ============================================================
-- Step 11: Initial sync of existing data
-- ============================================================

-- Sync all existing products with their branch inventory
DO $$
DECLARE
    v_product RECORD;
BEGIN
    FOR v_product IN SELECT DISTINCT id FROM products WHERE is_active = TRUE
    LOOP
        PERFORM sync_product_total_stock(v_product.id);
    END LOOP;
END $$;

-- ============================================================
-- Step 12: Create index for performance
-- ============================================================

-- Index for faster marketplace queries
CREATE INDEX IF NOT EXISTS idx_products_marketplace
ON products(tenant_id, is_active, deleted_at)
WHERE is_active = TRUE AND deleted_at IS NULL;

-- Index for order items lookup
CREATE INDEX IF NOT EXISTS idx_order_items_order_product
ON order_items(order_id, product_id);

-- Index for sale items lookup
CREATE INDEX IF NOT EXISTS idx_sale_items_sale_product
ON sale_items(sale_id, product_id);

-- ============================================================
-- Summary and Usage Examples
-- ============================================================

/*
REAL-TIME INVENTORY SYNC IMPLEMENTATION

This migration implements automatic inventory synchronization between:
1. POS sales → Branch inventory → Marketplace stock
2. Marketplace orders → Branch inventory → Product stock
3. Order cancellations → Inventory restoration

KEY FEATURES:
- Automatic inventory reservation when orders are placed
- Automatic inventory deduction when orders are confirmed/paid
- Automatic inventory restoration when orders are cancelled
- Real-time stock sync across all branches
- POS sales automatically update marketplace stock

TRIGGERS CREATED:
1. auto_sync_product_stock - Syncs product.stock_quantity from branch_inventory
2. auto_reserve_inventory_on_order - Reserves inventory when order is created
3. auto_order_inventory_sync - Syncs inventory on order status changes
4. auto_sync_inventory_on_sale - Syncs inventory when POS sale completes

USAGE EXAMPLES:

-- Check product availability for marketplace
SELECT * FROM check_product_availability(
    'product-uuid',
    5,  -- quantity
    'tenant-uuid'
);

-- Get real-time marketplace stock
SELECT * FROM get_marketplace_stock('product-uuid', 'tenant-uuid');

-- View all marketplace products with stock
SELECT * FROM marketplace_products_with_stock
WHERE tenant_id = 'tenant-uuid'
  AND is_available = TRUE
ORDER BY name;

-- Manual sync (usually not needed, triggers handle this)
SELECT sync_product_total_stock('product-uuid');

WORKFLOW:
1. Customer places order → inventory reserved
2. Customer pays → inventory deducted from stock
3. Order delivered → status updated, inventory already deducted
4. Customer cancels → inventory restored based on order status

POS SALES:
1. Sale completed → inventory deducted immediately
2. Stock synced → marketplace updated in real-time
*/
