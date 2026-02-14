enum TransactionType { sale, restock, adjustment, expiry, transfer_out, transfer_in }

class InventoryTransaction {
  final String id;
  final String tenantId;
  final String branchId;
  final String productId;
  final TransactionType transactionType;
  final int quantityDelta;
  final int previousQuantity;
  final int newQuantity;
  final double? unitCost;
  final String? referenceId; // order_id or transfer_id
  final String? referenceType;
  final String? notes;
  final String staffId;
  final DateTime createdAt;

  InventoryTransaction({
    required this.id,
    required this.tenantId,
    required this.branchId,
    required this.productId,
    required this.transactionType,
    required this.quantityDelta,
    required this.previousQuantity,
    required this.newQuantity,
    this.unitCost,
    this.referenceId,
    this.referenceType,
    this.notes,
    required this.staffId,
    required this.createdAt,
  });

  factory InventoryTransaction.fromJson(Map<String, dynamic> json) {
    return InventoryTransaction(
      id: json['id'],
      tenantId: json['tenant_id'],
      branchId: json['branch_id'],
      productId: json['product_id'],
      transactionType: TransactionType.values.firstWhere((e) => e.name == json['transaction_type']),
      quantityDelta: json['quantity_delta'],
      previousQuantity: json['previous_quantity'],
      newQuantity: json['new_quantity'],
      unitCost: json['unit_cost'] != null ? (json['unit_cost'] as num).toDouble() : null,
      referenceId: json['reference_id'],
      referenceType: json['reference_type'],
      notes: json['notes'],
      staffId: json['staff_id'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'branch_id': branchId,
      'product_id': productId,
      'transaction_type': transactionType.name,
      'quantity_delta': quantityDelta,
      'previous_quantity': previousQuantity,
      'new_quantity': newQuantity,
      'unit_cost': unitCost,
      'reference_id': referenceId,
      'reference_type': referenceType,
      'notes': notes,
      'staff_id': staffId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
