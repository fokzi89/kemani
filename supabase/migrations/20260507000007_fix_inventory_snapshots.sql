-- ============================================================
-- Migration: Ensure Product Snapshots in Branch Inventory (FINAL)
-- ============================================================
-- Description: Adds strength column and updates the trigger
--              to ensure product details are synced on every 
--              inventory update (including PO receives).
-- ============================================================

-- 1. Ensure strength column exists in branch_inventory
ALTER TABLE public.branch_inventory 
ADD COLUMN IF NOT EXISTS strength TEXT;

-- 2. Update the populate function to include strength and be more robust
CREATE OR REPLACE FUNCTION public.populate_branch_inventory_details()
RETURNS TRIGGER AS $$
DECLARE
    r_prod RECORD;
BEGIN
    SELECT name, barcode as sku, barcode, product_type, generic_name, unit_of_measure, image_url, strength
    INTO r_prod
    FROM public.products WHERE id = NEW.product_id;

    IF r_prod IS NOT NULL THEN
        NEW.product_name := COALESCE(NEW.product_name, r_prod.name);
        NEW.sku := COALESCE(NEW.sku, r_prod.sku);
        NEW.barcode := COALESCE(NEW.barcode, r_prod.barcode);
        NEW.product_type := COALESCE(NEW.product_type, r_prod.product_type);
        NEW.unit_of_measure := COALESCE(NEW.unit_of_measure, r_prod.unit_of_measure);
        NEW.image_url := COALESCE(NEW.image_url, r_prod.image_url);
        NEW.strength := COALESCE(NEW.strength, r_prod.strength);
        
        IF r_prod.product_type IN ('drug', 'medication') THEN
            NEW.generic_name := COALESCE(NEW.generic_name, r_prod.generic_name);
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 3. Update trigger to fire on INSERT and UPDATE
DROP TRIGGER IF EXISTS trg_populate_branch_inventory_details ON public.branch_inventory;
CREATE TRIGGER trg_populate_branch_inventory_details
    BEFORE INSERT OR UPDATE ON public.branch_inventory
    FOR EACH ROW
    EXECUTE FUNCTION public.populate_branch_inventory_details();

-- 4. Sync existing data
UPDATE public.branch_inventory bi
SET product_name = p.name,
    sku = p.barcode,
    strength = p.strength,
    product_type = p.product_type,
    image_url = p.image_url
FROM public.products p
WHERE bi.product_id = p.id
AND (bi.product_name IS NULL OR bi.strength IS NULL);
