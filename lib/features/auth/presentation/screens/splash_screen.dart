import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tailor_khata/core/theme/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack, // Gives a nice little pop at the end
    );

    // Start the animation
    _controller.forward();

    // Navigate to welcome screen after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        context.go('/welcome');
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.charcoalThread, // The dark background
      body: Stack(
        children: [
          Center(
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.content_cut_rounded,
                    size: 120,
                    color: AppColors.brassTape,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Tailor Khata',
                    style: TextStyle(
                      fontFamily: 'Zilla Slab',
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: AppColors.tailorChalk, // The off-white text
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'ٹیلر کھاتہ',
                    style: TextStyle(
                      fontFamily: 'Noto Nastaliq Urdu',
                      fontSize: 24,
                      color: AppColors.brassTape, // Golden touch
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 48,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Text(
                'TAILOR KHATA V1.0.0',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Roboto Mono',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  color: AppColors.tailorChalk.withOpacity(0.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
