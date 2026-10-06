import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tailor_khata/core/providers/database_provider.dart';

/// Opens the local database, upgrading it if needed, and resolves to the
/// route the app shows after the splash.
final startupRouteProvider = FutureProvider<String>((ref) async {
  await ref.watch(databaseProvider).database;
  final prefs = await SharedPreferences.getInstance();
  final isFirstLaunch = prefs.getBool('isFirstLaunch') ?? true;
  return isFirstLaunch ? '/onboarding' : '/welcome';
});
