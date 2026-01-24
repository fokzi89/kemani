'use client';

import { useEffect, useState } from 'react';
import { networkMonitor, NetworkStatus } from '@/lib/network/network-monitor';

/**
 * Hook to monitor network connectivity status
 *
 * @returns Network status information
 *
 * @example
 * ```tsx
 * function MyComponent() {
 *   const { status, isOnline, isOffline } = useNetworkStatus();
 *
 *   if (isOffline) {
 *     return <div>You are currently offline</div>;
 *   }
 *
 *   return <div>You are online</div>;
 * }
 * ```
 */
export function useNetworkStatus() {
  const [status, setStatus] = useState<NetworkStatus>(() => networkMonitor.getStatus());

  useEffect(() => {
    const unsubscribe = networkMonitor.subscribe((newStatus) => {
      setStatus(newStatus);
    });

    return unsubscribe;
  }, []);

  return {
    status,
    isOnline: status === 'online',
    isOffline: status === 'offline',
    isChecking: status === 'checking',
  };
}
