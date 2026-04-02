import { supabase } from '$lib/supabase';
import { error } from '@sveltejs/kit';

export async function load({ locals, params }) {
	const tenantId = locals.referringTenantId;
	if (!tenantId) {
		throw error(404, 'Storefront not found');
	}

	const { data: providers, error: fetchError } = await supabase
		.from('healthcare_providers')
		.select('*')
		.eq('tenant_id', tenantId)
		.eq('status', 'active');

	if (fetchError) {
		console.error('Error fetching medics:', fetchError);
		return { providers: [] };
	}

	return {
		providers: providers || []
	};
}
