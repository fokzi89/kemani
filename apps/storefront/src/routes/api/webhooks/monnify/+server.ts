import { json } from '@sveltejs/kit';
import { MONNIFY_SECRET_KEY } from '$env/static/private';
import crypto from 'crypto';

export async function POST({ request }) {
    const signature = request.headers.get('monnify-signature');
    const body = await request.text();

    if (!signature) {
        return json({ error: 'Missing signature' }, { status: 401 });
    }

    // 1. Verify Signature
    const hash = crypto
        .createHmac('sha512', MONNIFY_SECRET_KEY)
        .update(body)
        .digest('hex');

    if (hash !== signature) {
        console.error('Monnify Webhook: Invalid signature');
        return json({ error: 'Invalid signature' }, { status: 401 });
    }

    const payload = JSON.parse(body);

    // 2. Handle successful transaction
    if (payload.eventType === 'SUCCESSFUL_TRANSACTION') {
        const transaction = payload.eventData;
        const reference = transaction.paymentReference;
        console.log('Monnify Webhook: Payment successful', reference);
        
        // In a real app, you would verify the transaction status via API here
        // and update the order in your database.
    }

    return json({ received: true });
}
