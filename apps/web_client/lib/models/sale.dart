import 'package:freezed_annotation/freezed_annotation.dart';

part 'sale.freezed.dart';
part 'sale.g.dart';

@freezed
class Sale with _$Sale {
  const factory Sale({
    required String id,
    @JsonKey(name: 'tenant_id') required String tenantId,
    @JsonKey(name: 'sale_number') required String saleNumber,
    @JsonKey(name: 'customer_id') String? customerId,
    @JsonKey(name: 'cashier_id') required String cashierId,
    @JsonKey(name: 'total_amount') required double totalAmount,
    @JsonKey(name: 'payment_method') required String paymentMethod,
    @Default('completed') String status, // completed, pending, cancelled
    @JsonKey(name: 'created_at') DateTime? createdAt,
    // Note: Items not usually fetched directly in the sale row unless joined
    // But good to have in model if we construct full object
    @JsonKey(ignore: true) @Default([]) List<SaleItem> items,
  }) = _Sale;

  factory Sale.fromJson(Map<String, dynamic> json) => _$SaleFromJson(json);
}

@freezed
class SaleItem with _$SaleItem {
  const factory SaleItem({
    required String id,
    @JsonKey(name: 'sale_id') required String saleId,
    @JsonKey(name: 'product_id') required String productId,
    @JsonKey(name: 'product_name')
    String? productName, // Useful when fetched with join
    required int quantity,
    @JsonKey(name: 'unit_price') required double unitPrice,
    @JsonKey(name: 'total_price') required double totalPrice,
    @JsonKey(name: 'tenant_id') required String tenantId,
  }) = _SaleItem;

  factory SaleItem.fromJson(Map<String, dynamic> json) =>
      _$SaleItemFromJson(json);
}
