import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The current time. Tests override it to fix the date.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);
