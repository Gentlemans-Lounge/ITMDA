import 'package:flutter/material.dart';
import '../main.dart';
import '../services/firebase_service.dart';
import 'login_screen.dart';
import 'preferences_screen.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  bool _obscurePassword = true;

  void _showSnackBar(String message, bool isError) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF0FF),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const SizedBox(height: 60),
                const Text(
                  'Create your account',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 100),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email, color: Color(0xFFE6A2F8)),
                    labelStyle: TextStyle(color: Color(0xFFE6A2F8)),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFE6A2F8)),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFE6A2F8)),
                    ),
                  ),
                  validator: (val) => val!.isEmpty ? 'Enter an email' : null,
                  onChanged: (val) => setState(() => _email = val),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock, color: Color(0xFFE6A2F8)),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: const Color(0xFFE6A2F8),
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    labelStyle: const TextStyle(color: Color(0xFFE6A2F8)),
                    enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFE6A2F8)),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFE6A2F8)),
                    ),
                  ),
                  obscureText: _obscurePassword,
                  validator: (val) => val!.length < 6 ? 'Password must contain 6 or more characters' : null,
                  onChanged: (val) => setState(() => _password = val),
                ),
                const SizedBox(height: 100),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE6A2F8),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      dynamic result = await _firebaseService.signUpWithEmailAndPassword(_email, _password, 'developer');
                      if (result == null) {
                        _showSnackBar('Registration failed. Please try again.', true);
                      } else {
                        _showSnackBar('Registration successful!', false);
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => PreferencesScreen(
                              onThemeChanged: (bool isDarkMode) {
                                // Find the MyAppState and call toggleTheme
                                MyAppState? myAppState = context.findAncestorStateOfType<MyAppState>();
                                myAppState?.toggleTheme(isDarkMode);
                              },
                            ),
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Register', style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
                const SizedBox(height: 20),
                const Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('OR', style: TextStyle(color: Colors.grey)),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  icon: Image.asset('assets/images/google_logo.png', height: 18),
                  label: const Text('Continue with Google', style: TextStyle(color: Colors.black87, fontSize: 14)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    side: BorderSide(color: Colors.grey[300]!),
                  ),
                  onPressed: () async {
                    dynamic result = await _firebaseService.signInWithGoogle();
                    if (result == null) {
                      _showSnackBar('Google Sign-In failed. Please try again.', true);
                    } else {
                      _showSnackBar('Google Sign-In successful!', false);
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => PreferencesScreen(
                            onThemeChanged: (bool isDarkMode) {
                              // Find the MyAppState and call toggleTheme
                              MyAppState? myAppState = context.findAncestorStateOfType<MyAppState>();
                              myAppState?.toggleTheme(isDarkMode);
                            },
                          ),
                        ),
                      );
                    }
                  },
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Already have an account? ", style: TextStyle(color: Colors.grey[600])),
                    TextButton(
                      child: const Text('Login', style: TextStyle(color: Color(0xFFE6A2F8))),
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}