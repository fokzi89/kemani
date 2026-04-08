import { supabase } from '$lib/supabase';

export async function load({ parent }) {
  const { provider, session } = await parent();

  if (!session) {
    return { labRequests: [] };
  }

  // Fetch lab requests for this patient and tenant
  // Trying 'lab_requests' table as a standard naming convention
  const { data: labRequests, error } = await supabase
    .from('lab_requests')
    .select(`
      *,
      healthcare_providers (full_name, profile_photo_url)
    `)
    .eq('patient_id', session.user.id)
    .eq('tenant_id', provider.id)
    .order('created_at', { ascending: false });

  if (error) {
    if (error.code === 'PGRST116' || error.message.includes('not found')) {
      console.warn('lab_requests table may not exist yet.');
    } else {
      console.error('Error fetching lab requests:', error);
    }
    return { labRequests: [] };
  }

  return {
    labRequests
  };
}
