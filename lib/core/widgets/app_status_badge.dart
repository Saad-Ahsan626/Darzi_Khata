import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

enum AppBadgeTone { outline, olive, strong, muted }

/// Labels and icons convey meaning; features choose the status and tone.
class AppStatusBadge extends StatelessWidget {
  const AppStatusBadge({
    super.key,
    required this.label,
    this.icon,
    this.tone = AppBadgeTone.outline,
  });

  final String label;
  final IconData? icon;
  final AppBadgeTone tone;

  @override
  Widget build(BuildContext context) {
    final strong = tone == AppBadgeTone.strong;
    final color = strong
        ? AppPalette.white
        : tone == AppBadgeTone.olive
        ? AppPalette.oliveInk
        : tone == AppBadgeTone.muted
        ? AppPalette.ink70
        : AppPalette.carbon;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: strong
            ? AppPalette.carbon
            : tone == AppBadgeTone.olive
            ? AppPalette.oliveFill14
            : AppPalette.white,
        borderRadius: BorderRadius.circular(AppRadii.control / 2),
        border: Border.all(
          color: tone == AppBadgeTone.olive
              ? AppPalette.oliveBorder
              : AppPalette.lineStrong,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: color),
              const SizedBox(width: AppSpacing.xs),
            ],
            Flexible(
              child: Text(
                label.toUpperCase(),
                style: AppTypography.micro.copyWith(color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
