-- Allow public/anonymous users to view basic tenant information for the storefront
-- This is necessary for slug-based routing to resolve the tenant without authentication
DROP POLICY IF EXISTS "Public can view basic tenant info" ON public.tenants;
CREATE POLICY "Public can view basic tenant info"
  ON public.tenants
  FOR SELECT
  TO public
  USING (deleted_at IS NULL);

-- Allow public/anonymous users to view branch metadata for the storefront
-- Necessary for branch-based product filtering at the storefront
DROP POLICY IF EXISTS "Public can view branches for storefront" ON public.branches;
CREATE POLICY "Public can view branches for storefront"
  ON public.branches
  FOR SELECT
  TO public
  USING (deleted_at IS NULL);

-- Allow public/anonymous users to view products catalog for the storefront
DROP POLICY IF EXISTS "Public can view products for storefront" ON public.products;
CREATE POLICY "Public can view products for storefront"
  ON public.products
  FOR SELECT
  TO public
  USING (is_active IS NOT FALSE AND _sync_is_deleted IS NOT TRUE);

-- Allow public/anonymous users to view branch inventory for the storefront
-- This fulfills the requirement to fetch products via branch_inventory
DROP POLICY IF EXISTS "Public can view inventory for storefront" ON public.branch_inventory;
CREATE POLICY "Public can view inventory for storefront"
  ON public.branch_inventory
  FOR SELECT
  TO public
  USING (is_active IS NOT FALSE AND _sync_is_deleted IS NOT TRUE);

-- Allow authenticated customers to update stock quantities in branch inventory
DROP POLICY IF EXISTS "Customers can update branch inventory" ON public.branch_inventory;
CREATE POLICY "Customers can update branch inventory"
  ON public.branch_inventory
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.customers
      WHERE customers.id = auth.uid()
      AND customers.tenant_id = branch_inventory.tenant_id
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.customers
      WHERE customers.id = auth.uid()
      AND customers.tenant_id = branch_inventory.tenant_id
    )
  );

-- Allow public/anonymous users to view healthcare providers for the storefront Medics page
DROP POLICY IF EXISTS "Public can view healthcare providers" ON public.healthcare_providers;
CREATE POLICY "Public can view healthcare providers"
  ON public.healthcare_providers
  FOR SELECT
  TO public
  USING (status = 'active');
