import { NextRequest, NextResponse } from 'next/server';
import { createAdminClient, createClient } from '@/lib/supabase/server';

export async function POST(request: NextRequest) {
    try {
        const body = await request.json();
        const { businessName, fullName, address, subscriptionPlan, userId } = body;

        if (!businessName || !fullName || !address || !userId) {
            return NextResponse.json(
                { error: 'Missing required fields' },
                { status: 400 }
            );
        }

        // We use admin client to bypass RLS for creating tenant/branch/user
        const supabaseAdmin = await createAdminClient();

        // Verifying the user calling this is actually authenticated
        const supabase = await createClient();
        const { data: { user: authUser }, error: authError } = await supabase.auth.getUser();

        if (authError || !authUser || authUser.id !== userId) {
            return NextResponse.json(
                { error: 'Unauthorized' },
                { status: 401 }
            );
        }

        // 1. Create Tenant
        // For slug, we'll use a simple transformation of businessName for now
        // Ideally we should check for uniqueness but let's assume low collision or let DB error
        const slug = businessName.toLowerCase().replace(/[^a-z0-9]/g, '-') + '-' + Math.floor(Math.random() * 1000);

        const { data: tenant, error: tenantError } = await supabaseAdmin
            .from('tenants')
            .insert({
                name: businessName,
                slug: slug,
                subscription_id: subscriptionPlan,
                // status: 'active', // 'status' might not be in tenants table based on migration 002 check?
                // Migration 002 does NOT show 'status' column for tenants. 
                // Wait, let me check strict migration 002 provided earlier...
                // Table tenants: name, slug, email, phone, logo_url, brand_color, subscription_id ... deleted_at. NO status column.
                // Subscriptions has 'status'. Tenants does NOT.
            })
            .select()
            .single();

        if (tenantError) {
            console.error('Tenant creation error:', tenantError);
            return NextResponse.json({ error: 'Failed to create tenant' }, { status: 500 });
        }

        // 2. Create Main Branch
        const { data: branch, error: branchError } = await supabaseAdmin
            .from('branches')
            .insert({
                tenant_id: tenant.id,
                name: 'Main Branch',
                address: address,
                is_main: true,
            })
            .select()
            .single();

        if (branchError) {
            console.error('Branch creation error:', branchError);
            // Cleanup tenant if branch fails? logic could be improved with transactions if Supabase supported them easily via JS SDK
            return NextResponse.json({ error: 'Failed to create branch' }, { status: 500 });
        }

        // 3. Create User Profile
        const { error: userError } = await supabaseAdmin
            .from('users')
            .insert({
                id: userId,
                tenant_id: tenant.id,
                branch_id: branch.id,
                full_name: fullName,
                email: authUser.email,
                role: 'tenant_admin',
                status: 'active',
            });

        if (userError) {
            console.error('User profile creation error:', userError);
            return NextResponse.json({ error: 'Failed to create user profile' }, { status: 500 });
        }

        return NextResponse.json({ success: true, tenantId: tenant.id });

    } catch (error: any) {
        console.error('Registration error:', error);
        return NextResponse.json(
            { error: error.message || 'Internal server error' },
            { status: 500 }
        );
    }
}
