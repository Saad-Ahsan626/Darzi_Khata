import 'package:flutter/painting.dart';

/// Spacing in logical pixels, including the handoff's half-step increments.
abstract final class AppSpacing {
  static const base = 8.0;
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const xxxl = 40.0;
  static const scale = <double>[xs, sm, md, lg, xl, xxl, xxxl];

  static const screenPadding = 20.0;
  static const gutter = 12.0;
}

/// Corner radii in logical pixels.
abstract final class AppRadii {
  static const control = 12.0;
  static const card = 18.0;
  static const sheet = 28.0;
  static const pill = 999.0;
  static const icon = 21.0;
}

abstract final class AppSizing {
  static const minHitTarget = 48.0;

  /// Reference dimensions for visual comparison, not fixed screen constraints.
  static const referenceViewport = Size(390, 844);
  static const referenceMinWidth = 360.0;
}
