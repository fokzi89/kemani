// Loyalty Points Service
// Feature: 001-multi-tenant-pos (User Story 3)
// Handles loyalty points calculation, earning, and redemption (1 point per ₦100 spent)

import type { SupabaseClient } from '@supabase/supabase-js';
import type {
  LoyaltyCalculation,
  LoyaltyPointsResponse,
  LOYALTY_POINTS_MULTIPLIER
} from '../types/ecommerce';

export class LoyaltyService {
  private readonly POINTS_PER_NAIRA = 0.01; // 1 point per ₦100
  private readonly NAIRA_PER_POINT = 100; // ₦100 = 1 point

  constructor(private supabase: SupabaseClient) {}

  /**
   * Calculate loyalty points earned for an order amount
   * Rule: 1 point per ₦100 spent
   */
  calculatePointsEarned(orderAmount: number): LoyaltyCalculation {
    const pointsEarned = Math.floor(orderAmount * this.POINTS_PER_NAIRA);

    return {
      points_earned: pointsEarned,
      order_amount: orderAmount,
      multiplier: this.POINTS_PER_NAIRA
    };
  }

  /**
   * Calculate Naira value of loyalty points
   */
  calculatePointsValue(points: number): number {
    return points * this.NAIRA_PER_POINT;
  }

  /**
   * Award loyalty points to customer
   */
  async awardPoints(
    customerId: string,
    points: number,
    orderId: string
  ): Promise<{ success: boolean; new_balance?: number; error?: string }> {
    try {
      // Get current customer
      const { data: customer, error: fetchError } = await this.supabase
        .from('customers')
        .select('loyalty_points')
        .eq('id', customerId)
        .single();

      if (fetchError) {
        return { success: false, error: fetchError.message };
      }

      const newBalance = (customer.loyalty_points || 0) + points;

      // Update customer loyalty points
      const { error: updateError } = await this.supabase
        .from('customers')
        .update({ loyalty_points: newBalance })
        .eq('id', customerId);

      if (updateError) {
        return { success: false, error: updateError.message };
      }

      // Create loyalty transaction record (if table exists)
      await this.supabase.from('loyalty_transactions').insert({
        customer_id: customerId,
        order_id: orderId,
        points: points,
        transaction_type: 'earned',
        balance_after: newBalance
      });

      return { success: true, new_balance: newBalance };
    } catch (error: any) {
      return { success: false, error: error.message || 'Failed to award points' };
    }
  }

  /**
   * Redeem loyalty points (deduct from customer balance)
   */
  async redeemPoints(
    customerId: string,
    pointsToRedeem: number,
    orderId: string
  ): Promise<{ success: boolean; new_balance?: number; naira_value?: number; error?: string }> {
    try {
      // Get current customer
      const { data: customer, error: fetchError } = await this.supabase
        .from('customers')
        .select('loyalty_points')
        .eq('id', customerId)
        .single();

      if (fetchError) {
        return { success: false, error: fetchError.message };
      }

      const currentBalance = customer.loyalty_points || 0;

      // Check if customer has enough points
      if (currentBalance < pointsToRedeem) {
        return {
          success: false,
          error: `Insufficient loyalty points. Current balance: ${currentBalance}, Requested: ${pointsToRedeem}`
        };
      }

      const newBalance = currentBalance - pointsToRedeem;
      const nairaValue = this.calculatePointsValue(pointsToRedeem);

      // Update customer loyalty points
      const { error: updateError } = await this.supabase
        .from('customers')
        .update({ loyalty_points: newBalance })
        .eq('id', customerId);

      if (updateError) {
        return { success: false, error: updateError.message };
      }

      // Create loyalty transaction record (if table exists)
      await this.supabase.from('loyalty_transactions').insert({
        customer_id: customerId,
        order_id: orderId,
        points: -pointsToRedeem,
        transaction_type: 'redeemed',
        balance_after: newBalance
      });

      return { success: true, new_balance: newBalance, naira_value: nairaValue };
    } catch (error: any) {
      return { success: false, error: error.message || 'Failed to redeem points' };
    }
  }

  /**
   * Get customer loyalty points balance
   */
  async getPointsBalance(customerId: string): Promise<{
    balance?: LoyaltyPointsResponse;
    error?: string;
  }> {
    try {
      const { data: customer, error } = await this.supabase
        .from('customers')
        .select('loyalty_points')
        .eq('id', customerId)
        .single();

      if (error) {
        return { error: error.message };
      }

      const pointsBalance = customer.loyalty_points || 0;
      const pointsValue = this.calculatePointsValue(pointsBalance);

      // Get lifetime points from loyalty transactions (if table exists)
      const { data: transactions } = await this.supabase
        .from('loyalty_transactions')
        .select('points')
        .eq('customer_id', customerId)
        .eq('transaction_type', 'earned');

      const lifetimePoints = transactions
        ? transactions.reduce((sum, t) => sum + (t.points || 0), 0)
        : pointsBalance;

      const balance: LoyaltyPointsResponse = {
        customer_id: customerId,
        points_balance: pointsBalance,
        points_value_naira: pointsValue,
        lifetime_points: lifetimePoints,
        points_expiring_soon: [] // Not implementing expiration in MVP
      };

      return { balance };
    } catch (error: any) {
      return { error: error.message || 'Failed to fetch loyalty balance' };
    }
  }

  /**
   * Get loyalty transaction history
   */
  async getTransactionHistory(
    customerId: string,
    limit = 50
  ): Promise<{
    transactions: Array<{
      id: string;
      points: number;
      transaction_type: 'earned' | 'redeemed';
      order_id?: string;
      balance_after: number;
      created_at: string;
    }>;
    error?: string;
  }> {
    try {
      const { data: transactions, error } = await this.supabase
        .from('loyalty_transactions')
        .select('*')
        .eq('customer_id', customerId)
        .order('created_at', { ascending: false })
        .limit(limit);

      if (error) {
        return { transactions: [], error: error.message };
      }

      return { transactions: transactions || [] };
    } catch (error: any) {
      return { transactions: [], error: error.message || 'Failed to fetch transaction history' };
    }
  }

  /**
   * Validate points redemption for an order
   */
  async validateRedemption(
    customerId: string,
    pointsToRedeem: number,
    orderTotal: number
  ): Promise<{
    valid: boolean;
    discount_amount?: number;
    error?: string;
  }> {
    try {
      // Get customer balance
      const { balance, error } = await this.getPointsBalance(customerId);

      if (error || !balance) {
        return { valid: false, error: error || 'Failed to fetch balance' };
      }

      // Check if customer has enough points
      if (balance.points_balance < pointsToRedeem) {
        return {
          valid: false,
          error: `Insufficient points. You have ${balance.points_balance} points, but trying to redeem ${pointsToRedeem}.`
        };
      }

      // Calculate discount amount
      const discountAmount = this.calculatePointsValue(pointsToRedeem);

      // Check if discount exceeds order total (optional business rule)
      if (discountAmount > orderTotal) {
        return {
          valid: false,
          error: `Points value (₦${discountAmount}) exceeds order total (₦${orderTotal})`
        };
      }

      return { valid: true, discount_amount: discountAmount };
    } catch (error: any) {
      return { valid: false, error: error.message || 'Failed to validate redemption' };
    }
  }

  /**
   * Get points earning rate information
   */
  getEarningRate(): {
    points_per_naira: number;
    naira_per_point: number;
    description: string;
  } {
    return {
      points_per_naira: this.POINTS_PER_NAIRA,
      naira_per_point: this.NAIRA_PER_POINT,
      description: 'Earn 1 loyalty point for every ₦100 spent'
    };
  }
}
