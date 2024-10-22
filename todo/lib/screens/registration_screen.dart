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
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _displayNameController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String _selectedRole = 'developer';

  final List<String> _roles = ['developer', 'project_manager'];

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _displayNameController.dispose();
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

  Future<void> _handleEmailRegistration() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final result = await _firebaseService.signUpWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
        _displayNameController.text.trim(),
        _selectedRole,
      );

      if (result['success']) {
        _showSnackBar('Registration successful!', false);
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => PreferencesScreen(
                onThemeChanged: (bool isDarkMode) {
                  MyAppState? myAppState =
                      context.findAncestorStateOfType<MyAppState>();
                  myAppState?.toggleTheme(isDarkMode);
                },
              ),
            ),
          );
        }
      } else {
        _showSnackBar(result['message'] ?? 'Registration failed', true);
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
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => PreferencesScreen(
                  onThemeChanged: (bool isDarkMode) {
                    MyAppState? myAppState =
                        context.findAncestorStateOfType<MyAppState>();
                    myAppState?.toggleTheme(isDarkMode);
                  },
                  isNewUser: true,
                  userData: result,
                ),
              ),
            );
          }
        } else {
          _showSnackBar(
              'Account already exists. Redirecting to home...', false);
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => PreferencesScreen(
                  onThemeChanged: (bool isDarkMode) {
                    MyAppState? myAppState =
                        context.findAncestorStateOfType<MyAppState>();
                    myAppState?.toggleTheme(isDarkMode);
                  },
                ),
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
                          'Create your account',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 60),
                        TextFormField(
                          controller: _displayNameController,
                          decoration: const InputDecoration(
                            labelText: 'Display Name',
                            prefixIcon:
                                Icon(Icons.person, color: Color(0xFFE6A2F8)),
                            labelStyle: TextStyle(color: Color(0xFFE6A2F8)),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFFE6A2F8)),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFFE6A2F8)),
                            ),
                          ),
                          validator: (val) => val?.isEmpty ?? true
                              ? 'Please enter a display name'
                              : null,
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon:
                                Icon(Icons.email, color: Color(0xFFE6A2F8)),
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
                            prefixIcon: const Icon(Icons.lock,
                                color: Color(0xFFE6A2F8)),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: const Color(0xFFE6A2F8),
                              ),
                              onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                            ),
                            labelStyle:
                                const TextStyle(color: Color(0xFFE6A2F8)),
                            enabledBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFFE6A2F8)),
                            ),
                            focusedBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFFE6A2F8)),
                            ),
                          ),
                          obscureText: _obscurePassword,
                          validator: (val) => val!.length < 6
                              ? 'Password must contain 6 or more characters'
                              : null,
                        ),
                        const SizedBox(height: 24),
                        DropdownButtonFormField<String>(
                          value: _selectedRole,
                          decoration: const InputDecoration(
                            labelText: 'Role',
                            prefixIcon:
                                Icon(Icons.work, color: Color(0xFFE6A2F8)),
                            labelStyle: TextStyle(color: Color(0xFFE6A2F8)),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFFE6A2F8)),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFFE6A2F8)),
                            ),
                          ),
                          items: _roles.map((role) {
                            return DropdownMenuItem(
                              value: role,
                              child: Text(
                                role.replaceAll('_', ' ').toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 14,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) =>
                              setState(() => _selectedRole = val!),
                        ),
                        const SizedBox(height: 60),
                        if (_isLoading)
                          const Center(
                              child: CircularProgressIndicator(
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
                            onPressed: _handleEmailRegistration,
                            child: const Text(
                              'Register',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 16),
                            ),
                          ),
                        const SizedBox(height: 20),
                        const Row(
                          children: [
                            Expanded(child: Divider()),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text('OR',
                                  style: TextStyle(color: Colors.grey)),
                            ),
                            Expanded(child: Divider()),
                          ],
                        ),
                        const SizedBox(height: 20),
                        OutlinedButton.icon(
                          icon: Image.asset('assets/images/google_logo.png',
                              height: 18),
                          label: const Text(
                            'Continue with Google',
                            style:
                                TextStyle(color: Colors.black87, fontSize: 14),
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
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Already have an account? ",
                        style: TextStyle(color: Colors.grey[600])),
                    TextButton(
                      child: const Text('Login',
                          style: TextStyle(color: Color(0xFFE6A2F8))),
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const LoginScreen()),
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
