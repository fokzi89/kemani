/**
 * Network Monitor - Singleton for detecting online/offline status
 */

export type NetworkStatus = 'online' | 'offline' | 'checking';

type StatusListener = (status: NetworkStatus) => void;
type SyncCallback = () => void;

class NetworkMonitor {
  private currentStatus: NetworkStatus = 'checking';
  private statusListeners = new Set<StatusListener>();
  private syncCallbacks = new Set<SyncCallback>();
  private initialized = false;

  constructor() {
    if (typeof window !== 'undefined') {
      this.init();
    }
  }

  private init() {
    if (this.initialized) return;

    // Set initial status
    this.currentStatus = navigator.onLine ? 'online' : 'offline';

    // Listen to online/offline events
    window.addEventListener('online', this.handleOnline);
    window.addEventListener('offline', this.handleOffline);

    this.initialized = true;
  }

  private handleOnline = () => {
    const wasOffline = this.currentStatus === 'offline';
    this.currentStatus = 'online';
    this.notifyStatusListeners();

    // Trigger sync callbacks when transitioning from offline to online
    if (wasOffline) {
      this.triggerSyncCallbacks();
    }
  };

  private handleOffline = () => {
    this.currentStatus = 'offline';
    this.notifyStatusListeners();
  };

  private notifyStatusListeners() {
    this.statusListeners.forEach((listener) => {
      try {
        listener(this.currentStatus);
      } catch (error) {
        console.error('Error in network status listener:', error);
      }
    });
  }

  private triggerSyncCallbacks() {
    console.log('Network reconnected, triggering sync callbacks...');
    this.syncCallbacks.forEach((callback) => {
      try {
        callback();
      } catch (error) {
        console.error('Error in sync callback:', error);
      }
    });
  }

  /**
   * Subscribe to network status changes
   * @returns Unsubscribe function
   */
  subscribe(listener: StatusListener): () => void {
    this.statusListeners.add(listener);

    // Immediately notify with current status
    listener(this.currentStatus);

    return () => {
      this.statusListeners.delete(listener);
    };
  }

  /**
   * Register a callback to be triggered when network reconnects
   * @returns Unregister function
   */
  registerSyncCallback(callback: SyncCallback): () => void {
    this.syncCallbacks.add(callback);

    return () => {
      this.syncCallbacks.delete(callback);
    };
  }

  /**
   * Get current network status
   */
  getStatus(): NetworkStatus {
    return this.currentStatus;
  }

  /**
   * Check if currently online
   */
  isOnline(): boolean {
    return this.currentStatus === 'online';
  }

  /**
   * Check if currently offline
   */
  isOffline(): boolean {
    return this.currentStatus === 'offline';
  }

  /**
   * Force a status check (useful for testing)
   */
  checkStatus() {
    if (typeof window !== 'undefined') {
      const isOnline = navigator.onLine;
      this.currentStatus = isOnline ? 'online' : 'offline';
      this.notifyStatusListeners();
    }
  }

  /**
   * Cleanup event listeners (for testing/unmounting)
   */
  destroy() {
    if (typeof window !== 'undefined') {
      window.removeEventListener('online', this.handleOnline);
      window.removeEventListener('offline', this.handleOffline);
    }
    this.statusListeners.clear();
    this.syncCallbacks.clear();
    this.initialized = false;
  }
}

// Export singleton instance
export const networkMonitor = new NetworkMonitor();
