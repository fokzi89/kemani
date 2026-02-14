
export type SubscriptionPlanTier = 'starter' | 'growth' | 'business' | 'enterprise';
export type SubscriptionStatus = 'active' | 'canceled' | 'past_due' | 'trialing';
export type BillingPeriod = 'monthly' | 'yearly';

export interface Subscription {
    id: string;
    tenant_id: string;
    plan_tier: SubscriptionPlanTier;
    status: SubscriptionStatus;
    billing_period: BillingPeriod;
    current_period_start: string;
    current_period_end: string;
    cancel_at_period_end: boolean;
    payment_provider_sub_id?: string | null;
    created_at: string;
    updated_at: string;
}

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
