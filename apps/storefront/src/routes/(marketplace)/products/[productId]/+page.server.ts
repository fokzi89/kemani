import { error } from '@sveltejs/kit';
import { MarketplaceService } from '$lib/services/marketplace';
import { supabase } from '$lib/supabase';

export async function load({ params, locals }) {
	const productId = params.productId;
	const tenantId = locals.referringTenantId;

	if (!tenantId) {
		throw error(404, 'Storefront context not found');
	}

	const marketplaceService = new MarketplaceService(supabase);
	
	// Fetch product details directly from the inventory optimized service
	const { product, error: fetchError } = await marketplaceService.getMarketplaceProduct(productId, tenantId);

	if (fetchError || !product) {
		console.error('[ProductDetail] Error:', fetchError);
		throw error(404, 'Product not found in this store inventory');
	}

	// Fetch related products (same category)
	const { products: relatedResponse } = await marketplaceService.getMarketplaceProducts(tenantId, {
		category: product.category,
		limit: 5
	});

	const relatedProducts = (relatedResponse?.products || []).filter(p => p.id !== productId).slice(0, 4);

	return {
		product,
		relatedProducts
	};
}
