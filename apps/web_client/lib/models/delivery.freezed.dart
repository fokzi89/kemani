// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'delivery.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Delivery _$DeliveryFromJson(Map<String, dynamic> json) {
  return _Delivery.fromJson(json);
}

/// @nodoc
mixin _$Delivery {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'tenant_id')
  String get tenantId => throw _privateConstructorUsedError;
  @JsonKey(name: 'order_id')
  String get orderId => throw _privateConstructorUsedError;
  @JsonKey(name: 'driver_name')
  String? get driverName => throw _privateConstructorUsedError;
  @JsonKey(name: 'driver_phone')
  String? get driverPhone => throw _privateConstructorUsedError;
  @JsonKey(name: 'delivery_status')
  DeliveryStatus get status => throw _privateConstructorUsedError;
  @JsonKey(name: 'delivery_address')
  String get address => throw _privateConstructorUsedError;
  @JsonKey(name: 'delivery_fee')
  double get fee => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;
  @JsonKey(name: 'estimated_delivery_time')
  DateTime? get estimatedDeliveryTime => throw _privateConstructorUsedError;
  @JsonKey(name: 'actual_delivery_time')
  DateTime? get actualDeliveryTime => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime? get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this Delivery to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Delivery
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DeliveryCopyWith<Delivery> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DeliveryCopyWith<$Res> {
  factory $DeliveryCopyWith(Delivery value, $Res Function(Delivery) then) =
      _$DeliveryCopyWithImpl<$Res, Delivery>;
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'tenant_id') String tenantId,
    @JsonKey(name: 'order_id') String orderId,
    @JsonKey(name: 'driver_name') String? driverName,
    @JsonKey(name: 'driver_phone') String? driverPhone,
    @JsonKey(name: 'delivery_status') DeliveryStatus status,
    @JsonKey(name: 'delivery_address') String address,
    @JsonKey(name: 'delivery_fee') double fee,
    String? notes,
    @JsonKey(name: 'estimated_delivery_time') DateTime? estimatedDeliveryTime,
    @JsonKey(name: 'actual_delivery_time') DateTime? actualDeliveryTime,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  });
}

/// @nodoc
class _$DeliveryCopyWithImpl<$Res, $Val extends Delivery>
    implements $DeliveryCopyWith<$Res> {
  _$DeliveryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Delivery
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? tenantId = null,
    Object? orderId = null,
    Object? driverName = freezed,
    Object? driverPhone = freezed,
    Object? status = null,
    Object? address = null,
    Object? fee = null,
    Object? notes = freezed,
    Object? estimatedDeliveryTime = freezed,
    Object? actualDeliveryTime = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
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
            orderId: null == orderId
                ? _value.orderId
                : orderId // ignore: cast_nullable_to_non_nullable
                      as String,
            driverName: freezed == driverName
                ? _value.driverName
                : driverName // ignore: cast_nullable_to_non_nullable
                      as String?,
            driverPhone: freezed == driverPhone
                ? _value.driverPhone
                : driverPhone // ignore: cast_nullable_to_non_nullable
                      as String?,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as DeliveryStatus,
            address: null == address
                ? _value.address
                : address // ignore: cast_nullable_to_non_nullable
                      as String,
            fee: null == fee
                ? _value.fee
                : fee // ignore: cast_nullable_to_non_nullable
                      as double,
            notes: freezed == notes
                ? _value.notes
                : notes // ignore: cast_nullable_to_non_nullable
                      as String?,
            estimatedDeliveryTime: freezed == estimatedDeliveryTime
                ? _value.estimatedDeliveryTime
                : estimatedDeliveryTime // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            actualDeliveryTime: freezed == actualDeliveryTime
                ? _value.actualDeliveryTime
                : actualDeliveryTime // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            createdAt: freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            updatedAt: freezed == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$DeliveryImplCopyWith<$Res>
    implements $DeliveryCopyWith<$Res> {
  factory _$$DeliveryImplCopyWith(
    _$DeliveryImpl value,
    $Res Function(_$DeliveryImpl) then,
  ) = __$$DeliveryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'tenant_id') String tenantId,
    @JsonKey(name: 'order_id') String orderId,
    @JsonKey(name: 'driver_name') String? driverName,
    @JsonKey(name: 'driver_phone') String? driverPhone,
    @JsonKey(name: 'delivery_status') DeliveryStatus status,
    @JsonKey(name: 'delivery_address') String address,
    @JsonKey(name: 'delivery_fee') double fee,
    String? notes,
    @JsonKey(name: 'estimated_delivery_time') DateTime? estimatedDeliveryTime,
    @JsonKey(name: 'actual_delivery_time') DateTime? actualDeliveryTime,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  });
}

/// @nodoc
class __$$DeliveryImplCopyWithImpl<$Res>
    extends _$DeliveryCopyWithImpl<$Res, _$DeliveryImpl>
    implements _$$DeliveryImplCopyWith<$Res> {
  __$$DeliveryImplCopyWithImpl(
    _$DeliveryImpl _value,
    $Res Function(_$DeliveryImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Delivery
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? tenantId = null,
    Object? orderId = null,
    Object? driverName = freezed,
    Object? driverPhone = freezed,
    Object? status = null,
    Object? address = null,
    Object? fee = null,
    Object? notes = freezed,
    Object? estimatedDeliveryTime = freezed,
    Object? actualDeliveryTime = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _$DeliveryImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        tenantId: null == tenantId
            ? _value.tenantId
            : tenantId // ignore: cast_nullable_to_non_nullable
                  as String,
        orderId: null == orderId
            ? _value.orderId
            : orderId // ignore: cast_nullable_to_non_nullable
                  as String,
        driverName: freezed == driverName
            ? _value.driverName
            : driverName // ignore: cast_nullable_to_non_nullable
                  as String?,
        driverPhone: freezed == driverPhone
            ? _value.driverPhone
            : driverPhone // ignore: cast_nullable_to_non_nullable
                  as String?,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as DeliveryStatus,
        address: null == address
            ? _value.address
            : address // ignore: cast_nullable_to_non_nullable
                  as String,
        fee: null == fee
            ? _value.fee
            : fee // ignore: cast_nullable_to_non_nullable
                  as double,
        notes: freezed == notes
            ? _value.notes
            : notes // ignore: cast_nullable_to_non_nullable
                  as String?,
        estimatedDeliveryTime: freezed == estimatedDeliveryTime
            ? _value.estimatedDeliveryTime
            : estimatedDeliveryTime // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        actualDeliveryTime: freezed == actualDeliveryTime
            ? _value.actualDeliveryTime
            : actualDeliveryTime // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        createdAt: freezed == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        updatedAt: freezed == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$DeliveryImpl implements _Delivery {
  const _$DeliveryImpl({
    required this.id,
    @JsonKey(name: 'tenant_id') required this.tenantId,
    @JsonKey(name: 'order_id') required this.orderId,
    @JsonKey(name: 'driver_name') this.driverName,
    @JsonKey(name: 'driver_phone') this.driverPhone,
    @JsonKey(name: 'delivery_status') this.status = DeliveryStatus.pending,
    @JsonKey(name: 'delivery_address') required this.address,
    @JsonKey(name: 'delivery_fee') this.fee = 0.0,
    this.notes,
    @JsonKey(name: 'estimated_delivery_time') this.estimatedDeliveryTime,
    @JsonKey(name: 'actual_delivery_time') this.actualDeliveryTime,
    @JsonKey(name: 'created_at') this.createdAt,
    @JsonKey(name: 'updated_at') this.updatedAt,
  });

  factory _$DeliveryImpl.fromJson(Map<String, dynamic> json) =>
      _$$DeliveryImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'tenant_id')
  final String tenantId;
  @override
  @JsonKey(name: 'order_id')
  final String orderId;
  @override
  @JsonKey(name: 'driver_name')
  final String? driverName;
  @override
  @JsonKey(name: 'driver_phone')
  final String? driverPhone;
  @override
  @JsonKey(name: 'delivery_status')
  final DeliveryStatus status;
  @override
  @JsonKey(name: 'delivery_address')
  final String address;
  @override
  @JsonKey(name: 'delivery_fee')
  final double fee;
  @override
  final String? notes;
  @override
  @JsonKey(name: 'estimated_delivery_time')
  final DateTime? estimatedDeliveryTime;
  @override
  @JsonKey(name: 'actual_delivery_time')
  final DateTime? actualDeliveryTime;
  @override
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @override
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'Delivery(id: $id, tenantId: $tenantId, orderId: $orderId, driverName: $driverName, driverPhone: $driverPhone, status: $status, address: $address, fee: $fee, notes: $notes, estimatedDeliveryTime: $estimatedDeliveryTime, actualDeliveryTime: $actualDeliveryTime, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DeliveryImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.tenantId, tenantId) ||
                other.tenantId == tenantId) &&
            (identical(other.orderId, orderId) || other.orderId == orderId) &&
            (identical(other.driverName, driverName) ||
                other.driverName == driverName) &&
            (identical(other.driverPhone, driverPhone) ||
                other.driverPhone == driverPhone) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.address, address) || other.address == address) &&
            (identical(other.fee, fee) || other.fee == fee) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.estimatedDeliveryTime, estimatedDeliveryTime) ||
                other.estimatedDeliveryTime == estimatedDeliveryTime) &&
            (identical(other.actualDeliveryTime, actualDeliveryTime) ||
                other.actualDeliveryTime == actualDeliveryTime) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    tenantId,
    orderId,
    driverName,
    driverPhone,
    status,
    address,
    fee,
    notes,
    estimatedDeliveryTime,
    actualDeliveryTime,
    createdAt,
    updatedAt,
  );

  /// Create a copy of Delivery
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DeliveryImplCopyWith<_$DeliveryImpl> get copyWith =>
      __$$DeliveryImplCopyWithImpl<_$DeliveryImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DeliveryImplToJson(this);
  }
}

abstract class _Delivery implements Delivery {
  const factory _Delivery({
    required final String id,
    @JsonKey(name: 'tenant_id') required final String tenantId,
    @JsonKey(name: 'order_id') required final String orderId,
    @JsonKey(name: 'driver_name') final String? driverName,
    @JsonKey(name: 'driver_phone') final String? driverPhone,
    @JsonKey(name: 'delivery_status') final DeliveryStatus status,
    @JsonKey(name: 'delivery_address') required final String address,
    @JsonKey(name: 'delivery_fee') final double fee,
    final String? notes,
    @JsonKey(name: 'estimated_delivery_time')
    final DateTime? estimatedDeliveryTime,
    @JsonKey(name: 'actual_delivery_time') final DateTime? actualDeliveryTime,
    @JsonKey(name: 'created_at') final DateTime? createdAt,
    @JsonKey(name: 'updated_at') final DateTime? updatedAt,
  }) = _$DeliveryImpl;

  factory _Delivery.fromJson(Map<String, dynamic> json) =
      _$DeliveryImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'tenant_id')
  String get tenantId;
  @override
  @JsonKey(name: 'order_id')
  String get orderId;
  @override
  @JsonKey(name: 'driver_name')
  String? get driverName;
  @override
  @JsonKey(name: 'driver_phone')
  String? get driverPhone;
  @override
  @JsonKey(name: 'delivery_status')
  DeliveryStatus get status;
  @override
  @JsonKey(name: 'delivery_address')
  String get address;
  @override
  @JsonKey(name: 'delivery_fee')
  double get fee;
  @override
  String? get notes;
  @override
  @JsonKey(name: 'estimated_delivery_time')
  DateTime? get estimatedDeliveryTime;
  @override
  @JsonKey(name: 'actual_delivery_time')
  DateTime? get actualDeliveryTime;
  @override
  @JsonKey(name: 'created_at')
  DateTime? get createdAt;
  @override
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt;

  /// Create a copy of Delivery
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DeliveryImplCopyWith<_$DeliveryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
