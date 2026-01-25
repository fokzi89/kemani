import { NextRequest, NextResponse } from 'next/server';
import { createAdminClient } from '@/lib/supabase/server';

export async function POST(req: NextRequest) {
    try {
        const signature = req.headers.get('verif-hash');
        const secretHash = process.env.FLUTTERWAVE_SECRET_HASH || '';

        if (!signature || signature !== secretHash) {
            return NextResponse.json({ message: 'Invalid signature' }, { status: 401 });
        }

        const event = await req.json();

        if (event.event === 'charge.completed' && event.data.status === 'successful') {
            const reference = event.data.tx_ref;

            const supabase = await createAdminClient();

            // Update Sale
            const { error: saleError } = await supabase
                .from('sales')
                .update({ status: 'completed' })
                .eq('payment_reference', reference);

            if (saleError) {
                // Update Order
                await supabase
                    .from('orders')
                    .update({
                        payment_status: 'paid',
                        order_status: 'confirmed'
                    })
                    .eq('payment_reference', reference);
            }
        }

        return NextResponse.json({ received: true }, { status: 200 });
    } catch (error) {
        console.error('Flutterwave webhook error:', error);
        return NextResponse.json({ message: 'Internal server error' }, { status: 500 });
    }
}
