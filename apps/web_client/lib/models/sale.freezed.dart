// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sale.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Sale _$SaleFromJson(Map<String, dynamic> json) {
  return _Sale.fromJson(json);
}

/// @nodoc
mixin _$Sale {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'tenant_id')
  String get tenantId => throw _privateConstructorUsedError;
  @JsonKey(name: 'sale_number')
  String get saleNumber => throw _privateConstructorUsedError;
  @JsonKey(name: 'customer_id')
  String? get customerId => throw _privateConstructorUsedError;
  @JsonKey(name: 'cashier_id')
  String get cashierId => throw _privateConstructorUsedError;
  @JsonKey(name: 'total_amount')
  double get totalAmount => throw _privateConstructorUsedError;
  @JsonKey(name: 'payment_method')
  String get paymentMethod => throw _privateConstructorUsedError;
  String get status =>
      throw _privateConstructorUsedError; // completed, pending, cancelled
  @JsonKey(name: 'created_at')
  DateTime? get createdAt => throw _privateConstructorUsedError; // Note: Items not usually fetched directly in the sale row unless joined
  // But good to have in model if we construct full object
  @JsonKey(ignore: true)
  List<SaleItem> get items => throw _privateConstructorUsedError;

  /// Serializes this Sale to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Sale
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SaleCopyWith<Sale> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SaleCopyWith<$Res> {
  factory $SaleCopyWith(Sale value, $Res Function(Sale) then) =
      _$SaleCopyWithImpl<$Res, Sale>;
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'tenant_id') String tenantId,
    @JsonKey(name: 'sale_number') String saleNumber,
    @JsonKey(name: 'customer_id') String? customerId,
    @JsonKey(name: 'cashier_id') String cashierId,
    @JsonKey(name: 'total_amount') double totalAmount,
    @JsonKey(name: 'payment_method') String paymentMethod,
    String status,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(ignore: true) List<SaleItem> items,
  });
}

/// @nodoc
class _$SaleCopyWithImpl<$Res, $Val extends Sale>
    implements $SaleCopyWith<$Res> {
  _$SaleCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Sale
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? tenantId = null,
    Object? saleNumber = null,
    Object? customerId = freezed,
    Object? cashierId = null,
    Object? totalAmount = null,
    Object? paymentMethod = null,
    Object? status = null,
    Object? createdAt = freezed,
    Object? items = null,
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
            saleNumber: null == saleNumber
                ? _value.saleNumber
                : saleNumber // ignore: cast_nullable_to_non_nullable
                      as String,
            customerId: freezed == customerId
                ? _value.customerId
                : customerId // ignore: cast_nullable_to_non_nullable
                      as String?,
            cashierId: null == cashierId
                ? _value.cashierId
                : cashierId // ignore: cast_nullable_to_non_nullable
                      as String,
            totalAmount: null == totalAmount
                ? _value.totalAmount
                : totalAmount // ignore: cast_nullable_to_non_nullable
                      as double,
            paymentMethod: null == paymentMethod
                ? _value.paymentMethod
                : paymentMethod // ignore: cast_nullable_to_non_nullable
                      as String,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String,
            createdAt: freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            items: null == items
                ? _value.items
                : items // ignore: cast_nullable_to_non_nullable
                      as List<SaleItem>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SaleImplCopyWith<$Res> implements $SaleCopyWith<$Res> {
  factory _$$SaleImplCopyWith(
    _$SaleImpl value,
    $Res Function(_$SaleImpl) then,
  ) = __$$SaleImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'tenant_id') String tenantId,
    @JsonKey(name: 'sale_number') String saleNumber,
    @JsonKey(name: 'customer_id') String? customerId,
    @JsonKey(name: 'cashier_id') String cashierId,
    @JsonKey(name: 'total_amount') double totalAmount,
    @JsonKey(name: 'payment_method') String paymentMethod,
    String status,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(ignore: true) List<SaleItem> items,
  });
}

/// @nodoc
class __$$SaleImplCopyWithImpl<$Res>
    extends _$SaleCopyWithImpl<$Res, _$SaleImpl>
    implements _$$SaleImplCopyWith<$Res> {
  __$$SaleImplCopyWithImpl(_$SaleImpl _value, $Res Function(_$SaleImpl) _then)
    : super(_value, _then);

  /// Create a copy of Sale
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? tenantId = null,
    Object? saleNumber = null,
    Object? customerId = freezed,
    Object? cashierId = null,
    Object? totalAmount = null,
    Object? paymentMethod = null,
    Object? status = null,
    Object? createdAt = freezed,
    Object? items = null,
  }) {
    return _then(
      _$SaleImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        tenantId: null == tenantId
            ? _value.tenantId
            : tenantId // ignore: cast_nullable_to_non_nullable
                  as String,
        saleNumber: null == saleNumber
            ? _value.saleNumber
            : saleNumber // ignore: cast_nullable_to_non_nullable
                  as String,
        customerId: freezed == customerId
            ? _value.customerId
            : customerId // ignore: cast_nullable_to_non_nullable
                  as String?,
        cashierId: null == cashierId
            ? _value.cashierId
            : cashierId // ignore: cast_nullable_to_non_nullable
                  as String,
        totalAmount: null == totalAmount
            ? _value.totalAmount
            : totalAmount // ignore: cast_nullable_to_non_nullable
                  as double,
        paymentMethod: null == paymentMethod
            ? _value.paymentMethod
            : paymentMethod // ignore: cast_nullable_to_non_nullable
                  as String,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
        createdAt: freezed == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        items: null == items
            ? _value._items
            : items // ignore: cast_nullable_to_non_nullable
                  as List<SaleItem>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SaleImpl implements _Sale {
  const _$SaleImpl({
    required this.id,
    @JsonKey(name: 'tenant_id') required this.tenantId,
    @JsonKey(name: 'sale_number') required this.saleNumber,
    @JsonKey(name: 'customer_id') this.customerId,
    @JsonKey(name: 'cashier_id') required this.cashierId,
    @JsonKey(name: 'total_amount') required this.totalAmount,
    @JsonKey(name: 'payment_method') required this.paymentMethod,
    this.status = 'completed',
    @JsonKey(name: 'created_at') this.createdAt,
    @JsonKey(ignore: true) final List<SaleItem> items = const [],
  }) : _items = items;

  factory _$SaleImpl.fromJson(Map<String, dynamic> json) =>
      _$$SaleImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'tenant_id')
  final String tenantId;
  @override
  @JsonKey(name: 'sale_number')
  final String saleNumber;
  @override
  @JsonKey(name: 'customer_id')
  final String? customerId;
  @override
  @JsonKey(name: 'cashier_id')
  final String cashierId;
  @override
  @JsonKey(name: 'total_amount')
  final double totalAmount;
  @override
  @JsonKey(name: 'payment_method')
  final String paymentMethod;
  @override
  @JsonKey()
  final String status;
  // completed, pending, cancelled
  @override
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  // Note: Items not usually fetched directly in the sale row unless joined
  // But good to have in model if we construct full object
  final List<SaleItem> _items;
  // Note: Items not usually fetched directly in the sale row unless joined
  // But good to have in model if we construct full object
  @override
  @JsonKey(ignore: true)
  List<SaleItem> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  String toString() {
    return 'Sale(id: $id, tenantId: $tenantId, saleNumber: $saleNumber, customerId: $customerId, cashierId: $cashierId, totalAmount: $totalAmount, paymentMethod: $paymentMethod, status: $status, createdAt: $createdAt, items: $items)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SaleImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.tenantId, tenantId) ||
                other.tenantId == tenantId) &&
            (identical(other.saleNumber, saleNumber) ||
                other.saleNumber == saleNumber) &&
            (identical(other.customerId, customerId) ||
                other.customerId == customerId) &&
            (identical(other.cashierId, cashierId) ||
                other.cashierId == cashierId) &&
            (identical(other.totalAmount, totalAmount) ||
                other.totalAmount == totalAmount) &&
            (identical(other.paymentMethod, paymentMethod) ||
                other.paymentMethod == paymentMethod) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            const DeepCollectionEquality().equals(other._items, _items));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    tenantId,
    saleNumber,
    customerId,
    cashierId,
    totalAmount,
    paymentMethod,
    status,
    createdAt,
    const DeepCollectionEquality().hash(_items),
  );

  /// Create a copy of Sale
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SaleImplCopyWith<_$SaleImpl> get copyWith =>
      __$$SaleImplCopyWithImpl<_$SaleImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SaleImplToJson(this);
  }
}

abstract class _Sale implements Sale {
  const factory _Sale({
    required final String id,
    @JsonKey(name: 'tenant_id') required final String tenantId,
    @JsonKey(name: 'sale_number') required final String saleNumber,
    @JsonKey(name: 'customer_id') final String? customerId,
    @JsonKey(name: 'cashier_id') required final String cashierId,
    @JsonKey(name: 'total_amount') required final double totalAmount,
    @JsonKey(name: 'payment_method') required final String paymentMethod,
    final String status,
    @JsonKey(name: 'created_at') final DateTime? createdAt,
    @JsonKey(ignore: true) final List<SaleItem> items,
  }) = _$SaleImpl;

  factory _Sale.fromJson(Map<String, dynamic> json) = _$SaleImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'tenant_id')
  String get tenantId;
  @override
  @JsonKey(name: 'sale_number')
  String get saleNumber;
  @override
  @JsonKey(name: 'customer_id')
  String? get customerId;
  @override
  @JsonKey(name: 'cashier_id')
  String get cashierId;
  @override
  @JsonKey(name: 'total_amount')
  double get totalAmount;
  @override
  @JsonKey(name: 'payment_method')
  String get paymentMethod;
  @override
  String get status; // completed, pending, cancelled
  @override
  @JsonKey(name: 'created_at')
  DateTime? get createdAt; // Note: Items not usually fetched directly in the sale row unless joined
  // But good to have in model if we construct full object
  @override
  @JsonKey(ignore: true)
  List<SaleItem> get items;

  /// Create a copy of Sale
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SaleImplCopyWith<_$SaleImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SaleItem _$SaleItemFromJson(Map<String, dynamic> json) {
  return _SaleItem.fromJson(json);
}

/// @nodoc
mixin _$SaleItem {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'sale_id')
  String get saleId => throw _privateConstructorUsedError;
  @JsonKey(name: 'product_id')
  String get productId => throw _privateConstructorUsedError;
  @JsonKey(name: 'product_name')
  String? get productName => throw _privateConstructorUsedError; // Useful when fetched with join
  int get quantity => throw _privateConstructorUsedError;
  @JsonKey(name: 'unit_price')
  double get unitPrice => throw _privateConstructorUsedError;
  @JsonKey(name: 'total_price')
  double get totalPrice => throw _privateConstructorUsedError;
  @JsonKey(name: 'tenant_id')
  String get tenantId => throw _privateConstructorUsedError;

  /// Serializes this SaleItem to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SaleItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SaleItemCopyWith<SaleItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SaleItemCopyWith<$Res> {
  factory $SaleItemCopyWith(SaleItem value, $Res Function(SaleItem) then) =
      _$SaleItemCopyWithImpl<$Res, SaleItem>;
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'sale_id') String saleId,
    @JsonKey(name: 'product_id') String productId,
    @JsonKey(name: 'product_name') String? productName,
    int quantity,
    @JsonKey(name: 'unit_price') double unitPrice,
    @JsonKey(name: 'total_price') double totalPrice,
    @JsonKey(name: 'tenant_id') String tenantId,
  });
}

/// @nodoc
class _$SaleItemCopyWithImpl<$Res, $Val extends SaleItem>
    implements $SaleItemCopyWith<$Res> {
  _$SaleItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SaleItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? saleId = null,
    Object? productId = null,
    Object? productName = freezed,
    Object? quantity = null,
    Object? unitPrice = null,
    Object? totalPrice = null,
    Object? tenantId = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            saleId: null == saleId
                ? _value.saleId
                : saleId // ignore: cast_nullable_to_non_nullable
                      as String,
            productId: null == productId
                ? _value.productId
                : productId // ignore: cast_nullable_to_non_nullable
                      as String,
            productName: freezed == productName
                ? _value.productName
                : productName // ignore: cast_nullable_to_non_nullable
                      as String?,
            quantity: null == quantity
                ? _value.quantity
                : quantity // ignore: cast_nullable_to_non_nullable
                      as int,
            unitPrice: null == unitPrice
                ? _value.unitPrice
                : unitPrice // ignore: cast_nullable_to_non_nullable
                      as double,
            totalPrice: null == totalPrice
                ? _value.totalPrice
                : totalPrice // ignore: cast_nullable_to_non_nullable
                      as double,
            tenantId: null == tenantId
                ? _value.tenantId
                : tenantId // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SaleItemImplCopyWith<$Res>
    implements $SaleItemCopyWith<$Res> {
  factory _$$SaleItemImplCopyWith(
    _$SaleItemImpl value,
    $Res Function(_$SaleItemImpl) then,
  ) = __$$SaleItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'sale_id') String saleId,
    @JsonKey(name: 'product_id') String productId,
    @JsonKey(name: 'product_name') String? productName,
    int quantity,
    @JsonKey(name: 'unit_price') double unitPrice,
    @JsonKey(name: 'total_price') double totalPrice,
    @JsonKey(name: 'tenant_id') String tenantId,
  });
}

/// @nodoc
class __$$SaleItemImplCopyWithImpl<$Res>
    extends _$SaleItemCopyWithImpl<$Res, _$SaleItemImpl>
    implements _$$SaleItemImplCopyWith<$Res> {
  __$$SaleItemImplCopyWithImpl(
    _$SaleItemImpl _value,
    $Res Function(_$SaleItemImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SaleItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? saleId = null,
    Object? productId = null,
    Object? productName = freezed,
    Object? quantity = null,
    Object? unitPrice = null,
    Object? totalPrice = null,
    Object? tenantId = null,
  }) {
    return _then(
      _$SaleItemImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        saleId: null == saleId
            ? _value.saleId
            : saleId // ignore: cast_nullable_to_non_nullable
                  as String,
        productId: null == productId
            ? _value.productId
            : productId // ignore: cast_nullable_to_non_nullable
                  as String,
        productName: freezed == productName
            ? _value.productName
            : productName // ignore: cast_nullable_to_non_nullable
                  as String?,
        quantity: null == quantity
            ? _value.quantity
            : quantity // ignore: cast_nullable_to_non_nullable
                  as int,
        unitPrice: null == unitPrice
            ? _value.unitPrice
            : unitPrice // ignore: cast_nullable_to_non_nullable
                  as double,
        totalPrice: null == totalPrice
            ? _value.totalPrice
            : totalPrice // ignore: cast_nullable_to_non_nullable
                  as double,
        tenantId: null == tenantId
            ? _value.tenantId
            : tenantId // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SaleItemImpl implements _SaleItem {
  const _$SaleItemImpl({
    required this.id,
    @JsonKey(name: 'sale_id') required this.saleId,
    @JsonKey(name: 'product_id') required this.productId,
    @JsonKey(name: 'product_name') this.productName,
    required this.quantity,
    @JsonKey(name: 'unit_price') required this.unitPrice,
    @JsonKey(name: 'total_price') required this.totalPrice,
    @JsonKey(name: 'tenant_id') required this.tenantId,
  });

  factory _$SaleItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$SaleItemImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'sale_id')
  final String saleId;
  @override
  @JsonKey(name: 'product_id')
  final String productId;
  @override
  @JsonKey(name: 'product_name')
  final String? productName;
  // Useful when fetched with join
  @override
  final int quantity;
  @override
  @JsonKey(name: 'unit_price')
  final double unitPrice;
  @override
  @JsonKey(name: 'total_price')
  final double totalPrice;
  @override
  @JsonKey(name: 'tenant_id')
  final String tenantId;

  @override
  String toString() {
    return 'SaleItem(id: $id, saleId: $saleId, productId: $productId, productName: $productName, quantity: $quantity, unitPrice: $unitPrice, totalPrice: $totalPrice, tenantId: $tenantId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SaleItemImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.saleId, saleId) || other.saleId == saleId) &&
            (identical(other.productId, productId) ||
                other.productId == productId) &&
            (identical(other.productName, productName) ||
                other.productName == productName) &&
            (identical(other.quantity, quantity) ||
                other.quantity == quantity) &&
            (identical(other.unitPrice, unitPrice) ||
                other.unitPrice == unitPrice) &&
            (identical(other.totalPrice, totalPrice) ||
                other.totalPrice == totalPrice) &&
            (identical(other.tenantId, tenantId) ||
                other.tenantId == tenantId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    saleId,
    productId,
    productName,
    quantity,
    unitPrice,
    totalPrice,
    tenantId,
  );

  /// Create a copy of SaleItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SaleItemImplCopyWith<_$SaleItemImpl> get copyWith =>
      __$$SaleItemImplCopyWithImpl<_$SaleItemImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SaleItemImplToJson(this);
  }
}

abstract class _SaleItem implements SaleItem {
  const factory _SaleItem({
    required final String id,
    @JsonKey(name: 'sale_id') required final String saleId,
    @JsonKey(name: 'product_id') required final String productId,
    @JsonKey(name: 'product_name') final String? productName,
    required final int quantity,
    @JsonKey(name: 'unit_price') required final double unitPrice,
    @JsonKey(name: 'total_price') required final double totalPrice,
    @JsonKey(name: 'tenant_id') required final String tenantId,
  }) = _$SaleItemImpl;

  factory _SaleItem.fromJson(Map<String, dynamic> json) =
      _$SaleItemImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'sale_id')
  String get saleId;
  @override
  @JsonKey(name: 'product_id')
  String get productId;
  @override
  @JsonKey(name: 'product_name')
  String? get productName; // Useful when fetched with join
  @override
  int get quantity;
  @override
  @JsonKey(name: 'unit_price')
  double get unitPrice;
  @override
  @JsonKey(name: 'total_price')
  double get totalPrice;
  @override
  @JsonKey(name: 'tenant_id')
  String get tenantId;

  /// Create a copy of SaleItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SaleItemImplCopyWith<_$SaleItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
