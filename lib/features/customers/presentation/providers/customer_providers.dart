import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tailor_khata/core/providers/database_provider.dart';

import 'package:tailor_khata/features/customers/data/datasources/customer_local_data_source.dart';
import 'package:tailor_khata/features/customers/data/repositories/customer_repository_impl.dart';
import 'package:tailor_khata/features/customers/domain/repositories/customer_repository.dart';
import 'package:tailor_khata/features/customers/domain/usecases/add_customer.dart';
import 'package:tailor_khata/features/customers/domain/usecases/delete_customer.dart';
import 'package:tailor_khata/features/customers/domain/usecases/get_customer_by_id.dart';
import 'package:tailor_khata/features/customers/domain/usecases/get_customers.dart';
import 'package:tailor_khata/features/customers/domain/usecases/update_customer.dart';

final customerLocalDataSourceProvider = Provider<CustomerLocalDataSource>((
  ref,
) {
  final dbHelper = ref.watch(databaseProvider);
  return CustomerLocalDataSourceImpl(dbHelper: dbHelper);
});

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  final localDataSource = ref.watch(customerLocalDataSourceProvider);
  return CustomerRepositoryImpl(localDataSource: localDataSource);
});

final getCustomersUsecaseProvider = Provider<GetCustomers>((ref) {
  return GetCustomers(ref.watch(customerRepositoryProvider));
});

final getCustomerByIdUsecaseProvider = Provider<GetCustomerById>((ref) {
  return GetCustomerById(ref.watch(customerRepositoryProvider));
});

final addCustomerUsecaseProvider = Provider<AddCustomer>((ref) {
  return AddCustomer(ref.watch(customerRepositoryProvider));
});

final updateCustomerUsecaseProvider = Provider<UpdateCustomer>((ref) {
  return UpdateCustomer(ref.watch(customerRepositoryProvider));
});

final deleteCustomerUsecaseProvider = Provider<DeleteCustomer>((ref) {
  return DeleteCustomer(ref.watch(customerRepositoryProvider));
});
