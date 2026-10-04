import 'package:flutter/material.dart';
import 'package:tailor_khata/core/theme/design_tokens.dart';

class MeasurementChip extends StatelessWidget {
  final String labelEn;
  final String? value;
  final VoidCallback onTap;

  const MeasurementChip({
    super.key,
    required this.labelEn,
    this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null && value!.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppPalette.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasValue ? AppPalette.carbon : AppPalette.lineStrong,
            width: hasValue ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppPalette.carbon.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  labelEn,
                  style: const TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppPalette.carbon,
                  ),
                ),
                const SizedBox(width: 6),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              hasValue ? value! : 'Tap to add',
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontFeatures: hasValue ? AppTypography.tabularFigures : null,
                fontSize: hasValue ? 16 : 12,
                fontWeight: hasValue ? FontWeight.bold : FontWeight.normal,
                color: hasValue ? AppPalette.carbon : AppPalette.ink70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
