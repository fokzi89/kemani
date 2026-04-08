import { createClient } from '@supabase/supabase-js';
import { PUBLIC_SUPABASE_URL, PUBLIC_SUPABASE_ANON_KEY } from '$env/static/public';
import { error } from '@sveltejs/kit';

const db = createClient(PUBLIC_SUPABASE_URL, PUBLIC_SUPABASE_ANON_KEY);

export async function load({ params, parent }) {
  const { provider } = await parent();
  const aliasId = params.id;

  // 1. Fetch the doctor alias details from the view
  const { data: alias, error: aliasErr } = await db
    .from('doctor_aliases_with_details')
    .select('*')
    .eq('alias_id', aliasId)
    .single();

  let doctorInfo = null;
  let useFallback = false;

  if (aliasErr || !alias) {
    useFallback = true;
  } else {
    doctorInfo = {
      alias_id: alias.alias_id,
      doctor_id: alias.doctor_id,
      display_name: alias.display_name || alias.actual_name || 'Specialist',
      clinic_alias: alias.clinic_name || null,
      specialization: alias.specialization || 'Medical Specialist',
      sub_specialty: alias.sub_specialty,
      experience: alias.years_of_experience,
      rating: alias.average_rating,
      reviews: alias.total_reviews || 0,
      photo_url: alias.profile_photo_url,
      bio: alias.bio || null,
      is_verified: alias.is_verified,
      brand_color: alias.brand_color || provider?.brand_color || null,
      address: provider?.address,
      city: provider?.city,
      follow_up_duration: provider?.follow_up_duration || 24,
      slot_duration_minutes: provider?.slot_duration_minutes || 30,
      fees: {
        chat: alias.chatMarkUp,
        audio: alias.audioMarkUp,
        video: alias.videoMarkUp,
        office: alias.officeMarkUp
      },
      services_offered: [
        alias.offerChat ? 'chat' : null,
        alias.offerAudio ? 'audio' : null,
        alias.offersVideo ? 'video' : null,
        alias.offerOfficeVisit ? 'office' : null
      ].filter(Boolean)
    };
  }

  if (useFallback) {
    // Maybe it's the primary provider
    const { data: primaryHcp } = await db
      .from('healthcare_providers')
      .select('*')
      .eq('id', aliasId)
      .single();

    if (!primaryHcp) {
      throw error(404, 'Doctor not found');
    }
    doctorInfo = {
      alias_id: primaryHcp.id,
      doctor_id: primaryHcp.id,
      display_name: provider?.name || primaryHcp.full_name || 'Doctor',
      clinic_alias: null,
      specialization: primaryHcp.specialization || provider?.category || 'Medical Specialist',
      sub_specialty: primaryHcp.sub_specialty,
      experience: primaryHcp.years_of_experience,
      rating: primaryHcp.average_rating || 0,
      reviews: primaryHcp.total_reviews || 0,
      photo_url: primaryHcp.profile_photo_url || provider?.logo_url,
      bio: primaryHcp.bio,
      is_verified: primaryHcp.is_verified,
      follow_up_duration: primaryHcp.follow_up_duration || provider?.follow_up_duration || 24,
      slot_duration_minutes: primaryHcp.slot_duration_minutes || provider?.slot_duration_minutes || 30,
      services_offered: [
        primaryHcp.offerChat ? 'chat' : null,
        primaryHcp.offerAudio ? 'audio' : null,
        primaryHcp.offersVideo ? 'video' : null,
        primaryHcp.offerOfficeVisit ? 'office' : null
      ].filter(Boolean).length > 0 ? [
        primaryHcp.offerChat ? 'chat' : null,
        primaryHcp.offerAudio ? 'audio' : null,
        primaryHcp.offersVideo ? 'video' : null,
        primaryHcp.offerOfficeVisit ? 'office' : null
      ].filter(Boolean) : provider?.services_offered?.map((s: string) => s === 'voice' ? 'audio' : (s === 'office_visit' ? 'office' : s)) || ['chat', 'audio', 'video'],
      fees: { 
        chat: primaryHcp.chatMarkUp || primaryHcp.chatFee || provider?.fees?.chat || 5000, 
        audio: primaryHcp.audioMarkUp || primaryHcp.audioFee || provider?.fees?.audio || 8000, 
        video: primaryHcp.videoMarkUp || primaryHcp.videoFee || provider?.fees?.video || 10000,
        office: primaryHcp.officeMarkUp || primaryHcp.officeFee || provider?.fees?.office_visit || 15000
      },
      address: primaryHcp.address || provider?.address,
      city: primaryHcp.city || provider?.city,
      brand_color: primaryHcp.brand_color || provider?.brand_color
    };
  }

  const finalDoctorId = doctorInfo?.doctor_id;

  // 2. Fetch Reviews
  let doctorReviews: any[] = [];
  if (finalDoctorId) {
    const { data: fetchReviews } = await db
      .from('healthcare_reviews')
      .select('id, rating, comment, created_at, patient:patient_id(full_name)')
      .eq('provider_id', finalDoctorId)
      .eq('is_verified', true)
      .order('created_at', { ascending: false })
      .limit(10);
    
    if (fetchReviews) {
      doctorReviews = fetchReviews.map((r: any) => ({
        id: r.id,
        rating: r.rating,
        comment: r.comment,
        created_at: r.created_at,
        reviewer_name: r.patient?.full_name || 'Anonymous'
      }));
    }
  }

  // 3. Fetch Schedule
  let schedule: any[] = [];
  let bookedSlots: any[] = [];
  
  if (finalDoctorId) {
    const { data: availData } = await db
      .from('provider_availability_templates')
      .select('*')
      .eq('provider_id', finalDoctorId)
      .eq('is_closed', false)
      .order('day_of_week', { ascending: true });
    
    if (availData) schedule = availData;

    const todayDate = new Date().toISOString().split('T')[0];
    const { data: bSlots } = await db
      .from('provider_time_slots')
      .select('date, start_time, end_time, status')
      .eq('provider_id', finalDoctorId)
      .gte('date', todayDate)
      .in('status', ['booked', 'in_progress', 'held_for_payment']);
      
    if (bSlots) bookedSlots = bSlots;
  }

  return {
    doctor: doctorInfo,
    doctorReviews,
    schedule,
    bookedSlots
  };
}
