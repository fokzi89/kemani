import { supabase } from '$lib/supabase';
import { error } from '@sveltejs/kit';
import type { PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ params }) => {
	const { id } = params;

	try {
		// Get consultation details
		const { data: consultation, error: consultError } = await supabase
			.from('consultations')
			.select('*')
			.eq('id', id)
			.single();

		if (consultError || !consultation) {
			throw error(404, 'Consultation not found');
		}

		return {
			consultation
		};
	} catch (err) {
		console.error('Load error:', err);
		throw error(500, 'Failed to load consultation');
	}
};
