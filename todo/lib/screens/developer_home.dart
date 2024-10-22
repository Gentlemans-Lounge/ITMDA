import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';

class DeveloperHome extends StatefulWidget {
  const DeveloperHome({super.key});

  @override
  _DeveloperHomeState createState() => _DeveloperHomeState();
}

final List<String> _emojis = ['✌️', '🚀', '💪', '🌟', '🎯', '💫', '⭐️', '🔥'];

class _DeveloperHomeState extends State<DeveloperHome> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final FirebaseService _firebaseService = FirebaseService();
  String _displayName = '';
  int _taskCount = 0;
  int _selectedIndex = 0;  // For bottom navigation

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _calculateTaskCount();
  }

  Future<void> _loadUserData() async {
    final user = _firebaseService.getCurrentUser();
    if (user != null) {
      final userData = await _firebaseService.getUserData(user.uid);
      if (userData.exists) {
        setState(() {
          _displayName = userData.get('displayName') ?? '';
        });
      }
    }
  }

  Future<void> _calculateTaskCount() async {
    final user = _firebaseService.getCurrentUser();
    if (user != null) {
      final userTasksSnapshot = await FirebaseFirestore.instance
          .collection('user_tasks')
          .doc(user.uid)
          .get();

      if (userTasksSnapshot.exists) {
        final tasks = userTasksSnapshot.data()?['tasks'] as List<dynamic>?;
        setState(() {
          _taskCount = tasks?.length ?? 0;
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
              title: Text('Dashboard', style: TextStyle(color: theme.colorScheme.onSurface)),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.analytics, color: theme.colorScheme.onSurface),
              title: Text('Analytics', style: TextStyle(color: theme.colorScheme.onSurface)),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.settings, color: theme.colorScheme.onSurface),
              title: Text('Settings', style: TextStyle(color: theme.colorScheme.onSurface)),
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
                      Icon(Icons.message, color: theme.colorScheme.onSurface, size: 20),
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

              // Today's Tasks Header
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
                      // TODO: Implement see all functionality
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

              // Task Card
              StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: _firebaseService.getUserTasks(_firebaseService.getCurrentUser()!.uid),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data == null) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final tasks = (snapshot.data!.data()?['tasks'] as List<dynamic>?) ?? [];
                  if (tasks.isEmpty) {
                    return Center(
                      child: Text(
                        'No tasks for today',
                        style: TextStyle(color: theme.colorScheme.onSurface),
                      ),
                    );
                  }

                  // Show first task
                  final firstTask = tasks[0];
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Task details coming soon...',
                          style: TextStyle(
                            color: theme.colorScheme.onSurface,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
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
              // TODO: Add navigation logic for each tab
            },
          ),
        ),
      ),
    );
  }
}