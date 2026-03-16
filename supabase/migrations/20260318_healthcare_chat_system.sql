-- ============================================================================
-- Healthcare Chat System Migration
-- ============================================================================
-- Purpose: Create chat tables for provider-patient-pharmacy-lab communication
-- Features:
-- - Multi-party chat (providers, patients, pharmacies, labs)
-- - File attachments (images, PDFs, voice notes)
-- - Read receipts and typing indicators
-- - Message search and filtering
-- - Conversation archiving
-- ============================================================================

-- ============================================================================
-- 1. CHAT CONVERSATIONS
-- ============================================================================

CREATE TABLE IF NOT EXISTS chat_conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Conversation Type
    conversation_type TEXT NOT NULL CHECK (conversation_type IN ('provider_patient', 'provider_pharmacy', 'provider_lab')),

    -- Participants
    provider_id UUID NOT NULL REFERENCES healthcare_providers(id) ON DELETE CASCADE,
    participant_id UUID NOT NULL, -- patient_id (auth.users.id), pharmacy tenant_id, or lab tenant_id
    participant_type TEXT NOT NULL CHECK (participant_type IN ('patient', 'pharmacy', 'lab')),
    participant_name TEXT, -- Cached for performance
    participant_avatar_url TEXT,

    -- Conversation Metadata
    title TEXT, -- Optional conversation title
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'archived', 'deleted')),

    -- Last Message Info (denormalized for performance)
    last_message_content TEXT,
    last_message_time TIMESTAMPTZ,
    last_message_sender_id UUID,
    last_message_sender_type TEXT CHECK (last_message_sender_type IN ('provider', 'participant')),

    -- Unread Counts
    provider_unread_count INTEGER DEFAULT 0,
    participant_unread_count INTEGER DEFAULT 0,

    -- Related Entities
    consultation_id UUID REFERENCES consultations(id) ON DELETE SET NULL,
    prescription_id UUID REFERENCES prescriptions(id) ON DELETE SET NULL,

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    archived_at TIMESTAMPTZ,

    -- Constraints
    UNIQUE (provider_id, participant_id, participant_type)
);

-- Indexes
CREATE INDEX idx_chat_conversations_provider ON chat_conversations(provider_id, updated_at DESC);
CREATE INDEX idx_chat_conversations_participant ON chat_conversations(participant_id, participant_type, updated_at DESC);
CREATE INDEX idx_chat_conversations_status ON chat_conversations(status, updated_at DESC);
CREATE INDEX idx_chat_conversations_type ON chat_conversations(conversation_type);
CREATE INDEX idx_chat_conversations_unread ON chat_conversations(provider_id) WHERE provider_unread_count > 0;

-- RLS Policies
ALTER TABLE chat_conversations ENABLE ROW LEVEL SECURITY;

-- Providers can view their own conversations
CREATE POLICY "Providers can view own conversations"
    ON chat_conversations FOR SELECT
    USING (provider_id IN (SELECT id FROM healthcare_providers WHERE user_id = auth.uid()));

-- Providers can create conversations
CREATE POLICY "Providers can create conversations"
    ON chat_conversations FOR INSERT
    WITH CHECK (provider_id IN (SELECT id FROM healthcare_providers WHERE user_id = auth.uid()));

-- Providers can update their conversations
CREATE POLICY "Providers can update own conversations"
    ON chat_conversations FOR UPDATE
    USING (provider_id IN (SELECT id FROM healthcare_providers WHERE user_id = auth.uid()));

-- Patients can view conversations they're part of
CREATE POLICY "Patients can view own conversations"
    ON chat_conversations FOR SELECT
    USING (participant_id = auth.uid() AND participant_type = 'patient');

-- ============================================================================
-- 2. CHAT MESSAGES
-- ============================================================================

CREATE TABLE IF NOT EXISTS chat_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID NOT NULL REFERENCES chat_conversations(id) ON DELETE CASCADE,

    -- Sender Info
    sender_id UUID NOT NULL, -- provider.user_id or patient_id or tenant_id
    sender_type TEXT NOT NULL CHECK (sender_type IN ('provider', 'patient', 'pharmacy', 'lab')),
    sender_name TEXT NOT NULL, -- Cached for performance
    sender_avatar_url TEXT,

    -- Message Content
    message_type TEXT DEFAULT 'text' CHECK (message_type IN ('text', 'image', 'file', 'voice', 'system')),
    content TEXT, -- Text content or file description

    -- Attachments
    attachments JSONB DEFAULT '[]', -- [{url, type, name, size, thumbnail_url}]

    -- Message Status
    is_read BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMPTZ,
    is_edited BOOLEAN DEFAULT FALSE,
    edited_at TIMESTAMPTZ,
    is_deleted BOOLEAN DEFAULT FALSE,
    deleted_at TIMESTAMPTZ,

    -- Reply/Thread Support
    reply_to_message_id UUID REFERENCES chat_messages(id) ON DELETE SET NULL,

    -- Metadata
    metadata JSONB, -- For future extensions (reactions, forwarded, etc.)

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_chat_messages_conversation ON chat_messages(conversation_id, created_at DESC);
CREATE INDEX idx_chat_messages_sender ON chat_messages(sender_id, sender_type);
CREATE INDEX idx_chat_messages_unread ON chat_messages(conversation_id, is_read) WHERE is_read = FALSE;
CREATE INDEX idx_chat_messages_type ON chat_messages(message_type);
CREATE INDEX idx_chat_messages_content_search ON chat_messages USING gin(to_tsvector('english', content));

-- RLS Policies
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;

-- Providers can view messages in their conversations
CREATE POLICY "Providers can view conversation messages"
    ON chat_messages FOR SELECT
    USING (
        conversation_id IN (
            SELECT id FROM chat_conversations
            WHERE provider_id IN (SELECT id FROM healthcare_providers WHERE user_id = auth.uid())
        )
    );

-- Providers can send messages
CREATE POLICY "Providers can send messages"
    ON chat_messages FOR INSERT
    WITH CHECK (
        sender_type = 'provider' AND
        conversation_id IN (
            SELECT id FROM chat_conversations
            WHERE provider_id IN (SELECT id FROM healthcare_providers WHERE user_id = auth.uid())
        )
    );

-- Providers can update their own messages (edit, mark as read)
CREATE POLICY "Providers can update own messages"
    ON chat_messages FOR UPDATE
    USING (
        conversation_id IN (
            SELECT id FROM chat_conversations
            WHERE provider_id IN (SELECT id FROM healthcare_providers WHERE user_id = auth.uid())
        )
    );

-- Patients can view messages in their conversations
CREATE POLICY "Patients can view conversation messages"
    ON chat_messages FOR SELECT
    USING (
        conversation_id IN (
            SELECT id FROM chat_conversations
            WHERE participant_id = auth.uid() AND participant_type = 'patient'
        )
    );

-- Patients can send messages
CREATE POLICY "Patients can send messages"
    ON chat_messages FOR INSERT
    WITH CHECK (
        sender_type = 'patient' AND
        sender_id = auth.uid() AND
        conversation_id IN (
            SELECT id FROM chat_conversations
            WHERE participant_id = auth.uid() AND participant_type = 'patient'
        )
    );

-- ============================================================================
-- 3. CHAT ATTACHMENTS METADATA (Optional - for tracking)
-- ============================================================================

CREATE TABLE IF NOT EXISTS chat_attachments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    message_id UUID NOT NULL REFERENCES chat_messages(id) ON DELETE CASCADE,
    conversation_id UUID NOT NULL REFERENCES chat_conversations(id) ON DELETE CASCADE,

    -- File Info
    file_name TEXT NOT NULL,
    file_type TEXT NOT NULL, -- MIME type
    file_size BIGINT NOT NULL, -- bytes
    file_url TEXT NOT NULL, -- Supabase storage URL
    thumbnail_url TEXT, -- For images/videos

    -- File Category
    category TEXT NOT NULL CHECK (category IN ('image', 'document', 'voice', 'video', 'other')),

    -- Upload Info
    uploaded_by UUID NOT NULL,
    uploaded_by_type TEXT NOT NULL CHECK (uploaded_by_type IN ('provider', 'patient', 'pharmacy', 'lab')),

    -- Virus Scan (optional)
    scan_status TEXT DEFAULT 'pending' CHECK (scan_status IN ('pending', 'clean', 'infected', 'failed')),
    scan_result JSONB,

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_chat_attachments_message ON chat_attachments(message_id);
CREATE INDEX idx_chat_attachments_conversation ON chat_attachments(conversation_id, created_at DESC);
CREATE INDEX idx_chat_attachments_category ON chat_attachments(category);
CREATE INDEX idx_chat_attachments_uploader ON chat_attachments(uploaded_by, uploaded_by_type);

-- RLS Policies
ALTER TABLE chat_attachments ENABLE ROW LEVEL SECURITY;

-- Same access as messages
CREATE POLICY "Access follows message access"
    ON chat_attachments FOR SELECT
    USING (
        message_id IN (
            SELECT id FROM chat_messages
            WHERE conversation_id IN (
                SELECT id FROM chat_conversations
                WHERE provider_id IN (SELECT id FROM healthcare_providers WHERE user_id = auth.uid())
                   OR (participant_id = auth.uid() AND participant_type = 'patient')
            )
        )
    );

-- ============================================================================
-- 4. TYPING INDICATORS (Real-time presence)
-- ============================================================================

CREATE TABLE IF NOT EXISTS chat_typing_indicators (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID NOT NULL REFERENCES chat_conversations(id) ON DELETE CASCADE,

    -- Typer Info
    user_id UUID NOT NULL,
    user_type TEXT NOT NULL CHECK (user_type IN ('provider', 'patient', 'pharmacy', 'lab')),
    user_name TEXT NOT NULL,

    -- Status
    is_typing BOOLEAN DEFAULT TRUE,

    -- Timestamps
    started_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    -- Auto-cleanup after 10 seconds of inactivity
    expires_at TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '10 seconds'),

    UNIQUE (conversation_id, user_id, user_type)
);

-- Index
CREATE INDEX idx_typing_indicators_conversation ON chat_typing_indicators(conversation_id, expires_at);

-- RLS Policies
ALTER TABLE chat_typing_indicators ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own typing status"
    ON chat_typing_indicators FOR ALL
    USING (user_id = auth.uid());

-- ============================================================================
-- 5. HELPER FUNCTIONS
-- ============================================================================

-- Update conversation's last message info
CREATE OR REPLACE FUNCTION update_conversation_last_message()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE chat_conversations
    SET
        last_message_content = NEW.content,
        last_message_time = NEW.created_at,
        last_message_sender_id = NEW.sender_id,
        last_message_sender_type = NEW.sender_type,
        updated_at = NOW(),
        -- Increment unread count for the recipient
        provider_unread_count = CASE
            WHEN NEW.sender_type != 'provider' THEN provider_unread_count + 1
            ELSE provider_unread_count
        END,
        participant_unread_count = CASE
            WHEN NEW.sender_type = 'provider' THEN participant_unread_count + 1
            ELSE participant_unread_count
        END
    WHERE id = NEW.conversation_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_conversation_last_message
    AFTER INSERT ON chat_messages
    FOR EACH ROW
    EXECUTE FUNCTION update_conversation_last_message();

-- Mark messages as read
CREATE OR REPLACE FUNCTION mark_messages_as_read(
    p_conversation_id UUID,
    p_reader_type TEXT
)
RETURNS void AS $$
BEGIN
    -- Mark messages as read
    UPDATE chat_messages
    SET is_read = TRUE, read_at = NOW()
    WHERE conversation_id = p_conversation_id
      AND sender_type != p_reader_type
      AND is_read = FALSE;

    -- Reset unread count
    IF p_reader_type = 'provider' THEN
        UPDATE chat_conversations
        SET provider_unread_count = 0
        WHERE id = p_conversation_id;
    ELSE
        UPDATE chat_conversations
        SET participant_unread_count = 0
        WHERE id = p_conversation_id;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Clean up expired typing indicators
CREATE OR REPLACE FUNCTION cleanup_expired_typing_indicators()
RETURNS void AS $$
BEGIN
    DELETE FROM chat_typing_indicators
    WHERE expires_at < NOW();
END;
$$ LANGUAGE plpgsql;

-- Schedule cleanup (requires pg_cron extension)
-- SELECT cron.schedule('cleanup-typing-indicators', '*/30 * * * * *', 'SELECT cleanup_expired_typing_indicators();');

-- ============================================================================
-- 6. INDEXES FOR PERFORMANCE
-- ============================================================================

-- Full-text search on messages
CREATE INDEX IF NOT EXISTS idx_messages_fts ON chat_messages
USING gin(to_tsvector('english', coalesce(content, '')));

-- Conversation search by participant name
CREATE INDEX IF NOT EXISTS idx_conversations_participant_name ON chat_conversations
USING gin(to_tsvector('english', coalesce(participant_name, '')));

-- ============================================================================
-- MIGRATION COMPLETE
-- ============================================================================

-- Summary:
-- ✅ chat_conversations - Main conversation table with participant info
-- ✅ chat_messages - Individual messages with attachments support
-- ✅ chat_attachments - Detailed file tracking
-- ✅ chat_typing_indicators - Real-time typing presence
-- ✅ RLS policies for secure access
-- ✅ Helper functions for message management
-- ✅ Full-text search indexes
-- ✅ Trigger to update last message info
