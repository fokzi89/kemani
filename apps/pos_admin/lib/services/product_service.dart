import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pos_admin/models/product.dart';

class ProductService {
  final SupabaseClient _client = Supabase.instance.client;

  // Singleton pattern
  static final ProductService _instance = ProductService._internal();
  factory ProductService() => _instance;
  ProductService._internal();

  /// Create a new product
  Future<Product> createProduct({
    required String name,
    String? description,
    String? sku,
    String? barcode,
    String? category,
    required double unitPrice,
    double? costPrice,
    String? imageUrl,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    // Get tenant_id from user metadata
    final tenantId = _client.auth.currentUser?.userMetadata?['tenant_id'] as String?;
    if (tenantId == null) throw Exception('Tenant not found for user');

    final productData = {
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
    };

    final response = await _client
        .from('products')
        .insert(productData)
        .select()
        .single();

    return Product.fromJson(response);
  }

  /// Update an existing product
  Future<Product> updateProduct({
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

    final response = await _client
        .from('products')
        .update(updates)
        .eq('id', productId)
        .select()
        .single();

    return Product.fromJson(response);
  }

  /// Soft delete a product
  Future<void> deleteProduct(String productId) async {
    await _client.from('products').update({
      'is_active': false,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', productId);
  }

  /// Get a single product by ID
  Future<Product?> getProduct(String productId) async {
    final response = await _client
        .from('products')
        .select()
        .eq('id', productId)
        .eq('is_active', true)
        .maybeSingle();

    if (response == null) return null;
    return Product.fromJson(response);
  }

  /// List all products with optional filtering
  Future<List<Product>> listProducts({
    String? category,
    String? searchQuery,
    bool? isActive,
    int limit = 100,
    int offset = 0,
  }) async {
    var query = _client.from('products').select();

    // Apply filters
    if (category != null && category.isNotEmpty) {
      query = query.eq('category', category);
    }

    if (searchQuery != null && searchQuery.isNotEmpty) {
      query = query.or(
        'name.ilike.%$searchQuery%,'
        'description.ilike.%$searchQuery%,'
        'sku.ilike.%$searchQuery%,'
        'barcode.ilike.%$searchQuery%',
      );
    }

    if (isActive != null) {
      query = query.eq('is_active', isActive);
    } else {
      // By default, only show active products
      query = query.eq('is_active', true);
    }

    final response = await query
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return List<Product>.from(response.map((x) => Product.fromJson(x)));
  }

  /// Get product with inventory for a specific branch
  Future<ProductWithInventory?> getProductWithInventory({
    required String productId,
    required String branchId,
  }) async {
    final productData = await _client
        .from('products')
        .select()
        .eq('id', productId)
        .eq('is_active', true)
        .maybeSingle();

    if (productData == null) return null;

    final product = Product.fromJson(productData);

    final inventoryData = await _client
        .from('branch_inventory')
        .select()
        .eq('product_id', productId)
        .eq('branch_id', branchId)
        .eq('is_active', true)
        .maybeSingle();

    final inventory = inventoryData != null
        ? BranchInventory.fromJson(inventoryData)
        : null;

    return ProductWithInventory(product: product, inventory: inventory);
  }

  /// List products with inventory for a specific branch
  Future<List<ProductWithInventory>> listProductsWithInventory({
    required String branchId,
    String? category,
    String? searchQuery,
    bool? lowStockOnly,
    bool? expiringSoonOnly,
    int limit = 100,
    int offset = 0,
  }) async {
    // First get the products
    final products = await listProducts(
      category: category,
      searchQuery: searchQuery,
      limit: limit,
      offset: offset,
    );

    // Then get all inventory for these products
    final productIds = products.map((p) => p.id).toList();

    if (productIds.isEmpty) return [];

    final inventoryResponse = await _client
        .from('branch_inventory')
        .select()
        .eq('branch_id', branchId)
        .inFilter('product_id', productIds)
        .eq('is_active', true);

    final inventoryMap = <String, BranchInventory>{};
    for (final item in inventoryResponse) {
      final inventory = BranchInventory.fromJson(item);
      inventoryMap[inventory.productId] = inventory;
    }

    // Combine products with their inventory
    var result = products.map((product) {
      return ProductWithInventory(
        product: product,
        inventory: inventoryMap[product.id],
      );
    }).toList();

    // Apply inventory-specific filters
    if (lowStockOnly == true) {
      result = result.where((pi) => pi.isLowStock).toList();
    }

    if (expiringSoonOnly == true) {
      result = result.where((pi) =>
        pi.inventory?.isExpiringSoon == true
      ).toList();
    }

    return result;
  }

  /// Update inventory for a product in a branch
  Future<BranchInventory> updateInventory({
    required String branchId,
    required String productId,
    int? stockQuantity,
    int? lowStockThreshold,
    DateTime? expiryDate,
    int? expiryAlertDays,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final tenantId = _client.auth.currentUser?.userMetadata?['tenant_id'] as String?;
    if (tenantId == null) throw Exception('Tenant not found for user');

    // Check if inventory record exists
    final existing = await _client
        .from('branch_inventory')
        .select()
        .eq('branch_id', branchId)
        .eq('product_id', productId)
        .maybeSingle();

    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (stockQuantity != null) updates['stock_quantity'] = stockQuantity;
    if (lowStockThreshold != null) updates['low_stock_threshold'] = lowStockThreshold;
    if (expiryDate != null) updates['expiry_date'] = expiryDate.toIso8601String().split('T')[0];
    if (expiryAlertDays != null) updates['expiry_alert_days'] = expiryAlertDays;

    if (existing == null) {
      // Create new inventory record
      final inventoryData = {
        'tenant_id': tenantId,
        'branch_id': branchId,
        'product_id': productId,
        'stock_quantity': stockQuantity ?? 0,
        'low_stock_threshold': lowStockThreshold,
        'expiry_date': expiryDate?.toIso8601String().split('T')[0],
        'expiry_alert_days': expiryAlertDays,
        'reserved_quantity': 0,
        'is_active': true,
      };

      final response = await _client
          .from('branch_inventory')
          .insert(inventoryData)
          .select()
          .single();

      return BranchInventory.fromJson(response);
    } else {
      // Update existing inventory
      final response = await _client
          .from('branch_inventory')
          .update(updates)
          .eq('branch_id', branchId)
          .eq('product_id', productId)
          .select()
          .single();

      return BranchInventory.fromJson(response);
    }
  }

  /// Adjust stock quantity (add or subtract)
  Future<BranchInventory> adjustStock({
    required String branchId,
    required String productId,
    required int adjustment,
    String? reason,
  }) async {
    // Get current inventory
    final current = await _client
        .from('branch_inventory')
        .select()
        .eq('branch_id', branchId)
        .eq('product_id', productId)
        .single();

    final currentStock = current['stock_quantity'] as int? ?? 0;
    final newStock = currentStock + adjustment;

    if (newStock < 0) {
      throw Exception('Stock cannot be negative');
    }

    return updateInventory(
      branchId: branchId,
      productId: productId,
      stockQuantity: newStock,
    );
  }

  /// Get all unique categories
  Future<List<String>> getCategories() async {
    final response = await _client
        .from('products')
        .select('category')
        .eq('is_active', true)
        .not('category', 'is', null);

    final categories = <String>{};
    for (final item in response) {
      final category = item['category'] as String?;
      if (category != null && category.isNotEmpty) {
        categories.add(category);
      }
    }

    return categories.toList()..sort();
  }

  /// Get products that are low in stock
  Future<List<ProductWithInventory>> getLowStockProducts({
    required String branchId,
  }) async {
    return listProductsWithInventory(
      branchId: branchId,
      lowStockOnly: true,
      limit: 100,
    );
  }

  /// Get products expiring soon
  Future<List<ProductWithInventory>> getExpiringSoonProducts({
    required String branchId,
  }) async {
    return listProductsWithInventory(
      branchId: branchId,
      expiringSoonOnly: true,
      limit: 100,
    );
  }

  /// Get all branch inventory for a specific branch (used for cache refresh)
  Future<List<BranchInventory>> getBranchInventory(String branchId) async {
    final response = await _client
        .from('branch_inventory')
        .select()
        .eq('branch_id', branchId)
        .eq('is_active', true)
        .order('created_at', ascending: false);

    return List<BranchInventory>.from(
      response.map((x) => BranchInventory.fromJson(x)),
    );
  }
}
