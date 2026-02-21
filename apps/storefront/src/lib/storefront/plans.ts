import type { Database } from '$lib/types/supabase.js';

// Plan tier type from database
export type PlanTier = Database['public']['Enums']['plan_tier'];

// Legacy enum for backward compatibility
export enum PlanType {
    FREE = 'free',
    BASIC = 'basic', 
    PRO = 'pro',
    ENTERPRISE = 'enterprise',
    ENTERPRISE_CUSTOM = 'enterprise_custom'
}

export type PlanFeatures = {
    // Product limits
    maxProducts: number;
    maxStaff: number;
    maxBranches: number;
    
    // Chat features
    aiChatStandard: boolean;
    aiChatAgent: boolean; // Business/Pro+ only
    chatFileUploads: boolean;
    
    // Analytics
    analytics: 'basic' | 'advanced' | 'premium';
    
    // Multi-branch features
    multiBranch: boolean; // Pro+ only
    branchSwitching: boolean;
    
    // Delivery & Integration
    deliveryIntegration: boolean;
    whatsappIntegration: boolean;
    
    // Notifications
    smsNotifications: boolean;
    whatsappNotifications: boolean;
    
    // Ecommerce features
    ecommerceStorefront: boolean;
    customBranding: boolean;
    
    // Support
    prioritySupport: boolean;
};

const PLAN_LIMITS: Record<PlanTier, PlanFeatures> = {
    free: {
        maxProducts: 100,
        maxStaff: 1, // Owner only
        maxBranches: 1,
        aiChatStandard: false,
        aiChatAgent: false,
        chatFileUploads: false,
        analytics: 'basic',
        multiBranch: false,
        branchSwitching: false,
        deliveryIntegration: false,
        whatsappIntegration: false,
        smsNotifications: false,
        whatsappNotifications: false,
        ecommerceStorefront: true, // Available on all plans
        customBranding: false,
        prioritySupport: false,
    },
    basic: {
        maxProducts: 1000,
        maxStaff: 3,
        maxBranches: 1,
        aiChatStandard: true, // Rich media support
        aiChatAgent: false,
        chatFileUploads: true,
        analytics: 'advanced',
        multiBranch: false,
        branchSwitching: false,
        deliveryIntegration: true,
        whatsappIntegration: true,
        smsNotifications: true,
        whatsappNotifications: false, // Pro+ feature
        ecommerceStorefront: true,
        customBranding: true,
        prioritySupport: false,
    },
    pro: {
        maxProducts: 10000,
        maxStaff: 10,
        maxBranches: 5, // Multi-branch support
        aiChatStandard: true,
        aiChatAgent: true, // AI agent available
        chatFileUploads: true,
        analytics: 'premium',
        multiBranch: true, // Key differentiator
        branchSwitching: true,
        deliveryIntegration: true,
        whatsappIntegration: true,
        smsNotifications: true,
        whatsappNotifications: true,
        ecommerceStorefront: true,
        customBranding: true,
        prioritySupport: true,
    },
    enterprise: {
        maxProducts: Infinity,
        maxStaff: Infinity,
        maxBranches: Infinity,
        aiChatStandard: true,
        aiChatAgent: true,
        chatFileUploads: true,
        analytics: 'premium',
        multiBranch: true,
        branchSwitching: true,
        deliveryIntegration: true,
        whatsappIntegration: true,
        smsNotifications: true,
        whatsappNotifications: true,
        ecommerceStorefront: true,
        customBranding: true,
        prioritySupport: true,
    },
    enterprise_custom: {
        maxProducts: Infinity,
        maxStaff: Infinity,
        maxBranches: Infinity,
        aiChatStandard: true,
        aiChatAgent: true,
        chatFileUploads: true,
        analytics: 'premium',
        multiBranch: true,
        branchSwitching: true,
        deliveryIntegration: true,
        whatsappIntegration: true,
        smsNotifications: true,
        whatsappNotifications: true,
        ecommerceStorefront: true,
        customBranding: true,
        prioritySupport: true,
    },
};

/**
 * Get feature limits for a given plan
 */
export function getPlanLimits(plan: PlanTier | string): PlanFeatures {
    const p = plan as PlanTier;
    return PLAN_LIMITS[p] || PLAN_LIMITS.free;
}

/**
 * Check if a feature is enabled for the current plan
 */
export function isFeatureEnabled(plan: PlanTier | string, feature: keyof PlanFeatures): boolean {
    const limits = getPlanLimits(plan);
    const value = limits[feature];
    if (typeof value === 'boolean') return value;
    if (typeof value === 'number') return value > 0;
    return !!value;
}

/**
 * Check if limit is reached (e.g. currentProducts >= maxProducts)
 */
export function isLimitReached(
    plan: PlanTier | string,
    metric: 'maxProducts' | 'maxStaff' | 'maxBranches',
    currentValue: number
): boolean {
    const limits = getPlanLimits(plan);
    const limit = limits[metric];
    if (limit === Infinity) return false;
    return currentValue >= limit;
}

/**
 * Get remaining capacity for a metric
 */
export function getRemainingCapacity(
    plan: PlanTier | string,
    metric: 'maxProducts' | 'maxStaff' | 'maxBranches',
    currentValue: number
): number | 'unlimited' {
    const limits = getPlanLimits(plan);
    const limit = limits[metric];
    if (limit === Infinity) return 'unlimited';
    return Math.max(0, limit - currentValue);
}

/**
 * Check if user can add more items of a specific type
 */
export function canAddMore(
    plan: PlanTier | string,
    metric: 'maxProducts' | 'maxStaff' | 'maxBranches',
    currentValue: number,
    countToAdd: number = 1
): boolean {
    const limits = getPlanLimits(plan);
    const limit = limits[metric];
    if (limit === Infinity) return true;
    return (currentValue + countToAdd) <= limit;
}

/**
 * Get plan upgrade suggestions based on current usage
 */
export function getPlanUpgradeSuggestions(
    currentPlan: PlanTier | string,
    usage: {
        products: number;
        staff: number;
        branches: number;
    }
): {
    needsUpgrade: boolean;
    reasons: string[];
    suggestedPlan?: PlanTier;
} {
    const limits = getPlanLimits(currentPlan);
    const reasons: string[] = [];
    let needsUpgrade = false;
    let suggestedPlan: PlanTier | undefined;

    // Check limits
    if (usage.products >= limits.maxProducts && limits.maxProducts !== Infinity) {
        reasons.push(`Product limit reached (${limits.maxProducts})`);
        needsUpgrade = true;
    }
    
    if (usage.staff >= limits.maxStaff && limits.maxStaff !== Infinity) {
        reasons.push(`Staff limit reached (${limits.maxStaff})`);
        needsUpgrade = true;
    }
    
    if (usage.branches >= limits.maxBranches && limits.maxBranches !== Infinity) {
        reasons.push(`Branch limit reached (${limits.maxBranches})`);
        needsUpgrade = true;
    }

    // Suggest appropriate plan
    if (needsUpgrade) {
        if (currentPlan === 'free') {
            suggestedPlan = 'basic';
        } else if (currentPlan === 'basic') {
            suggestedPlan = usage.branches > 1 ? 'pro' : 'basic';
        } else if (currentPlan === 'pro') {
            suggestedPlan = 'enterprise';
        }
    }

    return {
        needsUpgrade,
        reasons,
        suggestedPlan
    };
}

/**
 * Plan enforcement utilities
 */
export class PlanEnforcement {
    constructor(private plan: PlanTier | string) {}

    /**
     * Enforce product count limit (T010a)
     */
    enforceProductLimit(currentCount: number): {
        allowed: boolean;
        limit: number;
        remaining: number | 'unlimited';
        message?: string;
    } {
        const limits = getPlanLimits(this.plan);
        const limit = limits.maxProducts;
        
        if (limit === Infinity) {
            return {
                allowed: true,
                limit: Infinity,
                remaining: 'unlimited'
            };
        }

        const allowed = currentCount < limit;
        const remaining = Math.max(0, limit - currentCount);

        return {
            allowed,
            limit,
            remaining,
            message: allowed 
                ? undefined 
                : `Product limit reached. Upgrade to add more products. Current: ${currentCount}/${limit}`
        };
    }

    /**
     * Enforce staff count limit (T010b)
     */
    enforceStaffLimit(currentCount: number): {
        allowed: boolean;
        limit: number;
        remaining: number | 'unlimited';
        message?: string;
    } {
        const limits = getPlanLimits(this.plan);
        const limit = limits.maxStaff;
        
        if (limit === Infinity) {
            return {
                allowed: true,
                limit: Infinity,
                remaining: 'unlimited'
            };
        }

        const allowed = currentCount < limit;
        const remaining = Math.max(0, limit - currentCount);

        return {
            allowed,
            limit,
            remaining,
            message: allowed 
                ? undefined 
                : `Staff limit reached. Upgrade to add more staff members. Current: ${currentCount}/${limit}`
        };
    }

    /**
     * Check if feature is available
     */
    checkFeature(feature: keyof PlanFeatures): {
        available: boolean;
        message?: string;
    } {
        const available = isFeatureEnabled(this.plan, feature);
        
        return {
            available,
            message: available 
                ? undefined 
                : `This feature is not available on your current plan. Please upgrade to access ${feature}.`
        };
    }
}

/**
 * Create plan enforcement instance
 */
export function createPlanEnforcement(plan: PlanTier | string): PlanEnforcement {
    return new PlanEnforcement(plan);
}
