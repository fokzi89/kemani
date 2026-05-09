-- Migration: Fix Doctor Aliases Schema
-- Adds tenant_partner and ensures created_at and other fields are in the view

-- 1. Add tenant_partner to doctor_aliases table
ALTER TABLE public.doctor_aliases ADD COLUMN IF NOT EXISTS tenant_partner UUID REFERENCES public.tenants(id) ON DELETE CASCADE;

-- 2. Backfill tenant_partner if possible (optional, but good for existing data)
-- If we assume primary_doctor_id's tenant is the intended partner
UPDATE public.doctor_aliases da
SET tenant_partner = u.tenant_id
FROM public.healthcare_providers hp
JOIN public.users u ON hp.user_id = u.id
WHERE da.primary_doctor_id = hp.id AND da.tenant_partner IS NULL;

-- 3. Recreate the view to include all necessary fields
CREATE OR REPLACE VIEW public.doctor_aliases_with_details AS
SELECT
  da.id,
  da.doctor_id,
  da.primary_doctor_id,
  da.tenant_partner,
  da.alias as display_name, -- renamed for consistency with other views
  da.alias,
  da.is_active,
  da.created_at,
  da.accepted,
  -- Provider details from healthcare_providers
  hp.full_name AS doctor_name,
  hp.profile_photo_url,
  hp.specialization,
  hp.sub_specialty,
  hp.years_of_experience,
  hp.consultation_types,
  hp.marked_up_fees AS consultation_fees,
  hp.preferred_languages,
  hp.average_rating,
  hp.total_consultations,
  hp.total_reviews,
  hp.is_verified,
  -- Primary doctor info
  hp_primary.full_name AS primary_doctor_name,
  COALESCE(hp_primary."clinic name", hp_primary.full_name) AS clinic_name
FROM public.doctor_aliases da
JOIN public.healthcare_providers hp ON da.doctor_id = hp.id
LEFT JOIN public.healthcare_providers hp_primary ON da.primary_doctor_id = hp_primary.id;

-- 4. Ensure RLS allows the tenant to see their aliases
DROP POLICY IF EXISTS "Tenants can see their partners" ON public.doctor_aliases;
CREATE POLICY "Tenants can see their partners" 
ON public.doctor_aliases FOR SELECT 
USING (
  tenant_partner IN (
    SELECT tenant_id FROM public.users 
    WHERE id = auth.uid()
  )
);
