
const { createClient } = require('@supabase/supabase-js');
const dotenv = require('dotenv');
const path = require('path');
dotenv.config({ path: path.resolve(__dirname, '../../../.env') });

const supabase = createClient(process.env.PUBLIC_SUPABASE_URL, process.env.PUBLIC_SUPABASE_ANON_KEY);

async function test() {
    // Get full HCP record to see how it links to a tenant
    console.log('\n=== HCP: kome-afoke-chariros (full record) ===');
    const { data: hcp, error } = await supabase
        .from('healthcare_providers')
        .select('*')
        .eq('slug', 'kome-afoke-chariros')
        .single();
    
    if (error) { console.error('Error:', error.message); return; }
    console.log(JSON.stringify(hcp, null, 2));

    // Also check bolo-bola-f4xkkt for comparison
    console.log('\n=== HCP: bolo-bola-f4xkkt (full record) ===');
    const { data: hcp2 } = await supabase
        .from('healthcare_providers')
        .select('id, full_name, slug, tenant_id, clinic_address')
        .eq('slug', 'bolo-bola-f4xkkt')
        .single();
    console.log(JSON.stringify(hcp2, null, 2));
}

test().then(() => process.exit(0));
