import { MarketplaceService } from '$lib/services/marketplace';
import { supabase } from '$lib/supabase';

export async function load({ parent, url }) {
	const { storefront } = await parent();
	const tenantId = storefront.id;

	const service = new MarketplaceService(supabase);

	const category = url.searchParams.get('category') || undefined;
	const search = url.searchParams.get('search') || undefined;
	const minPrice = url.searchParams.get('min_price') ? Number(url.searchParams.get('min_price')) : undefined;
	const maxPrice = url.searchParams.get('max_price') ? Number(url.searchParams.get('max_price')) : undefined;
	const sortBy = url.searchParams.get('sort') as any || 'newest';
	const inStockOnly = url.searchParams.get('in_stock') === 'true';

	const [productsResult, categoriesResult] = await Promise.all([
		service.getMarketplaceProducts(tenantId, {
			category,
			search,
			min_price: minPrice,
			max_price: maxPrice,
			sort_by: sortBy,
			in_stock_only: inStockOnly,
			limit: 24,
			page: 1
		}),
		service.getMarketplaceCategories(tenantId)
	]);

	return {
		products: productsResult.products?.products || [],
		categories: categoriesResult.categories || [],
		pagination: productsResult.products?.pagination || { page: 1, limit: 24, total: 0, pages: 0 },
		filters: { category, search, minPrice, maxPrice, sortBy, inStockOnly }
	};
}
