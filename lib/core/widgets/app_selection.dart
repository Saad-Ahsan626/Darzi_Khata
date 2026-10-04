import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

class AppSelectionChip extends StatelessWidget {
  const AppSelectionChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    child: OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: selected ? AppPalette.carbon : AppPalette.white,
        foregroundColor: selected ? AppPalette.white : AppPalette.carbon,
        side: BorderSide(color: selected ? AppPalette.carbon : AppPalette.line),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        animationDuration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : AppMotion.selection,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
      ),
      child: Text(label),
    ),
  );
}

class AppSelectionOption<T> {
  const AppSelectionOption({required this.value, required this.label});
  final T value;
  final String label;
}

class AppSegmentedControl<T> extends StatelessWidget {
  const AppSegmentedControl({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
  }) : assert(options.length > 1);

  final List<AppSelectionOption<T>> options;
  final T selected;
  final ValueChanged<T>? onChanged;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: AppPalette.surfaceControl,
      borderRadius: BorderRadius.circular(AppRadii.card),
    ),
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.xs),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked =
              MediaQuery.textScalerOf(context).scale(15) > 20 ||
              constraints.maxWidth / options.length < 120;
          final children = options
              .map(
                (option) => Semantics(
                  selected: option.value == selected,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: option.value == selected
                          ? AppPalette.carbon
                          : Colors.transparent,
                      foregroundColor: option.value == selected
                          ? AppPalette.white
                          : AppPalette.ink70,
                      animationDuration: MediaQuery.disableAnimationsOf(context)
                          ? Duration.zero
                          : AppMotion.selection,
                    ),
                    onPressed: onChanged == null
                        ? null
                        : () => onChanged!(option.value),
                    child: Text(option.label, textAlign: TextAlign.center),
                  ),
                ),
              )
              .toList();
          return stacked
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: children,
                )
              : Row(
                  children: children
                      .map((child) => Expanded(child: child))
                      .toList(),
                );
        },
      ),
    ),
  );
}
