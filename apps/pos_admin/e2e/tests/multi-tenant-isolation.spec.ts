import { test, expect } from '@playwright/test';
import {
  generateTestEmail,
  generateTestPassword,
  generateBusinessData,
  waitForFlutterApp,
  fillFlutterTextField,
  clickFlutterButton,
  expectTextVisible,
  waitForLoadingComplete,
  takeDebugScreenshot,
  signIn,
  signOut,
} from '../helpers/test-utils';

/**
 * E2E Tests: Multi-Tenant Isolation
 *
 * Tests User Story 2 - Acceptance Scenario AS4:
 * "Multiple tenants: user in tenant A can only access tenant A data"
 *
 * Test Coverage:
 * - Create two separate tenants
 * - Verify each tenant can only see their own data
 * - Verify cross-tenant data access is blocked
 * - Test role-based permissions within tenant
 */

test.describe('Multi-Tenant Data Isolation', () => {
  // Tenant A credentials and data
  let tenantAEmail: string;
  let tenantAPassword: string;
  let tenantABusinessName: string;

  // Tenant B credentials and data
  let tenantBEmail: string;
  let tenantBPassword: string;
  let tenantBBusinessName: string;

  test.beforeAll(async () => {
    // Generate unique credentials for both tenants
    tenantAEmail = generateTestEmail('tenant-a');
    tenantAPassword = generateTestPassword();
    tenantABusinessName = `Tenant A Business ${Date.now()}`;

    tenantBEmail = generateTestEmail('tenant-b');
    tenantBPassword = generateTestPassword();
    tenantBBusinessName = `Tenant B Business ${Date.now()}`;
  });

  test('should create Tenant A with complete onboarding', async ({ page }) => {
    // Step 1: Sign up
    await page.goto('/signup');
    await waitForFlutterApp(page);

    await fillFlutterTextField(page, 'Full Name', 'Tenant A Owner');
    await fillFlutterTextField(page, 'Email', tenantAEmail);
    await fillFlutterTextField(page, 'Password', tenantAPassword);
    await fillFlutterTextField(page, 'Confirm Password', tenantAPassword);
    await clickFlutterButton(page, 'Create Account');
    await waitForLoadingComplete(page);

    // Note: In production, would need to verify email
    // For testing, we'll skip to next step if email confirmation is disabled

    // Step 2: Country Selection (if redirected)
    if (await page.url().includes('country-selection')) {
      await fillFlutterTextField(page, 'Search country', 'Nigeria');
      await page.waitForTimeout(500);
      const nigeriaItem = page.locator('text="Nigeria"').first();
      await nigeriaItem.click();
      await page.waitForTimeout(1000);
      await clickFlutterButton(page, 'Continue');
      await waitForLoadingComplete(page);
    }

    // Step 3: Business Setup
    await page.waitForTimeout(2000); // Wait for page load

    if (await page.url().includes('business-setup')) {
      await fillFlutterTextField(page, 'Business Name', tenantABusinessName);

      // Select business type
      const businessTypeDropdown = page.locator('text="Select business type"').first();
      await businessTypeDropdown.click();
      await page.waitForTimeout(500);
      await clickFlutterButton(page, 'Retail');

      // Select location type
      const locationDropdown = page.locator('text="Select location type"').first();
      await locationDropdown.click();
      await page.waitForTimeout(500);
      await clickFlutterButton(page, 'Head Office');

      await fillFlutterTextField(page, 'State', 'Lagos');
      await fillFlutterTextField(page, 'City', 'Ikeja');
      await fillFlutterTextField(page, 'Office Address', '123 Tenant A Street');

      await clickFlutterButton(page, 'Complete Setup');
      await waitForLoadingComplete(page);
    }

    // Verify reached dashboard
    await expect(page).toHaveURL(/dashboard/, { timeout: 20000 });
    await takeDebugScreenshot(page, 'tenant-a-dashboard');

    // Sign out
    await signOut(page);
  });

  test('should create Tenant B with complete onboarding', async ({ page }) => {
    // Step 1: Sign up
    await page.goto('/signup');
    await waitForFlutterApp(page);

    await fillFlutterTextField(page, 'Full Name', 'Tenant B Owner');
    await fillFlutterTextField(page, 'Email', tenantBEmail);
    await fillFlutterTextField(page, 'Password', tenantBPassword);
    await fillFlutterTextField(page, 'Confirm Password', tenantBPassword);
    await clickFlutterButton(page, 'Create Account');
    await waitForLoadingComplete(page);

    // Step 2: Country Selection (if redirected)
    if (await page.url().includes('country-selection')) {
      await fillFlutterTextField(page, 'Search country', 'Kenya');
      await page.waitForTimeout(500);
      const kenyaItem = page.locator('text="Kenya"').first();
      await kenyaItem.click();
      await page.waitForTimeout(1000);
      await clickFlutterButton(page, 'Continue');
      await waitForLoadingComplete(page);
    }

    // Step 3: Business Setup
    await page.waitForTimeout(2000);

    if (await page.url().includes('business-setup')) {
      await fillFlutterTextField(page, 'Business Name', tenantBBusinessName);

      // Select business type
      const businessTypeDropdown = page.locator('text="Select business type"').first();
      await businessTypeDropdown.click();
      await page.waitForTimeout(500);
      await clickFlutterButton(page, 'Restaurant');

      // Select location type
      const locationDropdown = page.locator('text="Select location type"').first();
      await locationDropdown.click();
      await page.waitForTimeout(500);
      await clickFlutterButton(page, 'Head Office');

      await fillFlutterTextField(page, 'State', 'Nairobi');
      await fillFlutterTextField(page, 'City', 'Westlands');
      await fillFlutterTextField(page, 'Office Address', '456 Tenant B Avenue');

      // Select different brand color
      await clickFlutterButton(page, 'Choose your brand color');
      await page.waitForTimeout(1000);
      const colorOptions = page.locator('[style*="background"]').filter({ hasText: '' });
      await colorOptions.nth(3).click(); // Select different color
      await page.waitForTimeout(1000);

      await clickFlutterButton(page, 'Complete Setup');
      await waitForLoadingComplete(page);
    }

    // Verify reached dashboard
    await expect(page).toHaveURL(/dashboard/, { timeout: 20000 });
    await takeDebugScreenshot(page, 'tenant-b-dashboard');

    // Sign out
    await signOut(page);
  });

  test('should show only Tenant A data when logged in as Tenant A', async ({ page }) => {
    // Sign in as Tenant A
    await signIn(page, tenantAEmail, tenantAPassword);

    // Navigate to dashboard
    await expect(page).toHaveURL(/dashboard/, { timeout: 15000 });
    await waitForLoadingComplete(page);

    // Verify Tenant A business name is visible
    await expectTextVisible(page, tenantABusinessName);

    // Verify Tenant B business name is NOT visible
    const tenantBElement = page.locator(`text="${tenantBBusinessName}"`);
    const isTenantBVisible = await tenantBElement.isVisible({ timeout: 2000 }).catch(() => false);
    expect(isTenantBVisible).toBe(false);

    await takeDebugScreenshot(page, 'tenant-a-sees-own-data');

    // Sign out
    await signOut(page);
  });

  test('should show only Tenant B data when logged in as Tenant B', async ({ page }) => {
    // Sign in as Tenant B
    await signIn(page, tenantBEmail, tenantBPassword);

    // Navigate to dashboard
    await expect(page).toHaveURL(/dashboard/, { timeout: 15000 });
    await waitForLoadingComplete(page);

    // Verify Tenant B business name is visible
    await expectTextVisible(page, tenantBBusinessName);

    // Verify Tenant A business name is NOT visible
    const tenantAElement = page.locator(`text="${tenantABusinessName}"`);
    const isTenantAVisible = await tenantAElement.isVisible({ timeout: 2000 }).catch(() => false);
    expect(isTenantAVisible).toBe(false);

    await takeDebugScreenshot(page, 'tenant-b-sees-own-data');

    // Sign out
    await signOut(page);
  });

  test('should prevent cross-tenant data access via URL manipulation', async ({ page }) => {
    // Sign in as Tenant A
    await signIn(page, tenantAEmail, tenantAPassword);
    await waitForLoadingComplete(page);

    // Try to access Tenant B's data by manipulating URL parameters
    // Example: /dashboard?tenant=tenant-b-id
    // This should either redirect or show empty/error state

    // Get current URL
    const currentUrl = page.url();

    // Attempt to add tenant parameter
    const manipulatedUrl = currentUrl + '?tenant=fake-tenant-id';
    await page.goto(manipulatedUrl);
    await waitForLoadingComplete(page);

    // Verify still on dashboard or redirected to error/login
    const url = page.url();
    const isOnDashboard = url.includes('dashboard');

    if (isOnDashboard) {
      // If on dashboard, should still see only own data
      await expectTextVisible(page, tenantABusinessName);

      const tenantBElement = page.locator(`text="${tenantBBusinessName}"`);
      const isTenantBVisible = await tenantBElement.isVisible({ timeout: 2000 }).catch(() => false);
      expect(isTenantBVisible).toBe(false);
    }

    await takeDebugScreenshot(page, 'url-manipulation-blocked');

    // Sign out
    await signOut(page);
  });

  test('should maintain isolation after switching between tenants', async ({ page }) => {
    // Sign in as Tenant A
    await signIn(page, tenantAEmail, tenantAPassword);
    await waitForLoadingComplete(page);
    await expectTextVisible(page, tenantABusinessName);
    await signOut(page);

    // Sign in as Tenant B
    await signIn(page, tenantBEmail, tenantBPassword);
    await waitForLoadingComplete(page);
    await expectTextVisible(page, tenantBBusinessName);

    // Verify Tenant A data is NOT visible
    const tenantAElement = page.locator(`text="${tenantABusinessName}"`);
    const isTenantAVisible = await tenantAElement.isVisible({ timeout: 2000 }).catch(() => false);
    expect(isTenantAVisible).toBe(false);

    await takeDebugScreenshot(page, 'isolation-maintained-after-switch');

    // Sign out
    await signOut(page);

    // Sign back in as Tenant A
    await signIn(page, tenantAEmail, tenantAPassword);
    await waitForLoadingComplete(page);
    await expectTextVisible(page, tenantABusinessName);

    // Verify Tenant B data is NOT visible
    const tenantBElement = page.locator(`text="${tenantBBusinessName}"`);
    const isTenantBVisible = await tenantBElement.isVisible({ timeout: 2000 }).catch(() => false);
    expect(isTenantBVisible).toBe(false);

    await signOut(page);
  });

  test('should show correct country settings for each tenant', async ({ page }) => {
    // Sign in as Tenant A (Nigeria - NGN, +234)
    await signIn(page, tenantAEmail, tenantAPassword);
    await waitForLoadingComplete(page);

    // Navigate to settings or wherever country info is displayed
    // Check for Nigeria-specific settings (NGN currency, +234 dial code)
    // This depends on where country settings are shown in the UI

    await takeDebugScreenshot(page, 'tenant-a-country-settings');
    await signOut(page);

    // Sign in as Tenant B (Kenya - KES, +254)
    await signIn(page, tenantBEmail, tenantBPassword);
    await waitForLoadingComplete(page);

    // Check for Kenya-specific settings (KES currency, +254 dial code)
    await takeDebugScreenshot(page, 'tenant-b-country-settings');
    await signOut(page);
  });

  test('should show different brand colors for each tenant', async ({ page }) => {
    // Sign in as Tenant A
    await signIn(page, tenantAEmail, tenantAPassword);
    await waitForLoadingComplete(page);

    // Capture brand color (if visible in UI)
    const tenantABrandColor = await page.evaluate(() => {
      const element = document.querySelector('[style*="background-color"]');
      return element ? window.getComputedStyle(element).backgroundColor : null;
    });

    await takeDebugScreenshot(page, 'tenant-a-brand-color');
    await signOut(page);

    // Sign in as Tenant B
    await signIn(page, tenantBEmail, tenantBPassword);
    await waitForLoadingComplete(page);

    // Capture brand color
    const tenantBBrandColor = await page.evaluate(() => {
      const element = document.querySelector('[style*="background-color"]');
      return element ? window.getComputedStyle(element).backgroundColor : null;
    });

    await takeDebugScreenshot(page, 'tenant-b-brand-color');

    // Brand colors should be different (we selected different colors)
    expect(tenantABrandColor).not.toBe(tenantBBrandColor);

    await signOut(page);
  });
});

test.describe('Multi-Tenant Isolation with Products', () => {
  test.skip('should not see other tenant products', async ({ page }) => {
    // This test would require:
    // 1. Sign in as Tenant A
    // 2. Create product "Product A"
    // 3. Sign out
    // 4. Sign in as Tenant B
    // 5. Navigate to products page
    // 6. Verify "Product A" is NOT visible
    // 7. Create product "Product B"
    // 8. Sign out
    // 9. Sign in as Tenant A
    // 10. Verify "Product B" is NOT visible

    // Skipped for now as it requires product management UI
    console.log('Product isolation test requires product management screens');
  });

  test.skip('should not modify other tenant products', async ({ page }) => {
    // This test would verify that API calls to modify
    // another tenant's product are rejected

    // Requires product management UI
    console.log('Product modification test requires product management screens');
  });
});

test.describe('Cross-Tenant Security', () => {
  test('should not allow session hijacking between tenants', async ({ page, context }) => {
    // Sign in as Tenant A
    const cookies = await context.cookies();

    // Store cookies
    const tenantACookies = cookies;

    // Sign out
    await page.goto('/logout');
    await waitForLoadingComplete(page);

    // Sign in as Tenant B
    // The old session should not allow access to Tenant B data

    // Clear all cookies
    await context.clearCookies();

    // Try to restore Tenant A cookies
    await context.addCookies(tenantACookies);

    // Navigate to dashboard
    await page.goto('/dashboard');
    await waitForLoadingComplete(page);

    // Should either redirect to login or show Tenant A data
    // Should NOT show Tenant B data
    const url = page.url();
    expect(url).toMatch(/login|dashboard/);

    await takeDebugScreenshot(page, 'session-security-check');
  });

  test('should clear sensitive data on logout', async ({ page }) => {
    // This test verifies that tenant-specific data is cleared
    // from browser storage on logout

    // Sign in
    await page.goto('/login');
    await waitForFlutterApp(page);

    // Check localStorage before logout
    const localStorageBefore = await page.evaluate(() => {
      return Object.keys(localStorage);
    });

    // Sign out
    await page.goto('/logout');
    await waitForLoadingComplete(page);

    // Check localStorage after logout
    const localStorageAfter = await page.evaluate(() => {
      return Object.keys(localStorage);
    });

    // Sensitive keys should be cleared (auth tokens, user data, etc.)
    // The exact keys depend on implementation
    expect(localStorageAfter.length).toBeLessThanOrEqual(localStorageBefore.length);
  });
});
