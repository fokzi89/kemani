import { createClient } from '@/lib/supabase/client';
import { Commission } from '@/lib/types/database';

export class CommissionService {

    private static RATE_PERCENTAGE = 2.5; // Platform fee

    /**
     * Calculate commission amount
     */
    /**
     * Calculate commission amount based on plan tier and order total
     */
    static calculate(amount: number, planTier: 'starter' | 'growth' | 'business' | 'enterprise'): number {
        // Default flat fee for all plans
        let flatFee = 50;
        let variableFee = 0;

        if (planTier === 'starter') {
            // Starter: 1.5% + N50
            // Waive N50 if amount > 2500
            if (amount > 2500) {
                flatFee = 0;
            }

            // 1.5% calculation
            const rawVariable = amount * 0.015;

            // Cap 1.5% at 1000
            variableFee = Math.min(rawVariable, 1000);
        }

        // For Growth, Business, Enterprise: Only flat fee of N50 applies (as per "N50 ecommerce fee for all plans")
        // No variable percentage for paid plans to encourage upgrade.

        return Math.round(variableFee + flatFee);
    }

    /**
     * Record commission for a completed order
     */
    static async recordCommission(tenantId: string, orderId: string, orderTotal: number) {
        const supabase = await createClient();

        // Fetch subscription to determine tier
        // We import SubscriptionService dynamically or use direct DB query to avoid circular deps if any
        // But simpler to just query the subscription table directly here for speed/independence
        const { data: sub } = await supabase
            .from('subscriptions')
            .select('plan_tier')
            .eq('tenant_id', tenantId)
            .eq('status', 'active')
            .single();

        const planTier = sub?.plan_tier || 'starter'; // Default to starter if no sub found

        const amount = this.calculate(orderTotal, planTier);

        const { error } = await supabase
            .from('commissions')
            .insert({
                tenant_id: tenantId,
                order_id: orderId,
                amount: amount,
                rate_percentage: planTier === 'starter' ? 1.5 : 0, // Informational
                status: 'pending'
            });

        if (error) console.error("Failed to record commission", error);
    }
}
