import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@/lib/supabase/server';
import { SubscriptionService, PLANS, PlanLimits } from '@/lib/pos/subscription';
import { SubscriptionPlanTier } from '@/lib/types/database';

export async function GET(req: NextRequest) {
    try {
        const supabase = await createClient();
        const { data: { user }, error } = await supabase.auth.getUser();

        if (error || !user) {
            return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
        }

        const tenantId = user.user_metadata.tenant_id;
        if (!tenantId) {
            return NextResponse.json({ error: 'Tenant ID missing' }, { status: 400 });
        }

        // Get current subscription
        const subscription = await SubscriptionService.getCurrentSubscription(tenantId);

        // Get limits for the current plan
        const planDetails = PLANS[subscription.plan_tier];

        // Get current usage (optional, could be separate call or included)
        // Let's include basic usage check for UI display
        const usage = {
            branches: (await SubscriptionService.checkLimit(tenantId, 'branches')).current,
            staff: (await SubscriptionService.checkLimit(tenantId, 'staff')).current,
            products: (await SubscriptionService.checkLimit(tenantId, 'products')).current
        };

        return NextResponse.json({
            subscription,
            plan: planDetails,
            usage
        });

    } catch (error: any) {
        console.error('Subscription API Error', error);
        return NextResponse.json({ error: error.message || 'Internal Server Error' }, { status: 500 });
    }
}

export async function POST(req: NextRequest) {
    try {
        const supabase = await createClient();
        const { data: { user }, error } = await supabase.auth.getUser();

        if (error || !user) {
            return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
        }

        const body = await req.json();
        const { planTier } = body;
        const tenantId = user.user_metadata.tenant_id;

        if (!tenantId) {
            return NextResponse.json({ error: 'Tenant ID missing' }, { status: 400 });
        }

        if (!['starter', 'growth', 'business', 'enterprise'].includes(planTier)) {
            return NextResponse.json({ error: 'Invalid plan tier' }, { status: 400 });
        }

        // MVP: Immediate update. Real world: Payment gateway link generation first.
        await SubscriptionService.subscribe(tenantId, planTier as SubscriptionPlanTier);

        return NextResponse.json({ success: true, message: `Upgraded to ${planTier}` });

    } catch (error: any) {
        console.error('Subscription Upgrade Error', error);
        return NextResponse.json({ error: error.message || 'Internal Server Error' }, { status: 500 });
    }
}
export async function PUT(req: NextRequest) {
    try {
        const supabase = await createClient();
        const { data: { user }, error } = await supabase.auth.getUser();

        if (error || !user) {
            return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
        }

        const body = await req.json();
        const { action, enabled } = body;
        const tenantId = user.user_metadata.tenant_id;

        if (!tenantId) {
            return NextResponse.json({ error: 'Tenant ID missing' }, { status: 400 });
        }

        if (action === 'toggle_ai_addon') {
            await SubscriptionService.toggleAiAddon(tenantId, enabled);
            return NextResponse.json({ success: true, message: `AI Chat add-on ${enabled ? 'enabled' : 'disabled'}` });
        }

        return NextResponse.json({ error: 'Invalid action' }, { status: 400 });

    } catch (error: any) {
        console.error('Subscription Update Error', error);
        return NextResponse.json({ error: error.message || 'Internal Server Error' }, { status: 500 });
    }
}
