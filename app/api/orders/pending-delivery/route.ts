import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@/lib/supabase/client';
import { OrderService } from '@/lib/pos/orders';

export async function GET(req: NextRequest) {
    try {
        const supabase = await createClient();
        const { data: { user } } = await supabase.auth.getUser();
        if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

        const searchParams = req.nextUrl.searchParams;
        const branchId = searchParams.get('branchId') || undefined;

        const { data: userProfile } = await supabase.from('users').select('tenant_id').eq('id', user.id).single();
        if (!userProfile?.tenant_id) return NextResponse.json({ error: 'Tenant context missing' }, { status: 400 });

        const orders = await OrderService.getOrdersReadyForDelivery(userProfile.tenant_id, branchId);
        return NextResponse.json(orders);
    } catch (error) {
        console.error('Error fetching pending orders', error);
        return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 });
    }
}
