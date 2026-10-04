import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';
import 'app_button.dart';

class AppFeedback extends StatelessWidget {
  const AppFeedback({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
  }) : assert((actionLabel == null) == (onAction == null));

  const AppFeedback.error({
    super.key,
    this.title = 'Something went wrong',
    required this.message,
    this.actionLabel,
    this.onAction,
  }) : icon = Icons.error_outline,
       assert((actionLabel == null) == (onAction == null));

  final String title;
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(AppSpacing.xl),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 36, color: AppPalette.oliveInk),
        const SizedBox(height: AppSpacing.lg),
        Text(title, style: AppTypography.title, textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.sm),
        Text(
          message,
          style: AppTypography.support,
          textAlign: TextAlign.center,
        ),
        if (onAction != null) ...[
          const SizedBox(height: AppSpacing.xl),
          AppButton(label: actionLabel!, onPressed: onAction),
        ],
      ],
    ),
  );
}

class AppLoading extends StatelessWidget {
  const AppLoading({super.key, this.label = 'Loading…'});
  final String label;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox.square(
            dimension: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(label, style: AppTypography.support),
        ],
      ),
    ),
  );
}
