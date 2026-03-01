import 'active_sale.dart';
import 'package:uuid/uuid.dart';

/// Completed sale awaiting sync to Supabase
class PendingSale {
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
  final DateTime createdAt;
  final DateTime updatedAt;
  final String syncStatus; // 'pending', 'syncing', 'failed', 'synced'
  final int syncAttempts;
  final String? syncError;
  final DateTime? lastSyncAttemptAt;
  final bool completedOffline;
  final String? originalActiveSaleId;
  final List<PendingSaleItem> items;

  PendingSale({
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
    this.status = 'completed',
    required this.createdAt,
    required this.updatedAt,
    this.syncStatus = 'pending',
    this.syncAttempts = 0,
    this.syncError,
    this.lastSyncAttemptAt,
    this.completedOffline = true,
    this.originalActiveSaleId,
    this.items = const [],
  });

  factory PendingSale.fromActiveSale(ActiveSale activeSale, String saleNumber) {
    final now = DateTime.now();

    return PendingSale(
      id: activeSale.id, // Keep same ID for idempotent sync
      tenantId: activeSale.tenantId,
      branchId: activeSale.branchId,
      saleNumber: saleNumber,
      cashierId: activeSale.cashierId,
      customerId: activeSale.customerId,
      subtotal: activeSale.subtotal,
      taxAmount: activeSale.taxAmount,
      discountAmount: activeSale.discountAmount,
      totalAmount: activeSale.totalAmount,
      paymentMethod: activeSale.paymentMethod ?? 'cash',
      paymentReference: activeSale.paymentReference,
      status: 'completed',
      createdAt: activeSale.createdAt,
      updatedAt: now,
      syncStatus: 'pending',
      syncAttempts: 0,
      completedOffline: true,
      originalActiveSaleId: activeSale.id,
      items: activeSale.items
          .map((item) => PendingSaleItem.fromActiveSaleItem(item, activeSale.id))
          .toList(),
    );
  }

  factory PendingSale.fromJson(Map<String, dynamic> json) {
    return PendingSale(
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
      status: json['status'] as String? ?? 'completed',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      syncStatus: json['sync_status'] as String? ?? 'pending',
      syncAttempts: json['sync_attempts'] as int? ?? 0,
      syncError: json['sync_error'] as String?,
      lastSyncAttemptAt: json['last_sync_attempt_at'] != null
          ? DateTime.parse(json['last_sync_attempt_at'] as String)
          : null,
      completedOffline: (json['completed_offline'] as int?) == 1,
      originalActiveSaleId: json['original_active_sale_id'] as String?,
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => PendingSaleItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
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
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'sync_status': syncStatus,
      'sync_attempts': syncAttempts,
      'sync_error': syncError,
      'last_sync_attempt_at': lastSyncAttemptAt?.toIso8601String(),
      'completed_offline': completedOffline ? 1 : 0,
      'original_active_sale_id': originalActiveSaleId,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }

  /// Convert to format expected by SalesService.createSale()
  Map<String, dynamic> toSupabaseJson() {
    return {
      'id': id, // Include ID for idempotent creation
      'sale_number': saleNumber,
      'customer_id': customerId,
      'subtotal': subtotal,
      'tax_amount': taxAmount,
      'discount_amount': discountAmount,
      'total_amount': totalAmount,
      'payment_method': paymentMethod,
      'payment_reference': paymentReference,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'items': items
          .map((item) => {
                'product_id': item.productId,
                'product_name': item.productName,
                'quantity': item.quantity,
                'unit_price': item.unitPrice,
                'discount_percent': item.discountPercent,
                'discount_amount': item.discountAmount,
                'subtotal': item.subtotal,
              })
          .toList(),
    };
  }

  PendingSale copyWith({
    String? id,
    String? tenantId,
    String? branchId,
    String? saleNumber,
    String? cashierId,
    String? customerId,
    double? subtotal,
    double? taxAmount,
    double? discountAmount,
    double? totalAmount,
    String? paymentMethod,
    String? paymentReference,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? syncStatus,
    int? syncAttempts,
    String? syncError,
    DateTime? lastSyncAttemptAt,
    bool? completedOffline,
    String? originalActiveSaleId,
    List<PendingSaleItem>? items,
  }) {
    return PendingSale(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      branchId: branchId ?? this.branchId,
      saleNumber: saleNumber ?? this.saleNumber,
      cashierId: cashierId ?? this.cashierId,
      customerId: customerId ?? this.customerId,
      subtotal: subtotal ?? this.subtotal,
      taxAmount: taxAmount ?? this.taxAmount,
      discountAmount: discountAmount ?? this.discountAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentReference: paymentReference ?? this.paymentReference,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      syncAttempts: syncAttempts ?? this.syncAttempts,
      syncError: syncError ?? this.syncError,
      lastSyncAttemptAt: lastSyncAttemptAt ?? this.lastSyncAttemptAt,
      completedOffline: completedOffline ?? this.completedOffline,
      originalActiveSaleId: originalActiveSaleId ?? this.originalActiveSaleId,
      items: items ?? this.items,
    );
  }
}

/// Item in a pending sale
class PendingSaleItem {
  final String id;
  final String pendingSaleId;
  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double discountPercent;
  final double discountAmount;
  final double subtotal;

  PendingSaleItem({
    required this.id,
    required this.pendingSaleId,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    this.discountPercent = 0,
    this.discountAmount = 0,
    required this.subtotal,
  });

  factory PendingSaleItem.fromActiveSaleItem(
      ActiveSaleItem item, String pendingSaleId) {
    return PendingSaleItem(
      id: item.id,
      pendingSaleId: pendingSaleId,
      productId: item.productId,
      productName: item.productName,
      quantity: item.quantity,
      unitPrice: item.unitPrice,
      discountPercent: item.discountPercent,
      discountAmount: item.discountAmount,
      subtotal: item.subtotal,
    );
  }

  factory PendingSaleItem.fromJson(Map<String, dynamic> json) {
    return PendingSaleItem(
      id: json['id'] as String,
      pendingSaleId: json['pending_sale_id'] as String,
      productId: json['product_id'] as String,
      productName: json['product_name'] as String,
      quantity: json['quantity'] as int,
      unitPrice: (json['unit_price'] as num).toDouble(),
      discountPercent: (json['discount_percent'] as num?)?.toDouble() ?? 0,
      discountAmount: (json['discount_amount'] as num?)?.toDouble() ?? 0,
      subtotal: (json['subtotal'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pending_sale_id': pendingSaleId,
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
