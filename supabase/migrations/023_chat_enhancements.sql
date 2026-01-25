-- ============================================================
-- Migration 011: Chat Enhancements
-- ============================================================
-- Purpose: Extend chat system to support rich media, interactive elements, and plan-based features

-- New enum for extended chat message types
CREATE TYPE chat_message_type AS ENUM (
    'text',
    'image',
    'audio',
    'video',
    'location',
    'product_card',
    'receipt',
    'payment_confirmation',
    'discount_applied',
    'system_action'
);

-- New enum for chat actions
CREATE TYPE chat_action_type AS ENUM (
    'add_to_cart',
    'apply_discount',
    'view_product',
    'confirm_payment',
    'update_delivery_address',
    'request_human_agent'
);

-- Drop and recreate chat_messages table with enhanced schema
DROP TABLE IF EXISTS chat_messages CASCADE;

CREATE TABLE chat_messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    conversation_id UUID NOT NULL REFERENCES chat_conversations(id) ON DELETE CASCADE,
    sender_type sender_type NOT NULL,
    sender_id UUID REFERENCES users(id),

    -- Message content
    message_type chat_message_type DEFAULT 'text',
    message_text TEXT,

    -- Media support
    media_url TEXT,
    media_size_bytes BIGINT CHECK (media_size_bytes > 0),
    media_duration_seconds INTEGER CHECK (media_duration_seconds > 0),
    thumbnail_url TEXT,

    -- Structured data for different message types
    metadata JSONB DEFAULT '{}',
    -- Examples of metadata:
    -- Location: {"latitude": 6.5244, "longitude": 3.3792, "address": "123 Main St"}
    -- Product card: {"product_id": "uuid", "name": "Product Name", "price": 1500, "image_url": "...", "stock": 10}
    -- Discount: {"original_price": 2000, "discount_percent": 10, "final_price": 1800, "discount_code": "SAVE10"}
    -- Receipt: {"receipt_id": "uuid", "amount": 5000, "payment_method": "bank_transfer"}
    -- Payment confirmation: {"reference": "TXN123456", "amount": 5000, "confirmed_at": "2024-01-01T10:00:00Z"}

    -- Interactive actions
    action_type chat_action_type,
    action_data JSONB,
    action_completed_at TIMESTAMPTZ,
    action_completed_by UUID REFERENCES users(id),

    -- AI intent detection
    intent VARCHAR(100),
    confidence_score DECIMAL(3,2) CHECK (confidence_score >= 0 AND confidence_score <= 1),

    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Constraints
    CONSTRAINT text_or_media_required CHECK (
        message_text IS NOT NULL OR media_url IS NOT NULL
    ),
    CONSTRAINT action_requires_data CHECK (
        (action_type IS NULL AND action_data IS NULL) OR
        (action_type IS NOT NULL AND action_data IS NOT NULL)
    )
);

-- Create index for conversation messages
CREATE INDEX idx_chat_messages_conversation ON chat_messages(conversation_id, created_at DESC);
CREATE INDEX idx_chat_messages_type ON chat_messages(message_type, created_at DESC);
CREATE INDEX idx_chat_messages_action ON chat_messages(action_type, action_completed_at)
    WHERE action_type IS NOT NULL;

-- Function to check if tenant has chat feature access
CREATE OR REPLACE FUNCTION has_chat_feature(p_tenant_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    v_plan_tier plan_tier;
BEGIN
    SELECT s.plan_tier INTO v_plan_tier
    FROM tenants t
    JOIN subscriptions s ON t.subscription_id = s.id
    WHERE t.id = p_tenant_id
    AND s.status = 'active';

    -- Chat feature is available for 'pro' and 'enterprise' plans only
    RETURN v_plan_tier IN ('pro', 'enterprise', 'enterprise_custom');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if tenant has growth plan or higher (for e-commerce chat button)
CREATE OR REPLACE FUNCTION has_ecommerce_chat_feature(p_tenant_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    v_plan_tier plan_tier;
    v_features JSONB;
BEGIN
    SELECT s.plan_tier, s.features INTO v_plan_tier, v_features
    FROM tenants t
    JOIN subscriptions s ON t.subscription_id = s.id
    WHERE t.id = p_tenant_id
    AND s.status = 'active';

    -- E-commerce chat is available for 'pro' and 'enterprise' plans
    -- Can also check features JSONB for explicit 'ecommerce_chat' flag
    RETURN v_plan_tier IN ('pro', 'enterprise', 'enterprise_custom')
        OR (v_features->>'ecommerce_chat')::BOOLEAN = true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Add comment to subscriptions.features to document the schema
COMMENT ON COLUMN subscriptions.features IS
'JSONB field for feature flags. Example: {"ecommerce_chat": true, "ai_chat": true, "advanced_analytics": true, "multi_currency": true}';

-- Add helpful comments to the new columns
COMMENT ON COLUMN chat_messages.metadata IS
'Structured data specific to message_type. See migration file for examples.';
COMMENT ON COLUMN chat_messages.action_data IS
'Data for interactive actions. Example: {"product_id": "uuid", "quantity": 2, "cart_id": "uuid"}';
