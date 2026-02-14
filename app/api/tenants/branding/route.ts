import { NextRequest, NextResponse } from 'next/server';
import { BrandingService } from '@/lib/auth/branding';
import { BrandingConfig } from '@/lib/types/database';
import { UserService } from '@/lib/auth/user';
import { createClient } from '@/lib/supabase/client';

// GET - Get tenant branding
export async function GET(request: NextRequest) {
    try {
        const supabase = createClient();
        const { data: { user } } = await supabase.auth.getUser();

        if (!user) {
            return NextResponse.json(
                { error: 'Unauthorized' },
                { status: 401 }
            );
        }

        const currentUser = await UserService.getUser(user.id);
        if (!currentUser.tenant_id) {
            return NextResponse.json(
                { error: 'User not associated with a tenant' },
                { status: 403 }
            );
        }

        const branding = await BrandingService.getBranding(currentUser.tenant_id);
        return NextResponse.json(branding);
    } catch (error: any) {
        console.error('Get branding error:', error);
        return NextResponse.json(
            { error: error.message || 'Failed to get branding' },
            { status: 500 }
        );
    }
}

// PUT - Update tenant branding
export async function PUT(request: NextRequest) {
    try {
        const supabase = createClient();
        const { data: { user } } = await supabase.auth.getUser();

        if (!user) {
            return NextResponse.json(
                { error: 'Unauthorized' },
                { status: 401 }
            );
        }

        const currentUser = await UserService.getUser(user.id);

        // Only tenant admins can update branding
        if (currentUser.role !== 'tenant_admin' && currentUser.role !== 'platform_admin') {
            return NextResponse.json(
                { error: 'Insufficient permissions' },
                { status: 403 }
            );
        }

        if (!currentUser.tenant_id) {
            return NextResponse.json(
                { error: 'User not associated with a tenant' },
                { status: 403 }
            );
        }

        const branding: BrandingConfig = await request.json();
        const updated = await BrandingService.updateBranding(currentUser.tenant_id, branding);

        return NextResponse.json(updated);
    } catch (error: any) {
        console.error('Update branding error:', error);
        return NextResponse.json(
            { error: error.message || 'Failed to update branding' },
            { status: 500 }
        );
    }
}
