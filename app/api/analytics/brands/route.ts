import { NextRequest, NextResponse } from 'next/server';
import { compareBrands, compareProductAcrossBrands } from '@/lib/analytics';
import { createClient } from '@/lib/supabase/server';

/**
 * GET /api/analytics/brands
 * Get brand comparison analytics
 *
 * Query params:
 * - type: "compare" | "product-comparison"
 * - start_date: YYYY-MM-DD
 * - end_date: YYYY-MM-DD
 * - brand_ids: comma-separated UUIDs (optional)
 * - category_id: UUID (required for type=product-comparison)
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
    const type = searchParams.get('type') || 'compare';
    const startDate = searchParams.get('start_date');
    const endDate = searchParams.get('end_date');
    const brandIdsParam = searchParams.get('brand_ids');
    const categoryId = searchParams.get('category_id');
    const branchId = searchParams.get('branch_id');

    if (!startDate || !endDate) {
      return NextResponse.json(
        { error: 'start_date and end_date are required' },
        { status: 400 }
      );
    }

    const brandIds = brandIdsParam ? brandIdsParam.split(',') : undefined;

    let data;

    switch (type) {
      case 'compare':
        data = await compareBrands(
          tenantId,
          { start: startDate, end: endDate },
          brandIds,
          branchId || undefined
        );
        break;

      case 'product-comparison':
        if (!categoryId) {
          return NextResponse.json(
            { error: 'category_id is required for type=product-comparison' },
            { status: 400 }
          );
        }
        data = await compareProductAcrossBrands(
          tenantId,
          categoryId,
          { start: startDate, end: endDate },
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
    console.error('Brands analytics API error:', error);
    return NextResponse.json(
      { error: 'Internal server error', details: (error as Error).message },
      { status: 500 }
    );
  }
}
