import 'package:equatable/equatable.dart';

class Measurement extends Equatable {
  final String id;
  final String customerId;
  final String garmentType;
  final Map<String, dynamic> measurementData;
  final DateTime createdAt;
  final String ownerId;
  final int syncStatus;

  const Measurement({
    required this.id,
    required this.customerId,
    required this.garmentType,
    required this.measurementData,
    required this.createdAt,
    this.ownerId = 'guest',
    this.syncStatus = 0,
  });

  @override
  List<Object?> get props => [
        id,
        customerId,
        garmentType,
        measurementData,
        createdAt,
        ownerId,
        syncStatus,
      ];
}
