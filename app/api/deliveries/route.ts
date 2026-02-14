import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@/lib/supabase/client';
import { DeliveryService } from '@/lib/pos/delivery';
import { DeliveryInsert, DeliveryUpdate } from '@/lib/types/database';

export async function GET(req: NextRequest) {
    try {
        const supabase = await createClient();
        const { data: { user } } = await supabase.auth.getUser();
        if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

        const searchParams = req.nextUrl.searchParams;
        const branchId = searchParams.get('branchId') || undefined;
        const status = searchParams.get('status') || undefined;

        // Get Tenant
        const { data: userProfile } = await supabase.from('users').select('tenant_id').eq('id', user.id).single();
        if (!userProfile?.tenant_id) return NextResponse.json({ error: 'Tenant context missing' }, { status: 400 });

        const deliveries = await DeliveryService.getDeliveries(userProfile.tenant_id, branchId, status);
        return NextResponse.json(deliveries);
    } catch (error) {
        return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 });
    }
}

export async function POST(req: NextRequest) {
    try {
        const supabase = await createClient();
        const { data: { user } } = await supabase.auth.getUser();
        if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

        const { data: userProfile } = await supabase.from('users').select('tenant_id').eq('id', user.id).single();
        if (!userProfile?.tenant_id) return NextResponse.json({ error: 'Tenant context missing' }, { status: 400 });

        const body = await req.json();

        // Generate simple tracking number (mock logic)
        const trackingNumber = `TRK-${Date.now().toString().slice(-6)}`;

        const deliveryData: DeliveryInsert = {
            ...body,
            tenant_id: userProfile.tenant_id,
            tracking_number: trackingNumber,
            delivery_status: 'pending'
        };

        const delivery = await DeliveryService.createDelivery(deliveryData);
        return NextResponse.json(delivery);
    } catch (error) {
        console.error('Create delivery error', error);
        return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 });
    }
}

export async function PUT(req: NextRequest) {
    try {
        const supabase = await createClient();
        const { data: { user } } = await supabase.auth.getUser();
        if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

        const body = await req.json();
        const { id, type, riderId, status, ...updates } = body;
        // type: 'assign' | 'status'

        let result;

        if (type === 'assign' && riderId) {
            result = await DeliveryService.assignRider(id, riderId);
        } else if (type === 'status' && status) {
            const updateData: DeliveryUpdate = { delivery_status: status, ...updates };
            // If delivered, maybe set actual time
            if (status === 'delivered') {
                updateData.actual_delivery_time = new Date().toISOString();
            }
            result = await DeliveryService.updateStatus(id, updateData);
        } else {
            return NextResponse.json({ error: 'Invalid operation' }, { status: 400 });
        }

        return NextResponse.json(result);
    } catch (error) {
        console.error('Update delivery error', error);
        return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 });
    }
}
