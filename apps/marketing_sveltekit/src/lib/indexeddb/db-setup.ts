/**
 * IndexedDB setup for offline sales queue
 */

const DB_NAME = 'kemani-pos';
const DB_VERSION = 1;
const STORE_NAME = 'sales_queue';

/**
 * Initialize IndexedDB database with sales_queue store
 */
export async function initDB(): Promise<IDBDatabase> {
  return new Promise((resolve, reject) => {
    if (typeof window === 'undefined') {
      reject(new Error('IndexedDB is only available in the browser'));
      return;
    }

    const request = indexedDB.open(DB_NAME, DB_VERSION);

    request.onerror = () => {
      reject(new Error(`Failed to open IndexedDB: ${request.error?.message}`));
    };

    request.onsuccess = () => {
      resolve(request.result);
    };

    request.onupgradeneeded = (event) => {
      const db = (event.target as IDBOpenDBRequest).result;

      // Create sales_queue object store if it doesn't exist
      if (!db.objectStoreNames.contains(STORE_NAME)) {
        const objectStore = db.createObjectStore(STORE_NAME, {
          keyPath: 'id',
          autoIncrement: true,
        });

        // Create indexes
        objectStore.createIndex('clientId', 'clientId', { unique: true });
        objectStore.createIndex('tenantId', 'tenantId', { unique: false });
        objectStore.createIndex('createdAt', 'createdAt', { unique: false });
      }
    };
  });
}

/**
 * Get the sales_queue object store
 */
export async function getStore(mode: IDBTransactionMode = 'readonly'): Promise<IDBObjectStore> {
  const db = await initDB();
  const transaction = db.transaction(STORE_NAME, mode);
  return transaction.objectStore(STORE_NAME);
}

/**
 * Clear all data from the database (for testing/development)
 */
export async function clearDB(): Promise<void> {
  const store = await getStore('readwrite');
  return new Promise((resolve, reject) => {
    const request = store.clear();
    request.onsuccess = () => resolve();
    request.onerror = () => reject(request.error);
  });
}

/**
 * Delete the entire database (for testing/development)
 */
export async function deleteDB(): Promise<void> {
  return new Promise((resolve, reject) => {
    if (typeof window === 'undefined') {
      reject(new Error('IndexedDB is only available in the browser'));
      return;
    }

    const request = indexedDB.deleteDatabase(DB_NAME);
    request.onsuccess = () => resolve();
    request.onerror = () => reject(request.error);
  });
}

export { DB_NAME, DB_VERSION, STORE_NAME };
