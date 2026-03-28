-- ============================================================
-- ADD ONBOARDING_DONE FIELD
-- ============================================================

ALTER TABLE users ADD COLUMN IF NOT EXISTS onboarding_done BOOLEAN DEFAULT FALSE;

-- Update existing users with a tenant to be onboarding_done = true
UPDATE users SET onboarding_done = TRUE WHERE tenant_id IS NOT NULL;
