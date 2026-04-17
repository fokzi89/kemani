-- Add idle_timeout_minutes column to healthcare_providers
ALTER TABLE healthcare_providers 
ADD COLUMN IF NOT EXISTS idle_timeout_minutes INTEGER DEFAULT 30;

-- Add check constraint to cap at 60 minutes and minimum 1 minute
ALTER TABLE healthcare_providers
ADD CONSTRAINT check_idle_timeout_range 
CHECK (idle_timeout_minutes >= 1 AND idle_timeout_minutes <= 60);

-- Comment for documentation
COMMENT ON COLUMN healthcare_providers.idle_timeout_minutes IS 'Inactivity timeout in minutes for auto-logout (min 1, max 60)';
