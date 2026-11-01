import 'package:equatable/equatable.dart';

/// What a backup holds.
class BackupSummary extends Equatable {
  final DateTime createdAt;
  final int customers;
  final int orders;

  const BackupSummary({
    required this.createdAt,
    required this.customers,
    required this.orders,
  });

  @override
  List<Object?> get props => [createdAt, customers, orders];
}

/// A backup that cannot be used, with the reason to show the shop.
class BackupException implements Exception {
  final String message;

  const BackupException(this.message);

  @override
  String toString() => message;
}
