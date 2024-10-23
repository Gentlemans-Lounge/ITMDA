import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';
import '../widgets/shimmer_widgets.dart';
import '../widgets/task_card.dart';
import 'task_overview_screen.dart';

class TaskListScreen extends StatelessWidget {
  final String userId;
  final FirebaseService _firebaseService = FirebaseService();

  TaskListScreen({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: theme.colorScheme.onSurface,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'All Tasks',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 16),
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: _firebaseService.getUserTasks(userId),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: 3, // Show 3 shimmer loading items
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: ShimmerWidgets.loadingTask(theme),
                ),
              );
            }

            final tasks = (snapshot.data!.data()?['tasks'] as List<dynamic>?) ?? [];
            if (tasks.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.task_outlined,
                      size: 64,
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No tasks available',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You don\'t have any tasks assigned',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                return FutureBuilder<Map<String, dynamic>?>(
                  future: _firebaseService.getTaskDetails(
                    task['projectId'],
                    task['taskId'],
                  ),
                  builder: (context, taskSnapshot) {
                    if (!taskSnapshot.hasData) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: ShimmerWidgets.loadingTask(theme),
                      );
                    }

                    final taskData = taskSnapshot.data;
                    if (taskData == null) {
                      return const SizedBox.shrink();
                    }

                    return FutureBuilder<Map<String, dynamic>?>(
                      future: _firebaseService.getProjectDetails(task['projectId']),
                      builder: (context, projectSnapshot) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: TaskCard(
                            theme: theme,
                            taskData: taskData,
                            projectData: projectSnapshot.data,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TaskOverviewScreen(
                                    taskData: taskData,
                                    projectData: projectSnapshot.data,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}