import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@/lib/supabase/server';
import { AnalyticsService } from '@/lib/pos/analytics';

export async function GET(req: NextRequest) {
  try {
    const supabase = await createClient();
    const { data: { user }, error: authError } = await supabase.auth.getUser();

    if (authError || !user) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const { searchParams } = new URL(req.url);
    const tenantId = user.user_metadata.tenant_id;
    const branchId = user.user_metadata.branch_id; // Optional: filter by branch if needed
    const period = (searchParams.get('period') as 'day' | 'week' | 'month') || 'day';

    if (!tenantId) {
      return NextResponse.json({ error: 'Tenant ID missing' }, { status: 400 });
    }

    // For Super Admins or Multi-Branch Managers, they might want to see all branches.
    // For now, let's default to user's assigned branch or tenant-wide if authorized.
    // Assuming tenant dashboard for owner sees all.
    // We'll pass branchId if present (Store Manager), or undefined (Tenant Owner).
    // Check Role? (Assuming role check logic is in middleware or client, simple here)

    const metrics = await AnalyticsService.getDashboardMetrics(tenantId, branchId, period);

    return NextResponse.json({ metrics });

  } catch (error: any) {
    console.error('Analytics API Error', error);
    return NextResponse.json({ error: error.message || 'Internal Server Error' }, { status: 500 });
  }
}
