-- Drop the unused canManageScrap privilege from staff permission tables
ALTER TABLE public.users 
DROP COLUMN IF EXISTS "canManageScrap";

ALTER TABLE public.staff_invitations 
DROP COLUMN IF EXISTS "canManageScrap";
