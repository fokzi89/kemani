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

  let doctors = (aliases || [])
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

  // If no partner doctors found, fall back to showing the primary doctor themselves
  if (doctors.length === 0) {
    const { data: primaryHcp } = await db
      .from('healthcare_providers')
      .select('id, full_name, specialization, sub_specialty, years_of_experience, average_rating, total_reviews, profile_photo_url, bio, is_verified')
      .eq('id', primaryDoctorId)
      .single();

    if (primaryHcp) {
      doctors = [{
        alias_id: primaryHcp.id,
        doctor_id: primaryHcp.id,
        display_name: provider?.name || primaryHcp.full_name || 'Doctor',
        clinic_alias: null,
        specialization: primaryHcp.specialization || provider?.category || 'Medical Specialist',
        sub_specialty: primaryHcp.sub_specialty,
        experience: primaryHcp.years_of_experience,
        rating: primaryHcp.average_rating,
        reviews: primaryHcp.total_reviews,
        photo_url: primaryHcp.profile_photo_url || provider?.logo_url,
        bio: primaryHcp.bio,
        is_verified: primaryHcp.is_verified
      }];
    }
  }

  return { doctors };
}
