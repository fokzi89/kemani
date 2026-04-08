import { supabase } from './src/lib/supabase.js';

async function checkTables() {
  const { data: pData, error: pError } = await supabase.from('prescriptions').select('*').limit(1);
  console.log('prescriptions:', pError ? 'Not found or Error' : 'Exists');
  
  const { data: lData, error: lError } = await supabase.from('lab_test_requests').select('*').limit(1);
  console.log('lab_test_requests:', lError ? 'Not found or Error' : 'Exists');

  const { data: qData, error: qError } = await supabase.from('lab_requests').select('*').limit(1);
  console.log('lab_requests:', qError ? 'Not found or Error' : 'Exists');
}

checkTables();
