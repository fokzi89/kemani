import { error } from '@sveltejs/kit';
import { createClient } from '@supabase/supabase-js';
import { PUBLIC_SUPABASE_URL, PUBLIC_SUPABASE_ANON_KEY } from '$env/static/public';

const db = createClient(PUBLIC_SUPABASE_URL, PUBLIC_SUPABASE_ANON_KEY);

export async function load({ locals }) {
  let tenantId = locals.referringTenantId;

  const subdomain = locals.hostname?.split(':')[0].endsWith('.localhost') 
    ? locals.hostname.split('.')[0] 
    : (locals.hostname?.split('.').length >= 3 ? locals.hostname.split('.')[0] : null);

  // Fallback: use user-provided provider for testing in local dev only if no subdomain found
  if (!tenantId && !subdomain && locals.hostname?.includes('localhost')) {
    tenantId = 'c03d5466-e403-4721-911f-ebc25ce2a5f2';
  }

  // Build hcp query - prioritization: Subdomain Slug > Tenant ID
  let hcpQuery = db.from('healthcare_providers').select('*');
  if (subdomain) {
    hcpQuery = hcpQuery.eq('slug', subdomain);
  } else if (tenantId) {
    hcpQuery = hcpQuery.eq('id', tenantId);
  } else {
    throw error(404, 'No healthcare provider identified');
  }

  // Attempt to find the professional profile first
  const { data: hcp } = await hcpQuery.maybeSingle();

  // Then build tenant query - prioritize hcp slug if hcp was found
  let tenantQuery = db.from('tenants').select(`
        id, name, slug, subdomain, logo_url, brand_color,
        phone, email,
        services_offered, ecommerce_settings,
        branches!tenant_id(id, name, address, phone, city)
      `).is('deleted_at', null);

  if (hcp?.slug) {
    tenantQuery = tenantQuery.eq('slug', hcp.slug);
  } else if (subdomain) {
    tenantQuery = tenantQuery.eq('slug', subdomain);
  } else if (tenantId) {
    tenantQuery = tenantQuery.eq('id', tenantId);
  }

  // Then try to find the tenant record
  const { data: tenant } = await tenantQuery.maybeSingle();

  if (!hcp && !tenant) throw error(404, 'Healthcare provider data not found');

  const branches = ((tenant?.branches as any[]) || []).map((b: any) => ({
    id: b.id, name: b.name, address: b.address, phone: b.phone, city: b.city
  }));

  const firstBranch = branches[0];

  // Consolidate data, prioritizing professional HCP details over generic Tenant details
  return {
    provider: {
      id: tenant?.id || hcp?.id,
      hcp_id: hcp?.id || 'c03d5466-e403-4721-911f-ebc25ce2a5f2',
      name: hcp?.full_name || tenant?.name || 'Healthcare Provider',
      slug: hcp?.slug || tenant?.slug || 'bolo-bola-f4xkkt',
      subdomain: tenant?.subdomain,
      logo_url: hcp?.profile_photo_url || tenant?.logo_url,
      brand_color: tenant?.brand_color || '#003f87',
      city: firstBranch?.city || hcp?.clinic_address?.city || '',
      description: hcp?.bio || (tenant?.ecommerce_settings as any)?.description || '',
      category: hcp?.specialization || 'Cardiology',
      sub_specialty: hcp?.sub_specialty || 'Pediatric Cardiology',
      banner_url: (tenant?.ecommerce_settings as any)?.banner_url || null,
      phone: hcp?.phone || tenant?.phone || firstBranch?.phone,
      email: hcp?.email || tenant?.email,
      address: hcp?.clinic_address?.street || firstBranch?.address || '',
      services_offered: hcp 
        ? [
            hcp.offerChat && 'chat',
            hcp.offerAudio && 'audio',
            hcp.offersVideo && 'video',
            hcp.offerOfficeVisit && 'office_visit'
          ].filter(Boolean)
        : (tenant?.services_offered || ['chat', 'audio', 'video']),
      average_rating: hcp?.average_rating || 0.00,
      total_reviews: hcp?.total_reviews || 0,
      years_experience: hcp?.years_of_experience || 25,
      is_verified: hcp?.is_verified || false,
      fees: hcp 
        ? {
            chat: hcp.chatMarkUp || hcp.chatFee || 5000,
            audio: hcp.audioMarkUp || hcp.audioFee || 8000,
            video: hcp.videoMarkUp || hcp.videoFee || 10000,
            office_visit: hcp.officeMarkUp || hcp.officeFee || 15000
          }
        : { chat: 5000, audio: 8000, video: 10000 },
      branches
    }
  };
}
