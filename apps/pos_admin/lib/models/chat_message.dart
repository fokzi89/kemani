class ChatMessage {
  final String id;
  final String conversationId;
  final String senderType; // 'customer', 'ai_agent', 'staff'
  final String? senderId;
  final String? senderName;
  final String messageType; // 'text', 'image', 'audio', 'video', 'location', 'product_card', etc.
  final String? messageText;
  final String? mediaUrl;
  final int? mediaSizeBytes;
  final int? mediaDurationSeconds;
  final String? thumbnailUrl;
  final Map<String, dynamic>? metadata;
  final String? actionType;
  final Map<String, dynamic>? actionData;
  final DateTime? actionCompletedAt;
  final String? intent;
  final double? confidenceScore;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderType,
    this.senderId,
    this.senderName,
    this.messageType = 'text',
    this.messageText,
    this.mediaUrl,
    this.mediaSizeBytes,
    this.mediaDurationSeconds,
    this.thumbnailUrl,
    this.metadata,
    this.actionType,
    this.actionData,
    this.actionCompletedAt,
    this.intent,
    this.confidenceScore,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      conversationId: json['conversation_id'],
      senderType: json['sender_type'],
      senderId: json['sender_id'],
      senderName: json['sender_name'],
      messageType: json['message_type'] ?? 'text',
      messageText: json['message_text'],
      mediaUrl: json['media_url'],
      mediaSizeBytes: json['media_size_bytes'],
      mediaDurationSeconds: json['media_duration_seconds'],
      thumbnailUrl: json['thumbnail_url'],
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'])
          : null,
      actionType: json['action_type'],
      actionData: json['action_data'] != null
          ? Map<String, dynamic>.from(json['action_data'])
          : null,
      actionCompletedAt: json['action_completed_at'] != null
          ? DateTime.parse(json['action_completed_at'])
          : null,
      intent: json['intent'],
      confidenceScore: json['confidence_score'] != null
          ? (json['confidence_score'] as num).toDouble()
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'sender_type': senderType,
      'sender_id': senderId,
      'message_type': messageType,
      'message_text': messageText,
      'media_url': mediaUrl,
      'media_size_bytes': mediaSizeBytes,
      'media_duration_seconds': mediaDurationSeconds,
      'thumbnail_url': thumbnailUrl,
      'metadata': metadata,
      'action_type': actionType,
      'action_data': actionData,
      'action_completed_at': actionCompletedAt?.toIso8601String(),
      'intent': intent,
      'confidence_score': confidenceScore,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  bool get isFromCustomer => senderType == 'customer';
  bool get isFromAI => senderType == 'ai_agent';
  bool get isFromStaff => senderType == 'staff';
  bool get hasMedia => mediaUrl != null && mediaUrl!.isNotEmpty;
  bool get hasAction => actionType != null;
}
