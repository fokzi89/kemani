import 'package:flutter/material.dart';
import 'customer_support_chat_tab.dart';
import 'team_chat_tab.dart';
import 'ai_assistant_tab.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.support_agent),
              text: 'Customer Support',
            ),
            Tab(
              icon: Icon(Icons.group),
              text: 'Team Chat',
            ),
            Tab(
              icon: Icon(Icons.smart_toy),
              text: 'AI Assistant',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          CustomerSupportChatTab(),
          TeamChatTab(),
          AIAssistantTab(),
        ],
      ),
    );
  }
}
