-- ============================================================================
-- CREATE STORAGE BUCKETS FOR HEALTHCARE PROVIDERS
-- ============================================================================
-- This migration creates storage buckets for:
-- - Profile pictures (public)
-- - Certificates (private)
-- - Professional licenses (private)
-- ============================================================================

-- ============================================================================
-- CREATE STORAGE BUCKETS
-- ============================================================================

-- Profile Pictures Bucket
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'provider-profile-pictures',
    'provider-profile-pictures',
    true, -- Public access for profile pictures
    2097152, -- 2MB limit
    ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/jpg']
)
ON CONFLICT (id) DO NOTHING;

-- Certificates Bucket
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'provider-certificates',
    'provider-certificates',
    false, -- Private - only visible to provider and admins
    5242880, -- 5MB limit
    ARRAY['application/pdf', 'image/jpeg', 'image/png', 'image/jpg']
)
ON CONFLICT (id) DO NOTHING;

-- Licenses Bucket
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'provider-licenses',
    'provider-licenses',
    false, -- Private - only visible to provider and admins
    5242880, -- 5MB limit
    ARRAY['application/pdf', 'image/jpeg', 'image/png', 'image/jpg']
)
ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- STORAGE RLS POLICIES - PROFILE PICTURES
-- ============================================================================

DROP POLICY IF EXISTS "Providers can upload own profile pictures" ON storage.objects;
CREATE POLICY "Providers can upload own profile pictures"
    ON storage.objects FOR INSERT
    TO authenticated
    WITH CHECK (
        bucket_id = 'provider-profile-pictures' AND
        auth.uid()::text = (storage.foldername(name))[1]
    );

DROP POLICY IF EXISTS "Providers can update own profile pictures" ON storage.objects;
CREATE POLICY "Providers can update own profile pictures"
    ON storage.objects FOR UPDATE
    TO authenticated
    USING (
        bucket_id = 'provider-profile-pictures' AND
        auth.uid()::text = (storage.foldername(name))[1]
    );

DROP POLICY IF EXISTS "Providers can delete own profile pictures" ON storage.objects;
CREATE POLICY "Providers can delete own profile pictures"
    ON storage.objects FOR DELETE
    TO authenticated
    USING (
        bucket_id = 'provider-profile-pictures' AND
        auth.uid()::text = (storage.foldername(name))[1]
    );

DROP POLICY IF EXISTS "Anyone can view profile pictures" ON storage.objects;
CREATE POLICY "Anyone can view profile pictures"
    ON storage.objects FOR SELECT
    TO public
    USING (bucket_id = 'provider-profile-pictures');

-- ============================================================================
-- STORAGE RLS POLICIES - CERTIFICATES
-- ============================================================================

DROP POLICY IF EXISTS "Providers can upload own certificates" ON storage.objects;
CREATE POLICY "Providers can upload own certificates"
    ON storage.objects FOR INSERT
    TO authenticated
    WITH CHECK (
        bucket_id = 'provider-certificates' AND
        (storage.foldername(name))[1] IN (
            SELECT id::text FROM healthcare_providers WHERE user_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Providers can view own certificates" ON storage.objects;
CREATE POLICY "Providers can view own certificates"
    ON storage.objects FOR SELECT
    TO authenticated
    USING (
        bucket_id = 'provider-certificates' AND
        (storage.foldername(name))[1] IN (
            SELECT id::text FROM healthcare_providers WHERE user_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Providers can update own certificates" ON storage.objects;
CREATE POLICY "Providers can update own certificates"
    ON storage.objects FOR UPDATE
    TO authenticated
    USING (
        bucket_id = 'provider-certificates' AND
        (storage.foldername(name))[1] IN (
            SELECT id::text FROM healthcare_providers WHERE user_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Providers can delete own certificates" ON storage.objects;
CREATE POLICY "Providers can delete own certificates"
    ON storage.objects FOR DELETE
    TO authenticated
    USING (
        bucket_id = 'provider-certificates' AND
        (storage.foldername(name))[1] IN (
            SELECT id::text FROM healthcare_providers WHERE user_id = auth.uid()
        )
    );

-- ============================================================================
-- STORAGE RLS POLICIES - LICENSES
-- ============================================================================

DROP POLICY IF EXISTS "Providers can upload own licenses" ON storage.objects;
CREATE POLICY "Providers can upload own licenses"
    ON storage.objects FOR INSERT
    TO authenticated
    WITH CHECK (
        bucket_id = 'provider-licenses' AND
        (storage.foldername(name))[1] IN (
            SELECT id::text FROM healthcare_providers WHERE user_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Providers can view own licenses" ON storage.objects;
CREATE POLICY "Providers can view own licenses"
    ON storage.objects FOR SELECT
    TO authenticated
    USING (
        bucket_id = 'provider-licenses' AND
        (storage.foldername(name))[1] IN (
            SELECT id::text FROM healthcare_providers WHERE user_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Providers can update own licenses" ON storage.objects;
CREATE POLICY "Providers can update own licenses"
    ON storage.objects FOR UPDATE
    TO authenticated
    USING (
        bucket_id = 'provider-licenses' AND
        (storage.foldername(name))[1] IN (
            SELECT id::text FROM healthcare_providers WHERE user_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Providers can delete own licenses" ON storage.objects;
CREATE POLICY "Providers can delete own licenses"
    ON storage.objects FOR DELETE
    TO authenticated
    USING (
        bucket_id = 'provider-licenses' AND
        (storage.foldername(name))[1] IN (
            SELECT id::text FROM healthcare_providers WHERE user_id = auth.uid()
        )
    );
