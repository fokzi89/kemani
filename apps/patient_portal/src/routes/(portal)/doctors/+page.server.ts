import { createClient } from '@supabase/supabase-js';
import { PUBLIC_SUPABASE_URL, PUBLIC_SUPABASE_ANON_KEY } from '$env/static/public';

const db = createClient(PUBLIC_SUPABASE_URL, PUBLIC_SUPABASE_ANON_KEY);

export async function load({ parent }) {
  const { provider } = await parent();
  const primaryDoctorId = provider?.hcp_id;

  if (!primaryDoctorId) {
    return { doctors: [] };
  }

  // Fetch doctors associated with this clinic from the doctor_aliases table
  const { data: aliases, error } = await db
    .from('doctor_aliases')
    .select(`
      id,
      doctor_id,
      alias,
      clinic_name,
      doctor:healthcare_providers!doctor_id (
        id,
        full_name,
        specialization,
        sub_specialty,
        years_of_experience,
        average_rating,
        total_reviews,
        profile_photo_url,
        bio,
        is_verified,
        clinic_address,
        region
      )
    `)
    .eq('primary_doctor_id', primaryDoctorId)
    .eq('accepted', true);

  if (error) {
    console.error('[Doctors Load] Error fetching aliases:', error);
  }

  const doctors = (aliases || [])
    .map(a => {
      const hp = Array.isArray(a.doctor) ? a.doctor[0] : a.doctor;
      if (!hp) return null;
      return {
        alias_id: a.id,
        doctor_id: a.doctor_id,
        display_name: a.alias || hp?.full_name || 'Specialist',
        clinic_alias: a.alias,
        specialization: hp?.specialization || 'Medical Specialist',
        sub_specialty: hp?.sub_specialty,
        experience: hp?.years_of_experience,
        rating: hp?.average_rating,
        reviews: hp?.total_reviews,
        photo_url: hp?.profile_photo_url,
        bio: hp?.bio,
        is_verified: hp?.is_verified
      };
    })
    .filter(Boolean);

  return { doctors };
}
