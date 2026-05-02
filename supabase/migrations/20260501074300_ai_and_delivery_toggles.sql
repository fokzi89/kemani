-- Migration: Add AI enablement and delivery options
-- Description: Adds AI_is_enabled to tenants and delivery_enabled to branches.

ALTER TABLE public.tenants 
ADD COLUMN IF NOT EXISTS AI_is_enabled BOOLEAN DEFAULT false;

ALTER TABLE public.branches 
ADD COLUMN IF NOT EXISTS delivery_enabled BOOLEAN DEFAULT true;
