-- Migration: Add Pharmacist Mode to Tenants
-- Replaces freelance_pharmacist_enable with pharmacist_mode enum

-- 1. Remove old boolean column if it exists
ALTER TABLE public.tenants DROP COLUMN IF EXISTS freelance_pharmacist_enable;

-- 2. Add pharmacist_mode column
ALTER TABLE public.tenants ADD COLUMN IF NOT EXISTS pharmacist_mode TEXT NOT NULL DEFAULT 'Inhouse';

-- 3. Add constraint for mode
ALTER TABLE public.tenants DROP CONSTRAINT IF EXISTS tenants_pharmacist_mode_check;
ALTER TABLE public.tenants ADD CONSTRAINT tenants_pharmacist_mode_check 
CHECK (pharmacist_mode IN ('Inhouse', 'Freelance', 'Both'));

-- 4. Set default for existing tenants based on doctor partnership
UPDATE public.tenants SET pharmacist_mode = 'Both' WHERE "allowDoctorPartnerShip" = true;
UPDATE public.tenants SET pharmacist_mode = 'Inhouse' WHERE "allowDoctorPartnerShip" = false;

-- 5. Create a unified view for pharmacists (Staff + Partners)
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

GRANT SELECT ON public.available_pharmacists TO authenticated;
GRANT SELECT ON public.available_pharmacists TO anon;

COMMENT ON COLUMN public.tenants.pharmacist_mode IS 'Determines who handles pharmacy consultations: Inhouse staff, Freelance partners, or Both.';
