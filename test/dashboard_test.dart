import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tailor_khata/core/error/failures.dart';
import 'package:tailor_khata/core/providers/clock_provider.dart';
import 'package:tailor_khata/core/routing/app_router.dart';
import 'package:tailor_khata/core/theme/app_theme.dart';
import 'package:tailor_khata/core/theme/design_tokens.dart';
import 'package:tailor_khata/features/customers/domain/entities/customer.dart';
import 'package:tailor_khata/features/customers/presentation/providers/customers_notifier.dart';
import 'package:tailor_khata/features/dashboard/domain/entities/money_summary.dart';
import 'package:tailor_khata/features/dashboard/presentation/screens/revenue_screen.dart';
import 'package:tailor_khata/features/measurements/domain/entities/measurement.dart';
import 'package:tailor_khata/features/measurements/presentation/providers/measurements_notifier.dart';
import 'package:tailor_khata/features/orders/domain/entities/order.dart';
import 'package:tailor_khata/features/orders/domain/entities/order_status_event.dart';
import 'package:tailor_khata/features/orders/domain/entities/payment.dart';
import 'package:tailor_khata/features/orders/presentation/providers/orders_notifier.dart';
import 'package:tailor_khata/features/settings/domain/entities/shop_settings.dart';
import 'package:tailor_khata/features/settings/presentation/providers/shop_settings_providers.dart';

final _today = DateTime(2026, 10, 4, 9, 41);

Order _order(
  String id, {
  String customer = 'faisal',
  String status = 'Received',
  required DateTime created,
  DateTime? due,
  double total = 3000,
  double paid = 0,
}) => Order(
  id: id,
  customerId: customer,
  orderNumber: int.tryParse(id.replaceAll(RegExp(r'\D'), '')),
  garmentType: 'Shalwar Kameez',
  pieces: 2,
  status: status,
  deliveryDate: due ?? DateTime(2026, 10, 20),
  totalAmount: total,
  paidAmount: paid,
  createdAt: created,
);

Payment _payment(
  String order,
  double amount,
  DateTime at, {
  PaymentMethod method = PaymentMethod.cash,
  bool advance = false,
}) => Payment(
  id: '$order-${at.toIso8601String()}',
  orderId: order,
  amount: amount,
  method: method,
  isAdvance: advance,
  paidAt: at,
);

// A September order paid off in October, and two October orders.
final _orders = [
  _order(
    'o1',
    created: DateTime(2026, 9, 10),
    due: DateTime(2026, 10, 2),
    status: 'Stitching',
    total: 4000,
    paid: 4000,
  ),
  _order(
    'o2',
    customer: 'nida',
    created: DateTime(2026, 10, 1),
    due: DateTime(2026, 10, 4),
    status: 'Ready',
    total: 4800,
    paid: 2000,
  ),
  _order(
    'o3',
    customer: 'sadia',
    created: DateTime(2026, 10, 3),
    due: DateTime(2026, 10, 4),
    status: 'Stitching',
    total: 6000,
    paid: 1000,
  ),
];
final _payments = [
  _payment('o3', 1000, DateTime(2026, 10, 3, 12), advance: true),
  _payment('o1', 2500, DateTime(2026, 10, 2, 16), method: PaymentMethod.bank),
  _payment('o2', 2000, DateTime(2026, 10, 1, 11), advance: true),
  _payment('o1', 1500, DateTime(2026, 9, 10, 11), advance: true),
];

class _Customers extends CustomersNotifier {
  @override
  Future<List<Customer>> build() async => [
    for (final (id, name) in [
      ('faisal', 'Faisal Shah'),
      ('nida', 'Nida Aslam'),
      ('sadia', 'Sadia Rehman'),
    ])
      Customer(
        id: id,
        name: name,
        phone: '03004128876',
        createdAt: DateTime(2026),
      ),
  ];
}

class _Measurements extends MeasurementsNotifier {
  @override
  Future<List<Measurement>> build() async => const [];
}

class _Orders extends OrdersNotifier {
  final writes = <String>[];

  @override
  Future<List<Order>> build() async => _orders;

  @override
  Future<Failure?> changeStatus(String orderId, String status) async {
    writes.add('$orderId status $status');
    return null;
  }

  @override
  Future<Failure?> deliverOrder(String orderId) async {
    writes.add('$orderId deliver');
    return null;
  }
}

Future<_Orders> _pump(WidgetTester tester, String location) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final orders = _Orders();
  final router = createAppRouter(initialLocation: location);
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        customersNotifierProvider.overrideWith(_Customers.new),
        ordersNotifierProvider.overrideWith(() => orders),
        measurementsNotifierProvider.overrideWith(_Measurements.new),
        paymentsProvider.overrideWith((ref) async => _payments),
        orderStatusHistoryProvider.overrideWith(
          (ref, id) async => [
            OrderStatusEvent(
              id: id,
              orderId: id,
              status: 'Received',
              changedAt: DateTime(2026, 10, 1),
            ),
          ],
        ),
        orderPaymentsProvider.overrideWith((ref, id) async => const []),
        shopSettingsProvider.overrideWith(
          (ref) => const ShopSettings(
            shopName: 'Hassan Tailors',
            ownerName: 'Imran Hassan',
          ),
        ),
        clockProvider.overrideWithValue(() => _today),
      ],
      child: MaterialApp.router(
        theme: AppTheme.lightTheme,
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return orders;
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
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

  group('money summary', () {
    final october = Period.month(2026, 10);

    test('bills orders by the day taken and collects by the day paid', () {
      final summary = MoneySummary.of(october, _orders, _payments);
      // The two October orders; the September one is billed in September.
      expect(summary.billed, 10800);
      expect(summary.orderCount, 2);
      // Every October payment, including the one for September's order.
      expect(summary.collected, 5500);
      // Still owed on the October orders.
      expect(summary.outstanding, 7800);
      expect(summary.collectedShare, closeTo(5500 / 10800, 1e-9));
    });

    test('a period with nothing billed has no collected share', () {
      final summary = MoneySummary.of(
        Period.month(2026, 8),
        _orders,
        _payments,
      );
      expect(summary, const MoneySummary());
      expect(summary.collectedShare, isNull);
    });

    test('periods include their first and last day only', () {
      final days = Period.days(DateTime(2026, 9, 12), DateTime(2026, 10, 3));
      expect(days.contains(DateTime(2026, 9, 12)), isTrue);
      expect(days.contains(DateTime(2026, 10, 3, 23, 59)), isTrue);
      expect(days.contains(DateTime(2026, 10, 4)), isFalse);
      expect(days.last, DateTime(2026, 10, 3));
      expect(
        Period.monthToDate(_today),
        Period.days(DateTime(2026, 10), _today),
      );
      expect(Period.yearToDate(_today).start, DateTime(2026));
      expect(days.overlapsMonth(DateTime(2026, 9)), isTrue);
      expect(days.overlapsMonth(DateTime(2026, 8)), isFalse);
      expect(days.overlapsMonth(DateTime(2026, 11)), isFalse);
    });

    test('collected by month covers six months, oldest first', () {
      final totals = collectedByMonth(_payments, last: DateTime(2027, 1, 15));
      expect(
        [for (final total in totals) total.month],
        [
          DateTime(2026, 8),
          DateTime(2026, 9),
          DateTime(2026, 10),
          DateTime(2026, 11),
          DateTime(2026, 12),
          DateTime(2027),
        ],
      );
      expect(
        [for (final total in totals) total.amount],
        [0, 1500, 5500, 0, 0, 0],
      );
    });

    test('outstanding counts every order still owed', () {
      expect(totalOutstanding(_orders), (amount: 7800.0, orders: 2));
    });

    test('labels read as dates and short amounts', () {
      expect(periodLabel(Period.monthToDate(_today)), '1–4 October');
      expect(periodLabel(Period.month(2026, 9)), 'September');
      expect(periodLabel(Period.days(_today, _today)), '4 October');
      expect(
        periodLabel(Period.days(DateTime(2026, 9, 12), DateTime(2026, 10, 3))),
        '12 Sep – 3 Oct',
      );
      expect(
        periodLabel(Period.days(DateTime(2025, 12, 12), DateTime(2026, 1, 3))),
        '12 Dec 2025 – 3 Jan 2026',
      );
      expect(compactRupees(850), '850');
      expect(compactRupees(1500), '1.5k');
      expect(compactRupees(96400), '96k');
      expect(compactRupees(1200000), '1.2M');
    });
  });

  group('home', () {
    testWidgets("shows the month's money and the work in the shop", (
      tester,
    ) async {
      await _pump(tester, '/home');
      expect(find.text('Sunday, 4 October'), findsOneWidget);
      expect(find.text('Hassan Tailors'), findsOneWidget);
      expect(find.text('IH'), findsOneWidget);
      expect(find.text("THIS MONTH'S REVENUE"), findsOneWidget);
      expect(find.text('Rs 10,800'), findsOneWidget);
      expect(find.text('Rs 7,800'), findsOneWidget);
      expect(find.text('across 2 orders'), findsOneWidget);
      expect(find.text('Rs 5,500'), findsOneWidget);
      expect(find.text('51% of billed'), findsOneWidget);
      // Two orders are being made; o2 is ready.
      expect(find.text('orders in work'), findsOneWidget);
      expect(find.text('deliveries · 1 overdue'), findsOneWidget);
      expect(find.text('1 order past its delivery date'), findsOneWidget);
      // Ready first among today's deliveries.
      expect(
        tester.getTopLeft(find.text('Nida Aslam')).dy,
        lessThan(tester.getTopLeft(find.text('Sadia Rehman')).dy),
      );
    });

    testWidgets('an earlier month can be shown', (tester) async {
      await _pump(tester, '/home');
      await _tap(tester, find.byTooltip('Choose month'));
      await _tap(tester, find.text('September'));
      expect(find.text('REVENUE · SEPTEMBER'), findsOneWidget);
      expect(find.text('Rs 4,000'), findsOneWidget);
      expect(find.text('Rs 1,500'), findsOneWidget);
    });

    testWidgets('a ready order is delivered from Home', (tester) async {
      final orders = await _pump(tester, '/home');
      await _tap(tester, find.text('Deliver'));
      expect(find.text('Deliver with Rs 2,800 unpaid?'), findsOneWidget);
      await _tap(tester, find.text('Deliver, keep balance'));
      expect(orders.writes, ['o2 deliver']);
    });

    testWidgets('an order in work moves to its next stage from Home', (
      tester,
    ) async {
      final orders = await _pump(tester, '/home');
      await _tap(tester, find.text('Update'));
      expect(find.text('Change production status'), findsOneWidget);
      await _tap(tester, find.text('Save Status'));
      expect(orders.writes, ['o3 status Ready']);
    });

    testWidgets('view all opens the orders due today', (tester) async {
      await _pump(tester, '/home');
      await _tap(tester, find.text('View all ›'));
      expect(find.text('Orders'), findsWidgets);
      expect(find.text('Deliver ›'), findsOneWidget);
      // The late order is left to the Overdue filter.
      expect(find.text('OVERDUE 2 DAYS'), findsNothing);
    });

    testWidgets('the revenue card opens Revenue', (tester) async {
      await _pump(tester, '/home');
      await _tap(tester, find.text("THIS MONTH'S REVENUE"));
      expect(find.text('Revenue'), findsOneWidget);
      expect(find.text('COLLECTED · 1–4 OCTOBER'), findsOneWidget);
    });
  });

  group('revenue', () {
    testWidgets('totals the period and lists its payments', (tester) async {
      await _pump(tester, '/home/revenue');
      expect(find.text('Rs 5,500'), findsOneWidget);
      expect(find.text('Rs 10,800'), findsOneWidget);
      expect(find.text('Rs 7,800'), findsOneWidget);
      expect(find.text('2 orders'), findsOneWidget);
      await tester.ensureVisible(find.text('Sadia Rehman'));
      expect(find.text('TK-0003 · Cash advance · Yesterday'), findsOneWidget);
      expect(find.text('TK-0001 · Bank · 2 Oct'), findsOneWidget);

      await _tap(tester, find.text('Last month'));
      expect(find.text('COLLECTED · SEPTEMBER'), findsOneWidget);
      // The total and the one payment behind it.
      expect(find.text('Rs 1,500'), findsNWidgets(2));
      expect(find.text('Rs 4,000'), findsOneWidget);
    });

    testWidgets('a payment opens its order', (tester) async {
      await _pump(tester, '/home/revenue');
      await _tap(tester, find.text('Sadia Rehman'));
      expect(find.text('Record Payment'), findsOneWidget);
    });

    testWidgets("the period's payments are copied as CSV", (tester) async {
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await _pump(tester, '/home/revenue');
      await _tap(tester, find.text('Copy CSV'));
      expect(
        copied,
        'Date,Order,Customer,Method,Advance,Amount\n'
        '2026-10-01 11:00,TK-0002,Nida Aslam,Cash,yes,2000\n'
        '2026-10-02 16:00,TK-0001,Faisal Shah,Bank,no,2500\n'
        '2026-10-03 12:00,TK-0003,Sadia Rehman,Cash,yes,1000',
      );
      expect(find.text('Copied 3 payments'), findsOneWidget);
    });
  });
}
