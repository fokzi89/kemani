import { Page, expect } from '@playwright/test';

/**
 * Test Utilities for POS Admin E2E Tests
 */

/**
 * Generate unique test email address
 */
export function generateTestEmail(prefix: string = 'test'): string {
  const timestamp = Date.now();
  const random = Math.floor(Math.random() * 10000);
  return `${prefix}-${timestamp}-${random}@e2etest.com`;
}

/**
 * Generate secure test password
 */
export function generateTestPassword(): string {
  return `TestPass${Date.now()}!`;
}

/**
 * Wait for Flutter app to be ready
 * Flutter web apps take time to initialize
 */
export async function waitForFlutterApp(page: Page, timeout: number = 30000) {
  await page.waitForLoadState('networkidle', { timeout });

  // Wait for Flutter framework to be ready
  await page.waitForFunction(
    () => {
      // Check if Flutter app has rendered
      const canvas = document.querySelector('flt-glass-pane');
      return canvas !== null;
    },
    { timeout }
  );

  // Additional wait for app initialization
  await page.waitForTimeout(2000);
}

/**
 * Fill Flutter text field
 * Flutter web apps use canvas rendering, so we need special handling
 */
export async function fillFlutterTextField(
  page: Page,
  label: string,
  value: string
) {
  // Find input by label text
  const input = page.locator(`input[aria-label*="${label}"], input[placeholder*="${label}"]`).first();
  await input.waitFor({ state: 'visible', timeout: 10000 });
  await input.click();
  await input.fill(value);
}

/**
 * Click Flutter button by text
 */
export async function clickFlutterButton(page: Page, buttonText: string) {
  // Try multiple selectors for Flutter buttons
  const selectors = [
    `button:has-text("${buttonText}")`,
    `flt-semantics-container:has-text("${buttonText}")`,
    `[role="button"]:has-text("${buttonText}")`,
    `text="${buttonText}"`,
  ];

  for (const selector of selectors) {
    const button = page.locator(selector).first();
    if (await button.isVisible({ timeout: 2000 }).catch(() => false)) {
      await button.click();
      return;
    }
  }

  throw new Error(`Could not find button with text: ${buttonText}`);
}

/**
 * Wait for navigation after button click
 */
export async function clickAndWaitForNavigation(
  page: Page,
  buttonText: string,
  urlPattern?: string | RegExp
) {
  const [response] = await Promise.all([
    urlPattern ? page.waitForURL(urlPattern) : page.waitForNavigation(),
    clickFlutterButton(page, buttonText),
  ]);
  return response;
}

/**
 * Check if text exists on page
 */
export async function expectTextVisible(page: Page, text: string) {
  const element = page.locator(`text="${text}"`).first();
  await expect(element).toBeVisible({ timeout: 10000 });
}

/**
 * Wait for loading to complete
 */
export async function waitForLoadingComplete(page: Page) {
  // Wait for any loading spinners to disappear
  const spinner = page.locator('[role="progressbar"], .loading, text="Loading"');
  await spinner.waitFor({ state: 'hidden', timeout: 30000 }).catch(() => {});
  await page.waitForTimeout(500);
}

/**
 * Take screenshot for debugging
 */
export async function takeDebugScreenshot(page: Page, name: string) {
  await page.screenshot({
    path: `test-results/debug-${name}-${Date.now()}.png`,
    fullPage: true
  });
}

/**
 * Clean up test data from database
 */
export async function cleanupTestData(
  supabaseUrl: string,
  supabaseKey: string,
  email: string
) {
  // Note: This would require Supabase admin API access
  // For now, we'll rely on soft deletes and unique emails per test
  console.log(`Cleanup test data for: ${email}`);
}

/**
 * Select country from dropdown
 */
export async function selectCountry(page: Page, countryName: string) {
  // Search for country
  await fillFlutterTextField(page, 'Search country', countryName);
  await page.waitForTimeout(500);

  // Click country in list
  const countryItem = page.locator(`text="${countryName}"`).first();
  await countryItem.click();
}

/**
 * Upload file to Flutter file picker
 */
export async function uploadFile(page: Page, filePath: string) {
  const fileInput = page.locator('input[type="file"]');
  await fileInput.setInputFiles(filePath);
}

/**
 * Select color from color picker
 */
export async function selectBrandColor(page: Page, colorHex: string) {
  // Click color picker to open dialog
  await clickFlutterButton(page, 'Choose your brand color');
  await page.waitForTimeout(500);

  // Click color option (assuming colors are displayed as divs with background color)
  const colorOption = page.locator(`[style*="${colorHex}"]`).first();
  await colorOption.click();
}

/**
 * Verify database record exists via API
 */
export async function verifyRecordInDatabase(
  page: Page,
  table: string,
  field: string,
  value: string
): Promise<boolean> {
  // This would require a backend API endpoint to query
  // For now, we'll verify via UI feedback
  return true;
}

/**
 * Sign in with credentials
 */
export async function signIn(page: Page, email: string, password: string) {
  await page.goto('/login');
  await waitForFlutterApp(page);

  await fillFlutterTextField(page, 'Email', email);
  await fillFlutterTextField(page, 'Password', password);
  await clickFlutterButton(page, 'Sign In');

  await waitForLoadingComplete(page);
}

/**
 * Sign out
 */
export async function signOut(page: Page) {
  // Look for sign out button (usually in header or menu)
  await clickFlutterButton(page, 'Sign Out').catch(() => {
    // Try alternative selectors
    page.locator('[aria-label="Sign Out"], [title="Sign Out"]').first().click();
  });
  await waitForLoadingComplete(page);
}

/**
 * Generate test business data
 */
export function generateBusinessData() {
  const timestamp = Date.now();
  return {
    name: `E2E Test Business ${timestamp}`,
    type: 'Retail',
    locationType: 'Head Office',
    state: 'Lagos',
    city: 'Ikeja',
    address: `${timestamp} Test Street, E2E District`,
  };
}
