
export async function load({ locals, parent }) {
  const { provider, session } = await parent();
  
  const activeSession = session || locals.session;

  if (!activeSession) {
    return { consultations: [] };
  }

  // Fetch consultations for this specific patient
  let query = locals.supabase
    .from('consultations')
    .select('*')
    .eq('patient_id', activeSession.user.id);

  if (provider?.id) {
    query = query.eq('tenant_id', provider.id);
  }

  const { data: consultations, error: fetchError } = await query
    .order('scheduled_time', { ascending: false });

  if (fetchError) {
    console.error('Error fetching patient consultations:', fetchError);
    return { consultations: [] };
  }

  return {
    consultations: consultations || [],
    provider
  };
}
