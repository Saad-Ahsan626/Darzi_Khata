import 'package:flutter/painting.dart';

import 'app_palette.dart';

/// Type scale from the JSON handoff, in Flutter logical pixels.
///
/// CSS tracking is expressed in em; Flutter letterSpacing is the font size
/// multiplied by that tracking value. Colors inherit from the consuming theme,
/// except support text, whose ink70 color is specified in the handoff.
/// Font asset registration belongs to the application theme integration.
abstract final class AppTypography {
  static const fontFamily = 'Inter';
  static const tabularFigures = <FontFeature>[FontFeature.tabularFigures()];

  static const display = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: 28 * -0.03,
    fontFeatures: tabularFigures,
  );

  static const title = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    letterSpacing: 22 * -0.025,
  );

  static const screenTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 23,
    fontWeight: FontWeight.w600,
    letterSpacing: 23 * -0.025,
  );

  /// Render section-label copy in uppercase at the widget layer.
  static const sectionLabel = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 11 * 0.1,
  );

  static const body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w500,
  );

  static final support = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppPalette.ink70,
  );

  static const micro = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w600,
  );

  static const numberLg = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    fontFeatures: tabularFigures,
  );

  static const numberMd = TextStyle(
    fontFamily: fontFamily,
    fontSize: 17,
    fontWeight: FontWeight.w700,
    fontFeatures: tabularFigures,
  );
}
