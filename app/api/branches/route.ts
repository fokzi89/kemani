import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@/lib/supabase/server';
import { BranchService } from '@/lib/pos/branch';
import { BranchInsert } from '@/lib/types/database';

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

        // 3. Fetch Branches
        const branches = await BranchService.getBranches(userProfile.tenant_id);

        return NextResponse.json(branches);
    } catch (error) {
        console.error('Error fetching branches:', error);
        return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 });
    }
}

export async function POST(req: NextRequest) {
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

        const body = await req.json();

        // 3. Create Branch
        const newBranch: BranchInsert = {
            ...body,
            tenant_id: userProfile.tenant_id,
            // Ensure defaults if not provided but required? 
            // business_type is required enum, name is required.
        };

        const created = await BranchService.createBranch(newBranch);

        return NextResponse.json(created);

    } catch (error: any) {
        console.error('Error creating branch:', error);
        return NextResponse.json({ error: error.message || 'Internal Server Error' }, { status: 500 });
    }
}
