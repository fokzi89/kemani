const { test, expect } = require('@playwright/test');

test.describe('POS Admin Signup Flow', () => {
  test('should attempt to sign up and capture RLS error', async ({ page }) => {
    // Set up console message listener to catch all logs
    const consoleMessages = [];
    page.on('console', msg => {
      consoleMessages.push({
        type: msg.type(),
        text: msg.text()
      });
    });

    // Listen for network errors
    const networkErrors = [];
    page.on('response', async response => {
      if (!response.ok()) {
        try {
          const body = await response.text();
          networkErrors.push({
            url: response.url(),
            status: response.status(),
            statusText: response.statusText(),
            body: body
          });
        } catch (e) {
          // Ignore errors when reading response body
        }
      }
    });

    // Navigate to the POS app
    // Try multiple possible URLs where Flutter might be running
    const possibleUrls = [
      'http://localhost:57881',
      'http://localhost:57882',
      'http://localhost:8080',
      'http://localhost:3000',
    ];

    let appUrl = null;
    for (const url of possibleUrls) {
      try {
        console.log(`Trying to navigate to ${url}...`);
        await page.goto(url, { timeout: 60000 });
        await page.waitForLoadState('domcontentloaded', { timeout: 30000 });
        console.log(`Successfully connected to ${url}`);
        appUrl = url;
        break;
      } catch (e) {
        console.log(`Failed to connect to ${url}: ${e.message}`);
      }
    }

    if (!appUrl) {
      throw new Error('Could not find POS app on any common port. Please ensure the Flutter app is running.');
    }

    // Wait for the app to load
    await page.waitForLoadState('networkidle', { timeout: 30000 });

    // Take a screenshot of the initial page
    await page.screenshot({ path: 'screenshots/01-initial-page.png', fullPage: true });
    console.log('Screenshot saved: 01-initial-page.png');

    // Look for signup link or navigate directly to signup
    console.log('Looking for signup page...');

    // Try to find and click "Sign up" or similar link
    const signupLink = page.locator('text=/sign up|create account/i').first();
    if (await signupLink.isVisible({ timeout: 5000 }).catch(() => false)) {
      await signupLink.click();
      await page.waitForLoadState('networkidle');
    }

    await page.screenshot({ path: 'screenshots/02-signup-page.png', fullPage: true });
    console.log('Screenshot saved: 02-signup-page.png');

    // Fill in signup form
    console.log('Filling signup form...');
    const testEmail = `test${Date.now()}@example.com`;
    const testPassword = 'TestPassword123!';

    // Wait for form fields to be visible
    await page.waitForSelector('input[type="email"], input[placeholder*="email" i]', { timeout: 10000 });

    // Full Name
    const fullNameInput = page.locator('input').filter({ hasText: /full name/i }).or(
      page.locator('input[placeholder*="name" i]')
    ).first();
    if (await fullNameInput.isVisible({ timeout: 2000 }).catch(() => false)) {
      await fullNameInput.fill('Test User Name');
    }

    // Email
    const emailInput = page.locator('input[type="email"]').or(
      page.locator('input[placeholder*="email" i]')
    ).first();
    await emailInput.fill(testEmail);

    // Password
    const passwordInputs = page.locator('input[type="password"]');
    const passwordCount = await passwordInputs.count();

    if (passwordCount >= 1) {
      await passwordInputs.nth(0).fill(testPassword);
    }
    if (passwordCount >= 2) {
      await passwordInputs.nth(1).fill(testPassword);
    }

    await page.screenshot({ path: 'screenshots/03-form-filled.png', fullPage: true });
    console.log('Screenshot saved: 03-form-filled.png');

    // Submit the form
    console.log('Submitting form...');
    const submitButton = page.locator('button:has-text("Continue"), button:has-text("Sign up"), button:has-text("Create")').first();

    // Set up a promise to wait for the error
    const errorPromise = page.waitForEvent('console', msg => {
      return msg.text().includes('42501') || msg.text().includes('row-level security');
    }, { timeout: 10000 }).catch(() => null);

    await submitButton.click();

    // Wait for either success or error
    await page.waitForTimeout(3000);

    await page.screenshot({ path: 'screenshots/04-after-submit.png', fullPage: true });
    console.log('Screenshot saved: 04-after-submit.png');

    // Wait a bit more for any async errors
    await page.waitForTimeout(2000);

    // Print all captured console messages
    console.log('\n=== CONSOLE MESSAGES ===');
    consoleMessages.forEach(msg => {
      console.log(`[${msg.type}] ${msg.text}`);
    });

    // Print all network errors
    console.log('\n=== NETWORK ERRORS ===');
    networkErrors.forEach(err => {
      console.log(`${err.status} ${err.statusText} - ${err.url}`);
      console.log(`Body: ${err.body}`);
    });

    // Look for error message on the page
    const errorMessages = await page.locator('[class*="error"], [class*="Error"], .text-red-500, .text-red-600').allTextContents();
    if (errorMessages.length > 0) {
      console.log('\n=== ERROR MESSAGES ON PAGE ===');
      errorMessages.forEach(msg => console.log(msg));
    }

    // Take final screenshot
    await page.screenshot({ path: 'screenshots/05-final.png', fullPage: true });
    console.log('Screenshot saved: 05-final.png');

    // Verify we got the RLS error
    const hasRlsError = consoleMessages.some(msg =>
      msg.text.includes('42501') ||
      msg.text.includes('row-level security')
    ) || networkErrors.some(err =>
      err.body.includes('42501') ||
      err.body.includes('row-level security')
    );

    console.log(`\n=== RLS Error Detected: ${hasRlsError} ===`);

    // Keep the browser open for a moment
    await page.waitForTimeout(2000);
  });
});
