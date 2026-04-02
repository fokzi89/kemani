import { error, redirect } from '@sveltejs/kit';
import { supabase } from '$lib/supabase';

export async function load({ locals, params }: { locals: any; params: { slug?: string } }) {
  // 1. Try to get tenant from locals (resolved by subdomain in hooks.server.ts)
  let tenantId = locals.referringTenantId;
  let slug = params.slug;

  console.log(`[Storefront] Loader - Subdomain Tenant ID: ${tenantId}, Path Slug: ${slug}`);

  // 2. If no tenant ID from subdomain, try to resolve the path slug
  if (!tenantId && slug) {
    const isUUID = /^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$/.test(slug);
    
    // Resolve slug to ID
    const { data: tenantRef } = isUUID 
      ? await supabase.from('tenants').select('id').eq('id', slug).single()
      : await supabase.from('tenants').select('id').eq('slug', slug).single();
      
    if (tenantRef) tenantId = tenantRef.id;
  }

  // 3. Fallback to a default or error if no tenant identified
  if (!tenantId) {
     const dbDump = await supabase.from('tenants').select('id, name, slug, subdomain, ecommerce_enabled');
     throw error(404, "No storefront identified. Host parsed context: locals.referringTenantId=" + locals.referringTenantId + " | URL param=" + slug);
  }

  const selectFields = `
    id, name, slug, logo_url, brand_color,
    ecommerce_enabled, subdomain, custom_domain,
    services_offered, ecommerce_settings,
    branches!tenant_id(id, name, address)
  `;

  // Fetch full tenant data by ID
  const { data: tenant, error: tenantError } = await supabase
    .from('tenants')
    .select(selectFields)
    .eq('id', tenantId)
    .is('deleted_at', null)
    .single();

  if (tenantError) {
    console.error(`[Storefront] Supabase Error for ${tenantId}:`, tenantError);
  }

  // Tenant not found → 404
  if (tenantError || !tenant) {
    throw error(404, `No storefront found for the identified tenant.`);
  }

  // If path-based access was used and we have a subdomain approach, we might want to redirect
  // But for now, let's just allow it.

  // Ecommerce not enabled
  if (tenant.ecommerce_enabled === false) {
    throw error(403, `The storefront for "${tenant.name}" is not currently available.`);
  }

  return {
    tenant: {
      id: tenant.id,
      slug: tenant.slug,
      name: tenant.name,
      logo_url: tenant.logo_url,
      brand_color: tenant.brand_color || '#4f46e5',
      ecommerce_enabled: tenant.ecommerce_enabled,
      subdomain: tenant.subdomain,
      custom_domain: tenant.custom_domain,
      services_offered: tenant.services_offered || [],
      description: (tenant.ecommerce_settings as any)?.description || '',
      banner_url: (tenant.ecommerce_settings as any)?.banner_url || null,
      branches: ((tenant.branches as any[]) || []).map((b: any) => ({
        id: b.id,
        name: b.name,
        address: b.address
      }))
    }
  };
}
