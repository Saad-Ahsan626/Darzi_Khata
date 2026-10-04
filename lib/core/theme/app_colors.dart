import 'design_tokens.dart';

/// Compatibility aliases for older presentation code.
/// New presentation code imports design_tokens.dart and uses AppPalette.
@Deprecated('Use AppPalette from core/theme/design_tokens.dart instead.')
abstract final class AppColors {
  static const charcoalThread = AppPalette.carbon;
  static const tailorChalk = AppPalette.white;
  static const chalkDeep = AppPalette.surfaceControl;
  static const brassTape = AppPalette.carbon;
  static const stitchNavy = AppPalette.carbon;
  static const seamRed = AppPalette.carbon;
  static const fabricGrey = AppPalette.lineStrong;
  static const inkMuted = AppPalette.ink70;
  static const inkSoft = AppPalette.ink70;
  static const ghost = AppPalette.ink70;
  static const greenOk = AppPalette.oliveInk;
  static const navyBg = AppPalette.surfaceControl;
  static const brassBg = AppPalette.surfaceControl;
  static const greenBg = AppPalette.surfaceSunken;
  static const greyBg = AppPalette.surfaceSunken;
}
