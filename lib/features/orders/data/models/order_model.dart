import 'package:tailor_khata/features/orders/domain/entities/order.dart';

class OrderModel extends Order {
  const OrderModel({
    required super.id,
    required super.customerId,
    super.measurementId,
    required super.garmentType,
    required super.status,
    required super.deliveryDate,
    required super.totalAmount,
    required super.advancePaid,
    super.notes,
    required super.createdAt,
    super.deliveredAt,
    super.ownerId,
    super.syncStatus,
  });

  factory OrderModel.fromEntity(Order entity) {
    return OrderModel(
      id: entity.id,
      customerId: entity.customerId,
      measurementId: entity.measurementId,
      garmentType: entity.garmentType,
      status: entity.status,
      deliveryDate: entity.deliveryDate,
      totalAmount: entity.totalAmount,
      advancePaid: entity.advancePaid,
      notes: entity.notes,
      createdAt: entity.createdAt,
      deliveredAt: entity.deliveredAt,
      ownerId: entity.ownerId,
      syncStatus: entity.syncStatus,
    );
  }

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] as String,
      customerId: json['customerId'] as String,
      measurementId: json['measurementId'] as String?,
      garmentType: json['garmentType'] as String,
      status: json['status'] as String,
      deliveryDate: DateTime.fromMillisecondsSinceEpoch(json['deliveryDate'] as int),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      advancePaid: (json['advancePaid'] as num).toDouble(),
      notes: json['notes'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
      deliveredAt: json['deliveredAt'] != null ? DateTime.fromMillisecondsSinceEpoch(json['deliveredAt'] as int) : null,
      ownerId: json['ownerId'] as String? ?? 'guest',
      syncStatus: json['syncStatus'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerId': customerId,
      'measurementId': measurementId,
      'garmentType': garmentType,
      'status': status,
      'deliveryDate': deliveryDate.millisecondsSinceEpoch,
      'totalAmount': totalAmount,
      'advancePaid': advancePaid,
      'notes': notes,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'deliveredAt': deliveredAt?.millisecondsSinceEpoch,
      'ownerId': ownerId,
      'syncStatus': syncStatus,
    };
  }
}
