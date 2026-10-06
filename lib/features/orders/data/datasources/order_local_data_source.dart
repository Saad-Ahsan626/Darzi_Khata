import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import 'package:tailor_khata/core/database/database_helper.dart';
import 'package:tailor_khata/core/database/database_schema.dart';
import 'package:tailor_khata/core/error/exceptions.dart';
import 'package:tailor_khata/features/orders/data/models/order_model.dart';
import 'package:tailor_khata/features/orders/data/models/order_status_event_model.dart';
import 'package:tailor_khata/features/orders/data/models/payment_model.dart';
import 'package:tailor_khata/features/orders/domain/entities/order_status.dart';
import 'package:tailor_khata/features/orders/domain/entities/payment.dart';

abstract class OrderLocalDataSource {
  Future<List<OrderModel>> getOrders();
  Future<OrderModel> getOrderById(String id);
  Future<List<OrderModel>> getOrdersByCustomer(String customerId);
  Future<void> addOrder(OrderModel order);
  Future<void> updateOrder(OrderModel order);
  Future<void> deleteOrder(String id);
  Future<void> changeStatus({
    required String orderId,
    required String status,
    required DateTime changedAt,
  });
  Future<void> deliverOrder({
    required String orderId,
    required DateTime deliveredAt,
  });
  Future<List<OrderStatusEventModel>> getStatusHistory(String orderId);
  Future<PaymentModel> recordPayment({
    required String orderId,
    required double amount,
    required PaymentMethod method,
    required DateTime paidAt,
  });
  Future<void> deletePayment(String paymentId);
  Future<List<PaymentModel>> getPayments();
  Future<List<PaymentModel>> getPaymentsByOrder(String orderId);
}

class OrderLocalDataSourceImpl implements OrderLocalDataSource {
  final DatabaseHelper dbHelper;

  static const _uuid = Uuid();

  OrderLocalDataSourceImpl({required this.dbHelper});

  @override
  Future<List<OrderModel>> getOrders() async {
    try {
      final db = await dbHelper.database;
      final result = await db.query(DatabaseSchema.ordersTable, orderBy: 'createdAt DESC');
      return result.map((json) => OrderModel.fromJson(json)).toList();
    } catch (e) {
      throw LocalDatabaseException('Failed to fetch orders: $e');
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
      throw LocalDatabaseException('Failed to fetch order: $e');
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
      throw LocalDatabaseException('Failed to fetch orders for customer: $e');
    }
  }

  @override
  Future<void> addOrder(OrderModel order) async {
    try {
      final db = await dbHelper.database;
      await db.transaction((txn) async {
        final settings = await txn.query(
          DatabaseSchema.shopSettingsTable,
          columns: ['nextOrderNumber'],
        );
        final orderNumber = settings.first['nextOrderNumber'] as int;
        await txn.update(DatabaseSchema.shopSettingsTable, {
          'nextOrderNumber': orderNumber + 1,
        });
        await txn.insert(DatabaseSchema.ordersTable, {
          ...order.toJson(),
          'orderNumber': orderNumber,
        });
        await _insertStatusEvent(txn, order.id, order.status, order.createdAt);
        if (order.paidAmount > 0) {
          await txn.insert(
            DatabaseSchema.paymentsTable,
            PaymentModel(
              id: _uuid.v4(),
              orderId: order.id,
              amount: order.paidAmount,
              method: PaymentMethod.cash,
              isAdvance: true,
              paidAt: order.createdAt,
            ).toJson(),
          );
        }
      });
    } catch (e) {
      throw LocalDatabaseException('Failed to add order: $e');
    }
  }

  @override
  Future<void> updateOrder(OrderModel order) async {
    try {
      final db = await dbHelper.database;
      // Status, payments and the order number have their own writes, so an
      // edit built from an older copy of the order cannot overwrite them.
      await db.update(
        DatabaseSchema.ordersTable,
        {
          'customerId': order.customerId,
          'measurementId': order.measurementId,
          'garmentType': order.garmentType,
          'pieces': order.pieces,
          'fabric': order.fabric,
          'notes': order.notes,
          'deliveryDate': order.deliveryDate.millisecondsSinceEpoch,
          'totalAmount': order.totalAmount,
        },
        where: 'id = ?',
        whereArgs: [order.id],
      );
    } catch (e) {
      throw LocalDatabaseException('Failed to update order: $e');
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
      throw LocalDatabaseException('Failed to delete order: $e');
    }
  }

  @override
  Future<void> changeStatus({
    required String orderId,
    required String status,
    required DateTime changedAt,
  }) async {
    try {
      final db = await dbHelper.database;
      await db.transaction((txn) async {
        await _insertStatusEvent(txn, orderId, status, changedAt);
        await txn.update(
          DatabaseSchema.ordersTable,
          {'status': status},
          where: 'id = ?',
          whereArgs: [orderId],
        );
      });
    } catch (e) {
      throw LocalDatabaseException('Failed to change order status: $e');
    }
  }

  @override
  Future<void> deliverOrder({
    required String orderId,
    required DateTime deliveredAt,
  }) async {
    try {
      final db = await dbHelper.database;
      await db.transaction((txn) async {
        await _insertStatusEvent(
          txn,
          orderId,
          OrderStatus.delivered,
          deliveredAt,
        );
        await txn.update(
          DatabaseSchema.ordersTable,
          {
            'status': OrderStatus.delivered,
            'deliveredAt': deliveredAt.millisecondsSinceEpoch,
          },
          where: 'id = ?',
          whereArgs: [orderId],
        );
      });
    } catch (e) {
      throw LocalDatabaseException('Failed to deliver order: $e');
    }
  }

  @override
  Future<List<OrderStatusEventModel>> getStatusHistory(String orderId) async {
    try {
      final db = await dbHelper.database;
      final result = await db.query(
        DatabaseSchema.orderStatusEventsTable,
        where: 'orderId = ?',
        whereArgs: [orderId],
        orderBy: 'changedAt ASC, rowid ASC',
      );
      return result.map((json) => OrderStatusEventModel.fromJson(json)).toList();
    } catch (e) {
      throw LocalDatabaseException('Failed to fetch status history: $e');
    }
  }

  @override
  Future<PaymentModel> recordPayment({
    required String orderId,
    required double amount,
    required PaymentMethod method,
    required DateTime paidAt,
  }) async {
    try {
      final db = await dbHelper.database;
      final payment = PaymentModel(
        id: _uuid.v4(),
        orderId: orderId,
        amount: amount,
        method: method,
        paidAt: paidAt,
      );
      await db.transaction((txn) async {
        await txn.insert(DatabaseSchema.paymentsTable, payment.toJson());
        await _refreshPaidAmount(txn, orderId);
      });
      return payment;
    } catch (e) {
      throw LocalDatabaseException('Failed to record payment: $e');
    }
  }

  @override
  Future<void> deletePayment(String paymentId) async {
    try {
      final db = await dbHelper.database;
      await db.transaction((txn) async {
        final payments = await txn.query(
          DatabaseSchema.paymentsTable,
          columns: ['orderId'],
          where: 'id = ?',
          whereArgs: [paymentId],
        );
        if (payments.isEmpty) return;
        await txn.delete(
          DatabaseSchema.paymentsTable,
          where: 'id = ?',
          whereArgs: [paymentId],
        );
        await _refreshPaidAmount(txn, payments.first['orderId'] as String);
      });
    } catch (e) {
      throw LocalDatabaseException('Failed to delete payment: $e');
    }
  }

  @override
  Future<List<PaymentModel>> getPayments() async {
    try {
      final db = await dbHelper.database;
      final result = await db.query(
        DatabaseSchema.paymentsTable,
        orderBy: 'paidAt DESC, rowid DESC',
      );
      return result.map((json) => PaymentModel.fromJson(json)).toList();
    } catch (e) {
      throw LocalDatabaseException('Failed to fetch payments: $e');
    }
  }

  @override
  Future<List<PaymentModel>> getPaymentsByOrder(String orderId) async {
    try {
      final db = await dbHelper.database;
      final result = await db.query(
        DatabaseSchema.paymentsTable,
        where: 'orderId = ?',
        whereArgs: [orderId],
        orderBy: 'paidAt DESC, rowid DESC',
      );
      return result.map((json) => PaymentModel.fromJson(json)).toList();
    } catch (e) {
      throw LocalDatabaseException('Failed to fetch payments for order: $e');
    }
  }

  Future<void> _insertStatusEvent(
    Transaction txn,
    String orderId,
    String status,
    DateTime changedAt,
  ) async {
    await txn.insert(
      DatabaseSchema.orderStatusEventsTable,
      OrderStatusEventModel(
        id: _uuid.v4(),
        orderId: orderId,
        status: status,
        changedAt: changedAt,
      ).toJson(),
    );
  }

  /// Sets the order's stored paid total to the sum of its payments.
  Future<void> _refreshPaidAmount(Transaction txn, String orderId) async {
    await txn.rawUpdate(
      '''
      UPDATE ${DatabaseSchema.ordersTable}
      SET advancePaid = (
        SELECT COALESCE(SUM(amount), 0)
        FROM ${DatabaseSchema.paymentsTable}
        WHERE orderId = ?
      )
      WHERE id = ?
      ''',
      [orderId, orderId],
    );
  }
}
