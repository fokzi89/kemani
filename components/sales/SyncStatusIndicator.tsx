'use client';

import { useNetworkStatus } from '@/hooks/useNetworkStatus';
import { useSyncManager } from '@/hooks/useSyncManager';
import { useQueueCount } from '@/hooks/useQueueCount';

/**
 * Sync Status Indicator - Shows current sync status and progress
 */
export function SyncStatusIndicator() {
  const { isOnline } = useNetworkStatus();
  const { isSyncing, progress } = useSyncManager();
  const count = useQueueCount();

  // All synced - show success state
  if (count === 0 && !isSyncing) {
    return (
      <div className="flex items-center gap-2 text-sm text-green-700">
        <svg
          className="h-4 w-4"
          fill="none"
          viewBox="0 0 24 24"
          stroke="currentColor"
        >
          <path
            strokeLinecap="round"
            strokeLinejoin="round"
            strokeWidth={2}
            d="M5 13l4 4L19 7"
          />
        </svg>
        <span>All synced</span>
      </div>
    );
  }

  // Syncing in progress
  if (isSyncing && progress) {
    return (
      <div className="flex items-center gap-2 text-sm">
        <svg
          className="h-4 w-4 animate-spin text-blue-600"
          fill="none"
          viewBox="0 0 24 24"
        >
          <circle
            className="opacity-25"
            cx="12"
            cy="12"
            r="10"
            stroke="currentColor"
            strokeWidth="4"
          />
          <path
            className="opacity-75"
            fill="currentColor"
            d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
          />
        </svg>
        <span className="text-blue-700 font-medium">
          Syncing {progress.synced}/{progress.total}
        </span>
        {progress.failed > 0 && (
          <span className="text-xs text-red-600 bg-red-50 px-2 py-0.5 rounded">
            {progress.failed} failed
          </span>
        )}
      </div>
    );
  }

  // Pending sales waiting to sync
  if (count > 0) {
    return (
      <div className="flex items-center gap-2 text-sm">
        <svg
          className="h-4 w-4 text-yellow-600"
          fill="none"
          viewBox="0 0 24 24"
          stroke="currentColor"
        >
          <path
            strokeLinecap="round"
            strokeLinejoin="round"
            strokeWidth={2}
            d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"
          />
        </svg>
        <span className="text-yellow-700 font-medium">{count} pending</span>
        {!isOnline && (
          <span className="text-xs text-gray-600 bg-gray-100 px-2 py-0.5 rounded">
            Waiting for connection
          </span>
        )}
      </div>
    );
  }

  return null;
}
