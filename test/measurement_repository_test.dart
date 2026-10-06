import 'package:flutter_test/flutter_test.dart';
import 'package:tailor_khata/core/database/database_helper.dart';
import 'package:tailor_khata/features/customers/data/datasources/customer_local_data_source.dart';
import 'package:tailor_khata/features/customers/data/models/customer_model.dart';
import 'package:tailor_khata/features/measurements/data/datasources/measurement_local_data_source.dart';
import 'package:tailor_khata/features/measurements/data/repositories/measurement_repository_impl.dart';
import 'package:tailor_khata/features/measurements/domain/entities/fit_profile.dart';
import 'package:tailor_khata/features/measurements/domain/entities/measurement.dart';
import 'package:tailor_khata/features/measurements/domain/entities/measurement_unit.dart';
import 'package:tailor_khata/features/measurements/domain/repositories/measurement_repository.dart';
import 'package:tailor_khata/features/orders/data/datasources/order_local_data_source.dart';
import 'package:tailor_khata/features/orders/data/models/order_model.dart';

import 'support/database_test_support.dart';

final _measured = DateTime(2026, 9, 18, 18, 40);
final _remeasured = DateTime(2026, 10, 4, 12);

Measurement _profile(
  String id, {
  String fitProfile = FitProfile.formal,
  Map<String, double> values = const {'chest': 40.5, 'length': 42},
  MeasurementUnit unit = MeasurementUnit.inches,
  String? note,
  DateTime? updatedAt,
}) => Measurement(
  id: id,
  customerId: 'faisal',
  garmentType: 'Shalwar Kameez',
  fitProfile: fitProfile,
  measurementData: values,
  unit: unit,
  note: note,
  createdAt: _measured,
  updatedAt: updatedAt ?? _measured,
);

void main() {
  late DatabaseHelper database;
  late MeasurementRepository repository;

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
    repository = MeasurementRepositoryImpl(
      localDataSource: MeasurementLocalDataSourceImpl(dbHelper: database),
    );
  });

  Future<List<Measurement>> profiles() async =>
      valueOf(await repository.getMeasurementsByCustomer('faisal'));

  test('values, unit and note are read back as saved', () async {
    valueOf(
      await repository.addMeasurement(
        _profile(
          'formal',
          unit: MeasurementUnit.centimeters,
          note: 'Collar 1 inch wider than standard',
        ),
      ),
    );
    final saved = (await profiles()).single;
    expect(saved.measurementData, {'chest': 40.5, 'length': 42.0});
    expect(saved.fitProfile, FitProfile.formal);
    expect(saved.unit, MeasurementUnit.centimeters);
    expect(saved.note, 'Collar 1 inch wider than standard');
    expect(saved.updatedAt, _measured);
  });

  test('formal and casual fits are kept as separate profiles', () async {
    valueOf(await repository.addMeasurement(_profile('formal')));
    valueOf(
      await repository.addMeasurement(
        _profile(
          'casual',
          fitProfile: FitProfile.casual,
          values: const {'chest': 42, 'length': 43},
        ),
      ),
    );
    final byFit = {
      for (final profile in await profiles())
        profile.fitProfile: profile.measurementData['chest'],
    };
    expect(byFit, {FitProfile.formal: 40.5, FitProfile.casual: 42.0});
  });

  test('saving a profile again updates it and keeps its orders linked', () async {
    valueOf(await repository.addMeasurement(_profile('formal')));
    final orders = OrderLocalDataSourceImpl(dbHelper: database);
    await orders.addOrder(
      OrderModel(
        id: 'order',
        customerId: 'faisal',
        measurementId: 'formal',
        garmentType: 'Shalwar Kameez',
        status: 'Received',
        deliveryDate: DateTime(2026, 10, 12),
        totalAmount: 4800,
        paidAmount: 0,
        createdAt: _measured,
      ),
    );

    valueOf(
      await repository.updateMeasurement(
        _profile(
          'formal',
          values: const {'chest': 41, 'length': 42},
          updatedAt: _remeasured,
        ),
      ),
    );

    final saved = (await profiles()).single;
    expect(saved.measurementData['chest'], 41);
    expect(saved.updatedAt, _remeasured);
    expect((await orders.getOrderById('order')).measurementId, 'formal');
  });

  group('measurement units', () {
    test('inches are stored as entered', () {
      expect(MeasurementUnit.inches.toInches(40.5), 40.5);
      expect(MeasurementUnit.inches.fromInches(40.5), 40.5);
    });

    test('centimeters convert to and from inches', () {
      expect(MeasurementUnit.centimeters.fromInches(36), closeTo(91.44, 1e-9));
      expect(MeasurementUnit.centimeters.toInches(91.44), closeTo(36, 1e-9));
    });

    test('are found by their stored code', () {
      expect(MeasurementUnit.fromCode('in'), MeasurementUnit.inches);
      expect(MeasurementUnit.fromCode('cm'), MeasurementUnit.centimeters);
    });
  });
}
