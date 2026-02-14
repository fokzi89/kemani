import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@/lib/supabase/server';
import { ConsolidatedAnalyticsService } from '@/lib/pos/analytics';

export async function GET(req: NextRequest) {
    try {
        const supabase = await createClient();

        // 1. Verify Auth
        const { data: { user } } = await supabase.auth.getUser();
        if (!user) {
            return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
        }

        // 2. Get Tenant
        const { data: userProfile } = await supabase
            .from('users')
            .select('tenant_id')
            .eq('id', user.id)
            .single();

        if (!userProfile?.tenant_id) {
            return NextResponse.json({ error: 'Tenant context missing' }, { status: 400 });
        }

        const searchParams = req.nextUrl.searchParams;
        const from = searchParams.get('from') || new Date(new Date().setDate(new Date().getDate() - 30)).toISOString(); // Default 30 days
        const to = searchParams.get('to') || new Date().toISOString();

        const metrics = await ConsolidatedAnalyticsService.getConsolidatedMetrics(userProfile.tenant_id, from, to);

        return NextResponse.json(metrics);

    } catch (error) {
        console.error('Error fetching consolidated analytics:', error);
        return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 });
    }
}
