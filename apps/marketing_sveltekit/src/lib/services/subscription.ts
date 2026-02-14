import { supabase } from './supabase';
import type { Subscription, SubscriptionPlanTier } from '../types';

export interface PlanLimits {
    maxBranches: number;
    maxStaff: number;
    maxProducts: number;
    name: string;
    price: number;
    transactionFee: number;
    features: {
        canUseAi: boolean;
        canUseCustomDomain: boolean;
        canUseWhatsapp: boolean;
        canUseApi: boolean;
        hasInChatPurchase: boolean;
    };
}

export const PLANS: Record<SubscriptionPlanTier, PlanLimits> = {
    starter: {
        name: 'Starter',
        price: 0,
        transactionFee: 50,
        maxBranches: 1,
        maxStaff: 1, // Owner only
        maxProducts: 100,
        features: {
            canUseAi: false,
            canUseCustomDomain: false,
            canUseWhatsapp: false,
            canUseApi: false,
            hasInChatPurchase: true
        }
    },
    growth: {
        name: 'Growth',
        price: 750000, // ₦7,500
        transactionFee: 50,
        maxBranches: 1,
        maxStaff: 3,
        maxProducts: 999999, // Unlimited
        features: {
            canUseAi: false,
            canUseCustomDomain: true,
            canUseWhatsapp: true,
            canUseApi: false,
            hasInChatPurchase: true
        }
    },
    business: {
        name: 'Business',
        price: 3000000, // ₦30,000
        transactionFee: 50,
        maxBranches: 9999,
        maxStaff: 9999,
        maxProducts: 999999,
        features: {
            canUseAi: true,
            canUseCustomDomain: true,
            canUseWhatsapp: true,
            canUseApi: true,
            hasInChatPurchase: true
        }
    },
    enterprise: {
        name: 'Enterprise',
        price: 0, // Contact Sales
        transactionFee: 50,
        maxBranches: 9999,
        maxStaff: 9999,
        maxProducts: 999999,
        features: {
            canUseAi: true,
            canUseCustomDomain: true,
            canUseWhatsapp: true,
            canUseApi: true,
            hasInChatPurchase: true
        }
    }
};

export class SubscriptionService {

    /**
     * Get tenant's current subscription. Defaults to STARTER if none found.
     */
    static async getCurrentSubscription(tenantId: string): Promise<Subscription> {
        const { data } = await supabase
            .from('subscriptions')
            .select('*')
            .eq('tenant_id', tenantId)
            .eq('status', 'active')
            .single();

        if (!data) {
            // Return a virtual starter plan if no specific record exists (common for MVP)
            return {
                id: 'virtual-starter',
                tenant_id: tenantId,
                plan_tier: 'starter',
                status: 'active',
                billing_period: 'monthly',
                current_period_start: new Date().toISOString(),
                current_period_end: new Date(new Date().setFullYear(new Date().getFullYear() + 10)).toISOString(),
                cancel_at_period_end: false,
                created_at: new Date().toISOString(),
                updated_at: new Date().toISOString()
            } as Subscription; // Cast for now until precise type match
        }

        return data as Subscription;
    }

    /**
     * Check if a tenant can create more of a resource
     */
    static async checkLimit(tenantId: string, resource: 'branches' | 'staff' | 'products'): Promise<{ allowed: boolean; limit: number; current: number }> {
        const sub = await this.getCurrentSubscription(tenantId);
        const plan = PLANS[sub.plan_tier];

        let count = 0;

        if (resource === 'branches') {
            const { count: c } = await supabase.from('branches').select('*', { count: 'exact', head: true }).eq('tenant_id', tenantId);
            count = c || 0;
            return { allowed: count < plan.maxBranches, limit: plan.maxBranches, current: count };
        }

        if (resource === 'staff') {
            const { count: c } = await supabase.from('users').select('*', { count: 'exact', head: true }).eq('tenant_id', tenantId);
            count = c || 0;
            return { allowed: count < plan.maxStaff, limit: plan.maxStaff, current: count };
        }

        if (resource === 'products') {
            const { count: c } = await supabase.from('products').select('*', { count: 'exact', head: true }).eq('tenant_id', tenantId);
            count = c || 0;
            return { allowed: count < plan.maxProducts, limit: plan.maxProducts, current: count };
        }

        return { allowed: true, limit: 9999, current: 0 };
    }

    /**
     * Check if a tenant has access to a specific feature
     */
    static async checkFeatureAccess(tenantId: string, feature: keyof PlanLimits['features']): Promise<boolean> {
        const sub = await this.getCurrentSubscription(tenantId);
        const plan = PLANS[sub.plan_tier];
        return plan.features[feature];
    }

    /**
     * Simulate subscribing to a plan (MVP: Update DB directly)
     */
    static async subscribe(tenantId: string, planTier: SubscriptionPlanTier, billingPeriod: 'monthly' | 'yearly' = 'monthly') {
        const existing = await this.getCurrentSubscription(tenantId);

        if (existing.id !== 'virtual-starter') {
            // Update existing
            const { error } = await supabase
                .from('subscriptions')
                .update({
                    plan_tier: planTier,
                    billing_period: billingPeriod,
                    updated_at: new Date().toISOString()
                })
                .eq('id', existing.id);
            if (error) throw error;
        } else {
            // Insert new
            const { error } = await supabase
                .from('subscriptions')
                .insert({
                    tenant_id: tenantId,
                    plan_tier: planTier,
                    status: 'active',
                    billing_period: billingPeriod,
                    current_period_start: new Date().toISOString(),
                    current_period_end: new Date(new Date().setMonth(new Date().getMonth() + 1)).toISOString(),
                    cancel_at_period_end: false
                });
            if (error) throw error;
        }
    }
}
