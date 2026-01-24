import { SimpleSalesForm } from '@/components/sales/SimpleSalesForm';
import { AutoSyncProvider } from '@/components/sales/AutoSyncProvider';
import { QueueBadge } from '@/components/sales/QueueBadge';
import { SyncStatusIndicator } from '@/components/sales/SyncStatusIndicator';
import { ManualSyncButton } from '@/components/sales/ManualSyncButton';

export const metadata = {
  title: 'Sales | Kemani POS',
  description: 'Create and manage sales',
};

/**
 * Sales Page - Complete sales interface with offline queue support
 *
 * Features:
 * - Create sales with tier-based routing (free tier → queue, paid tier → direct API)
 * - Queue badge showing pending sales
 * - Sync status indicator
 * - Manual sync button
 * - Auto-sync when network reconnects (free tier only)
 */
export default function SalesPage() {
  return (
    <AutoSyncProvider>
      <div className="min-h-screen bg-gray-50 py-8 px-4">
        {/* Header with Queue Status */}
        <header className="max-w-7xl mx-auto mb-8">
          <div className="flex items-center justify-between">
            <div>
              <h1 className="text-3xl font-bold text-gray-900">Point of Sale</h1>
              <p className="mt-1 text-gray-600">
                Create sales with automatic offline queue support
              </p>
            </div>

            <div className="flex items-center gap-4">
              <QueueBadge />
            </div>
          </div>

          {/* Sync Controls */}
          <div className="mt-6 flex items-center justify-between bg-white rounded-lg shadow-sm p-4">
            <SyncStatusIndicator />
            <ManualSyncButton />
          </div>
        </header>

        {/* Sales Form */}
        <main className="max-w-7xl mx-auto">
          <SimpleSalesForm />
        </main>

        {/* Info Panel */}
        <footer className="max-w-7xl mx-auto mt-8">
          <div className="bg-white rounded-lg shadow-sm p-6">
            <h3 className="text-lg font-semibold text-gray-900 mb-3">
              How Offline Queue Works
            </h3>
            <div className="space-y-2 text-sm text-gray-600">
              <p>
                <strong>Free Tier:</strong> Sales are queued locally (IndexedDB) when offline,
                then automatically synced when you reconnect. Maximum 3 sales can be queued
                (warning shown at 4th).
              </p>
              <p>
                <strong>Paid Tiers:</strong> Use PowerSync for advanced offline capabilities.
                Sales sync automatically in the background.
              </p>
              <p className="mt-4 text-xs text-gray-500">
                Note: This is a simplified demo. Production version will include product
                selection, shopping cart, customer management, and receipt printing.
              </p>
            </div>
          </div>
        </footer>
      </div>
    </AutoSyncProvider>
  );
}
