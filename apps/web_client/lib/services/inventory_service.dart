import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product.dart';
import '../models/inventory.dart';

class InventoryService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Product>> getLowStockAlerts(String branchId) async {
    final response = await _supabase
        .from('products')
        .select()
        .eq('branch_id', branchId)
        .lte('current_stock', 10); // Hardcoded fallback or use explicit RPC in future

    final data = response as List<dynamic>;
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
        .select('current_stock, tenant_id') // Corrected column name
        .eq('id', productId)
        .single();
    
    final int previousQty = productRes['current_stock']; // Corrected column name
    final String tenantId = productRes['tenant_id'];
    final int newQty = previousQty + quantityDelta;
    
    // 2. Insert Transaction
    await _supabase.from('inventory_transactions').insert({
      'tenant_id': tenantId,
      'branch_id': branchId,
      'product_id': productId,
      'transaction_type': type.name, // Enum to string
      'quantity_delta': quantityDelta,
      'previous_quantity': previousQty,
      'new_quantity': newQty,
      'staff_id': user.id,
      'reference_id': referenceId,
      'reference_type': referenceType,
      'notes': notes,
      'created_at': DateTime.now().toIso8601String(),
    });

    // 3. Update Product
    await _supabase
        .from('products')
        .update({'current_stock': newQty}) // Corrected column name
        .eq('id', productId);
  }
}
