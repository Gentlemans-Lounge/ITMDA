import 'package:flutter/material.dart';

class ColleaguesScreen extends StatelessWidget {
  const ColleaguesScreen({super.key});

  Widget _buildColleagueCard(BuildContext context, {
    required String name,
    required String role,
    required String status,
    required int tasksCompleted,
    required int totalTasks,
    String? avatarUrl,
  }) {
    final theme = Theme.of(context);

    Color getStatusColor() {
      switch (status.toLowerCase()) {
        case 'available':
          return const Color(0xFF5CD669);
        case 'busy':
          return const Color(0xFFF6BB54);
        case 'in meeting':
          return const Color(0xFF9D9BFF);
        default:
          return Colors.grey;
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.grey[200],
            child: avatarUrl != null
                ? null
                : Text(
              name.substring(0, 1).toUpperCase(),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: getStatusColor().withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: getStatusColor(),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  role,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.task_alt,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$tasksCompleted/$totalTasks tasks completed',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
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
          'Colleagues',
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
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {},
          ),
        ],
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          _buildColleagueCard(
            context,
            name: 'Sarah Parker',
            role: 'Senior Developer',
            status: 'Available',
            tasksCompleted: 12,
            totalTasks: 15,
          ),
          _buildColleagueCard(
            context,
            name: 'John Smith',
            role: 'Project Manager',
            status: 'In Meeting',
            tasksCompleted: 8,
            totalTasks: 10,
          ),
          _buildColleagueCard(
            context,
            name: 'Mike Ross',
            role: 'UI Designer',
            status: 'Busy',
            tasksCompleted: 5,
            totalTasks: 8,
          ),
          _buildColleagueCard(
            context,
            name: 'Rachel Green',
            role: 'Frontend Developer',
            status: 'Available',
            tasksCompleted: 15,
            totalTasks: 20,
          ),
          _buildColleagueCard(
            context,
            name: 'David Miller',
            role: 'Backend Developer',
            status: 'In Meeting',
            tasksCompleted: 7,
            totalTasks: 12,
          ),
        ],
      ),
    );
  }
}