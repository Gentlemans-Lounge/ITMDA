import 'package:flutter/material.dart';

class TaskOverviewScreen extends StatelessWidget {
  final Map<String, dynamic> taskData;
  final Map<String, dynamic>? projectData;

  const TaskOverviewScreen({
    super.key,
    required this.taskData,
    this.projectData,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          taskData['title'] ?? 'Task Details',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontSize: 20,
          ),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: const Center(
        child: Text('Task details coming soon...'),
      ),
    );
  }
}