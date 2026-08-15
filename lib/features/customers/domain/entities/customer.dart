import 'package:equatable/equatable.dart';

class Customer extends Equatable {
  final String id;
  final String name;
  final String? phone;
  final DateTime createdAt;
  final String ownerId;
  final int syncStatus;

  const Customer({
    required this.id,
    required this.name,
    this.phone,
    required this.createdAt,
    this.ownerId = 'guest',
    this.syncStatus = 0,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        phone,
        createdAt,
        ownerId,
        syncStatus,
      ];
}
