-- Unified RLS Policies for Doctor Aliases
-- Allows both Clinical (Primary Doctors) and Pharmacy (Tenants) partners to manage relationships.

-- 1. DROP OLD POLICIES
DROP POLICY IF EXISTS "Primary doctor sees consultants" ON public.doctor_aliases;
DROP POLICY IF EXISTS "Consultant sees own alias" ON public.doctor_aliases;
DROP POLICY IF EXISTS "Primary doctor can invite consultants" ON public.doctor_aliases;
DROP POLICY IF EXISTS "Primary doctor can update consultants" ON public.doctor_aliases;
DROP POLICY IF EXISTS "Primary doctor can delete consultants" ON public.doctor_aliases;
DROP POLICY IF EXISTS "Public can see active consultants" ON public.doctor_aliases;
DROP POLICY IF EXISTS "Tenants can invite partners" ON public.doctor_aliases;

-- 2. CREATE UNIFIED POLICIES

-- SELECT: Allow stakeholders and public (if accepted)
CREATE POLICY "Select doctor aliases" ON public.doctor_aliases
FOR SELECT TO authenticated, anon
USING (
    -- Public can see accepted/active
    (accepted = true AND is_active = true) OR
    -- Owner/Partner can see all their records
    (
        auth.uid() IN (
            SELECT id FROM public.users 
            WHERE tenant_id = doctor_aliases.tenant_partner
        ) OR
        primary_doctor_id IN (
            SELECT id FROM public.healthcare_providers 
            WHERE user_id = auth.uid()
        ) OR
        doctor_id IN (
            SELECT id FROM public.healthcare_providers 
            WHERE user_id = auth.uid()
        )
    )
);

-- INSERT: Allow primary doctors or tenant admins/staff
CREATE POLICY "Insert doctor aliases" ON public.doctor_aliases
FOR INSERT TO authenticated
WITH CHECK (
    (
        tenant_partner IS NOT NULL AND
        tenant_partner IN (SELECT tenant_id FROM public.users WHERE id = auth.uid())
    ) OR
    (
        primary_doctor_id IS NOT NULL AND
        primary_doctor_id IN (SELECT id FROM public.healthcare_providers WHERE user_id = auth.uid())
    )
);

-- UPDATE: Allow the "inviter" (tenant or primary doctor)
CREATE POLICY "Update doctor aliases" ON public.doctor_aliases
FOR UPDATE TO authenticated
USING (
    (
        tenant_partner IS NOT NULL AND
        tenant_partner IN (SELECT tenant_id FROM public.users WHERE id = auth.uid())
    ) OR
    (
        primary_doctor_id IS NOT NULL AND
        primary_doctor_id IN (SELECT id FROM public.healthcare_providers WHERE user_id = auth.uid())
    )
)
WITH CHECK (
    (
        tenant_partner IS NOT NULL AND
        tenant_partner IN (SELECT tenant_id FROM public.users WHERE id = auth.uid())
    ) OR
    (
        primary_doctor_id IS NOT NULL AND
        primary_doctor_id IN (SELECT id FROM public.healthcare_providers WHERE user_id = auth.uid())
    )
);

-- DELETE: Allow the "inviter"
CREATE POLICY "Delete doctor aliases" ON public.doctor_aliases
FOR DELETE TO authenticated
USING (
    (
        tenant_partner IS NOT NULL AND
        tenant_partner IN (SELECT tenant_id FROM public.users WHERE id = auth.uid())
    ) OR
    (
        primary_doctor_id IS NOT NULL AND
        primary_doctor_id IN (SELECT id FROM public.healthcare_providers WHERE user_id = auth.uid())
    )
);

-- Ensure table has RLS enabled
ALTER TABLE public.doctor_aliases ENABLE ROW LEVEL SECURITY;

-- Refine grants
GRANT ALL ON public.doctor_aliases TO authenticated;
GRANT SELECT ON public.doctor_aliases TO anon;
