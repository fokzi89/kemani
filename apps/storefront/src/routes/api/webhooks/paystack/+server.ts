import type { RequestHandler } from './$types';
import { json } from '@sveltejs/kit';
import { createClient } from '$lib/services/supabase';
import crypto from 'crypto';

// POST - Paystack webhook handler
export const POST: RequestHandler = async ({ request }) => {
    try {
        const body = await request.text();
        const signature = request.headers.get('x-paystack-signature');

        if (!signature) {
            return json({ error: 'Missing signature' }, { status: 400 });
        }

        // Verify webhook signature
        const hash = crypto
            .createHmac('sha512', import.meta.env.VITE_PAYSTACK_SECRET_KEY || '')
            .update(body)
            .digest('hex');

        if (hash !== signature) {
            console.error('Invalid Paystack signature');
            return json({ error: 'Invalid signature' }, { status: 401 });
        }

        const event = JSON.parse(body);

        // Handle successful charge
        if (event.event === 'charge.success') {
            const { reference, amount, customer } = event.data;

            const supabase = createClient();

            // Update order payment status
            const { error } = await supabase
                .from('orders')
                .update({
                    payment_status: 'paid',
                    order_status: 'confirmed',
                    payment_reference: reference,
                    paid_at: new Date().toISOString()
                })
                .eq('order_number', reference);

            if (error) {
                console.error('Order update error:', error);
                return json({ error: 'Failed to update order' }, { status: 500 });
            }
        }

        return json({ received: true });
    } catch (error: any) {
        console.error('Paystack webhook error:', error);
        return json({ error: error.message || 'Internal Server Error' }, { status: 500 });
    }
};
