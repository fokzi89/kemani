import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@/lib/supabase/server';
import { receiptService } from '@/lib/pos/receipt';

export async function GET(req: NextRequest, { params }: { params: { saleId: string } }) {
    const supabase = await createClient();
    const { saleId } = params;

    // Fetch full sale details
    const { data: sale, error: saleError } = await supabase
        .from('sales')
        .select('*, branch:branches(*), tenant:tenants(*), cashier:users(full_name)')
        .eq('id', saleId)
        .single();

    if (saleError || !sale) return NextResponse.json({ error: 'Sale not found' }, { status: 404 });

    const { data: items, error: itemsError } = await supabase
        .from('sale_items')
        .select('*')
        .eq('sale_id', saleId);

    if (itemsError) return NextResponse.json({ error: 'Items not found' }, { status: 500 });

    const receiptData = {
        sale,
        items,
        tenant_name: sale.tenant.name,
        tenant_address: sale.tenant.email, // using email as placeholder address
        branch_name: sale.branch.name,
        branch_address: sale.branch.address,
        cashier_name: sale.cashier.full_name,
    };

    const html = receiptService.generateHTML(receiptData as any); // Cast due to raw query structure

    return new NextResponse(html, {
        headers: {
            'Content-Type': 'text/html',
        },
    });
}
