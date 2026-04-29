-- ============================================================
-- Migration: Update Sale Item Population Logic
-- Description: Updates the populate_sale_item_details function to fetch and snapshot
--              city, state, country (from branch) and generic_name (from product).
-- ============================================================

CREATE OR REPLACE FUNCTION populate_sale_item_details()
RETURNS TRIGGER AS $$
DECLARE
    r_prod RECORD;
    v_branch_id UUID;
    v_tenant_id UUID;
    v_customer_id UUID;
    v_cashier_id UUID;
    v_customer_name TEXT;
    v_cashier_name TEXT;
    v_provider_name TEXT;
    v_city TEXT;
    v_state TEXT;
    v_country TEXT;
BEGIN
    -- 1. Get product details from catalog (including generic_name)
    SELECT p.name, p.barcode as sku, p.category_id, c.name as category_name, p.generic_name
    INTO r_prod
    FROM public.products p
    LEFT JOIN public.categories c ON c.id = p.category_id
    WHERE p.id = NEW.product_id;

    -- 2. Get transaction context from Sale or Order if IDs are missing in NEW
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

    -- 3. Consolidate IDs (Priority: NEW > Context from Sale/Order)
    NEW.tenant_id := COALESCE(NEW.tenant_id, v_tenant_id);
    NEW.branch_id := COALESCE(NEW.branch_id, v_branch_id);
    NEW.customer_id := COALESCE(NEW.customer_id, v_customer_id);
    NEW.cashier_id := COALESCE(NEW.cashier_id, v_cashier_id);

    -- 4. Fetch Names and Locations for the consolidated IDs
    -- Customer Name
    IF NEW.customer_name IS NULL THEN
        IF NEW.customer_id IS NOT NULL THEN
            SELECT full_name INTO v_customer_name FROM public.customers WHERE id = NEW.customer_id;
            NEW.customer_name := v_customer_name;
        END IF;
        -- Fallback to the name on the sale record if customer_id doesn't yield a name (e.g. walk-in)
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

    -- Location Details (from branch)
    IF (NEW.city IS NULL OR NEW.state IS NULL OR NEW.country IS NULL) AND NEW.branch_id IS NOT NULL THEN
        SELECT city, state, country 
        INTO v_city, v_state, v_country 
        FROM public.branches 
        WHERE id = NEW.branch_id;
        
        NEW.city := COALESCE(NEW.city, v_city);
        NEW.state := COALESCE(NEW.state, v_state);
        NEW.country := COALESCE(NEW.country, v_country);
    END IF;

    -- 5. Populate metadata snapshots for product
    IF r_prod IS NOT NULL THEN
        NEW.product_name := COALESCE(NEW.product_name, r_prod.name);
        NEW.product_sku := COALESCE(NEW.product_sku, r_prod.sku);
        NEW.category_id := COALESCE(NEW.category_id, r_prod.category_id);
        NEW.category_name := COALESCE(NEW.category_name, r_prod.category_name);
        NEW.generic_name := COALESCE(NEW.generic_name, r_prod.generic_name);
        NEW.unit_of_measure := COALESCE(NEW.unit_of_measure, 'piece');

        -- 5b. Fetch unit_cost from branch_inventory if missing
        IF NEW.unit_cost IS NULL AND NEW.inventory_id IS NOT NULL THEN
            SELECT cost_price INTO NEW.unit_cost FROM public.branch_inventory WHERE id = NEW.inventory_id;
        END IF;
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

COMMENT ON FUNCTION populate_sale_item_details IS 'Trigger function to auto-populate product snapshot details, location context, and names in sale_items';
