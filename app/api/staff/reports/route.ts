import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@/lib/supabase/server';
import { StaffReportingService } from '@/lib/pos/reports';

export async function GET(req: NextRequest) {
    try {
        const supabase = await createClient();

        // 1. Auth Check (Admin Only?)
        // Regular staff can presumably see their own reports, but aggregate reports should be role-gated.
        const { data: { user } } = await supabase.auth.getUser();
        if (!user) {
            return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
        }

        const { data: userProfile } = await supabase
            .from('users')
            .select('tenant_id, role')
            .eq('id', user.id)
            .single();

        if (!userProfile?.tenant_id) {
            return NextResponse.json({ error: 'Tenant context missing' }, { status: 400 });
        }

        // Permission check for reporting
        // if (userProfile.role !== 'owner' && userProfile.role !== 'manager') {
        //    return NextResponse.json({ error: 'Forbidden' }, { status: 403 });
        // }

        // 2. Parse Params
        const searchParams = req.nextUrl.searchParams;
        const type = searchParams.get('type') || 'attendance'; // 'attendance' or 'attribution'
        const dateFrom = searchParams.get('from') || new Date(new Date().setDate(new Date().getDate() - 30)).toISOString();
        const dateTo = searchParams.get('to') || new Date().toISOString();

        let data;

        if (type === 'attribution') {
            data = await StaffReportingService.getSalesAttribution(userProfile.tenant_id, dateFrom, dateTo);
        } else {
            // Default to attendance summary
            data = await StaffReportingService.getStaffHoursSummary(userProfile.tenant_id, dateFrom, dateTo);
        }

        return NextResponse.json(data);
    } catch (error) {
        console.error('Reporting API error:', error);
        return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 });
    }
}
