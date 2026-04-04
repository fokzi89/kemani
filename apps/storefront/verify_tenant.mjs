import { createClient } from '@supabase/supabase-js';

const supabaseUrl = 'https://ykbpznoqebhopyqpoqaf.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlrYnB6bm9xZWJob3B5cXBvcWFmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg3NjExNDcsImV4cCI6MjA4NDMzNzE0N30.eN1BiyRWOgblp-LFaQvMXM13SttjHnmJb8-s5Y3eu38';

const supabase = createClient(supabaseUrl, supabaseKey);

async function verify() {
  const subdomain = 'iya-bo-shop-su7fw';
  console.log(`Checking for tenant: ${subdomain}`);

  const { data: bySubdomain, error: subError } = await supabase
    .from('tenants')
    .select('id, name, slug, subdomain')
    .eq('subdomain', subdomain)
    .single();

  if (bySubdomain) {
    console.log('Found by subdomain:', bySubdomain);
    return;
  }

  const { data: bySlug, error: slugError } = await supabase
    .from('tenants')
    .select('id, name, slug, subdomain')
    .eq('slug', subdomain)
    .single();

  if (bySlug) {
    console.log('Found by slug:', bySlug);
  } else {
    console.log('Tenant not found by slug or subdomain.');
  }
}

verify();
