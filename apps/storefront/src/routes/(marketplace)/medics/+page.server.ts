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
		.select('id, name, brand_color, ecommerce_settings, allowDoctorPartnerShip')
		.eq('id', tenantId)
		.single();

	if (tenantError || !tenant) {
		throw error(404, 'Storefront context not found');
	}

	// Fetch active and accepted doctor partners from the alias table
	const { data: providers, error: fetchError } = await supabase
		.from('doctor_aliases_with_details')
		.select('*')
		.eq('tenant_partner', tenantId)
		.eq('accepted', true)
		.eq('is_active', true);

	if (fetchError) {
		console.error('Error fetching medics:', fetchError);
		return { 
			tenant: {
				name: tenant.name,
				brand_color: tenant.brand_color || '#4f46e5',
				allowDoctorPartnerShip: tenant.allowDoctorPartnerShip ?? true
			},
			providers: [] 
		};
	}

	return {
		tenant: {
			name: tenant.name,
			brand_color: tenant.brand_color || '#4f46e5',
			allowDoctorPartnerShip: tenant.allowDoctorPartnerShip ?? true,
			description: (tenant.ecommerce_settings as any)?.description || ''
		},
		providers: providers || []
	};
}
