import type { PageServerLoad } from './$types';
import { error } from '@sveltejs/kit';
import { MarketplaceService } from '$lib/services/marketplace';

export const load: PageServerLoad = async ({ params, url }) => {
  const { tenantId } = params;
  const category = url.searchParams.get('category');
  const searchQuery = url.searchParams.get('q');

  // Resolve tenant ID if slug (user-friendly URL)
  let resolvedTenantId = tenantId;
  const isUuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(tenantId);

  if (!isUuid) {
    try {
      resolvedTenantId = await MarketplaceService.getTenantIdBySlug(tenantId);
    } catch (e) {
      throw error(404, 'Store not found');
    }
  }

  // Fetch data in parallel for better performance
  try {
    const [storeDetails, products, categories] = await Promise.all([
      MarketplaceService.getStorefrontDetails(resolvedTenantId),
      MarketplaceService.getStorefrontProducts(resolvedTenantId, category),
      MarketplaceService.getCategories(resolvedTenantId)
    ]);

    // Filter by search query if provided
    const filteredProducts = searchQuery
      ? products.filter(p =>
          p.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
          p.description?.toLowerCase().includes(searchQuery.toLowerCase())
        )
      : products;

    return {
      storeDetails,
      products: filteredProducts,
      categories,
      tenantId: resolvedTenantId,
      category,
      searchQuery
    };
  } catch (e) {
    console.error('Error loading marketplace:', e);
    throw error(404, 'Store not found');
  }
};
