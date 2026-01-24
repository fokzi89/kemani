'use client';

import { useEffect, ReactNode } from 'react';
import { networkMonitor } from '@/lib/network/network-monitor';
import { useSyncManager } from '@/hooks/useSyncManager';
import { useSubscription } from '@/hooks/useSubscription';

interface AutoSyncProviderProps {
  children: ReactNode;
}

/**
 * Auto-Sync Provider - Automatically syncs queued sales when network reconnects
 *
 * Only active for free tier users since paid tiers use PowerSync
 *
 * @example
 * ```tsx
 * <AutoSyncProvider>
 *   <SalesForm />
 * </AutoSyncProvider>
 * ```
 */
export function AutoSyncProvider({ children }: AutoSyncProviderProps) {
  const { syncAll } = useSyncManager();
  const { isFree, loading } = useSubscription();

  useEffect(() => {
    // Only enable auto-sync for free tier
    if (loading || !isFree) {
      return;
    }

    console.log('[AutoSync] Registering auto-sync callback for free tier');

    const unregister = networkMonitor.registerSyncCallback(async () => {
      console.log('[AutoSync] Network reconnected, triggering sync...');
      try {
        const result = await syncAll();
        if (result.succeeded.length > 0) {
          console.log(`[AutoSync] Successfully synced ${result.succeeded.length} sales`);
        }
        if (result.failed.length > 0) {
          console.error(`[AutoSync] Failed to sync ${result.failed.length} sales`);
        }
      } catch (error) {
        console.error('[AutoSync] Sync error:', error);
      }
    });

    return () => {
      console.log('[AutoSync] Unregistering auto-sync callback');
      unregister();
    };
  }, [isFree, loading, syncAll]);

  return <>{children}</>;
}
