import 'package:tailor_khata/features/orders/domain/entities/order.dart';

class OrderModel extends Order {
  const OrderModel({
    required super.id,
    required super.customerId,
    super.measurementId,
    super.orderNumber,
    required super.garmentType,
    super.pieces,
    super.fabric,
    super.notes,
    required super.status,
    required super.deliveryDate,
    required super.totalAmount,
    required super.paidAmount,
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
      orderNumber: entity.orderNumber,
      garmentType: entity.garmentType,
      pieces: entity.pieces,
      fabric: entity.fabric,
      notes: entity.notes,
      status: entity.status,
      deliveryDate: entity.deliveryDate,
      totalAmount: entity.totalAmount,
      paidAmount: entity.paidAmount,
      createdAt: entity.createdAt,
      deliveredAt: entity.deliveredAt,
      ownerId: entity.ownerId,
      syncStatus: entity.syncStatus,
    );
  }

  // The paid total is stored in the advancePaid column, named before
  // payments were recorded individually.
  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] as String,
      customerId: json['customerId'] as String,
      measurementId: json['measurementId'] as String?,
      orderNumber: json['orderNumber'] as int?,
      garmentType: json['garmentType'] as String,
      pieces: json['pieces'] as int? ?? 1,
      fabric: json['fabric'] as String?,
      notes: json['notes'] as String?,
      status: json['status'] as String,
      deliveryDate: DateTime.fromMillisecondsSinceEpoch(json['deliveryDate'] as int),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      paidAmount: (json['advancePaid'] as num).toDouble(),
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
      'orderNumber': orderNumber,
      'garmentType': garmentType,
      'pieces': pieces,
      'fabric': fabric,
      'notes': notes,
      'status': status,
      'deliveryDate': deliveryDate.millisecondsSinceEpoch,
      'totalAmount': totalAmount,
      'advancePaid': paidAmount,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'deliveredAt': deliveredAt?.millisecondsSinceEpoch,
      'ownerId': ownerId,
      'syncStatus': syncStatus,
    };
  }
}
