// Marketplace Product Detail API Endpoint (Public)
// GET /api/marketplace/[tenantId]/products/[productId] - Get single product details

import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { createClient } from '@supabase/supabase-js';
import { MarketplaceService } from '$lib/services/marketplace';

const supabase = createClient(
  import.meta.env.VITE_SUPABASE_URL,
  import.meta.env.VITE_SUPABASE_ANON_KEY
);

export const GET: RequestHandler = async ({ params }) => {
  try {
    const { tenantId, productId } = params;

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
