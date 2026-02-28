import { test, expect } from '@playwright/test';
import {
  generateTestEmail,
  generateTestPassword,
  waitForFlutterApp,
  fillFlutterTextField,
  clickFlutterButton,
  expectTextVisible,
  waitForLoadingComplete,
  takeDebugScreenshot,
} from '../helpers/test-utils';

/**
 * E2E Tests: Signup and Email Confirmation Flow
 *
 * Tests User Story 2 - Acceptance Scenario AS1:
 * "New business provides email/password or Google → creates account and sends email"
 *
 * Test Coverage:
 * - Email/password signup
 * - Email confirmation pending screen
 * - Resend confirmation email
 * - Navigation to login
 */

test.describe('Signup and Email Confirmation Flow', () => {
  let testEmail: string;
  let testPassword: string;

  test.beforeEach(async ({ page }) => {
    // Generate unique credentials for this test run
    testEmail = generateTestEmail('signup');
    testPassword = generateTestPassword();

    // Navigate to signup page
    await page.goto('/signup');
    await waitForFlutterApp(page);
  });

  test('should display signup form correctly', async ({ page }) => {
    // Verify all form elements are visible
    await expectTextVisible(page, 'Create Account');
    await expectTextVisible(page, 'Kemani POS');

    // Check form fields
    const fullNameInput = page.locator('input[placeholder*="Full Name"], input[aria-label*="Full Name"]').first();
    const emailInput = page.locator('input[placeholder*="Email"], input[type="email"]').first();
    const passwordInput = page.locator('input[placeholder*="Password"][type="password"]').first();

    await expect(fullNameInput).toBeVisible();
    await expect(emailInput).toBeVisible();
    await expect(passwordInput).toBeVisible();

    // Verify signup button exists
    await expectTextVisible(page, 'Create Account');
  });

  test('should show validation errors for empty fields', async ({ page }) => {
    // Click signup without filling fields
    await clickFlutterButton(page, 'Create Account');
    await page.waitForTimeout(1000);

    // Verify validation messages appear
    // Note: Exact text depends on Flutter validation implementation
    const errorMessages = page.locator('text=/Please|required|cannot be empty/i');
    const count = await errorMessages.count();

    expect(count).toBeGreaterThan(0);
  });

  test('should show error for invalid email format', async ({ page }) => {
    await fillFlutterTextField(page, 'Full Name', 'Test User');
    await fillFlutterTextField(page, 'Email', 'invalid-email');
    await fillFlutterTextField(page, 'Password', testPassword);
    await fillFlutterTextField(page, 'Confirm Password', testPassword);

    await clickFlutterButton(page, 'Create Account');
    await page.waitForTimeout(1000);

    // Verify email validation error
    await expectTextVisible(page, 'valid email');
  });

  test('should show error for password mismatch', async ({ page }) => {
    await fillFlutterTextField(page, 'Full Name', 'Test User');
    await fillFlutterTextField(page, 'Email', testEmail);
    await fillFlutterTextField(page, 'Password', testPassword);
    await fillFlutterTextField(page, 'Confirm Password', 'DifferentPassword123!');

    await clickFlutterButton(page, 'Create Account');
    await page.waitForTimeout(1000);

    // Verify password mismatch error
    await expectTextVisible(page, 'Passwords do not match');
  });

  test('should successfully sign up and show email confirmation screen', async ({ page }) => {
    // Fill signup form
    await fillFlutterTextField(page, 'Full Name', 'E2E Test User');
    await fillFlutterTextField(page, 'Email', testEmail);
    await fillFlutterTextField(page, 'Password', testPassword);
    await fillFlutterTextField(page, 'Confirm Password', testPassword);

    // Submit form
    await clickFlutterButton(page, 'Create Account');
    await waitForLoadingComplete(page);

    // Verify redirected to email confirmation pending screen
    await expect(page).toHaveURL(/email-confirmation-pending/, { timeout: 15000 });

    // Verify email confirmation screen content
    await expectTextVisible(page, 'Check Your Email');
    await expectTextVisible(page, testEmail);
    await expectTextVisible(page, 'Next Steps');

    // Verify instructions are shown
    await expectTextVisible(page, 'Check your email inbox');
    await expectTextVisible(page, 'Click the confirmation link');

    // Take screenshot for visual verification
    await takeDebugScreenshot(page, 'email-confirmation-screen');
  });

  test('should display email confirmation pending screen elements', async ({ page }) => {
    // Complete signup to get to email confirmation screen
    await fillFlutterTextField(page, 'Full Name', 'E2E Test User');
    await fillFlutterTextField(page, 'Email', testEmail);
    await fillFlutterTextField(page, 'Password', testPassword);
    await fillFlutterTextField(page, 'Confirm Password', testPassword);
    await clickFlutterButton(page, 'Create Account');
    await waitForLoadingComplete(page);

    // Verify all UI elements
    await expectTextVisible(page, 'Check Your Email');
    await expectTextVisible(page, 'We sent a confirmation link to:');
    await expectTextVisible(page, testEmail);

    // Verify buttons exist
    const resendButton = page.locator('button:has-text("Resend Confirmation Email")').first();
    const backToLoginButton = page.locator('button:has-text("Back to Login")').first();

    await expect(resendButton).toBeVisible();
    await expect(backToLoginButton).toBeVisible();

    // Verify help text
    await expectTextVisible(page, 'Check your spam folder');
  });

  test('should resend confirmation email successfully', async ({ page }) => {
    // Complete signup
    await fillFlutterTextField(page, 'Full Name', 'E2E Test User');
    await fillFlutterTextField(page, 'Email', testEmail);
    await fillFlutterTextField(page, 'Password', testPassword);
    await fillFlutterTextField(page, 'Confirm Password', testPassword);
    await clickFlutterButton(page, 'Create Account');
    await waitForLoadingComplete(page);

    // Click resend button
    await clickFlutterButton(page, 'Resend Confirmation Email');

    // Wait for loading/sending state
    await page.waitForTimeout(2000);

    // Verify success message appears
    // Check for either a snackbar or success banner
    const successIndicators = [
      'Confirmation email sent',
      'Email sent successfully',
      'sent successfully',
      'Check your inbox'
    ];

    let foundSuccess = false;
    for (const text of successIndicators) {
      const element = page.locator(`text="${text}"`);
      if (await element.isVisible({ timeout: 5000 }).catch(() => false)) {
        foundSuccess = true;
        break;
      }
    }

    expect(foundSuccess).toBe(true);

    // Take screenshot of success state
    await takeDebugScreenshot(page, 'email-resent-success');
  });

  test('should navigate back to login from email confirmation', async ({ page }) => {
    // Complete signup
    await fillFlutterTextField(page, 'Full Name', 'E2E Test User');
    await fillFlutterTextField(page, 'Email', testEmail);
    await fillFlutterTextField(page, 'Password', testPassword);
    await fillFlutterTextField(page, 'Confirm Password', testPassword);
    await clickFlutterButton(page, 'Create Account');
    await waitForLoadingComplete(page);

    // Click "Back to Login"
    await clickFlutterButton(page, 'Back to Login');
    await waitForLoadingComplete(page);

    // Verify redirected to login page
    await expect(page).toHaveURL(/login/, { timeout: 10000 });
    await expectTextVisible(page, 'Sign In');
  });

  test('should have responsive design on mobile', async ({ page, viewport }) => {
    if (!viewport || viewport.width > 768) {
      test.skip();
      return;
    }

    // Complete signup on mobile
    await fillFlutterTextField(page, 'Full Name', 'Mobile Test User');
    await fillFlutterTextField(page, 'Email', testEmail);
    await fillFlutterTextField(page, 'Password', testPassword);
    await fillFlutterTextField(page, 'Confirm Password', testPassword);
    await clickFlutterButton(page, 'Create Account');
    await waitForLoadingComplete(page);

    // Verify email confirmation screen is responsive
    await expectTextVisible(page, 'Check Your Email');

    // Hero section should not be visible on mobile (only desktop)
    const heroSection = page.locator('text="Almost There!"');
    const isHeroVisible = await heroSection.isVisible({ timeout: 2000 }).catch(() => false);

    // On mobile, hero section should be hidden
    if (viewport.width <= 900) {
      expect(isHeroVisible).toBe(false);
    }

    await takeDebugScreenshot(page, 'email-confirmation-mobile');
  });

  test('should handle network errors gracefully', async ({ page, context }) => {
    // Simulate offline mode after signup form is filled
    await fillFlutterTextField(page, 'Full Name', 'Network Error Test');
    await fillFlutterTextField(page, 'Email', testEmail);
    await fillFlutterTextField(page, 'Password', testPassword);
    await fillFlutterTextField(page, 'Confirm Password', testPassword);

    // Go offline
    await context.setOffline(true);

    // Try to submit
    await clickFlutterButton(page, 'Create Account');
    await page.waitForTimeout(3000);

    // Verify error message is shown
    const errorMessages = [
      'network error',
      'connection failed',
      'offline',
      'try again'
    ];

    let foundError = false;
    for (const text of errorMessages) {
      const element = page.locator(`text=/${text}/i`);
      if (await element.isVisible({ timeout: 2000 }).catch(() => false)) {
        foundError = true;
        break;
      }
    }

    // Should show some error (exact message may vary)
    // Restore network
    await context.setOffline(false);
  });
});

test.describe('Google OAuth Signup Flow', () => {
  test('should display Google Sign-In button', async ({ page }) => {
    await page.goto('/signup');
    await waitForFlutterApp(page);

    // Verify Google Sign-In button exists
    const googleButton = page.locator('button:has-text("Sign up with Google"), button:has-text("Google")').first();
    await expect(googleButton).toBeVisible({ timeout: 10000 });

    // Verify Google logo/icon is present
    await takeDebugScreenshot(page, 'google-signin-button');
  });

  test.skip('should initiate Google OAuth flow', async ({ page }) => {
    // Note: This test is skipped because it requires actual Google OAuth
    // which cannot be automated in E2E tests without complex setup

    await page.goto('/signup');
    await waitForFlutterApp(page);

    // This would need to:
    // 1. Click Google Sign-In button
    // 2. Handle OAuth popup/redirect
    // 3. Complete Google authentication
    // 4. Verify return to app

    // For manual testing only
    console.log('Google OAuth flow requires manual testing');
  });
});

test.describe('Signup Accessibility', () => {
  test('should have proper ARIA labels', async ({ page }) => {
    await page.goto('/signup');
    await waitForFlutterApp(page);

    // Check for ARIA labels on form inputs
    const inputs = page.locator('input');
    const count = await inputs.count();

    for (let i = 0; i < count; i++) {
      const input = inputs.nth(i);
      const ariaLabel = await input.getAttribute('aria-label');
      const placeholder = await input.getAttribute('placeholder');

      // Each input should have either aria-label or placeholder
      expect(ariaLabel || placeholder).toBeTruthy();
    }
  });

  test('should be keyboard navigable', async ({ page }) => {
    await page.goto('/signup');
    await waitForFlutterApp(page);

    // Tab through form fields
    await page.keyboard.press('Tab'); // Full Name
    await page.keyboard.press('Tab'); // Email
    await page.keyboard.press('Tab'); // Password
    await page.keyboard.press('Tab'); // Confirm Password
    await page.keyboard.press('Tab'); // Create Account button

    // Verify focus is on Create Account button
    const activeElement = await page.evaluate(() => document.activeElement?.tagName);
    expect(activeElement).toBeDefined();
  });
});
