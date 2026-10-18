import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:tailor_khata/core/app_info.dart';
import 'package:tailor_khata/core/theme/design_tokens.dart';
import 'package:tailor_khata/core/widgets/app_widgets.dart';
import 'package:tailor_khata/features/auth/presentation/widgets/sewn_button_mark.dart';

/// The first screen of a new install: what the app is, and the way in.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  static const _muted = Color.fromRGBO(255, 255, 255, 0.6);

  @override
  Widget build(BuildContext context) {
    final words = appName.split(' ');
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppPalette.carbon,
        body: Stack(
          children: [
            const Positioned.fill(
              child: AppTickPattern(color: Color(0x0EFFFFFF), spacing: 13),
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(28, 0, 28, 20),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 20,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 72),
                          const _Masthead(),
                          const Spacer(),
                          const SizedBox(height: 40),
                          Text(
                            words.join('\n'),
                            style: AppTypography.display.copyWith(
                              fontSize: 40,
                              height: 1.08,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 40 * -0.035,
                              color: AppPalette.white,
                            ),
                          ),
                          const SizedBox(height: 18),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 290),
                            child: Text(
                              'Customers, measurements, orders and balances '
                              '— kept precisely, kept on your phone. No '
                              'internet needed.',
                              style: AppTypography.body.copyWith(
                                fontSize: 15.5,
                                height: 1.55,
                                fontWeight: FontWeight.w400,
                                color: const Color.fromRGBO(
                                  255,
                                  255,
                                  255,
                                  0.66,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),
                          const IntrinsicHeight(
                            child: Row(
                              children: [
                                _Fact(value: '100%', label: 'offline'),
                                VerticalDivider(
                                  width: 37,
                                  color: AppPalette.glassBorder,
                                ),
                                _Fact(value: '4 taps', label: 'to a new order'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),
                          ElevatedButton(
                            onPressed: () => context.go('/onboarding'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppPalette.white,
                              foregroundColor: AppPalette.carbon,
                              overlayColor: AppPalette.carbon,
                              minimumSize: const Size.fromHeight(56),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              textStyle: AppTypography.body.copyWith(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 15.5 * -0.01,
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(child: Text('Continue to My Shop')),
                                SizedBox(width: 10),
                                Icon(Icons.arrow_forward, size: 19),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            'Your data stays on this device',
                            textAlign: TextAlign.center,
                            style: AppTypography.support.copyWith(
                              fontSize: 12,
                              color: _muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Masthead extends StatelessWidget {
  const _Masthead();

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: const Color.fromRGBO(255, 255, 255, 0.3),
            width: 1.5,
          ),
        ),
        alignment: Alignment.center,
        child: const SewnButtonMark.logo(size: 44),
      ),
      const SizedBox(width: 10),
      const Expanded(
        child: AppDashedLine(color: Color.fromRGBO(255, 255, 255, 0.3)),
      ),
      const SizedBox(width: 10),
      Text(
        'OFFLINE LEDGER',
        style: AppTypography.sectionLabel.copyWith(
          fontSize: 10,
          letterSpacing: 10 * 0.14,
          color: WelcomeScreen._muted,
        ),
      ),
    ],
  );
}

class _Fact extends StatelessWidget {
  const _Fact({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        value,
        style: AppTypography.numberMd.copyWith(
          fontSize: 19,
          color: AppPalette.white,
        ),
      ),
      const SizedBox(height: 2),
      Text(
        label,
        style: AppTypography.support.copyWith(
          fontSize: 11.5,
          color: const Color.fromRGBO(255, 255, 255, 0.5),
        ),
      ),
    ],
  );
}
