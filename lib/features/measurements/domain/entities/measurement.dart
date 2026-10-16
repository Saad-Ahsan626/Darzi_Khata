import 'package:equatable/equatable.dart';
import 'package:tailor_khata/features/measurements/domain/entities/fit_profile.dart';
import 'package:tailor_khata/features/measurements/domain/entities/measurement_unit.dart';

/// A value a field held before it was last changed, with the time the
/// profile was last saved holding it.
class PreviousMeasurement extends Equatable {
  /// In inches.
  final double value;
  final DateTime recordedAt;

  const PreviousMeasurement(this.value, this.recordedAt);

  @override
  List<Object?> get props => [value, recordedAt];
}

/// A customer's measurements for one garment and fit profile.
class Measurement extends Equatable {
  final String id;
  final String customerId;
  final String garmentType;
  final String fitProfile;

  /// Field key to value in inches, whichever [unit] the profile is shown in.
  final Map<String, double> measurementData;

  /// For each field that has changed, the value it held before.
  final Map<String, PreviousMeasurement> previousValues;
  final MeasurementUnit unit;

  /// Stitching note for this profile.
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String ownerId;
  final int syncStatus;

  const Measurement({
    required this.id,
    required this.customerId,
    required this.garmentType,
    this.fitProfile = FitProfile.formal,
    required this.measurementData,
    this.previousValues = const {},
    this.unit = MeasurementUnit.inches,
    this.note,
    required this.createdAt,
    required this.updatedAt,
    this.ownerId = 'guest',
    this.syncStatus = 0,
  });

  /// This profile with new [values] and [note], saved [at]. Each field whose
  /// value changes or is cleared keeps the value it had as its previous one.
  Measurement revise({
    required Map<String, double> values,
    required String? note,
    required DateTime at,
  }) {
    final previous = Map.of(previousValues);
    measurementData.forEach((key, old) {
      if (values[key] != old) {
        previous[key] = PreviousMeasurement(old, updatedAt);
      }
    });
    return copyWith(
      measurementData: Map.unmodifiable(values),
      previousValues: Map.unmodifiable(previous),
      note: note,
      updatedAt: at,
    );
  }

  Measurement copyWith({
    Map<String, double>? measurementData,
    Map<String, PreviousMeasurement>? previousValues,
    MeasurementUnit? unit,
    String? note,
    DateTime? updatedAt,
  }) {
    return Measurement(
      id: id,
      customerId: customerId,
      garmentType: garmentType,
      fitProfile: fitProfile,
      measurementData: measurementData ?? this.measurementData,
      previousValues: previousValues ?? this.previousValues,
      unit: unit ?? this.unit,
      note: note ?? this.note,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      ownerId: ownerId,
      syncStatus: syncStatus,
    );
  }

  @override
  List<Object?> get props => [
    id,
    customerId,
    garmentType,
    fitProfile,
    measurementData,
    previousValues,
    unit,
    note,
    createdAt,
    updatedAt,
    ownerId,
    syncStatus,
  ];
}
