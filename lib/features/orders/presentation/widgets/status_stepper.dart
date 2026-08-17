import 'package:flutter/material.dart';
import 'package:tailor_khata/core/theme/app_colors.dart';

class StatusStepper extends StatelessWidget {
  final String currentStatus;
  final ValueChanged<String> onStatusChanged;

  const StatusStepper({
    super.key,
    required this.currentStatus,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    const statuses = [
      {'en': 'Received', 'ur': 'وصول کیا'},
      {'en': 'Cutting', 'ur': 'کٹنگ'},
      {'en': 'Stitching', 'ur': 'سلائی'},
      {'en': 'Ready', 'ur': 'تیار'},
      {'en': 'Delivered', 'ur': 'ڈیلیورڈ'},
    ];

    final currentIndex = statuses.indexWhere((s) => s['en'] == currentStatus);

    return Column(
      children: List.generate(statuses.length, (index) {
        final status = statuses[index];
        final isCompletedOrCurrent = index <= currentIndex;
        final isCurrent = index == currentIndex;

        return GestureDetector(
          onTap: currentStatus == 'Delivered' ? null : () => onStatusChanged(status['en']!),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isCurrent ? AppColors.chalkDeep : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isCurrent ? AppColors.brassTape : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompletedOrCurrent
                        ? AppColors.brassTape
                        : Colors.transparent,
                    border: Border.all(
                      color: isCompletedOrCurrent
                          ? AppColors.brassTape
                          : AppColors.fabricGrey,
                      width: 2,
                    ),
                  ),
                  child: isCompletedOrCurrent
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    status['en']!,
                    style: TextStyle(
                      fontFamily: 'Noto Sans',
                      fontSize: 16,
                      fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w500,
                      color: AppColors.charcoalThread,
                    ),
                  ),
                ),
                Text(
                  status['ur']!,
                  style: TextStyle(
                    fontFamily: 'Noto Nastaliq Urdu',
                    fontSize: 16,
                    fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w400,
                    color: AppColors.charcoalThread,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
