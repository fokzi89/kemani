-- Migration: Fix Availability Template RLS
-- Replacing the monolithic 'FOR ALL' policy with explicit ones to ensure DELETE works reliably with subqueries.

-- 1. Drop the old unified policy
DROP POLICY IF EXISTS "Providers can manage their own templates" ON public.provider_availability_templates;
DROP POLICY IF EXISTS "Anyone can view active availability templates" ON public.provider_availability_templates;

-- 2. Add explicit granular policies
CREATE POLICY "Provider Select" ON public.provider_availability_templates
FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM public.healthcare_providers 
    WHERE id = provider_availability_templates.provider_id 
    AND (user_id = auth.uid())
  )
  OR is_active = true
);

CREATE POLICY "Provider Insert" ON public.provider_availability_templates
FOR INSERT
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.healthcare_providers 
    WHERE id = provider_id 
    AND user_id = auth.uid()
  )
);

CREATE POLICY "Provider Update" ON public.provider_availability_templates
FOR UPDATE
USING (
  EXISTS (
    SELECT 1 FROM public.healthcare_providers 
    WHERE id = provider_availability_templates.provider_id 
    AND user_id = auth.uid()
  )
);

CREATE POLICY "Provider Delete" ON public.provider_availability_templates
FOR DELETE
USING (
  EXISTS (
    SELECT 1 FROM public.healthcare_providers 
    WHERE id = provider_availability_templates.provider_id 
    AND user_id = auth.uid()
  )
);

GRANT ALL ON public.provider_availability_templates TO authenticated;
GRANT SELECT ON public.provider_availability_templates TO anon;
