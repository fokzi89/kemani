import { createClient } from '@supabase/supabase-js';
import { PUBLIC_SUPABASE_URL, PUBLIC_SUPABASE_ANON_KEY } from '$env/static/public';

const db = createClient(PUBLIC_SUPABASE_URL, PUBLIC_SUPABASE_ANON_KEY);

export async function load({ parent }) {
  const { provider } = await parent();
  const providerCity = provider?.city || '';

  // Step 1: Fetch pharmacy/supermarket branches
  const { data: pharmacyBranches, error: fetchErr } = await db
    .from('branches')
    .select('id, city, address, phone, business_type, tenant_id')
    .is('deleted_at', null)
    .in('business_type', ['pharmacy', 'pharmacy_supermarket', 'supermarket']);

  if (fetchErr) {
    console.error('[Pharmacies Load] Branches fetch error:', fetchErr);
    return { pharmacies: [], city: providerCity };
  }

  if (!pharmacyBranches || pharmacyBranches.length === 0) {
    return { pharmacies: [], city: providerCity };
  }

  // Step 2: Get tenant IDs from branches and fetch tenant details separately (avoids RLS issues on inner join)
  const tenantIds = [...new Set(pharmacyBranches.map((b: any) => b.tenant_id).filter(Boolean))];
  
  const { data: tenants, error: tenantErr } = await db
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
        display_type: (b.business_type || 'pharmacy').replace(/_/g, ' ')
      };
    })
    .filter(Boolean);

  return { pharmacies, city: providerCity };
}

