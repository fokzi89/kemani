
export async function load({ locals, parent }) {
  const { provider } = await parent();
  const providerCity = provider?.city || '';

  // Step 1: Build query for pharmacy/supermarket branches
  let query = locals.supabase
    .from('branches')
    .select('id, name, city, address, phone, business_type, tenant_id')
    .is('deleted_at', null)
    .in('business_type', ['pharmacy', 'pharmacy_supermarket', 'supermarket', 'mini_mart']);

  // If we are on a subdomain (provider exists), narrow down to that tenant's branches
  if (provider?.id) {
    query = query.eq('tenant_id', provider.id);
  }

  const { data: pharmacyBranches, error: fetchErr } = await query;

  if (fetchErr) {
    console.error('[Pharmacies Load] Branches fetch error:', fetchErr);
    return { pharmacies: [], city: providerCity };
  }

  if (!pharmacyBranches || pharmacyBranches.length === 0) {
    return { pharmacies: [], city: providerCity };
  }

  // Step 2: Get tenant IDs from branches and fetch tenant details separately
  const tenantIds = [...new Set(pharmacyBranches.map((b: any) => b.tenant_id).filter(Boolean))];
  
  const { data: tenants, error: tenantErr } = await locals.supabase
    .from('tenants')
    .select('id, name, slug, logo_url, brand_color, phone')
    .in('id', tenantIds)
    .is('deleted_at', null);

  if (tenantErr) {
    console.error('[Pharmacies Load] Tenants fetch error:', tenantErr);
  }

  const tenantMap = new Map((tenants || []).map((t: any) => [t.id, t]));

  const pharmacies = pharmacyBranches
    .map((b: any) => {
      const t = tenantMap.get(b.tenant_id);
      if (!t) return null;
      
      const displayName = b.name.toLowerCase().includes(t.name.toLowerCase()) 
        ? b.name 
        : `${t.name} - ${b.name}`;

      return {
        id: t.id,
        name: displayName,
        company_name: t.name,
        branch_name: b.name,
        slug: t.slug,
        logo_url: t.logo_url,
        brand_color: t.brand_color,
        branch_id: b.id,
        city: b.city,
        address: b.address,
        phone: b.phone || t.phone,
        display_type: (b.business_type || 'pharmacy').replace(/_/g, ' ')
      };
    })
    .filter(Boolean);

  return { pharmacies, city: providerCity };
}
