import 'package:flutter/material.dart';
import '../../models/chat_message.dart';

class AIAssistantTab extends StatefulWidget {
  const AIAssistantTab({super.key});

  @override
  State<AIAssistantTab> createState() => _AIAssistantTabState();
}

class _AIAssistantTabState extends State<AIAssistantTab> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    // Add welcome message from AI
    _messages.add(ChatMessage(
      id: 'welcome',
      conversationId: 'ai-assistant',
      senderType: 'ai_agent',
      messageText:
          'Hello! I\'m your AI Assistant. I can help you with:\n\n• Product recommendations\n• Sales insights and analytics\n• Business questions\n• POS system guidance\n\nWhat can I help you with today?',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _messageController.clear();

    // Add user message
    final userMessage = ChatMessage(
      id: 'user-${DateTime.now().millisecondsSinceEpoch}',
      conversationId: 'ai-assistant',
      senderType: 'staff',
      messageText: text,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
    });
    _scrollToBottom();

    // Simulate AI response (replace with actual AI API call)
    await Future.delayed(const Duration(seconds: 2));

    final aiResponse = ChatMessage(
      id: 'ai-${DateTime.now().millisecondsSinceEpoch}',
      conversationId: 'ai-assistant',
      senderType: 'ai_agent',
      messageText: _generateAIResponse(text),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    setState(() {
      _messages.add(aiResponse);
      _isSending = false;
    });
    _scrollToBottom();
  }

  String _generateAIResponse(String userMessage) {
    final lowercaseMessage = userMessage.toLowerCase();

    if (lowercaseMessage.contains('sale') || lowercaseMessage.contains('revenue')) {
      return 'Based on your sales data, I can see you\'ve made great progress this month! Your top-selling products are showing strong performance. Would you like me to provide detailed analytics or recommendations for improving sales?';
    } else if (lowercaseMessage.contains('product') ||
        lowercaseMessage.contains('inventory')) {
      return 'I can help you manage your products and inventory. You can:\n\n• Add new products\n• Update stock levels\n• View low-stock alerts\n• Analyze product performance\n\nWhich would you like to do?';
    } else if (lowercaseMessage.contains('customer')) {
      return 'Customer management is key to your success! I can help you:\n\n• View customer purchase history\n• Identify your top customers\n• Send personalized promotions\n• Analyze customer behavior\n\nHow can I assist with customers?';
    } else if (lowercaseMessage.contains('report') ||
        lowercaseMessage.contains('analytics')) {
      return 'I can generate various reports for you:\n\n• Daily sales summary\n• Product performance\n• Staff performance\n• Customer insights\n\nWhich report would you like to see?';
    } else {
      return 'I understand you\'re asking about "$userMessage". While I\'m still learning, I can help with sales data, product management, customer insights, and business analytics. Could you rephrase your question to focus on one of these areas?';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // AI Assistant Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.purple.shade400,
                Colors.purple.shade600,
              ],
            ),
          ),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.smart_toy,
                  color: Colors.purple,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'AI Business Assistant',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Powered by AI • Always ready to help',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.online_prediction,
                color: Colors.white.withOpacity(0.9),
              ),
            ],
          ),
        ),

        // Suggested questions
        if (_messages.length == 1)
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick questions:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildSuggestionChip('Show today\'s sales'),
                    _buildSuggestionChip('Top selling products'),
                    _buildSuggestionChip('Low stock alerts'),
                    _buildSuggestionChip('Customer insights'),
                  ],
                ),
              ],
            ),
          ),

        // Messages
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final message = _messages[index];
              return _buildMessageBubble(message);
            },
          ),
        ),

        // Message input
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'Ask me anything about your business...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    prefixIcon: const Icon(Icons.lightbulb_outline),
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              _isSending
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : IconButton(
                      icon: const Icon(Icons.send),
                      color: Colors.purple,
                      onPressed: _sendMessage,
                    ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestionChip(String text) {
    return ActionChip(
      label: Text(text),
      onPressed: () {
        _messageController.text = text;
        _sendMessage();
      },
      avatar: const Icon(Icons.auto_awesome, size: 16),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isFromAI = message.isFromAI;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            isFromAI ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          if (isFromAI)
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.purple,
              child: const Icon(
                Icons.smart_toy,
                size: 16,
                color: Colors.white,
              ),
            ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isFromAI ? Colors.purple.shade50 : Colors.blue.shade500,
                borderRadius: BorderRadius.circular(16).copyWith(
                  bottomLeft: isFromAI ? const Radius.circular(4) : null,
                  bottomRight: !isFromAI ? const Radius.circular(4) : null,
                ),
              ),
              child: Text(
                message.messageText ?? '',
                style: TextStyle(
                  color: isFromAI ? Colors.black87 : Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (!isFromAI)
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.green,
              child: const Icon(
                Icons.person,
                size: 16,
                color: Colors.white,
              ),
            ),
        ],
      ),
    );
  }
}
