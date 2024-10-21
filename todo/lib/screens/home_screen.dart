import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseService _firebaseService = FirebaseService();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return WillPopScope(
      onWillPop: () async => false, // Disable back button
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60),
                Text(
                  'My Projects',
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _firebaseService.getUserProjects(_firebaseService.getCurrentUser()!.uid),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(
                          child: Text(
                            'No projects found',
                            style: textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurface),
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          DocumentSnapshot project = snapshot.data!.docs[index];
                          return ListTile(
                            title: Text(
                              project['name'],
                              style: textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurface),
                            ),
                            subtitle: Text(
                              project['description'],
                              style: textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.7)),
                            ),
                            onTap: () {
                              // TODO: Navigate to project detail screen
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: theme.colorScheme.secondary,
          onPressed: () {
            // TODO: Implement project creation
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('Create New Project', style: textTheme.titleLarge),
                content: Text('Project creation will be implemented here.', style: textTheme.bodyMedium),
                actions: [
                  TextButton(
                    child: Text('OK', style: textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary)),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            );
          },
          child: Icon(Icons.add, color: theme.colorScheme.onSecondary),
        ),
      ),
    );
  }
}