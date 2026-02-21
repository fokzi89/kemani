import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';

part 'delivery.freezed.dart';
part 'delivery.g.dart';

enum DeliveryStatus {
  pending,
  in_progress,
  delivered,
  cancelled,
}

@freezed
class Delivery with _$Delivery {
  const factory Delivery({
    required String id,
    required String orderId,
    String? riderId,
    required DeliveryStatus status,
    DateTime? pickupTime,
    DateTime? deliveryTime,
    String? notes,
  }) = _Delivery;

  factory Delivery.fromJson(Map<String, dynamic> json) => _$DeliveryFromJson(json);
}
