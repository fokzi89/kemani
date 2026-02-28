import 'package:pos_admin/models/order_item.dart';

class Order {
  final String id;
  final String tenantId;
  final String branchId;
  final String orderNumber;
  final String customerId;
  final String orderType;
  final String orderStatus;
  final String paymentStatus;
  final String? paymentMethod;
  final String? paymentReference;
  final double subtotal;
  final double deliveryFee;
  final double taxAmount;
  final double totalAmount;
  final String fulfillmentType;
  final String? deliveryAddressId;
  final String? specialInstructions;
  final String? ecommercePlatform;
  final String? ecommerceOrderId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<OrderItem>? items;

  Order({
    required this.id,
    required this.tenantId,
    required this.branchId,
    required this.orderNumber,
    required this.customerId,
    required this.orderType,
    this.orderStatus = 'pending',
    this.paymentStatus = 'unpaid',
    this.paymentMethod,
    this.paymentReference,
    required this.subtotal,
    this.deliveryFee = 0.0,
    this.taxAmount = 0.0,
    required this.totalAmount,
    required this.fulfillmentType,
    this.deliveryAddressId,
    this.specialInstructions,
    this.ecommercePlatform,
    this.ecommerceOrderId,
    required this.createdAt,
    required this.updatedAt,
    this.items,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      branchId: json['branch_id'] as String,
      orderNumber: json['order_number'] as String,
      customerId: json['customer_id'] as String,
      orderType: json['order_type'] as String,
      orderStatus: json['order_status'] as String? ?? 'pending',
      paymentStatus: json['payment_status'] as String? ?? 'unpaid',
      paymentMethod: json['payment_method'] as String?,
      paymentReference: json['payment_reference'] as String?,
      subtotal: (json['subtotal'] as num).toDouble(),
      deliveryFee: json['delivery_fee'] != null
          ? (json['delivery_fee'] as num).toDouble()
          : 0.0,
      taxAmount: json['tax_amount'] != null
          ? (json['tax_amount'] as num).toDouble()
          : 0.0,
      totalAmount: (json['total_amount'] as num).toDouble(),
      fulfillmentType: json['fulfillment_type'] as String,
      deliveryAddressId: json['delivery_address_id'] as String?,
      specialInstructions: json['special_instructions'] as String?,
      ecommercePlatform: json['ecommerce_platform'] as String?,
      ecommerceOrderId: json['ecommerce_order_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      items: json['items'] != null
          ? (json['items'] as List)
              .map((i) => OrderItem.fromJson(i as Map<String, dynamic>))
              .toList()
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
      'order_type': orderType,
      'order_status': orderStatus,
      'payment_status': paymentStatus,
      'payment_method': paymentMethod,
      'payment_reference': paymentReference,
      'subtotal': subtotal,
      'delivery_fee': deliveryFee,
      'tax_amount': taxAmount,
      'total_amount': totalAmount,
      'fulfillment_type': fulfillmentType,
      'delivery_address_id': deliveryAddressId,
      'special_instructions': specialInstructions,
      'ecommerce_platform': ecommercePlatform,
      'ecommerce_order_id': ecommerceOrderId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Order copyWith({
    String? id,
    String? tenantId,
    String? branchId,
    String? orderNumber,
    String? customerId,
    String? orderType,
    String? orderStatus,
    String? paymentStatus,
    String? paymentMethod,
    String? paymentReference,
    double? subtotal,
    double? deliveryFee,
    double? taxAmount,
    double? totalAmount,
    String? fulfillmentType,
    String? deliveryAddressId,
    String? specialInstructions,
    String? ecommercePlatform,
    String? ecommerceOrderId,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<OrderItem>? items,
  }) {
    return Order(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      branchId: branchId ?? this.branchId,
      orderNumber: orderNumber ?? this.orderNumber,
      customerId: customerId ?? this.customerId,
      orderType: orderType ?? this.orderType,
      orderStatus: orderStatus ?? this.orderStatus,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentReference: paymentReference ?? this.paymentReference,
      subtotal: subtotal ?? this.subtotal,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      taxAmount: taxAmount ?? this.taxAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      fulfillmentType: fulfillmentType ?? this.fulfillmentType,
      deliveryAddressId: deliveryAddressId ?? this.deliveryAddressId,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      ecommercePlatform: ecommercePlatform ?? this.ecommercePlatform,
      ecommerceOrderId: ecommerceOrderId ?? this.ecommerceOrderId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      items: items ?? this.items,
    );
  }
}
