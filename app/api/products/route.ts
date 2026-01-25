import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@/lib/supabase/server';
import { productSchema } from '@/lib/utils/validation';

export async function GET(req: NextRequest) {
    const supabase = await createClient();
    const searchParams = req.nextUrl.searchParams;
    const branchId = searchParams.get('branchId');

    if (!branchId) {
        return NextResponse.json({ error: 'Branch ID required' }, { status: 400 });
    }

    const { data, error } = await supabase
        .from('products')
        .select('*')
        .eq('branch_id', branchId)
        .eq('is_active', true);

    if (error) return NextResponse.json({ error: error.message }, { status: 500 });
    return NextResponse.json(data);
}

export async function POST(req: NextRequest) {
    const body = await req.json();
    const validation = productSchema.safeParse(body);

    if (!validation.success) {
        return NextResponse.json({ error: validation.error.format() }, { status: 400 });
    }

    const supabase = await createClient();
    // Get tenant and branch from session/user context usually, but for simplicity taking from body or assuming middleware validated context
    // Here assuming body has everything needed for the insert policy to pass or fail

    const { data, error } = await supabase
        .from('products')
        .insert(body)
        .select()
        .single();

    if (error) return NextResponse.json({ error: error.message }, { status: 500 });
    return NextResponse.json(data);
}
