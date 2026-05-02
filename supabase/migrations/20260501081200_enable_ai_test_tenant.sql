-- Migration: Enable AI for test tenant
-- Description: Sets ai_is_enabled to true for the ade-ventures tenant.

UPDATE public.tenants 
SET ai_is_enabled = true 
WHERE slug = 'ade-ventures' OR name ILIKE '%Ade Ventures%';
