import { useSubscriptionContext } from '@/lib/context/SubscriptionContext';

/**
 * Hook to access subscription information
 *
 * @returns Subscription context with tier information and utilities
 * @throws Error if used outside SubscriptionProvider
 *
 * @example
 * ```tsx
 * function MyComponent() {
 *   const { isFree, isPaid, planTier } = useSubscription();
 *
 *   if (isFree) {
 *     // Free tier logic - use IndexedDB queue
 *   } else {
 *     // Paid tier logic - use PowerSync
 *   }
 * }
 * ```
 */
export function useSubscription() {
  return useSubscriptionContext();
}
