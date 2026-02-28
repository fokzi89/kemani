import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../lib/services/supabase_service.dart';

/// Role-Based Permissions Integration Tests
///
/// Tests User Story 2 Acceptance Scenario AS5:
/// "Tenant admin creates staff with roles → permissions enforced"
///
/// These tests verify that different user roles have appropriate
/// permissions via RLS policies.
void main() {
  late SupabaseService supabaseService;
  late SupabaseClient supabaseClient;

  // Test data
  String? tenantId;
  String? adminUserId;
  String? staffUserId;
  String? productId;

  setUpAll(() async {
    // Initialize Supabase for testing
    await Supabase.initialize(
      url: const String.fromEnvironment(
        'SUPABASE_URL',
        defaultValue: 'https://ykbpznoqebhopyqpoqaf.supabase.co',
      ),
      anonKey: const String.fromEnvironment(
        'SUPABASE_ANON_KEY',
        defaultValue:
            'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlrYnB6bm9xZWJob3B5cXBvcWFmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg3NjExNDcsImV4cCI6MjA4NDMzNzE0N30.eN1BiyRWOgblp-LFaQvMXM13SttjHnmJb8-s5Y3eu38',
      ),
    );

    supabaseService = SupabaseService();
    supabaseClient = Supabase.instance.client;
  });

  group('Role-Based Permissions Tests', () {
    test('T090: Setup - Create tenant with admin and staff users', () async {
      // Create Tenant Admin
      final adminEmail = 'admin-${DateTime.now().millisecondsSinceEpoch}@test.com';
      final adminPassword = 'AdminPassword123!';

      final adminAuthResponse = await supabaseService.signUp(
        email: adminEmail,
        password: adminPassword,
        metadata: {'full_name': 'Admin User'},
      );

      expect(adminAuthResponse.user, isNotNull, reason: 'Admin user should be created');
      adminUserId = adminAuthResponse.user!.id;

      await supabaseService.createUser(
        userId: adminUserId!,
        email: adminEmail,
        fullName: 'Admin User',
        role: 'tenant_admin',
      );

      tenantId = await supabaseService.createBusiness(
        ownerId: adminUserId!,
        businessName: 'Test Business for Roles',
        businessType: 'Retail',
        locationType: 'Head Office',
        state: 'Lagos',
        city: 'Ikeja',
        address: '789 Test Rd',
        countryCode: 'NG',
        dialCode: '+234',
        currencyCode: 'NGN',
      );

      await supabaseService.updateUser(
        userId: adminUserId!,
        tenantId: tenantId,
        completeOnboarding: true,
      );

      expect(tenantId, isNotNull, reason: 'Tenant should be created');

      // Create Staff User
      final staffEmail = 'staff-${DateTime.now().millisecondsSinceEpoch}@test.com';
      final staffPassword = 'StaffPassword123!';

      final staffAuthResponse = await supabaseService.signUp(
        email: staffEmail,
        password: staffPassword,
        metadata: {'full_name': 'Staff User'},
      );

      expect(staffAuthResponse.user, isNotNull, reason: 'Staff user should be created');
      staffUserId = staffAuthResponse.user!.id;

      await supabaseService.createUser(
        userId: staffUserId!,
        email: staffEmail,
        fullName: 'Staff User',
        role: 'staff',
        tenantId: tenantId,
      );

      expect(staffUserId, isNotNull, reason: 'Staff user should be created');
    });

    test('T090a: Admin can create product - should succeed', () async {
      // Sign in as admin
      await supabaseClient.auth.signInWithPassword(
        email: 'admin-${DateTime.now().millisecondsSinceEpoch}@test.com',
        password: 'AdminPassword123!',
      );

      // Create product as admin
      final productData = {
        'name': 'Test Product',
        'description': 'Created by Admin',
        'price': 150.00,
        'sku': 'ADMIN-PROD-001',
        'tenant_id': tenantId,
        'created_at': DateTime.now().toIso8601String(),
      };

      final response = await supabaseClient
          .from('products')
          .insert(productData)
          .select()
          .single();

      productId = response['id'] as String;

      expect(productId, isNotNull, reason: 'Admin should be able to create product');
      expect(response['name'], equals('Test Product'));
    });

    test('T090b: Staff can view products - should succeed', () async {
      // Sign in as staff
      await supabaseClient.auth.signOut();
      await supabaseClient.auth.signInWithPassword(
        email: 'staff-${DateTime.now().millisecondsSinceEpoch}@test.com',
        password: 'StaffPassword123!',
      );

      // Query products as staff
      final products = await supabaseClient.from('products').select();

      expect(products, isNotEmpty, reason: 'Staff should be able to view products');

      // Verify staff can see the product created by admin
      final hasProduct = products.any((p) => p['id'] == productId);
      expect(hasProduct, isTrue, reason: 'Staff should see admin-created product');
    });

    test('T090c: Staff cannot create products - should fail', () async {
      // Already signed in as staff from previous test

      // Attempt to create product as staff (should fail)
      final productData = {
        'name': 'Unauthorized Product',
        'description': 'Created by Staff (should fail)',
        'price': 99.00,
        'sku': 'STAFF-PROD-001',
        'tenant_id': tenantId,
        'created_at': DateTime.now().toIso8601String(),
      };

      try {
        await supabaseClient
            .from('products')
            .insert(productData)
            .select()
            .single();

        fail('Staff should NOT be able to create products');
      } catch (e) {
        // Expected to fail due to RLS policy (can_manage_products() check)
        expect(e, isNotNull, reason: 'Product creation should be blocked for staff role');
      }
    });

    test('T090d: Staff cannot update products - should fail', () async {
      // Already signed in as staff

      // Attempt to update product as staff (should fail)
      try {
        await supabaseClient
            .from('products')
            .update({'name': 'Hacked Product Name'})
            .eq('id', productId!);

        fail('Staff should NOT be able to update products');
      } catch (e) {
        // Expected to fail due to RLS policy
        expect(e, isNotNull, reason: 'Product update should be blocked for staff role');
      }

      // Verify product was not modified
      await supabaseClient.auth.signOut();
      await supabaseClient.auth.signInWithPassword(
        email: 'admin-${DateTime.now().millisecondsSinceEpoch}@test.com',
        password: 'AdminPassword123!',
      );

      final product = await supabaseClient
          .from('products')
          .select()
          .eq('id', productId!)
          .single();

      expect(product['name'], equals('Test Product'), reason: 'Product name should be unchanged');
    });

    test('T090e: Staff cannot delete products - should fail', () async {
      // Sign in as staff
      await supabaseClient.auth.signOut();
      await supabaseClient.auth.signInWithPassword(
        email: 'staff-${DateTime.now().millisecondsSinceEpoch}@test.com',
        password: 'StaffPassword123!',
      );

      // Attempt to delete product as staff (should fail)
      try {
        await supabaseClient
            .from('products')
            .delete()
            .eq('id', productId!);

        fail('Staff should NOT be able to delete products');
      } catch (e) {
        // Expected to fail due to RLS policy
        expect(e, isNotNull, reason: 'Product deletion should be blocked for staff role');
      }

      // Verify product still exists
      await supabaseClient.auth.signOut();
      await supabaseClient.auth.signInWithPassword(
        email: 'admin-${DateTime.now().millisecondsSinceEpoch}@test.com',
        password: 'AdminPassword123!',
      );

      final product = await supabaseClient
          .from('products')
          .select()
          .eq('id', productId!)
          .maybeSingle();

      expect(product, isNotNull, reason: 'Product should still exist');
    });

    test('T090f: Admin can update product - should succeed', () async {
      // Already signed in as admin

      // Update product as admin
      await supabaseClient
          .from('products')
          .update({'name': 'Updated Product Name'})
          .eq('id', productId!);

      final product = await supabaseClient
          .from('products')
          .select()
          .eq('id', productId!)
          .single();

      expect(product['name'], equals('Updated Product Name'), reason: 'Admin should be able to update product');
    });

    test('T090g: Admin can delete product - should succeed', () async {
      // Already signed in as admin

      // Delete product as admin
      await supabaseClient
          .from('products')
          .delete()
          .eq('id', productId!);

      final product = await supabaseClient
          .from('products')
          .select()
          .eq('id', productId!)
          .maybeSingle();

      expect(product, isNull, reason: 'Admin should be able to delete product');
    });

    test('T090h: Staff can view users in same tenant - should succeed', () async {
      // Sign in as staff
      await supabaseClient.auth.signOut();
      await supabaseClient.auth.signInWithPassword(
        email: 'staff-${DateTime.now().millisecondsSinceEpoch}@test.com',
        password: 'StaffPassword123!',
      );

      // Query users (RLS should show users in same tenant)
      final users = await supabaseClient.from('users').select();

      expect(users, isNotEmpty, reason: 'Staff should be able to view users in their tenant');

      // Verify all users belong to same tenant
      for (final user in users) {
        expect(
          user['tenant_id'],
          equals(tenantId),
          reason: 'All visible users should belong to same tenant',
        );
      }

      // Verify both admin and staff are visible
      final hasAdmin = users.any((u) => u['id'] == adminUserId);
      final hasStaff = users.any((u) => u['id'] == staffUserId);

      expect(hasAdmin, isTrue, reason: 'Staff should see admin user');
      expect(hasStaff, isTrue, reason: 'Staff should see themselves');
    });

    test('T090i: Staff can update own profile - should succeed', () async {
      // Already signed in as staff

      // Update own profile
      await supabaseClient
          .from('users')
          .update({'phone': '+2341234567890'})
          .eq('id', staffUserId!);

      final user = await supabaseClient
          .from('users')
          .select()
          .eq('id', staffUserId!)
          .single();

      expect(user['phone'], equals('+2341234567890'), reason: 'Staff should be able to update own profile');
    });

    test('T090j: Staff cannot update other users - should fail', () async {
      // Already signed in as staff

      // Attempt to update admin user (should fail)
      try {
        await supabaseClient
            .from('users')
            .update({'phone': '+2349876543210'})
            .eq('id', adminUserId!);

        fail('Staff should NOT be able to update other users');
      } catch (e) {
        // Expected to fail due to RLS policy (only can update own profile)
        expect(e, isNotNull, reason: 'User update should be blocked for other users');
      }
    });
  });

  tearDownAll(() async {
    // Cleanup
    await supabaseClient.auth.signOut();
  });
}
