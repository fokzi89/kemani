-- Allow authenticated customers to create conversations
DROP POLICY IF EXISTS "Customers can create conversations" ON public.chat_conversations;
CREATE POLICY "Customers can create conversations"
ON public.chat_conversations FOR INSERT
TO authenticated
WITH CHECK (customer_id = auth.uid());
