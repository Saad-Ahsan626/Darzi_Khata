import 'package:equatable/equatable.dart';

class Order extends Equatable {
  final String id;
  final String customerId;
  final String? measurementId;

  /// Sequential shop number, assigned when the order is first saved.
  final int? orderNumber;
  final String garmentType;
  final int pieces;
  final String? fabric;

  /// Note for the cutter.
  final String? notes;
  final String status;
  final DateTime deliveryDate;
  final double totalAmount;

  /// Sum of the payments recorded for this order.
  final double paidAmount;
  final DateTime createdAt;
  final DateTime? deliveredAt;
  final String ownerId;
  final int syncStatus;

  const Order({
    required this.id,
    required this.customerId,
    this.measurementId,
    this.orderNumber,
    required this.garmentType,
    this.pieces = 1,
    this.fabric,
    this.notes,
    required this.status,
    required this.deliveryDate,
    required this.totalAmount,
    required this.paidAmount,
    required this.createdAt,
    this.deliveredAt,
    this.ownerId = 'guest',
    this.syncStatus = 0,
  })  : assert(pieces > 0, 'An order has at least one piece'),
        assert(totalAmount >= 0, 'Total amount cannot be negative'),
        assert(paidAmount >= 0, 'Paid amount cannot be negative'),
        assert(paidAmount <= totalAmount, 'Paid amount cannot exceed total amount');

  double get balance => totalAmount - paidAmount;

  @override
  List<Object?> get props => [
        id,
        customerId,
        measurementId,
        orderNumber,
        garmentType,
        pieces,
        fabric,
        notes,
        status,
        deliveryDate,
        totalAmount,
        paidAmount,
        createdAt,
        deliveredAt,
        ownerId,
        syncStatus,
      ];
}
