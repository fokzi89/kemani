-- Migration: Refactor Scheduling Fields
-- 1. Add individual columns for duration and buffer to healthcare_providers
ALTER TABLE public.healthcare_providers 
ADD COLUMN IF NOT EXISTS slot_duration_minutes INTEGER DEFAULT 30,
ADD COLUMN IF NOT EXISTS buffer_time_minutes INTEGER DEFAULT 0;

-- 2. Migrate data from slot_settings JSONB if exists
UPDATE public.healthcare_providers
SET 
  slot_duration_minutes = COALESCE((slot_settings->>'duration')::integer, 30),
  buffer_time_minutes = COALESCE((slot_settings->>'buffer')::integer, 0)
WHERE slot_settings IS NOT NULL;

-- 3. Remove the redundant JSONB columns
ALTER TABLE public.healthcare_providers 
DROP COLUMN IF EXISTS work_schedule,
DROP COLUMN IF EXISTS slot_settings;

-- 4. Ensure RLS for the provider_availability_templates table
-- (Assuming the table was just created by the user)
ALTER TABLE public.provider_availability_templates ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Providers can manage their own templates"
ON public.provider_availability_templates
FOR ALL
USING (
  provider_id IN (
    SELECT id FROM public.healthcare_providers WHERE user_id = auth.uid()
  )
);

CREATE POLICY "Anyone can view active availability templates"
ON public.provider_availability_templates
FOR SELECT
USING (is_active = true);
