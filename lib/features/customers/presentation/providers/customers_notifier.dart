import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tailor_khata/core/usecase/usecase.dart';
import 'package:tailor_khata/features/customers/domain/entities/customer.dart';
import 'package:tailor_khata/features/customers/presentation/providers/customer_providers.dart';

class CustomersNotifier extends AsyncNotifier<List<Customer>> {
  @override
  Future<List<Customer>> build() async {
    return _fetchCustomers();
  }

  Future<List<Customer>> _fetchCustomers() async {
    final getCustomers = ref.watch(getCustomersUsecaseProvider);
    final result = await getCustomers(const NoParams());
    return result.fold(
      (failure) => throw Exception(failure.message),
      (customers) => customers,
    );
  }

  Future<void> loadCustomers() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchCustomers());
  }

  Future<void> addCustomer(Customer customer) async {
    final addCustomerUsecase = ref.read(addCustomerUsecaseProvider);
    final result = await addCustomerUsecase(customer);
    result.fold(
      (failure) => state = AsyncValue.error(failure.message, StackTrace.current),
      (_) => loadCustomers(),
    );
  }

  Future<void> updateCustomer(Customer customer) async {
    final updateCustomerUsecase = ref.read(updateCustomerUsecaseProvider);
    final result = await updateCustomerUsecase(customer);
    result.fold(
      (failure) => state = AsyncValue.error(failure.message, StackTrace.current),
      (_) => loadCustomers(),
    );
  }

  Future<void> deleteCustomer(String id) async {
    final deleteCustomerUsecase = ref.read(deleteCustomerUsecaseProvider);
    final result = await deleteCustomerUsecase(id);
    result.fold(
      (failure) => state = AsyncValue.error(failure.message, StackTrace.current),
      (_) => loadCustomers(),
    );
  }
}

final customersNotifierProvider = AsyncNotifierProvider<CustomersNotifier, List<Customer>>(() {
  return CustomersNotifier();
});
