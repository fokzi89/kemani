import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  // Singleton pattern
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  SupabaseClient get client => _client;

  // Auth helpers
  User? get currentUser => _client.auth.currentUser;
  Session? get currentSession => _client.auth.currentSession;

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? metadata,
  }) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
      data: metadata,
    );
  }

  // Create user entry in public.users table
  Future<void> createUser({
    required String userId,
    required String email,
    required String fullName,
    required String role, // user_role enum: 'tenant_admin', 'branch_manager', 'cashier', 'driver', 'platform_admin'
    String? tenantId,
    String? phone,
    String? gender,
    String? profilePictureUrl,
    String? passcodeHash,
  }) async {
    await _client.from('users').insert({
      'id': userId,
      'email': email,
      'full_name': fullName,
      'role': role,
      'tenant_id': tenantId,
      'phone': phone,
      'gender': gender?.toLowerCase(), // Ensure lowercase (male/female)
      'profile_picture_url': profilePictureUrl,
      'passcode_hash': passcodeHash,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  // Update user profile information
  Future<void> updateUser({
    required String userId,
    String? phone,
    String? gender,
    String? profilePictureUrl,
    String? tenantId,
    bool? completeOnboarding,
  }) async {
    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (phone != null) updates['phone'] = phone;
    if (gender != null) updates['gender'] = gender.toLowerCase();
    if (profilePictureUrl != null) updates['profile_picture_url'] = profilePictureUrl;
    if (tenantId != null) updates['tenant_id'] = tenantId;
    if (completeOnboarding == true) {
      updates['onboarding_completed_at'] = DateTime.now().toIso8601String();
    }

    await _client.from('users').update(updates).eq('id', userId);
  }

  // Get user from public.users table
  Future<Map<String, dynamic>?> getUser(String userId) async {
    final response = await _client
        .from('users')
        .select()
        .eq('id', userId)
        .maybeSingle();

    return response;
  }

  Future<bool> signInWithGoogle() async {
    return await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'io.supabase.posadmin://login-callback/',
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // Products Management
  Future<List<Map<String, dynamic>>> getProducts({String? category, String? searchQuery}) async {
    try {
      final userId = currentUser?.id;
      if (userId == null) return [];

      final userData = await getUser(userId);
      if (userData == null || userData['tenant_id'] == null) return [];

      final tenantId = userData['tenant_id'] as String;

      var queryBuilder = _client
          .from('products')
          .select()
          .eq('tenant_id', tenantId)
          .eq('is_active', true);

      if (category != null && category.isNotEmpty) {
        queryBuilder = queryBuilder.eq('category', category);
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        queryBuilder = queryBuilder.or('name.ilike.%$searchQuery%,sku.ilike.%$searchQuery%,barcode.ilike.%$searchQuery%');
      }

      final response = await queryBuilder.order('name', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getProductsWithInventory({
    String? branchId,
    String? category,
    String? searchQuery,
    bool? lowStockOnly,
  }) async {
    try {
      final userId = currentUser?.id;
      if (userId == null) return [];

      final userData = await getUser(userId);
      if (userData == null || userData['tenant_id'] == null) return [];

      final tenantId = userData['tenant_id'] as String;

      // Use the product_stock_status view if branch_id is provided
      if (branchId != null) {
        var queryBuilder = _client
            .from('product_stock_status')
            .select()
            .eq('tenant_id', tenantId)
            .eq('branch_id', branchId);

        if (category != null && category.isNotEmpty) {
          // Note: category might not be in the view, fallback to products join
          queryBuilder = queryBuilder.eq('category', category);
        }

        if (searchQuery != null && searchQuery.isNotEmpty) {
          queryBuilder = queryBuilder.or('product_name.ilike.%$searchQuery%,sku.ilike.%$searchQuery%,barcode.ilike.%$searchQuery%');
        }

        if (lowStockOnly == true) {
          queryBuilder = queryBuilder.inFilter('stock_status', ['low_stock', 'out_of_stock']);
        }

        final response = await queryBuilder.order('product_name', ascending: true);
        return List<Map<String, dynamic>>.from(response);
      } else {
        // Just get products without inventory
        return await getProducts(category: category, searchQuery: searchQuery);
      }
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> getProduct(String productId) async {
    try {
      final response = await _client
          .from('products')
          .select()
          .eq('id', productId)
          .maybeSingle();
      return response;
    } catch (e) {
      return null;
    }
  }

  Future<String> createProduct({
    required String name,
    String? description,
    String? sku,
    String? barcode,
    String? category,
    required double unitPrice,
    double? costPrice,
    String? imageUrl,
  }) async {
    final userId = currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final userData = await getUser(userId);
    if (userData == null || userData['tenant_id'] == null) {
      throw Exception('User has no tenant');
    }

    final tenantId = userData['tenant_id'] as String;

    final product = {
      'tenant_id': tenantId,
      'name': name,
      'description': description,
      'sku': sku,
      'barcode': barcode,
      'category': category,
      'unit_price': unitPrice,
      'cost_price': costPrice,
      'image_url': imageUrl,
      'is_active': true,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };

    final response = await _client
        .from('products')
        .insert(product)
        .select()
        .single();

    return response['id'] as String;
  }

  Future<void> updateProduct({
    required String productId,
    String? name,
    String? description,
    String? sku,
    String? barcode,
    String? category,
    double? unitPrice,
    double? costPrice,
    String? imageUrl,
    bool? isActive,
  }) async {
    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (name != null) updates['name'] = name;
    if (description != null) updates['description'] = description;
    if (sku != null) updates['sku'] = sku;
    if (barcode != null) updates['barcode'] = barcode;
    if (category != null) updates['category'] = category;
    if (unitPrice != null) updates['unit_price'] = unitPrice;
    if (costPrice != null) updates['cost_price'] = costPrice;
    if (imageUrl != null) updates['image_url'] = imageUrl;
    if (isActive != null) updates['is_active'] = isActive;

    await _client.from('products').update(updates).eq('id', productId);
  }

  Future<void> deleteProduct(String productId) async {
    // Soft delete by marking as inactive
    await _client.from('products').update({
      'is_active': false,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', productId);
  }

  // Branch Inventory Management
  Future<Map<String, dynamic>?> getBranchInventory(String branchId, String productId) async {
    try {
      final response = await _client
          .from('branch_inventory')
          .select()
          .eq('branch_id', branchId)
          .eq('product_id', productId)
          .maybeSingle();
      return response;
    } catch (e) {
      return null;
    }
  }

  Future<void> createOrUpdateBranchInventory({
    required String branchId,
    required String productId,
    required int stockQuantity,
    int? lowStockThreshold,
    DateTime? expiryDate,
    int? expiryAlertDays,
  }) async {
    final userId = currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final userData = await getUser(userId);
    if (userData == null || userData['tenant_id'] == null) {
      throw Exception('User has no tenant');
    }

    final tenantId = userData['tenant_id'] as String;

    // Check if inventory exists
    final existing = await getBranchInventory(branchId, productId);

    if (existing != null) {
      // Update existing
      await _client.from('branch_inventory').update({
        'stock_quantity': stockQuantity,
        'low_stock_threshold': lowStockThreshold,
        'expiry_date': expiryDate?.toIso8601String().split('T')[0],
        'expiry_alert_days': expiryAlertDays,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', existing['id']);
    } else {
      // Create new
      await _client.from('branch_inventory').insert({
        'tenant_id': tenantId,
        'branch_id': branchId,
        'product_id': productId,
        'stock_quantity': stockQuantity,
        'low_stock_threshold': lowStockThreshold ?? 10,
        'expiry_date': expiryDate?.toIso8601String().split('T')[0],
        'expiry_alert_days': expiryAlertDays ?? 30,
        'reserved_quantity': 0,
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<void> adjustStock({
    required String branchId,
    required String productId,
    required int quantityDelta,
    String? reason,
  }) async {
    final inventory = await getBranchInventory(branchId, productId);
    if (inventory == null) {
      throw Exception('Inventory record not found');
    }

    final currentStock = inventory['stock_quantity'] as int;
    final newStock = currentStock + quantityDelta;

    if (newStock < 0) {
      throw Exception('Insufficient stock. Available: $currentStock');
    }

    await _client.from('branch_inventory').update({
      'stock_quantity': newStock,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', inventory['id']);

    // TODO: Log inventory transaction for audit trail
  }

  // Sales
  Future<List<Map<String, dynamic>>> getSales() async {
    final response = await _client.from('sales').select();
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> createSale(Map<String, dynamic> sale) async {
    await _client.from('sales').insert(sale);
  }

  // Inventory
  Future<List<Map<String, dynamic>>> getInventory() async {
    final response = await _client.from('inventory').select();
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> updateInventory(String productId, int quantity) async {
    await _client.from('inventory').update({'quantity': quantity}).eq('product_id', productId);
  }

  // Analytics
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final userId = currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Get user's tenant_id
      final userData = await getUser(userId);
      if (userData == null || userData['tenant_id'] == null) {
        throw Exception('User has no tenant');
      }

      final tenantId = userData['tenant_id'] as String;

      // Get today's date range
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));

      // Query 1: Today's sales total
      final todaySalesData = await _client
          .from('sales')
          .select('total_amount')
          .eq('tenant_id', tenantId)
          .gte('created_at', today.toIso8601String())
          .lt('created_at', tomorrow.toIso8601String())
          .eq('status', 'completed');

      double todaysSales = 0;
      for (var sale in todaySalesData) {
        todaysSales += (sale['total_amount'] as num).toDouble();
      }

      // Query 2: Total products count
      final productsCountResponse = await _client
          .from('products')
          .select('id')
          .eq('tenant_id', tenantId)
          .eq('is_active', true)
          .count(CountOption.exact);

      // Query 3: Low stock products count
      final lowStockData = await _client.rpc('get_low_stock_count', params: {
        'p_tenant_id': tenantId,
      }).catchError((e) async {
        // Fallback if function doesn't exist yet
        final products = await _client
            .from('products')
            .select('stock_quantity, reorder_level')
            .eq('tenant_id', tenantId)
            .eq('is_active', true)
            .eq('track_inventory', true)
            .not('reorder_level', 'is', null);

        int count = 0;
        for (var product in products) {
          final stockQty = product['stock_quantity'] as int;
          final reorderLevel = product['reorder_level'] as int;
          if (stockQty <= reorderLevel) {
            count++;
          }
        }
        return count;
      });

      final lowStockCount = lowStockData is int ? lowStockData : 0;

      // Query 4: Today's transactions count
      final todayTransactionsResponse = await _client
          .from('sales')
          .select('id')
          .eq('tenant_id', tenantId)
          .gte('created_at', today.toIso8601String())
          .lt('created_at', tomorrow.toIso8601String())
          .count(CountOption.exact);

      return {
        'todaysSales': todaysSales,
        'totalProducts': productsCountResponse.count ?? 0,
        'lowStockCount': lowStockCount,
        'todaysTransactions': todayTransactionsResponse.count ?? 0,
      };
    } catch (e) {
      // Return zeros if there's an error
      return {
        'todaysSales': 0.0,
        'totalProducts': 0,
        'lowStockCount': 0,
        'todaysTransactions': 0,
      };
    }
  }

  // Get recent sales for dashboard
  Future<List<Map<String, dynamic>>> getRecentSales({int limit = 10}) async {
    try {
      final userId = currentUser?.id;
      if (userId == null) return [];

      final userData = await getUser(userId);
      if (userData == null || userData['tenant_id'] == null) return [];

      final tenantId = userData['tenant_id'] as String;

      final response = await _client
          .from('sales')
          .select('*, users!sales_cashier_id_fkey(full_name)')
          .eq('tenant_id', tenantId)
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  // Profile Management (uses users table, not separate profiles table)
  Future<void> updateUserProfile({
    required String userId,
    String? gender,
    String? phoneNumber,
    String? profileImageUrl,
  }) async {
    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (gender != null) updates['gender'] = gender.toLowerCase();
    if (phoneNumber != null) updates['phone'] = phoneNumber;
    if (profileImageUrl != null) updates['avatar_url'] = profileImageUrl;

    await _client.from('users').update(updates).eq('id', userId);
  }

  // Update country settings on tenant (not user profile)
  // Country/currency are TENANT-level settings, not user-level
  Future<void> updateCountrySettings({
    required String tenantId,
    required String countryCode,
    required String currencyCode,
    required String dialCode,
  }) async {
    await _client.from('tenants').update({
      'country_code': countryCode,
      'currency_code': currencyCode,
      'dial_code': dialCode,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', tenantId);
  }

  // Business Management
  Future<String> createBusiness({
    required String ownerId,
    required String businessName,
    required String businessType,
    required String locationType,
    required String state,
    required String city,
    required String address,
    String? logoUrl,
    String? brandColor,
    String? countryCode,
    String? dialCode,
    String? currencyCode,
  }) async {
    final insertData = {
      'name': businessName,
      'business_type': businessType,
      'location_type': locationType,
      'state': state,
      'city': city,
      'address': address,
      'logo_url': logoUrl,
      'owner_id': ownerId,
      'created_at': DateTime.now().toIso8601String(),
    };

    // Add branding if provided
    if (brandColor != null) insertData['brand_color'] = brandColor;

    // Add country settings if provided
    if (countryCode != null) insertData['country_code'] = countryCode;
    if (dialCode != null) insertData['dial_code'] = dialCode;
    if (currencyCode != null) insertData['currency_code'] = currencyCode;

    final response = await _client.from('tenants').insert(insertData).select().single();

    return response['id'] as String;
  }

  // Get user profile (from users table)
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    final response = await _client
        .from('users')
        .select()
        .eq('id', userId)
        .maybeSingle();

    return response;
  }

  Future<List<Map<String, dynamic>>> getUserBusinesses(String userId) async {
    final response = await _client
        .from('tenants')
        .select()
        .eq('owner_id', userId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  // Storage for images
  Future<String?> uploadImage({
    required String bucket,
    required String path,
    required List<int> fileBytes,
    String contentType = 'image/jpeg',
  }) async {
    try {
      final uploadPath = '$path/${DateTime.now().millisecondsSinceEpoch}';

      // Convert List<int> to Uint8List
      final bytes = Uint8List.fromList(fileBytes);

      await _client.storage.from(bucket).uploadBinary(
        uploadPath,
        bytes,
        fileOptions: FileOptions(
          contentType: contentType,
          upsert: true,
        ),
      );

      final publicUrl = _client.storage.from(bucket).getPublicUrl(uploadPath);
      return publicUrl;
    } catch (e) {
      return null;
    }
  }

  // Staff Management
  Future<Map<String, dynamic>> createStaffInvite({
    required String tenantId,
    required String fullName,
    required String email,
    required String phoneNumber,
    required String role,
  }) async {
    final inviteToken = DateTime.now().millisecondsSinceEpoch.toString();

    await _client.from('staff_invites').insert({
      'tenant_id': tenantId,
      'full_name': fullName,
      'email': email,
      'phone_number': phoneNumber,
      'role': role,
      'invite_token': inviteToken,
      'status': 'pending',
      'created_at': DateTime.now().toIso8601String(),
      'expires_at': DateTime.now().add(const Duration(days: 7)).toIso8601String(),
    });

    return {
      'inviteToken': inviteToken,
      'inviteLink': 'http://localhost:8082/staff-invite/$inviteToken',
    };
  }

  Future<Map<String, dynamic>?> getStaffInvite(String inviteToken) async {
    final response = await _client
        .from('staff_invites')
        .select()
        .eq('invite_token', inviteToken)
        .eq('status', 'pending')
        .maybeSingle();

    return response;
  }

  Future<String> acceptStaffInvite({
    required String inviteToken,
    required String password,
    required String gender,
    String? profileImageUrl,
    String? passcode,
    bool? biometricEnabled,
  }) async {
    // Get invite details
    final invite = await getStaffInvite(inviteToken);
    if (invite == null) {
      throw Exception('Invalid or expired invite');
    }

    // Create staff auth account
    final authResponse = await _client.auth.signUp(
      email: invite['email'] as String,
      password: password,
      data: {
        'full_name': invite['full_name'],
        'role': invite['role'],
        'user_type': 'staff',
      },
    );

    if (authResponse.user == null) {
      throw Exception('Failed to create staff account');
    }

    // Create user entry in public.users table with role from invite
    await createUser(
      userId: authResponse.user!.id,
      email: invite['email'] as String,
      fullName: invite['full_name'] as String,
      role: invite['role'] as String, // Use role from invite (cashier, branch_manager, etc.)
      tenantId: invite['tenant_id'] as String,
      phone: invite['phone_number'] as String?,
      gender: gender,
      profilePictureUrl: profileImageUrl,
      passcodeHash: passcode, // In production, this should be hashed
    );

    // Mark onboarding as complete
    await updateUser(
      userId: authResponse.user!.id,
      completeOnboarding: true,
    );

    // Mark invite as accepted
    await _client
        .from('staff_invites')
        .update({'status': 'accepted'})
        .eq('invite_token', inviteToken);

    return authResponse.user!.id;
  }

  Future<List<Map<String, dynamic>>> getTenantStaff(String tenantId) async {
    final response = await _client
        .from('users')
        .select()
        .eq('tenant_id', tenantId)
        .inFilter('role', ['cashier', 'branch_manager', 'driver']) // All non-admin staff roles
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>?> getStaffProfile(String userId) async {
    final response = await _client
        .from('users')
        .select()
        .eq('id', userId)
        .inFilter('role', ['cashier', 'branch_manager', 'driver']) // All non-admin staff roles
        .maybeSingle();

    return response;
  }

  Future<void> updateStaffPasscode(String userId, String passcode) async {
    await _client.from('users').update({
      'passcode_hash': passcode, // In production, this should be hashed
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', userId);
  }

  Future<void> updateStaffBiometric(String userId, bool enabled) async {
    // Biometric enabled flag can be stored in user metadata or a separate field if needed
    // For now, we'll just update the updated_at timestamp
    await _client.from('users').update({
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', userId);
  }
}
