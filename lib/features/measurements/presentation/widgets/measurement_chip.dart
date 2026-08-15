import 'package:flutter/material.dart';
import 'package:tailor_khata/core/theme/app_colors.dart';

class MeasurementChip extends StatelessWidget {
  final String labelEn;
  final String labelUr;
  final String? value;
  final VoidCallback onTap;

  const MeasurementChip({
    super.key,
    required this.labelEn,
    required this.labelUr,
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasValue ? AppColors.brassTape : AppColors.fabricGrey,
            width: hasValue ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
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
                    fontFamily: 'Noto Sans',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.charcoalThread,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  labelUr,
                  style: const TextStyle(
                    fontFamily: 'Noto Nastaliq Urdu',
                    fontSize: 12,
                    color: AppColors.inkMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              hasValue ? value! : 'Tap to add',
              style: TextStyle(
                fontFamily: hasValue ? 'Roboto Mono' : 'Noto Sans',
                fontSize: hasValue ? 16 : 12,
                fontWeight: hasValue ? FontWeight.bold : FontWeight.normal,
                color: hasValue ? AppColors.charcoalThread : AppColors.ghost,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
