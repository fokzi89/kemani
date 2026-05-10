-- ============================================================
-- Migration: Add missing roles to user_role enum
-- ============================================================

-- Adding values to the enum
ALTER TYPE public.user_role ADD VALUE IF NOT EXISTS 'super_admin';
ALTER TYPE public.user_role ADD VALUE IF NOT EXISTS 'pharmacist';
ALTER TYPE public.user_role ADD VALUE IF NOT EXISTS 'rider';

-- Note: In Postgres, ADD VALUE cannot be executed inside a transaction block 
-- if it's used in the same transaction. Since Supabase runs migrations in transactions, 
-- this might need to be run individually if it fails in a large block.
