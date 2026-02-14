-- Add passcode_hash column to users table for POS security
-- This stores the user's 6-digit PIN for re-authentication and inactivity lock

ALTER TABLE users
ADD COLUMN IF NOT EXISTS passcode_hash TEXT;

-- Add comment to explain usage
COMMENT ON COLUMN users.passcode_hash IS 'Hashed 6-digit PIN for POS re-authentication and inactivity lock. Set during onboarding.';

-- Create index for faster lookups (optional, but good practice)
CREATE INDEX IF NOT EXISTS idx_users_passcode_hash ON users(passcode_hash) WHERE passcode_hash IS NOT NULL;
