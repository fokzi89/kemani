import { json } from '@sveltejs/kit';
import { MarketplaceService } from '$lib/services/marketplace';
import { supabase } from '$lib/supabase';

export async function GET({ locals, params }: { locals: any; params: any }) {
  try {
    const tenantId = locals.referringTenantId || params.slug || params.tenantId;

    if (!tenantId) {
      return json({ error: 'Tenant identifier is required' }, { status: 400 });
    }

    const marketplaceService = new MarketplaceService(supabase);
    const result = await marketplaceService.getMarketplaceCategories(tenantId);

    if (result.error) {
      return json({ error: result.error }, { status: 500 });
    }

    return json({ categories: result.categories });
  } catch (error: any) {
    return json({ error: 'Internal server error' }, { status: 500 });
  }
}
