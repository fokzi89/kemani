-- Migration: Chat Queue System
-- Implements one-at-a-time consultation logic

-- 1. Handle dependencies and alter status column
DO $$
BEGIN
    -- Drop all dependencies first
    DROP VIEW IF EXISTS public.available_pharmacists;
    DROP INDEX IF EXISTS public.idx_chat_conversations_status;
    DROP INDEX IF EXISTS public.idx_chat_status;

    -- Remove default to avoid type mismatch during alter
    ALTER TABLE public.chat_conversations ALTER COLUMN status DROP DEFAULT;

    -- Alter column to TEXT with explicit cast
    -- We use varchar first then text as a workaround for some PG versions if needed
    ALTER TABLE public.chat_conversations 
    ALTER COLUMN status TYPE TEXT USING status::text;
    
    -- Restore default
    ALTER TABLE public.chat_conversations ALTER COLUMN status SET DEFAULT 'active';

    -- Update/Add check constraints
    ALTER TABLE public.chat_conversations DROP CONSTRAINT IF EXISTS chat_conversations_status_check;
    ALTER TABLE public.chat_conversations DROP CONSTRAINT IF EXISTS chat_conversations_status_check1;
    
    -- Re-add the constraint as TEXT check
    ALTER TABLE public.chat_conversations ADD CONSTRAINT chat_conversations_status_check 
    CHECK (status IN ('active', 'waiting', 'completed', 'archived', 'deleted', 'escalated', 'abandoned', 'open'));

    -- Re-create the index
    CREATE INDEX idx_chat_conversations_status ON public.chat_conversations(status);
END $$;

-- 2. Recreate the available_pharmacists view
CREATE OR REPLACE VIEW public.available_pharmacists AS
-- Staff Pharmacists
SELECT 
    u.id as id,
    u.id as user_id,
    u.full_name as display_name,
    u.avatar_url as photo_url,
    'Pharmacist' as specialization,
    u.tenant_id,
    'Inhouse' as provider_type,
    NULL::uuid as provider_id,
    5.0 as average_rating,
    0 as total_reviews,
    5 as years_of_experience,
    true as is_verified,
    (SELECT count(*)::int FROM public.chat_conversations WHERE service_provider = u.id AND status = 'active') as active_chats_count,
    (u.deleted_at IS NULL) as is_active
FROM public.users u
WHERE u.role = 'pharmacist'

UNION ALL

-- Freelance Pharmacists
SELECT 
    da.id as id,
    p.user_id,
    da.alias as display_name,
    p.profile_photo_url as photo_url,
    p.specialization,
    da.tenant_partner as tenant_id,
    'Freelance' as provider_type,
    p.id as provider_id,
    COALESCE(p.average_rating, 0.0) as average_rating,
    COALESCE(p.total_reviews, 0) as total_reviews,
    COALESCE(p.years_of_experience, 0) as years_of_experience,
    p.is_verified,
    (SELECT count(*)::int FROM public.chat_conversations WHERE service_provider = p.user_id AND status = 'active') as active_chats_count,
    da.is_active
FROM public.doctor_aliases da
JOIN public.healthcare_providers p ON da.doctor_id = p.id
WHERE da.accepted = true AND p.type = 'pharmacist';

-- 3. Function to get queue position
CREATE OR REPLACE FUNCTION public.get_chat_queue_position(p_conversation_id UUID)
RETURNS INTEGER AS $$
DECLARE
    v_provider_id UUID;
    v_created_at TIMESTAMPTZ;
    v_pos INTEGER;
BEGIN
    -- Get conversation details
    SELECT service_provider, created_at INTO v_provider_id, v_created_at
    FROM public.chat_conversations
    WHERE id = p_conversation_id;

    IF v_provider_id IS NULL THEN RETURN 0; END IF;

    -- Count how many 'waiting' chats for this provider were created before this one
    SELECT count(*)::int + 1 INTO v_pos
    FROM public.chat_conversations
    WHERE service_provider = v_provider_id
      AND status = 'waiting'
      AND created_at <= v_created_at;

    RETURN v_pos;
END;
$$ LANGUAGE plpgsql STABLE;

-- 4. Trigger to automatically queue if provider is busy
CREATE OR REPLACE FUNCTION public.handle_chat_queue_on_create()
RETURNS TRIGGER AS $$
DECLARE
    v_active_count INTEGER;
BEGIN
    -- Only apply if a specific service provider is assigned
    IF NEW.service_provider IS NOT NULL THEN
        -- Check if provider has any active chats
        SELECT count(*)::int INTO v_active_count
        FROM public.chat_conversations
        WHERE service_provider = NEW.service_provider
          AND status = 'active';

        -- If busy, move to waiting
        IF v_active_count > 0 AND NEW.status = 'active' THEN
            NEW.status := 'waiting';
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_handle_chat_queue_on_create ON public.chat_conversations;
CREATE TRIGGER trigger_handle_chat_queue_on_create
    BEFORE INSERT ON public.chat_conversations
    FOR EACH ROW
    EXECUTE FUNCTION handle_chat_queue_on_create();
