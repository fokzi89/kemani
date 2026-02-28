class Sale {
  final String id;
  final String tenantId;
  final String branchId;
  final String saleNumber;
  final String cashierId;
  final String? customerId;
  final double subtotal;
  final double taxAmount;
  final double discountAmount;
  final double totalAmount;
  final String paymentMethod;
  final String? paymentReference;
  final String status;
  final DateTime? voidedAt;
  final String? voidedById;
  final String? voidReason;
  final bool isSynced;
  final DateTime createdAt;
  final DateTime updatedAt;

  Sale({
    required this.id,
    required this.tenantId,
    required this.branchId,
    required this.saleNumber,
    required this.cashierId,
    this.customerId,
    required this.subtotal,
    required this.taxAmount,
    required this.discountAmount,
    required this.totalAmount,
    required this.paymentMethod,
    this.paymentReference,
    required this.status,
    this.voidedAt,
    this.voidedById,
    this.voidReason,
    this.isSynced = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Sale.fromJson(Map<String, dynamic> json) {
    return Sale(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      branchId: json['branch_id'] as String,
      saleNumber: json['sale_number'] as String,
      cashierId: json['cashier_id'] as String,
      customerId: json['customer_id'] as String?,
      subtotal: (json['subtotal'] as num).toDouble(),
      taxAmount: (json['tax_amount'] as num).toDouble(),
      discountAmount: (json['discount_amount'] as num).toDouble(),
      totalAmount: (json['total_amount'] as num).toDouble(),
      paymentMethod: json['payment_method'] as String,
      paymentReference: json['payment_reference'] as String?,
      status: json['status'] as String,
      voidedAt: json['voided_at'] != null
          ? DateTime.parse(json['voided_at'] as String)
          : null,
      voidedById: json['voided_by_id'] as String?,
      voidReason: json['void_reason'] as String?,
      isSynced: json['is_synced'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'branch_id': branchId,
      'sale_number': saleNumber,
      'cashier_id': cashierId,
      'customer_id': customerId,
      'subtotal': subtotal,
      'tax_amount': taxAmount,
      'discount_amount': discountAmount,
      'total_amount': totalAmount,
      'payment_method': paymentMethod,
      'payment_reference': paymentReference,
      'status': status,
      'voided_at': voidedAt?.toIso8601String(),
      'voided_by_id': voidedById,
      'void_reason': voidReason,
      'is_synced': isSynced,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class SaleItem {
  final String id;
  final String saleId;
  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double discountPercent;
  final double discountAmount;
  final double subtotal;

  SaleItem({
    required this.id,
    required this.saleId,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    this.discountPercent = 0,
    this.discountAmount = 0,
    required this.subtotal,
  });

  factory SaleItem.fromJson(Map<String, dynamic> json) {
    return SaleItem(
      id: json['id'] as String,
      saleId: json['sale_id'] as String,
      productId: json['product_id'] as String,
      productName: json['product_name'] as String,
      quantity: json['quantity'] as int,
      unitPrice: (json['unit_price'] as num).toDouble(),
      discountPercent: json['discount_percent'] != null
          ? (json['discount_percent'] as num).toDouble()
          : 0,
      discountAmount: json['discount_amount'] != null
          ? (json['discount_amount'] as num).toDouble()
          : 0,
      subtotal: (json['subtotal'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sale_id': saleId,
      'product_id': productId,
      'product_name': productName,
      'quantity': quantity,
      'unit_price': unitPrice,
      'discount_percent': discountPercent,
      'discount_amount': discountAmount,
      'subtotal': subtotal,
    };
  }
}
