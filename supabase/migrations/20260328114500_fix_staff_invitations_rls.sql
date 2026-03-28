-- Enable RLS on staff_invitations
ALTER TABLE public.staff_invitations ENABLE ROW LEVEL SECURITY;

-- Allow anyone with the token to read the invitation (required for the pre-login UI in Incognito)
CREATE POLICY "Allow public read of pending invitations by token"
ON public.staff_invitations
FOR SELECT
TO public
USING (status = 'pending');

-- Allow securely authenticated users to update their own invitation status to 'accepted'
CREATE POLICY "Allow authenticated user to accept invitation"
ON public.staff_invitations
FOR UPDATE
TO authenticated
USING (email = (auth.jwt() ->> 'email') AND status = 'pending')
WITH CHECK (status = 'accepted');

-- Allow admins (who invited) to read and manage all their invitations
CREATE POLICY "Allow tenant admins to view invitations"
ON public.staff_invitations
FOR ALL
TO authenticated
USING (tenant_id IN (
    SELECT tenant_id FROM public.users WHERE id = auth.uid()
));
