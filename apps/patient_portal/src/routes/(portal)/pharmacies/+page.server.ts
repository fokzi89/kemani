import { createClient } from '@supabase/supabase-js';
import { PUBLIC_SUPABASE_URL, PUBLIC_SUPABASE_ANON_KEY } from '$env/static/public';

const db = createClient(PUBLIC_SUPABASE_URL, PUBLIC_SUPABASE_ANON_KEY);

export async function load({ parent }) {
  const { provider } = await parent();
  const providerCity = provider?.city || '';

  // Fetch actual pharmacies and supermarkets directly from the branches table
  // Joined with tenants for branding information
  const { data: pharmacyBranches, error: fetchErr } = await db
    .from('branches')
    .select(`
      id,
      city,
      address,
      phone,
      business_type,
      tenant_id,
      tenants!inner(
        id,
        name,
        slug,
        logo_url,
        brand_color
      )
    `)
    .is('deleted_at', null)
    .in('business_type', ['pharmacy', 'pharmacy_supermarket', 'supermarket']);

  if (fetchErr) {
    console.error('[Pharmacies Load] Fetch error:', fetchErr);
  }

  const cityLower = providerCity.toLowerCase();
  const pharmacies = (pharmacyBranches || []).map((b: any) => {
    const t = b.tenants || {};
    return {
      id: t.id,
      name: t.name,
      slug: t.slug,
      logo_url: t.logo_url,
      brand_color: t.brand_color,
      branch_id: b.id,
      city: b.city,
      address: b.address,
      phone: b.phone || t.phone,
      display_type: (b.business_type || 'pharmacy').replace('_', ' ')
    };
  });

  return { pharmacies, city: providerCity };
}

