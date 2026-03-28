-- Add new profile and permission fields to users table
ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS passcode_hash text null,
  ADD COLUMN IF NOT EXISTS profile_picture_url text null,
  ADD COLUMN IF NOT EXISTS gender character varying(10) null,
  ADD COLUMN IF NOT EXISTS onboarding_completed_at timestamp with time zone null,
  ADD COLUMN IF NOT EXISTS onboarding_done boolean null default false,
  -- Permission flags
  ADD COLUMN IF NOT EXISTS "canManagePOS" boolean not null default false,
  ADD COLUMN IF NOT EXISTS "canManageProducts" boolean not null default false,
  ADD COLUMN IF NOT EXISTS "canManage Customers" boolean not null default false,
  ADD COLUMN IF NOT EXISTS "canManageOrders" boolean not null default false,
  ADD COLUMN IF NOT EXISTS "canViewMessages" boolean not null default false,
  ADD COLUMN IF NOT EXISTS "canViewAnalytics" boolean not null default false,
  ADD COLUMN IF NOT EXISTS "canMangeStaff" boolean not null default false,
  ADD COLUMN IF NOT EXISTS "canManageInventory" boolean not null default false,
  ADD COLUMN IF NOT EXISTS "canManageTransfer" boolean not null default false,
  ADD COLUMN IF NOT EXISTS "canManagebranches" boolean not null default false,
  ADD COLUMN IF NOT EXISTS "canManageRoles" boolean not null default false,
  ADD COLUMN IF NOT EXISTS "canManageScrap" boolean not null default false,
  ADD COLUMN IF NOT EXISTS "canTransferProduct" boolean not null default false,
  ADD COLUMN IF NOT EXISTS "canReturnProducts" boolean not null default false;

-- Add check constraint for gender
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_gender_values' AND conrelid = 'public.users'::regclass
    ) THEN
        ALTER TABLE public.users
            ADD CONSTRAINT chk_gender_values CHECK (
                gender IS NULL OR gender IN ('male', 'female', 'other')
            );
    END IF;
END $$;

-- Indexes for new fields
CREATE INDEX IF NOT EXISTS idx_users_passcode_hash ON public.users USING btree (passcode_hash) WHERE (passcode_hash IS NOT NULL);
CREATE INDEX IF NOT EXISTS idx_users_onboarding_completed ON public.users USING btree (onboarding_completed_at) WHERE (onboarding_completed_at IS NULL);
