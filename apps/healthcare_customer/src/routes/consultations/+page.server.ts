import { supabase } from '$lib/supabase';
import { error } from '@sveltejs/kit';
import type { PageServerLoad } from './$types';

export const load: PageServerLoad = async () => {
	try {
		// Get user's consultations (you'll need to pass user ID from auth)
		// For now, get all consultations
		const { data: consultations, error: consultError } = await supabase
			.from('consultations')
			.select('*')
			.order('created_at', { ascending: false });

		if (consultError) {
			console.error('Error fetching consultations:', consultError);
			return {
				consultations: []
			};
		}

		return {
			consultations: consultations || []
		};
	} catch (err) {
		console.error('Load error:', err);
		return {
			consultations: []
		};
	}
};
