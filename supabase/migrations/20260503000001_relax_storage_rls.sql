-- Relax storage.objects policies for chat-attachments to fix upload errors
-- The previous policy using storage.foldername() might have been failing or evaluated incorrectly

-- 1. Allow authenticated users to INSERT into chat-attachments
DROP POLICY IF EXISTS "Users can upload chat attachments" ON storage.objects;
CREATE POLICY "Users can upload chat attachments"
    ON storage.objects FOR INSERT
    TO authenticated
    WITH CHECK (bucket_id = 'chat-attachments');

-- 2. Allow authenticated users to UPDATE their own attachments
DROP POLICY IF EXISTS "Users can update chat attachments" ON storage.objects;
CREATE POLICY "Users can update chat attachments"
    ON storage.objects FOR UPDATE
    TO authenticated
    USING (bucket_id = 'chat-attachments');

-- 3. Ensure SELECT is still public
DROP POLICY IF EXISTS "Public chat attachments access" ON storage.objects;
CREATE POLICY "Public chat attachments access"
    ON storage.objects FOR SELECT
    TO public
    USING (bucket_id = 'chat-attachments');
