'use client';

import { useQueueCount } from '@/hooks/useQueueCount';
import { useNetworkStatus } from '@/hooks/useNetworkStatus';

/**
 * Queue Badge - Shows number of pending sales in the queue
 */
export function QueueBadge() {
  const count = useQueueCount();
  const { isOffline } = useNetworkStatus();

  if (count === 0) return null;

  return (
    <div className="flex items-center gap-2 px-3 py-1.5 bg-yellow-50 border border-yellow-200 rounded-lg text-sm">
      <div className="flex items-center gap-1.5">
        <div className="h-2 w-2 rounded-full bg-yellow-500 animate-pulse" />
        <span className="font-medium text-yellow-900">
          {count} Pending {count === 1 ? 'Sale' : 'Sales'}
        </span>
      </div>
      {isOffline && (
        <span className="text-xs text-yellow-700 bg-yellow-100 px-2 py-0.5 rounded">
          Offline
        </span>
      )}
    </div>
  );
}
