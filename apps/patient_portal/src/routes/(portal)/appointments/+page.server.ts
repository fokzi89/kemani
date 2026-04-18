
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
    let orFilter = `tenant_id.eq.${provider.id}`;
    if (provider.hcp_id && provider.hcp_id !== provider.id) {
      orFilter += `,provider_id.eq.${provider.hcp_id}`;
    } else if (provider.hcp_id === provider.id) {
      // In Mode B, provider.id IS the hcp_id, and tenant_id might be empty/null for direct HCPs
      orFilter += `,provider_id.eq.${provider.id}`;
    }
    query = query.or(orFilter);
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
