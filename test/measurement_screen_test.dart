import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tailor_khata/core/routing/app_router.dart';
import 'package:tailor_khata/core/theme/app_theme.dart';
import 'package:tailor_khata/core/theme/design_tokens.dart';
import 'package:tailor_khata/features/customers/domain/entities/customer.dart';
import 'package:tailor_khata/features/customers/presentation/providers/customers_notifier.dart';
import 'package:tailor_khata/features/measurements/domain/entities/fit_profile.dart';
import 'package:tailor_khata/features/measurements/domain/entities/measurement.dart';
import 'package:tailor_khata/features/measurements/presentation/providers/measurements_notifier.dart';
import 'package:tailor_khata/features/orders/domain/entities/order.dart';
import 'package:tailor_khata/features/orders/presentation/providers/orders_notifier.dart';

final _customer = Customer(
  id: 'faisal',
  name: 'Faisal Shah',
  createdAt: DateTime(2026, 3, 1),
);

final _formal = Measurement(
  id: 'formal',
  customerId: 'faisal',
  garmentType: 'Shalwar Kameez',
  measurementData: const {'chest': 40.5, 'length': 42},
  createdAt: DateTime(2026, 9, 18),
  updatedAt: DateTime(2026, 9, 18),
);

class _Customers extends CustomersNotifier {
  @override
  Future<List<Customer>> build() async => [_customer];
}

class _Orders extends OrdersNotifier {
  @override
  Future<List<Order>> build() async => [];
}

class _Measurements extends MeasurementsNotifier {
  final saved = <Measurement>[];

  @override
  Future<List<Measurement>> build() async => [_formal];

  @override
  Future<void> saveMeasurement(Measurement measurement) async {
    saved.add(measurement);
    state = AsyncValue.data([
      measurement,
      ...state.value!.where((existing) => existing.id != measurement.id),
    ]);
  }
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

  testWidgets('formal and casual fits show and save their own values', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final measurements = _Measurements();
    final router = createAppRouter(
      initialLocation: '/customers/faisal/measurements',
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          customersNotifierProvider.overrideWith(_Customers.new),
          ordersNotifierProvider.overrideWith(_Orders.new),
          measurementsNotifierProvider.overrideWith(() => measurements),
        ],
        child: MaterialApp.router(
          theme: AppTheme.lightTheme,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Stored inches are shown the way the screen always showed them.
    expect(find.text('40.5"'), findsOneWidget);
    expect(find.text('42.0"'), findsOneWidget);

    await tester.tap(find.text('Casual fit'));
    await tester.pumpAndSettle();
    expect(find.text('40.5"'), findsNothing);
    expect(find.text('Tap to add'), findsNWidgets(5));

    await tester.tap(find.text('Chest'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '42.5');
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    final casual = measurements.saved.single;
    expect(casual.id, isNot(_formal.id));
    expect(casual.fitProfile, FitProfile.casual);
    expect(casual.measurementData, {'chest': 42.5});
    expect(find.text('42.5"'), findsOneWidget);

    await tester.tap(find.text('Formal fit'));
    await tester.pumpAndSettle();
    expect(find.text('40.5"'), findsOneWidget);
    expect(find.text('42.5"'), findsNothing);

    await tester.tap(find.text('Chest'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();

    final formal = measurements.saved.last;
    expect(formal.id, _formal.id);
    expect(formal.fitProfile, FitProfile.formal);
    expect(formal.measurementData, {'length': 42.0});
  });
}
