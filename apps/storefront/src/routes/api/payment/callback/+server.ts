import { json, error } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import crypto from 'crypto';
import { PAYSTACK_SECRET_KEY } from '$env/static/private';

/**
 * Paystack Webhook Handler
 * 
 * Paystack sends POST requests to this endpoint when payment events occur.
 * We verify the signature, then update the order status accordingly.
 * 
 * Docs: https://paystack.com/docs/payments/webhooks
 */
export const POST: RequestHandler = async ({ request, locals: { supabase } }) => {
    try {
        const body = await request.text();

        // 1. Verify Paystack signature
        const signature = request.headers.get('x-paystack-signature');
        if (!signature) {
            throw error(401, 'Missing signature');
        }

        const hash = crypto
            .createHmac('sha512', PAYSTACK_SECRET_KEY)
            .update(body)
            .digest('hex');

        if (hash !== signature) {
            console.error('Paystack webhook: invalid signature');
            throw error(401, 'Invalid signature');
        }

        // 2. Parse event
        const event = JSON.parse(body);
        const eventType: string = event.event;
        const data = event.data;

        console.log(`Paystack webhook received: ${eventType}`, { reference: data?.reference });

        // 3. Handle events
        switch (eventType) {
            case 'charge.success': {
                const reference = data.reference; // This is our order ID
                const amountPaid = data.amount / 100; // Convert from kobo to naira
                const channel = data.channel; // card, bank, ussd, etc.
                const paidAt = data.paid_at;

                // Update order status to paid
                const { error: updateError } = await supabase
                    .from('storefront_orders')
                    .update({
                        status: 'paid',
                        payment_reference: reference,
                        payment_channel: channel,
                        payment_amount: amountPaid,
                        paid_at: paidAt,
                        updated_at: new Date().toISOString()
                    })
                    .eq('id', reference)
                    .eq('status', 'pending_payment'); // Only update if still pending

                if (updateError) {
                    console.error('Failed to update order:', updateError);
                    // Still return 200 so Paystack doesn't retry
                } else {
                    console.log(`Order ${reference} marked as paid`);
                }

                break;
            }

            case 'charge.failed': {
                const reference = data.reference;

                await supabase
                    .from('storefront_orders')
                    .update({
                        status: 'payment_failed',
                        updated_at: new Date().toISOString()
                    })
                    .eq('id', reference)
                    .eq('status', 'pending_payment');

                console.log(`Order ${reference} payment failed`);
                break;
            }

            case 'transfer.success':
            case 'transfer.failed':
            case 'transfer.reversed': {
                // Future: handle payouts to merchants
                console.log(`Transfer event: ${eventType}`, data);
                break;
            }

            default:
                console.log(`Unhandled Paystack event: ${eventType}`);
        }

        // Always return 200 to acknowledge receipt
        return json({ received: true });
    } catch (err: any) {
        console.error('Paystack webhook error:', err);
        // Return 200 even on error to prevent Paystack retries for invalid requests
        if (err.status === 401) throw err;
        return json({ received: true });
    }
};
