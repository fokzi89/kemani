-- Migration: Enable Real-time for Typing Indicators
-- Purpose: Support real-time typing indicators in the chat UI

-- 1. Enable real-time for the table
ALTER PUBLICATION supabase_realtime ADD TABLE chat_typing_indicators;

-- 2. Ensure RLS allows participants to manage their status
-- (Already handled by 20260418000001, but we ensure it's robust here)
DROP POLICY IF EXISTS "Participants can manage typing status" ON public.chat_typing_indicators;
CREATE POLICY "Participants can manage typing status"
ON public.chat_typing_indicators FOR ALL
USING (
    user_id = auth.uid() OR
    conversation_id IN (
        SELECT id FROM public.chat_conversations
        WHERE customer_id = auth.uid() OR 
              auth.uid() IN (SELECT user_id FROM public.healthcare_providers)
    )
);

-- 3. Add a function to automatically refresh expires_at on update
CREATE OR REPLACE FUNCTION refresh_typing_expiry()
RETURNS TRIGGER AS $$
BEGIN
    NEW.expires_at := NOW() + INTERVAL '10 seconds';
    NEW.updated_at := NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_refresh_typing_expiry ON public.chat_typing_indicators;
CREATE TRIGGER trigger_refresh_typing_expiry
    BEFORE UPDATE ON public.chat_typing_indicators
    FOR EACH ROW
    EXECUTE FUNCTION refresh_typing_expiry();
