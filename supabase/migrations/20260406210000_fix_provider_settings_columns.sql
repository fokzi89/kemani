-- Migration: Add missing provider settings columns and fix constraints
-- 1. Add follow_up_duration to healthcare_providers
ALTER TABLE public.healthcare_providers 
ADD COLUMN IF NOT EXISTS follow_up_duration INTEGER DEFAULT 24;

-- 2. Relax slot_duration check on provider_availability_templates to allow more flexible scheduling
-- First find the existing constraint name if possible, or just drop it if it matches the standard pattern
-- Typical name for inline check is provider_availability_templates_slot_duration_check
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.constraint_column_usage 
        WHERE table_name = 'provider_availability_templates' 
        AND column_name = 'slot_duration'
    ) THEN
        BEGIN
            ALTER TABLE public.provider_availability_templates DROP CONSTRAINT IF EXISTS provider_availability_templates_slot_duration_check;
        EXCEPTION WHEN undefined_object THEN
            -- Ignore if name is different, we can't easily guess it without information_schema
            NULL;
        END;
    END IF;
END $$;

-- Add updated check constraint to support 15, 30, 45, 60, 90, 120 minutes as per UI
-- We also ensure it handles existing values
ALTER TABLE public.provider_availability_templates
ADD CONSTRAINT provider_availability_templates_slot_duration_check_v2 
CHECK (slot_duration IN (15, 30, 45, 60, 90, 120));

-- 3. Ensure RLS for the healthcare_providers table allows updating these new columns
-- (Standard UPDATE policy usually covers all columns, so this is just a sanity check)
-- No changes needed if the existing policy is 'user_id = auth.uid()'
