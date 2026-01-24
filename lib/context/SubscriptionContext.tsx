'use client';

import { createContext, useContext, useEffect, useState, ReactNode } from 'react';
import { usePathname } from 'next/navigation';
import { createClient } from '@/lib/supabase/client';
import { Database } from '@/types/database.types';

type Subscription = Database['public']['Tables']['subscriptions']['Row'];
type PlanTier = Database['public']['Enums']['plan_tier'];

interface SubscriptionContextValue {
  subscription: Subscription | null;
  planTier: PlanTier | null;
  isFree: boolean;
  isPaid: boolean;
  loading: boolean;
  error: Error | null;
  refetch: () => Promise<void>;
}

const SubscriptionContext = createContext<SubscriptionContextValue | undefined>(undefined);

// Public routes that don't require authentication or subscription data
const PUBLIC_ROUTES = ['/', '/pricing', '/about', '/contact', '/privacy', '/terms', '/docs', '/support'];

export function SubscriptionProvider({ children }: { children: ReactNode }) {
  const pathname = usePathname();
  const [subscription, setSubscription] = useState<Subscription | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  const fetchSubscription = async () => {
    try {
      setLoading(true);
      setError(null);

      const supabase = createClient();

      // Get current user
      const { data: { user }, error: authError } = await supabase.auth.getUser();

      if (authError) throw authError;
      if (!user) {
        setSubscription(null);
        return;
      }

      // Get user's tenant
      const { data: userData, error: userError } = await supabase
        .from('users')
        .select('tenant_id')
        .eq('id', user.id)
        .single();

      if (userError) throw userError;
      if (!userData) throw new Error('User data not found');

      // Get tenant with subscription
      const { data: tenantData, error: tenantError } = await supabase
        .from('tenants')
        .select('subscription_id')
        .eq('id', userData.tenant_id)
        .single();

      if (tenantError) throw tenantError;
      if (!tenantData?.subscription_id) {
        throw new Error('No subscription found for tenant');
      }

      // Get subscription details
      const { data: subscriptionData, error: subscriptionError } = await supabase
        .from('subscriptions')
        .select('*')
        .eq('id', tenantData.subscription_id)
        .single();

      if (subscriptionError) throw subscriptionError;

      setSubscription(subscriptionData);
    } catch (err) {
      console.error('Failed to fetch subscription:', err);
      setError(err instanceof Error ? err : new Error('Unknown error'));
      setSubscription(null);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    // Skip fetching subscription for public routes
    const isPublicRoute = PUBLIC_ROUTES.includes(pathname);

    if (isPublicRoute) {
      setLoading(false);
      return;
    }

    fetchSubscription();
  }, [pathname]);

  const planTier = subscription?.plan_tier || null;
  const isFree = planTier === 'free';
  const isPaid = planTier !== null && planTier !== 'free';

  const value: SubscriptionContextValue = {
    subscription,
    planTier,
    isFree,
    isPaid,
    loading,
    error,
    refetch: fetchSubscription,
  };

  return (
    <SubscriptionContext.Provider value={value}>
      {children}
    </SubscriptionContext.Provider>
  );
}

export function useSubscriptionContext() {
  const context = useContext(SubscriptionContext);
  if (context === undefined) {
    throw new Error('useSubscriptionContext must be used within SubscriptionProvider');
  }
  return context;
}
