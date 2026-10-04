import 'package:flutter/painting.dart';

/// Palette from the Tailor Khata design handoff.
///
/// Carbon, white, and grey olive are the three base colors. The remaining
/// values are the handoff's derived tones and translucent surfaces.
abstract final class AppPalette {
  static const carbon = Color(0xFF171918);
  static const white = Color(0xFFFFFFFF);

  /// Use for accents and fills, rather than small text on white.
  static const greyOlive = Color(0xFF7C8070);

  static const oliveInk = Color(0xFF2F332C);
  static const oliveInkAlt = Color(0xFF5A5E51);
  static const surfaceSunken = Color(0xFFF6F6F3);
  static const surfaceControl = Color(0xFFF0F0ED);

  static final ink70 = carbon.withValues(alpha: 0.70);
  static final ink55 = carbon.withValues(alpha: 0.55);
  static final ink45 = carbon.withValues(alpha: 0.45);
  static final line = carbon.withValues(alpha: 0.10);
  static final lineStrong = carbon.withValues(alpha: 0.18);
  static final oliveFill10 = greyOlive.withValues(alpha: 0.10);
  static final oliveFill14 = greyOlive.withValues(alpha: 0.14);
  static final oliveBorder = greyOlive.withValues(alpha: 0.34);
  static final glassLight = white.withValues(alpha: 0.72);
  static final glassOnCarbon = white.withValues(alpha: 0.10);
  static final glassBorder = white.withValues(alpha: 0.18);
}
