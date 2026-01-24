'use client';

import { useState, FormEvent } from 'react';
import { useAuth } from '@/hooks/useAuth';
import { useSubscription } from '@/hooks/useSubscription';
import { useNetworkStatus } from '@/hooks/useNetworkStatus';
import { SalesQueueManager } from '@/lib/indexeddb/sales-queue';
import { CreateSalePayload } from '@/lib/indexeddb/types';

/**
 * Simplified Sales Form for demonstration
 *
 * NOTE: This is a minimal implementation to demonstrate the queue functionality.
 * A production version would include:
 * - Product selection with search
 * - Shopping cart with quantities
 * - Payment method selector
 * - Customer selector
 * - Discount and tax calculations
 */
export function SimpleSalesForm() {
  const { user, isAuthenticated } = useAuth();
  const { isFree, isPaid, planTier, loading: subLoading } = useSubscription();
  const { isOnline, isOffline } = useNetworkStatus();

  const [productName, setProductName] = useState('');
  const [quantity, setQuantity] = useState(1);
  const [unitPrice, setUnitPrice] = useState(0);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [message, setMessage] = useState<{ type: 'success' | 'error'; text: string } | null>(
    null
  );

  if (!isAuthenticated || subLoading) {
    return <div className="text-center py-8">Loading...</div>;
  }

  if (!user) {
    return <div className="text-center py-8">Please sign in to create sales</div>;
  }

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    setMessage(null);
    setIsSubmitting(true);

    try {
      const lineTotal = quantity * unitPrice;
      const subtotal = lineTotal;
      const total = subtotal;

      // Build sale payload
      // NOTE: In production, get these from actual data
      const salePayload: CreateSalePayload = {
        tenant_id: user.user_metadata?.tenant_id || '',
        branch_id: user.user_metadata?.branch_id || '',
        customer_type: 'walk-in',
        cashier_id: user.id,
        subtotal,
        discount_amount: 0,
        tax_amount: 0,
        delivery_fee: 0,
        total_amount: total,
        amount_paid: total,
        change_amount: 0,
        payment_method: 'cash',
        sale_type: 'pos',
        channel: 'in-store',
        items: [
          {
            product_id: crypto.randomUUID(), // Mock product ID
            quantity,
            unit_price: unitPrice,
            line_total: lineTotal,
            discount_amount: 0,
            tax_amount: 0,
          },
        ],
      };

      // Route based on tier and connectivity
      if (isFree) {
        await handleFreeTierSale(salePayload);
      } else {
        await handlePaidTierSale(salePayload);
      }

      // Reset form
      setProductName('');
      setQuantity(1);
      setUnitPrice(0);
    } catch (error) {
      console.error('Sale creation error:', error);
      setMessage({
        type: 'error',
        text: error instanceof Error ? error.message : 'Failed to create sale',
      });
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleFreeTierSale = async (payload: CreateSalePayload) => {
    if (isOnline) {
      // Direct API call when online
      const response = await fetch('/api/sales', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
      });

      if (!response.ok) {
        const error = await response.json();
        throw new Error(error.error?.message || 'Sale creation failed');
      }

      const data = await response.json();
      setMessage({
        type: 'success',
        text: `Sale ${data.data.sale_number} created successfully!`,
      });
    } else {
      // Offline: Add to IndexedDB queue
      const queueManager = new SalesQueueManager();
      const queueLength = await queueManager.getQueueLength();

      // Warn if queue has 3+ items
      if (queueLength >= 3) {
        const confirmed = window.confirm(
          `You have ${queueLength} sales queued. Adding more may cause sync issues. Continue?`
        );
        if (!confirmed) return;
      }

      await queueManager.addToQueue({
        clientId: crypto.randomUUID(),
        tenantId: payload.tenant_id,
        branchId: payload.branch_id,
        saleData: payload,
      });

      setMessage({
        type: 'success',
        text: 'Sale queued. Will sync when online.',
      });
    }
  };

  const handlePaidTierSale = async (payload: CreateSalePayload) => {
    // Paid tier always goes direct to API
    // PowerSync handles offline sync for paid tiers
    const response = await fetch('/api/sales', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
    });

    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.error?.message || 'Sale creation failed');
    }

    const data = await response.json();
    setMessage({
      type: 'success',
      text: `Sale ${data.data.sale_number} created successfully!`,
    });
  };

  return (
    <div className="max-w-2xl mx-auto">
      <div className="bg-white shadow-md rounded-lg p-6">
        <div className="mb-6">
          <h2 className="text-2xl font-bold text-gray-900">New Sale</h2>
          <div className="mt-2 flex items-center gap-4 text-sm">
            <span className="text-gray-600">
              Plan: <span className="font-medium text-gray-900">{planTier}</span>
            </span>
            <span className="text-gray-600">
              Status:{' '}
              <span
                className={`font-medium ${
                  isOnline ? 'text-green-600' : 'text-red-600'
                }`}
              >
                {isOnline ? 'Online' : 'Offline'}
              </span>
            </span>
            {isFree && isOffline && (
              <span className="text-xs bg-yellow-50 text-yellow-700 px-2 py-1 rounded">
                Sales will be queued
              </span>
            )}
          </div>
        </div>

        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label htmlFor="product" className="block text-sm font-medium text-gray-700">
              Product Name
            </label>
            <input
              type="text"
              id="product"
              value={productName}
              onChange={(e) => setProductName(e.target.value)}
              required
              className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 px-3 py-2 border"
              placeholder="Enter product name"
            />
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <label htmlFor="quantity" className="block text-sm font-medium text-gray-700">
                Quantity
              </label>
              <input
                type="number"
                id="quantity"
                value={quantity}
                onChange={(e) => setQuantity(parseInt(e.target.value) || 1)}
                min="1"
                required
                className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 px-3 py-2 border"
              />
            </div>

            <div>
              <label htmlFor="price" className="block text-sm font-medium text-gray-700">
                Unit Price (₦)
              </label>
              <input
                type="number"
                id="price"
                value={unitPrice}
                onChange={(e) => setUnitPrice(parseFloat(e.target.value) || 0)}
                min="0"
                step="0.01"
                required
                className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 px-3 py-2 border"
              />
            </div>
          </div>

          <div className="pt-4 border-t border-gray-200">
            <div className="flex justify-between text-lg font-semibold">
              <span>Total:</span>
              <span>₦{(quantity * unitPrice).toFixed(2)}</span>
            </div>
          </div>

          <button
            type="submit"
            disabled={isSubmitting || !productName || quantity < 1 || unitPrice <= 0}
            className="w-full bg-blue-600 text-white py-3 px-4 rounded-lg font-medium hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
          >
            {isSubmitting ? 'Creating Sale...' : 'Complete Sale'}
          </button>

          {message && (
            <div
              className={`mt-4 p-4 rounded-lg ${
                message.type === 'success'
                  ? 'bg-green-50 text-green-800'
                  : 'bg-red-50 text-red-800'
              }`}
            >
              {message.text}
            </div>
          )}
        </form>

        <div className="mt-6 p-4 bg-blue-50 rounded-lg text-sm text-blue-800">
          <p className="font-medium">Note:</p>
          <p className="mt-1">
            {isFree && isOffline
              ? 'You are offline. This sale will be queued and synced when you reconnect.'
              : isFree && isOnline
              ? 'You are online. This sale will be created immediately.'
              : 'PowerSync handles offline sync for your plan.'}
          </p>
        </div>
      </div>
    </div>
  );
}
