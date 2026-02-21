import type { RequestHandler } from './$types';
import { json } from '@sveltejs/kit';

export const GET: RequestHandler = async ({ url, locals: { supabase } }) => {
    try {
        const branchId = url.searchParams.get('branchId');
        const tenantId = url.searchParams.get('tenantId');
        const category = url.searchParams.get('category');
        const search = url.searchParams.get('search') || url.searchParams.get('q');
        const minPrice = url.searchParams.get('minPrice');
        const maxPrice = url.searchParams.get('maxPrice');
        const limit = parseInt(url.searchParams.get('limit') || '50');
        const offset = parseInt(url.searchParams.get('offset') || '0');
        const sortBy = url.searchParams.get('sortBy') || 'created_at';

        // Require at least branchId or tenantId for context
        if (!branchId && !tenantId) {
            return json({ error: 'Branch ID or Tenant ID required' }, { status: 400 });
        }

        const { data, error } = await supabase.rpc('search_storefront_products', {
            p_branch_id: branchId || null,
            p_tenant_id: tenantId || null,
            p_search_query: search || null,
            p_category: category || null,
            p_min_price: minPrice ? parseFloat(minPrice) : null,
            p_max_price: maxPrice ? parseFloat(maxPrice) : null,
            p_limit: limit,
            p_offset: offset,
            p_sort_by: sortBy,
            p_available_only: true
        });

        if (error) {
            console.error('Catalog fetch error:', error);
            return json({ error: error.message }, { status: 500 });
        }

        return json(data);
    } catch (error: any) {
        console.error('Catalog API Error:', error);
        return json({ error: error.message || 'Internal Server Error' }, { status: 500 });
    }
};
