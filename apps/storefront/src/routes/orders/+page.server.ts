import { redirect } from '@sveltejs/kit';
import type { PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ locals: { supabase, safeGetSession } }) => {
    const { user } = await safeGetSession();

    if (!user) {
        throw redirect(303, '/auth/signin?next=/orders');
    }

    // 1. Get the customer profile for the logged-in user to find their customer_id
    const { data: customer, error: customerError } = await supabase
        .from('storefront_customers')
        .select('id')
        .eq('user_id', user.id)
        .single();

    if (customerError && customerError.code !== 'PGRST116') {
        // PGRST116 is "Row not found" which is fine (new user)
        console.error('Error fetching customer profile:', customerError);
    }

    let orders: any[] = [];

    if (customer) {
        const { data: customerOrders, error: ordersError } = await supabase
            .from('storefront_orders')
            .select(`
                id, 
                order_status, 
                total_amount, 
                created_at, 
                delivery_method, 
                delivery_name,
                branch_id,
                tenant_id,
                paystack_reference,
                items:storefront_order_items (
                    product_name,
                    quantity
                )
            `)
            .eq('customer_id', customer.id)
            .order('created_at', { ascending: false })
            .limit(50);

        if (ordersError) {
            console.error('Error fetching orders:', ordersError);
        } else {
            orders = customerOrders || [];
        }
    }

    // Enrich with tenant branding (Business Name)
    if (orders.length > 0) {
        const tenantIds = [...new Set(orders.map((o: any) => o.tenant_id))];
        const { data: brands } = await supabase
            .from('tenant_branding')
            .select('tenant_id, business_name')
            .in('tenant_id', tenantIds);

        // Transform orders to include business name and normalize fields
        orders = orders.map((order: any) => {
            const brand = brands?.find((b: any) => b.tenant_id === order.tenant_id);
            return {
                ...order,
                business_name: brand?.business_name || 'Store',
                status: order.order_status, // UI expects `status` alias
                customer_name: order.delivery_name
            };
        });
    }

    return { orders, user };
};
