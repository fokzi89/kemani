-- ============================================================
-- Migration: Setup Storage Buckets for Image Uploads
-- ============================================================
-- Purpose: Create storage buckets and RLS policies for profile pictures and company logos
-- Date: 2026-02-08
-- Related: Task T093 - Implement image upload to Supabase Storage

-- ============================================================
-- 1. Create Storage Buckets
-- ============================================================

-- Create profile-pictures bucket (2MB limit, JPG/PNG/WebP)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'profile-pictures',
  'profile-pictures',
  true,
  2097152, -- 2MB in bytes
  ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/jpg']
)
ON CONFLICT (id) DO UPDATE SET
  public = true,
  file_size_limit = 2097152,
  allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/jpg'];

-- Create company-logos bucket (5MB limit, JPG/PNG/WebP/SVG)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'company-logos',
  'company-logos',
  true,
  5242880, -- 5MB in bytes
  ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/svg+xml', 'image/jpg']
)
ON CONFLICT (id) DO UPDATE SET
  public = true,
  file_size_limit = 5242880,
  allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/svg+xml', 'image/jpg'];

-- ============================================================
-- 2. RLS Policies for Profile Pictures
-- ============================================================

-- Allow authenticated users to upload their own profile pictures
DROP POLICY IF EXISTS "Users can upload own profile pictures" ON storage.objects;
CREATE POLICY "Users can upload own profile pictures"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'profile-pictures'
  AND (storage.foldername(name))[1] = 'profiles'
  AND (storage.foldername(name))[2] = auth.uid()::text
);

-- Allow authenticated users to update their own profile pictures
DROP POLICY IF EXISTS "Users can update own profile pictures" ON storage.objects;
CREATE POLICY "Users can update own profile pictures"
ON storage.objects
FOR UPDATE
TO authenticated
USING (
  bucket_id = 'profile-pictures'
  AND (storage.foldername(name))[1] = 'profiles'
  AND (storage.foldername(name))[2] = auth.uid()::text
);

-- Allow authenticated users to delete their own profile pictures
DROP POLICY IF EXISTS "Users can delete own profile pictures" ON storage.objects;
CREATE POLICY "Users can delete own profile pictures"
ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'profile-pictures'
  AND (storage.foldername(name))[1] = 'profiles'
  AND (storage.foldername(name))[2] = auth.uid()::text
);

-- Allow public read access to all profile pictures
DROP POLICY IF EXISTS "Anyone can view profile pictures" ON storage.objects;
CREATE POLICY "Anyone can view profile pictures"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'profile-pictures');

-- ============================================================
-- 3. RLS Policies for Company Logos
-- ============================================================

-- Allow tenant admins to upload company logos
DROP POLICY IF EXISTS "Tenant admins can upload logos" ON storage.objects;
CREATE POLICY "Tenant admins can upload logos"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'company-logos'
  AND (storage.foldername(name))[1] = 'logos'
  AND EXISTS (
    SELECT 1 FROM users
    WHERE users.id = auth.uid()
    AND users.role IN ('tenant_admin', 'platform_admin')
  )
);

-- Allow tenant admins to update company logos
DROP POLICY IF EXISTS "Tenant admins can update logos" ON storage.objects;
CREATE POLICY "Tenant admins can update logos"
ON storage.objects
FOR UPDATE
TO authenticated
USING (
  bucket_id = 'company-logos'
  AND (storage.foldername(name))[1] = 'logos'
  AND EXISTS (
    SELECT 1 FROM users
    WHERE users.id = auth.uid()
    AND users.role IN ('tenant_admin', 'platform_admin')
  )
);

-- Allow tenant admins to delete company logos
DROP POLICY IF EXISTS "Tenant admins can delete logos" ON storage.objects;
CREATE POLICY "Tenant admins can delete logos"
ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'company-logos'
  AND (storage.foldername(name))[1] = 'logos'
  AND EXISTS (
    SELECT 1 FROM users
    WHERE users.id = auth.uid()
    AND users.role IN ('tenant_admin', 'platform_admin')
  )
);

-- Allow public read access to all company logos
DROP POLICY IF EXISTS "Anyone can view company logos" ON storage.objects;
CREATE POLICY "Anyone can view company logos"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'company-logos');

-- ============================================================
-- 4. Verification
-- ============================================================

-- Verify buckets were created
DO $$
DECLARE
    bucket_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO bucket_count
    FROM storage.buckets
    WHERE id IN ('profile-pictures', 'company-logos');

    IF bucket_count = 2 THEN
        RAISE NOTICE '✅ Storage buckets created successfully';
        RAISE NOTICE '   - profile-pictures (2MB limit)';
        RAISE NOTICE '   - company-logos (5MB limit)';
    ELSE
        RAISE WARNING '⚠️  Only % of 2 buckets were created', bucket_count;
    END IF;
END $$;

-- Show bucket configuration
SELECT
    id,
    name,
    public,
    ROUND(file_size_limit / 1024.0 / 1024.0, 1) as "max_size_mb",
    allowed_mime_types
FROM storage.buckets
WHERE id IN ('profile-pictures', 'company-logos')
ORDER BY id;
