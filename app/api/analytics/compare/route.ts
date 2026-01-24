import { NextRequest, NextResponse } from 'next/server';
import {
  comparePeriods,
  compareMonthVsPreviousMonth,
  compareQuarterVsPreviousQuarter,
  compareYearVsPreviousYear,
} from '@/lib/analytics';
import { createClient } from '@/lib/supabase/server';

/**
 * GET /api/analytics/compare
 * Get period comparison analytics
 *
 * Query params:
 * - type: "custom" | "month" | "quarter" | "year"
 * - branch_id: optional UUID
 *
 * For type=custom:
 * - current_start: YYYY-MM-DD
 * - current_end: YYYY-MM-DD
 * - previous_start: YYYY-MM-DD
 * - previous_end: YYYY-MM-DD
 *
 * For type=month:
 * - year: number (e.g., 2024)
 * - month: number (1-12)
 *
 * For type=quarter:
 * - year: number
 * - quarter: number (1-4)
 *
 * For type=year:
 * - year: number
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
    const type = searchParams.get('type') || 'month';
    const branchId = searchParams.get('branch_id');

    let data;

    switch (type) {
      case 'custom': {
        const currentStart = searchParams.get('current_start');
        const currentEnd = searchParams.get('current_end');
        const previousStart = searchParams.get('previous_start');
        const previousEnd = searchParams.get('previous_end');

        if (!currentStart || !currentEnd || !previousStart || !previousEnd) {
          return NextResponse.json(
            { error: 'All date parameters are required for type=custom' },
            { status: 400 }
          );
        }

        data = await comparePeriods(
          tenantId,
          { start: currentStart, end: currentEnd },
          { start: previousStart, end: previousEnd },
          branchId || undefined
        );
        break;
      }

      case 'month': {
        const year = parseInt(searchParams.get('year') || new Date().getFullYear().toString());
        const month = parseInt(searchParams.get('month') || (new Date().getMonth() + 1).toString());

        if (month < 1 || month > 12) {
          return NextResponse.json({ error: 'Invalid month (1-12)' }, { status: 400 });
        }

        data = await compareMonthVsPreviousMonth(tenantId, year, month, branchId || undefined);
        break;
      }

      case 'quarter': {
        const year = parseInt(searchParams.get('year') || new Date().getFullYear().toString());
        const quarter = parseInt(searchParams.get('quarter') || '1') as 1 | 2 | 3 | 4;

        if (quarter < 1 || quarter > 4) {
          return NextResponse.json({ error: 'Invalid quarter (1-4)' }, { status: 400 });
        }

        data = await compareQuarterVsPreviousQuarter(tenantId, year, quarter, branchId || undefined);
        break;
      }

      case 'year': {
        const year = parseInt(searchParams.get('year') || new Date().getFullYear().toString());
        data = await compareYearVsPreviousYear(tenantId, year, branchId || undefined);
        break;
      }

      default:
        return NextResponse.json({ error: 'Invalid type parameter' }, { status: 400 });
    }

    return NextResponse.json({
      success: true,
      data,
    });
  } catch (error) {
    console.error('Compare analytics API error:', error);
    return NextResponse.json(
      { error: 'Internal server error', details: (error as Error).message },
      { status: 500 }
    );
  }
}
