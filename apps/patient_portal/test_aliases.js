import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
dotenv.config({ path: 'c:/Users/afokeoghene.akpomiem/kemani/apps/patient_portal/.env' });

const supabaseUrl = process.env.PUBLIC_SUPABASE_URL;
const supabaseKey = process.env.PUBLIC_SUPABASE_ANON_KEY;

if(!supabaseUrl || !supabaseKey) {
  console.log("No env");
  process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseKey);

async function test() {
  const { data, error } = await supabase
    .from('doctor_aliases')
    .select(`
      id,
      doctor_id,
      alias,
      clinic_name,
      accepted,
      is_active,
      primary_doctor_id,
      doctor:healthcare_providers!doctor_id (
        id,
        full_name
      )
    `)
    .limit(5);
    
  console.log("Error:", error);
  console.log("Data:", JSON.stringify(data, null, 2));
}

test();
