import type { RequestHandler } from './$types';
import { json } from '@sveltejs/kit';
import { createClient } from '$lib/services/supabase';

export const GET: RequestHandler = async ({ params }) => {
    try {
        const { id } = params;

        if (!id) {
            return json({ error: 'Product ID required' }, { status: 400 });
        }

        const supabase = createClient();

        const { data, error } = await supabase
            .from('storefront_products')
            .select('*')
            .eq('id', id)
            .eq('is_active', true)
            .single();

        if (error) {
            console.error('Product fetch error:', error);
            return json({ error: error.message }, { status: 404 });
        }

        return json(data);
    } catch (error: any) {
        console.error('Product API Error:', error);
        return json({ error: error.message || 'Internal Server Error' }, { status: 500 });
    }
};
