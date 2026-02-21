// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sale.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SaleImpl _$$SaleImplFromJson(Map<String, dynamic> json) => _$SaleImpl(
  id: json['id'] as String,
  tenantId: json['tenant_id'] as String,
  saleNumber: json['sale_number'] as String,
  customerId: json['customer_id'] as String?,
  cashierId: json['cashier_id'] as String,
  totalAmount: (json['total_amount'] as num).toDouble(),
  paymentMethod: json['payment_method'] as String,
  status: json['status'] as String? ?? 'completed',
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$$SaleImplToJson(_$SaleImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'tenant_id': instance.tenantId,
      'sale_number': instance.saleNumber,
      'customer_id': instance.customerId,
      'cashier_id': instance.cashierId,
      'total_amount': instance.totalAmount,
      'payment_method': instance.paymentMethod,
      'status': instance.status,
      'created_at': instance.createdAt?.toIso8601String(),
    };

_$SaleItemImpl _$$SaleItemImplFromJson(Map<String, dynamic> json) =>
    _$SaleItemImpl(
      id: json['id'] as String,
      saleId: json['sale_id'] as String,
      productId: json['product_id'] as String,
      productName: json['product_name'] as String?,
      quantity: (json['quantity'] as num).toInt(),
      unitPrice: (json['unit_price'] as num).toDouble(),
      totalPrice: (json['total_price'] as num).toDouble(),
      tenantId: json['tenant_id'] as String,
    );

Map<String, dynamic> _$$SaleItemImplToJson(_$SaleItemImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'sale_id': instance.saleId,
      'product_id': instance.productId,
      'product_name': instance.productName,
      'quantity': instance.quantity,
      'unit_price': instance.unitPrice,
      'total_price': instance.totalPrice,
      'tenant_id': instance.tenantId,
    };
