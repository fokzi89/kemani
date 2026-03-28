-- ============================================================================
-- FIX MISSING DELETE POLICY ON PRESCRIPTIONS
-- ============================================================================

ALTER TABLE prescriptions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Providers can delete issued prescriptions" ON prescriptions;
CREATE POLICY "Providers can delete issued prescriptions"
    ON prescriptions FOR DELETE
    TO authenticated
    USING (provider_id IN (SELECT id FROM healthcare_providers WHERE user_id = auth.uid()));
