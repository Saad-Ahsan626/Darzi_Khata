import 'dart:convert';
import 'package:tailor_khata/features/measurements/domain/entities/measurement.dart';

class MeasurementModel extends Measurement {
  const MeasurementModel({
    required super.id,
    required super.customerId,
    required super.garmentType,
    required super.measurementData,
    required super.createdAt,
    super.ownerId = 'guest',
    super.syncStatus = 0,
  });

  factory MeasurementModel.fromEntity(Measurement entity) {
    return MeasurementModel(
      id: entity.id,
      customerId: entity.customerId,
      garmentType: entity.garmentType,
      measurementData: Map<String, dynamic>.from(entity.measurementData),
      createdAt: entity.createdAt,
      ownerId: entity.ownerId,
      syncStatus: entity.syncStatus,
    );
  }

  factory MeasurementModel.fromJson(Map<String, dynamic> json) {
    return MeasurementModel(
      id: json['id'] as String,
      customerId: json['customerId'] as String,
      garmentType: json['garmentType'] as String,
      measurementData: jsonDecode(json['measurementData'] as String) as Map<String, dynamic>,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
      ownerId: json['ownerId'] as String? ?? 'guest',
      syncStatus: json['syncStatus'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerId': customerId,
      'garmentType': garmentType,
      'measurementData': jsonEncode(measurementData),
      'createdAt': createdAt.millisecondsSinceEpoch,
      'ownerId': ownerId,
      'syncStatus': syncStatus,
    };
  }
}
