import { test, expect } from '@playwright/test';

test('Verify Expense Flow and Dashboard Stability', async ({ page }) => {
  // Capture console logs for debugging
  page.on('console', msg => console.log(`BROWSER: ${msg.text()}`));
  page.on('pageerror', err => console.log(`BROWSER ERROR: ${err.message}`));

  // Navigate to login
  await page.goto('http://localhost:5176/login');
  
  // Fill credentials
  await page.fill('input[type="email"]', 'adeola@gmail.com');
  await page.fill('input[type="password"]', '123456');
  await page.click('button[type="submit"]');
  
  // Wait for login to complete and redirect to dashboard
  await page.waitForURL('**/');
  await expect(page.locator('h1:has-text("Business Dashboard")')).toBeVisible({ timeout: 15000 });
  
  // Navigate to Expenses page
  await page.goto('http://localhost:5176/expenses');
  await page.waitForURL('**/expenses');
  
  // Wait for page to be stable
  await page.waitForLoadState('networkidle');
  
  // Click Add New Expense
  const addButton = page.locator('button:has-text("Add New Expense")');
  await addButton.waitFor({ state: 'visible' });
  await addButton.click();
  
  // Wait for modal header "Raise New Bill"
  // The fix (missing Plus import) should ensure this is now visible
  await expect(page.locator('h2:has-text("Raise New Bill")')).toBeVisible({ timeout: 10000 });
  
  // Fill form
  const testDesc = `Regression test - ${new Date().toISOString()}`;
  await page.fill('input#amount', '2500');
  await page.fill('textarea#desc', testDesc);
  
  // Click Submit
  await page.click('button:has-text("Submit")');
  
  // Wait for modal to close
  await expect(page.locator('h2:has-text("Raise New Bill")')).toBeHidden({ timeout: 10000 });
  
  // Verify the new expense is in the table
  await expect(page.locator(`td:has-text("${testDesc}")`)).toBeVisible({ timeout: 10000 });
  
  console.log('Expense flow verified successfully!');
});
