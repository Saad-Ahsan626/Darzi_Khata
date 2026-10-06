import 'package:tailor_khata/features/orders/domain/entities/order_status_event.dart';

class OrderStatusEventModel extends OrderStatusEvent {
  const OrderStatusEventModel({
    required super.id,
    required super.orderId,
    required super.status,
    required super.changedAt,
  });

  factory OrderStatusEventModel.fromJson(Map<String, dynamic> json) {
    return OrderStatusEventModel(
      id: json['id'] as String,
      orderId: json['orderId'] as String,
      status: json['status'] as String,
      changedAt: DateTime.fromMillisecondsSinceEpoch(json['changedAt'] as int),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderId': orderId,
      'status': status,
      'changedAt': changedAt.millisecondsSinceEpoch,
    };
  }
}
