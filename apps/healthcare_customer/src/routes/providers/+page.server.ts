import { supabase } from '$lib/supabase';
import { error } from '@sveltejs/kit';
import type { PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ url }) => {
	const specialization = url.searchParams.get('specialization') || '';
	const search = url.searchParams.get('search') || '';
	const type = url.searchParams.get('type') || '';
	const country = url.searchParams.get('country') || 'NG'; // Default to Nigeria

	try {
		let query = supabase
			.from('healthcare_providers')
			.select('*')
			.eq('is_active', true)
			.eq('is_verified', true)
			.eq('country', country)
			.order('average_rating', { ascending: false });

		// Apply filters
		if (specialization) {
			query = query.eq('specialization', specialization);
		}

		if (type) {
			query = query.eq('type', type);
		}

		if (search) {
			query = query.or(`full_name.ilike.%${search}%,specialization.ilike.%${search}%,bio.ilike.%${search}%`);
		}

		const { data: providers, error: providerError } = await query;

		if (providerError) {
			console.error('Error fetching providers:', providerError);
			throw error(500, 'Failed to load providers');
		}

		// Get unique specializations for filter
		const { data: specializations } = await supabase
			.from('healthcare_providers')
			.select('specialization')
			.eq('country', country)
			.eq('is_active', true)
			.eq('is_verified', true);

		const uniqueSpecializations = [...new Set(specializations?.map(s => s.specialization) || [])];

		return {
			providers: providers || [],
			specializations: uniqueSpecializations,
			filters: {
				specialization,
				search,
				type,
				country
			}
		};
	} catch (err) {
		console.error('Load error:', err);
		throw error(500, 'Failed to load providers');
	}
};
