import '../models/order.dart';
import '../database/powersync.dart';
import 'package:uuid/uuid.dart';

class OrderService {
  final _db = PowerSyncService.db;
  final _uuid = const Uuid();

  /// Watch all orders for a specific tenant
  Stream<List<Order>> watchOrders(String tenantId) {
    return _db
        .watch(
          'SELECT * FROM orders WHERE tenant_id = ? ORDER BY created_at DESC',
          parameters: [tenantId],
        )
        .map((rows) => rows.map((row) => Order.fromJson(row)).toList());
  }

  /// Get order details with items
  Future<Order?> getOrderWithItems(String orderId) async {
    final orderRow = await _db.getOptional(
      'SELECT * FROM orders WHERE id = ?',
      [orderId],
    );
    if (orderRow == null) return null;

    final itemsRows = await _db.getAll(
      'SELECT * FROM order_items WHERE order_id = ?',
      [orderId],
    );
    final items = itemsRows.map((row) => OrderItem.fromJson(row)).toList();

    // Reconstruct order with items
    // We can use copyWith on the parsed order
    final order = Order.fromJson(orderRow);
    return order.copyWith(items: items);
  }

  /// Create a new order with items
  Future<Order> createOrder(Order order, List<OrderItem> items) async {
    final orderId = order.id.isEmpty ? _uuid.v4() : order.id;
    final now = DateTime.now();

    final newOrder = order.copyWith(id: orderId, updatedAt: now, items: items);

    await _db.writeTransaction((tx) async {
      // 1. Insert Order
      await tx.execute(
        '''INSERT INTO orders(id, tenant_id, branch_id, order_number, customer_id, 
           order_status, payment_status, subtotal, total_amount, created_at, updated_at)
           VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''',
        [
          newOrder.id,
          newOrder.tenantId,
          newOrder.branchId,
          newOrder.orderNumber,
          newOrder.customerId,
          newOrder.status.name,
          newOrder.paymentStatus.name,
          newOrder.subtotal,
          newOrder.totalAmount,
          newOrder.createdAt.toIso8601String(),
          newOrder.updatedAt?.toIso8601String(),
        ],
      );

      // 2. Insert Items
      for (final item in items) {
        final itemId = item.id != null && item.id!.isNotEmpty
            ? item.id!
            : _uuid.v4();
        await tx.execute(
          '''INSERT INTO order_items(id, tenant_id, order_id, product_id, product_name, quantity, unit_price, subtotal)
              VALUES(?, ?, ?, ?, ?, ?, ?, ?)''',
          [
            itemId,
            newOrder.tenantId,
            newOrder.id,
            item.productId,
            item.productName,
            item.quantity,
            item.unitPrice,
            item.subtotal,
          ],
        );
      }
    });

    return newOrder;
  }

  /// Update order status
  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    final now = DateTime.now();
    await _db.execute(
      'UPDATE orders SET order_status = ?, updated_at = ? WHERE id = ?',
      [status.name, now.toIso8601String(), orderId],
    );
  }

  /// Update payment status
  Future<void> updatePaymentStatus(String orderId, PaymentStatus status) async {
    final now = DateTime.now();
    await _db.execute(
      'UPDATE orders SET payment_status = ?, updated_at = ? WHERE id = ?',
      [status.name, now.toIso8601String(), orderId],
    );
  }
}
