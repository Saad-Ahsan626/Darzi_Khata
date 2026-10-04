import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tailor_khata/core/theme/design_tokens.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNext() async {
    if (_currentPage == 2) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isFirstLaunch', false);
      if (mounted) {
        context.go('/welcome');
      }
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  _buildPage(
                    iconWidget: const Icon(
                      Icons.content_cut_rounded,
                      size: 150,
                      color: AppPalette.lineStrong,
                    ),
                    titleEn: 'Digital Measurements',
                    descEn:
                        'Record measurements once on a digital model. Find them instantly the next time your customer visits.',
                  ),
                  _buildPage(
                    iconWidget: _buildFakeOrderCard(),
                    titleEn: 'Track Every Order',
                    descEn:
                        'Never miss a delivery date. Track every suit from cutting to delivery with real-time status updates.',
                  ),
                  _buildPage(
                    imagePath: 'assets/on_boarding/3rd.png',
                    titleEn: 'Works Fully Offline',
                    descEn:
                        'Your data stays on your device. Manage your shop anywhere, even without internet. Secure and private.',
                  ),
                ],
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildFakeOrderCard() {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppPalette.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppPalette.lineStrong),
        boxShadow: [
          BoxShadow(
            color: AppPalette.carbon.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ORD-7892',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontWeight: FontWeight.bold,
                  color: AppPalette.carbon,
                ),
              ),
              Icon(Icons.more_vert, size: 20, color: AppPalette.ink70),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Ali Hassan',
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 12,
              color: AppPalette.ink70,
            ),
          ),
          const SizedBox(height: 16),
          // Dashed line or dots
          Row(
            children: List.generate(
              15,
              (index) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Container(height: 1, color: AppPalette.lineStrong),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildFakeChip('Cutting', Icons.content_cut, true),
              _buildFakeChip('Stitching', Icons.crop_portrait, true, true),
              _buildFakeChip('Ready', Icons.check_circle_outline, false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFakeChip(
    String text,
    IconData icon,
    bool isActive, [
    bool isCurrent = false,
  ]) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: isCurrent
            ? AppPalette.carbon.withAlpha(51)
            : isActive
            ? AppPalette.lineStrong.withAlpha(128)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive || isCurrent
              ? Colors.transparent
              : AppPalette.lineStrong.withAlpha(128),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: isCurrent
                ? AppPalette.carbon
                : isActive
                ? AppPalette.carbon
                : AppPalette.lineStrong,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: isCurrent
                  ? AppPalette.carbon
                  : isActive
                  ? AppPalette.carbon
                  : AppPalette.lineStrong,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage({
    Widget? iconWidget,
    String? imagePath,
    required String titleEn,
    required String descEn,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (iconWidget != null)
            Container(
              height: 250,
              alignment: Alignment.center,
              child: iconWidget,
            )
          else if (imagePath != null)
            Container(
              height: 250,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: DecorationImage(
                  image: AssetImage(imagePath),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          const SizedBox(height: 48),
          Text(
            titleEn,
            style: const TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppPalette.carbon,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            descEn,
            style: const TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 12,
              color: AppPalette.carbon,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            children: List.generate(
              11,
              (index) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Container(height: 1, color: AppPalette.lineStrong),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) {
              final isCurrent = index == _currentPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 8,
                width: isCurrent ? 24 : 8,
                decoration: BoxDecoration(
                  color: isCurrent ? AppPalette.carbon : AppPalette.lineStrong,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppPalette.carbon,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              onPressed: _onNext,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _currentPage == 2 ? 'Get Started' : 'Next',
                    style: const TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppPalette.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward,
                    size: 20,
                    color: AppPalette.white,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
