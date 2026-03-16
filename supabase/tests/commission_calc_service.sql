-- pgTAP Tests for Service Commission Calculation
-- Feature: 004-tenant-referral-commissions
-- Tests: calculate_service_commission function
-- Constitutional Requirement: SC-002 (100% commission accuracy)

BEGIN;

SELECT plan(20);

-- =============================================================================
-- TEST SUITE 1: Service Commission WITH Referrer
-- =============================================================================
-- Formula: 10% markup, 90/10/10 split (provider/referrer/platform)

-- Test 1.1: Basic calculation (₦1,000 base)
SELECT results_eq(
  $$SELECT customer_pays, provider_gets, referrer_gets, platform_gets
    FROM calculate_service_commission(1000.00, TRUE)$$,
  $$VALUES (1100.00::DECIMAL(12,2), 900.00::DECIMAL(12,2), 100.00::DECIMAL(12,2), 100.00::DECIMAL(12,2))$$,
  'Service with referrer: ₦1,000 base → Customer pays ₦1,100, Provider ₦900, Referrer ₦100, Platform ₦100'
);

-- Test 1.2: Verify totals balance (customer_pays = provider + referrer + platform)
SELECT is(
  (SELECT customer_pays FROM calculate_service_commission(1000.00, TRUE)),
  (SELECT provider_gets + referrer_gets + platform_gets FROM calculate_service_commission(1000.00, TRUE)),
  'Service with referrer: Totals balance (₦1,100 = ₦900 + ₦100 + ₦100)'
);

-- Test 1.3: Large amount (₦50,000 base)
SELECT results_eq(
  $$SELECT customer_pays, provider_gets, referrer_gets, platform_gets
    FROM calculate_service_commission(50000.00, TRUE)$$,
  $$VALUES (55000.00::DECIMAL(12,2), 45000.00::DECIMAL(12,2), 5000.00::DECIMAL(12,2), 5000.00::DECIMAL(12,2))$$,
  'Service with referrer: ₦50,000 base → Customer pays ₦55,000, Provider ₦45,000, Referrer ₦5,000, Platform ₦5,000'
);

-- Test 1.4: Small amount with decimals (₦99.50 base)
SELECT results_eq(
  $$SELECT customer_pays, provider_gets, referrer_gets, platform_gets
    FROM calculate_service_commission(99.50, TRUE)$$,
  $$VALUES (109.45::DECIMAL(12,2), 89.55::DECIMAL(12,2), 9.95::DECIMAL(12,2), 9.95::DECIMAL(12,2))$$,
  'Service with referrer: ₦99.50 base → Decimal precision maintained'
);

-- Test 1.5: Verify 10% markup applied
SELECT is(
  (SELECT customer_pays FROM calculate_service_commission(1000.00, TRUE)),
  1000.00 * 1.10,
  'Service with referrer: 10% markup applied correctly'
);

-- Test 1.6: Verify provider gets 90% of base
SELECT is(
  (SELECT provider_gets FROM calculate_service_commission(1000.00, TRUE)),
  1000.00 * 0.90,
  'Service with referrer: Provider gets 90% of base price'
);

-- Test 1.7: Verify referrer gets 10% of base
SELECT is(
  (SELECT referrer_gets FROM calculate_service_commission(1000.00, TRUE)),
  1000.00 * 0.10,
  'Service with referrer: Referrer gets 10% of base price'
);

-- Test 1.8: Verify platform gets 10% of base
SELECT is(
  (SELECT platform_gets FROM calculate_service_commission(1000.00, TRUE)),
  1000.00 * 0.10,
  'Service with referrer: Platform gets 10% of base price'
);

-- Test 1.9: Zero edge case should not occur (positive price constraint)
-- This tests that function handles smallest valid amount
SELECT results_eq(
  $$SELECT customer_pays, provider_gets, referrer_gets, platform_gets
    FROM calculate_service_commission(0.01, TRUE)$$,
  $$VALUES (0.01::DECIMAL(12,2), 0.01::DECIMAL(12,2), 0.00::DECIMAL(12,2), 0.00::DECIMAL(12,2))$$,
  'Service with referrer: Handles smallest valid amount (₦0.01)'
);

-- Test 1.10: Very large consultation (₦1,000,000)
SELECT results_eq(
  $$SELECT customer_pays, provider_gets, referrer_gets, platform_gets
    FROM calculate_service_commission(1000000.00, TRUE)$$,
  $$VALUES (1100000.00::DECIMAL(12,2), 900000.00::DECIMAL(12,2), 100000.00::DECIMAL(12,2), 100000.00::DECIMAL(12,2))$$,
  'Service with referrer: Handles very large amounts correctly'
);

-- =============================================================================
-- TEST SUITE 2: Service Commission WITHOUT Referrer
-- =============================================================================
-- Formula: 10% markup, 90/0/20 split (provider/referrer/platform)

-- Test 2.1: Basic calculation (₦1,000 base)
SELECT results_eq(
  $$SELECT customer_pays, provider_gets, referrer_gets, platform_gets
    FROM calculate_service_commission(1000.00, FALSE)$$,
  $$VALUES (1100.00::DECIMAL(12,2), 900.00::DECIMAL(12,2), 0.00::DECIMAL(12,2), 200.00::DECIMAL(12,2))$$,
  'Service without referrer: ₦1,000 base → Customer pays ₦1,100, Provider ₦900, Referrer ₦0, Platform ₦200'
);

-- Test 2.2: Verify totals balance
SELECT is(
  (SELECT customer_pays FROM calculate_service_commission(1000.00, FALSE)),
  (SELECT provider_gets + referrer_gets + platform_gets FROM calculate_service_commission(1000.00, FALSE)),
  'Service without referrer: Totals balance (₦1,100 = ₦900 + ₦0 + ₦200)'
);

-- Test 2.3: Referrer amount is zero
SELECT is(
  (SELECT referrer_gets FROM calculate_service_commission(1000.00, FALSE)),
  0.00::DECIMAL(12,2),
  'Service without referrer: Referrer gets ₦0'
);

-- Test 2.4: Platform gets double share (20% instead of 10%)
SELECT is(
  (SELECT platform_gets FROM calculate_service_commission(1000.00, FALSE)),
  1000.00 * 0.20,
  'Service without referrer: Platform gets 20% of base price (double share)'
);

-- Test 2.5: Customer still pays same amount (10% markup regardless)
SELECT is(
  (SELECT customer_pays FROM calculate_service_commission(1000.00, FALSE)),
  (SELECT customer_pays FROM calculate_service_commission(1000.00, TRUE)),
  'Service: Customer pays same amount with or without referrer'
);

-- Test 2.6: Provider gets same amount (90% regardless)
SELECT is(
  (SELECT provider_gets FROM calculate_service_commission(1000.00, FALSE)),
  (SELECT provider_gets FROM calculate_service_commission(1000.00, TRUE)),
  'Service: Provider gets same amount with or without referrer'
);

-- Test 2.7: Large amount (₦50,000 base)
SELECT results_eq(
  $$SELECT customer_pays, provider_gets, referrer_gets, platform_gets
    FROM calculate_service_commission(50000.00, FALSE)$$,
  $$VALUES (55000.00::DECIMAL(12,2), 45000.00::DECIMAL(12,2), 0.00::DECIMAL(12,2), 10000.00::DECIMAL(12,2))$$,
  'Service without referrer: ₦50,000 base → Platform gets ₦10,000 (20%)'
);

-- Test 2.8: Decimal precision (₦99.50 base)
SELECT results_eq(
  $$SELECT customer_pays, provider_gets, referrer_gets, platform_gets
    FROM calculate_service_commission(99.50, FALSE)$$,
  $$VALUES (109.45::DECIMAL(12,2), 89.55::DECIMAL(12,2), 0.00::DECIMAL(12,2), 19.90::DECIMAL(12,2))$$,
  'Service without referrer: ₦99.50 base → Decimal precision maintained'
);

-- Test 2.9: Platform share comparison (with vs without referrer)
SELECT is(
  (SELECT platform_gets FROM calculate_service_commission(1000.00, FALSE)),
  (SELECT platform_gets FROM calculate_service_commission(1000.00, TRUE)) * 2,
  'Service: Platform gets exactly double when no referrer (₦200 vs ₦100)'
);

-- Test 2.10: Very large consultation without referrer
SELECT results_eq(
  $$SELECT customer_pays, provider_gets, referrer_gets, platform_gets
    FROM calculate_service_commission(1000000.00, FALSE)$$,
  $$VALUES (1100000.00::DECIMAL(12,2), 900000.00::DECIMAL(12,2), 0.00::DECIMAL(12,2), 200000.00::DECIMAL(12,2))$$,
  'Service without referrer: Handles very large amounts correctly'
);

SELECT * FROM finish();

ROLLBACK;
