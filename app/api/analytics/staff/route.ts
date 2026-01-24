import { NextRequest, NextResponse } from 'next/server';
import { getStaffPerformance, getStaffLeaderboard } from '@/lib/analytics';
import { createClient } from '@/lib/supabase/server';

/**
 * GET /api/analytics/staff
 * Get staff performance analytics
 *
 * Query params:
 * - type: "performance" | "leaderboard"
 * - start_date: YYYY-MM-DD
 * - end_date: YYYY-MM-DD
 * - branch_id: optional UUID
 * - staff_role: "cashier" | "sales_attendant" (optional)
 * - limit: number (for leaderboard, default 10)
 * - order_by: "revenue" | "transactions" | "profit" (for leaderboard)
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
    const type = searchParams.get('type') || 'performance';
    const startDate = searchParams.get('start_date');
    const endDate = searchParams.get('end_date');
    const branchId = searchParams.get('branch_id');
    const staffRole = searchParams.get('staff_role') as 'cashier' | 'sales_attendant' | undefined;
    const limit = parseInt(searchParams.get('limit') || '10');
    const orderBy = (searchParams.get('order_by') || 'revenue') as 'revenue' | 'transactions' | 'profit';

    if (!startDate || !endDate) {
      return NextResponse.json(
        { error: 'start_date and end_date are required' },
        { status: 400 }
      );
    }

    let data;

    switch (type) {
      case 'performance':
        data = await getStaffPerformance(
          tenantId,
          { start: startDate, end: endDate },
          branchId || undefined,
          staffRole
        );
        break;

      case 'leaderboard':
        data = await getStaffLeaderboard(
          tenantId,
          { start: startDate, end: endDate },
          limit,
          branchId || undefined,
          orderBy
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
    console.error('Staff analytics API error:', error);
    return NextResponse.json(
      { error: 'Internal server error', details: (error as Error).message },
      { status: 500 }
    );
  }
}
