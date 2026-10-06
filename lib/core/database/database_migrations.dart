import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import 'package:tailor_khata/core/database/database_schema.dart';

/// Upgrades for existing databases.
///
/// Statements stay within what the SQLite on Android 7 supports: no column
/// renames or drops, upserts, window functions or JSON functions.
abstract final class DatabaseMigrations {
  static const _uuid = Uuid();

  /// Version 4: customer notes, fit profiles with numeric values, order
  /// numbers, a payment ledger, status history and shop settings.
  static Future<void> toV4(Database db) async {
    await db.execute(
      'ALTER TABLE ${DatabaseSchema.customersTable} ADD COLUMN note TEXT',
    );
    await _upgradeMeasurements(db);
    final orderCount = await _upgradeOrders(db);
    await db.update(DatabaseSchema.shopSettingsTable, {
      'nextOrderNumber': orderCount + 1,
    });
  }

  static Future<void> _upgradeMeasurements(Database db) async {
    const table = DatabaseSchema.measurementsTable;
    await db.execute(
      "ALTER TABLE $table ADD COLUMN fitProfile TEXT NOT NULL DEFAULT 'Formal Fit'",
    );
    await db.execute(
      "ALTER TABLE $table ADD COLUMN unit TEXT NOT NULL DEFAULT 'in'",
    );
    await db.execute('ALTER TABLE $table ADD COLUMN note TEXT');
    await db.execute('ALTER TABLE $table ADD COLUMN updatedAt INTEGER');

    // Earlier versions showed the newest record per customer and garment.
    // That record becomes the Formal Fit profile; an older duplicate hands its
    // orders to it and is removed so the profile index can be created.
    final rows = await db.query(table, orderBy: 'createdAt DESC, rowid DESC');
    final kept = <(Object?, Object?), Object?>{};
    for (final row in rows) {
      final id = row['id'];
      final profile = (row['customerId'], row['garmentType']);
      if (kept.containsKey(profile)) {
        await db.update(
          DatabaseSchema.ordersTable,
          {'measurementId': kept[profile]},
          where: 'measurementId = ?',
          whereArgs: [id],
        );
        await db.delete(table, where: 'id = ?', whereArgs: [id]);
        continue;
      }
      kept[profile] = id;
      await db.update(
        table,
        {
          'measurementData': jsonEncode(
            _inches(row['measurementData'] as String),
          ),
          'updatedAt': row['createdAt'],
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    }
    await db.execute(DatabaseSchema.createMeasurementProfileIndex);
  }

  /// Values were stored as text such as `42.5"`, or empty once cleared.
  static Map<String, double> _inches(String legacyJson) {
    final legacy = jsonDecode(legacyJson) as Map<String, dynamic>;
    final values = <String, double>{};
    legacy.forEach((key, value) {
      final inches = value is num
          ? value.toDouble()
          : double.tryParse('$value'.replaceAll('"', '').trim());
      if (inches != null) values[key] = inches;
    });
    return values;
  }

  /// Returns the number of orders, which is also the last order number used.
  static Future<int> _upgradeOrders(Database db) async {
    const table = DatabaseSchema.ordersTable;
    await db.execute('ALTER TABLE $table ADD COLUMN orderNumber INTEGER');
    await db.execute(
      'ALTER TABLE $table ADD COLUMN pieces INTEGER NOT NULL DEFAULT 1',
    );
    await db.execute('ALTER TABLE $table ADD COLUMN fabric TEXT');
    // notes held the fabric description; it now holds the cutter's note.
    await db.execute('UPDATE $table SET fabric = notes, notes = NULL');

    for (final statement in DatabaseSchema.createLedgerStatements) {
      await db.execute(statement);
    }

    final orders = await db.query(table, orderBy: 'createdAt ASC, rowid ASC');
    var number = 0;
    for (final order in orders) {
      number++;
      final id = order['id'];
      final status = order['status'];
      final createdAt = order['createdAt'];
      final paid = (order['advancePaid'] as num).toDouble();
      final delivered = status == 'Delivered';

      await db.update(
        table,
        {'orderNumber': number},
        where: 'id = ?',
        whereArgs: [id],
      );
      // Only the creation and delivery times were recorded, so every earlier
      // stage is dated at creation.
      await db.insert(DatabaseSchema.orderStatusEventsTable, {
        'id': _uuid.v4(),
        'orderId': id,
        'status': 'Received',
        'changedAt': createdAt,
      });
      if (status != 'Received') {
        await db.insert(DatabaseSchema.orderStatusEventsTable, {
          'id': _uuid.v4(),
          'orderId': id,
          'status': status,
          'changedAt': delivered
              ? order['deliveredAt'] ?? createdAt
              : createdAt,
        });
      }
      // The paid total becomes one cash payment dated at creation, which is
      // the date revenue was reported under before payments had their own.
      if (paid > 0) {
        await db.insert(DatabaseSchema.paymentsTable, {
          'id': _uuid.v4(),
          'orderId': id,
          'amount': paid,
          'method': 'cash',
          'isAdvance': delivered ? 0 : 1,
          'paidAt': createdAt,
        });
      }
    }
    await db.execute(DatabaseSchema.createOrderNumberIndex);
    return number;
  }
}
