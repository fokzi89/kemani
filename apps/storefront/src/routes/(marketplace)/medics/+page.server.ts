import { supabase } from '$lib/supabase';
import { error } from '@sveltejs/kit';

export async function load({ locals }) {
	const tenantId = locals.referringTenantId;
	if (!tenantId) {
		throw error(404, 'Storefront not found');
	}

	// Fetch tenant details for branding
	const { data: tenant, error: tenantError } = await supabase
		.from('tenants')
		.select('id, name, brand_color, ecommerce_settings')
		.eq('id', tenantId)
		.single();

	if (tenantError || !tenant) {
		throw error(404, 'Storefront context not found');
	}

	// Fetch active and verified healthcare providers (relaxed filter for initial setup)
	const { data: providers, error: fetchError } = await supabase
		.from('healthcare_providers')
		.select('*')
		.not('is_active', 'is', false);

	if (fetchError) {
		console.error('Error fetching medics:', fetchError);
		return { 
			tenant: {
				name: tenant.name,
				brand_color: tenant.brand_color || '#4f46e5'
			},
			providers: [] 
		};
	}

	return {
		tenant: {
			name: tenant.name,
			brand_color: tenant.brand_color || '#4f46e5',
			description: (tenant.ecommerce_settings as any)?.description || ''
		},
		providers: providers || []
	};
}
