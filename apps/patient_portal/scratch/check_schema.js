
import { createClient } from '@supabase/supabase-js';

const SUPABASE_URL = 'https://ykbpznoqebhopyqpoqaf.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlrYnB6bm9xZWJob3B5cXBvcWFmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg3NjExNDcsImV4cCI6MjA4NDMzNzE0N30.eN1BiyRWOgblp-LFaQvMXM13SttjHnmJb8-s5Y3eu38';

const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

async function checkSchema() {
  const { data, error } = await supabase.from('products').select('*').limit(1);
  if (error) {
    console.error('Error:', error);
  } else if (data && data.length > 0) {
    console.log('Columns in products table:', Object.keys(data[0]).sort().join(', '));
  } else {
    console.log('No data in products table');
    // Try to get columns from a different table just in case
    const { data: cols } = await supabase.rpc('get_table_columns', { table_name: 'products' });
    console.log('Columns via RPC:', cols);
  }
}

checkSchema();
