import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

enum AppCardVariant { standard, carbon, selected }

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.variant = AppCardVariant.standard,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.onTap,
  });

  final Widget child;
  final AppCardVariant variant;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final dark = variant == AppCardVariant.carbon;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadii.card),
      side: BorderSide(
        color: variant == AppCardVariant.selected
            ? AppPalette.carbon
            : dark
            ? AppPalette.glassBorder
            : AppPalette.line,
      ),
    );
    final content = Padding(
      padding: padding,
      child: DefaultTextStyle.merge(
        style: TextStyle(color: dark ? AppPalette.white : AppPalette.carbon),
        child: IconTheme.merge(
          data: IconThemeData(
            color: dark ? AppPalette.white : AppPalette.carbon,
          ),
          child: child,
        ),
      ),
    );
    return Material(
      color: dark
          ? AppPalette.carbon
          : variant == AppCardVariant.selected
          ? AppPalette.surfaceSunken
          : AppPalette.white,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: onTap == null
          ? content
          : InkWell(onTap: onTap, customBorder: shape, child: content),
    );
  }
}
