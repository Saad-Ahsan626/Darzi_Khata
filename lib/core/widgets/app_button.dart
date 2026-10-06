import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

enum AppButtonVariant { primary, outlined, olive, destructive, text }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final callback = isLoading ? null : onPressed;
    final motionStyle = ButtonStyle(
      animationDuration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : AppMotion.selection,
    );
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          const SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: AppSpacing.sm),
        ] else if (icon != null || variant == AppButtonVariant.destructive) ...[
          Icon(icon ?? Icons.delete_outline, size: 20),
          const SizedBox(width: AppSpacing.sm),
        ],
        Flexible(child: Text(isLoading ? '$label…' : label)),
      ],
    );
    final Widget button = switch (variant) {
      AppButtonVariant.primary => ElevatedButton(
        onPressed: callback,
        style: motionStyle,
        child: content,
      ),
      AppButtonVariant.olive => ElevatedButton(
        onPressed: callback,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppPalette.oliveFill14,
          foregroundColor: AppPalette.oliveInk,
          side: const BorderSide(color: AppPalette.oliveBorder),
        ).merge(motionStyle),
        child: content,
      ),
      AppButtonVariant.outlined || AppButtonVariant.destructive =>
        OutlinedButton(onPressed: callback, style: motionStyle, child: content),
      AppButtonVariant.text => TextButton(
        onPressed: callback,
        style: motionStyle,
        child: content,
      ),
    };
    return Semantics(
      liveRegion: isLoading,
      child: SizedBox(width: expand ? double.infinity : null, child: button),
    );
  }
}

class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) =>
      IconButton(tooltip: label, onPressed: onPressed, icon: Icon(icon));
}

/// A bordered 40px icon button for screen headers. Its touch target is still
/// the full minimum size.
class AppBoxedIconButton extends StatelessWidget {
  const AppBoxedIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.onCarbon = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  /// Draw for a carbon background instead of a light one.
  final bool onCarbon;

  static const _size = Size.square(40);

  /// The same look for other icon buttons, such as a menu button.
  static ButtonStyle styleOf({required bool onCarbon}) => IconButton.styleFrom(
    foregroundColor: onCarbon ? AppPalette.white : AppPalette.carbon,
    fixedSize: _size,
    minimumSize: _size,
    padding: EdgeInsets.zero,
    tapTargetSize: MaterialTapTargetSize.padded,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadii.control),
      side: BorderSide(
        color: onCarbon ? AppPalette.glassBorder : AppPalette.lineStrong,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: label,
    onPressed: onPressed,
    icon: Icon(icon, size: 20),
    style: styleOf(onCarbon: onCarbon),
  );
}
