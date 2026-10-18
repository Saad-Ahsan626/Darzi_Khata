import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart' show Either, Right;
import 'package:tailor_khata/core/error/failures.dart';
import 'package:tailor_khata/core/providers/clock_provider.dart';
import 'package:tailor_khata/core/routing/app_router.dart';
import 'package:tailor_khata/core/theme/app_theme.dart';
import 'package:tailor_khata/core/theme/design_tokens.dart';
import 'package:tailor_khata/features/customers/domain/entities/customer.dart';
import 'package:tailor_khata/features/customers/presentation/providers/customers_notifier.dart';
import 'package:tailor_khata/features/measurements/domain/entities/fit_profile.dart';
import 'package:tailor_khata/features/measurements/domain/entities/measurement.dart';
import 'package:tailor_khata/features/measurements/presentation/providers/measurements_notifier.dart';
import 'package:tailor_khata/features/orders/domain/entities/order.dart';
import 'package:tailor_khata/features/orders/domain/entities/order_status_event.dart';
import 'package:tailor_khata/features/orders/domain/entities/payment.dart';
import 'package:tailor_khata/features/orders/presentation/providers/orders_notifier.dart';
import 'package:tailor_khata/features/orders/presentation/widgets/whatsapp_reminder.dart';
import 'package:tailor_khata/features/settings/domain/entities/shop_settings.dart';
import 'package:tailor_khata/features/settings/presentation/providers/shop_settings_providers.dart';

final _today = DateTime(2026, 10, 4, 9, 41);

// Newest first, the order in which the customer data source returns them.
final _newest = Customer(
  id: 'customer-new',
  name: 'Bilal Haider',
  phone: '03219984412',
  createdAt: DateTime(2026, 10, 4),
);
final _older = Customer(
  id: 'customer-old',
  name: 'Faisal Shah',
  phone: '03004128876',
  createdAt: DateTime(2026, 9, 1),
);

final _formal = Measurement(
  id: 'faisal-formal',
  customerId: _older.id,
  garmentType: 'Shalwar Kameez',
  fitProfile: FitProfile.formal,
  measurementData: const {'chest': 40.5, 'length': 42},
  createdAt: DateTime(2026, 9, 1),
  updatedAt: DateTime(2026, 9, 1),
);

Order _order({
  String id = 'order-1',
  String status = 'Received',
  double paid = 1000,
  DateTime? due,
}) => Order(
  id: id,
  customerId: _older.id,
  orderNumber: 42,
  garmentType: 'Shalwar Kameez',
  pieces: 2,
  status: status,
  deliveryDate: due ?? DateTime(2026, 10, 12),
  totalAmount: 3000,
  paidAmount: paid,
  createdAt: DateTime(2026, 10, 1),
);

class _Customers extends CustomersNotifier {
  @override
  Future<List<Customer>> build() async => [_newest, _older];
}

class _Measurements extends MeasurementsNotifier {
  @override
  Future<List<Measurement>> build() async => [_formal];
}

class _Orders extends OrdersNotifier {
  _Orders(this.initial);
  final List<Order> initial;
  Order? added;
  Order? updated;

  /// The writes the screens asked for, in order.
  final writes = <String>[];

  @override
  Future<List<Order>> build() async => initial;

  @override
  Future<Failure?> addOrder(Order order) async {
    added = order;
    state = AsyncData([...?state.valueOrNull, order]);
    return null;
  }

  @override
  Future<Failure?> updateOrder(Order order) async {
    updated = order;
    return null;
  }

  @override
  Future<Failure?> deleteOrder(String id) async {
    writes.add('delete order $id');
    state = AsyncData([
      for (final order in state.valueOrNull ?? const <Order>[])
        if (order.id != id) order,
    ]);
    return null;
  }

  @override
  Future<Failure?> changeStatus(String orderId, String status) async {
    writes.add('status $status');
    return null;
  }

  @override
  Future<Failure?> deliverOrder(String orderId) async {
    writes.add('deliver');
    return null;
  }

  @override
  Future<Either<Failure, Payment>> recordPayment(
    String orderId,
    double amount,
    PaymentMethod method,
  ) async {
    writes.add('payment $amount ${method.name}');
    return Right(
      Payment(
        id: 'payment-${writes.length}',
        orderId: orderId,
        amount: amount,
        method: method,
        paidAt: _today,
      ),
    );
  }

  @override
  Future<Failure?> deletePayment(String paymentId) async {
    writes.add('delete $paymentId');
    return null;
  }
}

/// Links the reminder sheet asked to open.
final _opened = <Uri>[];

Future<_Orders> _pumpApp(
  WidgetTester tester,
  String location, {
  List<Order> orders = const [],
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  _opened.clear();
  final fixture = _Orders(orders);
  final router = createAppRouter(initialLocation: location);
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        customersNotifierProvider.overrideWith(_Customers.new),
        ordersNotifierProvider.overrideWith(() => fixture),
        measurementsNotifierProvider.overrideWith(_Measurements.new),
        shopSettingsProvider.overrideWith(
          (ref) => const ShopSettings(
            shopName: 'Hassan Tailors',
            openingTime: '11:00',
            closingTime: '21:00',
            nextOrderNumber: 43,
          ),
        ),
        clockProvider.overrideWithValue(() => _today),
        orderStatusHistoryProvider.overrideWith(
          (ref, id) async => [
            OrderStatusEvent(
              id: 'received',
              orderId: id,
              status: 'Received',
              changedAt: DateTime(2026, 10, 1, 11),
            ),
          ],
        ),
        orderPaymentsProvider.overrideWith((ref, id) async => const []),
        externalLinkLauncherProvider.overrideWithValue((uri) async {
          _opened.add(uri);
          return true;
        }),
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

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// A text field by the label it is announced with.
Finder _field(String label) => find.descendant(
  of: find.byWidgetPredicate(
    (widget) => widget is Semantics && widget.properties.label == label,
  ),
  matching: find.byType(EditableText),
);

Finder _inDialog(String text) =>
    find.descendant(of: find.byType(Dialog), matching: find.text(text));

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

  group('order page', () {
    testWidgets('shows the money, the stage and when it is due', (
      tester,
    ) async {
      await _pumpApp(tester, '/orders/order-1', orders: [_order()]);
      expect(find.text('TK-0042'), findsOneWidget);
      expect(find.text('Faisal Shah · 0300 412 8876'), findsOneWidget);
      expect(find.text('DUE 12 OCT · IN 8 DAYS'), findsOneWidget);
      expect(find.text('Rs 3,000'), findsOneWidget);
      expect(find.text('Rs 2,000'), findsOneWidget);
      expect(
        find.text('Received since 1 Oct, 11:00 AM · 3 days in production'),
        findsOneWidget,
      );
    });

    testWidgets('changing the stage only changes the stage', (tester) async {
      final orders = await _pumpApp(
        tester,
        '/orders/order-1',
        orders: [_order()],
      );
      await _tap(tester, find.text('Change Status'));
      // The next stage is offered first.
      await _tap(tester, find.text('Save Status'));
      expect(orders.writes, ['status Cutting']);
      expect(find.text('Moved to Cutting'), findsOneWidget);
    });

    testWidgets('delivering with a balance states it and keeps it', (
      tester,
    ) async {
      final orders = await _pumpApp(
        tester,
        '/orders/order-1',
        orders: [_order(status: 'Ready')],
      );
      await _tap(tester, find.text('Mark Delivered'));
      expect(find.text('Deliver with Rs 2,000 unpaid?'), findsOneWidget);
      await _tap(tester, find.text('Deliver, keep balance'));
      expect(orders.writes, ['deliver']);
      expect(find.text('Rs 2,000 stays outstanding'), findsOneWidget);
    });

    testWidgets('recording payment first then delivers', (tester) async {
      final orders = await _pumpApp(
        tester,
        '/orders/order-1',
        orders: [_order(status: 'Ready')],
      );
      await _tap(tester, find.text('Mark Delivered'));
      await _tap(tester, find.text('Record payment first'));
      await _tap(tester, find.text('Record Rs 2,000'));
      expect(orders.writes, ['payment 2000.0 cash', 'deliver']);
    });

    testWidgets('cancelling a delivery leaves the order unchanged', (
      tester,
    ) async {
      final orders = await _pumpApp(
        tester,
        '/orders/order-1',
        orders: [_order()],
      );
      await _tap(tester, find.text('Mark Delivered'));
      await _tap(tester, find.text('Cancel'));
      expect(orders.writes, isEmpty);
    });

    testWidgets('a paid order is delivered after a plain confirmation', (
      tester,
    ) async {
      final orders = await _pumpApp(
        tester,
        '/orders/order-1',
        orders: [_order(paid: 3000)],
      );
      expect(
        tester
            .widget<ElevatedButton>(
              find.ancestor(
                of: find.text('Record Payment'),
                matching: find.byType(ElevatedButton),
              ),
            )
            .onPressed,
        isNull,
      );
      await _tap(tester, find.text('Mark Delivered'));
      expect(find.text('Mark as delivered?'), findsOneWidget);
      await _tap(tester, _inDialog('Mark Delivered'));
      expect(orders.writes, ['deliver']);
    });

    testWidgets('a payment is recorded with its method and can be undone', (
      tester,
    ) async {
      final orders = await _pumpApp(
        tester,
        '/orders/order-1',
        orders: [_order()],
      );
      await _tap(tester, find.text('Record Payment'));
      await _tap(tester, find.text('Half'));
      await _tap(tester, find.text('Easypaisa'));
      expect(find.text('Rs 1,000'), findsWidgets);
      await _tap(tester, find.text('Record Rs 1,000'));
      expect(orders.writes, ['payment 1000.0 easypaisa']);
      expect(find.text('Payment of Rs 1,000 recorded'), findsOneWidget);
      expect(
        find.text('Balance now Rs 1,000 · 4 Oct, 9:41 AM'),
        findsOneWidget,
      );

      await _tap(tester, find.text('Undo'));
      expect(orders.writes.last, 'delete payment-1');
      expect(find.text('Payment removed'), findsOneWidget);
    });

    testWidgets('undo still works after leaving the order', (tester) async {
      final orders = await _pumpApp(tester, '/orders', orders: [_order()]);
      await _tap(tester, find.text('Faisal Shah'));
      await _tap(tester, find.text('Record Payment'));
      await _tap(tester, find.text('Record Rs 2,000'));
      // The system back; the toast covers the header's back button.
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Record Payment'), findsNothing);
      await _tap(tester, find.text('Undo'));
      expect(orders.writes, ['payment 2000.0 cash', 'delete payment-1']);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a tap puts the confirmation away', (tester) async {
      await _pumpApp(tester, '/orders/order-1', orders: [_order()]);
      await _tap(tester, find.text('Change Status'));
      await _tap(tester, find.text('Save Status'));
      await _tap(tester, find.text('Moved to Cutting'));
      expect(find.text('Moved to Cutting'), findsNothing);
    });

    testWidgets('more than the balance cannot be recorded', (tester) async {
      await _pumpApp(tester, '/orders/order-1', orders: [_order()]);
      await _tap(tester, find.text('Record Payment'));
      await tester.enterText(find.byType(EditableText), '5000');
      await tester.pumpAndSettle();
      expect(find.text('More than the Rs 2,000 outstanding'), findsOneWidget);
      expect(
        tester
            .widget<ElevatedButton>(
              find.ancestor(
                of: find.text('Record payment'),
                matching: find.byType(ElevatedButton),
              ),
            )
            .onPressed,
        isNull,
      );
    });

    testWidgets('a delivered order with a balance still takes payments', (
      tester,
    ) async {
      await _pumpApp(
        tester,
        '/orders/order-1',
        orders: [_order(status: 'Delivered')],
      );
      expect(find.text('Record Payment'), findsOneWidget);
      expect(find.text('Change Status'), findsNothing);
      expect(find.text('Mark Delivered'), findsNothing);
    });

    testWidgets('the reminder opens WhatsApp with the message typed in', (
      tester,
    ) async {
      await _pumpApp(
        tester,
        '/orders/order-1',
        orders: [_order(status: 'Ready')],
      );
      await _tap(tester, find.text('Reminder'));
      expect(find.text('To Faisal Shah · 0300 412 8876'), findsOneWidget);
      await _tap(tester, find.text('Open WhatsApp'));
      final link = _opened.single;
      expect(link.host, 'wa.me');
      expect(link.path, '/923004128876');
      expect(
        link.queryParameters['text'],
        'Assalam o Alaikum Faisal Shah. Your Shalwar Kameez order (TK-0042) '
        'is ready for pickup at Hassan Tailors. Balance due: Rs 2,000. Shop '
        'timings 11am–9pm.',
      );
    });

    testWidgets('deleting an order asks first and goes back', (tester) async {
      final orders = await _pumpApp(tester, '/orders', orders: [_order()]);
      await _tap(tester, find.text('Faisal Shah'));
      await _tap(tester, find.byTooltip('More'));
      await _tap(tester, find.text('Delete order'));
      expect(find.text('Delete TK-0042?'), findsOneWidget);
      await _tap(tester, find.text('Delete permanently'));
      expect(orders.writes, ['delete order order-1']);
      expect(find.text('No orders yet'), findsOneWidget);
    });
  });

  group('order list', () {
    final late = _order(id: 'late', due: DateTime(2026, 10, 2));
    final dueToday = _order(id: 'today', status: 'Ready', due: _today);
    final upcoming = _order(id: 'upcoming');

    testWidgets('counts open orders and what is outstanding', (tester) async {
      await _pumpApp(tester, '/orders', orders: [upcoming, late, dueToday]);
      expect(find.text('3 open · Rs 6,000 outstanding'), findsOneWidget);
      expect(find.text('Overdue 2 days'.toUpperCase()), findsOneWidget);
      expect(find.text('Today, 4 Oct'), findsOneWidget);
      expect(find.text('Deliver ›'), findsOneWidget);
      expect(find.text('12 Oct · in 8 days'), findsOneWidget);
      // Late orders come first.
      expect(
        tester.getTopLeft(find.text('OVERDUE 2 DAYS')).dy,
        lessThan(tester.getTopLeft(find.text('Today, 4 Oct')).dy),
      );
    });

    testWidgets('the overdue filter lists late orders under a summary', (
      tester,
    ) async {
      await _pumpApp(tester, '/orders', orders: [upcoming, late, dueToday]);
      await _tap(tester, find.text('Overdue'));
      expect(find.text('1 order past its delivery date'), findsOneWidget);
      expect(find.text('Rs 2,000 outstanding across it'), findsOneWidget);
      expect(find.text('Remind ›'), findsOneWidget);
      expect(find.text('Today, 4 Oct'), findsNothing);
    });

    testWidgets('a filter with nothing in it says so', (tester) async {
      await _pumpApp(tester, '/orders', orders: [upcoming]);
      await _tap(tester, find.text('Overdue'));
      expect(find.text('Nothing overdue'), findsOneWidget);
      await _tap(tester, find.text('Today'));
      expect(find.text('Nothing due today'), findsOneWidget);
    });
  });

  group('new order', () {
    testWidgets('started from a customer, it belongs to that customer', (
      tester,
    ) async {
      final orders = await _pumpApp(tester, '/customers/${_older.id}');
      await _tap(tester, find.text('Create Order'));
      expect(find.text('Faisal Shah'), findsOneWidget);
      expect(find.text('TK-0043'), findsOneWidget);
      await tester.enterText(_field('Fabric'), 'Cotton, sky blue');
      await tester.enterText(_field('Total price'), '6500');
      await tester.enterText(_field('Advance paid'), '2000');
      await tester.pumpAndSettle();
      // The balance is on the card and in the bar that stays in view.
      expect(find.text('Rs 4,500'), findsNWidgets(2));
      await _tap(tester, find.text('Save Order'));

      final added = orders.added!;
      expect(added.customerId, _older.id);
      expect(added.measurementId, _formal.id);
      expect(added.garmentType, 'Shalwar Kameez');
      expect(added.fabric, 'Cotton, sky blue');
      expect(added.totalAmount, 6500);
      expect(added.paidAmount, 2000);
      expect(added.status, 'Received');
      expect(added.deliveryDate, DateTime(2026, 10, 11));
      // The new order opens in place of the form.
      expect(find.text('Record Payment'), findsOneWidget);
    });

    testWidgets('needs a customer and a total', (tester) async {
      final orders = await _pumpApp(tester, '/orders/new');
      await _tap(tester, find.text('Save Order'));
      expect(find.text('Choose who the order is for'), findsOneWidget);
      expect(find.text('Enter the total price'), findsOneWidget);
      expect(orders.added, isNull);
    });

    testWidgets('the advance cannot be more than the total', (tester) async {
      final orders = await _pumpApp(
        tester,
        '/orders/new?customerId=${_older.id}',
      );
      await tester.enterText(_field('Total price'), '1000');
      await tester.enterText(_field('Advance paid'), '1500');
      await tester.pumpAndSettle();
      expect(
        find.text("The advance can't be more than the total"),
        findsOneWidget,
      );
      await _tap(tester, find.text('Save Order'));
      expect(orders.added, isNull);
    });

    testWidgets('a customer is picked from the list', (tester) async {
      await _pumpApp(tester, '/orders/new');
      await _tap(tester, find.text('Choose customer'));
      await _tap(tester, find.text('Bilal Haider'));
      expect(find.text('Bilal Haider'), findsOneWidget);
      expect(find.text('Change'), findsOneWidget);
      // Bilal has no profile for this garment yet.
      expect(find.text('Take Formal Fit'), findsOneWidget);
    });

    testWidgets('a link to a missing customer still opens', (tester) async {
      await _pumpApp(tester, '/orders/new?customerId=missing');
      expect(tester.takeException(), isNull);
      expect(find.text('Choose customer'), findsOneWidget);
    });

    testWidgets('leaving a filled form asks first', (tester) async {
      await _pumpApp(tester, '/orders/new?customerId=${_older.id}');
      await tester.enterText(_field('Total price'), '1000');
      await tester.pumpAndSettle();
      await _tap(tester, find.byTooltip('Back'));
      expect(find.text('Discard this order?'), findsOneWidget);
      await _tap(tester, find.text('Keep editing'));
      expect(find.text('Save Order'), findsOneWidget);
    });
  });

  testWidgets('editing keeps payments and the number', (tester) async {
    final orders = await _pumpApp(
      tester,
      '/orders/order-1/edit',
      orders: [_order()],
    );
    expect(find.text('Edit Order'), findsOneWidget);
    expect(find.text('Paid so far'), findsOneWidget);
    await tester.enterText(_field('Total price'), '800');
    await tester.pumpAndSettle();
    await _tap(tester, find.text('Save Changes'));
    expect(
      find.text("The total can't be less than the Rs 1,000 already paid"),
      findsOneWidget,
    );
    expect(orders.updated, isNull);

    await tester.enterText(_field('Total price'), '3500');
    await tester.pumpAndSettle();
    await _tap(tester, find.text('Save Changes'));
    final updated = orders.updated!;
    expect(updated.totalAmount, 3500);
    expect(updated.paidAmount, 1000);
    expect(updated.orderNumber, 42);
    expect(updated.pieces, 2);
    // Back on the order page.
    expect(find.text('Edit Order'), findsNothing);
    expect(find.text('Record Payment'), findsOneWidget);
  });
}
