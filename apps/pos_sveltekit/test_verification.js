import { createClient } from '@supabase/supabase-js';

const supabaseUrl = 'https://ykbpznoqebhopyqpoqaf.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlrYnB6bm9xZWJob3B5cXBvcWFmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg3NjExNDcsImV4cCI6MjA4NDMzNzE0N30.eN1BiyRWOgblp-LFaQvMXM13SttjHnmJb8-s5Y3eu38';
const supabase = createClient(supabaseUrl, supabaseKey);

async function test() {
    console.log('Logging in...');
    const { data: auth, error: authErr } = await supabase.auth.signInWithPassword({
        email: 'aakpomiemie@gmail.com',
        password: '123456'
    });

    if (authErr) { console.error('Auth error:', authErr); return; }
    console.log('Login successful. Session set.');

    // 1. Fetch user data (mocking the onMount logic)
    console.log('Fetching user core data...');
    const { data: userData, error: userErr } = await supabase.from('users')
        .select('tenant_id, branch_id, full_name')
        .eq('id', auth.user.id)
        .single();
    
    if (userErr) { console.error('Error fetching users table:', userErr); return; }
    console.log('User data loaded:', userData);

    const tenantId = userData.tenant_id;
    const userBranchId = userData.branch_id;

    // 2. Fetch products (testing the NEQ and OR fix)
    console.log(`Fetching products for tenant: ${tenantId}...`);
    const { data: products, error: pErr, status: pStatus } = await supabase.from('products')
        .select('*')
        .eq('tenant_id', tenantId)
        .or('product_type.is.null,product_type.neq.Laboratory test')
        .order('created_at', { ascending: false });

    if (pErr) { console.error('Error fetching products:', pErr); }
    else {
        console.log(`Successfully fetched ${products?.length || 0} products.`);
        if (products && products.length > 0) {
            console.log('First product sample:', { id: products[0].id, name: products[0].name, type: products[0].product_type });
        } else {
            console.warn('Warning: Product list is empty. Is this expected?');
        }
    }

    // 3. Test metadata lookup
    console.log('Fetching tenant metadata...');
    const { data: tnt } = await supabase.from('tenants').select('name').eq('id', tenantId).single();
    console.log('Business name:', tnt?.name || 'N/A');

    if (userBranchId) {
        console.log('Fetching branch metadata...');
        const { data: brch } = await supabase.from('branches').select('name').eq('id', userBranchId).single();
        console.log('Branch name:', brch?.name || 'N/A');
    }
}

test();
