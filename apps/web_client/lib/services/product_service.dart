import '../models/product.dart';
import '../database/powersync.dart';
import 'package:uuid/uuid.dart';

class ProductService {
  final _db = PowerSyncService.db;
  final _uuid = const Uuid();

  /// Watch all products for a specific tenant
  Stream<List<Product>> watchProducts(String tenantId) {
    return _db
        .watch(
          'SELECT * FROM products WHERE tenant_id = ? ORDER BY name ASC',
          parameters: [tenantId],
        )
        .map((rows) => rows.map((row) => Product.fromJson(row)).toList());
  }

  /// Get all products for a specific tenant
  Future<List<Product>> getProducts(String tenantId) async {
    final rows = await _db.getAll(
      'SELECT * FROM products WHERE tenant_id = ? ORDER BY name ASC',
      [tenantId],
    );
    return rows.map((row) => Product.fromJson(row)).toList();
  }

  /// Get a single product by ID
  Future<Product?> getProductById(String id) async {
    final row = await _db.getOptional('SELECT * FROM products WHERE id = ?', [
      id,
    ]);
    return row != null ? Product.fromJson(row) : null;
  }

  /// Get a single product by Barcode
  Future<Product?> getProductByBarcode(String barcode, String tenantId) async {
    final row = await _db.getOptional(
      'SELECT * FROM products WHERE barcode = ? AND tenant_id = ?',
      [barcode, tenantId],
    );
    return row != null ? Product.fromJson(row) : null;
  }

  /// Create a new product
  Future<void> createProduct(Product product) async {
    final id = product.id.isEmpty ? _uuid.v4() : product.id;
    final now = DateTime.now().toIso8601String();

    await _db.execute(
      '''INSERT INTO products(id, tenant_id, name, description, sku, barcode, category_id, 
         cost_price, selling_price, current_stock, track_inventory, image_url, created_at, updated_at)
         VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''',
      [
        id,
        product.tenantId,
        product.name,
        product.description,
        product.sku,
        product.barcode,
        product.categoryId,
        product.costPrice,
        product.sellingPrice,
        product.currentStock,
        product.trackInventory ? 1 : 0,
        product.imageUrl,
        product.createdAt?.toIso8601String() ?? now,
        now,
      ],
    );
  }

  /// Update an existing product
  Future<void> updateProduct(Product product) async {
    final now = DateTime.now().toIso8601String();

    await _db.execute(
      '''UPDATE products SET 
         name = ?, description = ?, sku = ?, barcode = ?, category_id = ?, 
         cost_price = ?, selling_price = ?, current_stock = ?, track_inventory = ?, 
         image_url = ?, updated_at = ?
         WHERE id = ?''',
      [
        product.name,
        product.description,
        product.sku,
        product.barcode,
        product.categoryId,
        product.costPrice,
        product.sellingPrice,
        product.currentStock,
        product.trackInventory ? 1 : 0,
        product.imageUrl,
        now,
        product.id,
      ],
    );
  }

  /// Delete a product (soft delete or hard delete depending on sync rules)
  Future<void> deleteProduct(String id) async {
    await _db.execute('DELETE FROM products WHERE id = ?', [id]);
  }
}
