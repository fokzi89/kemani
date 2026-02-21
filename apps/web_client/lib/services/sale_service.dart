import 'package:supabase_flutter/supabase_flutter.dart';
import '../database/powersync.dart';
import '../models/sale.dart';

class SaleWithItems {
  final Sale sale;
  final List<SaleItem> items;

  SaleWithItems(this.sale, this.items);
}

class SaleService {
  final _db = PowerSyncService.db;
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Fetch a single sale with its items by ID using Local DB (PowerSync).
  Future<SaleWithItems?> getSaleWithItems(String saleId) async {
    final saleRow = await _db.getOptional('SELECT * FROM sales WHERE id = ?', [
      saleId,
    ]);
    if (saleRow == null) return null;

    final sale = Sale.fromJson(saleRow);

    final itemsRows = await _db.getAll(
      'SELECT * FROM sale_items WHERE sale_id = ?',
      [saleId],
    );
    final items = itemsRows.map((e) => SaleItem.fromJson(e)).toList();

    return SaleWithItems(sale, items);
  }

  /// Get the current user's tenant_id and branch_id
  Future<Map<String, String?>> _getUserContext() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return {'tenant_id': null, 'branch_id': null};

    final profile = await _supabase
        .from('users')
        .select('tenant_id, branch_id')
        .eq('id', user.id)
        .maybeSingle();

    return {
      'tenant_id': profile?['tenant_id'],
      'branch_id': profile?['branch_id'],
      'user_id': user.id,
    };
  }

  /// Create a POS sale with line items (Legacy Online Method).
  Future<Map<String, dynamic>> createSale({
    required List<Map<String, dynamic>> items,
    required String paymentMethod,
    double taxRate = 0.075,
    double discountAmount = 0,
    String? paymentReference,
  }) async {
    final ctx = await _getUserContext();
    final tenantId = ctx['tenant_id'];
    final branchId = ctx['branch_id'];
    final userId = ctx['user_id'];

    if (tenantId == null || branchId == null || userId == null) {
      throw Exception('User context not found — missing tenant or branch');
    }

    double subtotal = 0;
    final saleItems = <Map<String, dynamic>>[];

    for (final item in items) {
      final qty = item['quantity'] as int;
      final unitPrice = (item['unit_price'] as num).toDouble();
      final lineSubtotal = unitPrice * qty;
      subtotal += lineSubtotal;

      saleItems.add({
        'product_id': item['product_id'],
        'product_name': item['product_name'],
        'quantity': qty,
        'unit_price': unitPrice,
        'discount_percent': 0,
        'discount_amount': 0,
        'subtotal': lineSubtotal,
      });
    }

    final taxAmount = subtotal * taxRate;
    final totalAmount = subtotal + taxAmount - discountAmount;

    final now = DateTime.now();
    final datePart =
        '${now.year.toString().substring(2)}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final randomPart = (now.millisecondsSinceEpoch % 100000).toString().padLeft(
      5,
      '0',
    );
    final saleNumber = 'SL-$datePart-$randomPart';

    final saleResponse = await _supabase
        .from('sales')
        .insert({
          'tenant_id': tenantId,
          'branch_id': branchId,
          'sale_number': saleNumber,
          'cashier_id': userId,
          'subtotal': subtotal,
          'tax_amount': taxAmount,
          'discount_amount': discountAmount,
          'total_amount': totalAmount,
          'payment_method': paymentMethod,
          'payment_reference': paymentReference,
          'status': 'completed',
        })
        .select()
        .single();

    final saleId = saleResponse['id'];

    final itemsWithSaleId = saleItems.map((item) {
      return {...item, 'sale_id': saleId, 'tenant_id': tenantId};
    }).toList();

    await _supabase.from('sale_items').insert(itemsWithSaleId);

    return {...saleResponse, 'sale_items': itemsWithSaleId};
  }

  /// Fetch recent sales for the current user's tenant (Legacy Online Method).
  Future<List<Map<String, dynamic>>> getSales({int limit = 50}) async {
    final ctx = await _getUserContext();
    final tenantId = ctx['tenant_id'];
    if (tenantId == null) return [];

    final response = await _supabase
        .from('sales')
        .select('*, sale_items(*)')
        .eq('tenant_id', tenantId)
        .order('created_at', ascending: false)
        .limit(limit);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Void a sale (Legacy Online Method).
  Future<void> voidSale(String saleId, String reason) async {
    final user = _supabase.auth.currentUser;
    await _supabase
        .from('sales')
        .update({
          'status': 'voided',
          'voided_at': DateTime.now().toIso8601String(),
          'voided_by_id': user?.id,
          'void_reason': reason,
        })
        .eq('id', saleId);
  }
}
