-- Migration: Expand User Roles
-- Description: Adds 'pharmacist' and 'doctor' to the user_role enum.

-- Using individual statements as ADD VALUE often fails inside DO blocks or multi-statement transactions
ALTER TYPE public.user_role ADD VALUE IF NOT EXISTS 'pharmacist';
ALTER TYPE public.user_role ADD VALUE IF NOT EXISTS 'doctor';
