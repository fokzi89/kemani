class CustomerAddress {
  final String id;
  final String customerId;
  final String? label;
  final String addressLine;
  final double? latitude;
  final double? longitude;
  final bool isDefault;

  CustomerAddress({
    required this.id,
    required this.customerId,
    this.label,
    required this.addressLine,
    this.latitude,
    this.longitude,
    this.isDefault = false,
  });

  factory CustomerAddress.fromJson(Map<String, dynamic> json) {
    return CustomerAddress(
      id: json['id'] as String,
      customerId: json['customer_id'] as String,
      label: json['label'] as String?,
      addressLine: json['address_line'] as String,
      latitude: json['latitude'] != null
          ? (json['latitude'] as num).toDouble()
          : null,
      longitude: json['longitude'] != null
          ? (json['longitude'] as num).toDouble()
          : null,
      isDefault: json['is_default'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'label': label,
      'address_line': addressLine,
      'latitude': latitude,
      'longitude': longitude,
      'is_default': isDefault,
    };
  }

  CustomerAddress copyWith({
    String? id,
    String? customerId,
    String? label,
    String? addressLine,
    double? latitude,
    double? longitude,
    bool? isDefault,
  }) {
    return CustomerAddress(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      label: label ?? this.label,
      addressLine: addressLine ?? this.addressLine,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}
