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

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // Products
  Future<List<Map<String, dynamic>>> getProducts() async {
    final response = await _client.from('products').select();
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> addProduct(Map<String, dynamic> product) async {
    await _client.from('products').insert(product);
  }

  Future<void> updateProduct(String id, Map<String, dynamic> updates) async {
    await _client.from('products').update(updates).eq('id', id);
  }

  Future<void> deleteProduct(String id) async {
    await _client.from('products').delete().eq('id', id);
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
    // TODO: Implement dashboard statistics queries
    return {
      'totalSales': 0,
      'totalProducts': 0,
      'lowStock': 0,
      'transactions': 0,
    };
  }
}
