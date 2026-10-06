import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tailor_khata/core/providers/database_provider.dart';
import 'package:tailor_khata/features/customers/data/datasources/customer_local_data_source.dart';
import 'package:tailor_khata/features/customers/data/repositories/customer_repository_impl.dart';
import 'package:tailor_khata/features/customers/domain/entities/customer.dart';
import 'package:tailor_khata/features/customers/presentation/providers/customers_notifier.dart';
import 'package:tailor_khata/features/measurements/data/datasources/measurement_local_data_source.dart';
import 'package:tailor_khata/features/measurements/data/models/measurement_model.dart';
import 'package:tailor_khata/features/measurements/presentation/providers/measurements_notifier.dart';
import 'package:tailor_khata/features/orders/data/datasources/order_local_data_source.dart';
import 'package:tailor_khata/features/orders/data/models/order_model.dart';
import 'package:tailor_khata/features/orders/presentation/providers/orders_notifier.dart';

import 'support/database_test_support.dart';

void main() {
  setUpAll(useDesktopDatabases);

  test('a customer is read back as saved, including the note', () async {
    final repository = CustomerRepositoryImpl(
      localDataSource: CustomerLocalDataSourceImpl(
        dbHelper: await openTestDatabase(),
      ),
    );
    final customer = Customer(
      id: 'rameez',
      name: 'Rameez Khan',
      phone: '03045501122',
      address: 'Ichhra, Lahore',
      note: 'Prefers loose fit, collar 1 inch wider',
      createdAt: DateTime(2026, 10, 4),
    );

    valueOf(await repository.addCustomer(customer));

    // Stored rows come back as models, so compare the fields.
    final saved = valueOf(await repository.getCustomers()).single;
    expect(saved.props, customer.props);
  });

  test('deleting a customer clears their orders and measurements from the '
      'lists the screens hold', () async {
    final database = await openTestDatabase();
    final measurements = MeasurementLocalDataSourceImpl(dbHelper: database);
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(database),
        measurementLocalDataSourceProvider.overrideWithValue(measurements),
      ],
    );
    addTearDown(container.dispose);
    final customers = container.read(customersNotifierProvider.notifier);

    final saved = await customers.addCustomer(
      Customer(
        id: 'faisal',
        name: 'Faisal Shah',
        phone: '03004128876',
        createdAt: DateTime(2026, 3, 1),
      ),
    );
    expect(saved, isNull);
    await measurements.saveMeasurement(
      MeasurementModel(
        id: 'profile',
        customerId: 'faisal',
        garmentType: 'Shalwar Kameez',
        measurementData: const {'chest': 40.5},
        createdAt: DateTime(2026, 9, 18),
        updatedAt: DateTime(2026, 9, 18),
      ),
    );
    await OrderLocalDataSourceImpl(dbHelper: database).addOrder(
      OrderModel(
        id: 'order',
        customerId: 'faisal',
        garmentType: 'Shalwar Kameez',
        status: 'Received',
        deliveryDate: DateTime(2026, 10, 12),
        totalAmount: 4800,
        paidAmount: 2000,
        createdAt: DateTime(2026, 9, 28),
      ),
    );
    expect(await container.read(ordersNotifierProvider.future), hasLength(1));
    expect(
      await container.read(measurementsNotifierProvider.future),
      hasLength(1),
    );

    expect(await customers.deleteCustomer('faisal'), isNull);

    expect(await container.read(customersNotifierProvider.future), isEmpty);
    expect(await container.read(ordersNotifierProvider.future), isEmpty);
    expect(await container.read(measurementsNotifierProvider.future), isEmpty);
    final db = await database.database;
    expect(await db.query('payments'), isEmpty);
  });
}
