-- Migration: Add Pharmacist Verification Fields
-- Description: Adds professional registration and license fields to the users table.

ALTER TABLE public.users 
ADD COLUMN IF NOT EXISTS pharmacist_reg_num TEXT,
ADD COLUMN IF NOT EXISTS pharmacist_license_url TEXT,
ADD COLUMN IF NOT EXISTS pharmacist_verified BOOLEAN DEFAULT FALSE;

-- Add comments for clarity
COMMENT ON COLUMN public.users.pharmacist_reg_num IS 'Pharmacist Council registration number for staff pharmacists';
COMMENT ON COLUMN public.users.pharmacist_license_url IS 'URL to the uploaded license document (image/PDF)';
COMMENT ON COLUMN public.users.pharmacist_verified IS 'Whether the pharmacist professional details have been verified by an admin';

-- 2. Update Storage Policies for Licenses
-- Allow staff pharmacists to upload their licenses to the provider-licenses bucket
-- using their user_id as the folder name.
DO $$
BEGIN
    -- INSERT policy
    DROP POLICY IF EXISTS "Staff pharmacists can upload licenses" ON storage.objects;
    CREATE POLICY "Staff pharmacists can upload licenses"
        ON storage.objects FOR INSERT
        TO authenticated
        WITH CHECK (
            bucket_id = 'provider-licenses' AND
            EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'pharmacist')
        );

    -- SELECT policy
    DROP POLICY IF EXISTS "Staff pharmacists can view own licenses" ON storage.objects;
    CREATE POLICY "Staff pharmacists can view own licenses"
        ON storage.objects FOR SELECT
        TO authenticated
        USING (
            bucket_id = 'provider-licenses' AND
            (storage.foldername(name))[1] = auth.uid()::text
        );
END $$;
