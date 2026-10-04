import 'package:flutter/material.dart';
import 'package:tailor_khata/core/theme/design_tokens.dart';

class OrderFilterTabs extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const OrderFilterTabs({
    super.key,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const tabs = ['All', 'Today', 'This Week', 'Overdue'];

    return Container(
      color: AppPalette.carbon,
      width: double.infinity,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: List.generate(tabs.length, (index) {
            final isActive = selectedIndex == index;
            return GestureDetector(
              onTap: () => onChanged(index),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isActive
                          ? AppPalette.greyOlive
                          : Colors.transparent,
                      width: 3,
                    ),
                  ),
                ),
                child: Text(
                  tabs[index],
                  style: TextStyle(
                    color: isActive
                        ? AppPalette.white
                        : AppPalette.onCarbonMuted,
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 14,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
