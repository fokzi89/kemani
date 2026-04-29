-- 1. Ensure the current_tenant_id helper is robust and bypassing RLS
CREATE OR REPLACE FUNCTION current_tenant_id() 
RETURNS UUID AS $$
    SELECT u.tenant_id FROM public.users u WHERE u.id = auth.uid();
$$ LANGUAGE SQL SECURITY DEFINER;

-- 2. Tenants Table: Allow staff to see their assigned tenant
DROP POLICY IF EXISTS "Users can view own tenant" ON public.tenants;
DROP POLICY IF EXISTS "Users can view their own tenant" ON public.tenants;
DROP POLICY IF EXISTS "Users can select their own tenant by email" ON public.tenants;
DROP POLICY IF EXISTS "Public can view basic tenant info" ON public.tenants;

-- Restore public view for storefront slug resolution
CREATE POLICY "Public can view basic tenant info"
    ON public.tenants FOR SELECT
    USING (deleted_at IS NULL);

-- Add explicit staff access
CREATE POLICY "Staff can view their own tenant"
    ON public.tenants FOR SELECT
    USING (id = current_tenant_id());

-- 3. Branches Table: Allow staff to see branches in their tenant
DROP POLICY IF EXISTS "Tenant branch isolation" ON public.branches;
DROP POLICY IF EXISTS "Users can view branches in their tenant" ON public.branches;
DROP POLICY IF EXISTS "Users can view own branch" ON public.branches;
DROP POLICY IF EXISTS "Public can view branches for storefront" ON public.branches;

CREATE POLICY "Public can view branches for storefront"
    ON public.branches FOR SELECT
    USING (deleted_at IS NULL);

CREATE POLICY "Staff can view branches in their tenant"
    ON public.branches FOR SELECT
    USING (tenant_id = current_tenant_id());

-- 4. Users Table: Allow staff to see colleagues
DROP POLICY IF EXISTS "Users can view users in their tenant" ON public.users;
CREATE POLICY "Users can view users in their tenant"
    ON public.users FOR SELECT
    USING (tenant_id = current_tenant_id());

-- 5. Products Table: Ensure staff can see products
DROP POLICY IF EXISTS "Users can view products in their tenant" ON public.products;
CREATE POLICY "Users can view products in their tenant"
    ON public.products FOR SELECT
    USING (tenant_id = current_tenant_id());
