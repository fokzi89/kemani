import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product.dart';

class ProductService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Product>> getProducts(String branchId) async {
    final response = await _supabase
        .from('products')
        .select()
        .eq('branch_id', branchId)
        .eq('is_active', true); // Only fetch active products by default

    final data = response as List<dynamic>;
    return data.map((json) => Product.fromJson(json)).toList();
  }

  /// Fetch all active products for the current user's tenant
  Future<List<Product>> getProductsForCurrentUser() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    // Get the user's tenant_id
    final profile = await _supabase
        .from('users')
        .select('tenant_id')
        .eq('id', user.id)
        .maybeSingle();

    final tenantId = profile?['tenant_id'];
    if (tenantId == null) return [];

    final response = await _supabase
        .from('products')
        .select()
        .eq('tenant_id', tenantId)
        .eq('is_active', true)
        .order('name', ascending: true);

    final data = response as List<dynamic>;
    return data.map((json) => Product.fromJson(json)).toList();
  }

  /// Extract distinct categories from a list of products
  static List<Map<String, dynamic>> getCategoryData(List<Product> products) {
    final Map<String, int> categoryCount = {};
    for (final product in products) {
      final cat = product.category ?? 'Uncategorized';
      categoryCount[cat] = (categoryCount[cat] ?? 0) + 1;
    }

    final List<Map<String, dynamic>> categories = [
      {'name': 'All', 'count': products.length},
    ];

    // Sort by count (descending)
    final sorted = categoryCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    for (final entry in sorted) {
      categories.add({'name': entry.key, 'count': entry.value});
    }

    return categories;
  }

  Future<Product?> getProductByBarcode(String barcode, String branchId) async {
    final response = await _supabase
        .from('products')
        .select()
        .eq('branch_id', branchId)
        .eq('barcode', barcode)
        .maybeSingle();

    if (response == null) return null;
    return Product.fromJson(response);
  }

  Future<Product> createProduct(Map<String, dynamic> productData) async {
    final response = await _supabase
        .from('products')
        .insert(productData)
        .select()
        .single();

    return Product.fromJson(response);
  }

  Future<Product> updateProduct(
    String productId,
    Map<String, dynamic> updates,
  ) async {
    final response = await _supabase
        .from('products')
        .update(updates)
        .eq('id', productId)
        .select()
        .single();

    return Product.fromJson(response);
  }

  Future<void> deleteProduct(String productId) async {
    // Soft delete usually, but here setting is_active = false
    await _supabase
        .from('products')
        .update({'is_active': false})
        .eq('id', productId);
  }
}
