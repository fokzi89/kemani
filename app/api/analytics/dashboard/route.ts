import { NextRequest, NextResponse } from 'next/server';
import { getDashboardSummary } from '@/lib/analytics';
import { createClient } from '@/lib/supabase/server';

/**
 * GET /api/analytics/dashboard
 * Get dashboard summary metrics
 *
 * Query params:
 * - start_date: YYYY-MM-DD
 * - end_date: YYYY-MM-DD
 * - branch_id: optional UUID
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
    const startDate = searchParams.get('start_date');
    const endDate = searchParams.get('end_date');
    const branchId = searchParams.get('branch_id');

    if (!startDate || !endDate) {
      return NextResponse.json(
        { error: 'start_date and end_date are required' },
        { status: 400 }
      );
    }

    // Get dashboard summary
    const summary = await getDashboardSummary(
      tenantId,
      { start: startDate, end: endDate },
      branchId || undefined
    );

    return NextResponse.json({
      success: true,
      data: summary,
    });
  } catch (error) {
    console.error('Dashboard API error:', error);
    return NextResponse.json(
      { error: 'Internal server error', details: (error as Error).message },
      { status: 500 }
    );
  }
}
