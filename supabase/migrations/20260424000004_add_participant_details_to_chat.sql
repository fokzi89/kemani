-- Add participant details to chat_conversations for performance
ALTER TABLE public.chat_conversations 
ADD COLUMN IF NOT EXISTS participant_name TEXT,
ADD COLUMN IF NOT EXISTS participant_avatar_url TEXT;
