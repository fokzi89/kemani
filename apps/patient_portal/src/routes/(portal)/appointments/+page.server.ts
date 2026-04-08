import { error } from '@sveltejs/kit';
import { supabase } from '$lib/supabase';

export async function load({ parent }) {
  const { provider, session } = await parent();

  if (!session) {
    return { consultations: [] };
  }

  // Fetch consultations for this specific patient and this specific clinic (tenant)
  const { data: consultations, error: fetchError } = await supabase
    .from('consultations')
    .select('*')
    .eq('patient_id', session.user.id)
    .eq('tenant_id', provider.id)
    .order('scheduled_time', { ascending: false });

  if (fetchError) {
    console.error('Error fetching patient consultations:', fetchError);
    return { consultations: [] };
  }

  return {
    consultations,
    provider
  };
}
