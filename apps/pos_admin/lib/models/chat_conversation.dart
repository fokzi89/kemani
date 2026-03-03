class ChatConversation {
  final String id;
  final String tenantId;
  final String branchId;
  final String? customerId;
  final String? customerName;
  final String? customerEmail;
  final String? orderId;
  final String status; // 'active', 'completed', 'escalated', 'abandoned'
  final String? escalatedToUserId;
  final String? escalatedToUserName;
  final DateTime startedAt;
  final DateTime? endedAt;
  final String? lastMessageText;
  final DateTime? lastMessageAt;
  final int unreadCount;

  ChatConversation({
    required this.id,
    required this.tenantId,
    required this.branchId,
    this.customerId,
    this.customerName,
    this.customerEmail,
    this.orderId,
    required this.status,
    this.escalatedToUserId,
    this.escalatedToUserName,
    required this.startedAt,
    this.endedAt,
    this.lastMessageText,
    this.lastMessageAt,
    this.unreadCount = 0,
  });

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    return ChatConversation(
      id: json['id'],
      tenantId: json['tenant_id'],
      branchId: json['branch_id'],
      customerId: json['customer_id'],
      customerName: json['customer_name'],
      customerEmail: json['customer_email'],
      orderId: json['order_id'],
      status: json['status'] ?? 'active',
      escalatedToUserId: json['escalated_to_user_id'],
      escalatedToUserName: json['escalated_to_user_name'],
      startedAt: DateTime.parse(json['started_at']),
      endedAt: json['ended_at'] != null ? DateTime.parse(json['ended_at']) : null,
      lastMessageText: json['last_message_text'],
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.parse(json['last_message_at'])
          : null,
      unreadCount: json['unread_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'branch_id': branchId,
      'customer_id': customerId,
      'order_id': orderId,
      'status': status,
      'escalated_to_user_id': escalatedToUserId,
      'started_at': startedAt.toIso8601String(),
      'ended_at': endedAt?.toIso8601String(),
    };
  }
}
