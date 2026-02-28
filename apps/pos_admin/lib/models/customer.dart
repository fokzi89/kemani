class Customer {
  final String id;
  final String tenantId;
  final String phone;
  final String? email;
  final String fullName;
  final String? whatsappNumber;
  final int loyaltyPoints;
  final double totalPurchases;
  final int purchaseCount;
  final DateTime? lastPurchaseAt;
  final String loyaltyTier;
  final DateTime createdAt;
  final DateTime updatedAt;

  Customer({
    required this.id,
    required this.tenantId,
    required this.phone,
    this.email,
    required this.fullName,
    this.whatsappNumber,
    this.loyaltyPoints = 0,
    this.totalPurchases = 0.0,
    this.purchaseCount = 0,
    this.lastPurchaseAt,
    this.loyaltyTier = 'bronze',
    required this.createdAt,
    required this.updatedAt,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String?,
      fullName: json['full_name'] as String,
      whatsappNumber: json['whatsapp_number'] as String?,
      loyaltyPoints: json['loyalty_points'] as int? ?? 0,
      totalPurchases: json['total_purchases'] != null
          ? (json['total_purchases'] as num).toDouble()
          : 0.0,
      purchaseCount: json['purchase_count'] as int? ?? 0,
      lastPurchaseAt: json['last_purchase_at'] != null
          ? DateTime.parse(json['last_purchase_at'] as String)
          : null,
      loyaltyTier: json['loyalty_tier'] as String? ?? 'bronze',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'phone': phone,
      'email': email,
      'full_name': fullName,
      'whatsapp_number': whatsappNumber,
      'loyalty_points': loyaltyPoints,
      'total_purchases': totalPurchases,
      'purchase_count': purchaseCount,
      'last_purchase_at': lastPurchaseAt?.toIso8601String(),
      'loyalty_tier': loyaltyTier,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Customer copyWith({
    String? id,
    String? tenantId,
    String? phone,
    String? email,
    String? fullName,
    String? whatsappNumber,
    int? loyaltyPoints,
    double? totalPurchases,
    int? purchaseCount,
    DateTime? lastPurchaseAt,
    String? loyaltyTier,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Customer(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      whatsappNumber: whatsappNumber ?? this.whatsappNumber,
      loyaltyPoints: loyaltyPoints ?? this.loyaltyPoints,
      totalPurchases: totalPurchases ?? this.totalPurchases,
      purchaseCount: purchaseCount ?? this.purchaseCount,
      lastPurchaseAt: lastPurchaseAt ?? this.lastPurchaseAt,
      loyaltyTier: loyaltyTier ?? this.loyaltyTier,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
