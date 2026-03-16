/**
 * E2E Test: Customer Registration Workflow
 * Task: T111 - End-to-end testing
 *
 * Tests the complete customer registration flow including:
 * - API endpoint for customer registration
 * - Validation of required fields
 * - Customer data persistence
 * - Initial loyalty points balance
 */

const { test, expect } = require('@playwright/test');

// Test configuration
const API_BASE = 'http://localhost:5173'; // SvelteKit dev server
const TEST_TENANT_ID = 'test-tenant-id'; // Replace with actual tenant ID

test.describe('Customer Registration Workflow', () => {
  let customerId;

  test('should register a new customer successfully', async ({ request }) => {
    // Arrange: Prepare customer data
    const customerData = {
      tenant_id: TEST_TENANT_ID,
      full_name: 'John Doe Test',
      email: `test-${Date.now()}@example.com`,
      phone: `+234800${Math.floor(Math.random() * 10000000)}`
    };

    // Act: Send registration request
    const response = await request.post(`${API_BASE}/api/customers`, {
      data: customerData
    });

    // Assert: Check response
    expect(response.ok()).toBeTruthy();
    expect(response.status()).toBe(200);

    const data = await response.json();
    expect(data.customer).toBeDefined();
    expect(data.customer.id).toBeDefined();
    expect(data.customer.full_name).toBe(customerData.full_name);
    expect(data.customer.email).toBe(customerData.email);
    expect(data.customer.phone).toBe(customerData.phone);
    expect(data.customer.loyalty_points_balance).toBe(0); // New customers start with 0 points

    // Store customer ID for cleanup
    customerId = data.customer.id;

    console.log('✅ Customer registered successfully:', data.customer.id);
  });

  test('should fail registration with missing required fields', async ({ request }) => {
    // Arrange: Incomplete customer data (missing phone)
    const incompleteData = {
      tenant_id: TEST_TENANT_ID,
      full_name: 'Incomplete Customer'
      // Missing phone number
    };

    // Act: Send registration request
    const response = await request.post(`${API_BASE}/api/customers`, {
      data: incompleteData
    });

    // Assert: Should fail
    expect(response.ok()).toBeFalsy();
    expect(response.status()).toBeGreaterThanOrEqual(400);

    console.log('✅ Registration correctly rejected incomplete data');
  });

  test('should retrieve customer details after registration', async ({ request }) => {
    // First, register a customer
    const customerData = {
      tenant_id: TEST_TENANT_ID,
      full_name: 'Jane Doe Test',
      email: `test-retrieve-${Date.now()}@example.com`,
      phone: `+234800${Math.floor(Math.random() * 10000000)}`
    };

    const registerResponse = await request.post(`${API_BASE}/api/customers`, {
      data: customerData
    });
    const registerData = await registerResponse.json();
    const newCustomerId = registerData.customer.id;

    // Act: Retrieve customer details
    const getResponse = await request.get(`${API_BASE}/api/customers/${newCustomerId}`);

    // Assert: Customer data should match
    expect(getResponse.ok()).toBeTruthy();
    const getData = await getResponse.json();
    expect(getData.customer.id).toBe(newCustomerId);
    expect(getData.customer.full_name).toBe(customerData.full_name);
    expect(getData.customer.email).toBe(customerData.email);

    console.log('✅ Customer details retrieved successfully');
  });

  test('should search for customers', async ({ request }) => {
    // Arrange: Register a customer with unique name
    const uniqueName = `Searchable Customer ${Date.now()}`;
    const customerData = {
      tenant_id: TEST_TENANT_ID,
      full_name: uniqueName,
      phone: `+234800${Math.floor(Math.random() * 10000000)}`
    };

    await request.post(`${API_BASE}/api/customers`, {
      data: customerData
    });

    // Act: Search for the customer
    const searchResponse = await request.get(
      `${API_BASE}/api/customers?search=${encodeURIComponent(uniqueName)}`
    );

    // Assert: Should find the customer
    expect(searchResponse.ok()).toBeTruthy();
    const searchData = await searchResponse.json();
    expect(searchData.customers).toBeDefined();
    expect(searchData.customers.length).toBeGreaterThan(0);

    const foundCustomer = searchData.customers.find(c => c.full_name === uniqueName);
    expect(foundCustomer).toBeDefined();

    console.log('✅ Customer search working correctly');
  });

  test('should add address for customer', async ({ request }) => {
    // First, register a customer
    const customerData = {
      tenant_id: TEST_TENANT_ID,
      full_name: 'Address Test Customer',
      phone: `+234800${Math.floor(Math.random() * 10000000)}`
    };

    const registerResponse = await request.post(`${API_BASE}/api/customers`, {
      data: customerData
    });
    const registerData = await registerResponse.json();
    const newCustomerId = registerData.customer.id;

    // Act: Add an address
    const addressData = {
      address_line1: '123 Test Street',
      city: 'Lagos',
      state: 'Lagos',
      country: 'Nigeria',
      is_default: true
    };

    const addressResponse = await request.post(
      `${API_BASE}/api/customers/${newCustomerId}/addresses`,
      { data: addressData }
    );

    // Assert: Address should be created
    expect(addressResponse.ok()).toBeTruthy();
    const addressResult = await addressResponse.json();
    expect(addressResult.address).toBeDefined();
    expect(addressResult.address.address_line1).toBe(addressData.address_line1);
    expect(addressResult.address.is_default).toBe(true);

    // Verify address can be retrieved
    const getAddressesResponse = await request.get(
      `${API_BASE}/api/customers/${newCustomerId}/addresses`
    );
    expect(getAddressesResponse.ok()).toBeTruthy();
    const addresses = await getAddressesResponse.json();
    expect(addresses.addresses.length).toBeGreaterThan(0);

    console.log('✅ Customer address management working correctly');
  });

  test('should update customer profile', async ({ request }) => {
    // First, register a customer
    const customerData = {
      tenant_id: TEST_TENANT_ID,
      full_name: 'Update Test Customer',
      phone: `+234800${Math.floor(Math.random() * 10000000)}`
    };

    const registerResponse = await request.post(`${API_BASE}/api/customers`, {
      data: customerData
    });
    const registerData = await registerResponse.json();
    const newCustomerId = registerData.customer.id;

    // Act: Update customer profile
    const updateData = {
      full_name: 'Updated Name',
      email: `updated-${Date.now()}@example.com`
    };

    const updateResponse = await request.put(
      `${API_BASE}/api/customers/${newCustomerId}`,
      { data: updateData }
    );

    // Assert: Profile should be updated
    expect(updateResponse.ok()).toBeTruthy();
    const updateResult = await updateResponse.json();
    expect(updateResult.customer.full_name).toBe(updateData.full_name);
    expect(updateResult.customer.email).toBe(updateData.email);

    console.log('✅ Customer profile update working correctly');
  });
});

test.describe('Customer Statistics', () => {
  test('should track customer statistics correctly', async ({ request }) => {
    // Register a customer
    const customerData = {
      tenant_id: TEST_TENANT_ID,
      full_name: 'Stats Test Customer',
      phone: `+234800${Math.floor(Math.random() * 10000000)}`
    };

    const registerResponse = await request.post(`${API_BASE}/api/customers`, {
      data: customerData
    });
    const registerData = await registerResponse.json();
    const newCustomerId = registerData.customer.id;

    // Get customer with stats
    const getResponse = await request.get(
      `${API_BASE}/api/customers/${newCustomerId}?include_stats=true`
    );

    expect(getResponse.ok()).toBeTruthy();
    const getData = await getResponse.json();

    // New customer should have zero stats
    expect(getData.customer.total_orders).toBe(0);
    expect(getData.customer.total_spent).toBe(0);
    expect(getData.customer.loyalty_points_balance).toBe(0);

    console.log('✅ Customer statistics tracking initialized correctly');
  });
});

// Cleanup after all tests
test.afterAll(async () => {
  console.log('\n📋 Customer Registration Tests Summary:');
  console.log('- Customer registration API tested');
  console.log('- Field validation tested');
  console.log('- Customer retrieval tested');
  console.log('- Customer search tested');
  console.log('- Address management tested');
  console.log('- Profile updates tested');
  console.log('- Statistics tracking tested');
});
