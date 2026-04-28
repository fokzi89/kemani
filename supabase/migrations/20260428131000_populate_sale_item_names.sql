-- ============================================================
-- Migration: Populate Sale Item Names
-- Description: Updates the populate_sale_item_details function to fetch and snapshot
--              customer_name, cashier_name, and healthcare_provider_name.
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
BEGIN
    -- 1. Get product details from catalog
    SELECT p.name, p.sku, p.category_id, c.name as category_name, p.cost_price, p.unit_of_measure
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

    -- 4. Fetch Names for the consolidated IDs if they aren't already provided in NEW
    -- Customer Name
    IF NEW.customer_name IS NULL THEN
        IF NEW.customer_id IS NOT NULL THEN
            SELECT full_name INTO v_customer_name FROM public.customers WHERE id = NEW.customer_id;
            NEW.customer_name := v_customer_name;
        END IF;
        -- Fallback to the name on the sale record if customer_id doesn't yield a name (e.g. walk-in)
        IF NEW.customer_name IS NULL THEN
            NEW.customer_name := v_customer_name; -- This v_customer_name came from the sales table SELECT above
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

    -- 5. Populate metadata snapshots for product
    IF r_prod IS NOT NULL THEN
        NEW.product_name := COALESCE(NEW.product_name, r_prod.name);
        NEW.product_sku := COALESCE(NEW.product_sku, r_prod.sku);
        NEW.category_id := COALESCE(NEW.category_id, r_prod.category_id);
        NEW.category_name := COALESCE(NEW.category_name, r_prod.category_name);
        NEW.unit_of_measure := COALESCE(NEW.unit_of_measure, r_prod.unit_of_measure, 'piece');

        IF NEW.unit_cost IS NULL AND r_prod.cost_price IS NOT NULL THEN
            NEW.unit_cost := r_prod.cost_price;
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
