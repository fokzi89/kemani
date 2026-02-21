import { error } from '@sveltejs/kit';
import type { PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ params, locals: { supabase } }) => {
    const { id } = params;

    const { data: order, error: fetchError } = await supabase
        .from('storefront_orders')
        .select('*')
        .eq('id', id)
        .single();

    if (fetchError || !order) {
        console.error('Error fetching order:', fetchError);
        throw error(404, 'Order not found');
    }

    return { order };
};
