import 'package:shared_preferences/shared_preferences.dart';

/// Remembers on this device whether the welcome and introduction have been
/// seen, so later launches open the shop directly.
class LaunchPreferences {
  /// The key earlier versions set once onboarding was done, kept so those
  /// installs also go straight to the shop.
  static const _firstLaunch = 'isFirstLaunch';

  Future<bool> isFirstLaunch() async =>
      (await SharedPreferences.getInstance()).getBool(_firstLaunch) ?? true;

  Future<void> markShopOpened() async =>
      (await SharedPreferences.getInstance()).setBool(_firstLaunch, false);
}
