-- Doctor Aliases Table
-- Creates system-generated aliases for secondary doctors to protect their identity
-- Format: "Afoke A. (Kome Clinic)" - First name + Last initial + (Clinic Name)

-- Create the doctor_aliases table
CREATE TABLE public.doctor_aliases (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  doctor_id uuid NOT NULL REFERENCES public.healthcare_providers (id) ON DELETE CASCADE,
  primary_doctor_id uuid NOT NULL REFERENCES public.healthcare_providers (id) ON DELETE CASCADE,
  alias character varying(100) NOT NULL,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  accepted boolean NOT NULL DEFAULT false,
  clinic_name text NULL,
  CONSTRAINT doctor_aliases_pkey PRIMARY KEY (id),
  CONSTRAINT doctor_aliases_unique_active UNIQUE (doctor_id, primary_doctor_id, is_active)
) TABLESPACE pg_default;

COMMENT ON TABLE public.doctor_aliases IS 'Links secondary doctors to primary doctors with system-generated aliases to protect identity during patient consultations';

-- Index for finding consultants by primary doctor
CREATE INDEX idx_doctor_aliases_primary_doctor 
ON public.doctor_aliases USING btree (primary_doctor_id, is_active) 
WHERE is_active = true;

-- Index for finding primary doctor by consultant
CREATE INDEX idx_doctor_aliases_doctor 
ON public.doctor_aliases USING btree (doctor_id, is_active) 
WHERE is_active = true;

-- Enable RLS
ALTER TABLE public.doctor_aliases ENABLE ROW LEVEL SECURITY;

-- RLS Policies for the table (not for the view)

-- Policy: Primary doctor can see their consultants' aliases
CREATE POLICY "Primary doctor sees consultants" 
ON public.doctor_aliases FOR SELECT 
USING (
  primary_doctor_id IN (
    SELECT id FROM public.healthcare_providers 
    WHERE user_id = auth.uid()
  )
);

-- Policy: Consultant can see their own alias
CREATE POLICY "Consultant sees own alias" 
ON public.doctor_aliases FOR SELECT 
USING (
  doctor_id IN (
    SELECT id FROM public.healthcare_providers 
    WHERE user_id = auth.uid()
  )
);

-- Helper function to generate alias from provider data
-- Format: "FirstName L. (Clinic Name)" e.g., "Afoke A. (Kome Clinic)"
CREATE OR REPLACE FUNCTION public.generate_doctor_alias(
  p_doctor_first_name TEXT,
  p_doctor_last_name TEXT,
  p_clinic_name TEXT
) RETURNS TEXT AS $$
DECLARE
  v_first_name TEXT;
  v_last_initial TEXT;
  v_clean_clinic_name TEXT;
BEGIN
  -- Get first name (full)
  v_first_name := INITCAP(TRIM(p_doctor_first_name));
  
  -- Get last name initial
  v_last_initial := UPPER(LEFT(TRIM(p_doctor_last_name), 1));
  
  -- Clean clinic name: remove special chars, limit to 30 chars
  v_clean_clinic_name := INITCAP(
    TRIM(
      SUBSTRING(
        regexp_replace(p_clinic_name, '[^a-zA-Z0-9\s]', '', 'g'),
        1,
        30
      )
    )
  );
  
  -- Format: Afoke A. (Kome Clinic)
  RETURN v_first_name || ' ' || v_last_initial || '. (' || v_clean_clinic_name || ')';
END;
$$ LANGUAGE plpgsql IMMUTABLE;

COMMENT ON FUNCTION public.generate_doctor_alias IS 'Generates a system alias in format: FirstName L. (Clinic Name)';

-- Function to create alias for a secondary doctor
-- Note: Uses "clinic name" with double quotes to reference column with space
CREATE OR REPLACE FUNCTION public.create_doctor_alias(
  p_doctor_id UUID,
  p_primary_doctor_id UUID
) RETURNS UUID AS $$
DECLARE
  v_alias TEXT;
  v_doctor_first_name TEXT;
  v_doctor_last_name TEXT;
  v_clinic_name TEXT;
  v_alias_id UUID;
BEGIN
  -- Get secondary doctor full name
  SELECT hp.full_name INTO v_doctor_first_name
  FROM public.healthcare_providers hp
  WHERE hp.id = p_doctor_id;

  -- Split name into first and last
  v_doctor_first_name := SPLIT_PART(v_doctor_first_name, ' ', 1);
  v_doctor_last_name := COALESCE(
    SPLIT_PART(v_doctor_first_name, ' ', 2),
    SPLIT_PART(v_doctor_first_name, ' ', 1)
  );

  -- Get clinic name from primary doctor (use quoted column name "clinic name")
  SELECT COALESCE(hp."clinic name", hp.full_name) INTO v_clinic_name
  FROM public.healthcare_providers hp
  WHERE hp.id = p_primary_doctor_id;

  -- Generate alias
  v_alias := public.generate_doctor_alias(
    v_doctor_first_name,
    v_doctor_last_name,
    v_clinic_name
  );

  -- Insert or update alias (idempotent)
  INSERT INTO public.doctor_aliases (
    doctor_id,
    primary_doctor_id,
    alias,
    is_active,
    created_at
  )
  VALUES (
    p_doctor_id,
    p_primary_doctor_id,
    v_alias,
    true,
    NOW()
  )
  ON CONFLICT (doctor_id, primary_doctor_id, is_active) 
  DO UPDATE SET alias = EXCLUDED.alias
  RETURNING id INTO v_alias_id;

  RETURN v_alias_id;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION public.create_doctor_alias IS 'Creates or updates a system-generated alias for a secondary doctor';

-- View to display alias info with provider details (read-only, RLS inherited from base table)
-- Uses quoted column name "clinic name" 
CREATE OR REPLACE VIEW public.doctor_aliases_with_details AS
SELECT
  da.id,
  da.doctor_id,
  da.primary_doctor_id,
  da.alias,
  da.is_active,
  da.created_at,
  -- Provider details from healthcare_providers
  hp.full_name AS doctor_name,
  hp.profile_photo_url,
  hp.specialization,
  hp.sub_specialty,
  hp.years_of_experience,
  hp.consultation_types,
  hp.marked_up_fees AS consultation_fees,
  hp.preferred_languages,
  hp.average_rating,
  hp.total_consultations,
  hp.total_reviews,
  hp.is_verified,
  -- Primary doctor info (using quoted column name "clinic name")
  hp_primary.full_name AS primary_doctor_name,
  COALESCE(hp_primary."clinic name", hp_primary.full_name) AS clinic_name
FROM public.doctor_aliases da
JOIN public.healthcare_providers hp 
  ON da.doctor_id = hp.id
JOIN public.healthcare_providers hp_primary 
  ON da.primary_doctor_id = hp_primary.id
WHERE da.is_active = true;

COMMENT ON VIEW public.doctor_aliases_with_details IS 'Doctor aliases with full provider details for display in consultations';

-- Grant permissions (views don't need RLS policies)
GRANT SELECT ON public.doctor_aliases TO authenticated;
GRANT SELECT ON public.doctor_aliases_with_details TO authenticated;
GRANT SELECT ON public.doctor_aliases TO anon;
GRANT SELECT ON public.doctor_aliases_with_details TO anon;
GRANT EXECUTE ON FUNCTION public.generate_doctor_alias TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_doctor_alias TO authenticated;

-- Add foreign key indexes
CREATE INDEX idx_doctor_aliases_doctor_fkey 
ON public.doctor_aliases USING btree (doctor_id);

CREATE INDEX idx_doctor_aliases_primary_fkey 
ON public.doctor_aliases USING btree (primary_doctor_id);
