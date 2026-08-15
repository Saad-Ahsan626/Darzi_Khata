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
  late final MeasurementLocalDataSource _dataSource;

  @override
  Future<List<Measurement>> build() async {
    _dataSource = ref.watch(measurementLocalDataSourceProvider);
    return _fetchMeasurements();
  }

  Future<List<Measurement>> _fetchMeasurements() async {
    return await _dataSource.getMeasurements();
  }

  Future<void> saveMeasurement(Measurement measurement) async {
    final previousState = state.value;
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
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      if (previousState != null) {
        state = AsyncValue.data(previousState);
      }
    }
  }

  Future<void> deleteMeasurement(String id) async {
    final previousState = state.value;
    
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
