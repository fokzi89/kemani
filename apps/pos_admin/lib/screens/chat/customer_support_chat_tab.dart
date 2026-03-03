import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/chat_conversation.dart';
import '../../services/chat_service.dart';
import 'chat_conversation_screen.dart';

class CustomerSupportChatTab extends StatefulWidget {
  const CustomerSupportChatTab({super.key});

  @override
  State<CustomerSupportChatTab> createState() => _CustomerSupportChatTabState();
}

class _CustomerSupportChatTabState extends State<CustomerSupportChatTab> {
  final ChatService _chatService = ChatService();
  List<ChatConversation> _conversations = [];
  bool _isLoading = true;
  String _selectedFilter = 'active';
  RealtimeChannel? _subscription;

  @override
  void initState() {
    super.initState();
    _loadConversations();
    _subscribeToUpdates();
  }

  @override
  void dispose() {
    _subscription?.unsubscribe();
    super.dispose();
  }

  Future<void> _loadConversations() async {
    setState(() => _isLoading = true);
    try {
      final conversations =
          await _chatService.getCustomerConversations(status: _selectedFilter);
      if (mounted) {
        setState(() {
          _conversations = conversations;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading conversations: $e')),
        );
      }
    }
  }

  void _subscribeToUpdates() {
    _subscription = _chatService.subscribeToConversations(() {
      _loadConversations();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filter chips
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Wrap(
            spacing: 8,
            children: [
              FilterChip(
                label: const Text('Active'),
                selected: _selectedFilter == 'active',
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedFilter = 'active');
                    _loadConversations();
                  }
                },
              ),
              FilterChip(
                label: const Text('Escalated'),
                selected: _selectedFilter == 'escalated',
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedFilter = 'escalated');
                    _loadConversations();
                  }
                },
              ),
              FilterChip(
                label: const Text('Completed'),
                selected: _selectedFilter == 'completed',
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedFilter == 'completed');
                    _loadConversations();
                  }
                },
              ),
            ],
          ),
        ),

        // Conversation list
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _conversations.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No $_selectedFilter conversations',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadConversations,
                      child: ListView.separated(
                        itemCount: _conversations.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final conversation = _conversations[index];
                          return _buildConversationTile(conversation);
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildConversationTile(ChatConversation conversation) {
    final hasUnread = conversation.unreadCount > 0;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _getStatusColor(conversation.status),
        child: Text(
          conversation.customerName?.substring(0, 1).toUpperCase() ?? 'C',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              conversation.customerName ?? 'Unknown Customer',
              style: TextStyle(
                fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          if (hasUnread)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${conversation.unreadCount}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (conversation.customerEmail != null)
            Text(
              conversation.customerEmail!,
              style: const TextStyle(fontSize: 12),
            ),
          if (conversation.lastMessageText != null) ...[
            const SizedBox(height: 4),
            Text(
              conversation.lastMessageText!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
                fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ],
          if (conversation.escalatedToUserName != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.person, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Assigned to ${conversation.escalatedToUserName}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (conversation.lastMessageAt != null)
            Text(
              _formatTime(conversation.lastMessageAt!),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          const SizedBox(height: 4),
          _buildStatusBadge(conversation.status),
        ],
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatConversationScreen(
              conversation: conversation,
              chatType: ChatType.customerSupport,
            ),
          ),
        ).then((_) => _loadConversations());
      },
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    IconData icon;

    switch (status) {
      case 'active':
        color = Colors.green;
        icon = Icons.circle;
        break;
      case 'escalated':
        color = Colors.orange;
        icon = Icons.arrow_upward;
        break;
      case 'completed':
        color = Colors.grey;
        icon = Icons.check_circle;
        break;
      default:
        color = Colors.grey;
        icon = Icons.circle;
    }

    return Icon(icon, size: 16, color: color);
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'escalated':
        return Colors.orange;
      case 'completed':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}
