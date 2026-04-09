
const { createClient } = require('@supabase/supabase-js');
const dotenv = require('dotenv');
const path = require('path');
dotenv.config({ path: path.resolve(__dirname, '../../../.env') });

const url = process.env.PUBLIC_SUPABASE_URL;
const key = process.env.PUBLIC_SUPABASE_ANON_KEY;

const supabase = createClient(url, key);

async function test() {
    const slug = 'kome-afoke-chariros';
    console.log(`Testing slug: ${slug}`);

    const { data: tenantBySlug, error: err1 } = await supabase
        .from('tenants')
        .select('id')
        .eq('slug', slug)
        .single();
    
    if (err1) {
        console.error('Error lookup by slug:', err1.message);
        return;
    }
    console.log('Found Tenant ID:', tenantBySlug.id);

    const { data: tenant, error: err2 } = await supabase
        .from('tenants')
        .select(`
            id, name, slug, subdomain, logo_url, brand_color,
            phone, email,
            services_offered, ecommerce_settings,
            branches!tenant_id(id, name, address, phone, city)
        `)
        .eq('id', tenantBySlug.id)
        .is('deleted_at', null)
        .maybeSingle();
    
    if (err2) {
        console.error('Error fetching details:', err2.message);
    } else {
        console.log('Tenant Details Found:', !!tenant);
        console.log('Tenant Name:', tenant?.name);
        console.log('Branch Count:', tenant?.branches?.length);
    }
}

test();
