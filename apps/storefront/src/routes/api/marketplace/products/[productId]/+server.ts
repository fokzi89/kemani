// Marketplace Product Detail API Endpoint (Public)
// GET /api/marketplace/[slug]/products/[productId] - Get single product details

import { json } from '@sveltejs/kit';
import { supabase } from '$lib/supabase';
import { MarketplaceService } from '$lib/services/marketplace';

export async function GET({ locals, params }: { locals: any; params: any }) {
  try {
    const tenantId = locals.referringTenantId || params.slug || params.tenantId;
    const { productId } = params;

    const marketplaceService = new MarketplaceService(supabase);
    const result = await marketplaceService.getMarketplaceProduct(productId, tenantId);

    if (result.error) {
      return json({ error: result.error }, { status: 404 });
    }

    return json({ product: result.product });
  } catch (error: any) {
    return json({ error: error.message || 'Failed to fetch product' }, { status: 500 });
  }
};
