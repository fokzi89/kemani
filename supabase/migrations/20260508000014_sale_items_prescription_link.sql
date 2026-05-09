-- Migration: Link Sale Items to Prescriptions
-- Enables tracking which items in a sale were authorized by which prescription

ALTER TABLE public.sale_items 
ADD COLUMN IF NOT EXISTS prescription_id UUID REFERENCES public.prescriptions(id) ON DELETE SET NULL;

COMMENT ON COLUMN public.sale_items.prescription_id IS 'Link to the prescription that authorized this drug sale.';
