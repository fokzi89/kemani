-- ============================================================
-- Migration: Remove Unique Phone Constraint on Patients
-- ============================================================
-- Purpose: Allow healthcare providers to register multiple patients 
-- with the same phone number (e.g., family members, minors).
-- Also clarifies that patients can already be associated with
-- multiple different providers (the previous constraint was per-provider).

ALTER TABLE patients 
DROP CONSTRAINT IF EXISTS patients_healthcare_provider_id_phone_key;

-- We still keep the index on phone for search performance, 
-- but it is no longer unique.
COMMENT ON TABLE patients IS 'Updated: Removed unique constraint on phone per provider to allow family registration.';
