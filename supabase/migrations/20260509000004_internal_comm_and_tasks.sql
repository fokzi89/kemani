-- ============================================================
-- Migration: Internal Communication & Task System
-- ============================================================
-- Description: Adds infrastructure for staff-to-staff chat, 
--              tenant-wide task management, and enhanced 
--              real-time notifications.
-- ============================================================

-- 1. Extend chat_conversations for Internal Use
DO $$ 
BEGIN
    -- Add recipient_id for internal chats
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'chat_conversations' AND column_name = 'recipient_id') THEN
        ALTER TABLE public.chat_conversations ADD COLUMN recipient_id UUID REFERENCES public.users(id);
    END IF;

    -- Update chatType constraint to include 'Internal'
    ALTER TABLE public.chat_conversations DROP CONSTRAINT IF EXISTS chat_conversations_chatType_check;
    ALTER TABLE public.chat_conversations 
    ADD CONSTRAINT chat_conversations_chatType_check 
    CHECK ("chatType" = ANY (ARRAY['Customer Support'::text, 'Consultation'::text, 'Internal'::text]));
END $$;

-- 2. Staff Tasks Table
CREATE TABLE IF NOT EXISTS public.staff_tasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
    creator_id UUID NOT NULL REFERENCES public.users(id),
    assignee_id UUID REFERENCES public.users(id), -- Nullable for unassigned tasks
    
    title TEXT NOT NULL,
    description TEXT,
    priority TEXT NOT NULL DEFAULT 'medium', -- 'low', 'medium', 'high', 'urgent'
    status TEXT NOT NULL DEFAULT 'todo', -- 'todo', 'in_progress', 'completed', 'cancelled'
    
    due_date TIMESTAMPTZ,
    conversation_id UUID REFERENCES public.chat_conversations(id) ON DELETE SET NULL,
    
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3. Enhance staff_notifications
ALTER TABLE public.staff_notifications 
ADD COLUMN IF NOT EXISTS action_url TEXT,
ADD COLUMN IF NOT EXISTS category TEXT DEFAULT 'general', -- 'inventory', 'sale', 'task', 'chat'
ADD COLUMN IF NOT EXISTS priority TEXT DEFAULT 'info';    -- 'info', 'warning', 'critical'

-- 4. Indexes
CREATE INDEX IF NOT EXISTS idx_staff_tasks_tenant_status ON public.staff_tasks(tenant_id, status);
CREATE INDEX IF NOT EXISTS idx_staff_tasks_assignee ON public.staff_tasks(assignee_id);
CREATE INDEX IF NOT EXISTS idx_staff_notifications_category ON public.staff_notifications(category);

-- 5. RLS Policies for Staff Tasks (Tenant-Wide)
ALTER TABLE public.staff_tasks ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Staff can view all tasks in their tenant" ON public.staff_tasks;
CREATE POLICY "Staff can view all tasks in their tenant"
    ON public.staff_tasks FOR SELECT
    USING (
        tenant_id IN (
            SELECT tenant_id FROM public.users WHERE id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Managers can manage tasks" ON public.staff_tasks;
CREATE POLICY "Managers can manage tasks"
    ON public.staff_tasks FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.users
            WHERE id = auth.uid()
            AND role IN ('tenant_admin', 'branch_manager')
            AND tenant_id = staff_tasks.tenant_id
        )
    );

DROP POLICY IF EXISTS "Assignees can update their tasks" ON public.staff_tasks;
CREATE POLICY "Assignees can update their tasks"
    ON public.staff_tasks FOR UPDATE
    USING (assignee_id = auth.uid());

-- 6. Trigger for updated_at
DROP TRIGGER IF EXISTS tr_set_updated_at_staff_tasks ON public.staff_tasks;
CREATE TRIGGER tr_set_updated_at_staff_tasks
    BEFORE UPDATE ON public.staff_tasks
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at();

-- 7. Internal Chat Visibility RLS
-- Allow participants of internal chats (initiator OR recipient) to see them
DROP POLICY IF EXISTS "Staff can view internal chats" ON public.chat_conversations;
CREATE POLICY "Staff can view internal chats"
    ON public.chat_conversations FOR SELECT
    USING (
        tenant_id IN (SELECT tenant_id FROM public.users WHERE id = auth.uid())
        AND (
            "chatType" != 'Internal'
            OR service_provider = auth.uid()
            OR recipient_id = auth.uid()
        )
    );

-- 8. Audit Note
COMMENT ON TABLE public.staff_tasks IS 'Tenant-wide task management for organization coordination.';
