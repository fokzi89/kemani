import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@/lib/supabase/server';
import { inventoryService } from '@/lib/pos/inventory';

export async function GET(req: NextRequest) {
    const branchId = req.nextUrl.searchParams.get('branchId');
    if (!branchId) return NextResponse.json({ error: 'Branch ID required' }, { status: 400 });

    try {
        const alerts = await inventoryService.getLowStockAlerts(branchId);
        return NextResponse.json(alerts);
    } catch (error: any) {
        return NextResponse.json({ error: error.message }, { status: 500 });
    }
}

export async function POST(req: NextRequest) {
    const body = await req.json();
    const { productId, quantityDelta, type, branchId } = body;

    try {
        const supabase = await createClient();
        const { data: { user } } = await supabase.auth.getUser();
        if (!user) throw new Error('Unauthorized');

        const { data: userData } = await supabase.from('users').select('tenant_id').eq('id', user.id).single();

        await inventoryService.adjustStock(
            productId,
            quantityDelta,
            type,
            user.id,
            userData?.tenant_id,
            branchId,
            body.notes
        );
        return NextResponse.json({ success: true });
    } catch (error: any) {
        return NextResponse.json({ error: error.message }, { status: 500 });
    }
}
