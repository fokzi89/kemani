-- Migration: Add Human-Readable Day Names to Availability Templates
-- This improves database readability for manual queries and reporting.

ALTER TABLE public.provider_availability_templates 
ADD COLUMN IF NOT EXISTS day_name TEXT;

-- Update existing records with the correct day name based on day_of_week
UPDATE public.provider_availability_templates 
SET day_name = CASE 
    WHEN day_of_week = 0 THEN 'Sunday'
    WHEN day_of_week = 1 THEN 'Monday'
    WHEN day_of_week = 2 THEN 'Tuesday'
    WHEN day_of_week = 3 THEN 'Wednesday'
    WHEN day_of_week = 4 THEN 'Thursday'
    WHEN day_of_week = 5 THEN 'Friday'
    WHEN day_of_week = 6 THEN 'Saturday'
END
WHERE day_name IS NULL;
