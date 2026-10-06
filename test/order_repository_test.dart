import 'package:flutter_test/flutter_test.dart';
import 'package:tailor_khata/core/database/database_helper.dart';
import 'package:tailor_khata/core/error/failures.dart';
import 'package:tailor_khata/core/usecase/usecase.dart';
import 'package:tailor_khata/features/customers/data/datasources/customer_local_data_source.dart';
import 'package:tailor_khata/features/customers/data/models/customer_model.dart';
import 'package:tailor_khata/features/orders/data/datasources/order_local_data_source.dart';
import 'package:tailor_khata/features/orders/data/repositories/order_repository_impl.dart';
import 'package:tailor_khata/features/orders/domain/entities/order.dart';
import 'package:tailor_khata/features/orders/domain/entities/payment.dart';
import 'package:tailor_khata/features/orders/domain/repositories/order_repository.dart';
import 'package:tailor_khata/features/orders/domain/usecases/change_order_status.dart';
import 'package:tailor_khata/features/orders/domain/usecases/deliver_order.dart';
import 'package:tailor_khata/features/orders/domain/usecases/get_payments.dart';
import 'package:tailor_khata/features/orders/domain/usecases/record_payment.dart';
import 'package:tailor_khata/features/orders/domain/usecases/update_order.dart';

import 'support/database_test_support.dart';

final _ordered = DateTime(2026, 9, 28, 11);
final _later = DateTime(2026, 10, 3, 17, 10);
final _evenLater = DateTime(2026, 10, 4, 9, 41);

Order _newOrder(String id, {double paid = 2000, DateTime? createdAt}) => Order(
  id: id,
  customerId: 'faisal',
  garmentType: 'Shalwar Kameez',
  pieces: 2,
  fabric: 'Wash & wear, off-white',
  status: 'Received',
  deliveryDate: DateTime(2026, 10, 4),
  totalAmount: 4800,
  paidAmount: paid,
  createdAt: createdAt ?? _ordered,
);

void main() {
  late DatabaseHelper database;
  late OrderRepository repository;

  setUpAll(useDesktopDatabases);

  setUp(() async {
    database = await openTestDatabase();
    await CustomerLocalDataSourceImpl(dbHelper: database).addCustomer(
      CustomerModel(
        id: 'faisal',
        name: 'Faisal Shah',
        createdAt: DateTime(2026, 3, 1),
      ),
    );
    repository = OrderRepositoryImpl(
      localDataSource: OrderLocalDataSourceImpl(dbHelper: database),
    );
  });

  Future<Order> stored(String id) async =>
      valueOf(await repository.getOrderById(id));

  Future<List<String>> stages(String id) async => [
    for (final event in valueOf(await repository.getStatusHistory(id)))
      event.status,
  ];

  Future<void> add(Order order) async => valueOf(await repository.addOrder(order));

  group('new orders', () {
    test('receive consecutive order numbers', () async {
      await add(_newOrder('first'));
      await add(_newOrder('second'));
      expect((await stored('first')).orderNumber, 1);
      expect((await stored('second')).orderNumber, 2);

      final db = await database.database;
      final settings = (await db.query('shop_settings')).single;
      expect(settings['nextOrderNumber'], 3);
    });

    test('keep their number after an earlier order is deleted', () async {
      await add(_newOrder('first'));
      await add(_newOrder('second'));
      valueOf(await repository.deleteOrder('second'));
      await add(_newOrder('third'));
      expect((await stored('third')).orderNumber, 3);
    });

    test('start their history and record the advance', () async {
      await add(_newOrder('order'));
      final order = await stored('order');
      expect(order.pieces, 2);
      expect(order.fabric, 'Wash & wear, off-white');
      expect(order.paidAmount, 2000);
      expect(order.balance, 2800);

      final history = valueOf(await repository.getStatusHistory('order'));
      expect(history.single.status, 'Received');
      expect(history.single.changedAt, _ordered);

      final advance = valueOf(
        await repository.getPaymentsByOrder('order'),
      ).single;
      expect(advance.amount, 2000);
      expect(advance.method, PaymentMethod.cash);
      expect(advance.isAdvance, isTrue);
      expect(advance.paidAt, _ordered);
    });

    test('without an advance have no payment', () async {
      await add(_newOrder('order', paid: 0));
      expect(valueOf(await repository.getPaymentsByOrder('order')), isEmpty);
      expect((await stored('order')).paidAmount, 0);
    });
  });

  group('production stages', () {
    late ChangeOrderStatus changeStatus;

    setUp(() async {
      changeStatus = ChangeOrderStatus(repository);
      await add(_newOrder('order'));
    });

    Future<Object?> moveTo(String status) => changeStatus(
      ChangeOrderStatusParams(
        orderId: 'order',
        status: status,
        changedAt: _later,
      ),
    );

    test('add to the history and leave the money alone', () async {
      await moveTo('Cutting');
      final order = await stored('order');
      expect(order.status, 'Cutting');
      expect(order.paidAmount, 2000);
      expect(order.deliveredAt, isNull);
      expect(await stages('order'), ['Received', 'Cutting']);
      expect(valueOf(await repository.getPaymentsByOrder('order')), hasLength(1));
    });

    test('are not recorded twice when unchanged', () async {
      await moveTo('Cutting');
      await moveTo('Cutting');
      expect(await stages('order'), ['Received', 'Cutting']);
    });

    test('do not include delivery', () async {
      final result = await changeStatus(
        ChangeOrderStatusParams(
          orderId: 'order',
          status: 'Delivered',
          changedAt: _later,
        ),
      );
      expect(failureOf(result), isA<ValidationFailure>());
      expect((await stored('order')).status, 'Received');
      expect(await stages('order'), ['Received']);
    });
  });

  group('payments', () {
    late RecordPayment recordPayment;

    setUp(() async {
      recordPayment = RecordPayment(repository);
      await add(_newOrder('order'));
    });

    RecordPaymentParams payment(double amount, {DateTime? paidAt}) =>
        RecordPaymentParams(
          orderId: 'order',
          amount: amount,
          method: PaymentMethod.easypaisa,
          paidAt: paidAt ?? _later,
        );

    test('reduce the balance and are listed newest first', () async {
      final recorded = valueOf(await recordPayment(payment(1500)));
      expect(recorded.amount, 1500);
      expect(recorded.method, PaymentMethod.easypaisa);
      expect(recorded.isAdvance, isFalse);
      expect(recorded.paidAt, _later);

      final order = await stored('order');
      expect(order.paidAmount, 3500);
      expect(order.balance, 1300);
      expect(order.status, 'Received');

      final payments = valueOf(await repository.getPaymentsByOrder('order'));
      expect([for (final p in payments) p.amount], [1500, 2000]);
    });

    test('are refused above the balance or at zero', () async {
      expect(failureOf(await recordPayment(payment(2801))), isA<ValidationFailure>());
      expect(failureOf(await recordPayment(payment(0))), isA<ValidationFailure>());
      expect((await stored('order')).paidAmount, 2000);

      valueOf(await recordPayment(payment(2800)));
      expect((await stored('order')).balance, 0);
    });

    test('return to the balance when deleted', () async {
      final recorded = valueOf(await recordPayment(payment(1500)));
      valueOf(await repository.deletePayment(recorded.id));
      expect((await stored('order')).paidAmount, 2000);
      expect(valueOf(await repository.getPaymentsByOrder('order')), hasLength(1));
    });

    test('from every order are listed newest first', () async {
      await add(_newOrder('other', paid: 500, createdAt: _evenLater));
      valueOf(await recordPayment(payment(1500)));
      final payments = valueOf(await GetPayments(repository)(const NoParams()));
      expect(
        [for (final p in payments) (p.orderId, p.amount)],
        [('other', 500.0), ('order', 1500.0), ('order', 2000.0)],
      );
    });
  });

  group('delivery', () {
    late DeliverOrder deliver;

    setUp(() async {
      deliver = DeliverOrder(repository);
      await add(_newOrder('order'));
    });

    test('keeps the balance owed by default', () async {
      valueOf(
        await deliver(DeliverOrderParams(orderId: 'order', deliveredAt: _later)),
      );
      final order = await stored('order');
      expect(order.status, 'Delivered');
      expect(order.deliveredAt, _later);
      expect(order.paidAmount, 2000);
      expect(await stages('order'), ['Received', 'Delivered']);
    });

    test('can settle the balance as a payment made on delivery', () async {
      valueOf(
        await deliver(
          DeliverOrderParams(
            orderId: 'order',
            deliveredAt: _later,
            settleBalance: true,
          ),
        ),
      );
      final order = await stored('order');
      expect(order.status, 'Delivered');
      expect(order.balance, 0);

      final settlement = valueOf(
        await repository.getPaymentsByOrder('order'),
      ).first;
      expect(settlement.amount, 2800);
      expect(settlement.paidAt, _later);
      expect(settlement.isAdvance, isFalse);
    });

    test('happens once and ends production', () async {
      valueOf(
        await deliver(DeliverOrderParams(orderId: 'order', deliveredAt: _later)),
      );
      final again = await deliver(
        DeliverOrderParams(orderId: 'order', deliveredAt: _evenLater),
      );
      final restaged = await ChangeOrderStatus(repository)(
        ChangeOrderStatusParams(
          orderId: 'order',
          status: 'Ready',
          changedAt: _evenLater,
        ),
      );
      expect(failureOf(again), isA<ValidationFailure>());
      expect(failureOf(restaged), isA<ValidationFailure>());
      expect((await stored('order')).deliveredAt, _later);
      expect(await stages('order'), ['Received', 'Delivered']);
    });

    test('still allows the balance to be collected afterwards', () async {
      valueOf(
        await deliver(DeliverOrderParams(orderId: 'order', deliveredAt: _later)),
      );
      valueOf(
        await RecordPayment(repository)(
          RecordPaymentParams(
            orderId: 'order',
            amount: 2800,
            method: PaymentMethod.cash,
            paidAt: _evenLater,
          ),
        ),
      );
      final order = await stored('order');
      expect(order.balance, 0);
      // Collecting later does not move the delivery time.
      expect(order.deliveredAt, _later);
    });
  });

  group('editing an order', () {
    late UpdateOrder updateOrder;

    setUp(() async {
      updateOrder = UpdateOrder(repository);
      await add(_newOrder('order'));
    });

    Order edited({double total = 5200}) => Order(
      id: 'order',
      customerId: 'faisal',
      garmentType: 'Kurta',
      pieces: 3,
      fabric: 'Cotton, sky blue',
      notes: 'Collar 1 inch wider',
      // A copy made before the status and payment below were saved.
      status: 'Received',
      deliveryDate: DateTime(2026, 10, 9),
      totalAmount: total,
      paidAmount: 0,
      createdAt: _ordered,
    );

    test('saves details and keeps status, payments and number', () async {
      valueOf(
        await repository.changeStatus(
          orderId: 'order',
          status: 'Stitching',
          changedAt: _later,
        ),
      );
      valueOf(await updateOrder(edited()));

      final order = await stored('order');
      expect(order.garmentType, 'Kurta');
      expect(order.pieces, 3);
      expect(order.fabric, 'Cotton, sky blue');
      expect(order.notes, 'Collar 1 inch wider');
      expect(order.deliveryDate, DateTime(2026, 10, 9));
      expect(order.totalAmount, 5200);
      expect(order.status, 'Stitching');
      expect(order.paidAmount, 2000);
      expect(order.orderNumber, 1);
    });

    test('cannot lower the total below the amount paid', () async {
      final result = await updateOrder(edited(total: 1500));
      expect(failureOf(result), isA<ValidationFailure>());
      expect((await stored('order')).totalAmount, 4800);
    });
  });

  test('deleting an order removes its payments and history', () async {
    await add(_newOrder('order'));
    valueOf(await repository.deleteOrder('order'));
    final db = await database.database;
    expect(await db.query('payments'), isEmpty);
    expect(await db.query('order_status_events'), isEmpty);
  });
}
