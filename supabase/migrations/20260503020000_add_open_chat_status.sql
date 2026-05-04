-- Migration: Add 'open' status to chat_status enum
-- Purpose: Support unassigned chats that staff can join.

ALTER TYPE public.chat_status ADD VALUE IF NOT EXISTS 'open';
ALTER TABLE public.chat_conversations ALTER COLUMN status SET DEFAULT 'open';
UPDATE public.chat_conversations SET status = 'open' WHERE status = 'active' AND service_provider IS NULL;
