/**
 * Type definitions for IndexedDB offline queue
 */

export interface CreateSalePayload {
  tenant_id: string;
  branch_id: string;
  customer_id?: string;
  customer_type: 'walk-in' | 'registered' | 'marketplace' | 'new';
  cashier_id: string;
  sales_attendant_id?: string;
  subtotal: number;
  discount_amount: number;
  tax_amount: number;
  delivery_fee: number;
  total_amount: number;
  amount_paid: number;
  change_amount: number;
  payment_method: 'cash' | 'card' | 'transfer' | 'mobile_money' | 'split';
  payment_reference?: string;
  payment_status?: 'pending' | 'completed' | 'void' | 'refunded';
  sale_type: 'pos' | 'online' | 'marketplace' | 'delivery';
  channel: 'in-store' | 'online' | 'mobile-app' | 'whatsapp';
  sale_status?: 'pending' | 'completed' | 'void' | 'refunded' | 'partial_refund';
  receipt_number?: string;
  items: SaleItem[];
}

export interface SaleItem {
  product_id: string;
  quantity: number;
  unit_price: number;
  line_total: number;
  discount_amount: number;
  tax_amount: number;
}

export interface QueuedSale {
  id?: number; // IndexedDB auto-increment key
  clientId: string; // UUID for deduplication
  tenantId: string;
  branchId: string;
  saleData: CreateSalePayload;
  createdAt: number; // timestamp
  syncAttempts: number;
  lastError: string | null;
}

export interface SyncResult {
  succeeded: string[]; // clientIds
  failed: Array<{ clientId: string; error: string }>;
}

export interface SyncProgress {
  total: number;
  synced: number;
  failed: number;
  current: string | null; // Current clientId being synced
}
