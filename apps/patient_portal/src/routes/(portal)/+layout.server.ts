
import { error } from '@sveltejs/kit';

export async function load({ locals }) {
  const tenantId = locals.referringTenantId;
  const subdomain = locals.subdomain;
  const session = locals.session;
  const db = locals.supabase;

  // If no subdomain and no tenant ID, we are in "Global Discovery" mode
  if (!tenantId && !subdomain) {
    return {
      provider: null,
      session
    };
  }

  if (!tenantId) {
    // We have a subdomain but couldn't resolve it to a tenant
    throw error(404, `Healthcare provider '${subdomain}' not found`);
  }

  // Build tenant query - get tenant with branches
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

  if (tenantErr) {
    console.error('[Layout] Tenant fetch error:', tenantErr);
    throw error(500, 'Error loading provider data');
  }

  if (!tenant) {
    if (subdomain) throw error(404, `Healthcare provider '${subdomain}' not found`);
    return { provider: null, session };
  }

  // Look up associated healthcare provider (medic) by slug
  const { data: hcp } = await db
    .from('healthcare_providers')
    .select(`
      id, slug, full_name, specialization, sub_specialty,
      years_of_experience, average_rating, total_reviews,
      profile_photo_url, bio, is_verified,
      follow_up_duration, slot_duration_minutes,
      chatMarkUp, chatFee, audioMarkUp, audioFee,
      videoMarkUp, videoFee, officeMarkUp, officeFee,
      offerChat, offerAudio, offersVideo, offerOfficeVisit,
      clinic_address, phone, email
    `)
    .eq('slug', tenant.slug)
    .maybeSingle();

  const branches = ((tenant?.branches as any[]) || []).map((b: any) => ({
    id: b.id, name: b.name, address: b.address, phone: b.phone, city: b.city
  }));

  const firstBranch = branches[0];

  return {
    session,
    provider: {
      id: tenant.id,
      hcp_id: hcp?.id || null,
      name: hcp?.full_name || tenant.name,
      slug: tenant.slug,
      subdomain: tenant.subdomain,
      logo_url: hcp?.profile_photo_url || tenant.logo_url,
      brand_color: tenant.brand_color || '#003f87',
      city: firstBranch?.city || (hcp?.clinic_address as any)?.city || '',
      phone: hcp?.phone || tenant.phone || firstBranch?.phone,
      email: hcp?.email || tenant.email,
      address: (hcp?.clinic_address as any)?.street || firstBranch?.address || '',
      description: hcp?.bio || '',
      category: hcp?.specialization || 'Healthcare Provider',
      sub_specialty: hcp?.sub_specialty || '',
      services_offered: hcp
        ? [
            hcp.offerChat && 'chat',
            hcp.offerAudio && 'audio',
            hcp.offersVideo && 'video',
            hcp.offerOfficeVisit && 'office_visit'
          ].filter(Boolean)
        : (tenant.services_offered || ['chat', 'audio', 'video']),
      average_rating: hcp?.average_rating || 0,
      total_reviews: hcp?.total_reviews || 0,
      years_experience: hcp?.years_of_experience || 0,
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
