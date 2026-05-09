import { supabase } from '$lib/supabase';
import { error } from '@sveltejs/kit';

export async function load({ locals }) {
	const tenantId = locals.referringTenantId;
	if (!tenantId) {
		throw error(404, 'Storefront not found');
	}

	// Fetch tenant details for branding and mode
	const { data: tenant, error: tenantError } = await supabase
		.from('tenants')
		.select('id, name, brand_color, ecommerce_settings, allowDoctorPartnerShip, pharmacist_mode')
		.eq('id', tenantId)
		.single();

	if (tenantError || !tenant) {
		throw error(404, 'Storefront context not found');
	}

	// 1. Fetch active and accepted doctor partners (Non-Pharmacists)
	const { data: partners, error: partnersError } = await supabase
		.from('doctor_aliases_with_details')
		.select('*')
		.eq('tenant_partner', tenantId)
		.neq('specialization', 'Pharmacist') // We handle pharmacists separately below
		.eq('accepted', true)
		.eq('is_active', true);

	// 2. Fetch Pharmacists based on mode
	let pharmacistQuery = supabase
		.from('available_pharmacists')
		.select('*')
		.eq('tenant_id', tenantId)
		.eq('is_active', true);
	
	if (tenant.pharmacist_mode === 'Inhouse') {
		pharmacistQuery = pharmacistQuery.eq('provider_type', 'Inhouse');
	} else if (tenant.pharmacist_mode === 'Freelance') {
		pharmacistQuery = pharmacistQuery.eq('provider_type', 'Freelance');
	}
	// If 'Both', no additional filter needed

	const { data: pharmacists, error: pharmError } = await pharmacistQuery;

	const allProviders = [
		...(partners || []).map(p => ({
			...p,
			display_name: p.alias || p.doctor_name,
			photo_url: p.profile_photo_url,
			provider_type: 'Freelance'
		})),
		...(pharmacists || []).map(p => ({
			...p,
			doctor_name: p.display_name,
			profile_photo_url: p.photo_url,
			is_verified: true // Staff are verified, freelancers verified via alias join
		}))
	];

	return {
		tenant: {
			name: tenant.name,
			brand_color: tenant.brand_color || '#4f46e5',
			allowDoctorPartnerShip: tenant.allowDoctorPartnerShip ?? true,
			description: (tenant.ecommerce_settings as any)?.description || '',
			pharmacist_mode: tenant.pharmacist_mode
		},
		providers: allProviders
	};
}
