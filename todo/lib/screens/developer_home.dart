import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';
import '../widgets/shimmer_widgets.dart';
import '../widgets/task_card.dart';
import 'colleagues_screen.dart';
import 'messages_screen.dart';
import 'task_overview_screen.dart';
import 'task_list_screen.dart';

class DeveloperHome extends StatefulWidget {
  const DeveloperHome({super.key});

  @override
  _DeveloperHomeState createState() => _DeveloperHomeState();
}

final List<String> _emojis = ['✌️', '🚀', '💪', '🌟', '🎯', '💫', '⭐️', '🔥'];

class _DeveloperHomeState extends State<DeveloperHome> with WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final FirebaseService _firebaseService = FirebaseService();
  final GlobalKey<State> _taskKey = GlobalKey<State>();
  String _displayName = '';
  int _taskCount = 0;
  int _selectedIndex = 0;
  String? _userId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeUser();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setState(() {
        _taskKey.currentState?.setState(() {});
      });
    }
  }

  Future<void> _initializeUser() async {
    final user = _firebaseService.getCurrentUser();
    if (user?.email != null) {
      final userDetails =
      await _firebaseService.getUserDetailsByEmail(user!.email);

      if (userDetails != null && mounted) {
        setState(() {
          _userId = userDetails['id'];
          _displayName = userDetails['data']['displayName'] ?? '';
        });
        await _calculateTaskCount();
      }
    }
  }

  Future<void> _calculateTaskCount() async {
    if (_userId != null) {
      final count = await _firebaseService.getUserTaskCount(_userId!);
      if (mounted) {
        setState(() {
          _taskCount = count;
        });
      }
    }
  }

  void _showProfilePopup() {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.scaffoldBackgroundColor,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              backgroundColor: theme.colorScheme.primary,
              child: Icon(Icons.person, color: theme.colorScheme.onPrimary),
            ),
            const SizedBox(height: 16),
            Text(
              _displayName,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskSection(ThemeData theme) {
    return WillPopScope(
      onWillPop: () async {
        if (mounted) {
          setState(() {
          });
        }
        return true;
      },
      child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        key: _taskKey,
        stream: _firebaseService.getUserTasks(_userId!),
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

          final firstTask = tasks[0];

          return StreamBuilder<DocumentSnapshot>(
            stream: _firebaseService.streamTaskDetails(
              firstTask['projectId'],
              firstTask['taskId'],
            ),
            builder: (context, taskSnapshot) {

              if (!taskSnapshot.hasData) {
                return ShimmerWidgets.loadingTask(theme);
              }

              final taskData = taskSnapshot.data?.data() as Map<String, dynamic>?;
              if (taskData == null) {
                return const SizedBox.shrink();
              }

              // Add the IDs to the task data
              taskData['projectId'] = firstTask['projectId'];
              taskData['taskId'] = firstTask['taskId'];


              return FutureBuilder<Map<String, dynamic>?>(
                future: _firebaseService.getProjectDetails(firstTask['projectId']),
                builder: (context, projectSnapshot) {

                  if (projectSnapshot.data != null) {
                    projectSnapshot.data!['id'] = firstTask['projectId'];
                  }

                  return TaskCard(
                    // Add a key based on the status to force rebuild
                    key: ValueKey('task_${taskData['status']}_${taskData['taskId']}'),
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
                      ).then((_) {
                        if (mounted) {
                          setState(() {
                          });
                        }
                      });
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    String randomEmoji = _emojis[DateTime.now().millisecond % _emojis.length];

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: theme.scaffoldBackgroundColor,
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
              ),
              child: Text(
                'Menu',
                style: TextStyle(
                  color: theme.colorScheme.onPrimary,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.dashboard, color: theme.colorScheme.onSurface),
              title: Text('Dashboard',
                  style: TextStyle(color: theme.colorScheme.onSurface)),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.analytics, color: theme.colorScheme.onSurface),
              title: Text('Analytics',
                  style: TextStyle(color: theme.colorScheme.onSurface)),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.settings, color: theme.colorScheme.onSurface),
              title: Text('Settings',
                  style: TextStyle(color: theme.colorScheme.onSurface)),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row with Menu and Profile
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            spreadRadius: 2,
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: Icon(Icons.menu, color: theme.colorScheme.primary),
                        onPressed: () {
                          _scaffoldKey.currentState?.openDrawer();
                        },
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            spreadRadius: 2,
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: Icon(Icons.person, color: theme.colorScheme.primary),
                        onPressed: _showProfilePopup,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Welcome Text
              Text(
                'Start Your Day &\nBe Productive $randomEmoji',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                  height: 1.2,
                ),
              ),

              const SizedBox(height: 100),

              // Task Count Pill
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.message,
                          color: theme.colorScheme.onSurface, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'You have $_taskCount tasks today',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 100),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Today's Tasks",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      if (_userId != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TaskListScreen(userId: _userId!),
                          ),
                        ).then((_) {
                          setState(() {
                            _taskKey.currentState?.setState(() {});
                          });
                        });
                      }
                    },
                    child: Row(
                      children: [
                        Text(
                          'See All',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontSize: 14,
                          ),
                        ),
                        Icon(Icons.chevron_right, color: theme.colorScheme.primary),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_userId == null)
                ShimmerWidgets.loadingTask(theme)
              else
                _buildTaskSection(theme),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 12),
          child: BottomNavigationBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: theme.colorScheme.primary,
            unselectedItemColor: Colors.grey,
            currentIndex: _selectedIndex,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.message_outlined),
                activeIcon: Icon(Icons.message),
                label: 'Message',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.calendar_today_outlined),
                activeIcon: Icon(Icons.calendar_today),
                label: 'Calendar',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.people_outline),
                activeIcon: Icon(Icons.people),
                label: 'Colleagues',
              ),
            ],
            onTap: (index) {
              setState(() {
                _selectedIndex = index;
              });
              switch (index) {
                case 1: // Messages
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const MessageScreen()),
                  );
                  break;
                case 3: // Colleagues
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ColleaguesScreen()),
                  );
                  break;
              }
            },
          ),
        ),
      ),
    );
  }
}