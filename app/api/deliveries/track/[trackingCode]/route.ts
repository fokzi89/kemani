import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@/lib/supabase/client';
import { DeliveryService } from '@/lib/pos/delivery';

export async function GET(
    req: NextRequest,
    { params }: { params: Promise<{ trackingCode: string }> }
) {
    try {
        const { trackingCode } = await params;

        // No auth check required here as this is a public tracking endpoint.
        // However, we should be careful about what data is returned.
        // DeliveryService.getDeliveryByTracking returns limited data but includes customer specifics.
        // We might want to strip sensitive customer data if not intended for public view, 
        // but usually tracking page shows "Delivering to: John D.".

        const delivery = await DeliveryService.getDeliveryByTracking(trackingCode);

        if (!delivery) {
            return NextResponse.json({ error: 'Delivery not found' }, { status: 404 });
        }

        // Sanitize response if needed (e.g. hide internal IDs)
        const sanitized = {
            tracking_number: delivery.tracking_number,
            status: delivery.delivery_status,
            type: delivery.delivery_type,
            estimated_delivery_time: delivery.estimated_delivery_time,
            actual_delivery_time: delivery.actual_delivery_time,
            // Show limited rider info
            rider: delivery.rider ? {
                name: delivery.rider.user?.full_name || 'Assigned Rider',
                phone: delivery.rider.phone // Maybe hide phone or mask it?
            } : null,
            order: {
                order_number: delivery.order?.order_number
            }
        };

        return NextResponse.json(sanitized);
    } catch (error) {
        console.error('Tracking error', error);
        return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 });
    }
}
