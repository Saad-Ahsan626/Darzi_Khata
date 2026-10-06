import 'package:equatable/equatable.dart';

/// The moment an order entered a stage.
class OrderStatusEvent extends Equatable {
  final String id;
  final String orderId;
  final String status;
  final DateTime changedAt;

  const OrderStatusEvent({
    required this.id,
    required this.orderId,
    required this.status,
    required this.changedAt,
  });

  @override
  List<Object?> get props => [id, orderId, status, changedAt];
}
