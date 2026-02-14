class Product {
  final String id;
  final String tenantId;
  final String branchId;
  final String name;
  final String? description;
  final String? sku;
  final String? barcode;
  final String? category;
  final double unitPrice;
  final double? costPrice;
  final int stockQuantity;
  final int? lowStockThreshold;
  final String? imageUrl;
  final bool isActive;

  Product({
    required this.id,
    required this.tenantId,
    required this.branchId,
    required this.name,
    this.description,
    this.sku,
    this.barcode,
    this.category,
    required this.unitPrice,
    this.costPrice,
    required this.stockQuantity,
    this.lowStockThreshold,
    this.imageUrl,
    required this.isActive,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      tenantId: json['tenant_id'],
      branchId: json['branch_id'],
      name: json['name'],
      description: json['description'],
      sku: json['sku'],
      barcode: json['barcode'],
      category: json['category'],
      unitPrice: (json['unit_price'] as num).toDouble(),
      costPrice: json['cost_price'] != null ? (json['cost_price'] as num).toDouble() : null,
      stockQuantity: json['stock_quantity'],
      lowStockThreshold: json['low_stock_threshold'],
      imageUrl: json['image_url'],
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'branch_id': branchId,
      'name': name,
      'description': description,
      'sku': sku,
      'barcode': barcode,
      'category': category,
      'unit_price': unitPrice,
      'cost_price': costPrice,
      'stock_quantity': stockQuantity,
      'low_stock_threshold': lowStockThreshold,
      'image_url': imageUrl,
      'is_active': isActive,
    };
  }
}
