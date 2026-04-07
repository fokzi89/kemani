-- Migration: Implement Soft-Delete for Availability Templates
-- Adding is_closed column and making provider_id + day_of_week unique for reliable upserting.

-- 1. Add the is_closed column
ALTER TABLE public.provider_availability_templates 
ADD COLUMN IF NOT EXISTS is_closed BOOLEAN DEFAULT FALSE;

-- 2. Add a unique constraint to prevent duplicate day entries for a single provider
-- This allows us to use 'ON CONFLICT' to simply toggle is_closed state.
ALTER TABLE public.provider_availability_templates 
ADD CONSTRAINT unique_provider_day UNIQUE (provider_id, day_of_week);

-- 3. Pre-populate is_closed for existing records that might be logically inactive
UPDATE public.provider_availability_templates 
SET is_closed = NOT is_active 
WHERE is_active IS NOT NULL;
