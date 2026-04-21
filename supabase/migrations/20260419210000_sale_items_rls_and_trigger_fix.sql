-- ============================================================
-- Migration: RLS Policies and Corrected Trigger for Unified sale_items
-- Description: Adds RLS policies for the recreated sale_items table
--              and corrects the populate_sale_item_details trigger to
--              match the actual live products table schema.
-- ============================================================

-- 1. Enable RLS
ALTER TABLE public.sale_items ENABLE ROW LEVEL SECURITY;

-- 2. INSERT — any authenticated user of the same tenant
CREATE POLICY "sale_items_insert_own_tenant"
ON public.sale_items FOR INSERT TO authenticated
WITH CHECK (
    tenant_id IN (SELECT tenant_id FROM public.users WHERE id = auth.uid())
);

-- 3. SELECT — any authenticated user of the same tenant
CREATE POLICY "sale_items_select_own_tenant"
ON public.sale_items FOR SELECT TO authenticated
USING (
    tenant_id IN (SELECT tenant_id FROM public.users WHERE id = auth.uid())
);

-- 4. UPDATE — any authenticated user of the same tenant
CREATE POLICY "sale_items_update_own_tenant"
ON public.sale_items FOR UPDATE TO authenticated
USING (
    tenant_id IN (SELECT tenant_id FROM public.users WHERE id = auth.uid())
);

-- 5. DELETE — tenant admins and managers only
CREATE POLICY "sale_items_delete_managers"
ON public.sale_items FOR DELETE TO authenticated
USING (
    tenant_id IN (
        SELECT tenant_id FROM public.users
        WHERE id = auth.uid()
        AND role IN ('tenant_admin', 'branch_manager', 'platform_admin')
    )
);

-- 6. Corrected trigger function — matches actual live products table schema
--    (products has: name, barcode, category_id — NO sku, cost_price, unit_of_measure)
CREATE OR REPLACE FUNCTION populate_sale_item_details()
RETURNS TRIGGER AS $$
DECLARE
    v_prod_name     VARCHAR;
    v_prod_barcode  VARCHAR;
    v_prod_cat_id   UUID;
    v_prod_cat_name VARCHAR;
    v_branch_id     UUID;
    v_tenant_id     UUID;
BEGIN
    v_prod_name    := (SELECT p.name        FROM public.products p WHERE p.id = NEW.product_id LIMIT 1);
    v_prod_barcode := (SELECT p.barcode     FROM public.products p WHERE p.id = NEW.product_id LIMIT 1);
    v_prod_cat_id  := (SELECT p.category_id FROM public.products p WHERE p.id = NEW.product_id LIMIT 1);

    IF v_prod_cat_id IS NOT NULL THEN
        v_prod_cat_name := (SELECT c.name FROM public.categories c WHERE c.id = v_prod_cat_id LIMIT 1);
    END IF;

    IF NEW.sale_id IS NOT NULL THEN
        v_branch_id := (SELECT s.branch_id FROM public.sales s WHERE s.id = NEW.sale_id LIMIT 1);
        v_tenant_id := (SELECT s.tenant_id FROM public.sales s WHERE s.id = NEW.sale_id LIMIT 1);
    ELSIF NEW.order_id IS NOT NULL THEN
        v_branch_id := (SELECT o.branch_id FROM public.orders o WHERE o.id = NEW.order_id LIMIT 1);
        v_tenant_id := (SELECT o.tenant_id FROM public.orders o WHERE o.id = NEW.order_id LIMIT 1);
    END IF;

    NEW.tenant_id       := COALESCE(NEW.tenant_id,       v_tenant_id);
    NEW.branch_id       := COALESCE(NEW.branch_id,       v_branch_id);
    NEW.product_name    := COALESCE(NEW.product_name,    v_prod_name);
    NEW.product_sku     := COALESCE(NEW.product_sku,     v_prod_barcode);
    NEW.category_id     := COALESCE(NEW.category_id,     v_prod_cat_id);
    NEW.category_name   := COALESCE(NEW.category_name,   v_prod_cat_name);
    NEW.unit_of_measure := COALESCE(NEW.unit_of_measure, 'piece');

    -- Cost & profit only if unit_cost is explicitly provided
    IF NEW.unit_cost IS NOT NULL THEN
        NEW.total_cost    := NEW.unit_cost * NEW.quantity;
        NEW.gross_profit  := NEW.subtotal - NEW.total_cost;
        IF NEW.subtotal > 0 THEN
            NEW.profit_margin := (NEW.gross_profit / NEW.subtotal) * 100;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
