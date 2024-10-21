import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/setup_screen.dart';
import 'screens/login_screen.dart';

// Add this line to control whether to force the setup screen
const bool FORCE_SETUP_SCREEN = true;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
  }

  _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('darkMode') ?? false;
    });
  }

  void toggleTheme(bool isDarkMode) {
    setState(() {
      _isDarkMode = isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NowNow App',
      theme: _isDarkMode ? _darkTheme : _lightTheme,
      home: FutureBuilder(
        future: checkFirstTime(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          } else {
            if (snapshot.data == true) {
              return const SetupScreen();
            } else {
              return const LoginScreen();
            }
          }
        },
      ),
    );
  }

  Future<bool> checkFirstTime() async {
    if (FORCE_SETUP_SCREEN) return true;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isFirstTime = prefs.getBool('first_time') ?? true;
    if (isFirstTime) {
      await prefs.setBool('first_time', false);
    }
    return isFirstTime;
  }
}

final ThemeData _lightTheme = ThemeData(
  primaryColor: const Color(0xFFE6A2F8),
  scaffoldBackgroundColor: const Color(0xFFFAF0FF),
  colorScheme: const ColorScheme.light(
    primary: Color(0xFFE6A2F8),
    secondary: Color(0xFFC684D9),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFFE6A2F8),
    foregroundColor: Colors.black,
  ),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Colors.black),
    bodyMedium: TextStyle(color: Colors.black),
  ),
);

final ThemeData _darkTheme = ThemeData(
  primaryColor: const Color(0xFFC684D9),
  scaffoldBackgroundColor: const Color(0xFF121212),
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFFC684D9),
    secondary: Color(0xFFA665BA),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF1E1E1E),
    foregroundColor: Colors.white,
  ),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Colors.white),
    bodyMedium: TextStyle(color: Colors.white),
  ),
);