import 'dart:async';
import 'local_database_service.dart';
import 'sales_service.dart';
import 'product_service.dart';
import 'connectivity_service.dart';
import '../models/pending_sale.dart';
import '../models/product.dart';

/// Service for syncing offline data to Supabase
class SyncService {
  final LocalDatabaseService _localDb;
  final SalesService _salesService;
  final ProductService _productService;
  final ConnectivityService _connectivityService;

  bool _isSyncing = false;
  Timer? _periodicSyncTimer;

  SyncService(
    this._localDb,
    this._salesService,
    this._productService,
    this._connectivityService,
  );

  /// Start periodic background sync (every 5 minutes when online)
  void startPeriodicSync() {
    _periodicSyncTimer?.cancel();
    _periodicSyncTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (_connectivityService.isOnline && !_isSyncing) {
        syncPendingSales();
      }
    });

    print('✅ Periodic sync started (every 5 minutes)');
  }

  void stopPeriodicSync() {
    _periodicSyncTimer?.cancel();
    _periodicSyncTimer = null;
    print('❌ Periodic sync stopped');
  }

  // ============================================================================
  // PENDING SALES SYNC
  // ============================================================================

  /// Sync all pending sales to Supabase
  Future<SyncResult> syncPendingSales() async {
    if (_isSyncing) {
      return SyncResult.skipped('Already syncing');
    }

    if (!_connectivityService.isOnline) {
      return SyncResult.skipped('Offline');
    }

    _isSyncing = true;

    try {
      final pendingSalesData = await _localDb.getPendingSales(status: 'pending');

      if (pendingSalesData.isEmpty) {
        print('✅ No pending sales to sync');
        return SyncResult.completed(0, 0, []);
      }

      int successCount = 0;
      int failureCount = 0;
      final errors = <String>[];

      print('📤 Syncing ${pendingSalesData.length} pending sales...');

      for (final saleData in pendingSalesData) {
        final pendingSale = PendingSale.fromJson(saleData);

        try {
          // Mark as syncing
          await _localDb.updatePendingSaleStatus(pendingSale.id, 'syncing');

          // Attempt sync
          final result = await _syncSaleToSupabase(pendingSale);

          if (result.success) {
            // Mark as synced
            await _localDb.updatePendingSaleStatus(pendingSale.id, 'synced');

            // Delete after successful sync (optional: keep for 7 days via cleanup)
            // await _localDb.deletePendingSale(pendingSale.id);

            successCount++;
            print('  ✅ Synced: ${pendingSale.saleNumber}');
          } else {
            // Mark as failed
            await _localDb.updatePendingSaleStatus(
              pendingSale.id,
              'failed',
              error: result.error,
            );

            failureCount++;
            errors.add('${pendingSale.saleNumber}: ${result.error}');
            print('  ❌ Failed: ${pendingSale.saleNumber} - ${result.error}');
          }
        } catch (e) {
          await _localDb.updatePendingSaleStatus(
            pendingSale.id,
            'failed',
            error: e.toString(),
          );

          failureCount++;
          errors.add('${pendingSale.saleNumber}: $e');
          print('  ❌ Error: ${pendingSale.saleNumber} - $e');
        }
      }

      print('📊 Sync complete: $successCount succeeded, $failureCount failed');
      return SyncResult.completed(successCount, failureCount, errors);
    } finally {
      _isSyncing = false;
    }
  }

  /// Sync a single pending sale to Supabase
  Future<SaleSyncResult> _syncSaleToSupabase(PendingSale pendingSale) async {
    try {
      // Step 1: Check if sale already exists (idempotency)
      final existingSale = await _salesService.getSale(pendingSale.id);
      if (existingSale != null) {
        print('  ℹ️  Sale ${pendingSale.saleNumber} already exists in Supabase');
        return SaleSyncResult.success();
      }

      // Step 2: Validate stock levels for each item
      for (final item in pendingSale.items) {
        try {
          final inventory = await _productService.getProductWithInventory(
            productId: item.productId,
            branchId: pendingSale.branchId,
          );

          if (inventory == null) {
            return SaleSyncResult.failed(
              'Product ${item.productName} no longer exists',
            );
          }

          final availableStock = inventory.inventory?.availableQuantity ?? 0;
          if (availableStock < item.quantity) {
            return SaleSyncResult.failed(
              'Insufficient stock for ${item.productName}. '
              'Available: $availableStock, Required: ${item.quantity}',
            );
          }
        } catch (e) {
          return SaleSyncResult.failed(
            'Failed to validate stock for ${item.productName}: $e',
          );
        }
      }

      // Step 3: Create sale in Supabase using existing createSale method
      try {
        final sale = await _salesService.createSaleWithId(
          saleId: pendingSale.id, // Use same ID for idempotency
          items: pendingSale.items.map((item) => {
            'productId': item.productId,
            'productName': item.productName,
            'quantity': item.quantity,
            'unitPrice': item.unitPrice,
            'discountPercent': item.discountPercent,
          }).toList(),
          customerId: pendingSale.customerId,
          paymentMethod: pendingSale.paymentMethod,
          paymentReference: pendingSale.paymentReference,
          discountAmount: pendingSale.discountAmount,
          taxRate: 0.075,
        );

        print('  ✅ Sale created in Supabase: ${pendingSale.saleNumber}');
        return SaleSyncResult.success();
      } catch (e) {
        return SaleSyncResult.failed('Failed to create sale in Supabase: $e');
      }
    } catch (e) {
      return SaleSyncResult.failed('Unexpected error: $e');
    }
  }

  // ============================================================================
  // PRODUCT & INVENTORY CACHE REFRESH
  // ============================================================================

  /// Refresh product cache from Supabase
  Future<void> refreshProductCache() async {
    if (!_connectivityService.isOnline) {
      print('⚠️  Cannot refresh products: offline');
      return;
    }

    try {
      print('🔄 Refreshing product cache...');

      // Fetch all products (adjust limit as needed)
      final products = await _productService.listProducts(limit: 1000);

      // Convert to JSON and cache
      final productsJson = products.map((p) => p.toJson()).toList();
      await _localDb.cacheProducts(productsJson);

      print('✅ Cached ${products.length} products');
    } catch (e) {
      print('❌ Failed to refresh product cache: $e');
    }
  }

  /// Refresh branch inventory cache from Supabase
  Future<void> refreshInventoryCache(String branchId) async {
    if (!_connectivityService.isOnline) {
      print('⚠️  Cannot refresh inventory: offline');
      return;
    }

    try {
      print('🔄 Refreshing inventory cache for branch $branchId...');

      // Fetch all inventory for this branch
      final inventory = await _productService.getBranchInventory(branchId);

      // Convert to JSON and cache
      final inventoryJson = inventory.map((inv) => inv.toJson()).toList();
      await _localDb.cacheInventory(branchId, inventoryJson);

      print('✅ Cached ${inventory.length} inventory items');
    } catch (e) {
      print('❌ Failed to refresh inventory cache: $e');
    }
  }

  /// Perform full sync: products + inventory + pending sales
  Future<void> performFullSync(String branchId) async {
    if (!_connectivityService.isOnline) {
      throw Exception('Cannot perform full sync while offline');
    }

    print('🔄 Starting full sync...');

    await refreshProductCache();
    await refreshInventoryCache(branchId);
    await syncPendingSales();

    print('✅ Full sync complete');
  }

  /// Manual sync trigger (called from UI)
  Future<void> triggerManualSync(String branchId) async {
    print('🔄 Manual sync triggered');
    await performFullSync(branchId);
  }

  // ============================================================================
  // UTILITIES
  // ============================================================================

  bool get isSyncing => _isSyncing;

  void dispose() {
    stopPeriodicSync();
  }
}

// ============================================================================
// RESULT CLASSES
// ============================================================================

class SyncResult {
  final bool success;
  final int successCount;
  final int failureCount;
  final List<String> errors;
  final String? message;

  SyncResult.completed(this.successCount, this.failureCount, this.errors)
      : success = failureCount == 0,
        message = null;

  SyncResult.skipped(this.message)
      : success = false,
        successCount = 0,
        failureCount = 0,
        errors = [];
}

class SaleSyncResult {
  final bool success;
  final String? error;

  SaleSyncResult.success()
      : success = true,
        error = null;

  SaleSyncResult.failed(this.error) : success = false;
}
