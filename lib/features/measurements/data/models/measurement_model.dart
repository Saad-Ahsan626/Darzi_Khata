import 'dart:convert';
import 'package:tailor_khata/features/measurements/domain/entities/measurement.dart';
import 'package:tailor_khata/features/measurements/domain/entities/measurement_unit.dart';

class MeasurementModel extends Measurement {
  const MeasurementModel({
    required super.id,
    required super.customerId,
    required super.garmentType,
    super.fitProfile,
    required super.measurementData,
    super.unit,
    super.note,
    required super.createdAt,
    required super.updatedAt,
    super.ownerId = 'guest',
    super.syncStatus = 0,
  });

  factory MeasurementModel.fromEntity(Measurement entity) {
    return MeasurementModel(
      id: entity.id,
      customerId: entity.customerId,
      garmentType: entity.garmentType,
      fitProfile: entity.fitProfile,
      measurementData: Map<String, double>.from(entity.measurementData),
      unit: entity.unit,
      note: entity.note,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      ownerId: entity.ownerId,
      syncStatus: entity.syncStatus,
    );
  }

  factory MeasurementModel.fromJson(Map<String, dynamic> json) {
    final values = jsonDecode(json['measurementData'] as String) as Map<String, dynamic>;
    return MeasurementModel(
      id: json['id'] as String,
      customerId: json['customerId'] as String,
      garmentType: json['garmentType'] as String,
      fitProfile: json['fitProfile'] as String,
      measurementData: values.map((key, value) => MapEntry(key, (value as num).toDouble())),
      unit: MeasurementUnit.fromCode(json['unit'] as String),
      note: json['note'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
      // Rows written before updatedAt existed only have their creation time.
      updatedAt: DateTime.fromMillisecondsSinceEpoch((json['updatedAt'] ?? json['createdAt']) as int),
      ownerId: json['ownerId'] as String? ?? 'guest',
      syncStatus: json['syncStatus'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerId': customerId,
      'garmentType': garmentType,
      'fitProfile': fitProfile,
      'measurementData': jsonEncode(measurementData),
      'unit': unit.code,
      'note': note,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'ownerId': ownerId,
      'syncStatus': syncStatus,
    };
  }
}
