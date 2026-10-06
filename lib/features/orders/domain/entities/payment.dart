import 'package:equatable/equatable.dart';

enum PaymentMethod { cash, bank, easypaisa }

class Payment extends Equatable {
  final String id;
  final String orderId;
  final double amount;
  final PaymentMethod method;

  /// Whether this is the advance taken when the order was placed.
  final bool isAdvance;
  final DateTime paidAt;
  final String ownerId;
  final int syncStatus;

  const Payment({
    required this.id,
    required this.orderId,
    required this.amount,
    required this.method,
    this.isAdvance = false,
    required this.paidAt,
    this.ownerId = 'guest',
    this.syncStatus = 0,
  }) : assert(amount > 0, 'A payment is more than zero');

  @override
  List<Object?> get props => [
        id,
        orderId,
        amount,
        method,
        isAdvance,
        paidAt,
        ownerId,
        syncStatus,
      ];
}
