import 'package:tailor_khata/core/database/database_helper.dart';
import 'package:tailor_khata/core/database/database_schema.dart';
import 'package:tailor_khata/core/error/exceptions.dart';
import 'package:tailor_khata/features/orders/data/models/order_model.dart';

abstract class OrderLocalDataSource {
  Future<List<OrderModel>> getOrders();
  Future<OrderModel> getOrderById(String id);
  Future<List<OrderModel>> getOrdersByCustomer(String customerId);
  Future<void> addOrder(OrderModel order);
  Future<void> updateOrder(OrderModel order);
  Future<void> deleteOrder(String id);
}

class OrderLocalDataSourceImpl implements OrderLocalDataSource {
  final DatabaseHelper dbHelper;

  OrderLocalDataSourceImpl({required this.dbHelper});

  @override
  Future<List<OrderModel>> getOrders() async {
    try {
      final db = await dbHelper.database;
      final result = await db.query(DatabaseSchema.ordersTable, orderBy: 'createdAt DESC');
      return result.map((json) => OrderModel.fromJson(json)).toList();
    } catch (e) {
      throw LocalDatabaseException('Failed to fetch orders: \$e');
    }
  }

  @override
  Future<OrderModel> getOrderById(String id) async {
    try {
      final db = await dbHelper.database;
      final result = await db.query(
        DatabaseSchema.ordersTable,
        where: 'id = ?',
        whereArgs: [id],
      );
      if (result.isNotEmpty) {
        return OrderModel.fromJson(result.first);
      } else {
        throw LocalDatabaseException('Order not found');
      }
    } catch (e) {
      throw LocalDatabaseException('Failed to fetch order: \$e');
    }
  }

  @override
  Future<List<OrderModel>> getOrdersByCustomer(String customerId) async {
    try {
      final db = await dbHelper.database;
      final result = await db.query(
        DatabaseSchema.ordersTable,
        where: 'customerId = ?',
        whereArgs: [customerId],
        orderBy: 'createdAt DESC',
      );
      return result.map((json) => OrderModel.fromJson(json)).toList();
    } catch (e) {
      throw LocalDatabaseException('Failed to fetch orders for customer: \$e');
    }
  }

  @override
  Future<void> addOrder(OrderModel order) async {
    try {
      final db = await dbHelper.database;
      await db.insert(DatabaseSchema.ordersTable, order.toJson());
    } catch (e) {
      throw LocalDatabaseException('Failed to add order: \$e');
    }
  }

  @override
  Future<void> updateOrder(OrderModel order) async {
    try {
      final db = await dbHelper.database;
      await db.update(
        DatabaseSchema.ordersTable,
        order.toJson(),
        where: 'id = ?',
        whereArgs: [order.id],
      );
    } catch (e) {
      throw LocalDatabaseException('Failed to update order: \$e');
    }
  }

  @override
  Future<void> deleteOrder(String id) async {
    try {
      final db = await dbHelper.database;
      await db.delete(
        DatabaseSchema.ordersTable,
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw LocalDatabaseException('Failed to delete order: \$e');
    }
  }
}
