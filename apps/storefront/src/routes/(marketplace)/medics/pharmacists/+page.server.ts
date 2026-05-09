import { supabase } from '$lib/supabase';
import { error } from '@sveltejs/kit';

export async function load({ parent, url }) {
	const { storefront } = await parent();
	if (!storefront) throw error(404, 'Storefront not found');

	const tenantId = storefront.id;
    const productId = url.searchParams.get('productId');

	// 1. Fetch unified list of pharmacists for this tenant
	const { data: pharmacists, error: pError } = await supabase
		.from('available_pharmacists')
		.select('*')
		.eq('tenant_id', tenantId)
		.eq('is_active', true);

	if (pError) {
		console.error('[Pharmacists Page] Fetch Error:', pError);
		return { pharmacists: [], productId };
	}

	// 2. Fetch active consultation counts for these pharmacists to determine "Busy" status
    // We look for active conversations assigned to these user_ids
    const userIds = (pharmacists || []).map(p => p.user_id);
    const { data: activeChats } = await supabase
        .from('chat_conversations')
        .select('service_provider')
        .in('service_provider', userIds)
        .eq('status', 'active');

    // Map busy status
    const busyUserIds = new Set((activeChats || []).map(c => c.service_provider));

    const enrichedPharmacists = (pharmacists || []).map(p => ({
        ...p,
        isBusy: busyUserIds.has(p.user_id)
    }));

	return {
		pharmacists: enrichedPharmacists,
        productId
	};
}
