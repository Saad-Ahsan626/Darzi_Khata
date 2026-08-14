import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Cloud accounts launching soon'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/welcome'),
              child: const Text('Back'),
            ),
          ],
        ),
      ),
    );
  }
}
