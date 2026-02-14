import type { RequestHandler } from './$types';
import { json } from '@sveltejs/kit';
import { createClient } from '$lib/services/supabase';

// GET - Get store by slug
export const GET: RequestHandler = async ({ params }) => {
    try {
        const { slug } = params;

        if (!slug) {
            return json({ error: 'Store slug required' }, { status: 400 });
        }

        const supabase = createClient();

        // Get tenant and branch by slug
        const { data: tenant, error: tenantError } = await supabase
            .from('tenants')
            .select(`
                *,
                branches (
                    id,
                    name,
                    business_type,
                    address,
                    phone
                )
            `)
            .eq('slug', slug)
            .single();

        if (tenantError || !tenant) {
            console.error('Tenant fetch error:', tenantError);
            return json({ error: 'Store not found' }, { status: 404 });
        }

        // Get tenant branding
        const { data: branding } = await supabase
            .from('tenant_branding')
            .select('*')
            .eq('tenant_id', tenant.id)
            .maybeSingle();

        return json({
            tenant,
            branding,
            branches: tenant.branches
        });
    } catch (error: any) {
        console.error('Marketplace API Error:', error);
        return json({ error: error.message || 'Internal Server Error' }, { status: 500 });
    }
};
