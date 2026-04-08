import { createClient } from '@supabase/supabase-js';
import { PUBLIC_SUPABASE_URL, PUBLIC_SUPABASE_ANON_KEY } from '$env/static/public';

const db = createClient(PUBLIC_SUPABASE_URL, PUBLIC_SUPABASE_ANON_KEY);

export async function load({ parent }) {
  const { provider } = await parent();
  const primaryDoctorId = provider?.hcp_id;

  if (!primaryDoctorId) {
    return { doctors: [] };
  }

  // Fetch doctors associated with this clinic from the doctor_aliases_with_details view
  const { data: aliases, error } = await db
    .from('doctor_aliases_with_details')
    .select('*')
    .eq('clinic_id', primaryDoctorId)
    .eq('accepted', true)
    .is('is_active', true);

  if (error) {
    console.error('[Doctors Load] Error fetching aliases:', error);
  }

  let doctors = (aliases || [])
    .filter(a => a.doctor_id !== primaryDoctorId)
    .map(a => {
      return {
        alias_id: a.alias_id,
        doctor_id: a.doctor_id,
        display_name: a.display_name || a.actual_name || 'Specialist',
        clinic_alias: a.clinic_name || null,
        specialization: a.specialization || 'Medical Specialist',
        sub_specialty: a.sub_specialty,
        experience: a.years_of_experience,
        rating: a.average_rating,
        reviews: a.total_reviews || 0,
        photo_url: a.profile_photo_url,
        bio: a.bio || null,
        is_verified: a.is_verified,
      };
    })
    .filter(Boolean);

  // Always include the primary doctor themselves, pulled from healthcare_providers
  const { data: primaryHcp } = await db
    .from('healthcare_providers')
    .select('id, full_name, specialization, sub_specialty, years_of_experience, average_rating, total_reviews, profile_photo_url, bio, is_verified')
    .eq('id', primaryDoctorId)
    .single();

  if (primaryHcp) {
    doctors.unshift({
      alias_id: primaryHcp.id, // Use hcp id so detail page triggers fallback logic correctly
      doctor_id: primaryHcp.id,
      display_name: primaryHcp.full_name || provider?.name || 'Doctor',
      clinic_alias: null,
      specialization: primaryHcp.specialization || provider?.category || 'Medical Specialist',
      sub_specialty: primaryHcp.sub_specialty,
      experience: primaryHcp.years_of_experience,
      rating: primaryHcp.average_rating,
      reviews: primaryHcp.total_reviews,
      photo_url: primaryHcp.profile_photo_url || provider?.logo_url,
      bio: primaryHcp.bio,
      is_verified: primaryHcp.is_verified
    });
  }

  return { doctors };
}
