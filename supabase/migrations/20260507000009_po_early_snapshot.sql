-- ============================================================
-- Migration: Early Snapshot for Purchase Orders
-- ============================================================
-- Description: Adds product_name and strength to PO items.
--              Ensures details are captured at order time and
--              carried through to inventory.
-- ============================================================

-- 1. Add snapshot columns to purchase_order_items
ALTER TABLE public.purchase_order_items 
ADD COLUMN IF NOT EXISTS product_name TEXT,
ADD COLUMN IF NOT EXISTS strength TEXT;

-- 2. Create Trigger Function to snapshot details on PO Item creation
CREATE OR REPLACE FUNCTION public.populate_po_item_details()
RETURNS TRIGGER AS $$
BEGIN
    SELECT name, strength 
    INTO NEW.product_name, NEW.strength
    FROM public.products WHERE id = NEW.product_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 3. Create the trigger
DROP TRIGGER IF EXISTS trg_populate_po_item_details ON public.purchase_order_items;
CREATE TRIGGER trg_populate_po_item_details
    BEFORE INSERT ON public.purchase_order_items
    FOR EACH ROW
    EXECUTE FUNCTION public.populate_po_item_details();

-- 4. One-time sync for existing PO items
UPDATE public.purchase_order_items poi
SET product_name = p.name,
    strength = p.strength
FROM public.products p
WHERE poi.product_id = p.id
AND poi.product_name IS NULL;
