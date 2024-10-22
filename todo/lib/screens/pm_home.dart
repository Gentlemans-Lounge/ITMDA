import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';

class ProjectManagerHome extends StatefulWidget {
  const ProjectManagerHome({super.key});

  @override
  _ProjectManagerHomeState createState() => _ProjectManagerHomeState();
}

class _ProjectManagerHomeState extends State<ProjectManagerHome> {
  final FirebaseService _firebaseService = FirebaseService();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: Text(
            'Project Manager Dashboard\nComing Soon...',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}