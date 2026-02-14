import type { RequestHandler} from './$types';
import { json } from '@sveltejs/kit';
import { createClient } from '$lib/services/supabase';
import { nanoid } from 'nanoid';

export const POST: RequestHandler = async ({ request }) => {
    try {
        const orderData = await request.json();

        const {
            branch_id,
            customer_id,
            items,
            delivery_address,
            delivery_method,
            payment_method,
            customer_name,
            customer_phone,
            customer_email
        } = orderData;

        // Validate required fields
        if (!branch_id || !items || items.length === 0) {
            return json({ error: 'Branch ID and items are required' }, { status: 400 });
        }

        if (!customer_name || !customer_phone) {
            return json({ error: 'Customer name and phone are required' }, { status: 400 });
        }

        const supabase = createClient();

        // Calculate totals
        const subtotal = items.reduce((sum: number, item: any) => {
            return sum + (item.price * item.quantity);
        }, 0);

        const deliveryFee = orderData.delivery_fee || 0;
        const platformFee = 50; // N50 platform commission
        const transactionFee = 100; // N100 transaction fee
        const total = subtotal + deliveryFee + platformFee + transactionFee;

        // Generate order number
        const orderNumber = `ORD-${Date.now()}-${nanoid(6).toUpperCase()}`;

        // Create order
        const { data: order, error: orderError } = await supabase
            .from('orders')
            .insert({
                branch_id,
                customer_id,
                order_number: orderNumber,
                customer_name,
                customer_phone,
                customer_email,
                delivery_address,
                delivery_method: delivery_method || 'self_pickup',
                payment_method: payment_method || 'paystack',
                subtotal,
                delivery_fee: deliveryFee,
                platform_fee: platformFee,
                transaction_fee: transactionFee,
                total_amount: total,
                payment_status: 'pending',
                order_status: 'pending'
            })
            .select()
            .single();

        if (orderError) {
            console.error('Order creation error:', orderError);
            return json({ error: orderError.message }, { status: 500 });
        }

        // Create order items
        const orderItems = items.map((item: any) => ({
            order_id: order.id,
            product_id: item.product_id,
            product_name: item.name,
            quantity: item.quantity,
            unit_price: item.price,
            subtotal: item.price * item.quantity
        }));

        const { error: itemsError } = await supabase
            .from('order_items')
            .insert(orderItems);

        if (itemsError) {
            console.error('Order items creation error:', itemsError);
            // Rollback order
            await supabase.from('orders').delete().eq('id', order.id);
            return json({ error: 'Failed to create order items' }, { status: 500 });
        }

        return json({ order, message: 'Order created successfully' }, { status: 201 });
    } catch (error: any) {
        console.error('Orders API Error:', error);
        return json({ error: error.message || 'Internal Server Error' }, { status: 500 });
    }
};
