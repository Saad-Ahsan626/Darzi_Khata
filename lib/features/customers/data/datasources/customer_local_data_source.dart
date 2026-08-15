import 'package:tailor_khata/core/database/database_helper.dart';
import 'package:tailor_khata/core/database/database_schema.dart';
import 'package:tailor_khata/core/error/exceptions.dart';
import 'package:tailor_khata/features/customers/data/models/customer_model.dart';

abstract class CustomerLocalDataSource {
  Future<List<CustomerModel>> getCustomers();
  Future<CustomerModel> getCustomerById(String id);
  Future<void> addCustomer(CustomerModel customer);
  Future<void> updateCustomer(CustomerModel customer);
  Future<void> deleteCustomer(String id);
}

class CustomerLocalDataSourceImpl implements CustomerLocalDataSource {
  final DatabaseHelper dbHelper;

  CustomerLocalDataSourceImpl({required this.dbHelper});

  @override
  Future<List<CustomerModel>> getCustomers() async {
    try {
      final db = await dbHelper.database;
      final result = await db.query(
        DatabaseSchema.customersTable,
        orderBy: 'createdAt DESC',
      );
      return result.map((json) => CustomerModel.fromJson(json)).toList();
    } catch (e) {
      throw LocalDatabaseException('Failed to fetch customers: $e');
    }
  }

  @override
  Future<CustomerModel> getCustomerById(String id) async {
    try {
      final db = await dbHelper.database;
      final result = await db.query(
        DatabaseSchema.customersTable,
        where: 'id = ?',
        whereArgs: [id],
      );
      if (result.isNotEmpty) {
        return CustomerModel.fromJson(result.first);
      } else {
        throw LocalDatabaseException('Customer not found');
      }
    } catch (e) {
      throw LocalDatabaseException('Failed to fetch customer: $e');
    }
  }

  @override
  Future<void> addCustomer(CustomerModel customer) async {
    try {
      final db = await dbHelper.database;
      await db.insert(DatabaseSchema.customersTable, customer.toJson());
    } catch (e) {
      throw LocalDatabaseException('Failed to add customer: $e');
    }
  }

  @override
  Future<void> updateCustomer(CustomerModel customer) async {
    try {
      final db = await dbHelper.database;
      await db.update(
        DatabaseSchema.customersTable,
        customer.toJson(),
        where: 'id = ?',
        whereArgs: [customer.id],
      );
    } catch (e) {
      throw LocalDatabaseException('Failed to update customer: $e');
    }
  }

  @override
  Future<void> deleteCustomer(String id) async {
    try {
      final db = await dbHelper.database;
      await db.delete(
        DatabaseSchema.customersTable,
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw LocalDatabaseException('Failed to delete customer: $e');
    }
  }
}
