import 'package:flutter/painting.dart';

import 'app_palette.dart';

/// Glass specification from the JSON export. These values do not apply an
/// effect themselves; future presentation widgets own clipping and filtering.
abstract final class AppGlass {
  static const blurSigma = 20.0;

  /// CSS saturation reference; Flutter blur alone does not apply saturation.
  static const saturation = 1.3;

  static const lightFallback = AppPalette.white;
  static const darkFallback = AppPalette.carbon;
}

/// Shared surface shadows drawn from the HTML reference rather than gallery
/// frame shadows. Flutter blur rendering should be checked during UI integration.
abstract final class AppShadows {
  static final selection = List<BoxShadow>.unmodifiable([
    BoxShadow(
      color: AppPalette.carbon.withValues(alpha: 0.10),
      offset: const Offset(0, 1),
      blurRadius: 4,
    ),
  ]);

  static final navigation = List<BoxShadow>.unmodifiable([
    BoxShadow(
      color: AppPalette.carbon.withValues(alpha: 0.14),
      offset: const Offset(0, 10),
      blurRadius: 32,
    ),
  ]);

  static final sheet = List<BoxShadow>.unmodifiable([
    BoxShadow(
      color: AppPalette.carbon.withValues(alpha: 0.34),
      offset: const Offset(0, -16),
      blurRadius: 60,
    ),
  ]);

  static final modal = List<BoxShadow>.unmodifiable([
    BoxShadow(
      color: AppPalette.carbon.withValues(alpha: 0.40),
      offset: const Offset(0, 24),
      blurRadius: 70,
    ),
  ]);
}
