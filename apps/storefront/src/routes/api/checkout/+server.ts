import { error, json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';

export const POST: RequestHandler = async ({ request, locals: { supabase } }) => {
    try {
        const body = await request.json();
        const {
            items,
            deliveryMethod,
            deliveryFee,
            customerName,
            customerPhone,
            customerAddress,
            deliveryInstructions,
            subtotal,
            totalAmount
        } = body;

        if (!items?.length) {
            throw error(400, 'Cart is empty');
        }

        if (!customerName || !customerPhone || !customerAddress) {
            throw error(400, 'Delivery information is required');
        }

        // Create order in database
        const { data: order, error: orderError } = await supabase
            .from('storefront_orders')
            .insert({
                customer_name: customerName,
                customer_phone: customerPhone,
                delivery_address: customerAddress,
                delivery_instructions: deliveryInstructions || null,
                delivery_method: deliveryMethod,
                delivery_fee: deliveryFee,
                subtotal,
                total_amount: totalAmount,
                status: 'pending_payment',
                items: items.map((item: any) => ({
                    product_id: item.productId,
                    variant_id: item.variantId || null,
                    title: item.title,
                    price: item.price,
                    quantity: item.quantity,
                    line_total: item.price * item.quantity
                }))
            })
            .select()
            .single();

        if (orderError) {
            console.error('Order creation error:', orderError);
            throw error(500, 'Failed to create order');
        }

        return json({
            orderId: order.id,
            totalAmount: order.total_amount
        });
    } catch (err: any) {
        console.error('Checkout error:', err);
        if (err.status) throw err;
        throw error(500, 'Internal server error');
    }
};
