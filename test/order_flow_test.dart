import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tailor_khata/core/routing/app_router.dart';
import 'package:tailor_khata/core/theme/app_theme.dart';
import 'package:tailor_khata/core/theme/design_tokens.dart';
import 'package:tailor_khata/features/customers/domain/entities/customer.dart';
import 'package:tailor_khata/features/customers/presentation/providers/customers_notifier.dart';
import 'package:tailor_khata/features/orders/domain/entities/order.dart';
import 'package:tailor_khata/features/orders/domain/entities/payment.dart';
import 'package:tailor_khata/features/orders/presentation/providers/orders_notifier.dart';

// Newest first, the order in which the customer data source returns them.
final _newest = Customer(
  id: 'customer-new',
  name: 'Bilal Haider',
  createdAt: DateTime(2026, 10, 4),
);
final _older = Customer(
  id: 'customer-old',
  name: 'Faisal Shah',
  createdAt: DateTime(2026, 9, 1),
);

Order _order({String status = 'Received'}) => Order(
  id: 'order-1',
  customerId: _older.id,
  garmentType: 'Shalwar Kameez',
  status: status,
  deliveryDate: DateTime(2026, 10, 12),
  totalAmount: 3000,
  paidAmount: 1000,
  createdAt: DateTime(2026, 10, 1),
);

class _Customers extends CustomersNotifier {
  @override
  Future<List<Customer>> build() async => [_newest, _older];
}

class _Orders extends OrdersNotifier {
  _Orders(this.initial);
  final List<Order> initial;
  Order? added;

  /// The writes the screen asked for, in order.
  final writes = <String>[];

  @override
  Future<List<Order>> build() async => initial;
  @override
  Future<void> addOrder(Order order) async => added = order;
  @override
  Future<void> changeStatus(String orderId, String status) async =>
      writes.add('status $status');
  @override
  Future<void> deliverOrder(
    String orderId, {
    required bool settleBalance,
  }) async => writes.add(settleBalance ? 'deliver, settled' : 'deliver');
  @override
  Future<void> recordPayment(
    String orderId,
    double amount,
    PaymentMethod method,
  ) async => writes.add('payment $amount ${method.name}');
}

Future<_Orders> _pumpApp(
  WidgetTester tester,
  String location, {
  List<Order> orders = const [],
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final fixture = _Orders(orders);
  final router = createAppRouter(initialLocation: location);
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        customersNotifierProvider.overrideWith(_Customers.new),
        ordersNotifierProvider.overrideWith(() => fixture),
      ],
      child: MaterialApp.router(
        theme: AppTheme.lightTheme,
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return fixture;
}

Future<void> _tapStatus(WidgetTester tester, String status) async {
  await tester.ensureVisible(find.text(status));
  await tester.tap(find.text(status));
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

  testWidgets('changing a production stage only changes the stage', (
    tester,
  ) async {
    final orders = await _pumpApp(tester, '/orders/order-1', orders: [_order()]);
    await _tapStatus(tester, 'Cutting');
    expect(orders.writes, ['status Cutting']);
  });

  testWidgets('delivering without payment keeps the balance', (tester) async {
    final orders = await _pumpApp(tester, '/orders/order-1', orders: [_order()]);
    await _tapStatus(tester, 'Delivered');
    await tester.tap(find.text('Not Paid'));
    await tester.pumpAndSettle();
    expect(orders.writes, ['deliver']);
  });

  testWidgets('delivering with payment settles the balance', (tester) async {
    final orders = await _pumpApp(tester, '/orders/order-1', orders: [_order()]);
    await _tapStatus(tester, 'Delivered');
    await tester.tap(find.text('Paid & Deliver'));
    await tester.pumpAndSettle();
    expect(orders.writes, ['deliver, settled']);
  });

  testWidgets('cancelling a delivery leaves the order unchanged', (
    tester,
  ) async {
    final orders = await _pumpApp(tester, '/orders/order-1', orders: [_order()]);
    await _tapStatus(tester, 'Delivered');
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(orders.writes, isEmpty);
  });

  testWidgets('collecting the due on a delivered order records a payment', (
    tester,
  ) async {
    final orders = await _pumpApp(
      tester,
      '/orders/order-1',
      orders: [_order(status: 'Delivered')],
    );
    await tester.ensureVisible(find.text('Collect Due Amount'));
    await tester.tap(find.text('Collect Due Amount'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mark as Paid'));
    await tester.pumpAndSettle();
    expect(orders.writes, ['payment 2000.0 cash']);
  });

  testWidgets('an order started from a customer belongs to that customer', (
    tester,
  ) async {
    final orders = await _pumpApp(tester, '/customers/${_older.id}');
    await tester.tap(find.text('Create Order'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<DropdownButton<String>>(find.byType(DropdownButton<String>))
          .value,
      _older.id,
    );
    await tester.enterText(find.byType(TextFormField).first, '3000');
    await tester.ensureVisible(find.text('Save Order'));
    await tester.tap(find.text('Save Order'));
    await tester.pumpAndSettle();
    expect(orders.added?.customerId, _older.id);
  });

  testWidgets('the new-order link preselects its customer', (tester) async {
    await _pumpApp(tester, '/orders/new?customerId=${_older.id}');
    expect(
      tester
          .widget<DropdownButton<String>>(find.byType(DropdownButton<String>))
          .value,
      _older.id,
    );
  });

  testWidgets('a new order without a customer link still opens', (
    tester,
  ) async {
    await _pumpApp(tester, '/orders/new?customerId=missing');
    expect(tester.takeException(), isNull);
    expect(
      tester
          .widget<DropdownButton<String>>(find.byType(DropdownButton<String>))
          .value,
      _newest.id,
    );
  });
}
