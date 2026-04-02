import { error } from '@sveltejs/kit';
import { supabase } from '$lib/supabase';

export async function load({ params, locals }) {
	const medicId = params.medicId;
	const tenantId = locals.referringTenantId;

	if (!tenantId) {
		throw error(404, 'Storefront context not found');
	}

	// Fetch tenant details for branding
	const { data: tenant, error: tenantError } = await supabase
		.from('tenants')
		.select('id, name, brand_color')
		.eq('id', tenantId)
		.single();

	if (tenantError || !tenant) {
		throw error(404, 'Storefront context not found');
	}

	// Fetch specific medic
	const { data: medic, error: medicError } = await supabase
		.from('healthcare_providers')
		.select('*')
		.eq('id', medicId)
		.single();

	if (medicError || !medic) {
		throw error(404, 'Medic not found');
	}

	// Additional metadata format
	return {
		tenant: {
			name: tenant.name,
			brand_color: tenant.brand_color || '#4f46e5'
		},
		medic
	};
}
