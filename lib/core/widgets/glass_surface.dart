import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

enum GlassTone { light, dark }

/// Bounded blur with an explicit solid fallback. Use opaque cards for forms.
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.tone = GlassTone.light,
    this.blurEnabled = true,
    this.radius = AppRadii.card,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.shadows = const [],
  });

  final Widget child;
  final GlassTone tone;
  final bool blurEnabled;
  final double radius;
  final EdgeInsetsGeometry padding;
  final List<BoxShadow> shadows;

  @override
  Widget build(BuildContext context) {
    final dark = tone == GlassTone.dark;
    final useBlur = blurEnabled && !MediaQuery.highContrastOf(context);
    final borderRadius = BorderRadius.circular(radius);
    final surface = DecoratedBox(
      decoration: BoxDecoration(
        color: useBlur
            ? dark
                  ? AppPalette.glassOnCarbon
                  : AppPalette.glassLight
            : dark
            ? AppGlass.darkFallback
            : AppGlass.lightFallback,
        borderRadius: borderRadius,
        border: Border.all(
          color: dark ? AppPalette.glassBorder : AppPalette.line,
        ),
      ),
      child: Padding(
        padding: padding,
        child: DefaultTextStyle.merge(
          style: TextStyle(color: dark ? AppPalette.white : AppPalette.carbon),
          child: child,
        ),
      ),
    );
    return DecoratedBox(
      decoration: BoxDecoration(borderRadius: borderRadius, boxShadow: shadows),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: useBlur
            ? BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: AppGlass.blurSigma,
                  sigmaY: AppGlass.blurSigma,
                ),
                child: surface,
              )
            : surface,
      ),
    );
  }
}
