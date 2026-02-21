import 'package:freezed_annotation/freezed_annotation.dart';

part 'order.freezed.dart';
part 'order.g.dart';

enum OrderStatus { pending, confirmed, preparing, ready, completed, cancelled }

enum PaymentStatus { unpaid, paid, refunded }

@freezed
class Order with _$Order {
  const factory Order({
    required String id,
    @JsonKey(name: 'tenant_id') required String tenantId,
    @JsonKey(name: 'branch_id') required String branchId,
    @JsonKey(name: 'order_number') required String orderNumber,
    @JsonKey(name: 'customer_id') required String customerId,
    @JsonKey(name: 'order_status')
    @Default(OrderStatus.pending)
    OrderStatus status,
    @JsonKey(name: 'payment_status')
    @Default(PaymentStatus.unpaid)
    PaymentStatus paymentStatus,
    required double subtotal,
    @JsonKey(name: 'total_amount') required double totalAmount,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
    @JsonKey(name: 'order_items') List<OrderItem>? items,
  }) = _Order;

  factory Order.fromJson(Map<String, dynamic> json) => _$OrderFromJson(json);
}

@freezed
class OrderItem with _$OrderItem {
  const factory OrderItem({
    String? id,
    @JsonKey(name: 'order_id') String? orderId,
    @JsonKey(name: 'product_id') required String productId,
    @JsonKey(name: 'product_name') required String productName,
    required int quantity,
    @JsonKey(name: 'unit_price') required double unitPrice,
    required double subtotal,
  }) = _OrderItem;

  factory OrderItem.fromJson(Map<String, dynamic> json) =>
      _$OrderItemFromJson(json);
}
