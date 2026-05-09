-- Migration: Healthcare Commissions V2
-- Formalizes 5.5% prescription fee for all partners and 10% consultation fee for tenants

-- 1. Update prescriptions to reflect all partners (not just pharmacists)
COMMENT ON COLUMN public.prescriptions.is_freelance IS 'True if issued by a freelance partner (doctor or pharmacist), triggering the 5.5% fee.';

-- 2. Add consultation commission tracking to consultations table
ALTER TABLE public.consultations 
ADD COLUMN IF NOT EXISTS tenant_commission_rate DECIMAL(5,4) DEFAULT 0.0000,
ADD COLUMN IF NOT EXISTS tenant_commission_amount DECIMAL(10,2) DEFAULT 0.00;

COMMENT ON COLUMN public.consultations.tenant_commission_rate IS 'Rate of consultation fee that goes to the tenant (e.g., 0.1000 for 10%).';
COMMENT ON COLUMN public.consultations.tenant_commission_amount IS 'Calculated amount from the consultation fee that goes to the tenant.';

-- 3. Trigger to automatically set commission rate for doctors
CREATE OR REPLACE FUNCTION public.calculate_consultation_commissions()
RETURNS TRIGGER AS $$
DECLARE
    v_provider_type TEXT;
BEGIN
    -- Get provider type
    SELECT type INTO v_provider_type
    FROM public.healthcare_providers
    WHERE id = NEW.provider_id;

    -- If referred by storefront and provider is a doctor, set 10% commission
    IF NEW.referral_source = 'storefront' AND v_provider_type = 'doctor' THEN
        NEW.tenant_commission_rate := 0.1000;
        NEW.tenant_commission_amount := NEW.consultation_fee * 0.1000;
    ELSE
        NEW.tenant_commission_rate := 0.0000;
        NEW.tenant_commission_amount := 0.00;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_calculate_consultation_commissions ON public.consultations;
CREATE TRIGGER trigger_calculate_consultation_commissions
    BEFORE INSERT OR UPDATE OF consultation_fee, referral_source ON public.consultations
    FOR EACH ROW
    EXECUTE FUNCTION calculate_consultation_commissions();

-- 4. ENSURE DOCTOR_ALIASES TABLE AND VIEW ARE UPDATED
-- Safety check for the column
ALTER TABLE public.doctor_aliases ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW();

-- Drop view to refresh schema
DROP VIEW IF EXISTS public.doctor_aliases_with_details;

-- We use a dynamic approach for the view to handle potentially missing clinic_name column
DO $$
BEGIN
    EXECUTE 'CREATE OR REPLACE VIEW public.doctor_aliases_with_details AS
    SELECT
      da.id,
      da.doctor_id,
      da.primary_doctor_id,
      da.tenant_partner,
      da.alias as display_name,
      da.alias,
      da.is_active,
      da.created_at,
      da.accepted,
      -- Provider details
      hp.full_name AS doctor_name,
      hp.profile_photo_url,
      hp.specialization,
      hp.sub_specialty,
      hp.years_of_experience,
      hp.average_rating,
      hp.is_verified,
      -- Primary doctor info
      hp_primary.full_name AS primary_doctor_name,
      ' || 
      CASE WHEN EXISTS (
          SELECT 1 FROM information_schema.columns 
          WHERE table_name = 'healthcare_providers' AND column_name = 'clinic_name'
      ) THEN 'COALESCE(hp_primary.clinic_name, hp_primary.full_name)'
      ELSE 'hp_primary.full_name' 
      END || ' AS clinic_name
    FROM public.doctor_aliases da
    JOIN public.healthcare_providers hp ON da.doctor_id = hp.id
    LEFT JOIN public.healthcare_providers hp_primary ON da.primary_doctor_id = hp_primary.id';
END $$;

GRANT SELECT ON public.doctor_aliases_with_details TO authenticated;
GRANT SELECT ON public.doctor_aliases_with_details TO anon;
