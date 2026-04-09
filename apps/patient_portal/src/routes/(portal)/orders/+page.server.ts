
import { error } from '@sveltejs/kit';
import { createClient } from '@supabase/supabase-js';
import { PUBLIC_SUPABASE_URL, PUBLIC_SUPABASE_ANON_KEY } from '$env/static/public';

const db = createClient(PUBLIC_SUPABASE_URL, PUBLIC_SUPABASE_ANON_KEY);

export async function load({ locals, parent }) {
    const session = await locals.auth.validate();
    if (!session) throw error(401, 'Unauthorized');

    const { provider } = await parent();
    if (!provider) throw error(404, 'Provider not found');

    const { data: orders, error: ordersErr } = await db
        .from('orders')
        .select(`
            *,
            branches(name, address, city),
            order_items(id, product_name, quantity, unit_price, subtotal)
        `)
        .eq('customer_id', session.user.id)
        .eq('tenant_id', provider.id)
        .order('created_at', { ascending: false });

    if (ordersErr) {
        console.error('Error fetching orders:', ordersErr);
        return { orders: [] };
    }

    return {
        orders: orders || []
    };
}
