import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
dotenv.config({ path: 'c:/Users/afokeoghene.akpomiem/kemani/apps/patient_portal/.env' });

const db = createClient(process.env.PUBLIC_SUPABASE_URL, process.env.PUBLIC_SUPABASE_ANON_KEY);

async function test() {
  const provider = { hcp_id: '92b40d2e-d057-4007-97ac-b4851e5158f6' };

  // 1b. Fetch partner doctors from doctor_aliases
  const { data: aliases } = await db
    .from('doctor_aliases')
    .select(`
      id, doctor_id, alias,
      doctor:healthcare_providers!doctor_id (
        id, full_name, specialization, profile_photo_url, years_of_experience
      )
    `)
    .eq('primary_doctor_id', provider.hcp_id)
    .eq('accepted', true)
    .is('is_active', true)
    .limit(4);
    
    console.log("aliases", aliases);
    
    let medics = [
    ...(aliases || []).map(a => {
      const hp = Array.isArray(a.doctor) ? a.doctor[0] : a.doctor;
      return {
        id: a.id, // Use alias ID for linking instead of doctor_id
        full_name: a.alias || hp?.full_name || 'Specialist',
        specialty: hp?.specialization || 'Medical Specialist',
        photo_url: hp?.profile_photo_url,
        type: 'partner'
      };
    })
  ].filter(Boolean);
  console.log("medics", medics);
}
test();
