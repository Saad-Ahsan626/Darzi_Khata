import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tailor_khata/core/theme/design_tokens.dart';
import 'package:tailor_khata/core/widgets/app_widgets.dart';
import 'package:tailor_khata/features/auth/presentation/providers/startup_provider.dart';
import 'package:tailor_khata/features/auth/presentation/widgets/sewn_button_mark.dart';

/// The cold-start frame: the button mark is sewn on while the local records
/// open, then the app hands off to onboarding or the welcome screen.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  // The sequence is 1.2s of drawing followed by a 0.2s fade to the next
  // screen. It never waits longer than the records take to open.
  static const _total = 1400;
  static const _drawn = 1200 / _total;
  static const _sewing = Cubic(0.3, 0.7, 0.2, 1);
  static const _rising = Cubic(0.2, 0.8, 0.2, 1);

  /// The rim already shows this much of its circle on the first frame.
  static const _rimStart = 0.246;

  /// The progress sweep appears only if opening takes longer than this.
  static const _slowAfter = Duration(milliseconds: 400);

  late final _sequence = AnimationController(
    vsync: this,
    duration: AppMotion.splash,
  );
  late final _sweep = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  late final _ticks = _part(0, 280, Curves.easeOut);
  late final _rim = _part(0, 800, _sewing);
  late final _title = _part(440, 710, _rising);
  late final _label = _part(670, 900, Curves.easeOut);
  late final _holes = _part(710, 940, Curves.easeOut);
  late final _firstStitch = _part(880, 1100, _sewing);
  late final _secondStitch = _part(970, 1200, _sewing);
  late final _handOff = _part(1200, _total, Curves.easeOut);

  Timer? _slowTimer;
  bool _started = false;
  bool _slow = false;
  Object? _error;

  Animation<double> _part(int startMs, int endMs, Curve curve) =>
      CurvedAnimation(
        parent: _sequence,
        curve: Interval(startMs / _total, endMs / _total, curve: curve),
      );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _open(animate: !MediaQuery.disableAnimationsOf(context));
  }

  Future<void> _open({required bool animate}) async {
    _slowTimer = Timer(_slowAfter, () {
      if (!mounted || ref.read(startupRouteProvider).hasValue) return;
      setState(() => _slow = true);
      _sweep.repeat();
    });

    try {
      if (animate) {
        await _sequence.animateTo(_drawn).orCancel;
      } else {
        // Reduced motion shows the finished mark straight away.
        _sequence.value = _drawn;
      }
      final route = await ref.read(startupRouteProvider.future);
      _slowTimer?.cancel();
      if (!mounted) return;
      if (animate) await _sequence.forward().orCancel;
      if (mounted) context.go(route);
    } on TickerCanceled {
      // The screen was closed mid-animation.
    } catch (error) {
      _slowTimer?.cancel();
      if (!mounted) return;
      _sweep.stop();
      setState(() {
        _slow = false;
        _error = error;
      });
    }
  }

  void _retry() {
    setState(() => _error = null);
    ref.invalidate(startupRouteProvider);
    // The mark is already drawn, so a retry only waits for the records.
    _open(animate: false);
  }

  @override
  void dispose() {
    _slowTimer?.cancel();
    _sequence.dispose();
    _sweep.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppPalette.carbon,
        body: AnimatedBuilder(
          animation: _sequence,
          builder: (context, _) => Opacity(
            opacity: 1 - _handOff.value,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Opacity(
                  opacity: 0.55 * _ticks.value,
                  child: const AppTickPattern(
                    color: Color(0x0DFFFFFF),
                    spacing: 13,
                  ),
                ),
                Center(child: _buildMark()),
                Positioned(
                  left: AppSpacing.screenPadding,
                  right: AppSpacing.screenPadding,
                  bottom: 62,
                  child: SafeArea(top: false, child: _buildFooter()),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMark() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SewnButtonMark(
          rim: _rimStart + (1 - _rimStart) * _rim.value,
          holes: _holes.value,
          firstStitch: _firstStitch.value,
          secondStitch: _secondStitch.value,
        ),
        const SizedBox(height: 34),
        _Rising(
          amount: _title.value,
          distance: 12,
          child: const Text(
            'Tailor Khata',
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 30,
              fontWeight: FontWeight.w600,
              letterSpacing: 30 * -0.03,
              color: AppPalette.white,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _Rising(
          amount: _label.value,
          distance: 8,
          child: const Text(
            'OFFLINE LEDGER',
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              letterSpacing: 12.5 * 0.14,
              color: Color(0x8CFFFFFF),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    if (_error != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Couldn't open your records. Please try again.",
            textAlign: TextAlign.center,
            style: AppTypography.support.copyWith(
              color: AppPalette.onCarbonMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          OutlinedButton(
            onPressed: _retry,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppPalette.white,
              side: const BorderSide(color: AppPalette.glassBorder),
            ),
            child: const Text('Try again'),
          ),
        ],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Space is kept for the sweep so the caption does not move.
        SizedBox(
          width: 120,
          height: 2,
          child: _slow ? _ProgressSweep(animation: _sweep) : null,
        ),
        const SizedBox(height: AppSpacing.lg),
        const Text(
          'Opening your records · v1.0.0',
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontFeatures: AppTypography.tabularFigures,
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Color(0x9EFFFFFF),
          ),
        ),
      ],
    );
  }
}

/// Fades its child in while it rises [distance] pixels into place.
class _Rising extends StatelessWidget {
  const _Rising({
    required this.amount,
    required this.distance,
    required this.child,
  });

  final double amount;
  final double distance;
  final Widget child;

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: amount,
    child: Transform.translate(
      offset: Offset(0, distance * (1 - amount)),
      child: child,
    ),
  );
}

/// A short bar that travels along a track while the records are opening.
class _ProgressSweep extends StatelessWidget {
  const _ProgressSweep({required this.animation});
  final Animation<double> animation;

  static const _barWidth = 44.0;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Opening your records',
    child: ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: ColoredBox(
        color: const Color(0x24FFFFFF),
        child: AnimatedBuilder(
          animation: animation,
          builder: (context, child) => Align(
            alignment: Alignment.centerLeft,
            child: Transform.translate(
              // From just off the left edge to just off the right.
              offset: Offset(
                _barWidth *
                    (-1.1 +
                        3.7 * Curves.easeInOut.transform(animation.value)),
                0,
              ),
              child: child,
            ),
          ),
          child: const SizedBox(
            width: _barWidth,
            height: 2,
            child: ColoredBox(color: Color(0xCCFFFFFF)),
          ),
        ),
      ),
    ),
  );
}
