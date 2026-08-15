import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tailor_khata/features/measurements/domain/entities/measurement.dart';
import 'package:tailor_khata/features/measurements/presentation/providers/measurement_providers.dart';

class MeasurementsNotifier extends FamilyAsyncNotifier<List<Measurement>, String> {
  @override
  Future<List<Measurement>> build(String arg) async {
    return _fetchMeasurements(arg);
  }

  Future<List<Measurement>> _fetchMeasurements(String customerId) async {
    final getMeasurements = ref.watch(getMeasurementsByCustomerUsecaseProvider);
    final result = await getMeasurements(customerId);
    return result.fold(
      (failure) => throw Exception(failure.message),
      (measurements) => measurements,
    );
  }

  Future<void> loadMeasurements() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchMeasurements(arg));
  }

  Future<void> addMeasurement(Measurement measurement) async {
    final addMeasurementUsecase = ref.read(addMeasurementUsecaseProvider);
    final result = await addMeasurementUsecase(measurement);
    result.fold(
      (failure) => state = AsyncValue.error(failure.message, StackTrace.current),
      (_) => loadMeasurements(),
    );
  }

  Future<void> updateMeasurement(Measurement measurement) async {
    final updateMeasurementUsecase = ref.read(updateMeasurementUsecaseProvider);
    final result = await updateMeasurementUsecase(measurement);
    result.fold(
      (failure) => state = AsyncValue.error(failure.message, StackTrace.current),
      (_) => loadMeasurements(),
    );
  }

  Future<void> deleteMeasurement(String id) async {
    final deleteMeasurementUsecase = ref.read(deleteMeasurementUsecaseProvider);
    final result = await deleteMeasurementUsecase(id);
    result.fold(
      (failure) => state = AsyncValue.error(failure.message, StackTrace.current),
      (_) => loadMeasurements(),
    );
  }
}

final measurementsNotifierProvider = AsyncNotifierProviderFamily<MeasurementsNotifier, List<Measurement>, String>(() {
  return MeasurementsNotifier();
});
