import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

OverlayEntry? _shownToast;

/// Confirms a save at the top of the screen: what changed, a detail line
/// such as the new balance, and an optional action like Undo that is offered
/// until the toast goes away. A newer toast replaces the one showing.
void showAppToast(
  BuildContext context, {
  required String message,
  String? detail,
  String? actionLabel,
  VoidCallback? onAction,
  Duration duration = const Duration(seconds: 5),
}) {
  assert((actionLabel == null) == (onAction == null));
  final overlay = Overlay.of(context, rootOverlay: true);
  _removeShownToast();
  late final OverlayEntry entry;
  void dismiss() {
    if (_shownToast == entry) _removeShownToast();
  }

  entry = OverlayEntry(
    builder: (context) => _Toast(
      message: message,
      detail: detail,
      actionLabel: actionLabel,
      onAction: onAction == null
          ? null
          : () {
              dismiss();
              onAction();
            },
      duration: duration,
      onDone: dismiss,
    ),
  );
  _shownToast = entry;
  overlay.insert(entry);
}

void _removeShownToast() {
  final entry = _shownToast;
  _shownToast = null;
  entry
    ?..remove()
    ..dispose();
}

class _Toast extends StatefulWidget {
  const _Toast({
    required this.message,
    required this.detail,
    required this.actionLabel,
    required this.onAction,
    required this.duration,
    required this.onDone,
  });

  final String message;
  final String? detail;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Duration duration;
  final VoidCallback onDone;

  @override
  State<_Toast> createState() => _ToastState();
}

class _ToastState extends State<_Toast> with SingleTickerProviderStateMixin {
  late final AnimationController _appear = AnimationController(
    vsync: this,
    duration: AppMotion.sheet,
  );
  late final _curve = CurvedAnimation(parent: _appear, curve: AppMotion.curve);
  Timer? _timer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_timer != null) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _appear.value = 1;
    } else {
      _appear.forward();
    }
    _timer = Timer(widget.duration, _hide);
  }

  Future<void> _hide() async {
    _timer?.cancel();
    if (!MediaQuery.disableAnimationsOf(context)) await _appear.reverse();
    if (mounted) widget.onDone();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _curve.dispose();
    _appear.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: AppSpacing.screenPadding,
      right: AppSpacing.screenPadding,
      top: MediaQuery.paddingOf(context).top + AppSpacing.md,
      child: FadeTransition(
        opacity: _curve,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, -0.4),
            end: Offset.zero,
          ).animate(_curve),
          // It covers the top of the screen, so a tap puts it away early.
          child: GestureDetector(
            onTap: _hide,
            child: Semantics(
              liveRegion: true,
              container: true,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppPalette.carbon.withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppPalette.carbon.withValues(alpha: 0.3),
                      offset: const Offset(0, 12),
                      blurRadius: 36,
                    ),
                  ],
                ),
                child: Material(
                  type: MaterialType.transparency,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(15, 13, 6, 13),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check,
                          size: 18,
                          color: AppPalette.white,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.message,
                                style: AppTypography.body.copyWith(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  fontFeatures: AppTypography.tabularFigures,
                                  color: AppPalette.white,
                                ),
                              ),
                              if (widget.detail case final detail?) ...[
                                const SizedBox(height: 2),
                                Text(
                                  detail,
                                  style: AppTypography.support.copyWith(
                                    fontSize: 11,
                                    fontFeatures: AppTypography.tabularFigures,
                                    color: AppPalette.onCarbonMuted,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (widget.actionLabel case final label?)
                          TextButton(
                            onPressed: widget.onAction,
                            style: TextButton.styleFrom(
                              foregroundColor: AppPalette.white,
                              minimumSize: const Size(
                                AppSizing.minHitTarget,
                                AppSizing.minHitTarget,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                              ),
                              textStyle: AppTypography.body.copyWith(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            child: Text(label),
                          )
                        else
                          const SizedBox(width: 9),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
