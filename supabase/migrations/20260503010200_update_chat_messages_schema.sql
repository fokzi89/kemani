-- Migration: Update Chat Messages Schema for Media Support
-- Purpose: Add columns to support image, video, pdf, and voice attachments as expected by the POS UI.

ALTER TABLE public.chat_messages 
ADD COLUMN IF NOT EXISTS attachment_type text,
ADD COLUMN IF NOT EXISTS attachment_url text,
ADD COLUMN IF NOT EXISTS attachment_name text,
ADD COLUMN IF NOT EXISTS voice_duration integer;

-- Add comment for clarity
COMMENT ON COLUMN public.chat_messages.attachment_type IS 'Type of media: image, video, pdf, or audio/voice';
