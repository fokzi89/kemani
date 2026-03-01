import '../models/product.dart';

/// Locally cached product for offline access
class CachedProduct {
  final String id;
  final String tenantId;
  final String name;
  final String? description;
  final String? sku;
  final String? barcode;
  final String? category;
  final double unitPrice;
  final double? costPrice;
  final String? imageUrl;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime cacheSyncedAt;
  final int cacheVersion;

  CachedProduct({
    required this.id,
    required this.tenantId,
    required this.name,
    this.description,
    this.sku,
    this.barcode,
    this.category,
    required this.unitPrice,
    this.costPrice,
    this.imageUrl,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    required this.cacheSyncedAt,
    this.cacheVersion = 1,
  });

  factory CachedProduct.fromProduct(Product product) {
    return CachedProduct(
      id: product.id,
      tenantId: product.tenantId,
      name: product.name,
      description: product.description,
      sku: product.sku,
      barcode: product.barcode,
      category: product.category,
      unitPrice: product.unitPrice,
      costPrice: product.costPrice,
      imageUrl: product.imageUrl,
      isActive: product.isActive,
      createdAt: product.createdAt,
      updatedAt: product.updatedAt,
      cacheSyncedAt: DateTime.now(),
      cacheVersion: 1,
    );
  }

  factory CachedProduct.fromJson(Map<String, dynamic> json) {
    return CachedProduct(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      sku: json['sku'] as String?,
      barcode: json['barcode'] as String?,
      category: json['category'] as String?,
      unitPrice: (json['unit_price'] as num).toDouble(),
      costPrice: (json['cost_price'] as num?)?.toDouble(),
      imageUrl: json['image_url'] as String?,
      isActive: (json['is_active'] as int?) == 1,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      cacheSyncedAt: DateTime.parse(json['cache_synced_at'] as String),
      cacheVersion: json['cache_version'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'name': name,
      'description': description,
      'sku': sku,
      'barcode': barcode,
      'category': category,
      'unit_price': unitPrice,
      'cost_price': costPrice,
      'image_url': imageUrl,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'cache_synced_at': cacheSyncedAt.toIso8601String(),
      'cache_version': cacheVersion,
    };
  }

  /// Convert to Product model for compatibility with existing code
  Product toProduct() {
    return Product(
      id: id,
      tenantId: tenantId,
      name: name,
      description: description,
      sku: sku,
      barcode: barcode,
      category: category,
      unitPrice: unitPrice,
      costPrice: costPrice,
      imageUrl: imageUrl,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  CachedProduct copyWith({
    String? id,
    String? tenantId,
    String? name,
    String? description,
    String? sku,
    String? barcode,
    String? category,
    double? unitPrice,
    double? costPrice,
    String? imageUrl,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? cacheSyncedAt,
    int? cacheVersion,
  }) {
    return CachedProduct(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      name: name ?? this.name,
      description: description ?? this.description,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      category: category ?? this.category,
      unitPrice: unitPrice ?? this.unitPrice,
      costPrice: costPrice ?? this.costPrice,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      cacheSyncedAt: cacheSyncedAt ?? this.cacheSyncedAt,
      cacheVersion: cacheVersion ?? this.cacheVersion,
    );
  }
}

/// Locally cached branch inventory for offline access
class CachedBranchInventory {
  final String id;
  final String tenantId;
  final String branchId;
  final String productId;
  final int stockQuantity;
  final int reservedQuantity;
  final int? lowStockThreshold;
  final DateTime? expiryDate;
  final int? expiryAlertDays;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime cacheSyncedAt;
  final int cacheVersion;

  CachedBranchInventory({
    required this.id,
    required this.tenantId,
    required this.branchId,
    required this.productId,
    this.stockQuantity = 0,
    this.reservedQuantity = 0,
    this.lowStockThreshold,
    this.expiryDate,
    this.expiryAlertDays,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    required this.cacheSyncedAt,
    this.cacheVersion = 1,
  });

  factory CachedBranchInventory.fromBranchInventory(BranchInventory inventory) {
    return CachedBranchInventory(
      id: inventory.id,
      tenantId: inventory.tenantId,
      branchId: inventory.branchId,
      productId: inventory.productId,
      stockQuantity: inventory.stockQuantity,
      reservedQuantity: inventory.reservedQuantity,
      lowStockThreshold: inventory.lowStockThreshold,
      expiryDate: inventory.expiryDate,
      expiryAlertDays: inventory.expiryAlertDays,
      isActive: inventory.isActive,
      createdAt: inventory.createdAt,
      updatedAt: inventory.updatedAt,
      cacheSyncedAt: DateTime.now(),
      cacheVersion: 1,
    );
  }

  factory CachedBranchInventory.fromJson(Map<String, dynamic> json) {
    return CachedBranchInventory(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      branchId: json['branch_id'] as String,
      productId: json['product_id'] as String,
      stockQuantity: json['stock_quantity'] as int? ?? 0,
      reservedQuantity: json['reserved_quantity'] as int? ?? 0,
      lowStockThreshold: json['low_stock_threshold'] as int?,
      expiryDate: json['expiry_date'] != null
          ? DateTime.parse(json['expiry_date'] as String)
          : null,
      expiryAlertDays: json['expiry_alert_days'] as int?,
      isActive: (json['is_active'] as int?) == 1,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      cacheSyncedAt: DateTime.parse(json['cache_synced_at'] as String),
      cacheVersion: json['cache_version'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'branch_id': branchId,
      'product_id': productId,
      'stock_quantity': stockQuantity,
      'reserved_quantity': reservedQuantity,
      'low_stock_threshold': lowStockThreshold,
      'expiry_date': expiryDate?.toIso8601String(),
      'expiry_alert_days': expiryAlertDays,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'cache_synced_at': cacheSyncedAt.toIso8601String(),
      'cache_version': cacheVersion,
    };
  }

  /// Convert to BranchInventory model for compatibility
  BranchInventory toBranchInventory() {
    return BranchInventory(
      id: id,
      tenantId: tenantId,
      branchId: branchId,
      productId: productId,
      stockQuantity: stockQuantity,
      reservedQuantity: reservedQuantity,
      lowStockThreshold: lowStockThreshold,
      expiryDate: expiryDate,
      expiryAlertDays: expiryAlertDays,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Get available quantity (stock - reserved)
  int get availableQuantity => stockQuantity - reservedQuantity;

  /// Check if low stock
  bool get isLowStock =>
      lowStockThreshold != null && availableQuantity <= lowStockThreshold!;

  /// Check if out of stock
  bool get isOutOfStock => availableQuantity <= 0;

  CachedBranchInventory copyWith({
    String? id,
    String? tenantId,
    String? branchId,
    String? productId,
    int? stockQuantity,
    int? reservedQuantity,
    int? lowStockThreshold,
    DateTime? expiryDate,
    int? expiryAlertDays,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? cacheSyncedAt,
    int? cacheVersion,
  }) {
    return CachedBranchInventory(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      branchId: branchId ?? this.branchId,
      productId: productId ?? this.productId,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      reservedQuantity: reservedQuantity ?? this.reservedQuantity,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      expiryDate: expiryDate ?? this.expiryDate,
      expiryAlertDays: expiryAlertDays ?? this.expiryAlertDays,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      cacheSyncedAt: cacheSyncedAt ?? this.cacheSyncedAt,
      cacheVersion: cacheVersion ?? this.cacheVersion,
    );
  }
}
