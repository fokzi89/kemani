
import { error } from '@sveltejs/kit';

export async function load({ locals, parent }) {
    const { provider, session } = await parent();
    
    // Fallback to locals if parent doesn't have it for some reason
    const activeSession = session || locals.session;

    if (!activeSession) {
        return { orders: [] };
    }

    const { data: orders, error: ordersErr } = await locals.supabase
        .from('orders')
        .select(`
            *,
            branches(name, address, city),
            order_items(id, product_name, quantity, unit_price, subtotal)
        `)
        .eq('customer_id', activeSession.user.id)
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
