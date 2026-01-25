import { NextRequest, NextResponse } from 'next/server';
import crypto from 'crypto';
import { createAdminClient } from '@/lib/supabase/server';

export async function POST(req: NextRequest) {
    try {
        const body = await req.text();
        const hash = crypto
            .createHmac('sha512', process.env.PAYSTACK_SECRET_KEY || '')
            .update(body)
            .digest('hex');

        const signature = req.headers.get('x-paystack-signature');

        if (hash !== signature) {
            return NextResponse.json({ message: 'Invalid signature' }, { status: 401 });
        }

        const event = JSON.parse(body);

        if (event.event === 'charge.success') {
            const reference = event.data.reference;

            // Update Database
            const supabase = await createAdminClient();

            // Try updating Sale
            const { error: saleError } = await supabase
                .from('sales')
                .update({ status: 'completed' }) // Assuming 'completed' means paid/done for simple POS sales
                .eq('payment_reference', reference);

            if (saleError) {
                console.error('Error updating sale:', saleError);
                // If not a sale, try Order (e.g. marketplace order)
                const { error: orderError } = await supabase
                    .from('orders')
                    .update({
                        payment_status: 'paid',
                        payment_method: 'card', // or infer from event
                        order_status: 'confirmed'
                    })
                    .eq('payment_reference', reference);

                if (orderError) {
                    console.error('Error updating order:', orderError);
                }
            }
        }

        return NextResponse.json({ received: true }, { status: 200 });
    } catch (error) {
        console.error('Paystack webhook error:', error);
        return NextResponse.json({ message: 'Internal server error' }, { status: 500 });
    }
}
