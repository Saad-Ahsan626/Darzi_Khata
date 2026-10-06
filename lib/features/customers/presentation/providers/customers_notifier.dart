import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:tailor_khata/core/error/failures.dart';
import 'package:tailor_khata/core/usecase/usecase.dart';
import 'package:tailor_khata/features/customers/domain/entities/customer.dart';
import 'package:tailor_khata/features/customers/presentation/providers/customer_providers.dart';
import 'package:tailor_khata/features/measurements/presentation/providers/measurements_notifier.dart';
import 'package:tailor_khata/features/orders/presentation/providers/orders_notifier.dart';

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

  /// Reads the list again. The current list stays on screen meanwhile.
  Future<void> loadCustomers() async {
    state = await AsyncValue.guard(() => _fetchCustomers());
  }

  /// Saves a new customer. Returns why it could not be saved, or null once
  /// it is stored and the list is up to date.
  Future<Failure?> addCustomer(Customer customer) async {
    final addCustomerUsecase = ref.read(addCustomerUsecaseProvider);
    return _finish(await addCustomerUsecase(customer));
  }

  /// Saves changes to a customer, with the same result as [addCustomer].
  Future<Failure?> updateCustomer(Customer customer) async {
    final updateCustomerUsecase = ref.read(updateCustomerUsecaseProvider);
    return _finish(await updateCustomerUsecase(customer));
  }

  /// Deletes a customer along with their measurements and orders.
  Future<Failure?> deleteCustomer(String id) async {
    final deleteCustomerUsecase = ref.read(deleteCustomerUsecaseProvider);
    final failure = await _finish(await deleteCustomerUsecase(id));
    if (failure == null) {
      // Their orders and measurements were removed with them.
      ref.invalidate(ordersNotifierProvider);
      ref.invalidate(measurementsNotifierProvider);
    }
    return failure;
  }

  Future<Failure?> _finish(Either<Failure, void> result) async {
    final failure = result.getLeft().toNullable();
    if (failure == null) await loadCustomers();
    return failure;
  }
}

final customersNotifierProvider =
    AsyncNotifierProvider<CustomersNotifier, List<Customer>>(() {
      return CustomersNotifier();
    });
