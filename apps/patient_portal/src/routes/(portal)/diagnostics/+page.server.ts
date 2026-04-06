import { createClient } from '@supabase/supabase-js';
import { PUBLIC_SUPABASE_URL, PUBLIC_SUPABASE_ANON_KEY } from '$env/static/public';

const db = createClient(PUBLIC_SUPABASE_URL, PUBLIC_SUPABASE_ANON_KEY);

export async function load({ parent }) {
  const { provider } = await parent();
  const providerCity = provider?.city || '';

  const { data: all, error: fetchErr } = await db
    .from('tenants')
    .select('id, name, slug, subdomain, logo_url, brand_color, phone, email, services_offered, ecommerce_settings, branches!tenant_id(city, address, phone)')
    .neq('id', provider?.id || '')
    .is('deleted_at', null)
    .limit(50);

  if (fetchErr) {
    console.error('[Diagnostics Load] Fetch error:', fetchErr);
  }

  const cityLower = providerCity.toLowerCase();
  const keywords = ['diagn', 'lab', 'imaging', 'scan', 'x-ray', 'mri', 'pathol', 'test'];

  const diagnostics = (all || []).filter((t: any) => {
    const svcs = (t.services_offered || []).map((s: string) => s.toLowerCase());
    const name = (t.name || '').toLowerCase();
    const isDiag = svcs.some((s: string) => keywords.some(k => s.includes(k))) ||
                   keywords.some(k => name.includes(k));
    if (!isDiag) return false;

    if (!providerCity) return true;
    const tBranches = t.branches || [];
    return tBranches.some((b: any) => (b.city || '').toLowerCase().includes(cityLower));
  }).map((t: any) => {
    const firstBranch = t.branches?.[0] || {};
    return {
      ...t,
      city: firstBranch.city,
      address: firstBranch.address,
      phone: t.phone || firstBranch.phone
    };
  });

  console.log(`[Diagnostics Load] Found ${all?.length || 0} total, ${diagnostics.length} diagnostics filtered for city: "${providerCity}"`);

  return { diagnostics, city: providerCity };
}
