-- ============================================================
-- Migration: Fix Users Table Typos
-- Description: Renames misspelled columns in the users table to align with the codebase
--              and staff_invitations table.
-- ============================================================

ALTER TABLE public.users RENAME COLUMN "canMangeStaff" TO "canManageStaff";
ALTER TABLE public.users RENAME COLUMN "canReferToDoctor" TO "canReferDoctor";
