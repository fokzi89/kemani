import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
dotenv.config();

const supabaseUrl = process.env.PUBLIC_SUPABASE_URL || 'https://ykbpznoqebhopyqpoqaf.supabase.co';
const supabaseKey = process.env.PUBLIC_SUPABASE_ANON_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlrYnB6bm9xZWJob3B5cXBvcWFmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg3NjExNDcsImV4cCI6MjA4NDMzNzE0N30.eN1BiyRWOgblp-LFaQvMXM13SttjHnmJb8-s5Y3eu38';

const supabase = createClient(supabaseUrl, supabaseKey);

async function ensureTenant() {
  const { data: tenants, error: fetchError } = await supabase
    .from('tenants')
    .select('id, name, slug');

  if (fetchError) {
    console.error('Error fetching tenants:', fetchError);
    return;
  }

  if (tenants.length > 0) {
    console.log('Existing tenants:', tenants);
    return;
  }

  console.log('No tenants found. Creating test tenant...');
  const { data: newTenant, error: insertError } = await supabase
    .from('tenants')
    .insert({
      name: 'Ade Ventures',
      slug: 'ade-ventures',
      subdomain: 'ade-ventures',
      ecommerce_enabled: true
    })
    .select()
    .single();

  if (insertError) {
    console.error('Error creating tenant:', insertError);
  } else {
    console.log('Created test tenant:', newTenant);
    
    // Also create a branch
    const { error: branchError } = await supabase
      .from('branches')
      .insert({
        tenant_id: newTenant.id,
        name: 'Main Branch',
        address: '123 Test Street',
        delivery_enabled: true
      });
      
    if (branchError) console.error('Error creating branch:', branchError);
  }
}

ensureTenant();
