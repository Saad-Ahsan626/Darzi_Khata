import 'package:equatable/equatable.dart';

class Order extends Equatable {
  final String id;
  final String customerId;
  final String? measurementId;
  final String garmentType;
  final String status;
  final DateTime deliveryDate;
  final double totalAmount;
  final double advancePaid;
  final String? notes;
  final DateTime createdAt;
  final String ownerId;
  final int syncStatus;

  const Order({
    required this.id,
    required this.customerId,
    this.measurementId,
    required this.garmentType,
    required this.status,
    required this.deliveryDate,
    required this.totalAmount,
    required this.advancePaid,
    this.notes,
    required this.createdAt,
    this.ownerId = 'guest',
    this.syncStatus = 0,
  });

  @override
  List<Object?> get props => [
        id,
        customerId,
        measurementId,
        garmentType,
        status,
        deliveryDate,
        totalAmount,
        advancePaid,
        notes,
        createdAt,
        ownerId,
        syncStatus,
      ];
}
