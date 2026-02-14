import type { RequestHandler } from './$types';
import { json } from '@sveltejs/kit';

// POST - Calculate delivery fee
export const POST: RequestHandler = async ({ request }) => {
    try {
        const { delivery_method, origin_coordinates, destination_coordinates, branch_id } = await request.json();

        if (!delivery_method) {
            return json({ error: 'Delivery method required' }, { status: 400 });
        }

        // Base delivery fees
        const fees = {
            self_pickup: 0,
            bicycle: 500,
            motorbike: 800,
            platform_delivery: 1500 // Inter-city
        };

        let deliveryFee = fees[delivery_method as keyof typeof fees] || 0;

        // Add standard N100 delivery fee addition
        const totalFee = deliveryFee + 100;

        return json({
            base_fee: deliveryFee,
            additional_fee: 100,
            total_fee: totalFee,
            delivery_method
        });
    } catch (error: any) {
        console.error('Delivery calculation API Error:', error);
        return json({ error: error.message || 'Internal Server Error' }, { status: 500 });
    }
};
