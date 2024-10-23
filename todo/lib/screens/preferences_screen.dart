import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lottie/lottie.dart';
import 'developer_home.dart';
import 'pm_home.dart';
import '../services/firebase_service.dart';

class PreferencesScreen extends StatefulWidget {
  final Function(bool) onThemeChanged;
  final bool isNewUser;
  final Map<String, dynamic>? userData;

  const PreferencesScreen({
    super.key,
    required this.onThemeChanged,
    this.isNewUser = false,
    this.userData,
  });

  @override
  _PreferencesScreenState createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final _formKey = GlobalKey<FormState>();

  bool _darkMode = false;
  bool _notifications = false;
  String _displayName = '';
  String _selectedRole = 'developer';
  bool _isLoading = false;

  final List<String> _roles = ['developer', 'project_manager'];

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    if (widget.userData != null) {
      _displayName = widget.userData?['email']?.split('@')[0] ?? '';
    }
  }

  _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _darkMode = prefs.getBool('darkMode') ?? false;
      _notifications = prefs.getBool('notifications') ?? false;
    });
  }

  _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', _darkMode);
    await prefs.setBool('notifications', _notifications);
  }

  Future<void> _completeRegistration() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = _firebaseService.getCurrentUser();
      if (user == null) {
        _showError('No user found. Please try signing in again.');
        return;
      }

      // If we have userData from registration, use that role, otherwise use selected role
      final roleToUse = widget.userData?['role'] ?? _selectedRole;

      final result = await _firebaseService.completeGoogleSignUp(
        user,
        _displayName,
        roleToUse,
      );

      if (result['success']) {
        await _savePreferences();
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => roleToUse == 'project_manager'
                  ? const ProjectManagerHome()
                  : const DeveloperHome(),
            ),
          );
        }
      } else {
        _showError(result['message'] ?? 'Registration failed');
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 60),
                  Text(
                    widget.isNewUser ? 'Complete Your Profile' : 'Set Your Preferences',
                    style: textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Center(
                    child: Lottie.asset(
                      'assets/animations/preferences.json',
                      width: 200,
                      height: 200,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // New User Registration Fields
                  if (widget.isNewUser) ...[
                    TextFormField(
                      initialValue: _displayName,
                      decoration: InputDecoration(
                        labelText: 'Display Name',
                        hintText: 'How should we call you?',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (val) => val?.isEmpty ?? true ? 'Please enter a display name' : null,
                      onChanged: (val) => setState(() => _displayName = val),
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      value: _selectedRole,
                      decoration: InputDecoration(
                        labelText: 'Role',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: _roles.map((role) {
                        return DropdownMenuItem(
                          value: role,
                          child: Text(role.replaceAll('_', ' ').toUpperCase()),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedRole = val!),
                    ),
                    const SizedBox(height: 40),
                  ],

                  // General Preferences
                  SwitchListTile(
                    title: Text('Dark Mode', style: textTheme.bodyLarge),
                    value: _darkMode,
                    activeColor: theme.colorScheme.secondary,
                    onChanged: (bool value) {
                      setState(() => _darkMode = value);
                      widget.onThemeChanged(value);
                    },
                  ),
                  SwitchListTile(
                    title: Text('Enable Notifications', style: textTheme.bodyLarge),
                    value: _notifications,
                    activeColor: theme.colorScheme.secondary,
                    onChanged: (bool value) => setState(() => _notifications = value),
                  ),
                  const SizedBox(height: 40),

                  // Action Button
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else
                    Center(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        onPressed: () async {
                          if (widget.isNewUser) {
                            await _completeRegistration();
                          } else {
                            await _savePreferences();
                            if (mounted) {
                              // Get the role from userData if it exists (from email registration)
                              final role = widget.userData?['role'] as String?;

                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (context) => role == 'project_manager'
                                      ? const ProjectManagerHome()
                                      : const DeveloperHome(),
                                ),
                              );
                            }
                          }
                        },
                        child: Text(
                          widget.isNewUser ? 'Complete Registration' : 'Save and Continue',
                          style: textTheme.labelLarge?.copyWith(color: theme.colorScheme.onPrimary),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}