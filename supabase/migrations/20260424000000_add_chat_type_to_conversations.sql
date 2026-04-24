-- Add chatType column to chat_conversations
ALTER TABLE public.chat_conversations 
ADD COLUMN IF NOT EXISTS "chatType" text DEFAULT 'Customer Support' 
CHECK ("chatType" IN ('Customer Support', 'Consultation'));
