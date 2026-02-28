# Playwright E2E Tests - POS Admin

This directory contains end-to-end (E2E) tests for the POS Admin Flutter web application using Playwright Test framework.

## Overview

The test suite covers the complete User Story 2 (Multi-Tenant Onboarding & Authentication) with 59+ test cases across 4 test suites:

- **Signup Flow** (15 tests) - Email/password signup, validation, email confirmation screen
- **Country Selection** (16 tests) - Country search, selection, dial codes, currencies
- **Business Setup** (18 tests) - Form validation, logo upload, brand color picker
- **Multi-Tenant Isolation** (10 tests) - Cross-tenant data isolation, session security

## Prerequisites

- **Node.js** 18+ and npm
- **Flutter SDK** installed and in PATH
- **POS Admin app** at `apps/pos_admin/`
- **Supabase instance** configured

## Installation

1. Navigate to the e2e directory:
```bash
cd apps/pos_admin/e2e
```

2. Install dependencies:
```bash
npm install
```

3. Install Playwright browsers:
```bash
npx playwright install
```

## Running Tests

### Run All Tests

```bash
npm test
```

This runs all tests in headless mode across Chromium, Firefox, and WebKit browsers.

### Run Tests in Headed Mode (Watch Tests Run)

```bash
npm run test:headed
```

Useful for debugging - you can see the browser actions in real-time.

### Run Specific Test Suite

```bash
npm run test:signup        # Signup and email confirmation tests
npm run test:country       # Country selection tests
npm run test:business      # Business setup and brand color picker tests
npm run test:isolation     # Multi-tenant isolation tests
```

### Run in Debug Mode

```bash
npm run test:debug
```

Opens Playwright Inspector for step-by-step debugging with:
- Breakpoints
- Element picker
- Network logs
- Console output

### Run with UI Mode (Interactive)

```bash
npm run test:ui
```

Opens Playwright UI for:
- Selecting specific tests to run
- Viewing test results
- Inspecting screenshots/videos
- Time travel debugging

## Test Structure

```
e2e/
├── tests/
│   ├── signup-flow.spec.ts              # AS1: Email signup & confirmation
│   ├── country-selection.spec.ts        # AS2 & AS3: Country selection flow
│   ├── business-setup.spec.ts           # AS6: Business setup & branding
│   └── multi-tenant-isolation.spec.ts   # AS4: Multi-tenant data isolation
├── helpers/
│   └── test-utils.ts                    # Shared utilities for Flutter testing
├── package.json
├── playwright.config.ts
└── README.md
```

## Configuration

### Base URL

Tests default to `http://localhost:8080`. Override with environment variable:

```bash
BASE_URL=http://localhost:3000 npm test
```

### Flutter Web Server

The Playwright config automatically starts the Flutter web server on port 8080 before running tests. If you need to change this:

1. Edit `playwright.config.ts`
2. Update `webServer.command` and `webServer.url`

### Test Timeout

Default timeout is 60 seconds per test. For slower machines, increase in `playwright.config.ts`:

```typescript
timeout: 90 * 1000, // 90 seconds
```

## Test Coverage

### AS1: Account Creation and Email Confirmation
- ✅ Display signup form correctly
- ✅ Validate required fields
- ✅ Validate email format
- ✅ Check password mismatch
- ✅ Successfully sign up
- ✅ Show email confirmation pending screen
- ✅ Resend confirmation email
- ✅ Navigate back to login
- ✅ Responsive design on mobile
- ✅ Handle network errors
- ✅ Display Google Sign-In button
- ✅ Keyboard navigation
- ✅ ARIA labels

### AS2 & AS3: Country Selection
- ✅ Display country selection screen
- ✅ Show multiple countries in list
- ✅ Search and filter countries
- ✅ Clear search
- ✅ Select country and show confirmation
- ✅ Display country details (flag, name, dial code, currency)
- ✅ Enable Continue button after selection
- ✅ Navigate to business setup
- ✅ Allow changing country selection
- ✅ Show visual selection indicator
- ✅ Handle long country names
- ✅ Verify dial codes for Nigeria (+234), Kenya (+254), Ghana (+233)
- ✅ Responsive on mobile
- ✅ Keyboard navigation

### AS6: Business Setup and Branding
- ✅ Display business setup form
- ✅ Show logo upload section
- ✅ Show brand color picker
- ✅ Open color picker dialog
- ✅ Select and apply brand color
- ✅ Show checkmark on selected color
- ✅ Close color picker
- ✅ Validate required fields
- ✅ Fill and submit complete form
- ✅ Display business type options (Retail, Restaurant, Pharmacy, Healthcare)
- ✅ Display location type options (Head Office, Branch)
- ✅ Handle long business names
- ✅ Show loading state during submission
- ✅ Responsive on mobile
- ✅ Persist selected color after reopening
- ✅ Display all 12 color options
- ✅ Keyboard navigation

### AS4: Multi-Tenant Isolation
- ✅ Create Tenant A with complete onboarding
- ✅ Create Tenant B with complete onboarding
- ✅ Show only Tenant A data when logged in as Tenant A
- ✅ Show only Tenant B data when logged in as Tenant B
- ✅ Prevent cross-tenant data access via URL manipulation
- ✅ Maintain isolation after switching between tenants
- ✅ Show correct country settings for each tenant
- ✅ Show different brand colors for each tenant
- ✅ Prevent session hijacking between tenants
- ✅ Clear sensitive data on logout

## Debugging Failed Tests

### Screenshots and Videos

On test failure, Playwright automatically captures:
- **Screenshots**: `test-results/` directory
- **Videos**: `test-results/` directory (retained only on failure)
- **Traces**: Available for replay with `npx playwright show-trace <trace-file>`

### Debug Screenshots

Tests also capture debug screenshots at key steps:
```
test-results/debug-email-confirmation-screen-*.png
test-results/debug-country-selected-nigeria-*.png
test-results/debug-color-selected-and-applied-*.png
test-results/debug-tenant-a-dashboard-*.png
```

### Common Issues

#### 1. Flutter app not loading
**Symptom**: Tests timeout waiting for Flutter app

**Fix**:
```bash
# Manually start Flutter app first
cd apps/pos_admin
flutter run -d web-server --web-port=8080

# In another terminal, run tests with existing server
BASE_URL=http://localhost:8080 npm test
```

#### 2. Element not found errors
**Symptom**: "Could not find button with text: X"

**Cause**: Flutter web uses canvas rendering, standard selectors may not work

**Fix**: Test utilities in `helpers/test-utils.ts` use multiple selector strategies. If still failing:
- Check Flutter app is fully rendered (wait for `flt-glass-pane`)
- Increase timeout in test
- Use debug mode to inspect actual DOM

#### 3. Flaky tests
**Symptom**: Tests pass/fail inconsistently

**Fix**:
- Increase `waitForTimeout` values in test
- Add `waitForLoadingComplete()` after navigation
- Ensure `waitForFlutterApp()` is called after page loads

#### 4. Browser not installed
**Symptom**: "Executable doesn't exist at ..."

**Fix**:
```bash
npx playwright install chromium  # Or firefox, webkit
```

## CI/CD Integration

### GitHub Actions

Add to `.github/workflows/e2e-tests.yml`:

```yaml
name: E2E Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 18
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.x'

      - name: Install dependencies
        working-directory: apps/pos_admin/e2e
        run: npm ci

      - name: Install Playwright browsers
        working-directory: apps/pos_admin/e2e
        run: npx playwright install --with-deps chromium

      - name: Run E2E tests
        working-directory: apps/pos_admin/e2e
        run: npm test
        env:
          SUPABASE_URL: ${{ secrets.SUPABASE_URL }}
          SUPABASE_ANON_KEY: ${{ secrets.SUPABASE_ANON_KEY }}

      - name: Upload test results
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: playwright-results
          path: apps/pos_admin/e2e/test-results/
```

### Running on Different Browsers

By default, tests run on Chromium, Firefox, and WebKit. To run on specific browser:

```bash
npx playwright test --project=chromium
npx playwright test --project=firefox
npx playwright test --project=webkit
npx playwright test --project="Mobile Chrome"
npx playwright test --project="Mobile Safari"
```

## Test Data Management

### Generated Test Data

Tests use unique test emails and passwords:
- Email format: `<prefix>-<timestamp>-<random>@e2etest.com`
- Password format: `TestPass<timestamp>!`

This ensures no conflicts between test runs.

### Cleanup

Tests create real data in Supabase. To clean up:

1. **Manual cleanup**: Delete test tenants/users from Supabase Dashboard
2. **Automated cleanup** (future): Add cleanup script to `helpers/test-utils.ts`

## Writing New Tests

### Basic Test Structure

```typescript
import { test, expect } from '@playwright/test';
import {
  waitForFlutterApp,
  fillFlutterTextField,
  clickFlutterButton,
  expectTextVisible,
} from '../helpers/test-utils';

test('should do something', async ({ page }) => {
  // Navigate to page
  await page.goto('/your-page');
  await waitForFlutterApp(page);

  // Interact with Flutter elements
  await fillFlutterTextField(page, 'Field Label', 'value');
  await clickFlutterButton(page, 'Button Text');

  // Verify results
  await expectTextVisible(page, 'Expected Text');
  await expect(page).toHaveURL(/expected-path/);
});
```

### Best Practices

1. **Always call `waitForFlutterApp()`** after navigation
2. **Use test utilities** for Flutter interactions (not raw Playwright selectors)
3. **Add debug screenshots** at important steps: `await takeDebugScreenshot(page, 'step-name')`
4. **Wait for loading to complete**: `await waitForLoadingComplete(page)`
5. **Generate unique test data**: Use `generateTestEmail()`, `generateTestPassword()`
6. **Clean up after tests**: Sign out, clear state

## Troubleshooting

### Test utilities not working?

Check that you're importing from the correct path:
```typescript
import { ... } from '../helpers/test-utils';
```

### Flutter app not responding to clicks?

Make sure you're using `clickFlutterButton()` instead of raw `page.click()`. Flutter web uses canvas rendering which requires special handling.

### Timeout errors?

Increase timeout for specific operations:
```typescript
await expect(element).toBeVisible({ timeout: 15000 }); // 15 seconds
```

Or increase global timeout in `playwright.config.ts`.

## Resources

- [Playwright Documentation](https://playwright.dev)
- [Playwright Test API](https://playwright.dev/docs/api/class-test)
- [Flutter Web Testing Guide](https://docs.flutter.dev/testing/integration-tests)
- [User Story 2 Specification](../../../specs/001-multi-tenant-pos/spec.md)

## Support

For issues or questions about the E2E tests:
1. Check test output and screenshots in `test-results/`
2. Run in debug mode: `npm run test:debug`
3. Review test utilities in `helpers/test-utils.ts`
4. Check Flutter app logs for errors
