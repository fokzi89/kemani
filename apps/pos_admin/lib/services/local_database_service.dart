import 'package:hive_flutter/hive_flutter.dart';

/// Local database service using Hive for web/mobile/desktop support
class LocalDatabaseService {
  // Box names
  static const String _productsBoxName = 'cached_products';
  static const String _inventoryBoxName = 'cached_inventory';
  static const String _activeSalesBoxName = 'active_sales';
  static const String _pendingSalesBoxName = 'pending_sales';
  static const String _metadataBoxName = 'metadata';

  // Hive boxes
  late Box<Map> _productsBox;
  late Box<Map> _inventoryBox;
  late Box<Map> _activeSalesBox;
  late Box<Map> _pendingSalesBox;
  late Box<String> _metadataBox;

  Future<void> initialize() async {
    // Initialize Hive for Flutter (works on web, mobile, desktop)
    await Hive.initFlutter();

    // Open boxes
    _productsBox = await Hive.openBox<Map>(_productsBoxName);
    _inventoryBox = await Hive.openBox<Map>(_inventoryBoxName);
    _activeSalesBox = await Hive.openBox<Map>(_activeSalesBoxName);
    _pendingSalesBox = await Hive.openBox<Map>(_pendingSalesBoxName);
    _metadataBox = await Hive.openBox<String>(_metadataBoxName);

    // Initialize metadata if not exists
    if (_metadataBox.get('products_last_sync') == null) {
      await _metadataBox.put('products_last_sync', '');
      await _metadataBox.put('inventory_last_sync', '');
      await _metadataBox.put('last_full_sync', '');
    }
  }

  // ============================================================================
  // ACTIVE SALES OPERATIONS
  // ============================================================================

  Future<List<Map<String, dynamic>>> getActiveSales() async {
    final sales = <Map<String, dynamic>>[];

    for (final key in _activeSalesBox.keys) {
      final saleData = Map<String, dynamic>.from(_activeSalesBox.get(key) as Map);
      sales.add(saleData);
    }

    // Sort by last accessed (most recent first)
    sales.sort((a, b) {
      final aTime = DateTime.parse(a['last_accessed_at'] as String);
      final bTime = DateTime.parse(b['last_accessed_at'] as String);
      return bTime.compareTo(aTime);
    });

    return sales;
  }

  Future<void> saveActiveSale(Map<String, dynamic> sale) async {
    final saleId = sale['id'] as String;
    await _activeSalesBox.put(saleId, sale);
  }

  Future<void> deleteActiveSale(String saleId) async {
    await _activeSalesBox.delete(saleId);
  }

  Future<Map<String, dynamic>?> getActiveSale(String saleId) async {
    final saleData = _activeSalesBox.get(saleId);
    if (saleData == null) return null;
    return Map<String, dynamic>.from(saleData);
  }

  // ============================================================================
  // PENDING SALES OPERATIONS
  // ============================================================================

  Future<void> savePendingSale(Map<String, dynamic> sale) async {
    final saleId = sale['id'] as String;
    await _pendingSalesBox.put(saleId, sale);
  }

  Future<List<Map<String, dynamic>>> getPendingSales({String? status}) async {
    final sales = <Map<String, dynamic>>[];

    for (final key in _pendingSalesBox.keys) {
      final saleData = Map<String, dynamic>.from(_pendingSalesBox.get(key) as Map);

      // Filter by status if provided
      if (status == null || saleData['sync_status'] == status) {
        sales.add(saleData);
      }
    }

    // Sort by created_at (oldest first for FIFO sync)
    sales.sort((a, b) {
      final aTime = DateTime.parse(a['created_at'] as String);
      final bTime = DateTime.parse(b['created_at'] as String);
      return aTime.compareTo(bTime);
    });

    return sales;
  }

  Future<void> updatePendingSaleStatus(
    String saleId,
    String status, {
    String? error,
  }) async {
    final saleData = _pendingSalesBox.get(saleId);
    if (saleData == null) return;

    final sale = Map<String, dynamic>.from(saleData);
    sale['sync_status'] = status;
    sale['sync_attempts'] = (sale['sync_attempts'] as int? ?? 0) + 1;
    sale['sync_error'] = error;
    sale['last_sync_attempt_at'] = DateTime.now().toIso8601String();

    await _pendingSalesBox.put(saleId, sale);
  }

  Future<void> deletePendingSale(String saleId) async {
    await _pendingSalesBox.delete(saleId);
  }

  Future<Map<String, dynamic>?> getPendingSale(String saleId) async {
    final saleData = _pendingSalesBox.get(saleId);
    if (saleData == null) return null;
    return Map<String, dynamic>.from(saleData);
  }

  // ============================================================================
  // PRODUCT CACHE OPERATIONS
  // ============================================================================

  Future<void> cacheProducts(List<Map<String, dynamic>> products) async {
    final now = DateTime.now().toIso8601String();

    for (final product in products) {
      final productId = product['id'] as String;
      final productData = Map<String, dynamic>.from(product);
      productData['cache_synced_at'] = now;
      productData['cache_version'] = 1;

      await _productsBox.put(productId, productData);
    }

    await _updateCacheMetadata('products_last_sync', now);
  }

  Future<List<Map<String, dynamic>>> getCachedProducts({
    String? category,
    String? searchQuery,
  }) async {
    final products = <Map<String, dynamic>>[];

    for (final key in _productsBox.keys) {
      final productData = Map<String, dynamic>.from(_productsBox.get(key) as Map);

      // Filter by active status
      if (productData['is_active'] != 1) continue;

      // Filter by category if provided
      if (category != null && productData['category'] != category) continue;

      // Filter by search query if provided
      if (searchQuery != null) {
        final query = searchQuery.toLowerCase();
        final name = (productData['name'] as String?)?.toLowerCase() ?? '';
        final sku = (productData['sku'] as String?)?.toLowerCase() ?? '';
        final barcode = (productData['barcode'] as String?)?.toLowerCase() ?? '';

        if (!name.contains(query) &&
            !sku.contains(query) &&
            !barcode.contains(query)) {
          continue;
        }
      }

      products.add(productData);
    }

    // Sort by name
    products.sort((a, b) {
      final aName = a['name'] as String? ?? '';
      final bName = b['name'] as String? ?? '';
      return aName.compareTo(bName);
    });

    return products;
  }

  Future<Map<String, dynamic>?> getCachedProduct(String productId) async {
    final productData = _productsBox.get(productId);
    if (productData == null) return null;
    return Map<String, dynamic>.from(productData);
  }

  // ============================================================================
  // INVENTORY CACHE OPERATIONS
  // ============================================================================

  Future<void> cacheInventory(
    String branchId,
    List<Map<String, dynamic>> inventory,
  ) async {
    final now = DateTime.now().toIso8601String();

    // Clear old inventory for this branch first
    final keysToDelete = <String>[];
    for (final key in _inventoryBox.keys) {
      final invData = _inventoryBox.get(key);
      if (invData != null &&
          (invData as Map)['branch_id'] == branchId) {
        keysToDelete.add(key as String);
      }
    }
    for (final key in keysToDelete) {
      await _inventoryBox.delete(key);
    }

    // Add fresh inventory
    for (final item in inventory) {
      final productId = item['product_id'] as String;
      final inventoryData = Map<String, dynamic>.from(item);
      inventoryData['cache_synced_at'] = now;
      inventoryData['cache_version'] = 1;

      // Key format: {branchId}_{productId}
      final key = '${branchId}_$productId';
      await _inventoryBox.put(key, inventoryData);
    }

    await _updateCacheMetadata('inventory_last_sync', now);
  }

  Future<Map<String, dynamic>?> getCachedInventory(
    String branchId,
    String productId,
  ) async {
    final key = '${branchId}_$productId';
    final inventoryData = _inventoryBox.get(key);
    if (inventoryData == null) return null;
    return Map<String, dynamic>.from(inventoryData);
  }

  Future<List<Map<String, dynamic>>> getAllCachedInventory(
      String branchId) async {
    final inventory = <Map<String, dynamic>>[];

    for (final key in _inventoryBox.keys) {
      final invData = Map<String, dynamic>.from(_inventoryBox.get(key) as Map);
      if (invData['branch_id'] == branchId) {
        inventory.add(invData);
      }
    }

    return inventory;
  }

  // ============================================================================
  // CACHE METADATA OPERATIONS
  // ============================================================================

  Future<void> _updateCacheMetadata(String key, String value) async {
    await _metadataBox.put(key, value);
  }

  Future<String?> getCacheMetadata(String key) async {
    return _metadataBox.get(key);
  }

  // ============================================================================
  // SALE NUMBER GENERATION
  // ============================================================================

  Future<String> generateSaleNumber(String branchId) async {
    final date = DateTime.now();
    final dateStr =
        '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';

    // Find max sequence for this branch + date
    int maxSeq = 0;
    final prefix = 'SALE-$branchId-$dateStr-';

    for (final key in _pendingSalesBox.keys) {
      final saleData = _pendingSalesBox.get(key);
      if (saleData != null) {
        final saleNumber = (saleData as Map)['sale_number'] as String?;
        if (saleNumber != null && saleNumber.startsWith(prefix)) {
          final seqStr = saleNumber.substring(prefix.length);
          final seq = int.tryParse(seqStr) ?? 0;
          if (seq > maxSeq) maxSeq = seq;
        }
      }
    }

    final nextSeq = (maxSeq + 1).toString().padLeft(4, '0');
    return 'SALE-$branchId-$dateStr-$nextSeq';
  }

  // ============================================================================
  // CLEANUP OPERATIONS
  // ============================================================================

  Future<void> cleanupOldData() async {
    final sevenDaysAgo =
        DateTime.now().subtract(const Duration(days: 7)).toIso8601String();

    // Delete abandoned active sales older than 7 days
    final activeSalesToDelete = <String>[];
    for (final key in _activeSalesBox.keys) {
      final saleData = _activeSalesBox.get(key);
      if (saleData != null) {
        final sale = saleData as Map;
        if (sale['status'] == 'abandoned' &&
            (sale['updated_at'] as String).compareTo(sevenDaysAgo) < 0) {
          activeSalesToDelete.add(key as String);
        }
      }
    }
    for (final key in activeSalesToDelete) {
      await _activeSalesBox.delete(key);
    }

    // Delete synced pending sales older than 7 days
    final pendingSalesToDelete = <String>[];
    for (final key in _pendingSalesBox.keys) {
      final saleData = _pendingSalesBox.get(key);
      if (saleData != null) {
        final sale = saleData as Map;
        final lastAttempt = sale['last_sync_attempt_at'] as String?;
        if (sale['sync_status'] == 'synced' &&
            lastAttempt != null &&
            lastAttempt.compareTo(sevenDaysAgo) < 0) {
          pendingSalesToDelete.add(key as String);
        }
      }
    }
    for (final key in pendingSalesToDelete) {
      await _pendingSalesBox.delete(key);
    }
  }

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  Future<void> clearAllData() async {
    await _productsBox.clear();
    await _inventoryBox.clear();
    await _activeSalesBox.clear();
    await _pendingSalesBox.clear();

    // Reset metadata
    final now = DateTime.now().toIso8601String();
    await _metadataBox.put('products_last_sync', '');
    await _metadataBox.put('inventory_last_sync', '');
    await _metadataBox.put('last_full_sync', now);
  }

  Future<void> close() async {
    await _productsBox.close();
    await _inventoryBox.close();
    await _activeSalesBox.close();
    await _pendingSalesBox.close();
    await _metadataBox.close();
  }

  // ============================================================================
  // STATISTICS (helpful for debugging)
  // ============================================================================

  Map<String, int> getStats() {
    return {
      'cached_products': _productsBox.length,
      'cached_inventory': _inventoryBox.length,
      'active_sales': _activeSalesBox.length,
      'pending_sales': _pendingSalesBox.length,
    };
  }
}
