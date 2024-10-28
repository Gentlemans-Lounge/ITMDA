import 'package:flutter/material.dart';

class MessageScreen extends StatelessWidget {
  const MessageScreen({super.key});

  Widget _buildMessageTile({
    required String name,
    required String lastMessage,
    required String time,
    required bool isOnline,
    String? avatarUrl,
    bool unread = false,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.grey[200],
            child: avatarUrl != null
                ? null
                : Text(
              name.substring(0, 1).toUpperCase(),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
          ),
          if (isOnline)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: const Color(0xFF5CD669),
                  border: Border.all(color: Colors.white, width: 2),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
        ],
      ),
      title: Text(
        name,
        style: TextStyle(
          fontWeight: unread ? FontWeight.bold : FontWeight.normal,
          fontSize: 16,
        ),
      ),
      subtitle: Text(
        lastMessage,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: unread ? Colors.black87 : Colors.grey[600],
          fontWeight: unread ? FontWeight.w500 : FontWeight.normal,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            time,
            style: TextStyle(
              color: unread ? const Color(0xFF9D9BFF) : Colors.grey[500],
              fontSize: 12,
            ),
          ),
          if (unread) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Color(0xFF9D9BFF),
                shape: BoxShape.circle,
              ),
              child: const Text(
                '1',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Messages',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
        ],
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Online users row
          Container(
            height: 100,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildOnlineUser('Sarah Parker'),
                _buildOnlineUser('John Smith'),
                _buildOnlineUser('Mike Ross'),
                _buildOnlineUser('Rachel Green'),
                _buildOnlineUser('David Miller'),
              ],
            ),
          ),

          // Divider
          const Divider(height: 1),

          // Messages list
          Expanded(
            child: ListView(
              children: [
                _buildMessageTile(
                  name: 'Sarah Parker',
                  lastMessage: 'Can you review the new design?',
                  time: '2m ago',
                  isOnline: true,
                  unread: true,
                ),
                _buildMessageTile(
                  name: 'John Smith',
                  lastMessage: 'The meeting is scheduled for tomorrow',
                  time: '1h ago',
                  isOnline: true,
                ),
                _buildMessageTile(
                  name: 'Mike Ross',
                  lastMessage: 'Project files have been updated',
                  time: '2h ago',
                  isOnline: true,
                  unread: true,
                ),
                _buildMessageTile(
                  name: 'Rachel Green',
                  lastMessage: 'Thanks for your help!',
                  time: '1d ago',
                  isOnline: false,
                ),
                _buildMessageTile(
                  name: 'David Miller',
                  lastMessage: 'Let me know when you\'re free',
                  time: '2d ago',
                  isOnline: false,
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: theme.colorScheme.primary,
        child: const Icon(Icons.edit),
      ),
    );
  }

  Widget _buildOnlineUser(String name) {
    return Container(
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.grey[200],
                child: Text(
                  name.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFF5CD669),
                    border: Border.all(color: Colors.white, width: 2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            name.split(' ')[0],
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}