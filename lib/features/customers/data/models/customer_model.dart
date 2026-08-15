import 'package:tailor_khata/features/customers/domain/entities/customer.dart';

class CustomerModel extends Customer {
  const CustomerModel({
    required super.id,
    required super.name,
    super.urduName,
    super.phone,
    super.address,
    super.imagePath,
    required super.createdAt,
    super.ownerId = 'guest',
    super.syncStatus = 0,
  });

  factory CustomerModel.fromEntity(Customer entity) {
    return CustomerModel(
      id: entity.id,
      name: entity.name,
      urduName: entity.urduName,
      phone: entity.phone,
      address: entity.address,
      imagePath: entity.imagePath,
      createdAt: entity.createdAt,
      ownerId: entity.ownerId,
      syncStatus: entity.syncStatus,
    );
  }

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id'] as String,
      name: json['name'] as String,
      urduName: json['urduName'] as String?,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      imagePath: json['imagePath'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
      ownerId: json['ownerId'] as String? ?? 'guest',
      syncStatus: json['syncStatus'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'urduName': urduName,
      'phone': phone,
      'address': address,
      'imagePath': imagePath,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'ownerId': ownerId,
      'syncStatus': syncStatus,
    };
  }
}
