import { createClient } from '@/lib/supabase/client';
import { PLANS } from './subscription';
import { CommissionService } from './commission';

export interface Invoice {
    id: string;
    tenant_id: string;
    amount: number;
    currency: string;
    status: 'paid' | 'pending' | 'overdue';
    due_date: string;
    created_at: string;
    description: string;
    items: InvoiceItem[];
}

export interface InvoiceItem {
    description: string;
    amount: number;
}

export class BillingService {

    /**
     * Generate an invoice for a tenant's subscription renewal
     */
    static async generateSubscriptionInvoice(tenantId: string): Promise<Invoice | null> {
        const supabase = await createClient();

        // Get active subscription
        const { data: sub } = await supabase
            .from('subscriptions')
            .select('*')
            .eq('tenant_id', tenantId)
            .eq('status', 'active')
            .single();

        if (!sub) return null;

        const plan = PLANS[sub.plan_tier];
        if (plan.price === 0) return null; // Free/Starter tiers don't generate sub invoices

        // Create invoice record (mocked for MVP, would insert to 'invoices' table)
        const invoice: Invoice = {
            id: `inv_${Date.now()}`,
            tenant_id: tenantId,
            amount: plan.price,
            currency: 'NGN',
            status: 'pending',
            due_date: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString(), // Due in 7 days
            created_at: new Date().toISOString(),
            description: `Subscription Renewal - ${plan.name}`,
            items: [
                { description: `${plan.name} Plan (${sub.billing_period})`, amount: plan.price }
            ]
        };

        // In real app: Insert into DB
        // await supabase.from('invoices').insert(invoice);

        return invoice;
    }

    /**
     * Generate an invoice for unbilled commissions
     */
    static async generateCommissionInvoice(tenantId: string): Promise<Invoice | null> {
        const supabase = await createClient();

        // Get pending commissions
        const { data: commissions } = await supabase
            .from('commissions')
            .select('*')
            .eq('tenant_id', tenantId)
            .eq('status', 'pending');

        if (!commissions || commissions.length === 0) return null;

        const totalAmount = commissions.reduce((sum, c) => sum + c.amount, 0);

        if (totalAmount < 1000) return null; // Minimum threshold to invoice

        const invoice: Invoice = {
            id: `inv_comm_${Date.now()}`,
            tenant_id: tenantId,
            amount: totalAmount,
            currency: 'NGN',
            status: 'pending',
            due_date: new Date(Date.now() + 3 * 24 * 60 * 60 * 1000).toISOString(),
            created_at: new Date().toISOString(),
            description: `Commission Invoice - ${commissions.length} Orders`,
            items: commissions.map(c => ({
                description: `Order #${c.order_id.slice(0, 8)} Commission`,
                amount: c.amount
            }))
        };

        // In real app: Insert into DB and mark commissions as 'invoiced'

        return invoice;
    }

    /**
     * Get billing history for a tenant
     * MVP: Returns empty list or mock data
     */
    static async getBillingHistory(tenantId: string): Promise<Invoice[]> {
        // Mock data
        return [];
    }
}
