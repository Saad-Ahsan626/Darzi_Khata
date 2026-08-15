import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tailor_khata/core/providers/database_provider.dart';

import 'package:tailor_khata/features/measurements/data/datasources/measurement_local_data_source.dart';
import 'package:tailor_khata/features/measurements/data/repositories/measurement_repository_impl.dart';
import 'package:tailor_khata/features/measurements/domain/repositories/measurement_repository.dart';
import 'package:tailor_khata/features/measurements/domain/usecases/add_measurement.dart';
import 'package:tailor_khata/features/measurements/domain/usecases/delete_measurement.dart';
import 'package:tailor_khata/features/measurements/domain/usecases/get_measurement_by_id.dart';
import 'package:tailor_khata/features/measurements/domain/usecases/get_measurements_by_customer.dart';
import 'package:tailor_khata/features/measurements/domain/usecases/update_measurement.dart';

final measurementLocalDataSourceProvider = Provider<MeasurementLocalDataSource>(
  (ref) {
    final dbHelper = ref.watch(databaseProvider);
    return MeasurementLocalDataSourceImpl(dbHelper: dbHelper);
  },
);

final measurementRepositoryProvider = Provider<MeasurementRepository>((ref) {
  final localDataSource = ref.watch(measurementLocalDataSourceProvider);
  return MeasurementRepositoryImpl(localDataSource: localDataSource);
});

final getMeasurementsByCustomerUsecaseProvider =
    Provider<GetMeasurementsByCustomer>((ref) {
      return GetMeasurementsByCustomer(
        ref.watch(measurementRepositoryProvider),
      );
    });

final getMeasurementByIdUsecaseProvider = Provider<GetMeasurementById>((ref) {
  return GetMeasurementById(ref.watch(measurementRepositoryProvider));
});

final addMeasurementUsecaseProvider = Provider<AddMeasurement>((ref) {
  return AddMeasurement(ref.watch(measurementRepositoryProvider));
});

final updateMeasurementUsecaseProvider = Provider<UpdateMeasurement>((ref) {
  return UpdateMeasurement(ref.watch(measurementRepositoryProvider));
});

final deleteMeasurementUsecaseProvider = Provider<DeleteMeasurement>((ref) {
  return DeleteMeasurement(ref.watch(measurementRepositoryProvider));
});
