// Marketplace Products API Endpoint (Public)
// GET /api/marketplace/[tenantId]/products - Get tenant's marketplace products

import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { createClient } from '@supabase/supabase-js';
import { MarketplaceService } from '$lib/services/marketplace';
import type { MarketplaceFilters } from '$lib/types/ecommerce';

const supabase = createClient(
  import.meta.env.VITE_SUPABASE_URL,
  import.meta.env.VITE_SUPABASE_ANON_KEY
);

export const GET: RequestHandler = async ({ params, url }) => {
  try {
    const { tenantId } = params;

    // Parse query parameters
    const filters: MarketplaceFilters = {
      category: url.searchParams.get('category') || undefined,
      search: url.searchParams.get('search') || undefined,
      min_price: url.searchParams.get('min_price')
        ? parseFloat(url.searchParams.get('min_price')!)
        : undefined,
      max_price: url.searchParams.get('max_price')
        ? parseFloat(url.searchParams.get('max_price')!)
        : undefined,
      in_stock_only: url.searchParams.get('in_stock_only') === 'true',
      sort_by: (url.searchParams.get('sort_by') as any) || 'newest',
      page: parseInt(url.searchParams.get('page') || '1'),
      limit: parseInt(url.searchParams.get('limit') || '24')
    };

    const marketplaceService = new MarketplaceService(supabase);
    const result = await marketplaceService.getMarketplaceProducts(tenantId, filters);

    if (result.error) {
      return json({ error: result.error }, { status: 500 });
    }

    return json(result.products);
  } catch (error: any) {
    return json({ error: error.message || 'Failed to fetch products' }, { status: 500 });
  }
};
