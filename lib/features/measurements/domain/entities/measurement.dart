import 'package:equatable/equatable.dart';
import 'package:tailor_khata/features/measurements/domain/entities/fit_profile.dart';
import 'package:tailor_khata/features/measurements/domain/entities/measurement_unit.dart';

/// A customer's measurements for one garment and fit profile.
class Measurement extends Equatable {
  final String id;
  final String customerId;
  final String garmentType;
  final String fitProfile;

  /// Field key to value in inches, whichever [unit] the profile is shown in.
  final Map<String, double> measurementData;
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
    this.unit = MeasurementUnit.inches,
    this.note,
    required this.createdAt,
    required this.updatedAt,
    this.ownerId = 'guest',
    this.syncStatus = 0,
  });

  @override
  List<Object?> get props => [
        id,
        customerId,
        garmentType,
        fitProfile,
        measurementData,
        unit,
        note,
        createdAt,
        updatedAt,
        ownerId,
        syncStatus,
      ];
}
