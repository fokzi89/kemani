import { json } from '@sveltejs/kit';
import { supabase } from '$lib/supabase';
import { MarketplaceService } from '$lib/services/marketplace';

export async function GET({ locals, params }: { locals: any; params: { slug?: string } }) {
  try {
    const tenantId = locals.referringTenantId || params.slug;
    if (!tenantId) return json({ error: 'Tenant identifier is required' }, { status: 400 });

    const marketplaceService = new MarketplaceService(supabase);
    const result = await marketplaceService.getStorefrontInfo(tenantId);

    if (result.error) return json({ error: result.error }, { status: 500 });
    return json({ storefront: result.storefront });
  } catch (error: any) {
    return json({ error: 'Internal server error' }, { status: 500 });
  }
}
