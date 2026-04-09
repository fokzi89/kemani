
export async function load({ locals, parent }) {
  const { provider } = await parent();
  const providerCity = provider?.city || '';

  // Fetch pharmacy/supermarket branches filtered by correct business types
  // Business types: 'pharmacy', 'pharmacy_supermarket'
  const { data: pharmacyBranches, error: fetchErr } = await locals.supabase
    .from('branches')
    .select('id, name, city, address, phone, business_type, tenant_id')
    .is('deleted_at', null)
    .in('business_type', ['pharmacy', 'pharmacy_supermarket'])
    .order('name');

  if (fetchErr) {
    console.error('[Pharmacies Load] Branches fetch error:', fetchErr.message);
    return { pharmacies: [], city: providerCity, allCities: [] };
  }

  if (!pharmacyBranches || pharmacyBranches.length === 0) {
    return { pharmacies: [], city: providerCity, allCities: [] };
  }

  // Get unique tenant IDs and fetch their branding
  const tenantIds = [...new Set(pharmacyBranches.map((b: any) => b.tenant_id).filter(Boolean))];

  const { data: tenants, error: tenantErr } = await locals.supabase
    .from('tenants')
    .select('id, name, slug, logo_url, brand_color, phone')
    .in('id', tenantIds)
    .is('deleted_at', null);

  if (tenantErr) {
    console.error('[Pharmacies Load] Tenants fetch error:', tenantErr.message);
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
        city: b.city || '',
        address: b.address,
        phone: b.phone || t.phone,
        display_type: b.business_type === 'pharmacy_supermarket' ? 'Pharmacy & Store' : 'Community Pharmacy'
      };
    })
    .filter(Boolean);

  // Collect unique cities for the filter dropdown
  const allCities: string[] = [...new Set(pharmacies.map((p: any) => p.city).filter(Boolean))].sort() as string[];

  return { pharmacies, city: providerCity, allCities };
}
