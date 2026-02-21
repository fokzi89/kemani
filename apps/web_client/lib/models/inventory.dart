import 'package:freezed_annotation/freezed_annotation.dart';

part 'inventory.freezed.dart';
part 'inventory.g.dart';

enum TransactionType {
  sale,
  restock,
  adjustment,
  expiry,
  @JsonValue('transfer_out')
  transferOut,
  @JsonValue('transfer_in')
  transferIn
}

@freezed
class InventoryTransaction with _$InventoryTransaction {
  const factory InventoryTransaction({
    required String id,
    @JsonKey(name: 'tenant_id') required String tenantId,
    @JsonKey(name: 'branch_id') String? branchId,
    @JsonKey(name: 'product_id') required String productId,
    @JsonKey(name: 'transaction_type') required TransactionType transactionType,
    @JsonKey(name: 'quantity_delta') required int quantityDelta,
    @JsonKey(name: 'previous_quantity') required int previousQuantity,
    @JsonKey(name: 'new_quantity') required int newQuantity,
    @JsonKey(name: 'unit_cost') double? unitCost,
    @JsonKey(name: 'reference_id') String? referenceId,
    @JsonKey(name: 'reference_type') String? referenceType,
    String? notes,
    @JsonKey(name: 'staff_id') String? staffId,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _InventoryTransaction;

  factory InventoryTransaction.fromJson(Map<String, dynamic> json) =>
      _$InventoryTransactionFromJson(json);
}
