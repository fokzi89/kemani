import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@/lib/supabase/server';
import { AnalyticsService } from '@/lib/pos/analytics';

export async function GET(req: NextRequest) {
    try {
        const supabase = await createClient();
        const { data: { user }, error } = await supabase.auth.getUser();

        if (error || !user) {
            return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
        }

        const { searchParams } = new URL(req.url);
        const tenantId = user.user_metadata.tenant_id;
        const branchId = user.user_metadata.branch_id;
        const days = parseInt(searchParams.get('days') || '7');

        if (!tenantId) {
            return NextResponse.json({ error: 'Tenant ID missing' }, { status: 400 });
        }

        const trends = await AnalyticsService.getSalesTrends(tenantId, branchId, days);

        return NextResponse.json({ trends });

    } catch (error: any) {
        console.error('Analytics Trends API Error', error);
        return NextResponse.json({ error: error.message || 'Internal Server Error' }, { status: 500 });
    }
}
