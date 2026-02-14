enum OrderStatus { pending, confirmed, preparing, ready, completed, cancelled }
enum PaymentStatus { unpaid, paid, refunded }

class OrderItem {
  final String? id;
  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double subtotal;

  OrderItem({
    this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'],
      productId: json['product_id'],
      productName: json['product_name'],
      quantity: json['quantity'],
      unitPrice: (json['unit_price'] as num).toDouble(),
      subtotal: (json['subtotal'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'product_id': productId,
      'product_name': productName,
      'quantity': quantity,
      'unit_price': unitPrice,
      'subtotal': subtotal,
    };
  }
}

class Order {
  final String id;
  final String tenantId;
  final String branchId;
  final String orderNumber;
  final String customerId;
  final OrderStatus status;
  final PaymentStatus paymentStatus;
  final double subtotal;
  final double totalAmount;
  final DateTime createdAt;
  final List<OrderItem>? items;

  Order({
    required this.id,
    required this.tenantId,
    required this.branchId,
    required this.orderNumber,
    required this.customerId,
    required this.status,
    required this.paymentStatus,
    required this.subtotal,
    required this.totalAmount,
    required this.createdAt,
    this.items,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      tenantId: json['tenant_id'],
      branchId: json['branch_id'],
      orderNumber: json['order_number'],
      customerId: json['customer_id'],
      status: OrderStatus.values.firstWhere((e) => e.name == json['order_status'], orElse: () => OrderStatus.pending),
      paymentStatus: PaymentStatus.values.firstWhere((e) => e.name == json['payment_status'], orElse: () => PaymentStatus.unpaid),
      subtotal: (json['subtotal'] as num).toDouble(),
      totalAmount: (json['total_amount'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at']),
      items: json['order_items'] != null
          ? (json['order_items'] as List).map((i) => OrderItem.fromJson(i)).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'branch_id': branchId,
      'order_number': orderNumber,
      'customer_id': customerId,
      'order_status': status.name,
      'payment_status': paymentStatus.name,
      'subtotal': subtotal,
      'total_amount': totalAmount,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
