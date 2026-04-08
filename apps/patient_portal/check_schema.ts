import { supabase } from './src/lib/supabase.ts';

async function checkPrescriptionSchema() {
  const { data, error } = await supabase.from('prescriptions').select('*').limit(1);
  if (error) {
    console.error('Error:', error);
  } else {
    console.log('Columns:', Object.keys(data[0] || {}));
  }
}

checkPrescriptionSchema();
