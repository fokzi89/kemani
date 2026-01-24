'use client';

import { useEffect, useState, useRef, useCallback } from 'react';
import { SyncManager } from '@/lib/sync/sync-manager';
import { SyncProgress, SyncResult } from '@/lib/indexeddb/types';

/**
 * Hook to manage sales queue synchronization
 *
 * @returns Sync manager utilities
 *
 * @example
 * ```tsx
 * function SyncButton() {
 *   const { syncAll, isSyncing, progress } = useSyncManager();
 *
 *   const handleSync = async () => {
 *     const result = await syncAll();
 *     console.log(`Synced ${result.succeeded.length} sales`);
 *   };
 *
 *   return (
 *     <button onClick={handleSync} disabled={isSyncing}>
 *       {isSyncing ? `Syncing ${progress?.synced}/${progress?.total}` : 'Sync Now'}
 *     </button>
 *   );
 * }
 * ```
 */
export function useSyncManager() {
  const [isSyncing, setIsSyncing] = useState(false);
  const [progress, setProgress] = useState<SyncProgress | null>(null);
  const syncManagerRef = useRef<SyncManager | null>(null);

  // Initialize sync manager
  useEffect(() => {
    syncManagerRef.current = new SyncManager();

    const unsubscribe = syncManagerRef.current.subscribe((newProgress) => {
      setProgress(newProgress);
      setIsSyncing(newProgress.current !== null || newProgress.synced < newProgress.total);
    });

    return () => {
      unsubscribe();
    };
  }, []);

  const syncAll = useCallback(async (): Promise<SyncResult> => {
    if (!syncManagerRef.current) {
      return { succeeded: [], failed: [] };
    }

    setIsSyncing(true);
    try {
      const result = await syncManagerRef.current.syncAll();
      return result;
    } finally {
      setIsSyncing(false);
    }
  }, []);

  return {
    syncAll,
    isSyncing,
    progress,
  };
}
