import '../models/delivery.dart';
import '../database/powersync.dart';
import 'package:uuid/uuid.dart';

class DeliveryService {
  final _db = PowerSyncService.db;
  final _uuid = const Uuid();

  /// Watch all deliveries for a specific tenant
  Stream<List<Delivery>> watchDeliveries(String tenantId) {
    return _db
        .watch(
          'SELECT * FROM deliveries WHERE tenant_id = ? ORDER BY created_at DESC',
          parameters: [tenantId],
        )
        .map((rows) => rows.map((row) => Delivery.fromJson(row)).toList());
  }

  /// Get specific delivery for an order
  Future<Delivery?> getDeliveryByOrderId(String orderId) async {
    final row = await _db.getOptional(
      'SELECT * FROM deliveries WHERE order_id = ?',
      [orderId],
    );
    return row != null ? Delivery.fromJson(row) : null;
  }

  /// Create a new delivery record
  Future<Delivery> createDelivery(Delivery delivery) async {
    final id = delivery.id.isEmpty ? _uuid.v4() : delivery.id;
    final now = DateTime.now();

    final newDelivery = delivery.copyWith(
      id: id,
      createdAt: delivery.createdAt ?? now,
      updatedAt: now,
      status: DeliveryStatus.pending,
    );

    await _db.execute(
      '''INSERT INTO deliveries(
           id, tenant_id, order_id, driver_name, driver_phone, delivery_status, 
           delivery_address, delivery_fee, notes, estimated_delivery_time, 
           actual_delivery_time, created_at, updated_at
         ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''',
      [
        newDelivery.id,
        newDelivery.tenantId,
        newDelivery.orderId,
        newDelivery.driverName,
        newDelivery.driverPhone,
        newDelivery.status.name,
        newDelivery.address,
        newDelivery.fee,
        newDelivery.notes,
        newDelivery.estimatedDeliveryTime?.toIso8601String(),
        newDelivery.actualDeliveryTime?.toIso8601String(),
        newDelivery.createdAt?.toIso8601String(),
        newDelivery.updatedAt?.toIso8601String(),
      ],
    );

    return newDelivery;
  }

  /// Update delivery status
  Future<void> updateDeliveryStatus(
    String deliveryId,
    DeliveryStatus status,
  ) async {
    final now = DateTime.now();
    await _db.execute(
      '''UPDATE deliveries SET delivery_status = ?, updated_at = ?
         WHERE id = ?''',
      [status.name, now.toIso8601String(), deliveryId],
    );
  }

  /// Assign driver to delivery
  Future<void> assignDriver(
    String deliveryId,
    String driverName,
    String driverPhone,
  ) async {
    final now = DateTime.now();
    await _db.execute(
      '''UPDATE deliveries SET 
         driver_name = ?, driver_phone = ?, updated_at = ?
         WHERE id = ?''',
      [driverName, driverPhone, now.toIso8601String(), deliveryId],
    );
  }

  /// Update delivery details usually by admin or dispatcher
  Future<void> updateDelivery(Delivery delivery) async {
    final now = DateTime.now();
    await _db.execute(
      '''UPDATE deliveries SET 
           driver_name = ?, driver_phone = ?, delivery_status = ?, 
           delivery_address = ?, delivery_fee = ?, notes = ?, 
           estimated_delivery_time = ?, actual_delivery_time = ?, updated_at = ?
         WHERE id = ?''',
      [
        delivery.driverName,
        delivery.driverPhone,
        delivery.status.name,
        delivery.address,
        delivery.fee,
        delivery.notes,
        delivery.estimatedDeliveryTime?.toIso8601String(),
        delivery.actualDeliveryTime?.toIso8601String(),
        now.toIso8601String(),
        delivery.id,
      ],
    );
  }
}
