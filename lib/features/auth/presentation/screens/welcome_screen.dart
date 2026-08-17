import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tailor_khata/core/theme/app_colors.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.tailorChalk, // The off-white background
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 3),

            // Logo / Icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(13), // ~0.05 * 255
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.content_cut_rounded,
                  size: 48,
                  color: AppColors.brassTape,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Title
            const Text(
              'Tailor Khata',
              style: TextStyle(
                fontFamily: 'Zilla Slab',
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: AppColors.charcoalThread,
              ),
            ),
            const SizedBox(height: 8),

            // Urdu Title
            const Text(
              'ٹیلر کھاتہ',
              style: TextStyle(
                fontFamily: 'Noto Nastaliq Urdu',
                fontSize: 22,
                color: AppColors.brassTape,
              ),
            ),
            const SizedBox(height: 4),

            // Subtitle
            const Text(
              'Simple & Easy To Use',
              style: TextStyle(
                fontFamily: 'Noto Sans',
                fontSize: 14,
                color: AppColors.inkMuted,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 48),

            // Buttons Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(8), // ~0.03 * 255
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color: AppColors.fabricGrey.withAlpha(128),
                  ),
                ),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brassTape,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () => context.go('/login'),
                        icon: const Icon(
                          Icons.login,
                          color: Colors.white,
                          size: 20,
                        ),
                        label: const Text(
                          'Login',
                          style: TextStyle(
                            fontFamily: 'Noto Sans',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.stitchNavy,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () => context.go('/home'),
                        icon: const Icon(
                          Icons.person_outline,
                          color: Colors.white,
                          size: 20,
                        ),
                        label: const Text(
                          'Continue as Guest',
                          style: TextStyle(
                            fontFamily: 'Noto Sans',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(flex: 4),

            // Version text
            Text(
              'TAILOR KHATA V1.0.0',
              style: TextStyle(
                fontFamily: 'Roboto Mono',
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                color: AppColors.inkMuted,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
