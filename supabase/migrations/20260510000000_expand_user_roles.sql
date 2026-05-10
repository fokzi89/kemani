-- ============================================================
-- Migration: Expand user_role enum
-- Must run BEFORE 20260510000001_create_user_tenants.sql
-- ============================================================

ALTER TYPE public.user_role ADD VALUE IF NOT EXISTS 'staff';
ALTER TYPE public.user_role ADD VALUE IF NOT EXISTS 'accountant';
