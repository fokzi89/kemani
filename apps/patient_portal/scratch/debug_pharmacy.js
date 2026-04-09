
import { createClient } from '@supabase/supabase-js';

const SUPABASE_URL = 'https://ykbpznoqebhopyqpoqaf.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlrYnB6bm9xZWJob3B5cXBvcWFmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg3NjExNDcsImV4cCI6MjA4NDMzNzE0N30.eN1BiyRWOgblp-LFaQvMXM13SttjHnmJb8-s5Y3eu38';

const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

async function debug() {
  const { data: all } = await supabase.from('branches').select('id, name, deleted_at, business_type').ilike('name', '%Main branch%');
  console.log('All Main Branch variants:', all);
}

debug();
