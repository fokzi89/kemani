-- 5. PUBLIC SELECT policy (refining existing if any)
DROP POLICY IF EXISTS "Anyone can see healthcare providers" ON public.healthcare_providers;
CREATE POLICY "Anyone can see healthcare providers"
ON public.healthcare_providers FOR SELECT
USING (true);

-- 1. SELECT policies (already exist but refined)
DROP POLICY IF EXISTS "Primary doctor sees consultants" ON public.doctor_aliases;
CREATE POLICY "Primary doctor sees consultants" 
ON public.doctor_aliases FOR SELECT 
USING (
  primary_doctor_id IN (
    SELECT id FROM public.healthcare_providers 
    WHERE user_id = auth.uid()
  )
);

DROP POLICY IF EXISTS "Consultant sees own alias" ON public.doctor_aliases;
CREATE POLICY "Consultant sees own alias" 
ON public.doctor_aliases FOR SELECT 
USING (
  doctor_id IN (
    SELECT id FROM public.healthcare_providers 
    WHERE user_id = auth.uid()
  )
);

-- 2. INSERT policy
-- Allows primary doctor to invite other doctors
DROP POLICY IF EXISTS "Primary doctor can invite consultants" ON public.doctor_aliases;
CREATE POLICY "Primary doctor can invite consultants"
ON public.doctor_aliases FOR INSERT
WITH CHECK (
  primary_doctor_id IN (
    SELECT id FROM public.healthcare_providers 
    WHERE user_id = auth.uid()
  )
);

-- 3. UPDATE policy
-- Allows primary doctor to manage their consultants (e.g. toggle active state)
DROP POLICY IF EXISTS "Primary doctor can update consultants" ON public.doctor_aliases;
CREATE POLICY "Primary doctor can update consultants"
ON public.doctor_aliases FOR UPDATE
USING (
  primary_doctor_id IN (
    SELECT id FROM public.healthcare_providers 
    WHERE user_id = auth.uid()
  )
)
WITH CHECK (
  primary_doctor_id IN (
    SELECT id FROM public.healthcare_providers 
    WHERE user_id = auth.uid()
  )
);

-- 4. DELETE policy
-- Allows primary doctor to remove consultants from their clinic
DROP POLICY IF EXISTS "Primary doctor can delete consultants" ON public.doctor_aliases;
CREATE POLICY "Primary doctor can delete consultants"
ON public.doctor_aliases FOR DELETE
USING (
  primary_doctor_id IN (
    SELECT id FROM public.healthcare_providers 
    WHERE user_id = auth.uid()
  )
);

-- 5. PUBLIC SELECT policy
-- Allows anyone (patients) to see accepted and active consultants for a clinic
DROP POLICY IF EXISTS "Public can see active consultants" ON public.doctor_aliases;
CREATE POLICY "Public can see active consultants"
ON public.doctor_aliases FOR SELECT
USING (accepted = true AND (is_active IS NOT FALSE));

-- Grant the table to authenticated and anon users
GRANT ALL ON public.doctor_aliases TO authenticated;
GRANT SELECT ON public.doctor_aliases TO anon;
