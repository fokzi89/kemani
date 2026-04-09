
import { error } from '@sveltejs/kit';

export async function load({ locals }) {
  const tenantId = locals.referringTenantId;
  const hcpId = locals.referringHcpId;
  const subdomain = locals.subdomain;
  const session = locals.session;
  const db = locals.supabase;

  // Global Discovery mode — no subdomain at all
  if (!subdomain) {
    return { provider: null, session };
  }

  // --- MODE A: Tenant-based portal (pharmacy/clinic with tenant record) ---
  if (tenantId) {
    const { data: tenant, error: tenantErr } = await db
      .from('tenants')
      .select(`
          id, name, slug, subdomain, logo_url, brand_color,
          phone, email, services_offered, ecommerce_settings,
          branches!tenant_id(id, name, address, phone, city)
        `)
      .eq('id', tenantId)
      .is('deleted_at', null)
      .maybeSingle();

    if (tenantErr) {
      console.error('[Layout] Tenant fetch error:', tenantErr.message);
      throw error(500, 'Error loading provider data');
    }

    if (!tenant) throw error(404, `Provider '${subdomain}' not found`);

    // Try to also find matching HCP by slug for richer data
    const { data: hcp } = await db
      .from('healthcare_providers')
      .select(`
        id, full_name, specialization, sub_specialty, years_of_experience,
        average_rating, total_reviews, profile_photo_url, bio, is_verified,
        follow_up_duration, slot_duration_minutes, clinic_address, phone, email,
        chatMarkUp, chatFee, audioMarkUp, audioFee, videoMarkUp, videoFee,
        officeMarkUp, officeFee, offerChat, offerAudio, offersVideo, offerOfficeVisit
      `)
      .eq('slug', tenant.slug)
      .maybeSingle();

    const branches = ((tenant.branches as any[]) || []).map((b: any) => ({
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

  // --- MODE B: HCP-direct portal (medic has no tenant, identified by slug) ---
  if (hcpId) {
    const { data: hcp, error: hcpErr } = await db
      .from('healthcare_providers')
      .select(`
        id, full_name, slug, specialization, sub_specialty, years_of_experience,
        average_rating, total_reviews, profile_photo_url, bio, is_verified,
        follow_up_duration, slot_duration_minutes, clinic_address, phone, email,
        chatMarkUp, chatFee, audioMarkUp, audioFee, videoMarkUp, videoFee,
        officeMarkUp, officeFee, offerChat, offerAudio, offersVideo, offerOfficeVisit
      `)
      .eq('id', hcpId)
      .single();

    if (hcpErr || !hcp) throw error(404, `Provider '${subdomain}' not found`);

    return {
      session,
      provider: {
        id: hcp.id,        // Use hcp.id as both tenant and hcp id in this mode
        hcp_id: hcp.id,
        name: hcp.full_name,
        slug: hcp.slug,
        subdomain: hcp.slug,
        logo_url: hcp.profile_photo_url || null,
        brand_color: '#003f87',
        city: (hcp.clinic_address as any)?.city || '',
        phone: hcp.phone,
        email: hcp.email,
        address: (hcp.clinic_address as any)?.street || '',
        description: hcp.bio || '',
        category: hcp.specialization || 'Healthcare Provider',
        sub_specialty: hcp.sub_specialty || '',
        services_offered: [
          hcp.offerChat && 'chat',
          hcp.offerAudio && 'audio',
          hcp.offersVideo && 'video',
          hcp.offerOfficeVisit && 'office_visit'
        ].filter(Boolean),
        average_rating: hcp.average_rating || 0,
        total_reviews: hcp.total_reviews || 0,
        years_experience: hcp.years_of_experience || 0,
        is_verified: hcp.is_verified || false,
        fees: {
          chat: hcp.chatMarkUp || hcp.chatFee || 5000,
          audio: hcp.audioMarkUp || hcp.audioFee || 8000,
          video: hcp.videoMarkUp || hcp.videoFee || 10000,
          office_visit: hcp.officeMarkUp || hcp.officeFee || 15000
        },
        branches: []
      }
    };
  }

  // Subdomain exists but resolves to nothing
  throw error(404, `Provider '${subdomain}' not found`);
}
