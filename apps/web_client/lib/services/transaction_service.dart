import 'package:uuid/uuid.dart';
import '../database/powersync.dart';
import '../providers/cart_provider.dart'; // For CartItem

class TransactionService {
  final _db = PowerSyncService.db;
  final _uuid = const Uuid();

  /// Process a sale transaction locally (offline-first).
  ///
  /// This will:
  /// 1. Create a Sale record
  /// 2. Create SaleItem records
  /// 3. Create InventoryTransaction records (if applicable)
  /// 4. Update Product stock locally (optimistic)
  Future<String> processSale({
    required List<CartItem> items,
    required String tenantId,
    required String cashierId,
    required String paymentMethod,
    double taxRate = 0.0,
    double discountAmount = 0.0,
    String? customerId,
    String? branchId,
  }) async {
    if (items.isEmpty) throw Exception('Cart is empty');

    final saleId = _uuid.v4();
    final now = DateTime.now();
    final saleNumber =
        'SL-${now.millisecondsSinceEpoch}'; // Simple generation for now

    double subtotal = 0;
    for (final item in items) {
      subtotal += item.total;
    }

    final taxAmount = subtotal * taxRate;
    final totalAmount = subtotal + taxAmount - discountAmount;

    // Run in a transaction block to ensure atomicity
    await _db.writeTransaction((tx) async {
      // 1. Insert Sale
      await tx.execute(
        '''INSERT INTO sales(id, tenant_id, branch_id, sale_number, customer_id, cashier_id, 
           total_amount, payment_method, status, created_at)
           VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''',
        [
          saleId,
          tenantId,
          branchId,
          saleNumber,
          customerId,
          cashierId,
          totalAmount,
          paymentMethod,
          'completed',
          now.toIso8601String(),
        ],
      );

      // 2. Process Items
      for (final item in items) {
        final saleItemId = _uuid.v4();

        // Fetch latest product state for accurate stock

        // PowerSync generic tx
        final row = await tx.getOptional(
          'SELECT * FROM products WHERE id = ?',
          [item.product.id],
        );

        if (row == null) {
          throw Exception('Product not found: ${item.product.name}');
        }

        final currentStock = row['current_stock'] as int;
        final costPrice = (row['cost_price'] as num).toDouble();
        final trackInventory = (row['track_inventory'] as int) == 1;

        // Insert SaleItem
        await tx.execute(
          '''INSERT INTO sale_items(id, tenant_id, sale_id, product_id, product_name, 
             quantity, unit_price, total_price)
             VALUES(?, ?, ?, ?, ?, ?, ?, ?)''',
          [
            saleItemId,
            tenantId,
            saleId,
            item.product.id,
            item.product.name,
            item.quantity,
            item.product.sellingPrice,
            item.total,
          ],
        );

        // 3. Handle Inventory if tracked
        if (trackInventory) {
          final invTxId = _uuid.v4();
          final newQuantity = currentStock - item.quantity;

          await tx.execute(
            '''INSERT INTO inventory_transactions(id, tenant_id, branch_id, product_id, 
               transaction_type, quantity_delta, previous_quantity, new_quantity, 
               unit_cost, staff_id, reference_id, reference_type, created_at)
               VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''',
            [
              invTxId,
              tenantId,
              branchId,
              item.product.id,
              'sale',
              -item.quantity,
              currentStock,
              newQuantity,
              costPrice,
              cashierId,
              saleId,
              'sale',
              now.toIso8601String(),
            ],
          );

          // 4. Update Product Stock locally
          await tx.execute(
            'UPDATE products SET current_stock = ? WHERE id = ?',
            [newQuantity, item.product.id],
          );
        }
      }
    });

    return saleId;
  }

  /// Get all sales for a tenant (ordered by date desc)
  Future<List<Sale>> getSales(String tenantId) async {
    final rows = await _db.getAll(
      'SELECT * FROM sales WHERE tenant_id = ? ORDER BY created_at DESC',
      [tenantId],
    );
    return rows.map((row) => Sale.fromJson(row)).toList();
  }

  /// Get a single sale with its items
  Future<Sale?> getSaleWithItems(String saleId) async {
    final saleRow = await _db.getOptional('SELECT * FROM sales WHERE id = ?', [
      saleId,
    ]);
    if (saleRow == null) return null;

    final itemsRows = await _db.getAll(
      'SELECT * FROM sale_items WHERE sale_id = ?',
      [saleId],
    );
    final items = itemsRows.map((row) => SaleItem.fromJson(row)).toList();

    final sale = Sale.fromJson(saleRow);
    // ignore: invalid_use_of_visible_for_testing_member
    return sale.copyWith(items: items);
  }
}
