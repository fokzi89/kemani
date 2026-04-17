-- Add missing onboarding fields to healthcare_providers table
ALTER TABLE healthcare_providers
ADD COLUMN IF NOT EXISTS license_document_url TEXT;
