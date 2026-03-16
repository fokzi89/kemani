# End-to-End Testing Guide

**Feature**: 004-tenant-referral-commissions
**Updated**: 2026-03-15

## Overview

This guide provides comprehensive testing procedures for the multi-tenant referral commission system.

---

## Setup Before Testing

### 1. Database Configuration

```sql
-- Configure test tenants with services
UPDATE tenants
SET services_offered = ARRAY['pharmacy', 'diagnostic']
WHERE subdomain = 'fokz';

UPDATE tenants
SET services_offered = ARRAY['consultation']
WHERE subdomain = 'medic';

-- Verify configuration
SELECT id, name, subdomain, services_offered FROM tenants;
```

### 2. Test Users

Create test accounts:
```sql
-- Admin user
INSERT INTO auth.users (email, encrypted_password)
VALUES ('admin@test.com', crypt('password123', gen_salt('bf')));

-- Customer users
INSERT INTO auth.users (email, encrypted_password)
VALUES
  ('customer1@test.com', crypt('password123', gen_salt('bf'))),
  ('customer2@test.com', crypt('password123', gen_salt('bf')));
```

### 3. Test Data

```sql
-- Add test products for Fokz
INSERT INTO products (name, price, tenant_id, category)
VALUES
  ('Paracetamol', 500, 'fokz-uuid', 'pharmacy'),
  ('Blood Test', 5000, 'fokz-uuid', 'diagnostic');

-- Add test doctor for Medic
INSERT INTO doctors (name, specialization, consultation_fee, tenant_id)
VALUES ('Dr. Kome', 'General Physician', 1000, 'medic-uuid');
```

---

## Test Scenarios

### Scenario 1: Self-Provider (No Referral Commission)

**Test:** Customer visits fokz.kemani.com and buys Fokz's own products

**Steps:**
1. Visit `http://fokz.localhost:5173/products`
2. Verify auto-route notification shows
3. Add Paracetamol (₦500) to cart
4. Go to checkout
5. Complete payment

**Expected Results:**
```sql
-- Check transaction
SELECT * FROM transactions WHERE id = '[transaction-id]';
-- provider_tenant_id = referring_tenant_id = 'fokz-uuid'

-- Check commission
SELECT * FROM commissions WHERE transaction_id = '[transaction-id]';
-- referrer_amount = 0 (self-provider)
-- provider_gets = 470 (94% of 500)
-- platform_gets = 30 (6% of 500)
```

**Verify:**
- ✅ No referral commission awarded
- ✅ Platform gets both shares (4.5% + 1.5%)
- ✅ Total = base_price (₦500)

### Scenario 2: External Provider (With Referral Commission)

**Test:** Customer visits fokz.kemani.com and books consultation with external doctor

**Steps:**
1. Visit `http://fokz.localhost:5173/consultations`
2. Verify directory shows (Fokz doesn't offer consultation)
3. Select Dr. Kome from Medic Clinic
4. Book consultation (₦1,000)
5. Complete payment

**Expected Results:**
```sql
SELECT * FROM commissions WHERE transaction_id = '[transaction-id]';
-- customer_pays = 1100 (₦1,000 + 10% markup)
-- provider_gets = 990 (90% of 1100) → Dr. Kome
-- referrer_gets = 110 (10% of 1100) → Fokz Pharmacy
-- platform_gets = 110 (10% of 1100)
```

**Verify:**
- ✅ Fokz earns ₦110 referral commission
- ✅ Dr. Kome earns ₦990
- ✅ Platform earns ₦110
- ✅ Total = ₦1,210 (customer pays ₦1,100)

### Scenario 3: Multi-Service Cart (Mixed Self + External)

**Test:** Customer buys multiple services in one session

**Steps:**
1. Visit `http://fokz.localhost:5173`
2. Add to cart:
   - Paracetamol (₦5,000) - Fokz product
   - Consultation (₦1,000) - External doctor
   - Blood Test (₦5,000) - Fokz diagnostic
3. Go to checkout
4. Verify commission preview shows
5. Complete payment

**Expected Results:**

**Transaction Group:**
```sql
SELECT * FROM transactions WHERE group_id = '[group-id]';
-- 3 transactions, all with same referring_tenant_id = 'fokz-uuid'
```

**Commissions:**
```sql
SELECT
  t.type,
  c.referrer_amount,
  c.provider_amount,
  c.platform_amount
FROM commissions c
JOIN transactions t ON c.transaction_id = t.id
WHERE t.group_id = '[group-id]';

-- Item 1: Product (self-provider)
-- type: product_sale
-- referrer: 0
-- provider: 4,700
-- platform: 300

-- Item 2: Consultation (external)
-- type: consultation
-- referrer: 110
-- provider: 990
-- platform: 110

-- Item 3: Diagnostic (self-provider)
-- type: diagnostic_test
-- referrer: 0
-- provider: 4,950
-- platform: 550
```

**Totals:**
```sql
SELECT
  SUM(c.referrer_amount) as fokz_total,
  SUM(c.platform_amount) as platform_total
FROM commissions c
JOIN transactions t ON c.transaction_id = t.id
WHERE t.group_id = '[group-id]';

-- fokz_total = 9,760 (4,700 + 110 + 4,950)
-- platform_total = 960 (300 + 110 + 550)
```

**Verify:**
- ✅ Fokz earns ₦110 referral commission (only on external consultation)
- ✅ Fokz earns ₦9,650 as provider (own products + diagnostics)
- ✅ Platform earns ₦960
- ✅ Customer pays ₦11,600

### Scenario 4: Session Persistence

**Test:** Session remains active throughout browsing

**Steps:**
1. Visit `http://fokz.localhost:5173`
2. Check DevTools → Application → Cookies → `referral_session`
3. Navigate to /products
4. Navigate to /consultations
5. Navigate to /diagnostics
6. Navigate to /checkout

**Expected:**
- ✅ Same session cookie value throughout
- ✅ Session doesn't expire during browsing
- ✅ `referring_tenant_id` remains 'fokz-uuid'

### Scenario 5: Session Expiry

**Test:** Session expires after 24 hours

**Steps:**
1. Visit `http://fokz.localhost:5173`
2. Note session cookie value
3. Wait 24 hours (or manually expire cookie)
4. Revisit site
5. Check cookie value

**Expected:**
- ✅ New session cookie created
- ✅ Old session marked as expired in database

**Verify:**
```sql
SELECT * FROM referral_sessions
WHERE session_token = '[old-token]';
-- expires_at < NOW()
```

### Scenario 6: Different Subdomains

**Test:** Different subdomains create different sessions

**Steps:**
1. Visit `http://fokz.localhost:5173` in browser 1
2. Visit `http://medic.localhost:5173` in browser 2
3. Check session cookies in both browsers

**Expected:**
- ✅ Different session tokens
- ✅ Fokz session → referring_tenant_id = 'fokz-uuid'
- ✅ Medic session → referring_tenant_id = 'medic-uuid'

### Scenario 7: Automatic Routing

**Test:** Auto-route when tenant offers service

**Steps:**
1. Visit `http://fokz.localhost:5173/products`
2. Check if auto-route notification appears
3. Verify no directory shown

**Expected:**
- ✅ Auto-route notification visible
- ✅ Fokz products shown directly
- ✅ No external pharmacy directory

**Test:** Show directory when tenant doesn't offer service

**Steps:**
1. Visit `http://fokz.localhost:5173/consultations`
2. Check if directory appears

**Expected:**
- ✅ Directory of doctors shown
- ✅ No auto-route notification
- ✅ Fokz not in directory (they don't offer consultation)

---

## Automated Tests

### Run All Tests

```bash
# Unit tests (commission calculations)
npm test apps/storefront/tests/commission-calculation.test.ts

# E2E tests (session tracking)
npx playwright test tests/referral-session.spec.ts

# Multi-service tests
npx playwright test tests/multi-service-commission.spec.ts

# Auto-routing tests
npx playwright test tests/automatic-routing-self-provider.spec.ts

# Run all
npx playwright test
```

### Database Tests (pgTAP)

```sql
-- Test commission functions
\i test-commission-calculations.sql

-- Expected: All tests pass ✓
```

---

## Manual Testing Checklist

### Session Tracking
- [ ] Session created on subdomain visit
- [ ] Session persists across pages
- [ ] Session refreshes on user activity
- [ ] Session expires after 24 hours
- [ ] Different subdomains create different sessions

### Auto-Routing
- [ ] Auto-routes when tenant offers service
- [ ] Shows directory when tenant doesn't offer service
- [ ] Auto-route notification displays correctly
- [ ] Directory shows only relevant providers

### Commission Calculations
- [ ] Self-provider: No referral commission
- [ ] External provider: Referral commission awarded
- [ ] Service with referrer: Correct 90/10/10 split
- [ ] Product without referrer: Correct 94/0/6 split
- [ ] Multi-service: Totals match individual sums

### Payment Flow
- [ ] Transaction group created correctly
- [ ] Webhook received by Edge Function
- [ ] Commissions created in database
- [ ] Transaction status updated to 'completed'
- [ ] Payment callback redirects correctly

### Edge Cases
- [ ] Empty cart redirects properly
- [ ] Invalid session handled gracefully
- [ ] Webhook idempotency (no duplicate commissions)
- [ ] Amount mismatch logged but doesn't fail
- [ ] Mixed referrers in group rejected

---

## Performance Testing

### Load Test Commission Calculation

```typescript
// Test 1000 simultaneous commission calculations
const promises = [];
for (let i = 0; i < 1000; i++) {
  promises.push(
    CommissionCalculator.calculate({
      transactionType: 'product_sale',
      basePrice: 5000,
      hasReferrer: true
    })
  );
}

const results = await Promise.all(promises);
console.log('All calculations completed');
// Expected: < 5 seconds for 1000 calculations
```

### Webhook Processing Speed

```sql
-- Check average Edge Function execution time
SELECT
  AVG(execution_time_ms) as avg_time,
  MAX(execution_time_ms) as max_time
FROM edge_function_logs
WHERE function_name = 'process-referral-payment'
  AND created_at > NOW() - INTERVAL '1 day';

-- Expected: avg < 500ms, max < 2000ms
```

---

## Debugging Tools

### View Session

```sql
SELECT * FROM referral_sessions
WHERE session_token = '[your-cookie-value]';
```

### View Transactions

```sql
SELECT * FROM transactions
WHERE customer_id = '[customer-uuid]'
ORDER BY created_at DESC
LIMIT 10;
```

### View Commissions

```sql
SELECT
  t.type,
  t.base_price,
  t.final_price_paid,
  c.referrer_amount,
  c.provider_amount,
  c.platform_amount,
  c.created_at
FROM commissions c
JOIN transactions t ON c.transaction_id = t.id
WHERE c.referrer_tenant_id = '[tenant-uuid]'
ORDER BY c.created_at DESC;
```

### Edge Function Logs

```bash
# Via CLI
supabase functions logs process-referral-payment --tail

# Via Dashboard
Dashboard → Edge Functions → process-referral-payment → Logs
```

---

## Test Data Cleanup

After testing:

```sql
-- Delete test transactions
DELETE FROM transactions
WHERE customer_id IN (
  SELECT id FROM auth.users
  WHERE email LIKE '%@test.com'
);

-- Delete test commissions (cascade)
-- Commissions will be deleted automatically due to foreign key

-- Delete test sessions
DELETE FROM referral_sessions
WHERE referring_tenant_id = '[test-tenant-id]';

-- Reset tenant services (optional)
UPDATE tenants
SET services_offered = ARRAY[]::TEXT[]
WHERE subdomain IN ('fokz', 'medic');
```

---

## Success Criteria

All tests pass when:

✅ **Session Tracking**
- Sessions created and persisted correctly
- 24-hour expiry works
- Subdomain isolation maintained

✅ **Commission Calculations**
- 100% accuracy on all formulas
- Self-provider check working
- External provider check working

✅ **Auto-Routing**
- Correct routing decisions
- Proper directory display
- Notification UX working

✅ **Payment Integration**
- Webhooks received successfully
- Commissions created atomically
- Transaction groups processed correctly

✅ **Performance**
- Commission calculations < 100ms
- Webhook processing < 1s
- Page load times acceptable

✅ **Edge Cases**
- Error handling graceful
- Idempotency working
- Data validation passing

---

## Reporting Issues

When reporting bugs, include:

1. **Scenario**: What you were testing
2. **Expected**: What should happen
3. **Actual**: What actually happened
4. **Logs**: Edge Function logs, browser console
5. **Data**: Transaction ID, session token, user ID
6. **Environment**: Local/staging/production

**Example:**
```
Scenario: Multi-service checkout
Expected: 3 commissions created
Actual: Only 2 commissions created
Transaction Group ID: abc-123
Edge Function Log: [paste log]
```

---

## Next Steps After Testing

1. ✅ All scenarios pass
2. ✅ Performance acceptable
3. ✅ Edge cases handled
4. → **Deploy to production**
5. → **Monitor first transactions closely**
6. → **Set up alerts for failed webhooks**

Your commission system is tested and ready for production! 🚀
