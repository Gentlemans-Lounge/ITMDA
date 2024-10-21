import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lottie/lottie.dart';
import 'home_screen.dart';

class PreferencesScreen extends StatefulWidget {
  final Function(bool) onThemeChanged;

  const PreferencesScreen({super.key, required this.onThemeChanged});

  @override
  _PreferencesScreenState createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  bool _darkMode = false;
  bool _notifications = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              Text(
                'Set Your Preferences',
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 40),
              // Lottie animation
              Center(
                child: Lottie.asset(
                  'assets/animations/preferences.json',
                  width: 200,
                  height: 200,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 40),
              SwitchListTile(
                title: Text('Dark Mode', style: textTheme.bodyLarge),
                value: _darkMode,
                activeColor: theme.colorScheme.secondary,
                onChanged: (bool value) {
                  setState(() {
                    _darkMode = value;
                  });
                  widget.onThemeChanged(value);
                },
              ),
              SwitchListTile(
                title: Text('Enable Notifications', style: textTheme.bodyLarge),
                value: _notifications,
                activeColor: theme.colorScheme.secondary,
                onChanged: (bool value) {
                  setState(() {
                    _notifications = value;
                  });
                },
              ),
              const SizedBox(height: 40),
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
                    await _savePreferences();
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => const HomeScreen()),
                    );
                  },
                  child: Text('Save and Continue', style: textTheme.labelLarge?.copyWith(color: theme.colorScheme.onPrimary)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}