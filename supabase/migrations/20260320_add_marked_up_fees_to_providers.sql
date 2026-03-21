-- Add marked_up_fees column to healthcare_providers table
-- Date: 2026-03-20
-- This stores the customer-facing fees with 10% markup applied

ALTER TABLE healthcare_providers
ADD COLUMN IF NOT EXISTS marked_up_fees JSONB DEFAULT '{"chat": 0, "video": 0, "audio": 0, "office_visit": 0}';

-- Add index for marked_up_fees queries
CREATE INDEX IF NOT EXISTS idx_providers_marked_up_fees ON healthcare_providers USING GIN (marked_up_fees);

-- Comment for documentation
COMMENT ON COLUMN healthcare_providers.marked_up_fees IS 'Customer-facing consultation fees with 10% markup: {chat, video, audio, office_visit}';
