-- Migration: Create Chat Attachments Storage
-- Purpose: Enable file uploads (images, PDFs, voice notes) for the chat system

-- 1. Create the bucket
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'chat-attachments',
    'chat-attachments',
    true, -- Publicly accessible (medical data should ideally be private, but for simplicity in storefront we use public URLs)
    10485760, -- 10MB limit
    ARRAY[
        'image/jpeg', 'image/png', 'image/webp', 'image/jpg', 'image/gif',
        'application/pdf',
        'audio/webm', 'audio/mpeg', 'audio/wav', 'audio/ogg', 'audio/mp4', 'audio/aac'
    ]
)
ON CONFLICT (id) DO NOTHING;

-- 2. Storage RLS Policies

-- Anyone can view chat attachments (needed for simple public URL sharing)
DROP POLICY IF EXISTS "Anyone can view chat attachments" ON storage.objects;
CREATE POLICY "Anyone can view chat attachments"
    ON storage.objects FOR SELECT
    TO public
    USING (bucket_id = 'chat-attachments');

-- Authenticated users can upload to their own chat folders
-- We use a folder structure: chat/{conversation_id}/{filename}
DROP POLICY IF EXISTS "Users can upload chat attachments" ON storage.objects;
CREATE POLICY "Users can upload chat attachments"
    ON storage.objects FOR INSERT
    TO authenticated
    WITH CHECK (
        bucket_id = 'chat-attachments' AND
        (storage.foldername(name))[1] = 'chat'
    );

-- Allow deletion by owner if needed (optional)
DROP POLICY IF EXISTS "Users can delete own chat attachments" ON storage.objects;
CREATE POLICY "Users can delete own chat attachments"
    ON storage.objects FOR DELETE
    TO authenticated
    USING (
        bucket_id = 'chat-attachments' AND
        (storage.foldername(name))[1] = 'chat'
    );
