import type { PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ locals }) => {
	return {
		referringTenantId: locals.referringTenantId || null,
		user: locals.session?.user || null
	};
};
