import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _restaurantNameController = TextEditingController();
  bool _isRegistering = false;
  String? _errorMessage;

  Future<void> _submit() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    setState(() => _errorMessage = null);

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final restaurantName = _restaurantNameController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = "Please enter both email and password.");
      return;
    }

    if (_isRegistering && restaurantName.isEmpty) {
      setState(() => _errorMessage = "Please enter your Restaurant Name.");
      return;
    }

    try {
      if (_isRegistering) {
        await auth.signUp(email, password, restaurantName);
      } else {
        await auth.signIn(email, password);
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        switch (e.code) {
          case 'invalid-email':
            _errorMessage = "The email address is badly formatted.";
            break;
          case 'user-not-found':
          case 'wrong-password':
          case 'invalid-credential':
            _errorMessage = "Incorrect email or password.";
            break;
          case 'email-already-in-use':
            _errorMessage = "An account already exists for that email.";
            break;
          case 'weak-password':
            _errorMessage = "Password should be at least 6 characters.";
            break;
          default:
            _errorMessage = e.message ?? "An authentication error occurred.";
        }
      });
    } catch (e) {
      setState(() => _errorMessage = "An unexpected error occurred.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.ramen_dining,
                    size: 80,
                    color: Colors.deepOrange,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isRegistering ? 'Register Restaurant' : 'RamenOps',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (!_isRegistering) ...[
                     const SizedBox(height: 8),
                     Text(
                       'Welcome back to the Kitchen.',
                       style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                         color: Colors.grey,
                       ),
                     ),
                  ],
                  const SizedBox(height: 32),
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_isRegistering) ...[
                    TextField(
                      controller: _restaurantNameController,
                      decoration: const InputDecoration(
                        labelText: 'Restaurant Name',
                        prefixIcon: Icon(Icons.storefront),
                      ),
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email Address',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      helperText: _isRegistering 
                        ? 'Must be at least 6 characters long' 
                        : null,
                      helperMaxLines: 2,
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _isRegistering ? 'Create Account' : 'Login to Kitchen',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isRegistering 
                            ? 'Already have an account? ' 
                            : 'New Restaurant? ',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                             _isRegistering = !_isRegistering;
                             _errorMessage = null; 
                          });
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          _isRegistering ? 'Login here' : 'Register here',
                          style: const TextStyle(
                            color: Colors.deepOrange, 
                            fontWeight: FontWeight.bold
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () {
                      Provider.of<AuthProvider>(context, listen: false).loginAsGuest();
                    },
                    icon: const Icon(Icons.wifi_off),
                    label: const Text('Continue as Guest (Offline Mode)'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
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
