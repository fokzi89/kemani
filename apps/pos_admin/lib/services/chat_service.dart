import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chat_conversation.dart';
import '../models/chat_message.dart';

class ChatService {
  final _client = Supabase.instance.client;

  // Get all active customer conversations for the current tenant
  Future<List<ChatConversation>> getCustomerConversations({
    String status = 'active',
  }) async {
    try {
      final response = await _client
          .from('chat_conversations')
          .select('''
            *,
            customers!inner(id, full_name, email),
            users(id, full_name)
          ''')
          .eq('status', status)
          .order('started_at', ascending: false);

      return (response as List)
          .map((json) => ChatConversation.fromJson({
                ...json,
                'customer_name': json['customers']?['full_name'],
                'customer_email': json['customers']?['email'],
                'escalated_to_user_name': json['users']?['full_name'],
              }))
          .toList();
    } catch (e) {
      print('Error fetching customer conversations: $e');
      rethrow;
    }
  }

  // Get messages for a specific conversation
  Future<List<ChatMessage>> getMessages(String conversationId) async {
    try {
      final response = await _client
          .from('chat_messages')
          .select('''
            *,
            users(id, full_name)
          ''')
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: true);

      return (response as List)
          .map((json) => ChatMessage.fromJson({
                ...json,
                'sender_name': json['users']?['full_name'],
              }))
          .toList();
    } catch (e) {
      print('Error fetching messages: $e');
      rethrow;
    }
  }

  // Send a message
  Future<ChatMessage> sendMessage({
    required String conversationId,
    required String messageText,
    String messageType = 'text',
    String? mediaUrl,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw 'User not authenticated';

      final response = await _client
          .from('chat_messages')
          .insert({
            'conversation_id': conversationId,
            'sender_type': 'staff',
            'sender_id': userId,
            'message_type': messageType,
            'message_text': messageText,
            'media_url': mediaUrl,
            'metadata': metadata,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .select('''
            *,
            users(id, full_name)
          ''')
          .single();

      return ChatMessage.fromJson({
        ...response,
        'sender_name': response['users']?['full_name'],
      });
    } catch (e) {
      print('Error sending message: $e');
      rethrow;
    }
  }

  // Subscribe to new messages in a conversation (real-time)
  RealtimeChannel subscribeToMessages(
    String conversationId,
    void Function(ChatMessage message) onMessage,
  ) {
    return _client
        .channel('messages:$conversationId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'chat_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: conversationId,
          ),
          callback: (payload) async {
            // Fetch the full message with sender details
            final messageId = payload.newRecord['id'];
            final response = await _client
                .from('chat_messages')
                .select('''
                  *,
                  users(id, full_name)
                ''')
                .eq('id', messageId)
                .single();

            final message = ChatMessage.fromJson({
              ...response,
              'sender_name': response['users']?['full_name'],
            });
            onMessage(message);
          },
        )
        .subscribe();
  }

  // Subscribe to conversation updates (real-time)
  RealtimeChannel subscribeToConversations(
    void Function() onUpdate,
  ) {
    return _client
        .channel('conversations')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'chat_conversations',
          callback: (payload) {
            onUpdate();
          },
        )
        .subscribe();
  }

  // Mark conversation as escalated to current user
  Future<void> escalateConversation(String conversationId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw 'User not authenticated';

      await _client.from('chat_conversations').update({
        'status': 'escalated',
        'escalated_to_user_id': userId,
      }).eq('id', conversationId);
    } catch (e) {
      print('Error escalating conversation: $e');
      rethrow;
    }
  }

  // Mark conversation as completed
  Future<void> completeConversation(String conversationId) async {
    try {
      await _client.from('chat_conversations').update({
        'status': 'completed',
        'ended_at': DateTime.now().toIso8601String(),
      }).eq('id', conversationId);
    } catch (e) {
      print('Error completing conversation: $e');
      rethrow;
    }
  }

  // Send AI message (for AI Assistant)
  Future<ChatMessage> sendAIMessage({
    required String conversationId,
    required String messageText,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final response = await _client
          .from('chat_messages')
          .insert({
            'conversation_id': conversationId,
            'sender_type': 'ai_agent',
            'message_type': 'text',
            'message_text': messageText,
            'metadata': metadata,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return ChatMessage.fromJson(response);
    } catch (e) {
      print('Error sending AI message: $e');
      rethrow;
    }
  }

  // Create a new team chat conversation
  Future<ChatConversation> createTeamChat({
    required String tenantId,
    required String branchId,
  }) async {
    try {
      final response = await _client
          .from('chat_conversations')
          .insert({
            'tenant_id': tenantId,
            'branch_id': branchId,
            'status': 'active',
            'started_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return ChatConversation.fromJson(response);
    } catch (e) {
      print('Error creating team chat: $e');
      rethrow;
    }
  }
}
