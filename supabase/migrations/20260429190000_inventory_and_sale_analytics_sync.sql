-- ============================================================
-- Migration: Inventory and Sale Analytics Sync
-- Description: Snapshots product details into branch_inventory and 
--              updates sale_items trigger to pull generic_name from inventory.
-- ============================================================

-- 1. Ensure products table has necessary analytics columns
ALTER TABLE public.products ADD COLUMN IF NOT EXISTS unit_of_measure VARCHAR(20) DEFAULT 'piece';
ALTER TABLE public.products ADD COLUMN IF NOT EXISTS product_type TEXT;
ALTER TABLE public.products ADD COLUMN IF NOT EXISTS generic_name TEXT;
ALTER TABLE public.products ADD COLUMN IF NOT EXISTS image_url TEXT;

-- 2. Ensure branch_inventory table has snapshot columns
ALTER TABLE public.branch_inventory ADD COLUMN IF NOT EXISTS product_name TEXT;
ALTER TABLE public.branch_inventory ADD COLUMN IF NOT EXISTS sku TEXT;
ALTER TABLE public.branch_inventory ADD COLUMN IF NOT EXISTS barcode TEXT;
ALTER TABLE public.branch_inventory ADD COLUMN IF NOT EXISTS product_type TEXT;
ALTER TABLE public.branch_inventory ADD COLUMN IF NOT EXISTS generic_name TEXT;
ALTER TABLE public.branch_inventory ADD COLUMN IF NOT EXISTS unit_of_measure TEXT;
ALTER TABLE public.branch_inventory ADD COLUMN IF NOT EXISTS image_url TEXT;

-- 3. Ensure sale_items table has location snapshot columns
ALTER TABLE public.sale_items ADD COLUMN IF NOT EXISTS city VARCHAR(100);
ALTER TABLE public.sale_items ADD COLUMN IF NOT EXISTS state VARCHAR(100);
ALTER TABLE public.sale_items ADD COLUMN IF NOT EXISTS country VARCHAR(100);

-- 4. Inventory Trigger Function: Populate snapshots from products
CREATE OR REPLACE FUNCTION populate_branch_inventory_details()
RETURNS TRIGGER AS $$
DECLARE
    r_prod RECORD;
BEGIN
    SELECT name, barcode as sku, barcode, product_type, generic_name, unit_of_measure, image_url
    INTO r_prod
    FROM public.products WHERE id = NEW.product_id;

    IF r_prod IS NOT NULL THEN
        NEW.product_name := COALESCE(NEW.product_name, r_prod.name);
        NEW.sku := COALESCE(NEW.sku, r_prod.sku);
        NEW.barcode := COALESCE(NEW.barcode, r_prod.barcode);
        NEW.product_type := COALESCE(NEW.product_type, r_prod.product_type);
        NEW.unit_of_measure := COALESCE(NEW.unit_of_measure, r_prod.unit_of_measure);
        NEW.image_url := COALESCE(NEW.image_url, r_prod.image_url);
        
        -- Capture generic_name only if it's a drug/medication
        IF r_prod.product_type IN ('drug', 'medication') THEN
            NEW.generic_name := COALESCE(NEW.generic_name, r_prod.generic_name);
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_populate_branch_inventory_details ON public.branch_inventory;
CREATE TRIGGER trg_populate_branch_inventory_details
    BEFORE INSERT ON public.branch_inventory
    FOR EACH ROW
    EXECUTE FUNCTION populate_branch_inventory_details();

COMMENT ON FUNCTION populate_branch_inventory_details() IS 'Auto-populates product snapshots in branch_inventory';


-- 2. Update Sale Item Trigger Function: Pull generic_name from inventory snapshots
CREATE OR REPLACE FUNCTION populate_sale_item_details()
RETURNS TRIGGER AS $$
DECLARE
    r_prod RECORD;
    r_inv RECORD;
    v_branch_id UUID;
    v_tenant_id UUID;
    v_customer_id UUID;
    v_cashier_id UUID;
    v_customer_name TEXT;
    v_cashier_name TEXT;
    v_provider_name TEXT;
BEGIN
    -- 1. Get snapshot details from Branch Inventory if inventory_id is provided
    IF NEW.inventory_id IS NOT NULL THEN
        SELECT product_id, product_name, sku, barcode, product_type, generic_name, selling_price, cost_price
        INTO r_inv
        FROM public.branch_inventory WHERE id = NEW.inventory_id;
        
        IF r_inv IS NOT NULL THEN
            NEW.product_id := COALESCE(NEW.product_id, r_inv.product_id);
            NEW.product_name := COALESCE(NEW.product_name, r_inv.product_name);
            NEW.product_sku := COALESCE(NEW.product_sku, r_inv.sku);
            NEW.generic_name := COALESCE(NEW.generic_name, r_inv.generic_name);
            NEW.unit_cost := COALESCE(NEW.unit_cost, CAST(r_inv.cost_price AS NUMERIC));
        END IF;
    END IF;

    -- 2. Fallback to products catalog if details are still missing (e.g. non-inventory items)
    IF NEW.product_name IS NULL OR (NEW.generic_name IS NULL AND NEW.product_id IS NOT NULL) THEN
        SELECT p.name, p.barcode as sku, p.category_id, c.name as category_name, p.generic_name, p.product_type
        INTO r_prod
        FROM public.products p
        LEFT JOIN public.categories c ON c.id = p.category_id
        WHERE p.id = NEW.product_id;

        IF r_prod IS NOT NULL THEN
            NEW.product_name := COALESCE(NEW.product_name, r_prod.name);
            NEW.product_sku := COALESCE(NEW.product_sku, r_prod.sku);
            NEW.category_id := COALESCE(NEW.category_id, r_prod.category_id);
            NEW.category_name := COALESCE(NEW.category_name, r_prod.category_name);
            
            -- Only pull generic_name if it's a drug and we don't have it yet
            IF NEW.generic_name IS NULL AND r_prod.product_type IN ('drug', 'medication') THEN
                NEW.generic_name := r_prod.generic_name;
            END IF;
        END IF;
    END IF;

    -- 3. Get transaction context from Sale or Order if IDs are missing in NEW
    IF NEW.sale_id IS NOT NULL THEN
        SELECT 
            branch_id, tenant_id, customer_id, cashier_id, customer_name
        INTO 
            v_branch_id, v_tenant_id, v_customer_id, v_cashier_id, v_customer_name
        FROM public.sales WHERE id = NEW.sale_id;
    ELSIF NEW.order_id IS NOT NULL THEN
        SELECT 
            branch_id, tenant_id, customer_id
        INTO 
            v_branch_id, v_tenant_id, v_customer_id
        FROM public.orders WHERE id = NEW.order_id;
    END IF;

    -- 4. Consolidate IDs (Priority: NEW > Context from Sale/Order)
    NEW.tenant_id := COALESCE(NEW.tenant_id, v_tenant_id);
    NEW.branch_id := COALESCE(NEW.branch_id, v_branch_id);
    NEW.customer_id := COALESCE(NEW.customer_id, v_customer_id);
    NEW.cashier_id := COALESCE(NEW.cashier_id, v_cashier_id);

    -- 5. Fetch Names for the consolidated IDs
    -- Customer Name
    IF NEW.customer_name IS NULL THEN
        IF NEW.customer_id IS NOT NULL THEN
            SELECT full_name INTO v_customer_name FROM public.customers WHERE id = NEW.customer_id;
            NEW.customer_name := v_customer_name;
        END IF;
        IF NEW.customer_name IS NULL THEN
            NEW.customer_name := v_customer_name; 
        END IF;
    END IF;

    -- Cashier Name
    IF NEW.cashier_name IS NULL AND NEW.cashier_id IS NOT NULL THEN
        SELECT full_name INTO v_cashier_name FROM public.users WHERE id = NEW.cashier_id;
        NEW.cashier_name := v_cashier_name;
    END IF;

    -- Healthcare Provider Name
    IF NEW.healthcare_provider_name IS NULL AND NEW.health_care_provider IS NOT NULL THEN
        SELECT full_name INTO v_provider_name FROM public.healthcare_providers WHERE id = NEW.health_care_provider;
        NEW.healthcare_provider_name := v_provider_name;
    END IF;

    -- 6. Cost & Profit Calculation
    IF NEW.unit_cost IS NOT NULL THEN
        NEW.total_cost := NEW.unit_cost * NEW.quantity;
        NEW.gross_profit := NEW.subtotal - NEW.total_cost;
        IF NEW.subtotal > 0 THEN
            NEW.profit_margin := (NEW.gross_profit / NEW.subtotal) * 100;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
