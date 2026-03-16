// Commission Calculator Service
// Feature: 004-tenant-referral-commissions
// Handles commission calculation for transactions

import { supabase } from '$lib/supabase';
import type {
  CommissionCalculation,
  CommissionCalculationRequest,
  CommissionCalculationResponse,
  TransactionType
} from '$lib/types/commission';

/**
 * Round to 2 decimal places to avoid floating point precision errors
 * Uses banker's rounding (round half to even)
 */
export function roundCurrency(amount: number): number {
  return Math.round(amount * 100) / 100;
}

/**
 * CommissionCalculator Service
 * Calculates commission breakdowns for transactions
 */
export class CommissionCalculator {
  /**
   * Calculate service commission (consultation, diagnostic_test)
   * Formula:
   *   - With referrer: 10% markup, 90/10/10 split (provider/referrer/platform)
   *   - Without referrer: 10% markup, 90/0/20 split (platform gets double)
   *
   * @param basePrice - Base price of the service
   * @param hasReferrer - Whether transaction has a referring tenant
   * @returns Commission breakdown
   */
  static async calculateServiceCommission(
    basePrice: number,
    hasReferrer: boolean
  ): Promise<CommissionCalculation | null> {
    try {
      const { data, error } = await supabase.rpc('calculate_service_commission', {
        base_price: basePrice,
        has_referrer: hasReferrer
      });

      if (error) {
        console.error('Error calculating service commission:', error);
        return null;
      }

      if (!data || data.length === 0) {
        console.error('No data returned from calculate_service_commission');
        return null;
      }

      // Database function returns array with single row
      const result = data[0];

      return {
        customer_pays: roundCurrency(result.customer_pays),
        provider_gets: roundCurrency(result.provider_gets),
        referrer_gets: roundCurrency(result.referrer_gets),
        platform_gets: roundCurrency(result.platform_gets)
      };
    } catch (err) {
      console.error('Exception calculating service commission:', err);
      return null;
    }
  }

  /**
   * Calculate product commission (product_sale)
   * Formula:
   *   - With referrer: No markup, 94/4.5/1.5 split (provider/referrer/platform)
   *   - Without referrer: ₦100 fixed charge, 94/0/(1.5% + ₦100) split
   *
   * @param productPrice - Product price
   * @param hasReferrer - Whether transaction has a referring tenant
   * @returns Commission breakdown
   */
  static async calculateProductCommission(
    productPrice: number,
    hasReferrer: boolean
  ): Promise<CommissionCalculation | null> {
    try {
      const { data, error } = await supabase.rpc('calculate_product_commission', {
        product_price: productPrice,
        has_referrer: hasReferrer
      });

      if (error) {
        console.error('Error calculating product commission:', error);
        return null;
      }

      if (!data || data.length === 0) {
        console.error('No data returned from calculate_product_commission');
        return null;
      }

      const result = data[0];

      return {
        customer_pays: roundCurrency(result.customer_pays),
        provider_gets: roundCurrency(result.provider_gets),
        referrer_gets: roundCurrency(result.referrer_gets),
        platform_gets: roundCurrency(result.platform_gets)
      };
    } catch (err) {
      console.error('Exception calculating product commission:', err);
      return null;
    }
  }

  /**
   * Calculate commission based on transaction type
   * Unified interface for any transaction type
   *
   * @param request - Calculation request with transaction details
   * @returns Detailed commission breakdown with metadata
   */
  static async calculate(
    request: CommissionCalculationRequest
  ): Promise<CommissionCalculationResponse | null> {
    const { transaction_type, base_price, has_referrer } = request;

    // Validate base price
    if (base_price <= 0) {
      console.error('Invalid base price:', base_price);
      return null;
    }

    let calculation: CommissionCalculation | null = null;
    let formulaUsed: 'service_commission' | 'product_commission';
    let markupApplied = false;
    let markupPercentage: number | undefined;

    // Route to appropriate calculation based on transaction type
    if (transaction_type === 'consultation' || transaction_type === 'diagnostic_test') {
      calculation = await this.calculateServiceCommission(base_price, has_referrer);
      formulaUsed = 'service_commission';
      markupApplied = true;
      markupPercentage = 10;
    } else if (transaction_type === 'product_sale') {
      calculation = await this.calculateProductCommission(base_price, has_referrer);
      formulaUsed = 'product_commission';
      markupApplied = !has_referrer; // Only markup when no referrer (₦100 fixed)
      markupPercentage = undefined;
    } else {
      console.error('Invalid transaction type:', transaction_type);
      return null;
    }

    if (!calculation) {
      return null;
    }

    return {
      transaction_type,
      base_price: roundCurrency(base_price),
      customer_pays: calculation.customer_pays,
      breakdown: {
        provider_gets: calculation.provider_gets,
        referrer_gets: calculation.referrer_gets,
        platform_gets: calculation.platform_gets
      },
      formula_used: formulaUsed,
      markup_applied: markupApplied,
      markup_percentage: markupPercentage
    };
  }

  /**
   * Verify commission totals balance
   * Ensures customer_pays = provider_gets + referrer_gets + platform_gets
   *
   * @param calculation - Commission calculation to verify
   * @returns True if balanced (within 1 cent tolerance)
   */
  static verifyBalance(calculation: CommissionCalculation): boolean {
    const total = roundCurrency(
      calculation.provider_gets + calculation.referrer_gets + calculation.platform_gets
    );
    const difference = Math.abs(total - calculation.customer_pays);

    // Allow 1 cent tolerance for rounding
    return difference < 0.01;
  }

  /**
   * Calculate commission for multiple items in a cart
   * Useful for checkout preview with multiple products/services
   *
   * @param items - Array of items with prices and types
   * @param hasReferrer - Whether session has a referrer
   * @returns Aggregated commission breakdown
   */
  static async calculateCart(
    items: Array<{ type: TransactionType; price: number }>,
    hasReferrer: boolean
  ): Promise<{
    total_customer_pays: number;
    total_provider_gets: number;
    total_referrer_gets: number;
    total_platform_gets: number;
    item_breakdowns: CommissionCalculationResponse[];
  } | null> {
    try {
      const breakdowns: CommissionCalculationResponse[] = [];

      // Calculate each item
      for (const item of items) {
        const breakdown = await this.calculate({
          transaction_type: item.type,
          base_price: item.price,
          has_referrer: hasReferrer
        });

        if (!breakdown) {
          console.error('Failed to calculate commission for item:', item);
          return null;
        }

        breakdowns.push(breakdown);
      }

      // Aggregate totals
      const totals = breakdowns.reduce(
        (acc, breakdown) => {
          acc.total_customer_pays += breakdown.customer_pays;
          acc.total_provider_gets += breakdown.breakdown.provider_gets;
          acc.total_referrer_gets += breakdown.breakdown.referrer_gets;
          acc.total_platform_gets += breakdown.breakdown.platform_gets;
          return acc;
        },
        {
          total_customer_pays: 0,
          total_provider_gets: 0,
          total_referrer_gets: 0,
          total_platform_gets: 0
        }
      );

      return {
        ...totals,
        total_customer_pays: roundCurrency(totals.total_customer_pays),
        total_provider_gets: roundCurrency(totals.total_provider_gets),
        total_referrer_gets: roundCurrency(totals.total_referrer_gets),
        total_platform_gets: roundCurrency(totals.total_platform_gets),
        item_breakdowns: breakdowns
      };
    } catch (err) {
      console.error('Exception calculating cart commission:', err);
      return null;
    }
  }
}
