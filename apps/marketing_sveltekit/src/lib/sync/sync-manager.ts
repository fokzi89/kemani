/**
 * Sync Manager - Orchestrates syncing queued sales to Supabase API
 */

import { SalesQueueManager } from '@/lib/indexeddb/sales-queue';
import { SyncResult, SyncProgress } from '@/lib/indexeddb/types';

type ProgressListener = (progress: SyncProgress) => void;

export class SyncManager {
  private queueManager: SalesQueueManager;
  private listeners = new Set<ProgressListener>();
  private isSyncing = false;

  constructor() {
    this.queueManager = new SalesQueueManager();
  }

  /**
   * Sync all queued sales to the API
   */
  async syncAll(): Promise<SyncResult> {
    if (this.isSyncing) {
      console.warn('Sync already in progress');
      return { succeeded: [], failed: [] };
    }

    this.isSyncing = true;

    try {
      const queuedSales = await this.queueManager.getAllQueued();

      const progress: SyncProgress = {
        total: queuedSales.length,
        synced: 0,
        failed: 0,
        current: null,
      };

      const results: SyncResult = {
        succeeded: [],
        failed: [],
      };

      // Nothing to sync
      if (queuedSales.length === 0) {
        return results;
      }

      console.log(`Starting sync of ${queuedSales.length} sales...`);

      // Sync each sale sequentially
      for (const sale of queuedSales) {
        try {
          progress.current = sale.clientId;
          this.notifyProgress(progress);

          // POST to /api/sales
          const response = await fetch('/api/sales', {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
            },
            body: JSON.stringify(sale.saleData),
          });

          if (response.ok) {
            // Success: Remove from queue
            await this.queueManager.removeFromQueue(sale.id!);
            progress.synced++;
            results.succeeded.push(sale.clientId);
            console.log(`✓ Synced sale ${sale.clientId}`);
          } else {
            // API returned an error
            const errorData = await response.json().catch(() => ({ error: { message: response.statusText } }));
            const errorMessage = errorData.error?.message || response.statusText;

            await this.queueManager.updateSyncAttempt(sale.id!, errorMessage);
            progress.failed++;
            results.failed.push({ clientId: sale.clientId, error: errorMessage });
            console.error(`✗ Failed to sync sale ${sale.clientId}:`, errorMessage);
          }
        } catch (error) {
          // Network error or other exception
          const errorMessage = error instanceof Error ? error.message : 'Unknown error';
          await this.queueManager.updateSyncAttempt(sale.id!, errorMessage);
          progress.failed++;
          results.failed.push({ clientId: sale.clientId, error: errorMessage });
          console.error(`✗ Exception syncing sale ${sale.clientId}:`, error);
        }

        this.notifyProgress(progress);
      }

      progress.current = null;
      this.notifyProgress(progress);

      console.log(
        `Sync complete: ${results.succeeded.length} succeeded, ${results.failed.length} failed`
      );

      return results;
    } finally {
      this.isSyncing = false;
    }
  }

  /**
   * Subscribe to sync progress updates
   * @returns Unsubscribe function
   */
  subscribe(listener: ProgressListener): () => void {
    this.listeners.add(listener);
    return () => {
      this.listeners.delete(listener);
    };
  }

  /**
   * Notify all listeners of progress update
   */
  private notifyProgress(progress: SyncProgress) {
    this.listeners.forEach((listener) => {
      try {
        listener({ ...progress }); // Send a copy
      } catch (error) {
        console.error('Error in sync progress listener:', error);
      }
    });
  }

  /**
   * Check if sync is currently in progress
   */
  getSyncStatus(): boolean {
    return this.isSyncing;
  }

  /**
   * Get the queue manager instance
   */
  getQueueManager(): SalesQueueManager {
    return this.queueManager;
  }
}
