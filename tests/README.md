# E-Commerce E2E Test Suite

Comprehensive end-to-end tests for the multi-tenant POS e-commerce storefront (User Story 3).

## Overview

This test suite validates the complete e-commerce workflow including:
- Customer registration and management
- Product browsing and ordering
- Inventory validation and synchronization
- Loyalty points earning and redemption
- Order tracking and fulfillment

## Test Files

### 1. `e2e-customer-registration.spec.js`
Tests customer management functionality:
- Customer registration with validation
- Profile updates
- Address management
- Customer search
- Statistics tracking

**Test Coverage:**
- ✅ Register new customer
- ✅ Validate required fields
- ✅ Retrieve customer details
- ✅ Search customers
- ✅ Add/manage addresses
- ✅ Update customer profile
- ✅ Track customer statistics

### 2. `e2e-order-placement.spec.js`
Tests the complete order workflow:
- Product browsing and filtering
- Shopping cart functionality
- Order creation and validation
- Inventory checking
- Order tracking
- Status updates

**Test Coverage:**
- ✅ Browse marketplace products
- ✅ Filter by category
- ✅ Search products
- ✅ View product details
- ✅ Create order
- ✅ Validate inventory
- ✅ Track order status
- ✅ View order history
- ✅ Calculate totals correctly
- ✅ Support pickup orders
- ✅ Update order status
- ✅ Cancel orders
- ✅ Edge case validation

### 3. `e2e-loyalty-points.spec.js`
Tests loyalty points system:
- Points calculation (1 point per ₦100)
- Points awarding on delivery
- Points redemption (1 point = ₦100 discount)
- Balance tracking
- Edge cases

**Test Coverage:**
- ✅ Calculate points correctly
- ✅ Award points on delivery
- ✅ Preview points to earn
- ✅ Apply loyalty discount
- ✅ Prevent over-redemption
- ✅ Track points balance
- ✅ Convert points to currency
- ✅ Handle fractional points
- ✅ Prevent negative balances

## Prerequisites

### 1. Install Dependencies
```bash
npm install
```

### 2. Start SvelteKit Dev Server
The tests require the storefront app to be running:
```bash
cd apps/storefront
npm install
npm run dev
```

The server should be running at `http://localhost:5173`

### 3. Configure Test Data
Update the test configuration in each spec file:
```javascript
const TEST_TENANT_ID = 'your-tenant-id';
const TEST_BRANCH_ID = 'your-branch-id';
```

### 4. Prepare Database
Ensure your Supabase database has:
- Applied all migrations (including the new inventory sync migration)
- At least one tenant
- At least one branch
- Some test products with stock

## Running Tests

### Run All Tests
```bash
npx playwright test
```

### Run Specific Test Suite
```bash
# Customer registration tests only
npx playwright test e2e-customer-registration

# Order placement tests only
npx playwright test e2e-order-placement

# Loyalty points tests only
npx playwright test e2e-loyalty-points
```

### Run in UI Mode (Recommended for Debugging)
```bash
npx playwright test --ui
```

### Run with Headed Browser
```bash
npx playwright test --headed
```

### Run in Debug Mode
```bash
npx playwright test --debug
```

### Generate Test Report
```bash
npx playwright test --reporter=html
npx playwright show-report
```

## Test Configuration

The tests are configured in `playwright.config.js`:
- **Test Directory:** `./tests`
- **Timeout:** 120 seconds per test
- **Browser:** Chromium (Desktop Chrome)
- **Screenshots:** Enabled on failure
- **Video:** Retained on failure
- **Trace:** Retained on failure

## Expected Results

### Passing Tests
All tests should pass when:
- Backend API endpoints are working
- Database has proper test data
- Inventory sync triggers are active
- Real-time stock calculations are correct

### Potential Failures

#### "No products available"
- **Cause:** Empty product catalog
- **Fix:** Add products to your database with stock

#### "Order creation failed (inventory)"
- **Cause:** Insufficient stock for test products
- **Fix:** Increase stock quantity in `branch_inventory` table

#### "May require authentication"
- **Cause:** Merchant endpoints require auth
- **Fix:** Implement auth or mock auth tokens

#### "Test prerequisites missing"
- **Cause:** Setup failed (customer/product creation)
- **Fix:** Check database connection and RLS policies

## Test Data Cleanup

The tests create test data (customers, orders) during execution. To clean up:

```sql
-- Delete test customers
DELETE FROM customers
WHERE full_name LIKE '%Test%'
  OR email LIKE 'test-%@example.com';

-- Delete test orders
DELETE FROM orders
WHERE customer_id IN (
  SELECT id FROM customers
  WHERE full_name LIKE '%Test%'
);
```

## Continuous Integration

To run tests in CI:

```yaml
# .github/workflows/e2e-tests.yml
name: E2E Tests
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
      - run: npm install
      - run: npx playwright install --with-deps
      - run: npm run dev &
      - run: npx playwright test
      - uses: actions/upload-artifact@v3
        if: always()
        with:
          name: playwright-report
          path: playwright-report/
```

## Test Coverage Summary

### Customer Workflow (T111.1)
- ✅ Registration
- ✅ Profile management
- ✅ Address management
- ✅ Search functionality

### Order Workflow (T111.2)
- ✅ Product discovery
- ✅ Cart management
- ✅ Order creation
- ✅ Inventory validation
- ✅ Order tracking
- ✅ Status management

### Loyalty System (T111.3)
- ✅ Points earning (1 per ₦100)
- ✅ Points redemption (1 = ₦100 off)
- ✅ Balance tracking
- ✅ Transaction validation

## Business Rules Validated

1. **Inventory Management**
   - Stock cannot go negative
   - Orders reserve inventory
   - Cancelled orders restore inventory
   - Real-time sync between POS and marketplace

2. **Loyalty Points**
   - 1 point earned per ₦100 spent
   - 1 point = ₦100 discount when redeemed
   - Points awarded on order delivery
   - Cannot redeem more than available

3. **Order Processing**
   - Delivery orders require address
   - Pickup orders have no delivery fee
   - Tax calculated at 7.5% VAT
   - Inventory validated before order creation

4. **Customer Data**
   - Phone number required
   - Email optional
   - Multiple addresses supported
   - Default address marked

## Troubleshooting

### Tests Timeout
- Increase timeout in `playwright.config.js`
- Check if dev server is running
- Verify database connection

### Random Failures
- May be due to race conditions
- Check if triggers execute synchronously
- Add delays for async operations

### Authentication Errors
- Merchant endpoints may need auth
- Update tests to include auth tokens
- Or temporarily disable auth for testing

## Next Steps

1. **Add Authentication Tests**
   - Customer OTP login
   - Merchant authentication
   - Session management

2. **Add Payment Tests**
   - Payment gateway integration
   - Payment confirmation
   - Failed payment handling

3. **Add Performance Tests**
   - Load testing with many orders
   - Concurrent order placement
   - Large product catalogs

4. **Add Visual Regression Tests**
   - Screenshot comparison
   - UI consistency checks
   - Responsive design validation

## Support

For issues or questions:
- Check test output and screenshots
- Review Playwright trace files
- Check backend API logs
- Verify database state

---

**Test Suite Status:** ✅ Complete
**Coverage:** Customer registration, order placement, loyalty points
**Last Updated:** 2026-03-10
