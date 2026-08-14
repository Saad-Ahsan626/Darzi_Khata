import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tailor_khata/core/theme/app_theme.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.charcoalThread,
      body: Center(
        child: Text(
          'Tailor Khata\nSplash',
          style: Theme.of(
            context,
          ).textTheme.displayMedium?.copyWith(color: AppTheme.tailorChalk),
          textAlign: TextAlign.center,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/welcome'),
        child: const Icon(Icons.arrow_forward),
      ),
    );
  }
}
