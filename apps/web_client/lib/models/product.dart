import 'package:freezed_annotation/freezed_annotation.dart';

part 'product.freezed.dart';
part 'product.g.dart';

@freezed
class Product with _$Product {
  const factory Product({
    required String id,
    @JsonKey(name: 'tenant_id') required String tenantId,
    required String name,
    String? description,
    String? sku,
    String? barcode,
    @JsonKey(name: 'category_id') String? categoryId,
    @JsonKey(name: 'cost_price') @Default(0.0) double costPrice,
    @JsonKey(name: 'selling_price') required double sellingPrice,
    @JsonKey(name: 'current_stock') @Default(0) int currentStock,
    @JsonKey(name: 'track_inventory') @Default(true) bool trackInventory,
    @JsonKey(name: 'expiry_date') DateTime? expiryDate,
    @JsonKey(name: 'image_url') String? imageUrl,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _Product;

  factory Product.fromJson(Map<String, dynamic> json) =>
      _$ProductFromJson(json);
}
