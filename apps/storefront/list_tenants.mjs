import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
dotenv.config();

const supabaseUrl = process.env.PUBLIC_SUPABASE_URL || 'https://ykbpznoqebhopyqpoqaf.supabase.co';
const supabaseKey = process.env.PUBLIC_SUPABASE_ANON_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlrYnB6bm9xZWJob3B5cXBvcWFmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg3NjExNDcsImV4cCI6MjA4NDMzNzE0N30.eN1BiyRWOgblp-LFaQvMXM13SttjHnmJb8-s5Y3eu38';

const supabase = createClient(supabaseUrl, supabaseKey);

async function listTenants() {
  const { data, error } = await supabase
    .from('tenants')
    .select('id, name, slug, subdomain, AI_is_enabled');

  if (error) {
    console.error('Error fetching tenants:', error);
    return;
  }

  console.log('--- Tenants List ---');
  console.table(data);
}

listTenants();
