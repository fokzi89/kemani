-- Migration: Update Chat Schema and Access
-- Purpose: Align chat_conversations with the user's provided schema and allow tenant staff to access chats.

-- 1. Harmonize chat_conversations table
DO $$
BEGIN
    -- Add columns if they don't exist
    ALTER TABLE public.chat_conversations 
    ADD COLUMN IF NOT EXISTS "isConsulatation" boolean NOT NULL DEFAULT false,
    ADD COLUMN IF NOT EXISTS service_provider uuid REFERENCES auth.users(id),
    ADD COLUMN IF NOT EXISTS customer_name text,
    ADD COLUMN IF NOT EXISTS customer_pic text,
    ADD COLUMN IF NOT EXISTS service_provider_name text,
    ADD COLUMN IF NOT EXISTS service_provider_pic text,
    ADD COLUMN IF NOT EXISTS "chatType" text DEFAULT 'Customer Support',
    ADD COLUMN IF NOT EXISTS metadata jsonb DEFAULT '{}'::jsonb;

    -- Ensure chatType constraint exists
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chat_conversations_chatType_check') THEN
        ALTER TABLE public.chat_conversations 
        ADD CONSTRAINT chat_conversations_chatType_check 
        CHECK ("chatType" = ANY (ARRAY['Customer Support'::text, 'Consultation'::text]));
    END IF;
END
$$;

-- 2. Indexes for performance
CREATE INDEX IF NOT EXISTS idx_chat_tenant_branch ON public.chat_conversations (tenant_id, branch_id, started_at DESC);
CREATE INDEX IF NOT EXISTS idx_chat_customer ON public.chat_conversations (customer_id, started_at DESC);
CREATE INDEX IF NOT EXISTS idx_chat_status ON public.chat_conversations (status) WHERE (status = 'active');

-- 3. RLS Policies for chat_conversations
-- Allow participants (customer/medic) AND tenant staff to view/update/create
ALTER TABLE public.chat_conversations ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Participants and staff can view conversations" ON public.chat_conversations;
CREATE POLICY "Participants and staff can view conversations"
ON public.chat_conversations FOR SELECT
TO authenticated
USING (
    customer_id = auth.uid() OR 
    service_provider = auth.uid() OR
    tenant_id IN (SELECT tenant_id FROM public.users WHERE id = auth.uid())
);

DROP POLICY IF EXISTS "Participants and staff can update conversations" ON public.chat_conversations;
CREATE POLICY "Participants and staff can update conversations"
ON public.chat_conversations FOR UPDATE
TO authenticated
USING (
    customer_id = auth.uid() OR 
    service_provider = auth.uid() OR
    tenant_id IN (SELECT tenant_id FROM public.users WHERE id = auth.uid())
);

DROP POLICY IF EXISTS "Participants and staff can insert conversations" ON public.chat_conversations;
CREATE POLICY "Participants and staff can insert conversations"
ON public.chat_conversations FOR INSERT
TO authenticated
WITH CHECK (
    customer_id = auth.uid() OR 
    service_provider = auth.uid() OR
    tenant_id IN (SELECT tenant_id FROM public.users WHERE id = auth.uid())
);

-- 4. RLS Policies for chat_messages
-- Access follows conversation access
ALTER TABLE public.chat_messages ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Participants and staff can view messages" ON public.chat_messages;
CREATE POLICY "Participants and staff can view messages"
ON public.chat_messages FOR SELECT
TO authenticated
USING (
    conversation_id IN (
        SELECT id FROM public.chat_conversations
        WHERE customer_id = auth.uid() OR 
              service_provider = auth.uid() OR
              tenant_id IN (SELECT tenant_id FROM public.users WHERE id = auth.uid())
    )
);

DROP POLICY IF EXISTS "Participants and staff can insert messages" ON public.chat_messages;
CREATE POLICY "Participants and staff can insert messages"
ON public.chat_messages FOR INSERT
TO authenticated
WITH CHECK (
    conversation_id IN (
        SELECT id FROM public.chat_conversations
        WHERE customer_id = auth.uid() OR 
              service_provider = auth.uid() OR
              tenant_id IN (SELECT tenant_id FROM public.users WHERE id = auth.uid())
    )
);
