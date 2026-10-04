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

  static const ink70 = Color.fromRGBO(23, 25, 24, 0.70);
  static const ink55 = Color.fromRGBO(23, 25, 24, 0.55);
  static const ink45 = Color.fromRGBO(23, 25, 24, 0.45);
  static const line = Color.fromRGBO(23, 25, 24, 0.10);
  static const lineStrong = Color.fromRGBO(23, 25, 24, 0.18);
  static const oliveFill10 = Color.fromRGBO(124, 128, 112, 0.10);
  static const oliveFill14 = Color.fromRGBO(124, 128, 112, 0.14);
  static const oliveBorder = Color.fromRGBO(124, 128, 112, 0.34);
  static const glassLight = Color.fromRGBO(255, 255, 255, 0.72);
  static const glassOnCarbon = Color.fromRGBO(255, 255, 255, 0.10);
  static const glassBorder = Color.fromRGBO(255, 255, 255, 0.18);

  /// Supporting text on carbon surfaces; ink70 is for light surfaces.
  static const onCarbonMuted = Color.fromRGBO(255, 255, 255, 0.70);
}
