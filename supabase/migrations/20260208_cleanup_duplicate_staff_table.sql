-- ============================================================
-- Migration: Remove Duplicate staff_invites Table
-- ============================================================
-- Purpose: Clean up duplicate staff invitation table
-- Date: 2026-02-08
--
-- We have two similar tables:
-- 1. staff_invites (older, missing full_name field)
-- 2. staff_invitations (newer, used by current code)
--
-- This migration removes the older table to avoid confusion.
-- ============================================================

-- ============================================================
-- SAFETY CHECK: Verify current code uses staff_invitations
-- ============================================================
-- Before running this migration, confirm that:
-- 1. Your code references "staff_invitations" NOT "staff_invites"
-- 2. No active invitations exist in staff_invites
--
-- To check for active invitations in old table:
-- SELECT COUNT(*) FROM staff_invites WHERE status = 'pending';
-- ============================================================

-- ============================================================
-- 1. Migrate Any Existing Data (if needed)
-- ============================================================

-- Check if staff_invites has any records that staff_invitations doesn't
DO $$
DECLARE
    old_count INTEGER;
    new_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO old_count FROM staff_invites WHERE status = 'pending';
    SELECT COUNT(*) INTO new_count FROM staff_invitations WHERE status = 'pending';

    IF old_count > 0 THEN
        RAISE NOTICE 'WARNING: staff_invites has % pending invitations', old_count;
        RAISE NOTICE 'staff_invitations has % pending invitations', new_count;

        -- Optionally migrate data if needed
        -- INSERT INTO staff_invitations (tenant_id, email, full_name, role, ...)
        -- SELECT tenant_id, email, 'Unknown' as full_name, assigned_role::user_role, ...
        -- FROM staff_invites
        -- WHERE NOT EXISTS (
        --   SELECT 1 FROM staff_invitations si
        --   WHERE si.email = staff_invites.email
        --     AND si.tenant_id = staff_invites.tenant_id
        -- );
    ELSE
        RAISE NOTICE 'No pending invitations in staff_invites. Safe to drop.';
    END IF;
END $$;

-- ============================================================
-- 2. Drop Old Table
-- ============================================================

-- Drop the old staff_invites table (this will also drop associated indexes and policies)
DROP TABLE IF EXISTS staff_invites CASCADE;

-- ============================================================
-- 3. Verification
-- ============================================================

-- Verify staff_invitations table exists and has correct structure
DO $$
BEGIN
    -- Check that staff_invitations exists
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = 'public'
        AND table_name = 'staff_invitations'
    ) THEN
        RAISE EXCEPTION 'ERROR: staff_invitations table does not exist!';
    END IF;

    -- Check that full_name column exists
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
        AND table_name = 'staff_invitations'
        AND column_name = 'full_name'
    ) THEN
        RAISE EXCEPTION 'ERROR: staff_invitations table missing full_name column!';
    END IF;

    RAISE NOTICE '✅ Cleanup complete. staff_invitations is the active table.';
    RAISE NOTICE '✅ staff_invites table has been removed.';
END $$;
