// Multi-Tenant Referral Commission System - TypeScript Types
// Feature: 004-tenant-referral-commissions
// Auto-generated from database schema

/**
 * Commission status enum
 * Represents the lifecycle state of a commission record
 */
export type CommissionStatus = 'pending' | 'processed' | 'paid_out';

/**
 * Transaction type enum
 * Defines the type of transaction that generated a commission
 */
export type TransactionType = 'consultation' | 'product_sale' | 'diagnostic_test';

/**
 * Routing reason enum
 * Indicates how fulfillment was assigned to a tenant
 */
export type RoutingReason = 'pharmacy_referrer' | 'diagnostic_referrer' | 'customer_selected';

/**
 * Payment status enum
 * Tracks the payment state of a transaction
 */
export type PaymentStatus = 'pending' | 'completed' | 'failed' | 'refunded';

/**
 * Referral Session
 * Tracks which tenant's page a customer is currently browsing
 */
export interface ReferralSession {
  id: string;
  session_token: string;
  customer_id: string | null;
  referring_tenant_id: string;
  active: boolean;
  created_at: string;
  expires_at: string;
  last_activity_at: string;
}

/**
 * Transaction
 * Records customer purchases with pricing and referral attribution
 */
export interface Transaction {
  id: string;
  group_id: string;
  type: TransactionType;
  provider_tenant_id: string;
  customer_id: string;
  referring_tenant_id: string | null;
  base_price: number;
  final_price_paid: number;
  payment_status: PaymentStatus;
  payment_reference: string | null;
  created_at: string;
  paid_at: string | null;
}

/**
 * Commission
 * Records commission amounts earned/paid for each transaction
 */
export interface Commission {
  id: string;
  transaction_id: string;
  transaction_type: TransactionType;
  provider_tenant_id: string;
  referrer_tenant_id: string | null;
  customer_id: string;
  base_amount: number;
  customer_paid: number;
  provider_amount: number;
  referrer_amount: number | null;
  platform_amount: number;
  status: CommissionStatus;
  created_at: string;
  processed_at: string | null;
  paid_at: string | null;
  calculation_metadata: Record<string, any> | null;
}

/**
 * Fulfillment Routing
 * Tracks automatic routing of prescriptions and test requests
 */
export interface FulfillmentRouting {
  id: string;
  prescription_id: string | null;
  test_request_id: string | null;
  fulfilling_tenant_id: string;
  routing_reason: RoutingReason;
  created_at: string;
}

/**
 * Commission Calculation Result
 * Result of commission calculation functions
 */
export interface CommissionCalculation {
  customer_pays: number;
  provider_gets: number;
  referrer_gets: number;
  platform_gets: number;
}

/**
 * Commission Summary
 * Aggregated commission statistics for dashboard
 */
export interface CommissionSummary {
  total_earned: number;
  total_pending: number;
  total_processed: number;
  total_paid_out: number;
  transaction_count: number;
  avg_commission: number;
  by_transaction_type: {
    [key in TransactionType]?: {
      total: number;
      count: number;
      avg: number;
    };
  };
  by_status: {
    [key in CommissionStatus]?: {
      total: number;
      count: number;
    };
  };
  daily_trend: Array<{
    date: string;
    total_earned: number;
    count: number;
  }>;
}

/**
 * API Response wrapper
 * Standard response format for commission API endpoints
 */
export interface ApiResponse<T> {
  data: T;
  meta: {
    timestamp: string;
    request_id?: string;
    page?: number;
    per_page?: number;
    total?: number;
    total_pages?: number;
  };
}

/**
 * API Error response
 * Standard error format for commission API endpoints
 */
export interface ApiError {
  error: {
    code: string;
    message: string;
    details?: Record<string, any>;
  };
  meta: {
    timestamp: string;
    request_id?: string;
  };
}

/**
 * Commission calculation request payload
 * Used for preview calculations before checkout
 */
export interface CommissionCalculationRequest {
  transaction_type: TransactionType;
  base_price: number;
  has_referrer: boolean;
}

/**
 * Commission calculation response
 * Preview of commission breakdown
 */
export interface CommissionCalculationResponse {
  transaction_type: TransactionType;
  base_price: number;
  customer_pays: number;
  breakdown: {
    provider_gets: number;
    referrer_gets: number;
    platform_gets: number;
  };
  formula_used: 'service_commission' | 'product_commission';
  markup_applied: boolean;
  markup_percentage?: number;
}
