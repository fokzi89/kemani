import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@/lib/supabase/server';
import { saleSchema } from '@/lib/utils/validation';
import { transactionService } from '@/lib/pos/transaction';

export async function GET(req: NextRequest) {
  const supabase = await createClient();
  const branchId = req.nextUrl.searchParams.get('branchId');

  const { data, error } = await supabase
    .from('sales')
    .select('*, sale_items(*)')
    .eq('branch_id', branchId as string)
    .order('created_at', { ascending: false });

  if (error) return NextResponse.json({ error: error.message }, { status: 500 });
  return NextResponse.json(data);
}

export async function POST(req: NextRequest) {
  const body = await req.json();
  const validation = saleSchema.safeParse(body);

  if (!validation.success) {
    return NextResponse.json({ error: validation.error.format() }, { status: 400 });
  }

  try {
    const supabase = await createClient();
    const { data: { user } } = await supabase.auth.getUser();

    if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

    // Fetch tenant/branch context (assuming helper or stored in metadata)
    const { data: userData } = await supabase.from('users').select('tenant_id, branch_id').eq('id', user.id).single();
    if (!userData) return NextResponse.json({ error: 'User context not found' }, { status: 400 });

    const sale = await transactionService.processSale(body, user.id, userData.tenant_id, userData.branch_id);
    return NextResponse.json(sale);
  } catch (error) {
    console.error(error);
    return NextResponse.json({ error: 'Transaction failed' }, { status: 500 });
  }
}
