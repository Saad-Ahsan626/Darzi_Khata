import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tailor_khata/core/error/failures.dart';
import 'package:tailor_khata/core/providers/clock_provider.dart';
import 'package:tailor_khata/core/routing/app_router.dart';
import 'package:tailor_khata/core/theme/app_theme.dart';
import 'package:tailor_khata/core/theme/design_tokens.dart';
import 'package:tailor_khata/features/customers/domain/entities/customer.dart';
import 'package:tailor_khata/features/customers/presentation/providers/customers_notifier.dart';
import 'package:tailor_khata/features/customers/presentation/screens/add_edit_customer_screen.dart';
import 'package:tailor_khata/features/customers/presentation/screens/customer_list_screen.dart';
import 'package:tailor_khata/features/customers/presentation/widgets/customer_order_card.dart';
import 'package:tailor_khata/features/measurements/domain/entities/fit_profile.dart';
import 'package:tailor_khata/features/measurements/domain/entities/measurement.dart';
import 'package:tailor_khata/features/measurements/domain/entities/measurement_unit.dart';
import 'package:tailor_khata/features/measurements/presentation/providers/measurements_notifier.dart';
import 'package:tailor_khata/features/orders/domain/entities/order.dart';
import 'package:tailor_khata/features/orders/presentation/providers/orders_notifier.dart';
import 'package:tailor_khata/features/settings/domain/entities/shop_settings.dart';
import 'package:tailor_khata/features/settings/presentation/providers/shop_settings_providers.dart';

final _today = DateTime(2026, 10, 4, 9, 41);

Customer _customer(String id, String name, String phone, {String? address}) =>
    Customer(
      id: id,
      name: name,
      urduName: id == 'faisal' ? 'فیصل شاہ' : null,
      phone: phone,
      address: address,
      createdAt: DateTime(2024, 3, 12),
    );

// Saved newest first, as the data source returns them; the list sorts A–Z.
final _shop = [
  _customer('zara', 'Zara Malik', '03111234567'),
  _customer('nida', 'Nida Aslam', '03021184532'),
  _customer('farhan', 'Farhan Khalid', '03457762290'),
  _customer('faisal', 'Faisal Shah', '03004128876', address: 'Ichhra, Lahore'),
  _customer('bushra', 'Bushra Anwar', '03332217650'),
  _customer('bilal', 'Bilal Haider', '03219984412'),
];

Order _order(
  String id,
  String customerId,
  int number, {
  String garment = 'Shalwar Kameez',
  int pieces = 1,
  String? fabric,
  String status = 'Received',
  required DateTime due,
  required double total,
  required double paid,
  DateTime? created,
  DateTime? delivered,
}) => Order(
  id: id,
  customerId: customerId,
  orderNumber: number,
  garmentType: garment,
  pieces: pieces,
  fabric: fabric,
  status: status,
  deliveryDate: due,
  totalAmount: total,
  paidAmount: paid,
  createdAt: created ?? DateTime(2026, 9, 28),
  deliveredAt: delivered,
);

Order _deliveredAndPaid(
  String id,
  String customerId,
  int number,
  DateTime delivered, {
  String garment = 'Shalwar Kameez',
  String? fabric,
  double total = 4000,
}) => _order(
  id,
  customerId,
  number,
  garment: garment,
  fabric: fabric,
  status: 'Delivered',
  due: delivered,
  total: total,
  paid: total,
  created: delivered.subtract(const Duration(days: 8)),
  delivered: delivered,
);

final _orders = [
  _order('b1', 'bilal', 1043, pieces: 2, due: DateTime(2026, 10, 9), total: 6500, paid: 2000),
  _order('b2', 'bilal', 1044, garment: 'Kurta', status: 'Cutting', due: DateTime(2026, 10, 12), total: 2400, paid: 1500),
  _deliveredAndPaid('u1', 'bushra', 990, DateTime(2026, 9, 20)),
  _order('f1', 'faisal', 1042, pieces: 2, fabric: 'Wash & wear, off-white', status: 'Ready', due: DateTime(2026, 10, 4), total: 4800, paid: 2000),
  _deliveredAndPaid('f2', 'faisal', 987, DateTime(2026, 9, 12), garment: 'Waistcoat', fabric: 'Grey wool blend', total: 3500),
  _deliveredAndPaid('f3', 'faisal', 921, DateTime(2026, 6, 28), garment: 'Three-piece Suit', total: 18000),
  for (var month = 2; month <= 5; month++)
    _deliveredAndPaid('f-old-$month', 'faisal', 800 + month, DateTime(2026, month, 5)),
  _order('n1', 'nida', 1031, garment: 'Kurta', status: 'Stitching', due: DateTime(2026, 10, 2), total: 1500, paid: 0),
];

Measurement _profile(
  String id,
  String customerId,
  String garment, {
  String fit = FitProfile.formal,
  Map<String, double> values = const {'chest': 40.5, 'waist': 36},
  MeasurementUnit unit = MeasurementUnit.inches,
  DateTime? updated,
}) => Measurement(
  id: id,
  customerId: customerId,
  garmentType: garment,
  fitProfile: fit,
  measurementData: values,
  unit: unit,
  createdAt: updated ?? DateTime(2026, 8, 2),
  updatedAt: updated ?? DateTime(2026, 8, 2),
);

final _measurements = [
  _profile(
    'm1',
    'faisal',
    'Shalwar Kameez',
    values: const {'chest': 40.5, 'waist': 36, 'sleeve': 24.5, 'length': 42},
    updated: DateTime(2026, 9, 18),
  ),
  _profile(
    'm2',
    'faisal',
    'Trousers',
    fit: FitProfile.casual,
    values: const {'waist': 36},
    unit: MeasurementUnit.centimeters,
  ),
  for (var i = 1; i <= 3; i++) _profile('fk$i', 'farhan', 'Kurta $i'),
];

class _Customers extends CustomersNotifier {
  _Customers(this.customers, {this.failingSaves = 0});
  List<Customer> customers;

  /// How many saves fail before one goes through.
  int failingSaves;
  final attempted = <Customer>[];
  final added = <Customer>[];
  final updated = <Customer>[];
  final deleted = <String>[];

  @override
  Future<List<Customer>> build() async => customers;

  @override
  Future<Failure?> addCustomer(Customer customer) async {
    attempted.add(customer);
    if (failingSaves-- > 0) return const DatabaseFailure('disk full');
    added.add(customer);
    state = AsyncData(customers = [customer, ...customers]);
    return null;
  }

  @override
  Future<Failure?> updateCustomer(Customer customer) async {
    updated.add(customer);
    state = AsyncData(
      customers = [
        for (final saved in customers)
          saved.id == customer.id ? customer : saved,
      ],
    );
    return null;
  }

  @override
  Future<Failure?> deleteCustomer(String id) async {
    deleted.add(id);
    state = AsyncData(
      customers = [
        for (final saved in customers)
          if (saved.id != id) saved,
      ],
    );
    return null;
  }
}

class _Orders extends OrdersNotifier {
  @override
  Future<List<Order>> build() async => _orders;
}

class _Measurements extends MeasurementsNotifier {
  @override
  Future<List<Measurement>> build() async => _measurements;
}

/// Kept so a test can push a route the way a screen would.
late GoRouter _router;

Future<_Customers> _pump(
  WidgetTester tester,
  String location, {
  List<Customer>? customers,
  int failingSaves = 0,
  Size size = const Size(390, 844),
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final fixture = _Customers(customers ?? _shop, failingSaves: failingSaves);
  final router = _router = createAppRouter(initialLocation: location);
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        customersNotifierProvider.overrideWith(() => fixture),
        ordersNotifierProvider.overrideWith(_Orders.new),
        measurementsNotifierProvider.overrideWith(_Measurements.new),
        shopSettingsProvider.overrideWith((ref) => const ShopSettings()),
        clockProvider.overrideWithValue(() => _today),
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
  return fixture;
}

Finder get _fields => find.byType(TextFormField);
String _fieldText(WidgetTester tester, int index) =>
    tester.widget<TextFormField>(_fields.at(index)).controller!.text;

bool _canSave(WidgetTester tester, String label) =>
    tester
        .widget<ElevatedButton>(find.widgetWithText(ElevatedButton, label))
        .onPressed !=
    null;

double _top(WidgetTester tester, String text) =>
    tester.getTopLeft(find.text(text)).dy;

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

  group('customer list', () {
    testWidgets('lists customers A–Z with what needs attention', (
      tester,
    ) async {
      await _pump(tester, '/customers');

      expect(find.text('6 saved · 3 with balances'), findsOneWidget);
      for (final letter in ['B', 'F', 'N', 'Z']) {
        expect(find.text(letter), findsOneWidget);
      }
      expect(
        _top(tester, 'Bilal Haider'),
        lessThan(_top(tester, 'Bushra Anwar')),
      );
      expect(
        _top(tester, 'Bushra Anwar'),
        lessThan(_top(tester, 'Faisal Shah')),
      );
      expect(_top(tester, 'Nida Aslam'), lessThan(_top(tester, 'Zara Malik')));

      expect(find.text('0321 998 4412'), findsOneWidget);
      expect(find.text('2 open orders · Rs 5,400 due'), findsOneWidget);
      expect(find.text('Last order 12 Sep · no balance'), findsOneWidget);
      expect(find.text('Delivery today · Rs 2,800 due'), findsOneWidget);
      expect(find.text('3 measurement profiles saved'), findsOneWidget);
      expect(find.text('Overdue 2 days · Rs 1,500'), findsOneWidget);
      expect(find.text('No orders yet'), findsOneWidget);
    });

    testWidgets('search matches names and phone numbers', (tester) async {
      await _pump(tester, '/customers');

      await tester.enterText(find.byType(TextField), 'fa');
      await tester.pumpAndSettle();
      expect(find.text('Faisal Shah'), findsOneWidget);
      expect(find.text('Farhan Khalid'), findsOneWidget);
      expect(find.text('Bilal Haider'), findsNothing);

      await tester.enterText(find.byType(TextField), '0302 118');
      await tester.pumpAndSettle();
      expect(find.text('Nida Aslam'), findsOneWidget);
      expect(find.text('Faisal Shah'), findsNothing);
    });

    testWidgets('a search with no match can be cleared or saved as new', (
      tester,
    ) async {
      await _pump(tester, '/customers');
      await tester.enterText(find.byType(TextField), '0315 44');
      await tester.pumpAndSettle();
      expect(find.text('No match for “0315 44”'), findsOneWidget);

      await tester.tap(find.text('Clear search'));
      await tester.pumpAndSettle();
      expect(find.text('Faisal Shah'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '0315 44');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add new'));
      await tester.pumpAndSettle();
      expect(find.byType(AddEditCustomerScreen), findsOneWidget);
      expect(_fieldText(tester, 1), '0315 44');
    });

    testWidgets('an empty shop invites the first customer', (tester) async {
      await _pump(tester, '/customers', customers: const []);
      expect(find.text('Nothing saved yet'), findsOneWidget);
      expect(find.text('No customers yet'), findsOneWidget);

      await tester.tap(find.text('Add First Customer'));
      await tester.pumpAndSettle();
      expect(find.byType(AddEditCustomerScreen), findsOneWidget);
    });
  });

  group('adding a customer', () {
    testWidgets('saving waits for a name and a complete phone number', (
      tester,
    ) async {
      final customers = await _pump(tester, '/customers/new');
      expect(_canSave(tester, 'Save customer'), isFalse);
      expect(find.text("Enter the customer's name to save"), findsOneWidget);

      await tester.enterText(_fields.at(0), 'Rameez Khan');
      await tester.enterText(_fields.at(1), '030455011');
      await tester.pump();
      expect(_canSave(tester, 'Save customer'), isFalse);
      expect(find.text('Complete the phone number to save'), findsOneWidget);
      // The field is only checked once the user leaves it.
      expect(find.textContaining('Needs 11 digits'), findsNothing);

      await tester.tap(_fields.at(2));
      await tester.pump();
      expect(find.text('Needs 11 digits — 2 remaining'), findsOneWidget);

      await tester.enterText(_fields.at(1), '03045501198');
      await tester.enterText(_fields.at(3), 'Prefers loose fit');
      await tester.pump();
      expect(find.textContaining('Needs 11 digits'), findsNothing);
      expect(_canSave(tester, 'Save customer'), isTrue);

      await tester.tap(find.text('Save customer'));
      await tester.pumpAndSettle();
      final saved = customers.added.single;
      expect(saved.name, 'Rameez Khan');
      expect(saved.phone, '03045501198');
      expect(saved.note, 'Prefers loose fit');
      expect(find.byType(CustomerListScreen), findsOneWidget);
      expect(find.text('Customer saved'), findsOneWidget);
    });

    testWidgets('the phone number is grouped and kept to 11 digits', (
      tester,
    ) async {
      await _pump(tester, '/customers/new');
      await tester.enterText(_fields.at(1), '03045501198999');
      expect(_fieldText(tester, 1), '0304 550 1198');

      await tester.enterText(_fields.at(1), '+92 300 4128876');
      expect(_fieldText(tester, 1), '0300 412 8876');
    });

    testWidgets('a failed save keeps the form and can be retried', (
      tester,
    ) async {
      final customers = await _pump(
        tester,
        '/customers/new',
        failingSaves: 2,
      );
      await tester.enterText(_fields.at(0), 'Rameez Khan');
      await tester.enterText(_fields.at(1), '03045501198');
      await tester.pump();
      await tester.tap(find.text('Save customer'));
      await tester.pumpAndSettle();

      expect(find.text("Couldn't save customer"), findsOneWidget);
      expect(find.textContaining('disk full'), findsOneWidget);
      expect(customers.added, isEmpty);

      await tester.tap(find.text('Keep editing'));
      await tester.pumpAndSettle();
      expect(find.byType(AddEditCustomerScreen), findsOneWidget);
      expect(_fieldText(tester, 0), 'Rameez Khan');

      // Fails once more, then the retry goes through.
      await tester.tap(find.text('Save customer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Retry save'));
      await tester.pumpAndSettle();

      expect(customers.added.single.name, 'Rameez Khan');
      // Every attempt writes the same customer, so a retry cannot duplicate.
      expect({for (final attempt in customers.attempted) attempt.id}, {
        customers.added.single.id,
      });
      expect(find.byType(CustomerListScreen), findsOneWidget);
    });
  });

  testWidgets('screens fit a narrow phone with larger text', (tester) async {
    Future<void> open(String location) => _pump(
      tester,
      location,
      size: const Size(360, 740),
      textScale: 1.4,
    );

    await open('/customers');
    expect(tester.takeException(), isNull, reason: 'list');
    await tester.enterText(find.byType(TextField), 'nobody');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'no match');

    await open('/customers/new');
    await tester.enterText(_fields.at(1), '0304');
    await tester.tap(_fields.at(2));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'form');

    await open('/customers/faisal');
    expect(tester.takeException(), isNull, reason: 'measurements');
    await tester.tap(find.text('Order History'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'orders');
    await tester.tap(find.text('Measurements'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('More'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete customer'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'delete dialog');
  });

  testWidgets('editing keeps what the form does not show', (tester) async {
    final customers = await _pump(tester, '/customers');
    final faisal = _shop.firstWhere((customer) => customer.id == 'faisal');
    _router.push('/customers/faisal/edit', extra: faisal);
    await tester.pumpAndSettle();

    expect(_fieldText(tester, 0), 'Faisal Shah');
    expect(_fieldText(tester, 1), '0300 412 8876');
    expect(_fieldText(tester, 2), 'Ichhra, Lahore');
    await tester.enterText(_fields.at(3), 'Collar 1 inch wider');
    await tester.pump();
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    final saved = customers.updated.single;
    expect(saved.id, 'faisal');
    expect(saved.note, 'Collar 1 inch wider');
    expect(saved.urduName, faisal.urduName);
    expect(saved.createdAt, faisal.createdAt);
    expect(find.text('Customer updated'), findsOneWidget);
  });

  group('customer page', () {
    testWidgets('summarises the customer and their measurement profiles', (
      tester,
    ) async {
      await _pump(tester, '/customers/faisal');

      expect(find.text('Faisal Shah'), findsOneWidget);
      expect(find.text('0300 412 8876 · Ichhra, Lahore'), findsOneWidget);
      expect(find.text('7'), findsOneWidget);
      expect(find.text('Rs 2,800'), findsOneWidget);
      expect(find.text('Mar 2024'), findsOneWidget);

      expect(find.text('Shalwar Kameez'), findsOneWidget);
      expect(find.text('FORMAL'), findsOneWidget);
      expect(find.text('Updated 18 Sep · inches'), findsOneWidget);
      expect(find.text('40.5'), findsOneWidget);
      expect(find.text('24.5'), findsOneWidget);

      // A profile kept in centimeters shows its stored inches converted.
      expect(find.text('CASUAL'), findsOneWidget);
      expect(find.text('Updated 2 Aug · centimeters'), findsOneWidget);
      expect(find.text('91.4'), findsOneWidget);
    });

    testWidgets('lists open orders first and folds away older ones', (
      tester,
    ) async {
      await _pump(tester, '/customers/faisal');
      await tester.tap(find.text('Order History'));
      await tester.pumpAndSettle();

      expect(find.text('7 ORDERS · RS 2,800 OUTSTANDING'), findsOneWidget);
      expect(find.byType(CustomerOrderCard), findsNWidgets(3));
      expect(
        _top(tester, 'TK-1042'),
        lessThan(_top(tester, 'TK-0987')),
      );
      expect(_top(tester, 'TK-0987'), lessThan(_top(tester, 'TK-0921')));

      expect(find.text('Shalwar Kameez · 2 pcs'), findsOneWidget);
      expect(find.text('Wash & wear, off-white'), findsOneWidget);
      expect(find.text('of Rs 4,800'), findsOneWidget);
      expect(find.text('READY'), findsOneWidget);
      expect(find.text('Deliver today, 4 Oct'), findsOneWidget);
      expect(find.text('Waistcoat · 1 pc'), findsOneWidget);
      expect(find.text('PAID IN FULL'), findsNWidgets(2));

      await tester.tap(find.text('Show 4 earlier orders'));
      await tester.pumpAndSettle();
      expect(find.text('Show 4 earlier orders'), findsNothing);
      await tester.scrollUntilVisible(
        find.text('TK-0802'),
        200,
        scrollable: find.descendant(
          of: find.byType(ListView),
          matching: find.byType(Scrollable),
        ),
      );
      expect(find.text('TK-0802'), findsOneWidget);
    });

    testWidgets('a customer with nothing saved is invited to start', (
      tester,
    ) async {
      await _pump(tester, '/customers/zara');
      expect(find.text('No measurements yet'), findsOneWidget);
      await tester.tap(find.text('Order History'));
      await tester.pumpAndSettle();
      expect(find.text('No orders yet'), findsOneWidget);
    });

    testWidgets('deleting asks first and says what will be lost', (
      tester,
    ) async {
      final customers = await _pump(tester, '/customers/faisal');
      Future<void> openDeleteDialog() async {
        await tester.tap(find.byTooltip('More'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Delete customer'));
        await tester.pumpAndSettle();
      }

      await openDeleteDialog();
      expect(find.text('Delete Faisal Shah?'), findsOneWidget);
      expect(
        find.textContaining(
          'removes the customer, 2 measurement profiles and 7 orders',
        ),
        findsOneWidget,
      );
      expect(
        find.text('Rs 2,800 outstanding will be lost from your records'),
        findsOneWidget,
      );

      await tester.tap(find.text('Keep customer'));
      await tester.pumpAndSettle();
      expect(customers.deleted, isEmpty);
      expect(find.text('Faisal Shah'), findsOneWidget);

      await openDeleteDialog();
      await tester.tap(find.text('Delete permanently'));
      await tester.pumpAndSettle();
      expect(customers.deleted, ['faisal']);
      expect(find.byType(CustomerListScreen), findsOneWidget);
      expect(find.text('Faisal Shah'), findsNothing);
      expect(find.text('Faisal Shah deleted'), findsOneWidget);
    });
  });
}
