import 'package:flutter/animation.dart';

/// Animation specifications; widgets must honor reduced-motion preferences.
abstract final class AppMotion {
  static const selection = Duration(milliseconds: 180);
  static const sheet = Duration(milliseconds: 220);
  static const page = Duration(milliseconds: 250);
  static const splash = Duration(milliseconds: 1400);
  static const curve = Curves.easeOutCubic;
}
