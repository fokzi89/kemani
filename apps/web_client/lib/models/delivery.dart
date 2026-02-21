import 'package:freezed_annotation/freezed_annotation.dart';

part 'delivery.freezed.dart';
part 'delivery.g.dart';

enum DeliveryStatus {
  pending,
  picked_up,
  in_transit,
  delivered,
  failed,
  cancelled,
}

@freezed
class Delivery with _$Delivery {
  const factory Delivery({
    required String id,
    @JsonKey(name: 'tenant_id') required String tenantId,
    @JsonKey(name: 'order_id') required String orderId,
    @JsonKey(name: 'driver_name') String? driverName,
    @JsonKey(name: 'driver_phone') String? driverPhone,
    @JsonKey(name: 'delivery_status')
    @Default(DeliveryStatus.pending)
    DeliveryStatus status,
    @JsonKey(name: 'delivery_address') required String address,
    @JsonKey(name: 'delivery_fee') @Default(0.0) double fee,
    String? notes,
    @JsonKey(name: 'estimated_delivery_time') DateTime? estimatedDeliveryTime,
    @JsonKey(name: 'actual_delivery_time') DateTime? actualDeliveryTime,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _Delivery;

  factory Delivery.fromJson(Map<String, dynamic> json) =>
      _$DeliveryFromJson(json);
}
