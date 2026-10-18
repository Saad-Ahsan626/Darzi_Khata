import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tailor_khata/core/providers/database_provider.dart';
import 'package:tailor_khata/features/auth/data/launch_preferences.dart';

final launchPreferencesProvider = Provider<LaunchPreferences>(
  (ref) => LaunchPreferences(),
);

/// Opens the local database, upgrading it if needed, and resolves to the
/// route the app shows after the splash: the welcome on first launch, the
/// shop's Home after that.
final startupRouteProvider = FutureProvider<String>((ref) async {
  await ref.watch(databaseProvider).database;
  final firstLaunch = await ref
      .watch(launchPreferencesProvider)
      .isFirstLaunch();
  return firstLaunch ? '/welcome' : '/home';
});
