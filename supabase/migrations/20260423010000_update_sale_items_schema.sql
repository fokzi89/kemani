-- ============================================================
-- Migration: Update sale_items with Batch Allocations and Final Constraints
-- Description: Adds missing columns and ensures the schema matches the requested state.
-- ============================================================

-- 1. Add missing columns safely
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'sale_items' AND column_name = 'batch_allocations') THEN
        ALTER TABLE public.sale_items ADD COLUMN batch_allocations jsonb DEFAULT '[]'::jsonb;
    END IF;
END $$;

-- 2. Update/Ensure Constraints
-- First drop existing ones to avoid conflicts if they were named differently
ALTER TABLE public.sale_items DROP CONSTRAINT IF EXISTS sale_items_subtotal_check;
ALTER TABLE public.sale_items DROP CONSTRAINT IF EXISTS valid_subtotal_logic;
ALTER TABLE public.sale_items DROP CONSTRAINT IF EXISTS sale_items_quantity_check;
ALTER TABLE public.sale_items DROP CONSTRAINT IF EXISTS sale_items_unit_price_check;

ALTER TABLE public.sale_items ADD CONSTRAINT sale_items_subtotal_check CHECK (subtotal >= 0);
ALTER TABLE public.sale_items ADD CONSTRAINT valid_subtotal_logic CHECK (subtotal = (unit_price * quantity) - discount_amount);
ALTER TABLE public.sale_items ADD CONSTRAINT sale_items_quantity_check CHECK (quantity > 0);
ALTER TABLE public.sale_items ADD CONSTRAINT sale_items_unit_price_check CHECK (unit_price > 0);

-- 3. Ensure Indexes match requested state
CREATE INDEX IF NOT EXISTS idx_sale_items_tenant_final ON public.sale_items USING btree (tenant_id);
CREATE INDEX IF NOT EXISTS idx_sale_items_branch_final ON public.sale_items USING btree (branch_id);
CREATE INDEX IF NOT EXISTS idx_sale_items_created_at_final ON public.sale_items USING btree (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_sale_items_category_final ON public.sale_items USING btree (category_id) WHERE (category_id IS NOT NULL);
CREATE INDEX IF NOT EXISTS idx_sale_items_product_final ON public.sale_items USING btree (product_id);
CREATE INDEX IF NOT EXISTS idx_sale_items_sale_order_final ON public.sale_items USING btree (sale_id, order_id);

-- 4. Trigger is already handled in 20260419210000_sale_items_rls_and_trigger_fix.sql
-- but we ensure it's still attached.
DROP TRIGGER IF EXISTS trg_populate_sale_item_details ON public.sale_items;
CREATE TRIGGER trg_populate_sale_item_details
    BEFORE INSERT OR UPDATE ON public.sale_items
    FOR EACH ROW
    EXECUTE FUNCTION populate_sale_item_details();
