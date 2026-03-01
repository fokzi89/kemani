import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/sale.dart';

class SalesService {
  final SupabaseClient _client = Supabase.instance.client;

  // Singleton pattern
  static final SalesService _instance = SalesService._internal();
  factory SalesService() => _instance;
  SalesService._internal();

  /// Create a new sale transaction with auto-generated ID
  Future<Sale> createSale({
    required List<Map<String, dynamic>> items, // [{productId, productName, quantity, unitPrice}]
    String? customerId,
    required String paymentMethod,
    String? paymentReference,
    double discountAmount = 0,
    double taxRate = 0, // e.g., 0.075 for 7.5% VAT
  }) async {
    return createSaleWithId(
      saleId: null, // Auto-generate
      items: items,
      customerId: customerId,
      paymentMethod: paymentMethod,
      paymentReference: paymentReference,
      discountAmount: discountAmount,
      taxRate: taxRate,
    );
  }

  /// Create a new sale transaction with specific ID (for offline sync idempotency)
  Future<Sale> createSaleWithId({
    String? saleId, // Provide ID for idempotent creation, null to auto-generate
    required List<Map<String, dynamic>> items, // [{productId, productName, quantity, unitPrice}]
    String? customerId,
    required String paymentMethod,
    String? paymentReference,
    double discountAmount = 0,
    double taxRate = 0, // e.g., 0.075 for 7.5% VAT
  }) async {
    // Idempotency check: if saleId provided, check if already exists
    if (saleId != null) {
      final existingSale = await getSale(saleId);
      if (existingSale != null) {
        print('⚠️  Sale $saleId already exists, returning existing sale');
        return existingSale;
      }
    }
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final tenantId = _client.auth.currentUser?.userMetadata?['tenant_id'] as String?;
    final branchId = _client.auth.currentUser?.userMetadata?['branch_id'] as String?;

    if (tenantId == null || branchId == null) {
      throw Exception('Tenant or Branch not found for user');
    }

    // Calculate subtotal
    double subtotal = 0;
    for (final item in items) {
      final quantity = item['quantity'] as int;
      final unitPrice = item['unitPrice'] as double;
      subtotal += quantity * unitPrice;
    }

    // Calculate tax
    final taxAmount = subtotal * taxRate;

    // Calculate total
    final totalAmount = subtotal + taxAmount - discountAmount;

    // Generate sale number
    final saleNumber = await _generateSaleNumber(branchId);

    // Create sale
    final saleData = {
      if (saleId != null) 'id': saleId, // Use provided ID for idempotency
      'tenant_id': tenantId,
      'branch_id': branchId,
      'sale_number': saleNumber,
      'cashier_id': userId,
      'customer_id': customerId,
      'subtotal': subtotal,
      'tax_amount': taxAmount,
      'discount_amount': discountAmount,
      'total_amount': totalAmount,
      'payment_method': paymentMethod,
      'payment_reference': paymentReference,
      'status': 'completed',
      'is_synced': false,
    };

    final saleResponse = await _client
        .from('sales')
        .insert(saleData)
        .select()
        .single();

    final createdSaleId = saleResponse['id'] as String;

    // Create sale items
    final saleItems = items.map((item) {
      final quantity = item['quantity'] as int;
      final unitPrice = item['unitPrice'] as double;
      final itemDiscountPercent = item['discountPercent'] as double? ?? 0;
      final itemSubtotal = quantity * unitPrice;
      final itemDiscountAmount = itemSubtotal * (itemDiscountPercent / 100);

      return {
        'sale_id': createdSaleId,
        'product_id': item['productId'],
        'product_name': item['productName'],
        'quantity': quantity,
        'unit_price': unitPrice,
        'discount_percent': itemDiscountPercent,
        'discount_amount': itemDiscountAmount,
        'subtotal': itemSubtotal - itemDiscountAmount,
      };
    }).toList();

    await _client.from('sale_items').insert(saleItems);

    // Update inventory
    for (final item in items) {
      await _updateInventory(
        branchId: branchId,
        productId: item['productId'] as String,
        quantitySold: item['quantity'] as int,
      );
    }

    // Update customer loyalty points if customer exists
    if (customerId != null) {
      await _updateCustomerLoyalty(
        customerId: customerId,
        purchaseAmount: totalAmount,
      );
    }

    return Sale.fromJson(saleResponse);
  }

  /// Generate unique sale number
  Future<String> _generateSaleNumber(String branchId) async {
    final now = DateTime.now();
    final datePrefix = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';

    // Get count of sales today for this branch
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    final countResponse = await _client
        .from('sales')
        .select('id')
        .eq('branch_id', branchId)
        .gte('created_at', todayStart.toIso8601String())
        .lt('created_at', todayEnd.toIso8601String())
        .count(CountOption.exact);

    final sequenceNumber = (countResponse.count ?? 0) + 1;

    return 'SALE-$datePrefix-${sequenceNumber.toString().padLeft(4, '0')}';
  }

  /// Update inventory after sale
  Future<void> _updateInventory({
    required String branchId,
    required String productId,
    required int quantitySold,
  }) async {
    // Get current inventory
    final inventory = await _client
        .from('branch_inventory')
        .select()
        .eq('branch_id', branchId)
        .eq('product_id', productId)
        .maybeSingle();

    if (inventory == null) {
      // No inventory record - this shouldn't happen but handle gracefully
      print('Warning: No inventory record for product $productId in branch $branchId');
      return;
    }

    final currentStock = inventory['stock_quantity'] as int? ?? 0;
    final newStock = currentStock - quantitySold;

    if (newStock < 0) {
      throw Exception('Insufficient stock for product');
    }

    await _client
        .from('branch_inventory')
        .update({
          'stock_quantity': newStock,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('branch_id', branchId)
        .eq('product_id', productId);
  }

  /// Update customer loyalty points and purchase history
  Future<void> _updateCustomerLoyalty({
    required String customerId,
    required double purchaseAmount,
  }) async {
    // Get current customer data
    final customer = await _client
        .from('customers')
        .select()
        .eq('id', customerId)
        .single();

    final currentPoints = customer['loyalty_points'] as int? ?? 0;
    final currentTotal = (customer['total_purchases'] as num?)?.toDouble() ?? 0.0;
    final currentCount = customer['purchase_count'] as int? ?? 0;

    // Calculate new loyalty points (1 point per NGN 100 spent)
    final newPoints = (purchaseAmount / 100).floor();

    // Update customer
    await _client.from('customers').update({
      'loyalty_points': currentPoints + newPoints,
      'total_purchases': currentTotal + purchaseAmount,
      'purchase_count': currentCount + 1,
      'last_purchase_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', customerId);
  }

  /// Get sale by ID
  Future<Sale?> getSale(String saleId) async {
    final response = await _client
        .from('sales')
        .select()
        .eq('id', saleId)
        .maybeSingle();

    if (response == null) return null;
    return Sale.fromJson(response);
  }

  /// Get sale items
  Future<List<SaleItem>> getSaleItems(String saleId) async {
    final response = await _client
        .from('sale_items')
        .select()
        .eq('sale_id', saleId);

    return List<SaleItem>.from(
      response.map((x) => SaleItem.fromJson(x)),
    );
  }

  /// List sales with optional filters
  Future<List<Sale>> listSales({
    DateTime? startDate,
    DateTime? endDate,
    String? customerId,
    String? paymentMethod,
    int limit = 50,
    int offset = 0,
  }) async {
    var query = _client.from('sales').select();

    if (startDate != null) {
      query = query.gte('created_at', startDate.toIso8601String());
    }

    if (endDate != null) {
      query = query.lte('created_at', endDate.toIso8601String());
    }

    if (customerId != null) {
      query = query.eq('customer_id', customerId);
    }

    if (paymentMethod != null) {
      query = query.eq('payment_method', paymentMethod);
    }

    final response = await query
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return List<Sale>.from(response.map((x) => Sale.fromJson(x)));
  }

  /// Void a sale (admin only)
  Future<Sale> voidSale({
    required String saleId,
    required String reason,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    // Get sale details
    final sale = await getSale(saleId);
    if (sale == null) throw Exception('Sale not found');

    if (sale.status == 'voided') {
      throw Exception('Sale is already voided');
    }

    // Get sale items to restore inventory
    final saleItems = await getSaleItems(saleId);

    // Restore inventory
    final branchId = sale.branchId;
    for (final item in saleItems) {
      final inventory = await _client
          .from('branch_inventory')
          .select()
          .eq('branch_id', branchId)
          .eq('product_id', item.productId)
          .single();

      final currentStock = inventory['stock_quantity'] as int? ?? 0;
      final restoredStock = currentStock + item.quantity;

      await _client
          .from('branch_inventory')
          .update({
            'stock_quantity': restoredStock,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('branch_id', branchId)
          .eq('product_id', item.productId);
    }

    // Reverse customer loyalty if customer exists
    if (sale.customerId != null) {
      final customer = await _client
          .from('customers')
          .select()
          .eq('id', sale.customerId!)
          .single();

      final currentPoints = customer['loyalty_points'] as int? ?? 0;
      final currentTotal = (customer['total_purchases'] as num?)?.toDouble() ?? 0.0;
      final currentCount = customer['purchase_count'] as int? ?? 0;

      // Reverse loyalty points
      final pointsToRemove = (sale.totalAmount / 100).floor();

      await _client.from('customers').update({
        'loyalty_points': (currentPoints - pointsToRemove).clamp(0, 999999),
        'total_purchases': (currentTotal - sale.totalAmount).clamp(0.0, double.infinity),
        'purchase_count': (currentCount - 1).clamp(0, 999999),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', sale.customerId!);
    }

    // Mark sale as voided
    final response = await _client
        .from('sales')
        .update({
          'status': 'voided',
          'voided_at': DateTime.now().toIso8601String(),
          'voided_by_id': userId,
          'void_reason': reason,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', saleId)
        .select()
        .single();

    return Sale.fromJson(response);
  }

  /// Get today's sales summary
  Future<Map<String, dynamic>> getTodaysSummary() async {
    final branchId = _client.auth.currentUser?.userMetadata?['branch_id'] as String?;
    if (branchId == null) throw Exception('Branch not found');

    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final sales = await _client
        .from('sales')
        .select()
        .eq('branch_id', branchId)
        .eq('status', 'completed')
        .gte('created_at', startOfDay.toIso8601String())
        .lt('created_at', endOfDay.toIso8601String());

    double totalRevenue = 0;
    int transactionCount = sales.length;

    for (final sale in sales) {
      totalRevenue += (sale['total_amount'] as num).toDouble();
    }

    final averageOrderValue = transactionCount > 0 ? totalRevenue / transactionCount : 0;

    return {
      'totalRevenue': totalRevenue,
      'transactionCount': transactionCount,
      'averageOrderValue': averageOrderValue,
      'date': startOfDay.toIso8601String(),
    };
  }
}
