import type { RequestHandler } from './$types';
import { json } from '@sveltejs/kit';
import { BrandingService } from '$lib/auth/branding';
import type { BrandingConfig } from '$lib/types/database';
import { UserService } from '$lib/auth/user';
import { createClient } from '$lib/supabase/client';

// GET - Get tenant branding
export const GET: RequestHandler = async () => {
    try {
        const supabase = createClient();
        const { data: { user } } = await supabase.auth.getUser();

        if (!user) {
            return json(
                { error: 'Unauthorized' },
                { status: 401 }
            );
        }

        const currentUser = await UserService.getUser(user.id);
        if (!currentUser.tenant_id) {
            return json(
                { error: 'User not associated with a tenant' },
                { status: 403 }
            );
        }

        const branding = await BrandingService.getBranding(currentUser.tenant_id);
        return json(branding);
    } catch (error: any) {
        console.error('Get branding error:', error);
        return json(
            { error: error.message || 'Failed to get branding' },
            { status: 500 }
        );
    }
};

// PUT - Update tenant branding
export const PUT: RequestHandler = async ({ request }) => {
    try {
        const supabase = createClient();
        const { data: { user } } = await supabase.auth.getUser();

        if (!user) {
            return json(
                { error: 'Unauthorized' },
                { status: 401 }
            );
        }

        const currentUser = await UserService.getUser(user.id);

        // Only tenant admins can update branding
        if (currentUser.role !== 'tenant_admin' && currentUser.role !== 'platform_admin') {
            return json(
                { error: 'Insufficient permissions' },
                { status: 403 }
            );
        }

        if (!currentUser.tenant_id) {
            return json(
                { error: 'User not associated with a tenant' },
                { status: 403 }
            );
        }

        const branding: BrandingConfig = await request.json();
        const updated = await BrandingService.updateBranding(currentUser.tenant_id, branding);

        return json(updated);
    } catch (error: any) {
        console.error('Update branding error:', error);
        return json(
            { error: error.message || 'Failed to update branding' },
            { status: 500 }
        );
    }
};
