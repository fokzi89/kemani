import type { RequestHandler } from './$types';
import { json } from '@sveltejs/kit';
import { createClient } from '$lib/services/supabase';

export const GET: RequestHandler = async ({ params, url }) => {
    try {
        const { id } = params;
        const phone = url.searchParams.get('phone'); // For guest tracking

        if (!id) {
            return json({ error: 'Order ID required' }, { status: 400 });
        }

        const supabase = createClient();

        let query = supabase
            .from('orders')
            .select(`
                *,
                order_items (
                    id,
                    product_id,
                    product_name,
                    quantity,
                    unit_price,
                    subtotal
                )
            `)
            .eq('id', id);

        // If phone provided, verify it matches (for guest tracking)
        if (phone) {
            query = query.eq('customer_phone', phone);
        }

        const { data: order, error } = await query.single();

        if (error) {
            console.error('Order fetch error:', error);
            return json({ error: 'Order not found' }, { status: 404 });
        }

        return json(order);
    } catch (error: any) {
        console.error('Order tracking API Error:', error);
        return json({ error: error.message || 'Internal Server Error' }, { status: 500 });
    }
};
