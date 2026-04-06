import { describe, it, expect, beforeAll } from 'vitest';
import { CommissionCalculator, roundCurrency } from '$lib/services/commissionCalculator';
import type { CommissionCalculation } from '$lib/types/commission';

/**
 * Commission Calculation Tests
 * Feature: 004-tenant-referral-commissions
 * User Story 2: Accurate Commission Calculation
 *
 * Constitutional Requirement: SC-002 (100% commission accuracy)
 *
 * Tests verify:
 * - Service commission with referrer (90/10/10 split)
 * - Service commission without referrer (90/0/20 split)
 * - Product commission with referrer (94/4.5/1.5 split)
 * - Product commission without referrer (94/0/1.5% + ₦100 split)
 * - Currency rounding correctness
 * - Commission balance verification
 */

describe('Currency Rounding', () => {
  it('rounds to 2 decimal places correctly', () => {
    expect(roundCurrency(10.123)).toBe(10.12);
    expect(roundCurrency(10.126)).toBe(10.13);
    expect(roundCurrency(10.125)).toBe(10.13); // Banker's rounding
    expect(roundCurrency(10.115)).toBe(10.12);
  });

  it('handles edge cases', () => {
    expect(roundCurrency(0)).toBe(0);
    expect(roundCurrency(0.001)).toBe(0);
    expect(roundCurrency(0.009)).toBe(0.01);
    expect(roundCurrency(999999.999)).toBe(1000000);
  });
});

describe('Service Commission - With Referrer', () => {
  it('T060: calculates correctly for ₦1,000 base', async () => {
    const result = await CommissionCalculator.calculateServiceCommission(1000, true);

    expect(result).not.toBeNull();
    expect(result?.customer_pays).toBe(1100); // 10% markup
    expect(result?.provider_gets).toBe(900); // 90%
    expect(result?.referrer_gets).toBe(100); // 10%
    expect(result?.platform_gets).toBe(100); // 10%
  });

  it('verifies totals balance', async () => {
    const result = await CommissionCalculator.calculateServiceCommission(1000, true);

    expect(result).not.toBeNull();
    if (result) {
      const isBalanced = CommissionCalculator.verifyBalance(result);
      expect(isBalanced).toBe(true);
    }
  });

  it('T060: handles large amounts (₦50,000)', async () => {
    const result = await CommissionCalculator.calculateServiceCommission(50000, true);

    expect(result).not.toBeNull();
    expect(result?.customer_pays).toBe(55000);
    expect(result?.provider_gets).toBe(45000);
    expect(result?.referrer_gets).toBe(5000);
    expect(result?.platform_gets).toBe(5000);
  });

  it('T060: handles decimal amounts (₦99.50)', async () => {
    const result = await CommissionCalculator.calculateServiceCommission(99.5, true);

    expect(result).not.toBeNull();
    expect(result?.customer_pays).toBe(109.45);
    expect(result?.provider_gets).toBe(89.55);
    expect(result?.referrer_gets).toBe(9.95);
    expect(result?.platform_gets).toBe(9.95);
  });
});

describe('Service Commission - Without Referrer', () => {
  it('T061: calculates correctly for ₦1,000 base', async () => {
    const result = await CommissionCalculator.calculateServiceCommission(1000, false);

    expect(result).not.toBeNull();
    expect(result?.customer_pays).toBe(1100); // Same 10% markup
    expect(result?.provider_gets).toBe(900); // 90%
    expect(result?.referrer_gets).toBe(0); // No referrer
    expect(result?.platform_gets).toBe(200); // Platform gets double (20%)
  });

  it('T061: platform gets exactly double share', async () => {
    const withReferrer = await CommissionCalculator.calculateServiceCommission(1000, true);
    const withoutReferrer = await CommissionCalculator.calculateServiceCommission(1000, false);

    expect(withReferrer).not.toBeNull();
    expect(withoutReferrer).not.toBeNull();

    if (withReferrer && withoutReferrer) {
      expect(withoutReferrer.platform_gets).toBe(withReferrer.platform_gets * 2);
      expect(withoutReferrer.referrer_gets).toBe(0);
    }
  });

  it('T061: customer pays same with or without referrer', async () => {
    const withReferrer = await CommissionCalculator.calculateServiceCommission(1000, true);
    const withoutReferrer = await CommissionCalculator.calculateServiceCommission(1000, false);

    expect(withReferrer).not.toBeNull();
    expect(withoutReferrer).not.toBeNull();

    if (withReferrer && withoutReferrer) {
      expect(withReferrer.customer_pays).toBe(withoutReferrer.customer_pays);
    }
  });
});

describe('Product Commission - With Referrer', () => {
  it('T062: calculates correctly for ₦5,000 product', async () => {
    const result = await CommissionCalculator.calculateProductCommission(5000, true);

    expect(result).not.toBeNull();
    expect(result?.customer_pays).toBe(5000); // No markup
    expect(result?.provider_gets).toBe(4700); // 94%
    expect(result?.referrer_gets).toBe(225); // 4.5%
    expect(result?.platform_gets).toBe(75); // 1.5%
  });

  it('T062: no markup applied', async () => {
    const result = await CommissionCalculator.calculateProductCommission(5000, true);

    expect(result).not.toBeNull();
    if (result) {
      // Customer pays exactly the product price
      expect(result.customer_pays).toBe(5000);
    }
  });

  it('T062: percentages sum to 100%', async () => {
    const result = await CommissionCalculator.calculateProductCommission(5000, true);

    expect(result).not.toBeNull();
    if (result) {
      const total = result.provider_gets + result.referrer_gets + result.platform_gets;
      expect(roundCurrency(total)).toBe(result.customer_pays);
    }
  });

  it('T062: handles large amounts (₦100,000)', async () => {
    const result = await CommissionCalculator.calculateProductCommission(100000, true);

    expect(result).not.toBeNull();
    expect(result?.customer_pays).toBe(100000);
    expect(result?.provider_gets).toBe(94000);
    expect(result?.referrer_gets).toBe(4500);
    expect(result?.platform_gets).toBe(1500);
  });
});

describe('Product Commission - Without Referrer', () => {
  it('T063: calculates correctly for ₦5,000 product', async () => {
    const result = await CommissionCalculator.calculateProductCommission(5000, false);

    expect(result).not.toBeNull();
    expect(result?.customer_pays).toBe(5100); // ₦100 fixed charge
    expect(result?.provider_gets).toBe(4700); // 94%
    expect(result?.referrer_gets).toBe(0); // No referrer
    expect(result?.platform_gets).toBe(175); // 1.5% + ₦100 = ₦75 + ₦100
  });

  it('T063: applies ₦100 fixed charge', async () => {
    const result = await CommissionCalculator.calculateProductCommission(5000, false);

    expect(result).not.toBeNull();
    if (result) {
      expect(result.customer_pays).toBe(5100);
      expect(result.customer_pays - 5000).toBe(100);
    }
  });

  it('T063: customer pays more without referrer', async () => {
    const withReferrer = await CommissionCalculator.calculateProductCommission(5000, true);
    const withoutReferrer = await CommissionCalculator.calculateProductCommission(5000, false);

    expect(withReferrer).not.toBeNull();
    expect(withoutReferrer).not.toBeNull();

    if (withReferrer && withoutReferrer) {
      expect(withoutReferrer.customer_pays).toBeGreaterThan(withReferrer.customer_pays);
      expect(withoutReferrer.customer_pays - withReferrer.customer_pays).toBe(100);
    }
  });

  it('T063: platform gets 1.5% + ₦100', async () => {
    const result = await CommissionCalculator.calculateProductCommission(5000, false);

    expect(result).not.toBeNull();
    if (result) {
      const expectedPlatform = 5000 * 0.015 + 100;
      expect(result.platform_gets).toBe(roundCurrency(expectedPlatform));
    }
  });
});

describe('Unified Calculate Method', () => {
  it('routes consultations to service commission', async () => {
    const result = await CommissionCalculator.calculate({
      transaction_type: 'consultation',
      base_price: 1000,
      has_referrer: true
    });

    expect(result).not.toBeNull();
    expect(result?.formula_used).toBe('service_commission');
    expect(result?.markup_applied).toBe(true);
    expect(result?.markup_percentage).toBe(10);
  });

  it('routes diagnostic tests to service commission', async () => {
    const result = await CommissionCalculator.calculate({
      transaction_type: 'diagnostic_test',
      base_price: 5000,
      has_referrer: true
    });

    expect(result).not.toBeNull();
    expect(result?.formula_used).toBe('service_commission');
  });

  it('routes product sales to product commission', async () => {
    const result = await CommissionCalculator.calculate({
      transaction_type: 'product_sale',
      base_price: 5000,
      has_referrer: true
    });

    expect(result).not.toBeNull();
    expect(result?.formula_used).toBe('product_commission');
    expect(result?.markup_applied).toBe(false);
  });

  it('rejects invalid base prices', async () => {
    const result = await CommissionCalculator.calculate({
      transaction_type: 'consultation',
      base_price: 0,
      has_referrer: true
    });

    expect(result).toBeNull();
  });
});

describe('Cart Calculation', () => {
  it('T064: calculates multi-item cart correctly', async () => {
    const items = [
      { type: 'consultation' as const, price: 1000 },
      { type: 'product_sale' as const, price: 5000 },
      { type: 'diagnostic_test' as const, price: 5000 }
    ];

    const result = await CommissionCalculator.calculateCart(items, true);

    expect(result).not.toBeNull();
    if (result) {
      // Consultation: 1100, Product: 5000, Test: 5500
      expect(result.total_customer_pays).toBe(11600);

      // Verify breakdown
      expect(result.item_breakdowns.length).toBe(3);

      // Verify totals match sum of items
      const manualTotal = result.item_breakdowns.reduce(
        (sum, item) => sum + item.customer_pays,
        0
      );
      expect(result.total_customer_pays).toBe(roundCurrency(manualTotal));
    }
  });

  it('T064: aggregates referrer commission correctly', async () => {
    const items = [
      { type: 'consultation' as const, price: 1000 }, // ₦100 referrer
      { type: 'product_sale' as const, price: 5000 } // ₦225 referrer
    ];

    const result = await CommissionCalculator.calculateCart(items, true);

    expect(result).not.toBeNull();
    if (result) {
      expect(result.total_referrer_gets).toBe(325); // ₦100 + ₦225
    }
  });

  it('T064: handles cart without referrer', async () => {
    const items = [{ type: 'product_sale' as const, price: 5000 }];

    const result = await CommissionCalculator.calculateCart(items, false);

    expect(result).not.toBeNull();
    if (result) {
      expect(result.total_referrer_gets).toBe(0);
      expect(result.total_customer_pays).toBe(5100); // ₦100 fixed charge
    }
  });
});

describe('T065: Property-Based Tests - Totals Always Balance', () => {
  const testCases = [
    { price: 100, type: 'consultation' as const },
    { price: 1000, type: 'consultation' as const },
    { price: 5000, type: 'product_sale' as const },
    { price: 10000, type: 'diagnostic_test' as const },
    { price: 99.99, type: 'product_sale' as const },
    { price: 50000, type: 'consultation' as const }
  ];

  testCases.forEach(({ price, type }) => {
    it(`totals balance for ${type} at ₦${price} (with referrer)`, async () => {
      const result = await CommissionCalculator.calculate({
        transaction_type: type,
        base_price: price,
        has_referrer: true
      });

      expect(result).not.toBeNull();
      if (result) {
        const total = roundCurrency(
          result.breakdown.provider_gets +
            result.breakdown.referrer_gets +
            result.breakdown.platform_gets
        );
        const difference = Math.abs(total - result.customer_pays);
        expect(difference).toBeLessThan(0.01); // Within 1 cent
      }
    });

    it(`totals balance for ${type} at ₦${price} (without referrer)`, async () => {
      const result = await CommissionCalculator.calculate({
        transaction_type: type,
        base_price: price,
        has_referrer: false
      });

      expect(result).not.toBeNull();
      if (result) {
        const total = roundCurrency(
          result.breakdown.provider_gets +
            result.breakdown.referrer_gets +
            result.breakdown.platform_gets
        );
        const difference = Math.abs(total - result.customer_pays);
        expect(difference).toBeLessThan(0.01);
      }
    });
  });
});
