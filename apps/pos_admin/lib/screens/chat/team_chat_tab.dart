import 'package:flutter/material.dart';

class TeamChatTab extends StatefulWidget {
  const TeamChatTab({super.key});

  @override
  State<TeamChatTab> createState() => _TeamChatTabState();
}

class _TeamChatTabState extends State<TeamChatTab> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.group,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Team Chat',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Chat with your team members',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () {
              // TODO: Implement create team chat
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Team Chat coming soon!'),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Start Team Chat'),
          ),
        ],
      ),
    );
  }
}
