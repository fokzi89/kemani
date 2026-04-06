import { createClient } from '@supabase/supabase-js';
import { PUBLIC_SUPABASE_URL, PUBLIC_SUPABASE_ANON_KEY } from '$env/static/public';

const db = createClient(PUBLIC_SUPABASE_URL, PUBLIC_SUPABASE_ANON_KEY);

export async function load({ parent }) {
  const { provider } = await parent();

  // 1. Fetch medics (doctors) for this provider (Tenant)
  const { data: medics } = await db
    .from('medics')
    .select('id, full_name, specialty, photo_url, bio, years_experience')
    .eq('tenant_id', provider.id)
    .eq('is_active', true)
    .limit(6);

  // 2. Fetch reviews for the Healthcare Provider (Professional Profiling)
  let reviews = [];
  if (provider.hcp_id) {
    const { data: fetchReviews, error } = await db
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

  return { 
    medics: medics || [],
    reviews: reviews.map((r: any) => ({
      id: r.id,
      rating: r.rating,
      comment: r.comment,
      created_at: r.created_at,
      reviewer_name: r.patient?.full_name || 'Anonymous Patient'
    }))
  };
}
