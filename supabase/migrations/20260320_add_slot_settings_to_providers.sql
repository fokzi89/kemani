-- Add slot_settings column to healthcare_providers table
-- Date: 2026-03-20
-- This allows providers to configure appointment slot duration and buffer times

ALTER TABLE healthcare_providers
ADD COLUMN IF NOT EXISTS slot_settings JSONB DEFAULT '{"duration": 30, "buffer": 0, "breakTimes": []}';

-- Add index for slot_settings queries
CREATE INDEX IF NOT EXISTS idx_providers_slot_settings ON healthcare_providers USING GIN (slot_settings);

-- Comment for documentation
COMMENT ON COLUMN healthcare_providers.slot_settings IS 'Appointment slot configuration: {duration (minutes), buffer (minutes), breakTimes: [{startTime, endTime}]}';
