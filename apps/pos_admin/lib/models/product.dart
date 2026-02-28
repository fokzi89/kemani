// Product model (tenant-scoped catalog)
class Product {
  final String id;
  final String tenantId;
  final String name;
  final String? description;
  final String? sku;
  final String? barcode;
  final String? category;
  final double unitPrice; // selling price
  final double? costPrice;
  final String? imageUrl;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
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
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      sku: json['sku'] as String?,
      barcode: json['barcode'] as String?,
      category: json['category'] as String?,
      unitPrice: (json['unit_price'] as num).toDouble(),
      costPrice: json['cost_price'] != null ? (json['cost_price'] as num).toDouble() : null,
      imageUrl: json['image_url'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
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
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Product copyWith({
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
  }) {
    return Product(
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
    );
  }
}

// Branch Inventory model (per-branch stock levels)
class BranchInventory {
  final String id;
  final String tenantId;
  final String branchId;
  final String productId;
  final int stockQuantity;
  final int? lowStockThreshold;
  final DateTime? expiryDate;
  final int? expiryAlertDays;
  final int reservedQuantity;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  BranchInventory({
    required this.id,
    required this.tenantId,
    required this.branchId,
    required this.productId,
    required this.stockQuantity,
    this.lowStockThreshold,
    this.expiryDate,
    this.expiryAlertDays,
    this.reservedQuantity = 0,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BranchInventory.fromJson(Map<String, dynamic> json) {
    return BranchInventory(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      branchId: json['branch_id'] as String,
      productId: json['product_id'] as String,
      stockQuantity: json['stock_quantity'] as int? ?? 0,
      lowStockThreshold: json['low_stock_threshold'] as int?,
      expiryDate: json['expiry_date'] != null
          ? DateTime.parse(json['expiry_date'] as String)
          : null,
      expiryAlertDays: json['expiry_alert_days'] as int?,
      reservedQuantity: json['reserved_quantity'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'branch_id': branchId,
      'product_id': productId,
      'stock_quantity': stockQuantity,
      'low_stock_threshold': lowStockThreshold,
      'expiry_date': expiryDate?.toIso8601String().split('T')[0],
      'expiry_alert_days': expiryAlertDays,
      'reserved_quantity': reservedQuantity,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  int get availableQuantity => stockQuantity - reservedQuantity;

  bool get isLowStock {
    if (lowStockThreshold == null) return false;
    return availableQuantity <= lowStockThreshold!;
  }

  bool get isOutOfStock => availableQuantity <= 0;

  bool get isExpiringSoon {
    if (expiryDate == null || expiryAlertDays == null) return false;
    final daysUntilExpiry = expiryDate!.difference(DateTime.now()).inDays;
    return daysUntilExpiry >= 0 && daysUntilExpiry <= expiryAlertDays!;
  }

  bool get isExpired {
    if (expiryDate == null) return false;
    return expiryDate!.isBefore(DateTime.now());
  }

  String get stockStatus {
    if (isOutOfStock) return 'out_of_stock';
    if (isLowStock) return 'low_stock';
    return 'in_stock';
  }
}

// Combined view for product with inventory
class ProductWithInventory {
  final Product product;
  final BranchInventory? inventory;

  ProductWithInventory({
    required this.product,
    this.inventory,
  });

  int get stockQuantity => inventory?.stockQuantity ?? 0;
  int get availableQuantity => inventory?.availableQuantity ?? 0;
  bool get isLowStock => inventory?.isLowStock ?? false;
  bool get isOutOfStock => inventory?.isOutOfStock ?? true;
  String get stockStatus => inventory?.stockStatus ?? 'unknown';
}
