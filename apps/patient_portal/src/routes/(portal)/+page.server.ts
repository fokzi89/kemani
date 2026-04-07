import { createClient } from '@supabase/supabase-js';
import { PUBLIC_SUPABASE_URL, PUBLIC_SUPABASE_ANON_KEY } from '$env/static/public';

const db = createClient(PUBLIC_SUPABASE_URL, PUBLIC_SUPABASE_ANON_KEY);

export async function load({ parent }) {
  const { provider } = await parent();

  // 1a. Fetch internal medics (doctors) for this provider (Tenant)
  const { data: internalMedics } = await db
    .from('medics')
    .select('id, full_name, specialty, photo_url, bio, years_experience')
    .eq('tenant_id', provider.id)
    .eq('is_active', true)
    .limit(4);

  // 1b. Fetch partner doctors from doctor_aliases
  const { data: aliases } = await db
    .from('doctor_aliases')
    .select(`
      id, doctor_id, alias,
      doctor:healthcare_providers!doctor_id (
        id, full_name, specialization, profile_photo_url, years_of_experience
      )
    `)
    .eq('primary_doctor_id', provider.hcp_id)
    .eq('accepted', true)
    .is('is_active', true)
    .limit(4);

  // Combine both sources
  let medics = [
    ...(internalMedics || []).map(m => ({
      id: m.id,
      full_name: m.full_name,
      specialty: m.specialty,
      photo_url: m.photo_url,
      type: 'internal'
    })),
    ...(aliases || []).map(a => {
      const hp = Array.isArray(a.doctor) ? a.doctor[0] : a.doctor;
      return {
        id: a.doctor_id,
        full_name: hp?.full_name || a.alias || 'Specialist',
        specialty: hp?.specialization || 'Medical Specialist',
        photo_url: hp?.profile_photo_url,
        type: 'partner'
      };
    })
  ].filter(Boolean);

  // 2. Fetch reviews for the Healthcare Provider (Professional Profiling)
  let reviews: any[] = [];
  if (provider.hcp_id) {
    const { data: fetchReviews } = await db
      .from('healthcare_reviews')
      .select(`
        id, rating, comment, created_at,
        patient:patient_id(full_name)
      `)
      .eq('provider_id', provider.hcp_id)
      .eq('is_verified', true)
      .order('created_at', { ascending: false })
      .limit(3);
    
    if (fetchReviews) reviews = fetchReviews;
  }

  // 3. Fetch availability and follow_up_duration
  let schedule: any[] = [];
  let bookedSlots: any[] = [];
  let followUpDuration = 24;
  let slotDuration = 30;

  if (provider.hcp_id) {
    const { data: hcpData } = await db
      .from('healthcare_providers')
      .select('follow_up_duration, slot_duration_minutes')
      .eq('id', provider.hcp_id)
      .single();
    
    if (hcpData) {
      followUpDuration = hcpData.follow_up_duration || 24;
      slotDuration = hcpData.slot_duration_minutes || 30;
    }

    const { data: availData } = await db
      .from('provider_availability_templates')
      .select('*')
      .eq('provider_id', provider.hcp_id)
      .eq('is_closed', false)
      .order('day_of_week', { ascending: true });
    
    if (availData) schedule = availData;

    const todayDate = new Date().toISOString().split('T')[0];
    const { data: bSlots } = await db
      .from('provider_time_slots')
      .select('date, start_time, end_time, status')
      .eq('provider_id', provider.hcp_id)
      .gte('date', todayDate)
      .in('status', ['booked', 'in_progress', 'held_for_payment']);
      
    if (bSlots) bookedSlots = bSlots;
  }

  return { 
    medics,
    bookedSlots,
    reviews: reviews.map((r: any) => ({
      id: r.id,
      rating: r.rating,
      comment: r.comment,
      created_at: r.created_at,
      reviewer_name: r.patient?.full_name || 'Anonymous Patient'
    })),
    schedule,
    followUpDuration,
    slotDuration
  };
}
