-- Harmonized Chat System Migration
-- This aligns with the user's existing schema while adding medical capabilities.

-- 1. Extend Enums (if they don't already have 'medic')
-- We use a DO block to safely add types if they don't exist
DO $$
BEGIN
    -- Check if 'medic' exists in sender_type
    IF NOT EXISTS (SELECT 1 FROM pg_enum e JOIN pg_type t ON e.enumtypid = t.oid WHERE t.typname = 'sender_type' AND e.enumlabel = 'medic') THEN
        ALTER TYPE public.sender_type ADD VALUE 'medic';
    END IF;
    
    -- Check if 'medic' exists in user_type (used by typing indicators in some schemas)
    IF EXISTS (SELECT 1 FROM pg_type WHERE typname = 'user_type') THEN
        IF NOT EXISTS (SELECT 1 FROM pg_enum e JOIN pg_type t ON e.enumtypid = t.oid WHERE t.typname = 'user_type' AND e.enumlabel = 'medic') THEN
            ALTER TYPE public.user_type ADD VALUE 'medic';
        END IF;
    END IF;
END
$$;

-- 2. Ensure Conversations Table supports Consultations
-- The user's snippet provided 'chat_conversations'
ALTER TABLE public.chat_conversations 
ADD COLUMN IF NOT EXISTS consultation_id UUID REFERENCES public.consultations(id) ON DELETE CASCADE,
ADD COLUMN IF NOT EXISTS consultation_code VARCHAR(20);

-- Table structure harmonization (referencing the user's snippet)
-- We assume these tables exist as per user's prompt, but we ensure the columns and links are there.

-- 3. Typing Indicators (Clinical version)
CREATE TABLE IF NOT EXISTS public.chat_typing_indicators (
    id UUID PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
    conversation_id UUID NOT NULL REFERENCES public.chat_conversations(id) ON DELETE CASCADE,
    user_id UUID NOT NULL,
    user_type TEXT NOT NULL CHECK (user_type IN ('medic', 'customer', 'staff', 'ai_agent')),
    is_typing BOOLEAN DEFAULT TRUE,
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '10 seconds'),
    UNIQUE (conversation_id, user_id)
);

-- 4. RLS Policies for Harmonized Schema
ALTER TABLE public.chat_conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_attachments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_typing_indicators ENABLE ROW LEVEL SECURITY;

-- Conversations Access
DROP POLICY IF EXISTS "Participants can view conversations" ON public.chat_conversations;
CREATE POLICY "Participants can view conversations"
ON public.chat_conversations FOR SELECT
USING (
    customer_id = auth.uid() OR 
    auth.uid() IN (SELECT user_id FROM public.healthcare_providers) OR
    tenant_id IN (SELECT tenant_id FROM public.users WHERE id = auth.uid() AND role IN ('tenant_admin', 'platform_admin'))
);

-- Messages Access
DROP POLICY IF EXISTS "Participants can view messages" ON public.chat_messages;
CREATE POLICY "Participants can view messages"
ON public.chat_messages FOR SELECT
USING (
    conversation_id IN (
        SELECT id FROM public.chat_conversations
        WHERE customer_id = auth.uid() OR 
              auth.uid() IN (SELECT user_id FROM public.healthcare_providers)
    )
);

DROP POLICY IF EXISTS "Participants can insert messages" ON public.chat_messages;
CREATE POLICY "Participants can insert messages"
ON public.chat_messages FOR INSERT
WITH CHECK (
    conversation_id IN (
        SELECT id FROM public.chat_conversations
        WHERE customer_id = auth.uid() OR 
              auth.uid() IN (SELECT user_id FROM public.healthcare_providers)
    )
);

-- Trigger to automatically generate consultation_code if it's a medical chat
CREATE OR REPLACE FUNCTION generate_consultation_code()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.consultation_id IS NOT NULL AND NEW.consultation_code IS NULL THEN
        NEW.consultation_code := 'CONS-' || UPPER(SUBSTRING(REPLACE(NEW.consultation_id::text, '-', ''), 1, 4));
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_generate_consultation_code ON public.chat_conversations;
CREATE TRIGGER trigger_generate_consultation_code
    BEFORE INSERT OR UPDATE ON public.chat_conversations
    FOR EACH ROW
    EXECUTE FUNCTION generate_consultation_code();
