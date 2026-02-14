import { createClient } from '@/lib/supabase/client';

/**
 * Get current tenant ID from user metadata
 */
export async function getCurrentTenantId(): Promise<string | null> {
    const supabase = createClient();

    const { data: { user } } = await supabase.auth.getUser();

    if (!user) return null;

    // Get tenant_id from user's metadata or from users table
    const { data: userData } = await supabase
        .from('users')
        .select('tenant_id')
        .eq('id', user.id)
        .single();

    return userData?.tenant_id || null;
}

/**
 * Get current user's role
 */
export async function getCurrentUserRole(): Promise<string | null> {
    const supabase = createClient();

    const { data: { user } } = await supabase.auth.getUser();

    if (!user) return null;

    const { data: userData } = await supabase
        .from('users')
        .select('role')
        .eq('id', user.id)
        .single();

    return userData?.role || null;
}

/**
 * Get current user's branch ID
 */
export async function getCurrentBranchId(): Promise<string | null> {
    const supabase = createClient();

    const { data: { user } } = await supabase.auth.getUser();

    if (!user) return null;

    const { data: userData } = await supabase
        .from('users')
        .select('branch_id')
        .eq('id', user.id)
        .single();

    return userData?.branch_id || null;
}

/**
 * Check if user has specific role
 */
export async function hasRole(role: string): Promise<boolean> {
    const userRole = await getCurrentUserRole();
    return userRole === role;
}

/**
 * Check if user is platform admin
 */
export async function isPlatformAdmin(): Promise<boolean> {
    return hasRole('platform_admin');
}

/**
 * Check if user is tenant admin
 */
export async function isTenantAdmin(): Promise<boolean> {
    return hasRole('tenant_admin');
}

/**
 * Get tenant details
 */
export async function getTenantDetails(tenantId: string) {
    const supabase = createClient();

    const { data, error } = await supabase
        .from('tenants')
        .select('*')
        .eq('id', tenantId)
        .single();

    if (error) {
        console.error('Error fetching tenant:', error);
        return null;
    }

    return data;
}

/**
 * Get user's full profile
 */
export async function getUserProfile() {
    const supabase = createClient();

    const { data: { user } } = await supabase.auth.getUser();

    if (!user) return null;

    const { data: profile } = await supabase
        .from('users')
        .select(`
      *,
      tenant:tenants(*),
      branch:branches(*)
    `)
        .eq('id', user.id)
        .single();

    return profile;
}
