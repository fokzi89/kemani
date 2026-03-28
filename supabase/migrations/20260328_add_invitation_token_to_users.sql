-- Add invitation_token and invitation fields to users table
ALTER TABLE users
  ADD COLUMN IF NOT EXISTS invitation_token UUID DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS invitation_expires_at TIMESTAMPTZ DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS invitation_accepted_at TIMESTAMPTZ DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS invited_by UUID REFERENCES users(id) ON DELETE SET NULL;

-- Index for fast token lookups
CREATE INDEX IF NOT EXISTS idx_users_invitation_token ON users(invitation_token) WHERE invitation_token IS NOT NULL;
