import { error } from '@sveltejs/kit';

export async function load({ locals }) {
	const tenantId = locals.referringTenantId;

	if (!tenantId) {
		throw error(404, 'Checkout session context invalid');
	}

	return {
		tenantId
	};
}
