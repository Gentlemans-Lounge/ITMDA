import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';
import '../widgets/shimmer_widgets.dart';
import '../widgets/task_card.dart';
import 'task_overview_screen.dart';

class TaskListScreen extends StatefulWidget {
  final String userId;

  const TaskListScreen({
    super.key,
    required this.userId,
  });

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  String _selectedFilter = 'All';
  Map<String, int> _statusCounts = {
    'All': 0,
    'To Do': 0,
    'In Review': 0,
    'Completed': 0,
  };

  Future<void> _updateStatusCounts(List<dynamic> tasks) async {
    int todoCount = 0;
    int inReviewCount = 0;
    int completedCount = 0;

    for (var task in tasks) {
      final taskDetails = await _firebaseService.getTaskDetails(
        task['projectId'],
        task['taskId'],
      );

      if (taskDetails != null) {
        final taskStatus = taskDetails['status']?.toLowerCase() ?? 'todo';
        if (taskStatus == 'todo') {
          todoCount++;
        } else if (taskStatus == 'in_progress') {
          inReviewCount++;
        } else if (taskStatus == 'completed') {
          completedCount++;
        }
      }
    }

    if (mounted) {
      setState(() {
        _statusCounts = {
          'All': tasks.length,
          'To Do': todoCount,
          'In Progress': inReviewCount,
          'Completed': completedCount,
        };
      });
    }
  }

  Widget _buildFilterChip(String filter) {
    bool isSelected = _selectedFilter == filter;
    Color getColor() {
      if (!isSelected) return Colors.transparent;
      switch (filter.toLowerCase()) {
        case 'completed':
          return const Color(0xFF5CD669);
        case 'in progress':
          return const Color(0xFF9D9BFF);
        case 'to do':
          return const Color(0xFFF6BB54);
        default:
          return Colors.grey;
      }
    }

    Color getTextColor() {
      if (!isSelected) {
        return Theme.of(context).colorScheme.onSurface;
      }
      return Colors.white;
    }

    int count = _statusCounts[filter] ?? 0;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = filter;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? getColor() : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: !isSelected ? Border.all(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.12),
          ) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              filter,
              style: TextStyle(
                color: getTextColor(),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withOpacity(0.2)
                      : Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    color: getTextColor(),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<List<dynamic>> _getFilteredTasks(List<dynamic> tasks) async {
    if (_selectedFilter == 'All') return tasks;

    String statusToFilter = _selectedFilter.toLowerCase();
    if (statusToFilter == 'to do') statusToFilter = 'todo';
    if (statusToFilter == 'in progress') statusToFilter = 'in_progress';

    List<dynamic> filteredTasks = [];

    for (var task in tasks) {
      final taskDetails = await _firebaseService.getTaskDetails(
        task['projectId'],
        task['taskId'],
      );

      if (taskDetails != null) {
        final taskStatus = taskDetails['status']?.toLowerCase() ?? 'todo';
        if (taskStatus == statusToFilter) {
          filteredTasks.add(task);
        }
      }
    }

    return filteredTasks;
  }

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
      body: Column(
        children: [
          // Filter chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: _firebaseService.getUserTasks(widget.userId),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox.shrink();

                  final tasks = (snapshot.data!.data()?['tasks'] as List<dynamic>?) ?? [];
                  _updateStatusCounts(tasks);

                  return Row(
                    children: [
                      _buildFilterChip('All'),
                      _buildFilterChip('To Do'),
                      _buildFilterChip('In Progress'),
                      _buildFilterChip('Completed'),
                    ],
                  );
                },
              ),
            ),
          ),

          // Tasks list
          Expanded(
            child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: _firebaseService.getUserTasks(widget.userId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: 3,
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: ShimmerWidgets.loadingTask(theme),
                    ),
                  );
                }

                var tasks = (snapshot.data!.data()?['tasks'] as List<dynamic>?) ?? [];

                return FutureBuilder<List<dynamic>>(
                  future: _getFilteredTasks(tasks),
                  builder: (context, filteredTasksSnapshot) {
                    if (!filteredTasksSnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    tasks = filteredTasksSnapshot.data!;

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
                              _selectedFilter == 'All'
                                  ? 'You don\'t have any tasks assigned'
                                  : 'No tasks with status: $_selectedFilter',
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

                            taskData['projectId'] = task['projectId'];
                            taskData['taskId'] = task['taskId'];

                            return FutureBuilder<Map<String, dynamic>?>(
                              future: _firebaseService.getProjectDetails(task['projectId']),
                              builder: (context, projectSnapshot) {
                                if (projectSnapshot.data != null) {
                                  projectSnapshot.data!['id'] = task['projectId'];
                                }

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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}