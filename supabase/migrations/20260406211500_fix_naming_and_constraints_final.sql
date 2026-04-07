-- Migration: Correct column naming and update constraints
-- 1. Rename "clinic name" to "clinic_name" to avoid spacing issues
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'healthcare_providers' 
        AND column_name = 'clinic name'
    ) THEN
        ALTER TABLE public.healthcare_providers RENAME COLUMN "clinic name" TO clinic_name;
    END IF;
END $$;

-- 2. Ensure follow_up_duration is present (it was in the schema but just in case)
ALTER TABLE public.healthcare_providers 
ADD COLUMN IF NOT EXISTS follow_up_duration INTEGER DEFAULT 24;

-- 3. Update the slot_duration check constraint name to be more robust and allow new values
-- We use a name that is less likely to conflict and handles the new options
ALTER TABLE public.provider_availability_templates 
DROP CONSTRAINT IF EXISTS provider_availability_templates_slot_duration_check;

ALTER TABLE public.provider_availability_templates 
DROP CONSTRAINT IF EXISTS provider_availability_templates_slot_duration_check_v2;

ALTER TABLE public.provider_availability_templates
ADD CONSTRAINT prov_avail_slot_duration_valid 
CHECK (slot_duration IN (15, 30, 45, 60, 90, 120));

-- 4. Set defaults for any NULL values in critical columns to prevent update failures
UPDATE public.healthcare_providers SET strike = 0 WHERE strike IS NULL;
UPDATE public.healthcare_providers SET accept_invite = true WHERE accept_invite IS NULL;
UPDATE public.healthcare_providers SET slot_duration_minutes = 30 WHERE slot_duration_minutes IS NULL;
UPDATE public.healthcare_providers SET buffer_time_minutes = 0 WHERE buffer_time_minutes IS NULL;
UPDATE public.healthcare_providers SET follow_up_duration = 24 WHERE follow_up_duration IS NULL;
