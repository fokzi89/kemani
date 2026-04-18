-- Relax constraints for clinical messaging
-- Medical users (clinicians) are authenticated via auth.users but may not have a matching record 
-- in the retail-focused public.users table. We make the sender_id foreign key nullable 
-- or remove the strict link to the retail table if it blocks healthcare functionality.

DO $$
BEGIN
    -- Drop the strict foreign key to retail users if it exists
    IF EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'chat_messages_sender_id_fkey'
    ) THEN
        ALTER TABLE public.chat_messages DROP CONSTRAINT chat_messages_sender_id_fkey;
    END IF;

    -- Add a more flexible link or ensure it's just a UUID for the sender
    -- We keep it as a UUID but don't force it to be in the retail table.
    -- It still links via auth.uid() in RLS policies.
END $$;
