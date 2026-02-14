import type { RequestHandler } from './$types';
import { json } from '@sveltejs/kit';
import { createClient } from '$lib/services/supabase';

export const GET: RequestHandler = async ({ url }) => {
    try {
        const branchId = url.searchParams.get('branchId');
        const category = url.searchParams.get('category');
        const search = url.searchParams.get('search');
        const minPrice = url.searchParams.get('minPrice');
        const maxPrice = url.searchParams.get('maxPrice');

        if (!branchId) {
            return json({ error: 'Branch ID required' }, { status: 400 });
        }

        const supabase = createClient();

        let query = supabase
            .from('storefront_products')
            .select('*')
            .eq('branch_id', branchId)
            .eq('is_active', true)
            .eq('is_available', true);

        // Apply filters
        if (category) {
            query = query.eq('category', category);
        }

        if (search) {
            query = query.ilike('name', `%${search}%`);
        }

        if (minPrice) {
            query = query.gte('price', parseFloat(minPrice));
        }

        if (maxPrice) {
            query = query.lte('price', parseFloat(maxPrice));
        }

        const { data, error } = await query.order('created_at', { ascending: false });

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
