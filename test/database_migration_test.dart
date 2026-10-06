import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tailor_khata/core/database/database_schema.dart';

import 'support/database_test_support.dart';

// The schema a version 3 install created, before DatabaseSchema moved on.
const _version3Schema = [
  '''
  CREATE TABLE customers (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    urduName TEXT,
    phone TEXT,
    address TEXT,
    imagePath TEXT,
    createdAt INTEGER NOT NULL,
    ownerId TEXT DEFAULT 'guest',
    syncStatus INTEGER DEFAULT 0
  )
  ''',
  '''
  CREATE TABLE measurements (
    id TEXT PRIMARY KEY,
    customerId TEXT NOT NULL,
    garmentType TEXT NOT NULL,
    measurementData TEXT NOT NULL,
    createdAt INTEGER NOT NULL,
    ownerId TEXT DEFAULT 'guest',
    syncStatus INTEGER DEFAULT 0,
    FOREIGN KEY(customerId) REFERENCES customers(id) ON DELETE CASCADE
  )
  ''',
  '''
  CREATE TABLE orders (
    id TEXT PRIMARY KEY,
    customerId TEXT NOT NULL,
    measurementId TEXT,
    garmentType TEXT NOT NULL,
    status TEXT NOT NULL,
    deliveryDate INTEGER NOT NULL,
    totalAmount REAL NOT NULL,
    advancePaid REAL NOT NULL,
    notes TEXT,
    createdAt INTEGER NOT NULL,
    deliveredAt INTEGER,
    ownerId TEXT DEFAULT 'guest',
    syncStatus INTEGER DEFAULT 0,
    FOREIGN KEY(customerId) REFERENCES customers(id) ON DELETE CASCADE,
    FOREIGN KEY(measurementId) REFERENCES measurements(id) ON DELETE SET NULL
  )
  ''',
];

int _at(int month, int day, [int hour = 10]) =>
    DateTime(2026, month, day, hour).millisecondsSinceEpoch;

Map<String, Object?> _customer(String id, String name) => {
  'id': id,
  'name': name,
  'phone': '03004128876',
  'createdAt': _at(7, 1),
};

Map<String, Object?> _measurement(
  String id, {
  String garment = 'Shalwar Kameez',
  required Map<String, Object?> values,
  required int createdAt,
}) => {
  'id': id,
  'customerId': 'faisal',
  'garmentType': garment,
  'measurementData': jsonEncode(values),
  'createdAt': createdAt,
};

Map<String, Object?> _order(
  String id, {
  String customerId = 'faisal',
  String? measurementId,
  required String status,
  required double total,
  required double paid,
  String? notes,
  required int createdAt,
  int? deliveredAt,
}) => {
  'id': id,
  'customerId': customerId,
  'measurementId': measurementId,
  'garmentType': 'Shalwar Kameez',
  'status': status,
  'deliveryDate': _at(10, 12),
  'totalAmount': total,
  'advancePaid': paid,
  'notes': notes,
  'createdAt': createdAt,
  'deliveredAt': deliveredAt,
};

/// A shop as version 3 stored it. Orders are inserted out of date order.
Future<void> _seedShop(Database db) async {
  await db.insert('customers', _customer('faisal', 'Faisal Shah'));
  await db.insert('customers', _customer('bilal', 'Bilal Haider'));
  await db.insert(
    'measurements',
    _measurement(
      'profile',
      values: {'neck': '15.5"', 'chest': '40.0"', 'waist': '', 'length': 42},
      createdAt: _at(9, 18),
    ),
  );
  await db.insert(
    'orders',
    _order(
      'in-progress',
      measurementId: 'profile',
      status: 'Stitching',
      total: 4800,
      paid: 2000,
      notes: 'Wash & wear, off-white',
      createdAt: _at(9, 28),
    ),
  );
  await db.insert(
    'orders',
    _order(
      'unpaid',
      customerId: 'bilal',
      status: 'Received',
      total: 6500,
      paid: 0,
      createdAt: _at(10, 2),
    ),
  );
  await db.insert(
    'orders',
    _order(
      'delivered',
      status: 'Delivered',
      total: 3500,
      paid: 3500,
      notes: 'Grey wool blend',
      createdAt: _at(8, 1),
      deliveredAt: _at(8, 9, 17),
    ),
  );
}

/// Creates a version 3 database holding [seed]'s rows and returns the same
/// database after the app has opened and upgraded it.
Future<Database> _upgradedFrom(Future<void> Function(Database db) seed) async {
  final path = temporaryDatabasePath();
  final version3 = await databaseFactory.openDatabase(
    path,
    options: OpenDatabaseOptions(
      version: 3,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, _) async {
        for (final statement in _version3Schema) {
          await db.execute(statement);
        }
      },
    ),
  );
  await seed(version3);
  await version3.close();
  return (await openTestDatabase(path)).database;
}

Future<Map<String, Object?>> _row(Database db, String table, String id) async =>
    (await db.query(table, where: 'id = ?', whereArgs: [id])).single;

Future<Map<String, Set<String>>> _describe(Database db) async {
  final description = <String, Set<String>>{};
  final tables = await db.rawQuery(
    "SELECT name FROM sqlite_master WHERE type = 'table' "
    "AND name NOT LIKE 'sqlite_%'",
  );
  for (final table in tables) {
    final name = table['name'] as String;
    final columns = await db.rawQuery('PRAGMA table_info($name)');
    description[name] = {
      for (final column in columns)
        '${column['name']} ${column['type']} notnull=${column['notnull']} '
            'default=${column['dflt_value']} pk=${column['pk']}',
    };
  }
  final indexes = await db.rawQuery(
    "SELECT name, tbl_name FROM sqlite_master WHERE type = 'index' "
    "AND name LIKE 'idx_%'",
  );
  description['indexes'] = {
    for (final index in indexes) '${index['name']} on ${index['tbl_name']}',
  };
  return description;
}

void main() {
  setUpAll(useDesktopDatabases);

  test('a new database starts at the current version with shop settings', () async {
    final db = await (await openTestDatabase()).database;
    expect(await db.getVersion(), DatabaseSchema.version);
    final settings = (await db.query('shop_settings')).single;
    expect(settings['nextOrderNumber'], 1);
    expect(settings['orderPrefix'], 'TK-');
    expect(settings['defaultUnit'], 'in');
  });

  test('an upgraded database has the same structure as a new one', () async {
    final upgraded = await _upgradedFrom(_seedShop);
    final created = await (await openTestDatabase()).database;
    expect(await upgraded.getVersion(), DatabaseSchema.version);
    expect(await _describe(upgraded), await _describe(created));
  });

  test('customers are kept and gain an empty note', () async {
    final db = await _upgradedFrom(_seedShop);
    final customer = await _row(db, 'customers', 'faisal');
    expect(customer['name'], 'Faisal Shah');
    expect(customer['phone'], '03004128876');
    expect(customer['note'], isNull);
  });

  test('measurement text becomes numbers in a Formal Fit profile', () async {
    final db = await _upgradedFrom(_seedShop);
    final profile = await _row(db, 'measurements', 'profile');
    // The cleared waist value is dropped; the others keep their size.
    expect(jsonDecode(profile['measurementData'] as String), {
      'neck': 15.5,
      'chest': 40.0,
      'length': 42.0,
    });
    expect(profile['fitProfile'], 'Formal Fit');
    expect(profile['unit'], 'in');
    expect(profile['note'], isNull);
    expect(profile['updatedAt'], profile['createdAt']);
  });

  test('duplicate measurement records merge into the newest', () async {
    final db = await _upgradedFrom((db) async {
      await db.insert('customers', _customer('faisal', 'Faisal Shah'));
      await db.insert(
        'measurements',
        _measurement('older', values: {'chest': '39.5"'}, createdAt: _at(8, 1)),
      );
      await db.insert(
        'measurements',
        _measurement('newer', values: {'chest': '40.5"'}, createdAt: _at(9, 1)),
      );
      await db.insert(
        'measurements',
        _measurement(
          'kurta',
          garment: 'Kurta',
          values: {'chest': '41.0"'},
          createdAt: _at(7, 1),
        ),
      );
      await db.insert(
        'orders',
        _order(
          'linked',
          measurementId: 'older',
          status: 'Received',
          total: 3000,
          paid: 0,
          createdAt: _at(8, 2),
        ),
      );
    });
    final ids = (await db.query('measurements')).map((row) => row['id']);
    expect(ids, unorderedEquals(['newer', 'kurta']));
    expect((await _row(db, 'orders', 'linked'))['measurementId'], 'newer');
  });

  test('orders are numbered in the order they were created', () async {
    final db = await _upgradedFrom(_seedShop);
    final delivered = await _row(db, 'orders', 'delivered');
    final inProgress = await _row(db, 'orders', 'in-progress');
    final unpaid = await _row(db, 'orders', 'unpaid');
    expect(delivered['orderNumber'], 1);
    expect(inProgress['orderNumber'], 2);
    expect(unpaid['orderNumber'], 3);
    expect((await db.query('shop_settings')).single['nextOrderNumber'], 4);
  });

  test('order notes move to fabric and money is unchanged', () async {
    final db = await _upgradedFrom(_seedShop);
    final order = await _row(db, 'orders', 'in-progress');
    expect(order['fabric'], 'Wash & wear, off-white');
    expect(order['notes'], isNull);
    expect(order['pieces'], 1);
    expect(order['status'], 'Stitching');
    expect(order['totalAmount'], 4800);
    expect(order['advancePaid'], 2000);
    expect(order['measurementId'], 'profile');
  });

  test('each paid amount becomes one cash payment on the order date', () async {
    final db = await _upgradedFrom(_seedShop);
    final payments = await db.query('payments', orderBy: 'paidAt');
    expect(payments, hasLength(2));

    final settled = payments.first;
    expect(settled['orderId'], 'delivered');
    expect(settled['amount'], 3500);
    expect(settled['method'], 'cash');
    expect(settled['paidAt'], _at(8, 1));
    expect(settled['isAdvance'], 0);

    final advance = payments.last;
    expect(advance['orderId'], 'in-progress');
    expect(advance['amount'], 2000);
    expect(advance['paidAt'], _at(9, 28));
    expect(advance['isAdvance'], 1);
  });

  test('status history starts at creation and ends at the current stage', () async {
    final db = await _upgradedFrom(_seedShop);
    Future<List<(Object?, Object?)>> history(String orderId) async => [
      for (final event in await db.query(
        'order_status_events',
        where: 'orderId = ?',
        whereArgs: [orderId],
        orderBy: 'changedAt, rowid',
      ))
        (event['status'], event['changedAt']),
    ];

    expect(await history('unpaid'), [('Received', _at(10, 2))]);
    expect(await history('in-progress'), [
      ('Received', _at(9, 28)),
      ('Stitching', _at(9, 28)),
    ]);
    expect(await history('delivered'), [
      ('Received', _at(8, 1)),
      ('Delivered', _at(8, 9, 17)),
    ]);
  });

  test('deleting an upgraded order removes its payments and history', () async {
    final db = await _upgradedFrom(_seedShop);
    await db.delete('orders', where: 'id = ?', whereArgs: ['in-progress']);
    expect(
      await db.query(
        'payments',
        where: 'orderId = ?',
        whereArgs: ['in-progress'],
      ),
      isEmpty,
    );
    expect(
      await db.query(
        'order_status_events',
        where: 'orderId = ?',
        whereArgs: ['in-progress'],
      ),
      isEmpty,
    );
  });
}
