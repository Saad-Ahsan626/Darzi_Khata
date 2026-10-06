import 'package:tailor_khata/features/orders/domain/entities/payment.dart';

class PaymentModel extends Payment {
  const PaymentModel({
    required super.id,
    required super.orderId,
    required super.amount,
    required super.method,
    super.isAdvance,
    required super.paidAt,
    super.ownerId,
    super.syncStatus,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'] as String,
      orderId: json['orderId'] as String,
      amount: (json['amount'] as num).toDouble(),
      method: PaymentMethod.values.byName(json['method'] as String),
      isAdvance: json['isAdvance'] == 1,
      paidAt: DateTime.fromMillisecondsSinceEpoch(json['paidAt'] as int),
      ownerId: json['ownerId'] as String? ?? 'guest',
      syncStatus: json['syncStatus'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderId': orderId,
      'amount': amount,
      'method': method.name,
      'isAdvance': isAdvance ? 1 : 0,
      'paidAt': paidAt.millisecondsSinceEpoch,
      'ownerId': ownerId,
      'syncStatus': syncStatus,
    };
  }
}
