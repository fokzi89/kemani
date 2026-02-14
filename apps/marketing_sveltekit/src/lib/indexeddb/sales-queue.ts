/**
 * Sales Queue Manager for IndexedDB offline queue
 */

import { getStore } from './db-setup';
import { QueuedSale, CreateSalePayload } from './types';

export class SalesQueueManager {
  /**
   * Add a sale to the queue
   */
  async addToQueue(
    sale: Omit<QueuedSale, 'id' | 'createdAt' | 'syncAttempts' | 'lastError'>
  ): Promise<number> {
    const store = await getStore('readwrite');

    const queuedSale: Omit<QueuedSale, 'id'> = {
      ...sale,
      createdAt: Date.now(),
      syncAttempts: 0,
      lastError: null,
    };

    return new Promise((resolve, reject) => {
      const request = store.add(queuedSale);
      request.onsuccess = () => resolve(request.result as number);
      request.onerror = () => reject(request.error);
    });
  }

  /**
   * Get the number of sales in the queue
   */
  async getQueueLength(): Promise<number> {
    const store = await getStore('readonly');
    return new Promise((resolve, reject) => {
      const request = store.count();
      request.onsuccess = () => resolve(request.result);
      request.onerror = () => reject(request.error);
    });
  }

  /**
   * Get all queued sales, ordered by creation time
   */
  async getAllQueued(): Promise<QueuedSale[]> {
    const store = await getStore('readonly');
    return new Promise((resolve, reject) => {
      const request = store.getAll();
      request.onsuccess = () => {
        const sales = request.result as QueuedSale[];
        // Sort by createdAt (oldest first)
        sales.sort((a, b) => a.createdAt - b.createdAt);
        resolve(sales);
      };
      request.onerror = () => reject(request.error);
    });
  }

  /**
   * Get a specific queued sale by its ID
   */
  async getById(id: number): Promise<QueuedSale | null> {
    const store = await getStore('readonly');
    return new Promise((resolve, reject) => {
      const request = store.get(id);
      request.onsuccess = () => resolve((request.result as QueuedSale) || null);
      request.onerror = () => reject(request.error);
    });
  }

  /**
   * Get a queued sale by its clientId
   */
  async getByClientId(clientId: string): Promise<QueuedSale | null> {
    const store = await getStore('readonly');
    const index = store.index('clientId');

    return new Promise((resolve, reject) => {
      const request = index.get(clientId);
      request.onsuccess = () => resolve((request.result as QueuedSale) || null);
      request.onerror = () => reject(request.error);
    });
  }

  /**
   * Remove a sale from the queue after successful sync
   */
  async removeFromQueue(id: number): Promise<void> {
    const store = await getStore('readwrite');
    return new Promise((resolve, reject) => {
      const request = store.delete(id);
      request.onsuccess = () => resolve();
      request.onerror = () => reject(request.error);
    });
  }

  /**
   * Update sync attempt count and last error for a queued sale
   */
  async updateSyncAttempt(id: number, error: string | null): Promise<void> {
    const store = await getStore('readwrite');

    return new Promise((resolve, reject) => {
      const getRequest = store.get(id);

      getRequest.onsuccess = () => {
        const sale = getRequest.result as QueuedSale;
        if (!sale) {
          reject(new Error(`Sale with id ${id} not found`));
          return;
        }

        sale.syncAttempts += 1;
        sale.lastError = error;

        const updateRequest = store.put(sale);
        updateRequest.onsuccess = () => resolve();
        updateRequest.onerror = () => reject(updateRequest.error);
      };

      getRequest.onerror = () => reject(getRequest.error);
    });
  }

  /**
   * Clear all queued sales (for testing/development)
   */
  async clearQueue(): Promise<void> {
    const store = await getStore('readwrite');
    return new Promise((resolve, reject) => {
      const request = store.clear();
      request.onsuccess = () => resolve();
      request.onerror = () => reject(request.error);
    });
  }

  /**
   * Get sales for a specific tenant
   */
  async getByTenant(tenantId: string): Promise<QueuedSale[]> {
    const store = await getStore('readonly');
    const index = store.index('tenantId');

    return new Promise((resolve, reject) => {
      const request = index.getAll(tenantId);
      request.onsuccess = () => {
        const sales = request.result as QueuedSale[];
        // Sort by createdAt (oldest first)
        sales.sort((a, b) => a.createdAt - b.createdAt);
        resolve(sales);
      };
      request.onerror = () => reject(request.error);
    });
  }

  /**
   * Check if a sale with the given clientId already exists in the queue
   */
  async exists(clientId: string): Promise<boolean> {
    const sale = await this.getByClientId(clientId);
    return sale !== null;
  }
}
