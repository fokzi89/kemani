-- Migration: Make Retail Columns Nullable in Chat Conversations
-- Purpose: Support clinical consultations that are not tied to a specific retail tenant or branch

-- 1. Alter tenant_id to be nullable
ALTER TABLE public.chat_conversations 
ALTER COLUMN tenant_id DROP NOT NULL;

-- 2. Alter branch_id to be nullable
ALTER TABLE public.chat_conversations 
ALTER COLUMN branch_id DROP NOT NULL;

-- 3. Alter customer_id to be nullable
-- Clinical patients reference auth.users(id) instead of customers(id)
ALTER TABLE public.chat_conversations 
ALTER COLUMN customer_id DROP NOT NULL;

-- 4. Update RLS policies to handle NULLs if necessary
-- (The existing policies in 20260418000002 already use auth.uid() or healthcare_providers check, so they are robust)

-- 5. Add comments
COMMENT ON COLUMN public.chat_conversations.tenant_id IS 'Optional for clinical chats not tied to a retail tenant';
COMMENT ON COLUMN public.chat_conversations.branch_id IS 'Optional for clinical chats not tied to a retail branch';
COMMENT ON COLUMN public.chat_conversations.customer_id IS 'Optional for clinical chats where patient is identified by auth.uid directly';
