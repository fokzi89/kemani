import { NextRequest, NextResponse } from 'next/server';
import {
  getProductSalesHistory,
  getTopProducts,
  getSlowMovingProducts,
} from '@/lib/analytics';
import { createClient } from '@/lib/supabase/server';

/**
 * GET /api/analytics/products
 * Get product analytics
 *
 * Query params:
 * - type: "history" | "top" | "slow-moving"
 * - product_id: UUID (required for type=history)
 * - start_date: YYYY-MM-DD
 * - end_date: YYYY-MM-DD
 * - branch_id: optional UUID
 * - limit: number (for top/slow-moving)
 * - order_by: "revenue" | "quantity" | "profit" (for top products)
 */
export async function GET(request: NextRequest) {
  try {
    const supabase = await createClient();

    // Get authenticated user
    const {
      data: { user },
      error: authError,
    } = await supabase.auth.getUser();

    if (authError || !user) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    // Get user's tenant_id
    const { data: userData, error: userError } = await supabase
      .from('users')
      .select('tenant_id')
      .eq('id', user.id)
      .single();

    if (userError || !userData) {
      return NextResponse.json({ error: 'User not found' }, { status: 404 });
    }

    const tenantId = userData.tenant_id;

    // Parse query parameters
    const searchParams = request.nextUrl.searchParams;
    const type = searchParams.get('type') || 'top';
    const productId = searchParams.get('product_id');
    const startDate = searchParams.get('start_date');
    const endDate = searchParams.get('end_date');
    const branchId = searchParams.get('branch_id');
    const limit = parseInt(searchParams.get('limit') || '10');
    const orderBy = (searchParams.get('order_by') || 'revenue') as 'revenue' | 'quantity' | 'profit';

    if (!startDate || !endDate) {
      return NextResponse.json(
        { error: 'start_date and end_date are required' },
        { status: 400 }
      );
    }

    let data;

    switch (type) {
      case 'history':
        if (!productId) {
          return NextResponse.json(
            { error: 'product_id is required for type=history' },
            { status: 400 }
          );
        }
        data = await getProductSalesHistory(
          tenantId,
          productId,
          { start: startDate, end: endDate },
          branchId || undefined
        );
        break;

      case 'top':
        data = await getTopProducts(
          tenantId,
          { start: startDate, end: endDate },
          limit,
          branchId || undefined,
          orderBy
        );
        break;

      case 'slow-moving':
        data = await getSlowMovingProducts(
          tenantId,
          { start: startDate, end: endDate },
          limit,
          branchId || undefined
        );
        break;

      default:
        return NextResponse.json({ error: 'Invalid type parameter' }, { status: 400 });
    }

    return NextResponse.json({
      success: true,
      data,
    });
  } catch (error) {
    console.error('Products analytics API error:', error);
    return NextResponse.json(
      { error: 'Internal server error', details: (error as Error).message },
      { status: 500 }
    );
  }
}
