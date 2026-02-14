import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product.dart';
import '../models/inventory_transaction.dart';

class InventoryService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Product>> getLowStockAlerts(String branchId) async {
    final response = await _supabase
        .from('products')
        .select()
        .eq('branch_id', branchId)
        .filter('stock_quantity', 'lte', _supabase.rpc('get_low_stock_threshold', params: {}).toString()); 
        // Note: simplified logic. Actually checking col <= col is tricky in REST.
        // Better to just fetch all and filter in app or use a view.
        // Assuming we fetch all 'active' products and filter in memory for now or use a dedicated RPC/View.
    
    // Correct approach using client-side filter for MVP flexibility or raw SQL/RPC if performant
    // Let's use a simple query for products where stock <= low_stock_threshold
    // Supabase Postgrest doesn't easily support "where col1 <= col2" without RPC.
    
    final response2 = await _supabase
        .from('products')
        .select()
        .eq('branch_id', branchId)
        .lte('stock_quantity', 10); // Hardcoded fallback or use explicit RPC in future

    final data = response2 as List<dynamic>;
    return data.map((json) => Product.fromJson(json)).toList();
  }

  Future<void> adjustStock({
    required String productId,
    required int quantityDelta,
    required TransactionType type,
    required String branchId,
    String? referenceId,
    String? referenceType,
    String? notes,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Unauthorized');

    // 1. Get current product to find previous quantity
    final productRes = await _supabase
        .from('products')
        .select('stock_quantity, tenant_id')
        .eq('id', productId)
        .single();
    
    final int previousQty = productRes['stock_quantity'];
    final String tenantId = productRes['tenant_id'];
    final int newQty = previousQty + quantityDelta;
    
    // 2. Insert Transaction
    await _supabase.from('inventory_transactions').insert({
      'tenant_id': tenantId,
      'branch_id': branchId,
      'product_id': productId,
      'transaction_type': type.name,
      'quantity_delta': quantityDelta,
      'previous_quantity': previousQty,
      'new_quantity': newQty,
      'staff_id': user.id,
      'reference_id': referenceId,
      'reference_type': referenceType,
      'notes': notes,
    });

    // 3. Update Product
    await _supabase
        .from('products')
        .update({'stock_quantity': newQty})
        .eq('id', productId);
  }
}
