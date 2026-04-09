
import { error } from '@sveltejs/kit';
import { createClient } from '@supabase/supabase-js';
import { PUBLIC_SUPABASE_URL, PUBLIC_SUPABASE_ANON_KEY } from '$env/static/public';

const db = createClient(PUBLIC_SUPABASE_URL, PUBLIC_SUPABASE_ANON_KEY);

export async function load({ locals }) {
  const tenantId = locals.referringTenantId;
  const subdomain = locals.subdomain;
  const session = locals.session;

  // If no subdomain and no tenant ID, we are in "Global Discovery" mode
  if (!tenantId && !subdomain) {
    return {
      provider: null,
      session
    };
  }

  // Build tenant query
  const { data: tenant, error: tenantErr } = await db
    .from('tenants')
    .select(`
        id, name, slug, subdomain, logo_url, brand_color,
        phone, email,
        services_offered, ecommerce_settings,
        branches!tenant_id(id, name, address, phone, city)
      `)
    .eq('id', tenantId)
    .is('deleted_at', null)
    .maybeSingle();

  if (tenantErr || !tenant) {
    // If we were supposed to have a tenant but failed, it's a 404
    if (subdomain) throw error(404, `Healthcare provider '${subdomain}' not found`);
    return { provider: null, session };
  }

  const branches = ((tenant?.branches as any[]) || []).map((b: any) => ({
    id: b.id, name: b.name, address: b.address, phone: b.phone, city: b.city
  }));

  const firstBranch = branches[0];

  return {
    session,
    provider: {
      id: tenant.id,
      name: tenant.name,
      slug: tenant.slug,
      subdomain: tenant.subdomain,
      logo_url: tenant.logo_url,
      brand_color: tenant.brand_color || '#003f87',
      city: firstBranch?.city || '',
      phone: tenant.phone || firstBranch?.phone,
      email: tenant.email,
      address: firstBranch?.address || '',
      services_offered: tenant.services_offered || ['chat', 'audio', 'video'],
      branches
    }
  };
}
