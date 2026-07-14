import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Spin to Earn',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 50),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.login),
                    label: const Text('Sign in with Google'),
                    onPressed: () async {
                      setState(() => _isLoading = true);
                      final user = await authService.signInWithGoogle();
                      if (user != null) {
                        final dbService = DatabaseService();
                        final existingUser = await dbService.getUser(user.uid);
                        if (existingUser == null) {
                          await dbService.createUser(user);
                        }
                      }
                      if (mounted) setState(() => _isLoading = false);
                    },
                  ),
                ],
              ),
      ),
    );
  }
}
