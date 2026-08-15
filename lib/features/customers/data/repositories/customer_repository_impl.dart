import 'package:fpdart/fpdart.dart';
import 'package:tailor_khata/core/error/exceptions.dart';
import 'package:tailor_khata/core/error/failures.dart';
import 'package:tailor_khata/features/customers/data/datasources/customer_local_data_source.dart';
import 'package:tailor_khata/features/customers/data/models/customer_model.dart';
import 'package:tailor_khata/features/customers/domain/entities/customer.dart';
import 'package:tailor_khata/features/customers/domain/repositories/customer_repository.dart';

class CustomerRepositoryImpl implements CustomerRepository {
  final CustomerLocalDataSource localDataSource;

  CustomerRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, List<Customer>>> getCustomers() async {
    try {
      final models = await localDataSource.getCustomers();
      return Right(models);
    } on LocalDatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Customer>> getCustomerById(String id) async {
    try {
      final model = await localDataSource.getCustomerById(id);
      return Right(model);
    } on LocalDatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> addCustomer(Customer customer) async {
    try {
      final model = CustomerModel.fromEntity(customer);
      await localDataSource.addCustomer(model);
      return const Right(null);
    } on LocalDatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> updateCustomer(Customer customer) async {
    try {
      final model = CustomerModel.fromEntity(customer);
      await localDataSource.updateCustomer(model);
      return const Right(null);
    } on LocalDatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> deleteCustomer(String id) async {
    try {
      await localDataSource.deleteCustomer(id);
      return const Right(null);
    } on LocalDatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    }
  }
}
