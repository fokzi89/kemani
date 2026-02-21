import { SUPABASE_SERVICE_ROLE_KEY } from '$env/static/private';
import { PUBLIC_SUPABASE_URL } from '$env/static/public';
import { createClient } from '@supabase/supabase-js';
import { isFeatureEnabled } from '$lib/storefront/plans';
import type { Database } from '$lib/types/supabase';

// Create a service role client for administrative tasks (like checking plans and sending notifications)
const adminSupabase = createClient<Database>(
    PUBLIC_SUPABASE_URL,
    SUPABASE_SERVICE_ROLE_KEY
);

export type NotificationType = 'sms' | 'whatsapp' | 'email';

export interface NotificationResult {
    success: boolean;
    error?: string;
    skipped?: boolean;
}

/**
 * Send a notification to a customer, respecting plan limits.
 */
export async function sendNotification(
    tenantId: string,
    type: NotificationType,
    recipient: string,
    message: string,
    metadata?: any
): Promise<NotificationResult> {
    // 1. Get Tenant Plan from database (using admin privileges)
    // We assume 'tenants' table has 'plan_tier' column as per schema conventions
    const { data: tenant, error } = await adminSupabase
        .from('tenants' as any) // Type might be missing in partial generation
        .select('plan_tier')
        .eq('id', tenantId)
        .single();

    if (error || !tenant) {
        console.error('Notification Service: Failed to fetch tenant plan', error);
        return { success: false, error: 'Tenant lookup failed' };
    }

    const planTier = tenant.plan_tier;

    // 2. Check Feature Access
    let allowed = true;
    if (type === 'sms') {
        allowed = isFeatureEnabled(planTier, 'smsNotifications');
    } else if (type === 'whatsapp') {
        allowed = isFeatureEnabled(planTier, 'whatsappNotifications');
    }
    // Email usually allowed or distinct feature

    if (!allowed) {
        console.warn(`Notification Service: Blocked ${type} for tenant ${tenantId} (Plan: ${planTier})`);
        return { success: false, skipped: true, error: 'Plan restriction' };
    }

    // 3. Send Notification (Stub for now)
    // In a real implementation, we would call Twilio, Meta API, or a queue here.
    console.info(`[Notification Service] Sending ${type} to ${recipient}: "${message}"`);

    // TODO: Implement actual provider integration
    // await smsProvider.send(...)

    return { success: true };
}
