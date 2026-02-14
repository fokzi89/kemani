import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@/lib/supabase/server';
import { BranchService } from '@/lib/pos/branch';

export async function GET(
    req: NextRequest,
    { params }: { params: Promise<{ branchId: string }> } // Params is a Promise in Next.js 15
) {
    try {
        const { branchId } = await params;
        const supabase = await createClient();

        const { data: { user } } = await supabase.auth.getUser();
        if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

        const branch = await BranchService.getBranch(branchId);

        if (!branch) {
            return NextResponse.json({ error: 'Branch not found' }, { status: 404 });
        }

        // Check if user belongs to tenant (security check)
        const { data: userProfile } = await supabase.from('users').select('tenant_id').eq('id', user.id).single();
        if (branch.tenant_id !== userProfile?.tenant_id) {
            return NextResponse.json({ error: 'Unauthorized Access' }, { status: 403 });
        }

        return NextResponse.json(branch);
    } catch (error) {
        return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 });
    }
}

export async function PUT(
    req: NextRequest,
    { params }: { params: Promise<{ branchId: string }> }
) {
    try {
        const { branchId } = await params;
        const supabase = await createClient();

        const { data: { user } } = await supabase.auth.getUser();
        if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

        const body = await req.json();

        // Security check: ensure branch belongs to user's tenant
        const existing = await BranchService.getBranch(branchId);
        if (!existing) return NextResponse.json({ error: 'Branch not found' }, { status: 404 });

        const { data: userProfile } = await supabase.from('users').select('tenant_id').eq('id', user.id).single();
        if (existing.tenant_id !== userProfile?.tenant_id) {
            return NextResponse.json({ error: 'Unauthorized Access' }, { status: 403 });
        }

        const updated = await BranchService.updateBranch(branchId, body);
        return NextResponse.json(updated);

    } catch (error) {
        console.error("Error updating branch", error);
        return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 });
    }
}

export async function DELETE(
    req: NextRequest,
    { params }: { params: Promise<{ branchId: string }> }
) {
    try {
        const { branchId } = await params;
        const supabase = await createClient();

        const { data: { user } } = await supabase.auth.getUser();
        if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

        // Security check
        const existing = await BranchService.getBranch(branchId);
        if (!existing) return NextResponse.json({ error: 'Branch not found' }, { status: 404 });

        const { data: userProfile } = await supabase.from('users').select('tenant_id').eq('id', user.id).single();
        if (existing.tenant_id !== userProfile?.tenant_id) {
            return NextResponse.json({ error: 'Unauthorized Access' }, { status: 403 });
        }

        await BranchService.deleteBranch(branchId);
        return NextResponse.json({ success: true });

    } catch (error) {
        console.error("Error deleting branch", error);
        return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 });
    }
}
