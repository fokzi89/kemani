import '../models/customer.dart';
import '../database/powersync.dart';
import 'package:uuid/uuid.dart';

class CustomerService {
  final _db = PowerSyncService.db;
  final _uuid = const Uuid();

  /// Watch all customers for a specific tenant
  Stream<List<Customer>> watchCustomers(String tenantId) {
    return _db
        .watch(
          'SELECT * FROM customers WHERE tenant_id = ? ORDER BY full_name ASC',
          parameters: [tenantId],
        )
        .map((rows) => rows.map((row) => Customer.fromJson(row)).toList());
  }

  /// Get all customers for a specific tenant
  Future<List<Customer>> getCustomers(String tenantId) async {
    final rows = await _db.getAll(
      'SELECT * FROM customers WHERE tenant_id = ? ORDER BY full_name ASC',
      [tenantId],
    );
    return rows.map((row) => Customer.fromJson(row)).toList();
  }

  /// Search customers by name, phone, or email
  Future<List<Customer>> searchCustomers(String tenantId, String query) async {
    final searchPattern = '%$query%';
    final rows = await _db.getAll(
      '''SELECT * FROM customers 
         WHERE tenant_id = ? 
         AND (full_name LIKE ? OR phone_number LIKE ? OR email LIKE ?)
         ORDER BY full_name ASC''',
      [tenantId, searchPattern, searchPattern, searchPattern],
    );
    return rows.map((row) => Customer.fromJson(row)).toList();
  }

  /// Get a single customer by ID
  Future<Customer?> getCustomerById(String id) async {
    final row = await _db.getOptional('SELECT * FROM customers WHERE id = ?', [
      id,
    ]);
    return row != null ? Customer.fromJson(row) : null;
  }

  /// Create a new customer
  Future<Customer> createCustomer(Customer customer) async {
    final id = customer.id.isEmpty ? _uuid.v4() : customer.id;
    final now = DateTime.now();

    final newCustomer = customer.copyWith(
      id: id,
      createdAt: customer.createdAt ?? now,
      updatedAt: now,
    );

    await _db.execute(
      '''INSERT INTO customers(id, tenant_id, full_name, phone_number, email, created_at, updated_at)
         VALUES(?, ?, ?, ?, ?, ?, ?)''',
      [
        newCustomer.id,
        newCustomer.tenantId,
        newCustomer.fullName,
        newCustomer.phoneNumber,
        newCustomer.email,
        newCustomer.createdAt?.toIso8601String(),
        newCustomer.updatedAt?.toIso8601String(),
      ],
    );

    return newCustomer;
  }

  /// Update an existing customer
  Future<void> updateCustomer(Customer customer) async {
    final now = DateTime.now();
    await _db.execute(
      '''UPDATE customers SET 
         full_name = ?, phone_number = ?, email = ?, updated_at = ?
         WHERE id = ?''',
      [
        customer.fullName,
        customer.phoneNumber,
        customer.email,
        now.toIso8601String(),
        customer.id,
      ],
    );
  }

  /// Delete a customer
  Future<void> deleteCustomer(String id) async {
    await _db.execute('DELETE FROM customers WHERE id = ?', [id]);
  }
}
