import type { SupabaseClient } from '@supabase/supabase-js';
import type { Database, PlanTier } from '$lib/types/supabase.js';
import { PlanEnforcement, getPlanLimits, isFeatureEnabled } from '$lib/storefront/plans.js';

export interface TenantUsage {
    products: number;
    staff: number;
    branches: number;
}

export interface PlanEnforcementResult {
    allowed: boolean;
    message?: string;
    limit?: number;
    current?: number;
    remaining?: number | 'unlimited';
}

export class PlanEnforcementService {
    private enforcement: PlanEnforcement;

    constructor(
        private supabase: SupabaseClient<Database>,
        private planTier: PlanTier,
        private tenantId: string
    ) {
        this.enforcement = new PlanEnforcement(planTier);
    }

    /**
     * Get current tenant usage statistics
     * Note: For storefront, we only track products directly
     * Staff and branch counts would come from the main POS system
     */
    async getTenantUsage(): Promise<TenantUsage> {
        // Get product count from storefront
        const { count: productCount } = await this.supabase
            .from('storefront_products')
            .select('*', { count: 'exact', head: true })
            .eq('tenant_id', this.tenantId);

        // For staff and branch counts, we'll need to get these from the main system
        // For now, return defaults that can be overridden
        return {
            products: productCount || 0,
            staff: 1, // Default to 1 (owner)
            branches: 1 // Default to 1 branch
        };
    }

    /**
     * Get tenant usage with external data
     */
    async getTenantUsageWithExternalData(externalUsage?: Partial<TenantUsage>): Promise<TenantUsage> {
        const baseUsage = await this.getTenantUsage();
        
        return {
            products: baseUsage.products,
            staff: externalUsage?.staff ?? baseUsage.staff,
            branches: externalUsage?.branches ?? baseUsage.branches
        };
    }

    /**
     * Check if tenant can add a new product (T010a)
     */
    async canAddProduct(): Promise<PlanEnforcementResult> {
        const usage = await this.getTenantUsage();
        const result = this.enforcement.enforceProductLimit(usage.products);
        
        return {
            allowed: result.allowed,
            message: result.message,
            limit: result.limit === Infinity ? undefined : result.limit,
            current: usage.products,
            remaining: result.remaining
        };
    }

    /**
     * Check if tenant can add new staff member (T010b)
     * Uses external staff count since storefront doesn't track staff
     */
    async canAddStaff(currentStaffCount?: number): Promise<PlanEnforcementResult> {
        const staffCount = currentStaffCount ?? 1; // Default to 1 if not provided
        const result = this.enforcement.enforceStaffLimit(staffCount);
        
        return {
            allowed: result.allowed,
            message: result.message,
            limit: result.limit === Infinity ? undefined : result.limit,
            current: staffCount,
            remaining: result.remaining
        };
    }

    /**
     * Check if tenant can add new branch
     * Uses external branch count since storefront doesn't track branches
     */
    async canAddBranch(currentBranchCount?: number): Promise<PlanEnforcementResult> {
        const branchCount = currentBranchCount ?? 1; // Default to 1 if not provided
        const limits = getPlanLimits(this.planTier);
        const limit = limits.maxBranches;
        
        if (limit === Infinity) {
            return {
                allowed: true,
                remaining: 'unlimited'
            };
        }

        const allowed = branchCount < limit;
        const remaining = Math.max(0, limit - branchCount);

        return {
            allowed,
            message: allowed 
                ? undefined 
                : `Branch limit reached. Upgrade to add more branches. Current: ${branchCount}/${limit}`,
            limit,
            current: branchCount,
            remaining
        };
    }

    /**
     * Check if feature is available for current plan
     */
    checkFeatureAccess(feature: keyof ReturnType<typeof getPlanLimits>): PlanEnforcementResult {
        const available = isFeatureEnabled(this.planTier, feature);
        
        return {
            allowed: available,
            message: available 
                ? undefined 
                : `This feature is not available on your current plan. Please upgrade to access ${feature}.`
        };
    }

    /**
     * Get comprehensive plan status
     */
    async getPlanStatus(externalUsage?: Partial<TenantUsage>) {
        const usage = await this.getTenantUsageWithExternalData(externalUsage);
        const limits = getPlanLimits(this.planTier);
        
        return {
            planTier: this.planTier,
            usage,
            limits,
            enforcement: {
                products: this.enforcement.enforceProductLimit(usage.products),
                staff: this.enforcement.enforceStaffLimit(usage.staff),
                branches: await this.canAddBranch(usage.branches)
            },
            features: {
                aiChatStandard: this.checkFeatureAccess('aiChatStandard'),
                aiChatAgent: this.checkFeatureAccess('aiChatAgent'),
                multiBranch: this.checkFeatureAccess('multiBranch'),
                deliveryIntegration: this.checkFeatureAccess('deliveryIntegration'),
                whatsappIntegration: this.checkFeatureAccess('whatsappIntegration'),
                customBranding: this.checkFeatureAccess('customBranding')
            }
        };
    }
}

/**
 * Create plan enforcement service instance
 * For storefront, we'll default to 'free' plan if no plan is provided
 */
export async function createPlanEnforcementService(
    supabase: SupabaseClient<Database>,
    tenantId: string,
    planTier?: PlanTier
): Promise<PlanEnforcementService> {
    // Use provided plan tier or default to 'free'
    // In a real implementation, this would come from the main POS system
    const plan = planTier || 'free';
    
    return new PlanEnforcementService(supabase, plan, tenantId);
}

/**
 * Middleware function to check plan limits before operations
 */
export async function withPlanEnforcement<T>(
    supabase: SupabaseClient<Database>,
    tenantId: string,
    operation: 'add_product' | 'add_staff' | 'add_branch',
    callback: () => Promise<T>,
    planTier?: PlanTier
): Promise<T> {
    const service = await createPlanEnforcementService(supabase, tenantId, planTier);
    
    let check: PlanEnforcementResult;
    
    switch (operation) {
        case 'add_product':
            check = await service.canAddProduct();
            break;
        case 'add_staff':
            check = await service.canAddStaff();
            break;
        case 'add_branch':
            check = await service.canAddBranch();
            break;
        default:
            throw new Error(`Unknown operation: ${operation}`);
    }
    
    if (!check.allowed) {
        throw new Error(check.message || 'Operation not allowed by current plan');
    }
    
    return callback();
}