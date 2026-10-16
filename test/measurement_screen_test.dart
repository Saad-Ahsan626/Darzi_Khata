import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tailor_khata/core/providers/clock_provider.dart';
import 'package:tailor_khata/core/routing/app_router.dart';
import 'package:tailor_khata/core/theme/app_theme.dart';
import 'package:tailor_khata/core/theme/design_tokens.dart';
import 'package:tailor_khata/features/customers/domain/entities/customer.dart';
import 'package:tailor_khata/features/customers/presentation/providers/customers_notifier.dart';
import 'package:tailor_khata/features/customers/presentation/screens/customer_detail_screen.dart';
import 'package:tailor_khata/features/measurements/domain/entities/fit_profile.dart';
import 'package:tailor_khata/features/measurements/domain/entities/measurement.dart';
import 'package:tailor_khata/features/measurements/domain/entities/measurement_unit.dart';
import 'package:tailor_khata/features/measurements/presentation/providers/measurements_notifier.dart';
import 'package:tailor_khata/features/measurements/presentation/screens/measurement_screen.dart';
import 'package:tailor_khata/features/orders/domain/entities/order.dart';
import 'package:tailor_khata/features/orders/presentation/providers/orders_notifier.dart';
import 'package:tailor_khata/features/settings/domain/entities/shop_settings.dart';
import 'package:tailor_khata/features/settings/presentation/providers/shop_settings_providers.dart';

final _now = DateTime(2026, 10, 4, 9, 41);
final _savedAt = DateTime(2026, 9, 18, 18, 40);

final _formal = Measurement(
  id: 'formal',
  customerId: 'faisal',
  garmentType: 'Shalwar Kameez',
  measurementData: const {
    'neck': 15.5,
    'chest': 40.5,
    'waist': 36,
    'length': 42,
  },
  previousValues: {'chest': PreviousMeasurement(39.5, DateTime(2026, 8, 2))},
  note: 'Collar 1 inch wider',
  createdAt: DateTime(2026, 8, 2),
  updatedAt: _savedAt,
);

final _trousers = Measurement(
  id: 'trousers',
  customerId: 'faisal',
  garmentType: 'Trousers',
  fitProfile: FitProfile.casual,
  measurementData: const {'waist': 36.02, 'hip': 40.94},
  unit: MeasurementUnit.centimeters,
  createdAt: DateTime(2026, 8, 2),
  updatedAt: DateTime(2026, 8, 2),
);

class _Customers extends CustomersNotifier {
  @override
  Future<List<Customer>> build() async => [
    Customer(id: 'faisal', name: 'Faisal Shah', createdAt: DateTime(2024)),
  ];
}

class _Orders extends OrdersNotifier {
  @override
  Future<List<Order>> build() async => [];
}

class _Measurements extends MeasurementsNotifier {
  _Measurements(this.profiles);
  List<Measurement> profiles;
  final saved = <Measurement>[];

  @override
  Future<List<Measurement>> build() async => profiles;

  @override
  Future<bool> saveMeasurement(Measurement measurement) async {
    saved.add(measurement);
    profiles = [
      measurement,
      for (final profile in profiles)
        if (profile.id != measurement.id) profile,
    ];
    state = AsyncData(profiles);
    return true;
  }
}

Future<_Measurements> _pump(
  WidgetTester tester, {
  String query = '',
  Size size = const Size(390, 844),
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final measurements = _Measurements([_formal, _trousers]);
  final router = createAppRouter(
    initialLocation: '/customers/faisal/measurements$query',
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        customersNotifierProvider.overrideWith(_Customers.new),
        ordersNotifierProvider.overrideWith(_Orders.new),
        measurementsNotifierProvider.overrideWith(() => measurements),
        shopSettingsProvider.overrideWith((ref) => const ShopSettings()),
        clockProvider.overrideWithValue(() => _now),
      ],
      child: MaterialApp.router(
        theme: AppTheme.lightTheme,
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return measurements;
}

// Cards show the value and unit as one text, such as '40.5 in'.

/// Opens the editor for the field labelled [label], such as 'CHEST'.
Future<void> _openField(WidgetTester tester, String label) async {
  final field = find.text(label);
  // Scroll only when needed, so the status banner stays in view.
  if (!tester.any(field)) {
    await tester.scrollUntilVisible(
      field,
      200,
      scrollable: find.byType(Scrollable).last,
    );
  }
  await tester.tap(field);
  await tester.pumpAndSettle();
}

Future<void> _tapText(WidgetTester tester, String text) async {
  await tester.tap(find.text(text));
  await tester.pumpAndSettle();
}

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

  testWidgets('shows the garment fields in groups, as saved', (tester) async {
    await _pump(tester);

    expect(find.text('Faisal Shah'), findsOneWidget);
    expect(find.text('UPPER BODY'), findsOneWidget);
    expect(find.text('SLEEVE & LENGTH'), findsOneWidget);
    expect(find.text('KAMEEZ LENGTH'), findsOneWidget);
    expect(find.text('40.5 in'), findsOneWidget);
    expect(find.text('42.0 in'), findsOneWidget);
    expect(find.textContaining('Saved'), findsOneWidget);
    expect(find.textContaining('Updated 18 Sep, 6:40 PM'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Collar 1 inch wider'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(
      find.text('Bottom opening is optional — the order can still be saved.'),
      findsOneWidget,
    );
  });

  testWidgets('edits stay a draft until the profile is saved', (tester) async {
    final measurements = await _pump(tester);

    await _openField(tester, 'CHEST');
    await _tapText(tester, '+ 1/2');
    await _tapText(tester, 'Update Chest');

    expect(find.text('41.0 in'), findsOneWidget);
    expect(find.textContaining('1 field edited'), findsOneWidget);
    expect(measurements.saved, isEmpty);

    await _tapText(tester, 'Save Profile');
    final saved = measurements.saved.single;
    expect(saved.id, 'formal');
    expect(saved.measurementData['chest'], 41);
    expect(saved.measurementData['neck'], 15.5);
    expect(saved.previousValues['chest'], PreviousMeasurement(40.5, _savedAt));
    expect(saved.updatedAt, _now);
    expect(find.textContaining('Updated 4 Oct, 9:41 AM'), findsOneWidget);
    expect(find.text('Save Profile'), findsNothing);
  });

  testWidgets('discarding returns to the saved values', (tester) async {
    final measurements = await _pump(tester);
    await _openField(tester, 'NECK');
    await _tapText(tester, '− 1/2');
    await _tapText(tester, 'Update Neck');
    expect(find.text('15.0 in'), findsOneWidget);

    await _tapText(tester, 'Discard');
    expect(find.text('15.5 in'), findsOneWidget);
    expect(find.textContaining('Saved'), findsOneWidget);
    expect(measurements.saved, isEmpty);
  });

  testWidgets('the editor steps, types and offers the previous value', (
    tester,
  ) async {
    final measurements = await _pump(tester);
    await _openField(tester, 'CHEST');

    expect(find.text('Shalwar Kameez · Formal Fit'), findsOneWidget);
    expect(find.text('39.5 in · 2 Aug'), findsOneWidget);

    await tester.tap(find.byTooltip('Increase'));
    await tester.pump();
    expect(find.text('40.75'), findsOneWidget);
    await _tapText(tester, '− 1/4');
    await _tapText(tester, '− 1/4');
    expect(find.text('40.25'), findsOneWidget);

    await _tapText(tester, 'Use');
    expect(find.text('39.5'), findsOneWidget);

    for (var i = 0; i < 4; i++) {
      await tester.tap(find.bySemanticsLabel('Delete'));
    }
    for (final key in ['4', '1', '.', '2', '5']) {
      await tester.tap(find.text(key).last);
    }
    await tester.pump();
    expect(find.text('41.25'), findsOneWidget);
    await _tapText(tester, 'Update Chest');
    await _tapText(tester, 'Save Profile');
    expect(measurements.saved.single.measurementData['chest'], 41.25);
  });

  testWidgets('centimeter profiles step by half a centimeter, kept in inches', (
    tester,
  ) async {
    final measurements = await _pump(
      tester,
      query: '?garment=Trousers&fit=Casual%20Fit',
    );
    expect(find.text('91.5 cm'), findsOneWidget);
    expect(find.text('104.0 cm'), findsOneWidget);

    await _openField(tester, 'WAIST');
    await tester.tap(find.byTooltip('Increase'));
    await tester.pump();
    expect(find.text('92.0'), findsOneWidget);
    await _tapText(tester, 'Update Waist');
    await _tapText(tester, 'Save Profile');

    final saved = measurements.saved.single;
    expect(saved.unit, MeasurementUnit.centimeters);
    expect(saved.measurementData['waist'], closeTo(92 / 2.54, 1e-9));
  });

  testWidgets('a value left as it was is not counted as an edit', (
    tester,
  ) async {
    await _pump(tester, query: '?garment=Trousers&fit=Casual%20Fit');
    await _openField(tester, 'WAIST');
    await _tapText(tester, 'Update Waist');
    expect(find.textContaining('Saved'), findsOneWidget);
    expect(find.text('Save Profile'), findsNothing);
  });

  testWidgets('changing the unit saves it and converts the values', (
    tester,
  ) async {
    final measurements = await _pump(tester);
    await tester.tap(find.bySemanticsLabel('Centimeters'));
    await tester.pumpAndSettle();

    final saved = measurements.saved.single;
    expect(saved.unit, MeasurementUnit.centimeters);
    expect(saved.measurementData, _formal.measurementData);
    expect(saved.updatedAt, _savedAt);
    expect(find.text('102.9 cm'), findsOneWidget);
  });

  testWidgets('a garment without a profile is saved as a new one', (
    tester,
  ) async {
    final measurements = await _pump(tester);
    await _tapText(tester, 'Kurta');
    expect(find.text('Nothing saved for Formal Fit yet'), findsOneWidget);

    await _openField(tester, 'CHEST');
    for (final key in ['4', '0']) {
      await tester.tap(find.text(key).last);
    }
    await tester.pump();
    await _tapText(tester, 'Update Chest');
    await _tapText(tester, 'Save Profile');

    final saved = measurements.saved.single;
    expect(saved.id, isNot(anyOf('formal', 'trousers')));
    expect(saved.garmentType, 'Kurta');
    expect(saved.fitProfile, FitProfile.formal);
    expect(saved.measurementData, {'chest': 40.0});
    expect(saved.unit, MeasurementUnit.inches);
  });

  testWidgets('unsaved changes are settled before switching fit', (
    tester,
  ) async {
    final measurements = await _pump(tester);
    await _openField(tester, 'NECK');
    await _tapText(tester, '+ 1/4');
    await _tapText(tester, 'Update Neck');

    await _tapText(tester, 'Casual Fit');
    expect(find.text('Save your changes?'), findsOneWidget);
    await _tapText(tester, 'Keep editing');
    expect(find.text('15.75 in'), findsOneWidget);

    await _tapText(tester, 'Casual Fit');
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Discard'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Nothing saved for Casual Fit yet'), findsOneWidget);
    expect(measurements.saved, isEmpty);
  });

  testWidgets('leaving with unsaved changes can save them first', (
    tester,
  ) async {
    final measurements = await _pump(tester);
    await _openField(tester, 'NECK');
    await _tapText(tester, '+ 1/4');
    await _tapText(tester, 'Update Neck');

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await _tapText(tester, 'Save');

    expect(measurements.saved.single.measurementData['neck'], 15.75);
    expect(find.byType(MeasurementScreen), findsNothing);
    expect(find.byType(CustomerDetailScreen), findsOneWidget);
  });

  testWidgets('the screen and editor fit a narrow phone with larger text', (
    tester,
  ) async {
    await _pump(tester, size: const Size(360, 740), textScale: 1.4);
    expect(tester.takeException(), isNull);
    await _openField(tester, 'CHEST');
    expect(tester.takeException(), isNull);
  });
}
