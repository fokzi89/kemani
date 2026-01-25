import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@/lib/supabase/server';

export async function POST(req: NextRequest) {
    const formData = await req.formData();
    const file = formData.get('file') as File;
    const branchId = formData.get('branchId') as string;

    if (!file || !branchId) {
        return NextResponse.json({ error: 'File and Branch ID required' }, { status: 400 });
    }

    // Parse CSV (basic implementation)
    const text = await file.text();
    const rows = text.split('\n').slice(1); // Skip header

    const products = rows.map(row => {
        const [name, unit_price, stock_quantity, sku, category] = row.split(',');
        if (!name || !unit_price) return null;
        return {
            name: name.trim(),
            unit_price: parseFloat(unit_price),
            stock_quantity: parseInt(stock_quantity) || 0,
            sku: sku?.trim(),
            category: category?.trim(),
            branch_id: branchId,
            // tenant_id should be injected via verified user/session in real app
        };
    }).filter(Boolean);

    const supabase = await createClient();

    // Need to get tenant_id from current session to ensure security
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

    // Enrich with tenant_id logic here...

    // Batch insert
    const { data, error } = await supabase.from('products').insert(products as any).select();

    if (error) return NextResponse.json({ error: error.message }, { status: 500 });
    return NextResponse.json({ count: data.length });
}
