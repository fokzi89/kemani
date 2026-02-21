-- ============================================================================
-- Migration: Chat Attachments Enhancements
-- Feature: 002-ecommerce-storefront (Chat)
-- Description: Allow orphaned attachments and guest uploads
-- ============================================================================

-- Make message_id nullable
ALTER TABLE chat_attachments ALTER COLUMN message_id DROP NOT NULL;
COMMENT ON COLUMN chat_attachments.message_id IS 'Linked message ID (nullable for draft attachments)';

-- Make uploaded_by nullable (for guest uploads)
ALTER TABLE chat_attachments ALTER COLUMN uploaded_by DROP NOT NULL;
COMMENT ON COLUMN chat_attachments.uploaded_by IS 'Uploader ID (NULL for guests)';
