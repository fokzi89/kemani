// E-Commerce & Marketplace TypeScript Types
// Feature: 001-multi-tenant-pos (User Story 3)
// Generated: 2026-03-10

import type { Database } from './database.types';

// ============================================================================
// Database Row Types (extracted from Supabase schema)
// ============================================================================

export type Customer = Database['public']['Tables']['customers']['Row'];
export type CustomerAddress = Database['public']['Tables']['customer_addresses']['Row'];
export type Order = Database['public']['Tables']['orders']['Row'];
export type OrderItem = Database['public']['Tables']['order_items']['Row'];
export type Product = Database['public']['Tables']['products']['Row'];

// Insert types (for creating new records)
export type CustomerInsert = Database['public']['Tables']['customers']['Insert'];
export type CustomerAddressInsert = Database['public']['Tables']['customer_addresses']['Insert'];
export type OrderInsert = Database['public']['Tables']['orders']['Insert'];
export type OrderItemInsert = Database['public']['Tables']['order_items']['Insert'];

// Update types (for updating records)
export type CustomerUpdate = Database['public']['Tables']['customers']['Update'];
export type CustomerAddressUpdate = Database['public']['Tables']['customer_addresses']['Update'];
export type OrderUpdate = Database['public']['Tables']['orders']['Update'];

// ============================================================================
// Enums & Constants
// ============================================================================

export type OrderStatus =
  | 'pending'
  | 'confirmed'
  | 'processing'
  | 'ready_for_pickup'
  | 'out_for_delivery'
  | 'delivered'
  | 'cancelled'
  | 'refunded';

export type OrderType = 'delivery' | 'pickup';

export type PaymentStatus = 'pending' | 'paid' | 'failed' | 'refunded';

export type PaymentMethod = 'cash' | 'card' | 'transfer' | 'mobile_money';

export type AddressType = 'home' | 'work' | 'other';


// ============================================================================
// Extended Types (with relationships and computed fields)
// ============================================================================

/**
 * Customer with loyalty and order stats
 */
export interface CustomerWithStats extends Customer {
  total_orders?: number;
  total_purchases?: number;
  last_order_date?: string;
  addresses?: CustomerAddress[];
}

/**
 * Order with customer and items
 */
export interface OrderDetail extends Order {
  customer?: Pick<Customer, 'id' | 'full_name' | 'email' | 'phone'>;
  items?: OrderItemDetail[];
  delivery_address?: CustomerAddress;
}

/**
 * Order item with product details
 */
export interface OrderItemDetail extends OrderItem {
  product?: Pick<Product, 'id' | 'name' | 'sku' | 'image_url' | 'category'>;
}

/**
 * Marketplace product (public-facing)
 */
export interface MarketplaceProduct {
  id: string;
  inventory_id?: string; // Reference to specific branch_inventory record
  tenant_id: string;
  branch_id: string;
  name: string;
  description?: string;
  sku: string;
  category?: string;
  price: number; // Final effective price (original or sale)
  selling_price?: number; // Original strike-through price
  sale_price?: number; // Discounted price
  percentage_discount?: number; // Badge value
  image_url?: string;
  stock_quantity: number;
  is_available: boolean;
  business_name?: string;
  rating?: number; // Optional display rating (0–5), not stored in DB
  generic_name?: string;
  strength?: string;
  dosage_form?: string;
  product_side_effect?: string;
  interactions?: string;
  product_details?: string;
}

/**
 * Shopping cart item
 */
export interface CartItem {
  product_id: string;
  product_name: string;
  product_image?: string;
  price: number;
  selling_price?: number; // Original price for display
  quantity: number;
  subtotal: number;
  stock_available: number;
}

/**
 * Shopping cart
 */
export interface Cart {
  tenant_id: string;
  items: CartItem[];
  subtotal: number;
  tax: number;
  delivery_fee: number;
  total: number;
}

/**
 * Customer purchase history item
 */
export interface PurchaseHistoryItem {
  order_id: string;
  order_date: string;
  total_amount: number;
  items_count: number;
  status: OrderStatus;
}

// ============================================================================
// API Request/Response Types
// ============================================================================

/**
 * Customer registration request
 */
export interface CustomerRegistrationRequest {
  full_name: string;
  email?: string;
  phone: string;
  password?: string; // Optional for phone-only registration
}

/**
 * Customer authentication request (OTP)
 */
export interface CustomerAuthRequest {
  phone?: string;
  email?: string;
  otp_code?: string; // For verification
}

/**
 * Customer authentication response
 */
export interface CustomerAuthResponse {
  customer_id: string;
  session_token: string;
  expires_at: string;
}

/**
 * Add address request
 */
export interface AddAddressRequest {
  address_line1: string;
  address_line2?: string;
  city: string;
  state?: string;
  postal_code?: string;
  country: string;
  type: AddressType;
  is_default: boolean;
}

/**
 * Marketplace filters
 */
export interface MarketplaceFilters {
  category?: string;
  search?: string;
  min_price?: number;
  max_price?: number;
  in_stock_only?: boolean;
  branch_id?: string;
  sort_by?: 'price_asc' | 'price_desc' | 'name' | 'newest';
  page?: number;
  limit?: number;
}

/**
 * Marketplace product list response
 */
export interface MarketplaceProductListResponse {
  products: MarketplaceProduct[];
  pagination: {
    page: number;
    limit: number;
    total: number;
    pages: number;
  };
}

/**
 * Create order request
 */
export interface CreateOrderRequest {
  customer_id: string;
  tenant_id: string;
  branch_id: string;
  items: Array<{
    product_id: string;
    quantity: number;
    unit_price: number;
  }>;
  order_type: OrderType;
  delivery_address_id?: string; // Required for delivery orders
  payment_method: PaymentMethod;
  notes?: string;
}

/**
 * Create order response
 */
export interface CreateOrderResponse {
  order_id: string;
  order_number: string;
  total_amount: number;
  payment_url?: string; // For card/online payments
  tracking_url: string;
}

/**
 * Order tracking response
 */
export interface OrderTrackingResponse {
  order: OrderDetail;
  status_history: Array<{
    status: OrderStatus;
    timestamp: string;
    note?: string;
  }>;
  estimated_delivery?: string;
  tracking_number?: string;
}

/**
 * Update order status request
 */
export interface UpdateOrderStatusRequest {
  status: OrderStatus;
  note?: string;
}


// ============================================================================
// Service Types
// ============================================================================


/**
 * Inventory check result
 */
export interface InventoryCheckResult {
  product_id: string;
  requested_quantity: number;
  available_quantity: number;
  is_available: boolean;
}

/**
 * Order fulfillment result
 */
export interface OrderFulfillmentResult {
  order_id: string;
  fulfilled: boolean;
  items_fulfilled: number;
  items_failed: number;
  inventory_deductions: Array<{
    product_id: string;
    quantity: number;
    success: boolean;
  }>;
}

// ============================================================================
// Error Types
// ============================================================================

export interface EcommerceAPIError {
  code: string;
  message: string;
  action?: string;
}

export type EcommerceErrorCode =
  | 'CUSTOMER_NOT_FOUND'
  | 'INVALID_OTP'
  | 'PRODUCT_OUT_OF_STOCK'
  | 'INSUFFICIENT_STOCK'
  | 'INVALID_ADDRESS'
  | 'INVALID_PAYMENT_METHOD'
  | 'ORDER_NOT_FOUND'
  | 'ORDER_NOT_FOUND'
  | 'CART_EMPTY'
  | 'TENANT_NOT_FOUND'
  | 'UNAUTHORIZED'
  | 'VALIDATION_ERROR';

// ============================================================================
// UI State Types
// ============================================================================

/**
 * Cart UI state
 */
export interface CartState {
  items: CartItem[];
  is_loading: boolean;
  error?: string;
}

/**
 * Checkout UI state
 */
export interface CheckoutState {
  cart: Cart;
  customer?: Customer;
  selected_address?: CustomerAddress;
  selected_payment_method?: PaymentMethod;
  order_type: OrderType;
  is_submitting: boolean;
  error?: string;
}

/**
 * Order tracking UI state
 */
export interface OrderTrackingState {
  order?: OrderDetail;
  status_history: Array<{
    status: OrderStatus;
    timestamp: string;
    note?: string;
  }>;
  is_loading: boolean;
  error?: string;
}

// ============================================================================
// Helper Types
// ============================================================================

/**
 * Pagination parameters
 */
export interface PaginationParams {
  page: number;
  limit: number;
}

/**
 * Sort parameters
 */
export interface SortParams {
  field: string;
  direction: 'asc' | 'desc';
}

/**
 * Date range filter
 */
export interface DateRangeFilter {
  start_date: string; // YYYY-MM-DD
  end_date: string; // YYYY-MM-DD
}

/**
 * Distance calculation (for delivery)
 */
export interface DistanceCalculation {
  distance_km: number;
  within_threshold: boolean;
  delivery_fee: number;
}
