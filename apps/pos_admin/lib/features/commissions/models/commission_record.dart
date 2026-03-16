// Multi-Tenant Referral Commission System - Flutter Models
// Feature: 004-tenant-referral-commissions
// Hive-compatible models for offline storage

import 'package:hive/hive.dart';

part 'commission_record.g.dart';

/// Commission status enum
enum CommissionStatus {
  pending,
  processed,
  paidOut,
}

/// Transaction type enum
enum TransactionType {
  consultation,
  productSale,
  diagnosticTest,
}

/// Commission Record
/// Represents a single commission transaction with Hive storage support
@HiveType(typeId: 10)
class CommissionRecord extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String transactionId;

  @HiveField(2)
  String transactionType; // 'consultation', 'product_sale', 'diagnostic_test'

  @HiveField(3)
  String providerTenantId;

  @HiveField(4)
  String? referrerTenantId; // Nullable if no referrer

  @HiveField(5)
  String customerId;

  @HiveField(6)
  double baseAmount;

  @HiveField(7)
  double customerPaid;

  @HiveField(8)
  double providerAmount;

  @HiveField(9)
  double? referrerAmount; // Nullable if no referrer

  @HiveField(10)
  double platformAmount;

  @HiveField(11)
  String status; // 'pending', 'processed', 'paid_out'

  @HiveField(12)
  DateTime createdAt;

  @HiveField(13)
  DateTime? processedAt;

  @HiveField(14)
  DateTime? paidAt;

  @HiveField(15)
  Map<String, dynamic>? calculationMetadata;

  CommissionRecord({
    required this.id,
    required this.transactionId,
    required this.transactionType,
    required this.providerTenantId,
    this.referrerTenantId,
    required this.customerId,
    required this.baseAmount,
    required this.customerPaid,
    required this.providerAmount,
    this.referrerAmount,
    required this.platformAmount,
    required this.status,
    required this.createdAt,
    this.processedAt,
    this.paidAt,
    this.calculationMetadata,
  });

  /// Create from JSON (Supabase response)
  factory CommissionRecord.fromJson(Map<String, dynamic> json) {
    return CommissionRecord(
      id: json['id'] as String,
      transactionId: json['transaction_id'] as String,
      transactionType: json['transaction_type'] as String,
      providerTenantId: json['provider_tenant_id'] as String,
      referrerTenantId: json['referrer_tenant_id'] as String?,
      customerId: json['customer_id'] as String,
      baseAmount: (json['base_amount'] as num).toDouble(),
      customerPaid: (json['customer_paid'] as num).toDouble(),
      providerAmount: (json['provider_amount'] as num).toDouble(),
      referrerAmount: json['referrer_amount'] != null
          ? (json['referrer_amount'] as num).toDouble()
          : null,
      platformAmount: (json['platform_amount'] as num).toDouble(),
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      processedAt: json['processed_at'] != null
          ? DateTime.parse(json['processed_at'] as String)
          : null,
      paidAt: json['paid_at'] != null
          ? DateTime.parse(json['paid_at'] as String)
          : null,
      calculationMetadata:
          json['calculation_metadata'] as Map<String, dynamic>?,
    );
  }

  /// Convert to JSON (for Supabase)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'transaction_id': transactionId,
      'transaction_type': transactionType,
      'provider_tenant_id': providerTenantId,
      'referrer_tenant_id': referrerTenantId,
      'customer_id': customerId,
      'base_amount': baseAmount,
      'customer_paid': customerPaid,
      'provider_amount': providerAmount,
      'referrer_amount': referrerAmount,
      'platform_amount': platformAmount,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'processed_at': processedAt?.toIso8601String(),
      'paid_at': paidAt?.toIso8601String(),
      'calculation_metadata': calculationMetadata,
    };
  }

  /// Get commission status enum
  CommissionStatus get statusEnum {
    switch (status) {
      case 'pending':
        return CommissionStatus.pending;
      case 'processed':
        return CommissionStatus.processed;
      case 'paid_out':
        return CommissionStatus.paidOut;
      default:
        return CommissionStatus.pending;
    }
  }

  /// Get transaction type enum
  TransactionType get transactionTypeEnum {
    switch (transactionType) {
      case 'consultation':
        return TransactionType.consultation;
      case 'product_sale':
        return TransactionType.productSale;
      case 'diagnostic_test':
        return TransactionType.diagnosticTest;
      default:
        return TransactionType.consultation;
    }
  }

  /// Check if commission is paid out
  bool get isPaidOut => status == 'paid_out';

  /// Check if commission is pending
  bool get isPending => status == 'pending';

  /// Check if commission is processed
  bool get isProcessed => status == 'processed';

  /// Check if this tenant is the referrer (earning commission)
  bool isReferrerFor(String tenantId) => referrerTenantId == tenantId;

  /// Check if this tenant is the provider (paying commission)
  bool isProviderFor(String tenantId) => providerTenantId == tenantId;
}

/// Referral Statistics
/// Aggregated stats for commission dashboard
@HiveType(typeId: 11)
class ReferralStats extends HiveObject {
  @HiveField(0)
  double totalEarned;

  @HiveField(1)
  double totalPending;

  @HiveField(2)
  double totalProcessed;

  @HiveField(3)
  double totalPaidOut;

  @HiveField(4)
  int transactionCount;

  @HiveField(5)
  double avgCommission;

  @HiveField(6)
  DateTime lastUpdated;

  ReferralStats({
    required this.totalEarned,
    required this.totalPending,
    required this.totalProcessed,
    required this.totalPaidOut,
    required this.transactionCount,
    required this.avgCommission,
    required this.lastUpdated,
  });

  /// Create from JSON (API summary response)
  factory ReferralStats.fromJson(Map<String, dynamic> json) {
    return ReferralStats(
      totalEarned: (json['total_earned'] as num).toDouble(),
      totalPending: (json['total_pending'] as num).toDouble(),
      totalProcessed: (json['total_processed'] as num).toDouble(),
      totalPaidOut: (json['total_paid_out'] as num).toDouble(),
      transactionCount: json['transaction_count'] as int,
      avgCommission: (json['avg_commission'] as num).toDouble(),
      lastUpdated: DateTime.now(),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'total_earned': totalEarned,
      'total_pending': totalPending,
      'total_processed': totalProcessed,
      'total_paid_out': totalPaidOut,
      'transaction_count': transactionCount,
      'avg_commission': avgCommission,
      'last_updated': lastUpdated.toIso8601String(),
    };
  }
}
