// Transaction Group Service
// Feature: 004-tenant-referral-commissions
// Handles grouping of multiple transactions in a single checkout session

import { supabase } from '$lib/supabase';
import type { TransactionType } from '$lib/types/commission';

/**
 * TransactionGroup represents a cart/checkout session
 * All transactions in the same group share:
 * - Same group_id (UUID)
 * - Same referring_tenant_id (from session)
 * - Same customer_id
 * - Processed together in payment webhook
 */

export interface CartItem {
  type: TransactionType;
  base_price: number;
  provider_tenant_id: string;
  metadata?: Record<string, any>;
}

export interface TransactionGroupMetadata {
  group_id: string;
  customer_id: string;
  referring_tenant_id: string | null;
  created_at: string;
  items: CartItem[];
  total_base_price: number;
  total_final_price: number;
}

/**
 * TransactionGroupService
 * Manages transaction groups for multi-service checkouts
 */
export class TransactionGroupService {
  /**
   * Generate a unique group ID for a checkout session
   * @returns UUID string
   */
  static generateGroupId(): string {
    return crypto.randomUUID();
  }

  /**
   * Create transaction records for all items in cart
   * All transactions share the same group_id
   *
   * @param customerId - Customer making the purchase
   * @param referringTenantId - Referring tenant from session (null if none)
   * @param items - Array of cart items
   * @returns Array of created transaction records with group_id
   */
  static async createTransactionGroup(
    customerId: string,
    referringTenantId: string | null,
    items: CartItem[]
  ): Promise<{ group_id: string; transactions: any[] } | null> {
    if (items.length === 0) {
      console.error('Cannot create transaction group with empty cart');
      return null;
    }

    const groupId = this.generateGroupId();

    try {
      // Prepare transaction records
      const transactionRecords = items.map((item) => ({
        group_id: groupId,
        type: item.type,
        provider_tenant_id: item.provider_tenant_id,
        customer_id: customerId,
        referring_tenant_id: referringTenantId,
        base_price: item.base_price,
        final_price_paid: 0, // Will be calculated and updated after commission calc
        payment_status: 'pending',
        payment_reference: null
      }));

      // Insert all transactions in a single batch
      const { data, error } = await supabase
        .from('transactions')
        .insert(transactionRecords)
        .select();

      if (error) {
        console.error('Error creating transaction group:', error);
        return null;
      }

      console.log(`Created transaction group ${groupId} with ${data.length} transactions`);

      return {
        group_id: groupId,
        transactions: data
      };
    } catch (err) {
      console.error('Exception creating transaction group:', err);
      return null;
    }
  }

  /**
   * Get all transactions in a group
   * @param groupId - Group ID to query
   * @returns Array of transactions
   */
  static async getTransactionsByGroup(groupId: string): Promise<any[] | null> {
    try {
      const { data, error } = await supabase
        .from('transactions')
        .select('*')
        .eq('group_id', groupId)
        .order('created_at', { ascending: true });

      if (error) {
        console.error('Error fetching transaction group:', error);
        return null;
      }

      return data;
    } catch (err) {
      console.error('Exception fetching transaction group:', err);
      return null;
    }
  }

  /**
   * Get commission records for all transactions in a group
   * @param groupId - Group ID to query
   * @returns Array of commission records
   */
  static async getCommissionsByGroup(groupId: string): Promise<any[] | null> {
    try {
      // First get all transactions in the group
      const transactions = await this.getTransactionsByGroup(groupId);
      if (!transactions || transactions.length === 0) {
        return null;
      }

      const transactionIds = transactions.map((t) => t.id);

      // Get commissions for these transactions
      const { data, error } = await supabase
        .from('commissions')
        .select('*')
        .in('transaction_id', transactionIds)
        .order('created_at', { ascending: true });

      if (error) {
        console.error('Error fetching commissions for group:', error);
        return null;
      }

      return data;
    } catch (err) {
      console.error('Exception fetching commissions for group:', err);
      return null;
    }
  }

  /**
   * Calculate total commission for a referrer across all transactions in group
   * @param groupId - Group ID to aggregate
   * @returns Total referrer commission or null
   */
  static async calculateGroupReferrerTotal(groupId: string): Promise<number | null> {
    try {
      const commissions = await this.getCommissionsByGroup(groupId);
      if (!commissions || commissions.length === 0) {
        return null;
      }

      const total = commissions.reduce((sum, commission) => {
        return sum + (commission.referrer_amount || 0);
      }, 0);

      // Round to 2 decimal places
      return Math.round(total * 100) / 100;
    } catch (err) {
      console.error('Exception calculating group referrer total:', err);
      return null;
    }
  }

  /**
   * Verify all transactions in a group have the same referring_tenant_id
   * Important for ensuring commission attribution is consistent
   *
   * @param groupId - Group ID to verify
   * @returns True if all transactions have same referrer (or all null)
   */
  static async verifyGroupReferrerConsistency(groupId: string): Promise<boolean> {
    try {
      const transactions = await this.getTransactionsByGroup(groupId);
      if (!transactions || transactions.length === 0) {
        return false;
      }

      // Get unique referring_tenant_ids
      const referrers = new Set(
        transactions.map((t) => t.referring_tenant_id).filter((id) => id !== null)
      );

      // Check if all null or all the same
      if (referrers.size === 0) {
        // All null - consistent (no referrer)
        return true;
      }

      if (referrers.size === 1) {
        // All same referrer - consistent
        return true;
      }

      // Mixed referrers - inconsistent
      console.warn(`Group ${groupId} has inconsistent referrers:`, Array.from(referrers));
      return false;
    } catch (err) {
      console.error('Exception verifying group consistency:', err);
      return false;
    }
  }

  /**
   * Update all transactions in a group to completed status
   * Called after successful payment processing
   *
   * @param groupId - Group ID to update
   * @param paymentReference - Payment reference from gateway
   * @returns Success boolean
   */
  static async markGroupAsCompleted(
    groupId: string,
    paymentReference: string
  ): Promise<boolean> {
    try {
      const { error } = await supabase
        .from('transactions')
        .update({
          payment_status: 'completed',
          paid_at: new Date().toISOString(),
          payment_reference: paymentReference
        })
        .eq('group_id', groupId)
        .eq('payment_status', 'pending'); // Only update pending transactions

      if (error) {
        console.error('Error marking group as completed:', error);
        return false;
      }

      return true;
    } catch (err) {
      console.error('Exception marking group as completed:', err);
      return false;
    }
  }

  /**
   * Get group metadata summary
   * Useful for checkout confirmation pages
   *
   * @param groupId - Group ID to summarize
   * @returns Summary metadata
   */
  static async getGroupSummary(groupId: string): Promise<{
    group_id: string;
    transaction_count: number;
    total_customer_paid: number;
    total_referrer_commission: number;
    has_referrer: boolean;
    payment_status: string;
  } | null> {
    try {
      const transactions = await this.getTransactionsByGroup(groupId);
      if (!transactions || transactions.length === 0) {
        return null;
      }

      const commissions = await this.getCommissionsByGroup(groupId);

      const totalCustomerPaid = transactions.reduce(
        (sum, t) => sum + parseFloat(t.final_price_paid || 0),
        0
      );

      const totalReferrerCommission = commissions
        ? commissions.reduce((sum, c) => sum + (c.referrer_amount || 0), 0)
        : 0;

      const hasReferrer = transactions[0]?.referring_tenant_id !== null;
      const paymentStatus = transactions[0]?.payment_status || 'unknown';

      return {
        group_id: groupId,
        transaction_count: transactions.length,
        total_customer_paid: Math.round(totalCustomerPaid * 100) / 100,
        total_referrer_commission: Math.round(totalReferrerCommission * 100) / 100,
        has_referrer: hasReferrer,
        payment_status: paymentStatus
      };
    } catch (err) {
      console.error('Exception getting group summary:', err);
      return null;
    }
  }
}
