import 'package:equatable/equatable.dart';

class Customer extends Equatable {
  final String id;
  final String name;
  final String? urduName;
  final String? phone;
  final String? address;
  final String? imagePath;
  final DateTime createdAt;
  final String ownerId;
  final int syncStatus;

  const Customer({
    required this.id,
    required this.name,
    this.urduName,
    this.phone,
    this.address,
    this.imagePath,
    required this.createdAt,
    this.ownerId = 'guest',
    this.syncStatus = 0,
  }) : assert(name.length > 0, 'Name cannot be empty');

  @override
  List<Object?> get props => [
        id,
        name,
        urduName,
        phone,
        address,
        imagePath,
        createdAt,
        ownerId,
        syncStatus,
      ];
}
