import 'dart:convert';

/// Entry in the sync queue for offline operations
class SyncQueueEntry {
  final int? id;
  final String operationType; // 'sale_create', 'inventory_update', etc.
  final String entityType; // 'sale', 'inventory', etc.
  final String entityId;
  final Map<String, dynamic> payload;
  final int priority;
  final String status; // 'pending', 'processing', 'completed', 'failed'
  final int retryCount;
  final int maxRetries;
  final String? errorMessage;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? processedAt;

  SyncQueueEntry({
    this.id,
    required this.operationType,
    required this.entityType,
    required this.entityId,
    required this.payload,
    this.priority = 0,
    this.status = 'pending',
    this.retryCount = 0,
    this.maxRetries = 3,
    this.errorMessage,
    required this.createdAt,
    required this.updatedAt,
    this.processedAt,
  });

  factory SyncQueueEntry.create({
    required String operationType,
    required String entityType,
    required String entityId,
    required Map<String, dynamic> payload,
    int priority = 0,
    int maxRetries = 3,
  }) {
    final now = DateTime.now();
    return SyncQueueEntry(
      operationType: operationType,
      entityType: entityType,
      entityId: entityId,
      payload: payload,
      priority: priority,
      status: 'pending',
      retryCount: 0,
      maxRetries: maxRetries,
      createdAt: now,
      updatedAt: now,
    );
  }

  factory SyncQueueEntry.fromJson(Map<String, dynamic> json) {
    return SyncQueueEntry(
      id: json['id'] as int?,
      operationType: json['operation_type'] as String,
      entityType: json['entity_type'] as String,
      entityId: json['entity_id'] as String,
      payload: jsonDecode(json['payload'] as String) as Map<String, dynamic>,
      priority: json['priority'] as int? ?? 0,
      status: json['status'] as String? ?? 'pending',
      retryCount: json['retry_count'] as int? ?? 0,
      maxRetries: json['max_retries'] as int? ?? 3,
      errorMessage: json['error_message'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      processedAt: json['processed_at'] != null
          ? DateTime.parse(json['processed_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'operation_type': operationType,
      'entity_type': entityType,
      'entity_id': entityId,
      'payload': jsonEncode(payload),
      'priority': priority,
      'status': status,
      'retry_count': retryCount,
      'max_retries': maxRetries,
      'error_message': errorMessage,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'processed_at': processedAt?.toIso8601String(),
    };
  }

  SyncQueueEntry copyWith({
    int? id,
    String? operationType,
    String? entityType,
    String? entityId,
    Map<String, dynamic>? payload,
    int? priority,
    String? status,
    int? retryCount,
    int? maxRetries,
    String? errorMessage,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? processedAt,
  }) {
    return SyncQueueEntry(
      id: id ?? this.id,
      operationType: operationType ?? this.operationType,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      payload: payload ?? this.payload,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      retryCount: retryCount ?? this.retryCount,
      maxRetries: maxRetries ?? this.maxRetries,
      errorMessage: errorMessage ?? this.errorMessage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      processedAt: processedAt ?? this.processedAt,
    );
  }

  /// Check if entry has exceeded max retries
  bool get hasExceededMaxRetries => retryCount >= maxRetries;

  /// Check if entry can be retried
  bool get canRetry => !hasExceededMaxRetries && status == 'failed';

  /// Check if entry is pending
  bool get isPending => status == 'pending';

  /// Check if entry is processing
  bool get isProcessing => status == 'processing';

  /// Check if entry is completed
  bool get isCompleted => status == 'completed';

  /// Check if entry has failed
  bool get hasFailed => status == 'failed';
}
