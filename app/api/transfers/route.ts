import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@/lib/supabase/server';
import { InterBranchTransferService } from '@/lib/pos/transfer';
import { InterBranchTransferInsert } from '@/lib/types/database';

export async function GET(req: NextRequest) {
    try {
        const supabase = await createClient();
        const { data: { user } } = await supabase.auth.getUser();
        if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

        const { data: userProfile } = await supabase.from('users').select('tenant_id').eq('id', user.id).single();
        if (!userProfile?.tenant_id) return NextResponse.json({ error: 'Tenant context missing' }, { status: 400 });

        const searchParams = req.nextUrl.searchParams;
        const sourceBranchId = searchParams.get('sourceBranchId') || undefined;
        const destBranchId = searchParams.get('destBranchId') || undefined;
        const status = searchParams.get('status') || undefined;

        const transfers = await InterBranchTransferService.getTransfers(userProfile.tenant_id, {
            sourceBranchId,
            destBranchId,
            status
        });

        return NextResponse.json(transfers);
    } catch (error) {
        console.error("Error fetching transfers", error);
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
        const { items, ...transferDataRaw } = body;

        const transferData: InterBranchTransferInsert = {
            ...transferDataRaw,
            tenant_id: userProfile.tenant_id,
            requested_by: user.id
        };

        const result = await InterBranchTransferService.createTransfer(transferData, items);

        return NextResponse.json(result);

    } catch (error) {
        console.error("Error creating transfer", error);
        return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 });
    }
}

export async function PUT(req: NextRequest) {
    try {
        const supabase = await createClient();
        const { data: { user } } = await supabase.auth.getUser();
        if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

        const body = await req.json();
        const { transferId, status } = body;

        if (!transferId || !status) {
            return NextResponse.json({ error: 'Missing transferId or status' }, { status: 400 });
        }

        const result = await InterBranchTransferService.updateStatus(transferId, status, user.id);

        return NextResponse.json(result);

    } catch (error) {
        console.error("Error updating transfer status", error);
        return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 });
    }
}
