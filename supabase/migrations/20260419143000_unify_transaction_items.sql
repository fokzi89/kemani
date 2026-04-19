-- ============================================================
-- Migration: Unify Order and Sale Items with Analytics (FINAL VERIFIED)
-- Description: Recreates sale_items with granular analytics and drops order_items.
-- Optimized for: PostgreSQL compatibility and SQL Editor runners.
-- ============================================================

-- 1. CLEANUP: Drop old tables and all their dependencies
DROP TABLE IF EXISTS public.order_items CASCADE;
DROP TABLE IF EXISTS public.sale_items CASCADE;

-- 2. CREATE: Create the Unified sale_items Table
CREATE TABLE public.sale_items (
  id uuid NOT NULL DEFAULT extensions.uuid_generate_v4 (),
  tenant_id uuid NOT NULL,
  sale_id uuid NULL, 
  order_id uuid NULL, 
  inventory_id uuid NULL, 
  product_id uuid NOT NULL,
  product_name character varying(255) NOT NULL,
  product_sku character varying(100) NULL,
  category_id uuid NULL,
  category_name character varying(255) NULL,
  quantity integer NOT NULL,
  unit_of_measure character varying(20) NULL DEFAULT 'piece'::character varying,
  strength text NULL,
  
  -- Price & Discount
  unit_price numeric(12, 2) NOT NULL,
  original_price numeric(15, 2) NULL,
  discount_percent numeric(5, 2) NULL DEFAULT 0,
  discount_amount numeric(12, 2) NULL DEFAULT 0,
  discount_percentage numeric(5, 2) NULL DEFAULT 0,
  discount_type character varying(50) NULL,
  discount_code character varying(50) NULL,
  
  -- Tax
  tax_percentage numeric(5, 2) NULL DEFAULT 0,
  tax_amount numeric(15, 2) NULL DEFAULT 0,
  
  -- Totals
  subtotal numeric(12, 2) NOT NULL,
  
  -- Cost & Profit
  unit_cost numeric(15, 2) NULL,
  total_cost numeric(15, 2) NULL,
  gross_profit numeric(15, 2) NULL,
  profit_margin numeric(5, 2) NULL,
  
  -- Context
  branch_id uuid NULL,
  cashier_id uuid NULL,
  health_care_provider uuid NULL,
  customer_id uuid NULL,
  
  -- Audit
  sale_date timestamp with time zone NOT NULL DEFAULT now(),
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  
  -- Generated Analytics Columns (Stored for performance)
  sale_hour integer GENERATED ALWAYS AS (EXTRACT(HOUR FROM (sale_date AT TIME ZONE 'UTC'))) STORED,
  sale_day integer GENERATED ALWAYS AS (EXTRACT(DAY FROM (sale_date AT TIME ZONE 'UTC'))) STORED,
  sale_week integer GENERATED ALWAYS AS (EXTRACT(WEEK FROM (sale_date AT TIME ZONE 'UTC'))) STORED,
  sale_month integer GENERATED ALWAYS AS (EXTRACT(MONTH FROM (sale_date AT TIME ZONE 'UTC'))) STORED,
  sale_quarter integer GENERATED ALWAYS AS (EXTRACT(QUARTER FROM (sale_date AT TIME ZONE 'UTC'))) STORED,
  sale_year integer GENERATED ALWAYS AS (EXTRACT(YEAR FROM (sale_date AT TIME ZONE 'UTC'))) STORED,

  -- Primary Key
  PRIMARY KEY (id),
  
  -- Foreign Keys
  FOREIGN KEY (tenant_id) REFERENCES tenants (id) ON DELETE CASCADE,
  FOREIGN KEY (sale_id) REFERENCES sales (id) ON DELETE CASCADE,
  FOREIGN KEY (order_id) REFERENCES orders (id) ON DELETE CASCADE,
  FOREIGN KEY (product_id) REFERENCES products (id),
  FOREIGN KEY (inventory_id) REFERENCES branch_inventory (id),
  FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE SET NULL,
  FOREIGN KEY (branch_id) REFERENCES branches (id),
  FOREIGN KEY (cashier_id) REFERENCES users (id),
  FOREIGN KEY (customer_id) REFERENCES customers (id),
  FOREIGN KEY (health_care_provider) REFERENCES healthcare_providers (id),
  
  -- Validations
  CHECK (quantity > 0),
  CHECK (unit_price > 0),
  CHECK (subtotal >= 0),
  CONSTRAINT valid_subtotal_logic CHECK (subtotal = (unit_price * quantity) - discount_amount)
) TABLESPACE pg_default;

-- 3. INDEXES: Create Performance Indices
CREATE INDEX IF NOT EXISTS idx_sale_items_tenant_final ON public.sale_items(tenant_id);
CREATE INDEX IF NOT EXISTS idx_sale_items_branch_final ON public.sale_items(branch_id);
CREATE INDEX IF NOT EXISTS idx_sale_items_created_at_final ON public.sale_items(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_sale_items_category_final ON public.sale_items(category_id) WHERE (category_id IS NOT NULL);
CREATE INDEX IF NOT EXISTS idx_sale_items_product_final ON public.sale_items(product_id);
CREATE INDEX IF NOT EXISTS idx_sale_items_sale_order_final ON public.sale_items(sale_id, order_id);

-- 4. LOGIC: Update Populate Details Function
CREATE OR REPLACE FUNCTION populate_sale_item_details()
RETURNS TRIGGER AS $$
DECLARE
    r_prod RECORD;
    v_branch_id UUID;
    v_tenant_id UUID;
BEGIN
    -- Get product details from catalog
    SELECT p.name, p.sku, p.category_id, c.name as category_name, p.cost_price, p.unit_of_measure
    INTO r_prod
    FROM public.products p
    LEFT JOIN public.categories c ON c.id = p.category_id
    WHERE p.id = NEW.product_id;

    -- Get transaction context from Sale or Order
    IF NEW.sale_id IS NOT NULL THEN
        SELECT branch_id, tenant_id INTO v_branch_id, v_tenant_id FROM public.sales WHERE id = NEW.sale_id;
    ELSIF NEW.order_id IS NOT NULL THEN
        SELECT branch_id, tenant_id INTO v_branch_id, v_tenant_id FROM public.orders WHERE id = NEW.order_id;
    END IF;

    -- Populate metadata snapshots if product found
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

    -- Populate tenant and branch
    NEW.tenant_id := COALESCE(NEW.tenant_id, v_tenant_id);
    NEW.branch_id := COALESCE(NEW.branch_id, v_branch_id);

    -- Cost & Profit Calculation
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

-- 5. TRIGGER: Enable Trigger
DROP TRIGGER IF EXISTS trg_populate_sale_item_details ON public.sale_items;
CREATE TRIGGER trg_populate_sale_item_details
    BEFORE INSERT OR UPDATE ON public.sale_items
    FOR EACH ROW
    EXECUTE FUNCTION populate_sale_item_details();
