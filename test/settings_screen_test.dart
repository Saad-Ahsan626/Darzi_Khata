import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:tailor_khata/core/error/failures.dart';
import 'package:tailor_khata/core/routing/app_router.dart';
import 'package:tailor_khata/core/theme/app_theme.dart';
import 'package:tailor_khata/core/theme/design_tokens.dart';
import 'package:tailor_khata/features/measurements/domain/entities/measurement_unit.dart';
import 'package:tailor_khata/features/settings/domain/entities/shop_settings.dart';
import 'package:tailor_khata/features/settings/domain/repositories/shop_settings_repository.dart';
import 'package:tailor_khata/features/settings/presentation/providers/shop_settings_providers.dart';

/// Settings kept in memory, as the database would keep them.
class _Repository implements ShopSettingsRepository {
  _Repository(this.settings);
  ShopSettings settings;
  int saves = 0;

  @override
  Future<Either<Failure, ShopSettings>> getSettings() async => Right(settings);

  @override
  Future<Either<Failure, void>> updateSettings(ShopSettings settings) async {
    saves++;
    this.settings = settings;
    return const Right(null);
  }
}

const _hassan = ShopSettings(
  shopName: 'Hassan Tailors',
  ownerName: 'Imran Hassan',
  phone: '03008841120',
  address: 'Anarkali, Lahore',
  openingTime: '11:00',
  closingTime: '21:00',
  nextOrderNumber: 43,
);

Future<_Repository> _pump(
  WidgetTester tester, {
  ShopSettings settings = _hassan,
  String location = '/settings',
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final repository = _Repository(settings);
  final router = createAppRouter(initialLocation: location);
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [shopSettingsRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp.router(
        theme: AppTheme.lightTheme,
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return repository;
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Finder _field(String label) => find.descendant(
  of: find.byWidgetPredicate(
    (widget) => widget is Semantics && widget.properties.label == label,
  ),
  matching: find.byType(EditableText),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final font = FontLoader(AppTypography.fontFamily);
    for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      font.addFont(rootBundle.load('assets/fonts/inter/Inter-$weight.ttf'));
    }
    await font.load();
    final icons = FontLoader('MaterialIcons');
    icons.addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });

  testWidgets('shows the shop and its preferences', (tester) async {
    await _pump(tester);
    expect(find.text('Hassan Tailors'), findsOneWidget);
    expect(find.text('Imran Hassan · 0300 884 1120'), findsOneWidget);
    expect(find.text('Anarkali, Lahore'), findsOneWidget);
    expect(find.text('11:00 — 21:00'), findsOneWidget);
    expect(find.text('DK-'), findsOneWidget);
    expect(find.text('7 garments'), findsOneWidget);
    expect(find.text('Version 1.0.0 · works fully offline'), findsOneWidget);
  });

  testWidgets('a new shop is asked for its details', (tester) async {
    await _pump(tester, settings: const ShopSettings());
    expect(find.text('Name your shop'), findsOneWidget);
    expect(find.text('Add the owner and phone'), findsOneWidget);
    expect(find.text('Not set'), findsNWidgets(2));
  });

  testWidgets('the shop profile is edited and saved', (tester) async {
    final repository = await _pump(tester);
    await _tap(tester, find.text('Edit'));
    await tester.enterText(_field('Shop name'), 'Hassan & Sons');
    await tester.enterText(_field('Shop phone (optional)'), '0300');
    await tester.pumpAndSettle();
    expect(find.text('Needs 11 digits — 7 remaining'), findsOneWidget);
    await tester.enterText(_field('Shop phone (optional)'), '03001112222');
    await tester.pumpAndSettle();
    await _tap(tester, find.text('Save'));

    expect(repository.settings.shopName, 'Hassan & Sons');
    expect(repository.settings.phone, '03001112222');
    // Everything else is kept.
    expect(repository.settings.address, 'Anarkali, Lahore');
    expect(find.text('Hassan & Sons'), findsOneWidget);
    expect(find.text('Settings saved'), findsOneWidget);
  });

  testWidgets('the order prefix shows the next number as typed', (
    tester,
  ) async {
    final repository = await _pump(tester);
    await _tap(tester, find.text('Order number prefix'));
    await tester.enterText(_field('Prefix'), 'ht-');
    await tester.pumpAndSettle();
    expect(find.text('Next order: HT-0043'), findsOneWidget);
    await _tap(tester, find.text('Save'));
    expect(repository.settings.orderPrefix, 'HT-');
  });

  testWidgets('shop timings can be removed', (tester) async {
    final repository = await _pump(tester);
    await _tap(tester, find.text('Shop timings'));
    await _tap(tester, find.text('Remove timings'));
    expect(repository.settings.hasHours, isFalse);
    expect(find.text('Not set'), findsOneWidget);
  });

  testWidgets('cancelling an edit saves nothing', (tester) async {
    final repository = await _pump(tester);
    await _tap(tester, find.text('Shop address'));
    await tester.enterText(_field('Address'), 'Liberty Market');
    await _tap(tester, find.text('Cancel'));
    expect(repository.saves, 0);
  });

  testWidgets('the default unit is saved as soon as it is chosen', (
    tester,
  ) async {
    final repository = await _pump(tester);
    await _tap(tester, find.bySemanticsLabel('Centimeters'));
    expect(repository.settings.defaultUnit, MeasurementUnit.centimeters);
    expect(repository.settings.shopName, 'Hassan Tailors');
  });

  testWidgets('garment fields are listed for each garment', (tester) async {
    await _pump(tester);
    await _tap(tester, find.text('Garment fields'));
    expect(find.text('Shalwar Kameez'), findsOneWidget);
    expect(find.text('Kurta'), findsOneWidget);
  });

  test('copying settings keeps the order counter and can clear hours', () {
    final cleared = _hassan.copyWith(hours: () => null);
    expect(cleared.hasHours, isFalse);
    expect(cleared.nextOrderNumber, 43);
    final moved = _hassan.copyWith(
      hours: () => (opens: '10:00', closes: '20:00'),
    );
    expect((moved.openingTime, moved.closingTime), ('10:00', '20:00'));
    expect(_hassan.copyWith(address: 'Gulberg').openingTime, '11:00');
  });
}
