-- pgTAP Tests for Product Commission Calculation
-- Feature: 004-tenant-referral-commissions
-- Tests: calculate_product_commission function
-- Constitutional Requirement: SC-002 (100% commission accuracy)

BEGIN;

SELECT plan(22);

-- =============================================================================
-- TEST SUITE 1: Product Commission WITH Referrer
-- =============================================================================
-- Formula: No markup, 94/4.5/1.5 split (provider/referrer/platform)

-- Test 1.1: Basic calculation (₦5,000 product)
SELECT results_eq(
  $$SELECT customer_pays, provider_gets, referrer_gets, platform_gets
    FROM calculate_product_commission(5000.00, TRUE)$$,
  $$VALUES (5000.00::DECIMAL(12,2), 4700.00::DECIMAL(12,2), 225.00::DECIMAL(12,2), 75.00::DECIMAL(12,2))$$,
  'Product with referrer: ₦5,000 price → Customer pays ₦5,000, Provider ₦4,700, Referrer ₦225, Platform ₦75'
);

-- Test 1.2: Verify totals balance (customer_pays = provider + referrer + platform)
SELECT is(
  (SELECT customer_pays FROM calculate_product_commission(5000.00, TRUE)),
  (SELECT provider_gets + referrer_gets + platform_gets FROM calculate_product_commission(5000.00, TRUE)),
  'Product with referrer: Totals balance (₦5,000 = ₦4,700 + ₦225 + ₦75)'
);

-- Test 1.3: No markup applied (customer pays product price)
SELECT is(
  (SELECT customer_pays FROM calculate_product_commission(5000.00, TRUE)),
  5000.00::DECIMAL(12,2),
  'Product with referrer: No markup (customer pays exactly product price)'
);

-- Test 1.4: Provider gets 94% of product price
SELECT is(
  (SELECT provider_gets FROM calculate_product_commission(5000.00, TRUE)),
  5000.00 * 0.94,
  'Product with referrer: Provider gets 94% of product price'
);

-- Test 1.5: Referrer gets 4.5% of product price
SELECT is(
  (SELECT referrer_gets FROM calculate_product_commission(5000.00, TRUE)),
  5000.00 * 0.045,
  'Product with referrer: Referrer gets 4.5% of product price'
);

-- Test 1.6: Platform gets 1.5% of product price
SELECT is(
  (SELECT platform_gets FROM calculate_product_commission(5000.00, TRUE)),
  5000.00 * 0.015,
  'Product with referrer: Platform gets 1.5% of product price'
);

-- Test 1.7: Large product (₦100,000)
SELECT results_eq(
  $$SELECT customer_pays, provider_gets, referrer_gets, platform_gets
    FROM calculate_product_commission(100000.00, TRUE)$$,
  $$VALUES (100000.00::DECIMAL(12,2), 94000.00::DECIMAL(12,2), 4500.00::DECIMAL(12,2), 1500.00::DECIMAL(12,2))$$,
  'Product with referrer: ₦100,000 price → Provider ₦94,000, Referrer ₦4,500, Platform ₦1,500'
);

-- Test 1.8: Small product with decimals (₦99.99)
SELECT results_eq(
  $$SELECT customer_pays, provider_gets, referrer_gets, platform_gets
    FROM calculate_product_commission(99.99, TRUE)$$,
  $$VALUES (99.99::DECIMAL(12,2), 93.99::DECIMAL(12,2), 4.50::DECIMAL(12,2), 1.50::DECIMAL(12,2))$$,
  'Product with referrer: ₦99.99 price → Decimal precision maintained'
);

-- Test 1.9: Verify percentages sum to 100%
SELECT is(
  94.0 + 4.5 + 1.5,
  100.0,
  'Product with referrer: Percentages sum to 100% (94% + 4.5% + 1.5%)'
);

-- Test 1.10: Very small product (₦10.00)
SELECT results_eq(
  $$SELECT customer_pays, provider_gets, referrer_gets, platform_gets
    FROM calculate_product_commission(10.00, TRUE)$$,
  $$VALUES (10.00::DECIMAL(12,2), 9.40::DECIMAL(12,2), 0.45::DECIMAL(12,2), 0.15::DECIMAL(12,2))$$,
  'Product with referrer: ₦10.00 price → Handles small amounts correctly'
);

-- Test 1.11: Product at ₦1,234.56 (arbitrary decimal)
SELECT results_eq(
  $$SELECT customer_pays, provider_gets, referrer_gets, platform_gets
    FROM calculate_product_commission(1234.56, TRUE)$$,
  $$VALUES (1234.56::DECIMAL(12,2), 1160.49::DECIMAL(12,2), 55.56::DECIMAL(12,2), 18.52::DECIMAL(12,2))$$,
  'Product with referrer: ₦1,234.56 price → Arbitrary decimal handled correctly'
);

-- =============================================================================
-- TEST SUITE 2: Product Commission WITHOUT Referrer
-- =============================================================================
-- Formula: ₦100 fixed charge, 94/0/(1.5% + ₦100) split

-- Test 2.1: Basic calculation (₦5,000 product)
SELECT results_eq(
  $$SELECT customer_pays, provider_gets, referrer_gets, platform_gets
    FROM calculate_product_commission(5000.00, FALSE)$$,
  $$VALUES (5100.00::DECIMAL(12,2), 4700.00::DECIMAL(12,2), 0.00::DECIMAL(12,2), 175.00::DECIMAL(12,2))$$,
  'Product without referrer: ₦5,000 price → Customer pays ₦5,100, Provider ₦4,700, Referrer ₦0, Platform ₦175 (₦75 + ₦100)'
);

-- Test 2.2: Verify totals balance
SELECT is(
  (SELECT customer_pays FROM calculate_product_commission(5000.00, FALSE)),
  (SELECT provider_gets + referrer_gets + platform_gets FROM calculate_product_commission(5000.00, FALSE)),
  'Product without referrer: Totals balance (₦5,100 = ₦4,700 + ₦0 + ₦175)'
);

-- Test 2.3: Fixed ₦100 charge applied
SELECT is(
  (SELECT customer_pays FROM calculate_product_commission(5000.00, FALSE)),
  5000.00 + 100.00,
  'Product without referrer: ₦100 fixed charge applied to customer'
);

-- Test 2.4: Referrer amount is zero
SELECT is(
  (SELECT referrer_gets FROM calculate_product_commission(5000.00, FALSE)),
  0.00::DECIMAL(12,2),
  'Product without referrer: Referrer gets ₦0'
);

-- Test 2.5: Provider gets same amount (94% regardless)
SELECT is(
  (SELECT provider_gets FROM calculate_product_commission(5000.00, FALSE)),
  (SELECT provider_gets FROM calculate_product_commission(5000.00, TRUE)),
  'Product: Provider gets same amount with or without referrer (₦4,700)'
);

-- Test 2.6: Platform gets 1.5% + ₦100
SELECT is(
  (SELECT platform_gets FROM calculate_product_commission(5000.00, FALSE)),
  5000.00 * 0.015 + 100.00,
  'Product without referrer: Platform gets 1.5% + ₦100 fixed charge'
);

-- Test 2.7: Customer pays more without referrer (fixed charge)
SELECT ok(
  (SELECT customer_pays FROM calculate_product_commission(5000.00, FALSE)) >
  (SELECT customer_pays FROM calculate_product_commission(5000.00, TRUE)),
  'Product: Customer pays more without referrer (₦5,100 vs ₦5,000)'
);

-- Test 2.8: Exact difference is ₦100
SELECT is(
  (SELECT customer_pays FROM calculate_product_commission(5000.00, FALSE)) -
  (SELECT customer_pays FROM calculate_product_commission(5000.00, TRUE)),
  100.00::DECIMAL(12,2),
  'Product: Difference in customer payment is exactly ₦100'
);

-- Test 2.9: Large product (₦100,000)
SELECT results_eq(
  $$SELECT customer_pays, provider_gets, referrer_gets, platform_gets
    FROM calculate_product_commission(100000.00, FALSE)$$,
  $$VALUES (100100.00::DECIMAL(12,2), 94000.00::DECIMAL(12,2), 0.00::DECIMAL(12,2), 1600.00::DECIMAL(12,2))$$,
  'Product without referrer: ₦100,000 price → Platform ₦1,600 (₦1,500 + ₦100)'
);

-- Test 2.10: Small product (₦10.00)
SELECT results_eq(
  $$SELECT customer_pays, provider_gets, referrer_gets, platform_gets
    FROM calculate_product_commission(10.00, FALSE)$$,
  $$VALUES (110.00::DECIMAL(12,2), 9.40::DECIMAL(12,2), 0.00::DECIMAL(12,2), 100.15::DECIMAL(12,2))$$,
  'Product without referrer: ₦10.00 price → Platform ₦100.15 (₦0.15 + ₦100)'
);

-- Test 2.11: Platform share comparison (with vs without referrer)
SELECT is(
  (SELECT platform_gets FROM calculate_product_commission(5000.00, FALSE)),
  (SELECT platform_gets FROM calculate_product_commission(5000.00, TRUE)) + 100.00,
  'Product: Platform gets exactly ₦100 more when no referrer (₦175 vs ₦75)'
);

SELECT * FROM finish();

ROLLBACK;
