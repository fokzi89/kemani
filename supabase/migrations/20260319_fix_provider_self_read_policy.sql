-- Fix Healthcare Provider Self-Read RLS Policy
-- Date: 2026-03-19
--
-- Issue: Providers can't read their own unverified profiles during onboarding
-- Fix: Add policy allowing providers to always read their own profile

-- ============================================================================
-- ADD POLICY FOR PROVIDERS TO READ OWN PROFILE
-- ============================================================================

-- Allow providers to read their own profile regardless of verification status
CREATE POLICY "Providers can view own profile"
    ON healthcare_providers FOR SELECT
    USING (user_id = auth.uid());

-- Note: The existing policy "Anyone can view active verified providers" allows
-- public viewing of verified providers. This new policy allows self-viewing.
