import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../lib/services/supabase_service.dart';

/// Multi-Tenant Isolation Integration Tests
///
/// Tests User Story 2 Acceptance Scenario AS4:
/// "Multiple tenants: user in tenant A can only access tenant A data"
///
/// These tests verify that Row-Level Security (RLS) policies
/// properly isolate data between tenants.
void main() {
  late SupabaseService supabaseService;
  late SupabaseClient supabaseClient;

  // Test data
  String? tenantAId;
  String? tenantBId;
  String? userAId;
  String? userBId;
  String? productAId;
  String? productBId;

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

  group('Multi-Tenant Data Isolation Tests', () {
    test('T089: Setup - Create two separate tenants with users', () async {
      // Create Tenant A
      final emailA = 'tenant-a-owner-${DateTime.now().millisecondsSinceEpoch}@test.com';
      final passwordA = 'TestPassword123!';

      final authResponseA = await supabaseService.signUp(
        email: emailA,
        password: passwordA,
        metadata: {'full_name': 'Tenant A Owner'},
      );

      expect(authResponseA.user, isNotNull, reason: 'User A should be created');
      userAId = authResponseA.user!.id;

      await supabaseService.createUser(
        userId: userAId!,
        email: emailA,
        fullName: 'Tenant A Owner',
        role: 'owner',
      );

      tenantAId = await supabaseService.createBusiness(
        ownerId: userAId!,
        businessName: 'Test Business A',
        businessType: 'Retail',
        locationType: 'Head Office',
        state: 'Lagos',
        city: 'Ikeja',
        address: '123 Test St',
        countryCode: 'NG',
        dialCode: '+234',
        currencyCode: 'NGN',
      );

      await supabaseService.updateUser(
        userId: userAId!,
        tenantId: tenantAId,
        completeOnboarding: true,
      );

      expect(tenantAId, isNotNull, reason: 'Tenant A should be created');

      // Create Tenant B
      final emailB = 'tenant-b-owner-${DateTime.now().millisecondsSinceEpoch}@test.com';
      final passwordB = 'TestPassword123!';

      final authResponseB = await supabaseService.signUp(
        email: emailB,
        password: passwordB,
        metadata: {'full_name': 'Tenant B Owner'},
      );

      expect(authResponseB.user, isNotNull, reason: 'User B should be created');
      userBId = authResponseB.user!.id;

      await supabaseService.createUser(
        userId: userBId!,
        email: emailB,
        fullName: 'Tenant B Owner',
        role: 'owner',
      );

      tenantBId = await supabaseService.createBusiness(
        ownerId: userBId!,
        businessName: 'Test Business B',
        businessType: 'Restaurant',
        locationType: 'Head Office',
        state: 'Abuja',
        city: 'Wuse',
        address: '456 Test Ave',
        countryCode: 'NG',
        dialCode: '+234',
        currencyCode: 'NGN',
      );

      await supabaseService.updateUser(
        userId: userBId!,
        tenantId: tenantBId,
        completeOnboarding: true,
      );

      expect(tenantBId, isNotNull, reason: 'Tenant B should be created');
      expect(tenantAId, isNot(equals(tenantBId)), reason: 'Tenants should have different IDs');
    });

    test('T089a: Tenant A creates product - should succeed', () async {
      // Sign in as Tenant A user
      await supabaseClient.auth.signInWithPassword(
        email: 'tenant-a-owner-${DateTime.now().millisecondsSinceEpoch}@test.com',
        password: 'TestPassword123!',
      );

      // Create product for Tenant A
      final productData = {
        'name': 'Product A',
        'description': 'Test Product A',
        'price': 100.00,
        'sku': 'PROD-A-001',
        'tenant_id': tenantAId,
        'created_at': DateTime.now().toIso8601String(),
      };

      final response = await supabaseClient
          .from('products')
          .insert(productData)
          .select()
          .single();

      productAId = response['id'] as String;

      expect(productAId, isNotNull, reason: 'Product A should be created');
      expect(response['name'], equals('Product A'));
      expect(response['tenant_id'], equals(tenantAId));
    });

    test('T089b: Tenant B creates product - should succeed', () async {
      // Sign in as Tenant B user
      await supabaseClient.auth.signOut();
      await supabaseClient.auth.signInWithPassword(
        email: 'tenant-b-owner-${DateTime.now().millisecondsSinceEpoch}@test.com',
        password: 'TestPassword123!',
      );

      // Create product for Tenant B
      final productData = {
        'name': 'Product B',
        'description': 'Test Product B',
        'price': 200.00,
        'sku': 'PROD-B-001',
        'tenant_id': tenantBId,
        'created_at': DateTime.now().toIso8601String(),
      };

      final response = await supabaseClient
          .from('products')
          .insert(productData)
          .select()
          .single();

      productBId = response['id'] as String;

      expect(productBId, isNotNull, reason: 'Product B should be created');
      expect(response['name'], equals('Product B'));
      expect(response['tenant_id'], equals(tenantBId));
    });

    test('T089c: Tenant A queries products - should ONLY see Product A', () async {
      // Sign in as Tenant A user
      await supabaseClient.auth.signOut();
      await supabaseClient.auth.signInWithPassword(
        email: 'tenant-a-owner-${DateTime.now().millisecondsSinceEpoch}@test.com',
        password: 'TestPassword123!',
      );

      // Query all products (RLS should filter to only Tenant A)
      final products = await supabaseClient.from('products').select();

      expect(products, isNotEmpty, reason: 'Tenant A should see at least one product');

      // Verify all products belong to Tenant A
      for (final product in products) {
        expect(
          product['tenant_id'],
          equals(tenantAId),
          reason: 'All products should belong to Tenant A',
        );
      }

      // Verify Product A is visible
      final hasProductA = products.any((p) => p['id'] == productAId);
      expect(hasProductA, isTrue, reason: 'Product A should be visible to Tenant A');

      // Verify Product B is NOT visible
      final hasProductB = products.any((p) => p['id'] == productBId);
      expect(hasProductB, isFalse, reason: 'Product B should NOT be visible to Tenant A');
    });

    test('T089d: Tenant B queries products - should ONLY see Product B', () async {
      // Sign in as Tenant B user
      await supabaseClient.auth.signOut();
      await supabaseClient.auth.signInWithPassword(
        email: 'tenant-b-owner-${DateTime.now().millisecondsSinceEpoch}@test.com',
        password: 'TestPassword123!',
      );

      // Query all products (RLS should filter to only Tenant B)
      final products = await supabaseClient.from('products').select();

      expect(products, isNotEmpty, reason: 'Tenant B should see at least one product');

      // Verify all products belong to Tenant B
      for (final product in products) {
        expect(
          product['tenant_id'],
          equals(tenantBId),
          reason: 'All products should belong to Tenant B',
        );
      }

      // Verify Product B is visible
      final hasProductB = products.any((p) => p['id'] == productBId);
      expect(hasProductB, isTrue, reason: 'Product B should be visible to Tenant B');

      // Verify Product A is NOT visible
      final hasProductA = products.any((p) => p['id'] == productAId);
      expect(hasProductA, isFalse, reason: 'Product A should NOT be visible to Tenant B');
    });

    test('T089e: Tenant A cannot update Tenant B product', () async {
      // Sign in as Tenant A user
      await supabaseClient.auth.signOut();
      await supabaseClient.auth.signInWithPassword(
        email: 'tenant-a-owner-${DateTime.now().millisecondsSinceEpoch}@test.com',
        password: 'TestPassword123!',
      );

      // Attempt to update Product B (should fail due to RLS)
      try {
        await supabaseClient
            .from('products')
            .update({'name': 'Hacked Product B'})
            .eq('id', productBId!);

        fail('Should not be able to update Product B from Tenant A');
      } catch (e) {
        // Expected to fail
        expect(e, isNotNull, reason: 'Update should be blocked by RLS');
      }

      // Verify Product B was NOT modified
      await supabaseClient.auth.signOut();
      await supabaseClient.auth.signInWithPassword(
        email: 'tenant-b-owner-${DateTime.now().millisecondsSinceEpoch}@test.com',
        password: 'TestPassword123!',
      );

      final productB = await supabaseClient
          .from('products')
          .select()
          .eq('id', productBId!)
          .single();

      expect(productB['name'], equals('Product B'), reason: 'Product B name should be unchanged');
    });

    test('T089f: Tenant A cannot delete Tenant B product', () async {
      // Sign in as Tenant A user
      await supabaseClient.auth.signOut();
      await supabaseClient.auth.signInWithPassword(
        email: 'tenant-a-owner-${DateTime.now().millisecondsSinceEpoch}@test.com',
        password: 'TestPassword123!',
      );

      // Attempt to delete Product B (should fail due to RLS)
      try {
        await supabaseClient
            .from('products')
            .delete()
            .eq('id', productBId!);

        fail('Should not be able to delete Product B from Tenant A');
      } catch (e) {
        // Expected to fail
        expect(e, isNotNull, reason: 'Delete should be blocked by RLS');
      }

      // Verify Product B still exists
      await supabaseClient.auth.signOut();
      await supabaseClient.auth.signInWithPassword(
        email: 'tenant-b-owner-${DateTime.now().millisecondsSinceEpoch}@test.com',
        password: 'TestPassword123!',
      );

      final productB = await supabaseClient
          .from('products')
          .select()
          .eq('id', productBId!)
          .maybeSingle();

      expect(productB, isNotNull, reason: 'Product B should still exist');
    });
  });

  tearDownAll(() async {
    // Cleanup test data
    // Note: In production tests, you'd want to clean up created tenants,
    // users, and products. For now, we'll leave them for manual verification.
    await supabaseClient.auth.signOut();
  });
}
