import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tailor_khata/core/database/database_helper.dart';
import 'package:tailor_khata/features/measurements/data/datasources/measurement_local_data_source.dart';
import 'package:tailor_khata/features/measurements/data/models/measurement_model.dart';
import 'package:tailor_khata/features/measurements/domain/entities/measurement.dart';

final measurementLocalDataSourceProvider = Provider<MeasurementLocalDataSource>((ref) {
  final dbHelper = DatabaseHelper.instance;
  return MeasurementLocalDataSourceImpl(dbHelper: dbHelper);
});

final measurementsNotifierProvider = AsyncNotifierProvider<MeasurementsNotifier, List<Measurement>>(() {
  return MeasurementsNotifier();
});

class MeasurementsNotifier extends AsyncNotifier<List<Measurement>> {
  MeasurementLocalDataSource get _dataSource =>
      ref.read(measurementLocalDataSourceProvider);

  @override
  Future<List<Measurement>> build() async {
    return _fetchMeasurements();
  }

  Future<List<Measurement>> _fetchMeasurements() async {
    return await _dataSource.getMeasurements();
  }

  /// Saves a profile and returns whether it was stored. When it was not, the
  /// list goes back to what it held before.
  Future<bool> saveMeasurement(Measurement measurement) async {
    final previousState = state.valueOrNull;
    final model = MeasurementModel.fromEntity(measurement);
    
    // Optimistic update
    if (previousState != null) {
      final exists = previousState.any((m) => m.id == measurement.id);
      if (exists) {
        state = AsyncValue.data(
          previousState.map((m) => m.id == measurement.id ? measurement : m).toList()
        );
      } else {
        state = AsyncValue.data([measurement, ...previousState]);
      }
    }

    try {
      await _dataSource.saveMeasurement(model);
      return true;
    } on Exception {
      if (previousState != null) {
        state = AsyncValue.data(previousState);
      }
      return false;
    }
  }

  Future<void> deleteMeasurement(String id) async {
    final previousState = state.valueOrNull;
    
    // Optimistic update
    if (previousState != null) {
      state = AsyncValue.data(previousState.where((m) => m.id != id).toList());
    }

    try {
      await _dataSource.deleteMeasurement(id);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      if (previousState != null) {
        state = AsyncValue.data(previousState);
      }
    }
  }
}
