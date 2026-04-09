
import { createClient } from '@supabase/supabase-js';

const SUPABASE_URL = 'https://ykbpznoqebhopyqpoqaf.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlrYnB6bm9xZWJob3B5cXBvcWFmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg3NjExNDcsImV4cCI6MjA4NDMzNzE0N30.eN1BiyRWOgblp-LFaQvMXM13SttjHnmJb8-s5Y3eu38';

const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

async function checkValues() {
  const branchId = '65c7eede-ed37-4f8a-84a3-ed3c7b32969b';
  const { data, error } = await supabase
    .from('branch_inventory')
    .select('id, product_name, selling_price, sale_price, stock_quantity')
    .eq('branch_id', branchId)
    .limit(3);
  
  if (error) {
    console.error('Error:', error);
  } else {
    console.log('Sample Data for Branch 65c...:');
    console.log(JSON.stringify(data, null, 2));
  }
}

checkValues();
