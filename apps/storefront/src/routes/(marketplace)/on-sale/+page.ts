import { error } from '@sveltejs/kit';

export const load = async ({ fetch, parent }) => {
	const { storefront } = await parent();
	
	try {
		const res = await fetch(`/api/marketplace/products?is_on_sale=true&limit=48`);
		if (!res.ok) throw error(res.status, 'Failed to load sale products');
		
		const data = await res.json();
		
		return {
			products: data.products,
			pagination: data.pagination,
			title: 'On Sale Now',
			description: 'Premium healthcare at unbeatable prices. Limited time offers.'
		};
	} catch (err: any) {
		console.error('Sale load error:', err);
		return {
			products: [],
			pagination: { total: 0, pages: 0, page: 1, limit: 48 },
			title: 'On Sale Now',
			error: 'Could not load sale products at this time.'
		};
	}
};
