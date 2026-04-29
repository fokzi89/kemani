-- Migration: Relax Sale Total Constraint
-- Description: Changes total_amount check from > 0 to >= 0 to support full returns/refunds.

-- 1. Drop the existing strict constraint
-- The error message confirmed the name is 'sales_total_amount_check'
ALTER TABLE public.sales DROP CONSTRAINT IF EXISTS sales_total_amount_check;

-- 2. Add the relaxed constraint
ALTER TABLE public.sales ADD CONSTRAINT sales_total_amount_check CHECK (total_amount >= 0);

-- 3. Update the item-level quantity constraint if necessary
-- (Currently sale_items.quantity > 0, which is correct as we delete or zero-out items)
-- But in the RPC, we set quantity to 0 for returned items.
-- Let's check sale_items quantity constraint.
ALTER TABLE public.sale_items DROP CONSTRAINT IF EXISTS sale_items_quantity_check;
ALTER TABLE public.sale_items ADD CONSTRAINT sale_items_quantity_check CHECK (quantity >= 0);
