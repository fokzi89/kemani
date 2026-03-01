import 'package:uuid/uuid.dart';

/// In-progress sale that hasn't been completed yet
class ActiveSale {
  final String id;
  final String tenantId;
  final String branchId;
  final String cashierId;
  final String? customerId;
  final String? customerName;
  final double subtotal;
  final double taxAmount;
  final double discountAmount;
  final double totalAmount;
  final String? paymentMethod;
  final String? paymentReference;
  final String status; // 'draft', 'on_hold', 'abandoned'
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime lastAccessedAt;
  final List<ActiveSaleItem> items;

  ActiveSale({
    required this.id,
    required this.tenantId,
    required this.branchId,
    required this.cashierId,
    this.customerId,
    this.customerName,
    this.subtotal = 0,
    this.taxAmount = 0,
    this.discountAmount = 0,
    this.totalAmount = 0,
    this.paymentMethod,
    this.paymentReference,
    this.status = 'draft',
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    required this.lastAccessedAt,
    this.items = const [],
  });

  factory ActiveSale.create({
    required String tenantId,
    required String branchId,
    required String cashierId,
  }) {
    final now = DateTime.now();
    return ActiveSale(
      id: const Uuid().v4(),
      tenantId: tenantId,
      branchId: branchId,
      cashierId: cashierId,
      createdAt: now,
      updatedAt: now,
      lastAccessedAt: now,
    );
  }

  factory ActiveSale.fromJson(Map<String, dynamic> json) {
    return ActiveSale(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      branchId: json['branch_id'] as String,
      cashierId: json['cashier_id'] as String,
      customerId: json['customer_id'] as String?,
      customerName: json['customer_name'] as String?,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      taxAmount: (json['tax_amount'] as num?)?.toDouble() ?? 0,
      discountAmount: (json['discount_amount'] as num?)?.toDouble() ?? 0,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0,
      paymentMethod: json['payment_method'] as String?,
      paymentReference: json['payment_reference'] as String?,
      status: json['status'] as String? ?? 'draft',
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      lastAccessedAt: DateTime.parse(json['last_accessed_at'] as String),
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => ActiveSaleItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'branch_id': branchId,
      'cashier_id': cashierId,
      'customer_id': customerId,
      'customer_name': customerName,
      'subtotal': subtotal,
      'tax_amount': taxAmount,
      'discount_amount': discountAmount,
      'total_amount': totalAmount,
      'payment_method': paymentMethod,
      'payment_reference': paymentReference,
      'status': status,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'last_accessed_at': lastAccessedAt.toIso8601String(),
      'items': items.map((item) => item.toJson()).toList(),
    };
  }

  ActiveSale copyWith({
    String? id,
    String? tenantId,
    String? branchId,
    String? cashierId,
    String? customerId,
    String? customerName,
    double? subtotal,
    double? taxAmount,
    double? discountAmount,
    double? totalAmount,
    String? paymentMethod,
    String? paymentReference,
    String? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastAccessedAt,
    List<ActiveSaleItem>? items,
  }) {
    return ActiveSale(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      branchId: branchId ?? this.branchId,
      cashierId: cashierId ?? this.cashierId,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      subtotal: subtotal ?? this.subtotal,
      taxAmount: taxAmount ?? this.taxAmount,
      discountAmount: discountAmount ?? this.discountAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentReference: paymentReference ?? this.paymentReference,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
      items: items ?? this.items,
    );
  }

  /// Calculate subtotal from items
  double calculateSubtotal() {
    return items.fold(0, (sum, item) => sum + item.subtotal);
  }

  /// Calculate tax (7.5% rate)
  double calculateTax({double rate = 0.075}) {
    final taxableAmount = calculateSubtotal() - discountAmount;
    return taxableAmount * rate;
  }

  /// Calculate total
  double calculateTotal({double taxRate = 0.075}) {
    final sub = calculateSubtotal();
    final tax = calculateTax(rate: taxRate);
    return sub + tax - discountAmount;
  }

  /// Recalculate all amounts and return updated sale
  ActiveSale recalculate({double taxRate = 0.075}) {
    final sub = calculateSubtotal();
    final tax = (sub - discountAmount) * taxRate;
    final total = sub + tax - discountAmount;

    return copyWith(
      subtotal: sub,
      taxAmount: tax,
      totalAmount: total,
      updatedAt: DateTime.now(),
    );
  }
}

/// Item in an active sale
class ActiveSaleItem {
  final String id;
  final String activeSaleId;
  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double discountPercent;
  final double discountAmount;
  final double subtotal;
  final DateTime createdAt;
  final DateTime updatedAt;

  ActiveSaleItem({
    required this.id,
    required this.activeSaleId,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    this.discountPercent = 0,
    this.discountAmount = 0,
    required this.subtotal,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ActiveSaleItem.create({
    required String activeSaleId,
    required String productId,
    required String productName,
    required int quantity,
    required double unitPrice,
    double discountPercent = 0,
  }) {
    final now = DateTime.now();
    final lineTotal = quantity * unitPrice;
    final discountAmount = lineTotal * (discountPercent / 100);
    final subtotal = lineTotal - discountAmount;

    return ActiveSaleItem(
      id: const Uuid().v4(),
      activeSaleId: activeSaleId,
      productId: productId,
      productName: productName,
      quantity: quantity,
      unitPrice: unitPrice,
      discountPercent: discountPercent,
      discountAmount: discountAmount,
      subtotal: subtotal,
      createdAt: now,
      updatedAt: now,
    );
  }

  factory ActiveSaleItem.fromJson(Map<String, dynamic> json) {
    return ActiveSaleItem(
      id: json['id'] as String,
      activeSaleId: json['active_sale_id'] as String,
      productId: json['product_id'] as String,
      productName: json['product_name'] as String,
      quantity: json['quantity'] as int,
      unitPrice: (json['unit_price'] as num).toDouble(),
      discountPercent: (json['discount_percent'] as num?)?.toDouble() ?? 0,
      discountAmount: (json['discount_amount'] as num?)?.toDouble() ?? 0,
      subtotal: (json['subtotal'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'active_sale_id': activeSaleId,
      'product_id': productId,
      'product_name': productName,
      'quantity': quantity,
      'unit_price': unitPrice,
      'discount_percent': discountPercent,
      'discount_amount': discountAmount,
      'subtotal': subtotal,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ActiveSaleItem copyWith({
    String? id,
    String? activeSaleId,
    String? productId,
    String? productName,
    int? quantity,
    double? unitPrice,
    double? discountPercent,
    double? discountAmount,
    double? subtotal,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ActiveSaleItem(
      id: id ?? this.id,
      activeSaleId: activeSaleId ?? this.activeSaleId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      discountPercent: discountPercent ?? this.discountPercent,
      discountAmount: discountAmount ?? this.discountAmount,
      subtotal: subtotal ?? this.subtotal,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Recalculate subtotal based on quantity, price, and discount
  ActiveSaleItem recalculate() {
    final lineTotal = quantity * unitPrice;
    final discAmt = lineTotal * (discountPercent / 100);
    final sub = lineTotal - discAmt;

    return copyWith(
      discountAmount: discAmt,
      subtotal: sub,
      updatedAt: DateTime.now(),
    );
  }
}
