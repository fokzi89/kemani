-- Migration: Fix Chat RLS Policies
-- Purpose: Allow medics and patients to initialize and update chat conversations

-- 1. Ensure RLS is enabled
ALTER TABLE public.chat_conversations ENABLE ROW LEVEL SECURITY;

-- 2. INSERT Policy
-- Allows medics to create a conversation if they are part of a registered healthcare provider clinic
DROP POLICY IF EXISTS "Medics can create conversations" ON public.chat_conversations;
CREATE POLICY "Medics can create conversations"
ON public.chat_conversations FOR INSERT
WITH CHECK (
    auth.uid() IN (SELECT user_id FROM public.healthcare_providers)
);

-- 3. SELECT Policy (Harmonized)
-- Allows participants (patient or medic) to view the conversation
DROP POLICY IF EXISTS "Participants can view conversations" ON public.chat_conversations;
CREATE POLICY "Participants can view conversations"
ON public.chat_conversations FOR SELECT
USING (
    customer_id = auth.uid() OR 
    auth.uid() IN (SELECT user_id FROM public.healthcare_providers)
);

-- 4. UPDATE Policy
-- Allows participants to update status or metadata (like last_message_time)
DROP POLICY IF EXISTS "Participants can update conversations" ON public.chat_conversations;
CREATE POLICY "Participants can update conversations"
ON public.chat_conversations FOR UPDATE
USING (
    customer_id = auth.uid() OR 
    auth.uid() IN (SELECT user_id FROM public.healthcare_providers)
);

-- 5. DELETE Policy (Safety)
-- Only admins should delete, but we prevent accidental deletions by standard users
DROP POLICY IF EXISTS "Admins can delete conversations" ON public.chat_conversations;
CREATE POLICY "Admins can delete conversations"
ON public.chat_conversations FOR DELETE
USING (
    auth.uid() IN (SELECT id FROM public.users WHERE role IN ('tenant_admin', 'platform_admin'))
);
