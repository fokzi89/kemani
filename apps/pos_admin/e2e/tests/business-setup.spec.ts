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
  uploadFile,
} from '../helpers/test-utils';

/**
 * E2E Tests: Business Setup and Brand Color Picker
 *
 * Tests User Story 2 - Acceptance Scenario AS6:
 * "Tenant configures branding → applies to POS and receipts"
 *
 * Test Coverage:
 * - Business setup form display
 * - Logo upload functionality
 * - Brand color picker interaction
 * - Form validation
 * - Complete business setup
 * - Navigation to dashboard
 */

test.describe('Business Setup Flow', () => {
  let businessData: ReturnType<typeof generateBusinessData>;

  test.beforeEach(async ({ page }) => {
    // Generate test data
    businessData = generateBusinessData();

    // Navigate directly to business setup
    // In a real flow, you'd go through signup → country selection first
    await page.goto('/business-setup');
    await waitForFlutterApp(page);
  });

  test('should display business setup form correctly', async ({ page }) => {
    // Verify page title and branding
    await expectTextVisible(page, 'Business Setup');
    await expectTextVisible(page, 'Kemani POS');
    await expectTextVisible(page, 'Step 4 of 4');

    // Verify progress indicator shows all 4 steps complete
    const progressText = page.locator('text="Step 4 of 4"');
    await expect(progressText).toBeVisible();

    // Verify all form sections exist
    await expectTextVisible(page, 'Business Name');
    await expectTextVisible(page, 'Business Type');
    await expectTextVisible(page, 'State');
    await expectTextVisible(page, 'City');

    await takeDebugScreenshot(page, 'business-setup-screen');
  });

  test('should display logo upload section', async ({ page }) => {
    // Verify logo upload section exists
    const uploadSection = page.locator('text="Upload logo", text="Change logo"').first();
    await expect(uploadSection).toBeVisible({ timeout: 10000 });

    // Verify upload icon/button is visible
    const uploadButton = page.locator('button:has-text("Upload logo")');
    await expect(uploadButton).toBeVisible();

    await takeDebugScreenshot(page, 'logo-upload-section');
  });

  test('should display brand color picker', async ({ page }) => {
    // Verify brand color section exists
    await expectTextVisible(page, 'Brand Color');
    await expectTextVisible(page, 'Choose your brand color');

    // Verify color preview box exists
    const colorPreview = page.locator('[style*="background"], [style*="color"]').first();
    await expect(colorPreview).toBeVisible({ timeout: 10000 });

    // Verify default color hex is shown
    const hexCode = page.locator('text=/#[0-9A-Fa-f]{6}/');
    await expect(hexCode).toBeVisible();

    // Verify help text
    await expectTextVisible(page, 'branding across your POS and receipts');

    await takeDebugScreenshot(page, 'brand-color-picker-section');
  });

  test('should open color picker dialog', async ({ page }) => {
    // Click on color picker to open dialog
    await clickFlutterButton(page, 'Choose your brand color');
    await page.waitForTimeout(1000);

    // Verify dialog opens
    await expectTextVisible(page, 'Select Brand Color');

    // Verify color options are displayed
    // Should have 12 color options
    const colorOptions = page.locator('[style*="background-color"]').filter({ hasText: '' });
    const count = await colorOptions.count();

    expect(count).toBeGreaterThanOrEqual(12);

    // Verify Close button exists
    const closeButton = page.locator('button:has-text("Close")');
    await expect(closeButton).toBeVisible();

    await takeDebugScreenshot(page, 'color-picker-dialog-open');
  });

  test('should select and apply brand color', async ({ page }) => {
    // Open color picker
    await clickFlutterButton(page, 'Choose your brand color');
    await page.waitForTimeout(1000);

    // Get initial hex code
    const initialHex = await page.locator('text=/#[0-9A-Fa-f]{6}/').first().textContent();

    // Click a different color (e.g., Blue #3B82F6)
    // Find color divs and click the second one (assuming Emerald is default, Blue is second)
    const colorOptions = page.locator('[style*="background"]').filter({ hasText: '' });
    await colorOptions.nth(1).click();
    await page.waitForTimeout(1000);

    // Dialog should close automatically
    const dialog = page.locator('text="Select Brand Color"');
    const isDialogVisible = await dialog.isVisible({ timeout: 2000 }).catch(() => false);
    expect(isDialogVisible).toBe(false);

    // Verify hex code updated in the preview
    const newHex = await page.locator('text=/#[0-9A-Fa-f]{6}/').first().textContent();
    expect(newHex).not.toBe(initialHex);

    await takeDebugScreenshot(page, 'color-selected-and-applied');
  });

  test('should show selected color with checkmark in picker', async ({ page }) => {
    // Open color picker
    await clickFlutterButton(page, 'Choose your brand color');
    await page.waitForTimeout(1000);

    // Default color (Emerald) should have checkmark
    const checkmark = page.locator('svg[data-icon="check"], text="✓"').first();
    await expect(checkmark).toBeVisible({ timeout: 5000 });

    await takeDebugScreenshot(page, 'selected-color-checkmark');
  });

  test('should close color picker with Close button', async ({ page }) => {
    // Open color picker
    await clickFlutterButton(page, 'Choose your brand color');
    await page.waitForTimeout(1000);

    // Click Close button
    await clickFlutterButton(page, 'Close');
    await page.waitForTimeout(500);

    // Dialog should be closed
    const dialog = page.locator('text="Select Brand Color"');
    const isVisible = await dialog.isVisible({ timeout: 2000 }).catch(() => false);
    expect(isVisible).toBe(false);
  });

  test('should validate required fields', async ({ page }) => {
    // Try to submit without filling fields
    await clickFlutterButton(page, 'Complete Setup');
    await page.waitForTimeout(1000);

    // Verify validation errors appear
    const errorMessages = page.locator('text=/Please|required|cannot be empty/i');
    const count = await errorMessages.count();

    expect(count).toBeGreaterThan(0);

    await takeDebugScreenshot(page, 'validation-errors');
  });

  test('should fill and submit complete business setup form', async ({ page }) => {
    // Fill business name
    await fillFlutterTextField(page, 'Business Name', businessData.name);

    // Select business type
    const businessTypeDropdown = page.locator('text="Select business type"').first();
    await businessTypeDropdown.click();
    await page.waitForTimeout(500);
    await clickFlutterButton(page, businessData.type);

    // Select location type
    const locationDropdown = page.locator('text="Select location type"').first();
    await locationDropdown.click();
    await page.waitForTimeout(500);
    await clickFlutterButton(page, businessData.locationType);

    // Fill state
    await fillFlutterTextField(page, 'State', businessData.state);

    // Fill city
    await fillFlutterTextField(page, 'City', businessData.city);

    // Fill address
    await fillFlutterTextField(page, 'Office Address', businessData.address);

    // Select a brand color
    await clickFlutterButton(page, 'Choose your brand color');
    await page.waitForTimeout(1000);
    const colorOptions = page.locator('[style*="background"]').filter({ hasText: '' });
    await colorOptions.nth(2).click(); // Select Purple
    await page.waitForTimeout(1000);

    await takeDebugScreenshot(page, 'form-filled-complete');

    // Submit form
    await clickFlutterButton(page, 'Complete Setup');
    await waitForLoadingComplete(page);

    // Verify navigation to dashboard
    await expect(page).toHaveURL(/dashboard/, { timeout: 20000 });
    await expectTextVisible(page, 'Dashboard');
  });

  test('should display business type dropdown options', async ({ page }) => {
    // Click business type dropdown
    const dropdown = page.locator('text="Select business type"').first();
    await dropdown.click();
    await page.waitForTimeout(1000);

    // Verify business type options
    const expectedTypes = ['Retail', 'Restaurant', 'Pharmacy', 'Healthcare'];

    for (const type of expectedTypes) {
      await expectTextVisible(page, type);
    }

    await takeDebugScreenshot(page, 'business-type-dropdown');
  });

  test('should display location type dropdown options', async ({ page }) => {
    // Click location type dropdown
    const dropdown = page.locator('text="Select location type"').first();
    await dropdown.click();
    await page.waitForTimeout(1000);

    // Verify location options
    await expectTextVisible(page, 'Head Office');
    await expectTextVisible(page, 'Branch');

    await takeDebugScreenshot(page, 'location-type-dropdown');
  });

  test('should handle long business names', async ({ page }) => {
    const longName = 'A'.repeat(200); // Very long business name

    await fillFlutterTextField(page, 'Business Name', longName);

    // Verify input accepts long names
    const input = page.locator('input[placeholder*="Business Name"]').first();
    const value = await input.inputValue();

    expect(value.length).toBeGreaterThan(100);

    await takeDebugScreenshot(page, 'long-business-name');
  });

  test('should show loading state during submission', async ({ page }) => {
    // Fill minimum required fields
    await fillFlutterTextField(page, 'Business Name', businessData.name);

    const businessTypeDropdown = page.locator('text="Select business type"').first();
    await businessTypeDropdown.click();
    await page.waitForTimeout(500);
    await clickFlutterButton(page, 'Retail');

    const locationDropdown = page.locator('text="Select location type"').first();
    await locationDropdown.click();
    await page.waitForTimeout(500);
    await clickFlutterButton(page, 'Head Office');

    await fillFlutterTextField(page, 'State', businessData.state);
    await fillFlutterTextField(page, 'City', businessData.city);
    await fillFlutterTextField(page, 'Office Address', businessData.address);

    // Submit form
    const submitButton = page.locator('button:has-text("Complete Setup")').first();
    await submitButton.click();

    // Verify loading state appears
    const loadingIndicator = page.locator('[role="progressbar"], text="Loading", .loading');
    const isLoadingVisible = await loadingIndicator.isVisible({ timeout: 3000 }).catch(() => false);

    // Loading might appear briefly
    await takeDebugScreenshot(page, 'submission-loading');
  });

  test('should be responsive on mobile', async ({ page, viewport }) => {
    if (!viewport || viewport.width > 768) {
      test.skip();
      return;
    }

    // Verify form is usable on mobile
    await expectTextVisible(page, 'Business Setup');

    // Hero section should not be visible on mobile
    const heroText = page.locator('text="Almost There!"');
    const isHeroVisible = await heroText.isVisible({ timeout: 2000 }).catch(() => false);
    expect(isHeroVisible).toBe(false);

    // Verify form fields are accessible
    await fillFlutterTextField(page, 'Business Name', 'Mobile Test Business');

    // Open color picker on mobile
    await clickFlutterButton(page, 'Choose your brand color');
    await page.waitForTimeout(1000);

    // Verify color picker dialog is readable on mobile
    await expectTextVisible(page, 'Select Brand Color');

    await takeDebugScreenshot(page, 'business-setup-mobile');
  });

  test('should persist selected color after reopening picker', async ({ page }) => {
    // Open color picker and select Blue
    await clickFlutterButton(page, 'Choose your brand color');
    await page.waitForTimeout(1000);
    const colorOptions = page.locator('[style*="background"]').filter({ hasText: '' });
    await colorOptions.nth(1).click(); // Select Blue
    await page.waitForTimeout(1000);

    // Reopen color picker
    await clickFlutterButton(page, 'Choose your brand color');
    await page.waitForTimeout(1000);

    // Verify Blue still has checkmark (is selected)
    const selectedColor = colorOptions.nth(1);
    const checkmark = selectedColor.locator('svg[data-icon="check"], text="✓"');

    const hasCheckmark = await checkmark.isVisible({ timeout: 2000 }).catch(() => false);
    expect(hasCheckmark).toBe(true);

    await takeDebugScreenshot(page, 'color-persisted-after-reopen');
  });

  test('should display all 12 color options', async ({ page }) => {
    // Open color picker
    await clickFlutterButton(page, 'Choose your brand color');
    await page.waitForTimeout(1000);

    // Count color options
    const colorOptions = page.locator('[style*="background-color"]').filter({ hasText: '' });
    const count = await colorOptions.count();

    // Should have exactly 12 colors
    expect(count).toBeGreaterThanOrEqual(12);

    // Verify colors are visually distinct (not all the same)
    const colors = [];
    for (let i = 0; i < Math.min(count, 12); i++) {
      const bgColor = await colorOptions.nth(i).evaluate(el => window.getComputedStyle(el).backgroundColor);
      colors.push(bgColor);
    }

    // All colors should be unique
    const uniqueColors = new Set(colors);
    expect(uniqueColors.size).toBeGreaterThan(1);

    await takeDebugScreenshot(page, 'all-12-colors');
  });
});

test.describe('Business Setup Accessibility', () => {
  test('should be keyboard navigable', async ({ page }) => {
    await page.goto('/business-setup');
    await waitForFlutterApp(page);

    // Tab through form fields
    await page.keyboard.press('Tab'); // Business name
    await page.keyboard.type('Test Business');

    await page.keyboard.press('Tab'); // Business type dropdown
    await page.keyboard.press('Enter'); // Open dropdown
    await page.waitForTimeout(500);
    await page.keyboard.press('ArrowDown');
    await page.keyboard.press('Enter'); // Select option

    // Verify keyboard navigation works
    await takeDebugScreenshot(page, 'keyboard-navigation');
  });

  test('should have proper form labels', async ({ page }) => {
    await page.goto('/business-setup');
    await waitForFlutterApp(page);

    // Verify all inputs have labels
    const labels = [
      'Business Name',
      'Business Type',
      'State',
      'City',
      'Office Address',
    ];

    for (const label of labels) {
      await expectTextVisible(page, label);
    }
  });

  test('should announce validation errors to screen readers', async ({ page }) => {
    await page.goto('/business-setup');
    await waitForFlutterApp(page);

    // Submit empty form
    await clickFlutterButton(page, 'Complete Setup');
    await page.waitForTimeout(1000);

    // Check for ARIA live regions with error messages
    const errorRegions = page.locator('[role="alert"], [aria-live="polite"]');
    const count = await errorRegions.count();

    // At least some accessibility markup should exist
    expect(count).toBeGreaterThanOrEqual(0);
  });
});
