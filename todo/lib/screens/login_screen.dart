import 'package:flutter/material.dart';
import '../main.dart';
import '../services/firebase_service.dart';
import 'registration_screen.dart';
import 'preferences_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, bool isError) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _handleEmailSignIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final result = await _firebaseService.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (result['success']) {
        _showSnackBar('Login successful!', false);
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) =>
                  PreferencesScreen(
                    onThemeChanged: (bool isDarkMode) {
                      MyAppState? myAppState = context.findAncestorStateOfType<
                          MyAppState>();
                      myAppState?.toggleTheme(isDarkMode);
                    },
                  ),
            ),
          );
        }
      } else {
        if (result['needsRegistration'] == true) {
          _showSnackBar(
              'No account found with this email. Please register first.', true);
        } else {
          _showSnackBar(result['message'] ?? 'Login failed', true);
        }
      }
    } catch (e) {
      _showSnackBar('An error occurred: ${e.toString()}', true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);

    try {
      final result = await _firebaseService.signInWithGoogle();

      if (result['success']) {
        if (result['needsRegistration'] == true) {
          // New Google user needs to complete registration
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) =>
                    PreferencesScreen(
                      onThemeChanged: (bool isDarkMode) {
                        MyAppState? myAppState = context
                            .findAncestorStateOfType<MyAppState>();
                        myAppState?.toggleTheme(isDarkMode);
                      },
                      isNewUser: true,
                      userData: result,
                    ),
              ),
            );
          }
        } else {
          // Existing Google user
          _showSnackBar('Login successful!', false);
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const HomeScreen(),
              ),
            );
          }
        }
      } else {
        _showSnackBar(result['message'] ?? 'Google sign-in failed', true);
      }
    } catch (e) {
      _showSnackBar('An error occurred: ${e.toString()}', true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF0FF),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        const SizedBox(height: 60),
                        const Text(
                          'Login',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 100),
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(
                                Icons.email, color: Color(0xFFE6A2F8)),
                            labelStyle: TextStyle(color: Color(0xFFE6A2F8)),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFFE6A2F8)),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFFE6A2F8)),
                            ),
                          ),
                          validator: (val) {
                            if (val == null || val.isEmpty) {
                              return 'Please enter an email';
                            }
                            if (!val.contains('@') || !val.contains('.')) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(
                                Icons.lock, color: Color(0xFFE6A2F8)),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off : Icons
                                    .visibility,
                                color: const Color(0xFFE6A2F8),
                              ),
                              onPressed: () => setState(() =>
                              _obscurePassword = !_obscurePassword),
                            ),
                            labelStyle: const TextStyle(
                                color: Color(0xFFE6A2F8)),
                            enabledBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFFE6A2F8)),
                            ),
                            focusedBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFFE6A2F8)),
                            ),
                          ),
                          obscureText: _obscurePassword,
                          validator: (val) =>
                          val!.length < 6
                              ? 'Enter a password 6+ chars long'
                              : null,
                        ),
                        const SizedBox(height: 100),
                        if (_isLoading)
                          const Center(child: CircularProgressIndicator(
                              color: Color(0xFFE6A2F8)))
                        else
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE6A2F8),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            onPressed: _handleEmailSignIn,
                            child: const Text('Sign in', style: TextStyle(
                                color: Colors.white, fontSize: 16)),
                          ),
                        const SizedBox(height: 20),
                        const Row(
                          children: [
                            Expanded(child: Divider()),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                  'OR', style: TextStyle(color: Colors.grey)),
                            ),
                            Expanded(child: Divider()),
                          ],
                        ),
                        const SizedBox(height: 20),
                        OutlinedButton.icon(
                          icon: Image.asset(
                              'assets/images/google_logo.png', height: 18),
                          label: const Text('Continue with Google',
                              style: TextStyle(
                                  color: Colors.black87, fontSize: 14)
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            side: BorderSide(color: Colors.grey[300]!),
                          ),
                          onPressed: _handleGoogleSignIn,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Bottom account prompt
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Don't have an account? ",
                        style: TextStyle(color: Colors.grey[600])),
                    TextButton(
                      child: const Text('Register',
                          style: TextStyle(color: Color(0xFFE6A2F8))),
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (
                              context) => const RegistrationScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}