import { supabase } from '$lib/supabase';

export async function load({ parent }) {
  try {
    const { provider, session } = await parent();

    if (!session) {
      return { prescriptions: [] };
    }

    // Fetch prescriptions for this patient
    const { data: prescriptions, error: fetchError } = await supabase
      .from('prescriptions')
      .select('*')
      .eq('patient_id', session.user.id);

    if (fetchError) {
      console.error('Database Error:', fetchError);
      return { prescriptions: [] };
    }

    return {
      prescriptions: prescriptions || []
    };
  } catch (err) {
    console.error('Server Loader Error:', err);
    return { prescriptions: [] };
  }
}
