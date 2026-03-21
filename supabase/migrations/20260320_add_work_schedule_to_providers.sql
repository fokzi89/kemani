-- Add work_schedule column to healthcare_providers table
-- Date: 2026-03-20
-- This allows providers to set their working hours for each day of the week

ALTER TABLE healthcare_providers
ADD COLUMN IF NOT EXISTS work_schedule JSONB DEFAULT '[]';

-- Add index for work_schedule queries
CREATE INDEX IF NOT EXISTS idx_providers_work_schedule ON healthcare_providers USING GIN (work_schedule);

-- Comment for documentation
COMMENT ON COLUMN healthcare_providers.work_schedule IS 'Array of objects defining working hours per day: [{day, enabled, startTime, endTime}]';
