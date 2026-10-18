import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tailor_khata/core/app_info.dart';
import 'package:tailor_khata/core/providers/database_provider.dart';
import 'package:tailor_khata/core/routing/app_router.dart';
import 'package:tailor_khata/core/theme/app_theme.dart';
import 'package:tailor_khata/core/theme/design_tokens.dart';
import 'package:tailor_khata/features/auth/data/launch_preferences.dart';
import 'package:tailor_khata/features/auth/presentation/providers/startup_provider.dart';
import 'package:tailor_khata/features/customers/domain/entities/customer.dart';
import 'package:tailor_khata/features/customers/presentation/providers/customers_notifier.dart';
import 'package:tailor_khata/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:tailor_khata/features/orders/domain/entities/order.dart';
import 'package:tailor_khata/features/orders/domain/entities/payment.dart';
import 'package:tailor_khata/features/orders/presentation/providers/orders_notifier.dart';
import 'package:tailor_khata/features/settings/domain/entities/shop_settings.dart';
import 'package:tailor_khata/features/settings/presentation/providers/shop_settings_providers.dart';

import 'support/database_test_support.dart';

/// Launch state held in memory.
class _Launch extends LaunchPreferences {
  _Launch({this.firstLaunch = true});
  bool firstLaunch;

  @override
  Future<bool> isFirstLaunch() async => firstLaunch;

  @override
  Future<void> markShopOpened() async => firstLaunch = false;
}

class _Customers extends CustomersNotifier {
  @override
  Future<List<Customer>> build() async => const [];
}

class _Orders extends OrdersNotifier {
  @override
  Future<List<Order>> build() async => const [];
}

Future<_Launch> _pump(WidgetTester tester, String location) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final launch = _Launch();
  final router = createAppRouter(initialLocation: location);
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        launchPreferencesProvider.overrideWithValue(launch),
        customersNotifierProvider.overrideWith(_Customers.new),
        ordersNotifierProvider.overrideWith(_Orders.new),
        paymentsProvider.overrideWith((ref) async => const <Payment>[]),
        shopSettingsProvider.overrideWith((ref) => const ShopSettings()),
      ],
      child: MaterialApp.router(
        theme: AppTheme.lightTheme,
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return launch;
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    useDesktopDatabases();
    final font = FontLoader(AppTypography.fontFamily);
    for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      font.addFont(rootBundle.load('assets/fonts/inter/Inter-$weight.ttf'));
    }
    await font.load();
    final icons = FontLoader('MaterialIcons');
    icons.addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });

  group('after the splash', () {
    Future<String> routeFor(LaunchPreferences launch) async {
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(await openTestDatabase()),
          launchPreferencesProvider.overrideWithValue(launch),
        ],
      );
      addTearDown(container.dispose);
      return container.read(startupRouteProvider.future);
    }

    test('a new install opens on the welcome', () async {
      expect(await routeFor(_Launch()), '/welcome');
    });

    test(
      'once the shop has been opened, launches go straight to Home',
      () async {
        expect(await routeFor(_Launch(firstLaunch: false)), '/home');
      },
    );
  });

  group('launch preferences', () {
    test('a new install is a first launch until the shop is opened', () async {
      SharedPreferences.setMockInitialValues({});
      final launch = LaunchPreferences();
      expect(await launch.isFirstLaunch(), isTrue);
      await launch.markShopOpened();
      expect(await launch.isFirstLaunch(), isFalse);
    });

    test(
      'installs that finished the old introduction skip the welcome',
      () async {
        SharedPreferences.setMockInitialValues({'isFirstLaunch': false});
        expect(await LaunchPreferences().isFirstLaunch(), isFalse);
      },
    );
  });

  testWidgets('the welcome leads into the introduction', (tester) async {
    await _pump(tester, '/welcome');
    expect(find.text(appName.replaceAll(' ', '\n')), findsOneWidget);
    expect(find.text('Your data stays on this device'), findsOneWidget);
    await _tap(tester, find.text('Continue to My Shop'));
    expect(find.text('01 — MEASUREMENTS'), findsOneWidget);
    expect(find.text('1 of 3'), findsOneWidget);
  });

  testWidgets('the introduction pages forward and back, then opens Home', (
    tester,
  ) async {
    final launch = await _pump(tester, '/onboarding');
    // No way back from the first page.
    expect(find.byTooltip('Back'), findsNothing);

    await _tap(tester, find.text('Next'));
    expect(find.text('02 — PRODUCTION'), findsOneWidget);
    await _tap(tester, find.byTooltip('Back'));
    expect(find.text('01 — MEASUREMENTS'), findsOneWidget);

    await _tap(tester, find.text('Next'));
    await _tap(tester, find.text('Next'));
    expect(find.text('3 of 3'), findsOneWidget);
    // Skip is retired where the main button does the same.
    expect(
      tester
          .widget<TextButton>(
            find.ancestor(
              of: find.text('Skip'),
              matching: find.byType(TextButton),
            ),
          )
          .onPressed,
      isNull,
    );
    expect(launch.firstLaunch, isTrue);

    await _tap(tester, find.text('Continue to My Shop'));
    expect(launch.firstLaunch, isFalse);
    expect(find.byType(DashboardScreen), findsOneWidget);
  });

  testWidgets('skipping the introduction also opens the shop', (tester) async {
    final launch = await _pump(tester, '/onboarding');
    await _tap(tester, find.text('Skip'));
    expect(launch.firstLaunch, isFalse);
    expect(find.byType(DashboardScreen), findsOneWidget);
  });
}
