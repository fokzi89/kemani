import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/active_sale.dart';
import '../models/pending_sale.dart';
import '../models/product.dart';
import '../models/customer.dart';
import '../services/local_database_service.dart';
import '../services/sales_service.dart';
import '../services/product_service.dart';
import '../services/connectivity_service.dart';
import '../services/sync_service.dart';

/// Provider for managing multiple concurrent sales
class SalesProvider extends ChangeNotifier {
  final LocalDatabaseService _localDb;
  final SalesService _salesService;
  final ProductService _productService;
  final ConnectivityService _connectivityService;
  final SyncService _syncService;

  // State
  List<ActiveSale> _activeSales = [];
  ActiveSale? _currentSale;
  bool _isLoading = false;
  bool _isSyncing = false;

  // Getters
  List<ActiveSale> get activeSales => _activeSales;
  ActiveSale? get currentSale => _currentSale;
  bool get isOnline => _connectivityService.isOnline;
  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;
  int get activeSaleCount => _activeSales.length;

  SalesProvider(
    this._localDb,
    this._salesService,
    this._productService,
    this._connectivityService,
    this._syncService,
  ) {
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadActiveSales();

    // Listen to connectivity changes
    _connectivityService.onConnectivityChanged.listen(_handleConnectivityChange);
  }

  // ============================================================================
  // MULTI-SALE MANAGEMENT
  // ============================================================================

  /// Create a new sale
  Future<ActiveSale> createNewSale() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final tenantId = user.userMetadata?['tenant_id'] as String?;
    final branchId = user.userMetadata?['branch_id'] as String?;

    if (tenantId == null || branchId == null) {
      throw Exception('Tenant or Branch not found');
    }

    final newSale = ActiveSale.create(
      tenantId: tenantId,
      branchId: branchId,
      cashierId: user.id,
    );

    _activeSales.add(newSale);
    _currentSale = newSale;

    await _saveCurrentSale();
    notifyListeners();

    print('✅ Created new sale: ${newSale.id}');
    return newSale;
  }

  /// Switch to a different sale
  Future<void> switchToSale(String saleId) async {
    final sale = _activeSales.firstWhere(
      (s) => s.id == saleId,
      orElse: () => throw Exception('Sale not found'),
    );

    _currentSale = sale.copyWith(lastAccessedAt: DateTime.now());

    // Update in list
    final index = _activeSales.indexWhere((s) => s.id == saleId);
    if (index != -1) {
      _activeSales[index] = _currentSale!;
    }

    await _saveCurrentSale();
    notifyListeners();
  }

  /// Delete a sale
  Future<void> deleteSale(String saleId) async {
    _activeSales.removeWhere((s) => s.id == saleId);

    if (_currentSale?.id == saleId) {
      _currentSale = _activeSales.isNotEmpty ? _activeSales.first : null;
    }

    await _localDb.deleteActiveSale(saleId);
    notifyListeners();

    print('🗑️  Deleted sale: $saleId');
  }

  // ============================================================================
  // CART OPERATIONS
  // ============================================================================

  /// Add item to current sale's cart
  Future<void> addItemToCart(Product product, {int quantity = 1}) async {
    if (_currentSale == null) {
      await createNewSale();
    }

    // Check if product already in cart
    final existingItemIndex = _currentSale!.items.indexWhere(
      (item) => item.productId == product.id,
    );

    List<ActiveSaleItem> updatedItems;

    if (existingItemIndex != -1) {
      // Update existing item quantity
      final existingItem = _currentSale!.items[existingItemIndex];
      final updatedItem = existingItem.copyWith(
        quantity: existingItem.quantity + quantity,
      ).recalculate();

      updatedItems = List.from(_currentSale!.items);
      updatedItems[existingItemIndex] = updatedItem;
    } else {
      // Add new item
      final newItem = ActiveSaleItem.create(
        activeSaleId: _currentSale!.id,
        productId: product.id,
        productName: product.name,
        quantity: quantity,
        unitPrice: product.unitPrice,
      );

      updatedItems = List.from(_currentSale!.items)..add(newItem);
    }

    _currentSale = _currentSale!.copyWith(items: updatedItems).recalculate();
    _updateCurrentSaleInList();
    await _saveCurrentSale();
    notifyListeners();
  }

  /// Update item quantity
  Future<void> updateItemQuantity(String itemId, int quantity) async {
    if (_currentSale == null) return;

    List<ActiveSaleItem> updatedItems;

    if (quantity <= 0) {
      // Remove item
      updatedItems = _currentSale!.items.where((item) => item.id != itemId).toList();
    } else {
      // Update quantity
      updatedItems = _currentSale!.items.map((item) {
        if (item.id == itemId) {
          return item.copyWith(quantity: quantity).recalculate();
        }
        return item;
      }).toList();
    }

    _currentSale = _currentSale!.copyWith(items: updatedItems).recalculate();
    _updateCurrentSaleInList();
    await _saveCurrentSale();
    notifyListeners();
  }

  /// Remove item from cart
  Future<void> removeItemFromCart(String itemId) async {
    if (_currentSale == null) return;

    final updatedItems = _currentSale!.items.where((item) => item.id != itemId).toList();

    _currentSale = _currentSale!.copyWith(items: updatedItems).recalculate();
    _updateCurrentSaleInList();
    await _saveCurrentSale();
    notifyListeners();
  }

  /// Update discount
  Future<void> updateDiscount(double discountAmount) async {
    if (_currentSale == null) return;

    _currentSale = _currentSale!.copyWith(discountAmount: discountAmount).recalculate();
    _updateCurrentSaleInList();
    await _saveCurrentSale();
    notifyListeners();
  }

  /// Update payment method
  Future<void> updatePaymentMethod(String method) async {
    if (_currentSale == null) return;

    _currentSale = _currentSale!.copyWith(paymentMethod: method);
    _updateCurrentSaleInList();
    await _saveCurrentSale();
    notifyListeners();
  }

  /// Select customer
  Future<void> selectCustomer(Customer? customer) async {
    if (_currentSale == null) return;

    _currentSale = _currentSale!.copyWith(
      customerId: customer?.id,
      customerName: customer?.fullName,
    );
    _updateCurrentSaleInList();
    await _saveCurrentSale();
    notifyListeners();
  }

  // ============================================================================
  // SALE COMPLETION
  // ============================================================================

  /// Complete the current sale
  Future<SaleCompletionResult> completeSale({
    bool validateStock = true,
  }) async {
    if (_currentSale == null) {
      return SaleCompletionResult.failed(['No active sale']);
    }

    if (_currentSale!.items.isEmpty) {
      return SaleCompletionResult.failed(['Cart is empty']);
    }

    if (_currentSale!.paymentMethod == null) {
      return SaleCompletionResult.failed(['Payment method not selected']);
    }

    _isLoading = true;
    notifyListeners();

    try {
      // Step 1: Validate stock if online
      if (isOnline && validateStock) {
        final validationResult = await _validateStockAndPrices();
        if (!validationResult.isValid) {
          _isLoading = false;
          notifyListeners();
          return SaleCompletionResult.failed(validationResult.errors);
        }
      }

      // Step 2: Generate sale number
      final branchId = _currentSale!.branchId;
      final saleNumber = await _localDb.generateSaleNumber(branchId);

      // Step 3: Try immediate sync if online
      if (isOnline) {
        try {
          final sale = await _salesService.createSaleWithId(
            saleId: _currentSale!.id,
            items: _currentSale!.items.map((item) => {
              'productId': item.productId,
              'productName': item.productName,
              'quantity': item.quantity,
              'unitPrice': item.unitPrice,
              'discountPercent': item.discountPercent,
            }).toList(),
            customerId: _currentSale!.customerId,
            paymentMethod: _currentSale!.paymentMethod!,
            paymentReference: _currentSale!.paymentReference,
            discountAmount: _currentSale!.discountAmount,
            taxRate: 0.075,
          );

          // Success: Delete active sale
          await _localDb.deleteActiveSale(_currentSale!.id);
          _activeSales.removeWhere((s) => s.id == _currentSale!.id);
          _currentSale = _activeSales.isNotEmpty ? _activeSales.first : null;

          _isLoading = false;
          notifyListeners();

          print('✅ Sale completed online: $saleNumber');
          return SaleCompletionResult.success(sale, syncedImmediately: true);
        } catch (e) {
          // Failed online: Fall back to offline
          print('⚠️  Online sale failed, saving offline: $e');
          return await _completeSaleOffline(saleNumber);
        }
      } else {
        // Offline mode
        return await _completeSaleOffline(saleNumber);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Complete sale offline (save to pending queue)
  Future<SaleCompletionResult> _completeSaleOffline(String saleNumber) async {
    // Convert ActiveSale to PendingSale
    final pendingSale = PendingSale.fromActiveSale(_currentSale!, saleNumber);

    // Save to pending_sales
    await _localDb.savePendingSale(pendingSale.toJson());

    // Delete from active_sales
    await _localDb.deleteActiveSale(_currentSale!.id);
    _activeSales.removeWhere((s) => s.id == _currentSale!.id);
    _currentSale = _activeSales.isNotEmpty ? _activeSales.first : null;

    notifyListeners();

    print('💾 Sale saved offline: $saleNumber');
    return SaleCompletionResult.success(pendingSale, syncedImmediately: false);
  }

  /// Validate stock quantities and prices before completing sale
  Future<ValidationResult> _validateStockAndPrices() async {
    final errors = <String>[];

    for (final item in _currentSale!.items) {
      try {
        final inventory = await _productService.getProductWithInventory(
          productId: item.productId,
          branchId: _currentSale!.branchId,
        );

        if (inventory == null) {
          errors.add('Product ${item.productName} not found');
          continue;
        }

        final availableStock = inventory.inventory?.availableQuantity ?? 0;
        if (availableStock < item.quantity) {
          errors.add(
            'Insufficient stock for ${item.productName}. '
            'Available: $availableStock, Required: ${item.quantity}',
          );
        }

        // Check price difference (warn if > 10%)
        final priceDiff = (inventory.product.unitPrice - item.unitPrice).abs();
        final priceChangePercent = (priceDiff / item.unitPrice) * 100;
        if (priceChangePercent > 10) {
          errors.add(
            'Price changed for ${item.productName}: '
            'NGN ${item.unitPrice} → NGN ${inventory.product.unitPrice}',
          );
        }
      } catch (e) {
        errors.add('Failed to validate ${item.productName}: $e');
      }
    }

    return ValidationResult(errors.isEmpty, errors);
  }

  // ============================================================================
  // CONNECTIVITY HANDLING
  // ============================================================================

  void _handleConnectivityChange(bool online) {
    notifyListeners();

    if (online) {
      print('🌐 Online: Triggering background sync');
      _triggerBackgroundSync();
    } else {
      print('📵 Offline mode');
    }
  }

  Future<void> _triggerBackgroundSync() async {
    if (_isSyncing) return;

    _isSyncing = true;
    notifyListeners();

    try {
      final user = Supabase.instance.client.auth.currentUser;
      final branchId = user?.userMetadata?['branch_id'] as String?;

      if (branchId != null) {
        await _syncService.syncPendingSales();
      }
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  // ============================================================================
  // PERSISTENCE
  // ============================================================================

  Future<void> _loadActiveSales() async {
    _isLoading = true;
    notifyListeners();

    try {
      final salesData = await _localDb.getActiveSales();
      _activeSales = salesData.map((data) => ActiveSale.fromJson(data)).toList();

      // Set current sale to most recently accessed
      if (_activeSales.isNotEmpty) {
        _currentSale = _activeSales.first;
      }

      print('📂 Loaded ${_activeSales.length} active sales');
    } catch (e) {
      print('❌ Failed to load active sales: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveCurrentSale() async {
    if (_currentSale != null) {
      await _localDb.saveActiveSale(_currentSale!.toJson());
    }
  }

  void _updateCurrentSaleInList() {
    if (_currentSale == null) return;

    final index = _activeSales.indexWhere((s) => s.id == _currentSale!.id);
    if (index != -1) {
      _activeSales[index] = _currentSale!;
    }
  }
}

// ============================================================================
// RESULT CLASSES
// ============================================================================

class SaleCompletionResult {
  final bool success;
  final dynamic sale; // Sale or PendingSale
  final bool syncedImmediately;
  final List<String> errors;

  SaleCompletionResult.success(this.sale, {required this.syncedImmediately})
      : success = true,
        errors = [];

  SaleCompletionResult.failed(this.errors)
      : success = false,
        sale = null,
        syncedImmediately = false;
}

class ValidationResult {
  final bool isValid;
  final List<String> errors;

  ValidationResult(this.isValid, this.errors);
}
