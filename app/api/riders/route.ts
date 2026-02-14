import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@/lib/supabase/client';
import { RiderService } from '@/lib/pos/rider';
import { RiderInsert } from '@/lib/types/database';

export async function GET(req: NextRequest) {
    try {
        const supabase = await createClient();
        const { data: { user } } = await supabase.auth.getUser();
        if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

        const { data: userProfile } = await supabase.from('users').select('tenant_id').eq('id', user.id).single();
        if (!userProfile?.tenant_id) return NextResponse.json({ error: 'Tenant context missing' }, { status: 400 });

        const searchParams = req.nextUrl.searchParams;
        const available = searchParams.get('available') === 'true';

        const riders = await RiderService.getRiders(userProfile.tenant_id, available);
        return NextResponse.json(riders);
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
        const riderData: RiderInsert = {
            ...body,
            tenant_id: userProfile.tenant_id
        };

        const rider = await RiderService.createRider(riderData);
        return NextResponse.json(rider);
    } catch (error) {
        console.error('Create rider error', error);
        return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 });
    }
}
