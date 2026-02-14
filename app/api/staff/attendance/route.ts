import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@/lib/supabase/server';
import { StaffAttendanceService } from '@/lib/pos/attendance';

export async function POST(req: NextRequest) {
    try {
        const supabase = await createClient();

        // 1. Verify Auth & Role
        const { data: { user } } = await supabase.auth.getUser();
        if (!user) {
            return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
        }

        // Get Tenant context (usually from header or session)
        // Assuming linked to user metadata or we fetch from DB.
        // For MVP, we'll fetch user's tenant_id from DB.
        const { data: userProfile } = await supabase
            .from('users')
            .select('tenant_id, branch_id')
            .eq('id', user.id)
            .single();

        if (!userProfile?.tenant_id) {
            return NextResponse.json({ error: 'Tenant context missing' }, { status: 400 });
        }

        // 2. Perform Clock In
        // Body could contain specific userId if admin is clocking in for someone else,
        // but default to self.
        const body = await req.json().catch(() => ({}));
        const targetUserId = body.userId || user.id;

        const branchId = userProfile.branch_id;

        // Only allow clocking in others if admin? (Future Scope)

        const result = await StaffAttendanceService.clockIn(userProfile.tenant_id, targetUserId, branchId || undefined);

        return NextResponse.json(result);
    } catch (error: any) {
        if (error.message === 'User is already clocked in.') {
            return NextResponse.json({ error: error.message }, { status: 409 });
        }
        console.error('Clock-in error:', error);
        return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 });
    }
}

export async function PUT(req: NextRequest) {
    try {
        const supabase = await createClient();

        const { data: { user } } = await supabase.auth.getUser();
        if (!user) {
            return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
        }

        const { data: userProfile } = await supabase
            .from('users')
            .select('tenant_id')
            .eq('id', user.id)
            .single();

        if (!userProfile?.tenant_id) {
            return NextResponse.json({ error: 'Tenant context missing' }, { status: 400 });
        }

        const body = await req.json().catch(() => ({}));
        const targetUserId = body.userId || user.id;

        const result = await StaffAttendanceService.clockOut(userProfile.tenant_id, targetUserId);

        return NextResponse.json(result);
    } catch (error: any) {
        if (error.message.includes('No open clock-in')) {
            return NextResponse.json({ error: error.message }, { status: 404 });
        }
        console.error('Clock-out error:', error);
        return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 });
    }
}

export async function GET(req: NextRequest) {
    // Check current status
    try {
        const supabase = await createClient();
        const { data: { user } } = await supabase.auth.getUser();
        if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

        const searchParams = req.nextUrl.searchParams;
        const targetUserId = searchParams.get('userId') || user.id;

        const { data: userProfile } = await supabase
            .from('users')
            .select('tenant_id')
            .eq('id', user.id)
            .single();

        if (!userProfile?.tenant_id) {
            return NextResponse.json({ error: 'Tenant context missing' }, { status: 400 });
        }

        const status = await StaffAttendanceService.getStatus(userProfile.tenant_id, targetUserId);
        return NextResponse.json(status);

    } catch (error) {
        return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 });
    }
}
