// Marketplace Products API Endpoint (Public)
// GET /api/marketplace/[slug]/products - Get products for a tenant by slug

import { json } from '@sveltejs/kit';
import { supabase } from '$lib/supabase';
import { MarketplaceService } from '$lib/services/marketplace';
import type { MarketplaceFilters } from '$lib/types/ecommerce';

export async function GET({ locals, params, url }: { locals: any; params: any; url: URL }) {
  try {
    // 1. Try host-based resolution from hooks (Approach 2), then fallback to slug
    const tenantId = locals.referringTenantId || params.slug || params.tenantId;
    if (!tenantId) return json({ error: 'Tenant identifier is required' }, { status: 400 });

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
      branch_id: url.searchParams.get('branch_id') || undefined,
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
