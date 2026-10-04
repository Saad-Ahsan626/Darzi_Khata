import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';
import 'glass_surface.dart';

class AppNavigationItem {
  const AppNavigationItem({required this.label, required this.icon});
  final String label;
  final IconData icon;
}

class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    this.blurEnabled = true,
  }) : assert(items.length > 1),
       assert(selectedIndex >= 0 && selectedIndex < items.length);

  final List<AppNavigationItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final bool blurEnabled;

  @override
  Widget build(BuildContext context) => GlassSurface(
    blurEnabled: blurEnabled,
    radius: AppRadii.sheet,
    padding: const EdgeInsets.all(AppSpacing.sm),
    shadows: AppShadows.navigation,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(items.length, (index) {
        final selected = index == selectedIndex;
        final item = items[index];
        return Expanded(
          child: Semantics(
            selected: selected,
            button: true,
            label: item.label,
            child: Tooltip(
              message: item.label,
              child: Material(
                color: selected ? AppPalette.carbon : Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadii.icon),
                animateColor: true,
                animationDuration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : AppMotion.selection,
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadii.icon),
                  focusColor: selected
                      ? AppPalette.glassBorder
                      : AppPalette.oliveFill14,
                  onTap: () => onSelected(index),
                  child: AnimatedContainer(
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : AppMotion.selection,
                    curve: AppMotion.curve,
                    constraints: const BoxConstraints(
                      minHeight: AppSizing.minHitTarget,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadii.icon),
                    ),
                    child: ExcludeSemantics(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            item.icon,
                            size: 22,
                            color: selected
                                ? AppPalette.white
                                : AppPalette.ink70,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            item.label,
                            textAlign: TextAlign.center,
                            style: AppTypography.micro.copyWith(
                              color: selected
                                  ? AppPalette.white
                                  : AppPalette.ink70,
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    ),
  );
}
