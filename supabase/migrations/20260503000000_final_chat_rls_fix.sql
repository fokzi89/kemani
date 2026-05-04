-- Final Chat and Identity RLS Harmonization
-- Purpose: Resolve 42501 (Permission Denied) errors for images and patient profiles

-- 1. Ensure Storage Visibility for Chat Attachments
-- The 'chat-attachments' bucket is public, but storage.objects policies might be restrictive.
-- We ensure anyone can SELECT objects from this bucket.
DROP POLICY IF EXISTS "Public chat attachments access" ON storage.objects;
CREATE POLICY "Public chat attachments access"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'chat-attachments');

-- 2. Fix Unified Patient Profile Creation
-- During social login, the system tries to link the user to a unified profile.
-- We must allow authenticated users to INSERT their own profile and link.
ALTER TABLE public.unified_patient_profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Authenticated users can create profiles" ON public.unified_patient_profiles;
CREATE POLICY "Authenticated users can create profiles"
ON public.unified_patient_profiles FOR INSERT
TO authenticated
WITH CHECK (true);

DROP POLICY IF EXISTS "Users can view own profiles" ON public.unified_patient_profiles;
CREATE POLICY "Users can view own profiles"
ON public.unified_patient_profiles FOR SELECT
TO authenticated
USING (
    id IN (
        SELECT unified_patient_id FROM public.patient_account_links 
        WHERE customer_id = auth.uid()
    )
);

-- 3. Ensure Chat Messages are visible to the conversation participants
-- Double check policies on chat_messages
DROP POLICY IF EXISTS "Participants can view conversation messages" ON public.chat_messages;
CREATE POLICY "Participants can view conversation messages"
ON public.chat_messages FOR SELECT
TO authenticated
USING (
    conversation_id IN (
        SELECT id FROM public.chat_conversations
        WHERE customer_id = auth.uid() OR 
              auth.uid() IN (SELECT user_id FROM public.healthcare_providers)
    )
);
