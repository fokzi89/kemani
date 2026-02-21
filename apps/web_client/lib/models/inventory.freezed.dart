// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'inventory.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

InventoryTransaction _$InventoryTransactionFromJson(Map<String, dynamic> json) {
  return _InventoryTransaction.fromJson(json);
}

/// @nodoc
mixin _$InventoryTransaction {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'tenant_id')
  String get tenantId => throw _privateConstructorUsedError;
  @JsonKey(name: 'branch_id')
  String? get branchId => throw _privateConstructorUsedError;
  @JsonKey(name: 'product_id')
  String get productId => throw _privateConstructorUsedError;
  @JsonKey(name: 'transaction_type')
  TransactionType get transactionType => throw _privateConstructorUsedError;
  @JsonKey(name: 'quantity_delta')
  int get quantityDelta => throw _privateConstructorUsedError;
  @JsonKey(name: 'previous_quantity')
  int get previousQuantity => throw _privateConstructorUsedError;
  @JsonKey(name: 'new_quantity')
  int get newQuantity => throw _privateConstructorUsedError;
  @JsonKey(name: 'unit_cost')
  double? get unitCost => throw _privateConstructorUsedError;
  @JsonKey(name: 'reference_id')
  String? get referenceId => throw _privateConstructorUsedError;
  @JsonKey(name: 'reference_type')
  String? get referenceType => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;
  @JsonKey(name: 'staff_id')
  String? get staffId => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime? get createdAt => throw _privateConstructorUsedError;

  /// Serializes this InventoryTransaction to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of InventoryTransaction
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $InventoryTransactionCopyWith<InventoryTransaction> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $InventoryTransactionCopyWith<$Res> {
  factory $InventoryTransactionCopyWith(
    InventoryTransaction value,
    $Res Function(InventoryTransaction) then,
  ) = _$InventoryTransactionCopyWithImpl<$Res, InventoryTransaction>;
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'tenant_id') String tenantId,
    @JsonKey(name: 'branch_id') String? branchId,
    @JsonKey(name: 'product_id') String productId,
    @JsonKey(name: 'transaction_type') TransactionType transactionType,
    @JsonKey(name: 'quantity_delta') int quantityDelta,
    @JsonKey(name: 'previous_quantity') int previousQuantity,
    @JsonKey(name: 'new_quantity') int newQuantity,
    @JsonKey(name: 'unit_cost') double? unitCost,
    @JsonKey(name: 'reference_id') String? referenceId,
    @JsonKey(name: 'reference_type') String? referenceType,
    String? notes,
    @JsonKey(name: 'staff_id') String? staffId,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  });
}

/// @nodoc
class _$InventoryTransactionCopyWithImpl<
  $Res,
  $Val extends InventoryTransaction
>
    implements $InventoryTransactionCopyWith<$Res> {
  _$InventoryTransactionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of InventoryTransaction
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? tenantId = null,
    Object? branchId = freezed,
    Object? productId = null,
    Object? transactionType = null,
    Object? quantityDelta = null,
    Object? previousQuantity = null,
    Object? newQuantity = null,
    Object? unitCost = freezed,
    Object? referenceId = freezed,
    Object? referenceType = freezed,
    Object? notes = freezed,
    Object? staffId = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            tenantId: null == tenantId
                ? _value.tenantId
                : tenantId // ignore: cast_nullable_to_non_nullable
                      as String,
            branchId: freezed == branchId
                ? _value.branchId
                : branchId // ignore: cast_nullable_to_non_nullable
                      as String?,
            productId: null == productId
                ? _value.productId
                : productId // ignore: cast_nullable_to_non_nullable
                      as String,
            transactionType: null == transactionType
                ? _value.transactionType
                : transactionType // ignore: cast_nullable_to_non_nullable
                      as TransactionType,
            quantityDelta: null == quantityDelta
                ? _value.quantityDelta
                : quantityDelta // ignore: cast_nullable_to_non_nullable
                      as int,
            previousQuantity: null == previousQuantity
                ? _value.previousQuantity
                : previousQuantity // ignore: cast_nullable_to_non_nullable
                      as int,
            newQuantity: null == newQuantity
                ? _value.newQuantity
                : newQuantity // ignore: cast_nullable_to_non_nullable
                      as int,
            unitCost: freezed == unitCost
                ? _value.unitCost
                : unitCost // ignore: cast_nullable_to_non_nullable
                      as double?,
            referenceId: freezed == referenceId
                ? _value.referenceId
                : referenceId // ignore: cast_nullable_to_non_nullable
                      as String?,
            referenceType: freezed == referenceType
                ? _value.referenceType
                : referenceType // ignore: cast_nullable_to_non_nullable
                      as String?,
            notes: freezed == notes
                ? _value.notes
                : notes // ignore: cast_nullable_to_non_nullable
                      as String?,
            staffId: freezed == staffId
                ? _value.staffId
                : staffId // ignore: cast_nullable_to_non_nullable
                      as String?,
            createdAt: freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$InventoryTransactionImplCopyWith<$Res>
    implements $InventoryTransactionCopyWith<$Res> {
  factory _$$InventoryTransactionImplCopyWith(
    _$InventoryTransactionImpl value,
    $Res Function(_$InventoryTransactionImpl) then,
  ) = __$$InventoryTransactionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'tenant_id') String tenantId,
    @JsonKey(name: 'branch_id') String? branchId,
    @JsonKey(name: 'product_id') String productId,
    @JsonKey(name: 'transaction_type') TransactionType transactionType,
    @JsonKey(name: 'quantity_delta') int quantityDelta,
    @JsonKey(name: 'previous_quantity') int previousQuantity,
    @JsonKey(name: 'new_quantity') int newQuantity,
    @JsonKey(name: 'unit_cost') double? unitCost,
    @JsonKey(name: 'reference_id') String? referenceId,
    @JsonKey(name: 'reference_type') String? referenceType,
    String? notes,
    @JsonKey(name: 'staff_id') String? staffId,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  });
}

/// @nodoc
class __$$InventoryTransactionImplCopyWithImpl<$Res>
    extends _$InventoryTransactionCopyWithImpl<$Res, _$InventoryTransactionImpl>
    implements _$$InventoryTransactionImplCopyWith<$Res> {
  __$$InventoryTransactionImplCopyWithImpl(
    _$InventoryTransactionImpl _value,
    $Res Function(_$InventoryTransactionImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of InventoryTransaction
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? tenantId = null,
    Object? branchId = freezed,
    Object? productId = null,
    Object? transactionType = null,
    Object? quantityDelta = null,
    Object? previousQuantity = null,
    Object? newQuantity = null,
    Object? unitCost = freezed,
    Object? referenceId = freezed,
    Object? referenceType = freezed,
    Object? notes = freezed,
    Object? staffId = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(
      _$InventoryTransactionImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        tenantId: null == tenantId
            ? _value.tenantId
            : tenantId // ignore: cast_nullable_to_non_nullable
                  as String,
        branchId: freezed == branchId
            ? _value.branchId
            : branchId // ignore: cast_nullable_to_non_nullable
                  as String?,
        productId: null == productId
            ? _value.productId
            : productId // ignore: cast_nullable_to_non_nullable
                  as String,
        transactionType: null == transactionType
            ? _value.transactionType
            : transactionType // ignore: cast_nullable_to_non_nullable
                  as TransactionType,
        quantityDelta: null == quantityDelta
            ? _value.quantityDelta
            : quantityDelta // ignore: cast_nullable_to_non_nullable
                  as int,
        previousQuantity: null == previousQuantity
            ? _value.previousQuantity
            : previousQuantity // ignore: cast_nullable_to_non_nullable
                  as int,
        newQuantity: null == newQuantity
            ? _value.newQuantity
            : newQuantity // ignore: cast_nullable_to_non_nullable
                  as int,
        unitCost: freezed == unitCost
            ? _value.unitCost
            : unitCost // ignore: cast_nullable_to_non_nullable
                  as double?,
        referenceId: freezed == referenceId
            ? _value.referenceId
            : referenceId // ignore: cast_nullable_to_non_nullable
                  as String?,
        referenceType: freezed == referenceType
            ? _value.referenceType
            : referenceType // ignore: cast_nullable_to_non_nullable
                  as String?,
        notes: freezed == notes
            ? _value.notes
            : notes // ignore: cast_nullable_to_non_nullable
                  as String?,
        staffId: freezed == staffId
            ? _value.staffId
            : staffId // ignore: cast_nullable_to_non_nullable
                  as String?,
        createdAt: freezed == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$InventoryTransactionImpl implements _InventoryTransaction {
  const _$InventoryTransactionImpl({
    required this.id,
    @JsonKey(name: 'tenant_id') required this.tenantId,
    @JsonKey(name: 'branch_id') this.branchId,
    @JsonKey(name: 'product_id') required this.productId,
    @JsonKey(name: 'transaction_type') required this.transactionType,
    @JsonKey(name: 'quantity_delta') required this.quantityDelta,
    @JsonKey(name: 'previous_quantity') required this.previousQuantity,
    @JsonKey(name: 'new_quantity') required this.newQuantity,
    @JsonKey(name: 'unit_cost') this.unitCost,
    @JsonKey(name: 'reference_id') this.referenceId,
    @JsonKey(name: 'reference_type') this.referenceType,
    this.notes,
    @JsonKey(name: 'staff_id') this.staffId,
    @JsonKey(name: 'created_at') this.createdAt,
  });

  factory _$InventoryTransactionImpl.fromJson(Map<String, dynamic> json) =>
      _$$InventoryTransactionImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'tenant_id')
  final String tenantId;
  @override
  @JsonKey(name: 'branch_id')
  final String? branchId;
  @override
  @JsonKey(name: 'product_id')
  final String productId;
  @override
  @JsonKey(name: 'transaction_type')
  final TransactionType transactionType;
  @override
  @JsonKey(name: 'quantity_delta')
  final int quantityDelta;
  @override
  @JsonKey(name: 'previous_quantity')
  final int previousQuantity;
  @override
  @JsonKey(name: 'new_quantity')
  final int newQuantity;
  @override
  @JsonKey(name: 'unit_cost')
  final double? unitCost;
  @override
  @JsonKey(name: 'reference_id')
  final String? referenceId;
  @override
  @JsonKey(name: 'reference_type')
  final String? referenceType;
  @override
  final String? notes;
  @override
  @JsonKey(name: 'staff_id')
  final String? staffId;
  @override
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  @override
  String toString() {
    return 'InventoryTransaction(id: $id, tenantId: $tenantId, branchId: $branchId, productId: $productId, transactionType: $transactionType, quantityDelta: $quantityDelta, previousQuantity: $previousQuantity, newQuantity: $newQuantity, unitCost: $unitCost, referenceId: $referenceId, referenceType: $referenceType, notes: $notes, staffId: $staffId, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$InventoryTransactionImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.tenantId, tenantId) ||
                other.tenantId == tenantId) &&
            (identical(other.branchId, branchId) ||
                other.branchId == branchId) &&
            (identical(other.productId, productId) ||
                other.productId == productId) &&
            (identical(other.transactionType, transactionType) ||
                other.transactionType == transactionType) &&
            (identical(other.quantityDelta, quantityDelta) ||
                other.quantityDelta == quantityDelta) &&
            (identical(other.previousQuantity, previousQuantity) ||
                other.previousQuantity == previousQuantity) &&
            (identical(other.newQuantity, newQuantity) ||
                other.newQuantity == newQuantity) &&
            (identical(other.unitCost, unitCost) ||
                other.unitCost == unitCost) &&
            (identical(other.referenceId, referenceId) ||
                other.referenceId == referenceId) &&
            (identical(other.referenceType, referenceType) ||
                other.referenceType == referenceType) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.staffId, staffId) || other.staffId == staffId) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    tenantId,
    branchId,
    productId,
    transactionType,
    quantityDelta,
    previousQuantity,
    newQuantity,
    unitCost,
    referenceId,
    referenceType,
    notes,
    staffId,
    createdAt,
  );

  /// Create a copy of InventoryTransaction
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$InventoryTransactionImplCopyWith<_$InventoryTransactionImpl>
  get copyWith =>
      __$$InventoryTransactionImplCopyWithImpl<_$InventoryTransactionImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$InventoryTransactionImplToJson(this);
  }
}

abstract class _InventoryTransaction implements InventoryTransaction {
  const factory _InventoryTransaction({
    required final String id,
    @JsonKey(name: 'tenant_id') required final String tenantId,
    @JsonKey(name: 'branch_id') final String? branchId,
    @JsonKey(name: 'product_id') required final String productId,
    @JsonKey(name: 'transaction_type')
    required final TransactionType transactionType,
    @JsonKey(name: 'quantity_delta') required final int quantityDelta,
    @JsonKey(name: 'previous_quantity') required final int previousQuantity,
    @JsonKey(name: 'new_quantity') required final int newQuantity,
    @JsonKey(name: 'unit_cost') final double? unitCost,
    @JsonKey(name: 'reference_id') final String? referenceId,
    @JsonKey(name: 'reference_type') final String? referenceType,
    final String? notes,
    @JsonKey(name: 'staff_id') final String? staffId,
    @JsonKey(name: 'created_at') final DateTime? createdAt,
  }) = _$InventoryTransactionImpl;

  factory _InventoryTransaction.fromJson(Map<String, dynamic> json) =
      _$InventoryTransactionImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'tenant_id')
  String get tenantId;
  @override
  @JsonKey(name: 'branch_id')
  String? get branchId;
  @override
  @JsonKey(name: 'product_id')
  String get productId;
  @override
  @JsonKey(name: 'transaction_type')
  TransactionType get transactionType;
  @override
  @JsonKey(name: 'quantity_delta')
  int get quantityDelta;
  @override
  @JsonKey(name: 'previous_quantity')
  int get previousQuantity;
  @override
  @JsonKey(name: 'new_quantity')
  int get newQuantity;
  @override
  @JsonKey(name: 'unit_cost')
  double? get unitCost;
  @override
  @JsonKey(name: 'reference_id')
  String? get referenceId;
  @override
  @JsonKey(name: 'reference_type')
  String? get referenceType;
  @override
  String? get notes;
  @override
  @JsonKey(name: 'staff_id')
  String? get staffId;
  @override
  @JsonKey(name: 'created_at')
  DateTime? get createdAt;

  /// Create a copy of InventoryTransaction
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$InventoryTransactionImplCopyWith<_$InventoryTransactionImpl>
  get copyWith => throw _privateConstructorUsedError;
}
