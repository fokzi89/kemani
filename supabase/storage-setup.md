# Supabase Storage Setup

This document explains how to set up the required storage buckets for image uploads.

## Required Buckets

### 1. Profile Pictures (`profile-pictures`)
- **Purpose**: Store user profile pictures for owners and staff
- **Max File Size**: 2MB
- **Allowed Types**: JPG, PNG, WebP
- **Access**: Public

### 2. Company Logos (`company-logos`)
- **Purpose**: Store tenant/company logos
- **Max File Size**: 5MB
- **Allowed Types**: JPG, PNG, WebP, SVG
- **Access**: Public

---

## Setup Methods

### Method 1: Using Supabase Dashboard (Recommended)

1. Go to **Supabase Dashboard** → **Storage**
2. Click **"Create new bucket"**

#### Create `profile-pictures` bucket:
- **Name**: `profile-pictures`
- **Public bucket**: ✅ Enable
- **File size limit**: 2MB
- **Allowed MIME types**: `image/jpeg`, `image/png`, `image/webp`
- Click **Create bucket**

#### Create `company-logos` bucket:
- **Name**: `company-logos`
- **Public bucket**: ✅ Enable
- **File size limit**: 5MB
- **Allowed MIME types**: `image/jpeg`, `image/png`, `image/webp`, `image/svg+xml`
- Click **Create bucket**

### Method 2: Using SQL (Automated)

Run this SQL in **Supabase Dashboard** → **SQL Editor**:

```sql
-- Create profile-pictures bucket
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'profile-pictures',
  'profile-pictures',
  true,
  2097152, -- 2MB in bytes
  ARRAY['image/jpeg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO NOTHING;

-- Create company-logos bucket
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'company-logos',
  'company-logos',
  true,
  5242880, -- 5MB in bytes
  ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/svg+xml']
)
ON CONFLICT (id) DO NOTHING;
```

---

## Storage Policies (RLS)

### Profile Pictures Policy

```sql
-- Allow authenticated users to upload their own profile pictures
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
CREATE POLICY "Anyone can view profile pictures"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'profile-pictures');
```

### Company Logos Policy

```sql
-- Allow tenant admins to upload company logos
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
    AND users.tenant_id::text = (storage.foldername(name))[2]
  )
);

-- Allow tenant admins to update company logos
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
    AND users.tenant_id::text = (storage.foldername(name))[2]
  )
);

-- Allow tenant admins to delete company logos
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
    AND users.tenant_id::text = (storage.foldername(name))[2]
  )
);

-- Allow public read access to all company logos
CREATE POLICY "Anyone can view company logos"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'company-logos');
```

---

## Folder Structure

### Profile Pictures
```
profile-pictures/
└── profiles/
    └── {userId}/
        ├── {userId}_timestamp_randomstr.jpg
        ├── {userId}_timestamp_randomstr.png
        └── ...
```

### Company Logos
```
company-logos/
└── logos/
    └── {tenantId}/
        ├── {userId}_timestamp_randomstr.jpg
        ├── {userId}_timestamp_randomstr.png
        └── ...
```

---

## API Endpoints

### Upload Profile Picture
```typescript
POST /api/storage/upload-profile-picture

FormData:
- file: File (required)
- oldImagePath: string (optional, for updates)

Response:
{
  success: true,
  url: "https://your-project.supabase.co/storage/v1/object/public/profile-pictures/profiles/{userId}/{filename}",
  path: "profiles/{userId}/{filename}"
}
```

### Upload Company Logo
```typescript
POST /api/storage/upload-logo

FormData:
- file: File (required)
- tenantId: string (optional, defaults to user's tenant)
- oldImagePath: string (optional, for updates)

Response:
{
  success: true,
  url: "https://your-project.supabase.co/storage/v1/object/public/company-logos/logos/{tenantId}/{filename}",
  path: "logos/{tenantId}/{filename}"
}
```

---

## Verification

After setup, verify the buckets exist:

```sql
SELECT id, name, public, file_size_limit, allowed_mime_types
FROM storage.buckets
WHERE id IN ('profile-pictures', 'company-logos');
```

Expected output:
```
id                 | name              | public | file_size_limit | allowed_mime_types
-------------------|-------------------|--------|-----------------|-----------------------------------
profile-pictures   | profile-pictures  | true   | 2097152         | {image/jpeg,image/png,image/webp}
company-logos      | company-logos     | true   | 5242880         | {image/jpeg,image/png,image/webp,image/svg+xml}
```

---

## Troubleshooting

### Issue: "Bucket not found"
- **Solution**: Create the buckets using Method 1 or 2 above

### Issue: "Policy violation"
- **Solution**: Apply the RLS policies from the "Storage Policies" section

### Issue: "File size exceeds limit"
- **Solution**: Check that file size limits match your requirements (2MB for profiles, 5MB for logos)

### Issue: "Invalid MIME type"
- **Solution**: Ensure you're uploading JPG, PNG, WebP (or SVG for logos)

---

## Next Steps

1. ✅ Create the two storage buckets
2. ✅ Apply RLS policies
3. ✅ Test uploads via API endpoints
4. Build UI components for image upload (file pickers, previews, etc.)
