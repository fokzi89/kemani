import { error } from '@sveltejs/kit';

export const load = async ({ fetch, parent }) => {
	const { storefront } = await parent();
	
	try {
		const res = await fetch(`/api/marketplace/products?is_featured=true&limit=48`);
		if (!res.ok) throw error(res.status, 'Failed to load featured products');
		
		const data = await res.json();
		
		return {
			products: data.products,
			pagination: data.pagination,
			title: 'Featured Products',
			description: 'Handpicked premium health products just for you.'
		};
	} catch (err: any) {
		console.error('Featured load error:', err);
		return {
			products: [],
			pagination: { total: 0, pages: 0, page: 1, limit: 48 },
			title: 'Featured Products',
			error: 'Could not load featured products at this time.'
		};
	}
};
