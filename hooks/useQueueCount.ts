'use client';

import { useEffect, useState } from 'react';
import { SalesQueueManager } from '@/lib/indexeddb/sales-queue';
import { useSubscription } from './useSubscription';

/**
 * Hook to get the number of sales in the queue
 *
 * Polls IndexedDB every 5 seconds to update the count.
 * Only active for free tier users.
 *
 * @returns Number of sales in queue
 */
export function useQueueCount() {
  const [count, setCount] = useState(0);
  const { isFree, loading } = useSubscription();

  useEffect(() => {
    if (loading || !isFree) {
      setCount(0);
      return;
    }

    const updateCount = async () => {
      try {
        const queueManager = new SalesQueueManager();
        const length = await queueManager.getQueueLength();
        setCount(length);
      } catch (error) {
        console.error('Error fetching queue count:', error);
        setCount(0);
      }
    };

    // Initial update
    updateCount();

    // Poll every 5 seconds
    const interval = setInterval(updateCount, 5000);

    return () => clearInterval(interval);
  }, [isFree, loading]);

  return count;
}
