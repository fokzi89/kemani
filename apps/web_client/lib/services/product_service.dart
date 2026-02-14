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

  Future<Product> updateProduct(String productId, Map<String, dynamic> updates) async {
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
