-- Add RLS Policy for Healthcare Providers to Create Subscriptions
-- Date: 2026-03-19
--
-- Issue: Healthcare providers can't create subscription records during onboarding
-- Fix: Add policy allowing authenticated users to create subscriptions

-- ============================================================================
-- ADD POLICY FOR HEALTHCARE PROVIDERS TO CREATE SUBSCRIPTIONS
-- ============================================================================

-- Allow authenticated users (healthcare providers) to create subscriptions
-- This is needed for onboarding flow where providers create their own subscription
CREATE POLICY "Authenticated users can create subscriptions"
    ON subscriptions FOR INSERT
    WITH CHECK (auth.uid() IS NOT NULL);

-- Allow users to view subscriptions they created (for healthcare providers)
-- This supplements the existing tenant-based policy
CREATE POLICY "Users can view own subscriptions"
    ON subscriptions FOR SELECT
    USING (
        -- Either they're a healthcare provider viewing their subscription
        EXISTS (
            SELECT 1 FROM healthcare_providers
            WHERE healthcare_providers.subscription_id = subscriptions.id
            AND healthcare_providers.user_id = auth.uid()
        )
        -- Or it's a tenant viewing their subscription (existing policy handles this)
        OR tenant_id = (auth.jwt() ->> 'tenant_id')::UUID
    );

-- Allow healthcare providers to update their own subscriptions
CREATE POLICY "Healthcare providers can update own subscriptions"
    ON subscriptions FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM healthcare_providers
            WHERE healthcare_providers.subscription_id = subscriptions.id
            AND healthcare_providers.user_id = auth.uid()
        )
    );
