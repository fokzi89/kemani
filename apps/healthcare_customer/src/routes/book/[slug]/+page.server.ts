import { supabase } from '$lib/supabase';
import { error } from '@sveltejs/kit';
import type { PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ params }) => {
	const { slug } = params;

	try {
		// Get provider details
		const { data: provider, error: providerError } = await supabase
			.from('healthcare_providers')
			.select('*')
			.eq('slug', slug)
			.eq('is_active', true)
			.eq('is_verified', true)
			.single();

		if (providerError || !provider) {
			throw error(404, 'Provider not found');
		}

		// Get available time slots for next 14 days
		const today = new Date().toISOString().split('T')[0];
		const twoWeeksLater = new Date(Date.now() + 14 * 24 * 60 * 60 * 1000).toISOString().split('T')[0];

		const { data: slots, error: slotsError } = await supabase
			.from('provider_time_slots')
			.select('*')
			.eq('provider_id', provider.id)
			.eq('status', 'available')
			.gte('date', today)
			.lte('date', twoWeeksLater)
			.order('date', { ascending: true })
			.order('start_time', { ascending: true });

		if (slotsError) {
			console.error('Error fetching slots:', slotsError);
		}

		return {
			provider,
			slots: slots || []
		};
	} catch (err) {
		console.error('Load error:', err);
		throw error(500, 'Failed to load booking information');
	}
};
