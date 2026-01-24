'use client';

import { useState } from 'react';
import { useSyncManager } from '@/hooks/useSyncManager';
import { useNetworkStatus } from '@/hooks/useNetworkStatus';
import { useQueueCount } from '@/hooks/useQueueCount';

/**
 * Manual Sync Button - Allows users to manually trigger sync
 */
export function ManualSyncButton() {
  const { syncAll, isSyncing } = useSyncManager();
  const { isOnline } = useNetworkStatus();
  const count = useQueueCount();
  const [message, setMessage] = useState<string | null>(null);

  if (count === 0) return null;

  const handleSync = async () => {
    setMessage(null);
    try {
      const result = await syncAll();

      if (result.failed.length > 0) {
        setMessage(
          `Sync completed. ${result.succeeded.length} succeeded, ${result.failed.length} failed.`
        );
      } else if (result.succeeded.length > 0) {
        setMessage(`All ${result.succeeded.length} sales synced successfully!`);
      } else {
        setMessage('No sales to sync.');
      }

      // Clear message after 5 seconds
      setTimeout(() => setMessage(null), 5000);
    } catch (error) {
      setMessage('Sync failed. Please try again.');
      console.error('Sync error:', error);
    }
  };

  return (
    <div className="flex flex-col gap-2">
      <button
        onClick={handleSync}
        disabled={isSyncing || !isOnline}
        className="px-4 py-2 bg-blue-600 text-white rounded-lg font-medium hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
      >
        {isSyncing ? (
          <span className="flex items-center gap-2">
            <svg className="animate-spin h-4 w-4" fill="none" viewBox="0 0 24 24">
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
            Syncing...
          </span>
        ) : (
          'Sync Now'
        )}
      </button>

      {message && (
        <div
          className={`text-sm p-2 rounded ${
            message.includes('failed')
              ? 'bg-red-50 text-red-700'
              : 'bg-green-50 text-green-700'
          }`}
        >
          {message}
        </div>
      )}
    </div>
  );
}
