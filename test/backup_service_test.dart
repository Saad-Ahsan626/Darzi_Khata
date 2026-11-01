import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tailor_khata/core/database/database_helper.dart';
import 'package:tailor_khata/features/backup/data/backup_service.dart';
import 'package:tailor_khata/features/backup/domain/backup_summary.dart';
import 'package:tailor_khata/features/customers/data/datasources/customer_local_data_source.dart';
import 'package:tailor_khata/features/customers/data/models/customer_model.dart';
import 'package:tailor_khata/features/orders/data/datasources/order_local_data_source.dart';
import 'package:tailor_khata/features/orders/data/models/order_model.dart';

import 'support/database_test_support.dart';

final _now = DateTime(2026, 11, 1, 10, 30);

Directory _tempFolder(String name) {
  final folder = Directory.systemTemp.createTempSync('darzi_$name');
  addTearDown(() {
    if (folder.existsSync()) folder.deleteSync(recursive: true);
  });
  return folder;
}

/// A zip with the given entries, as a stream like the file picker gives.
Stream<List<int>> _zip(Map<String, List<int>> entries) {
  final archive = Archive();
  for (final MapEntry(:key, :value) in entries.entries) {
    archive.addFile(ArchiveFile.bytes(key, value));
  }
  return Stream.value(ZipEncoder().encodeBytes(archive));
}

List<int> _manifest({int format = 1, String app = 'darzi-khata'}) =>
    utf8.encode(
      jsonEncode({
        'app': app,
        'format': format,
        'schemaVersion': 5,
        'createdAt': _now.toIso8601String(),
      }),
    );

/// A bare SQLite file at [version] with only customers and orders.
Future<List<int>> _bareDatabase(int version) async {
  final path = p.join(_tempFolder('bare').path, 'bare.db');
  final db = await openDatabase(
    path,
    version: version,
    onCreate: (db, _) async {
      await db.execute('CREATE TABLE customers (id TEXT PRIMARY KEY)');
      await db.execute('CREATE TABLE orders (id TEXT PRIMARY KEY)');
    },
  );
  await db.close();
  return File(path).readAsBytes();
}

void main() {
  late DatabaseHelper database;
  late Directory photos;
  late BackupService service;
  late CustomerLocalDataSourceImpl customers;

  setUpAll(useDesktopDatabases);

  setUp(() async {
    database = await openTestDatabase();
    photos = _tempFolder('photos');
    final work = _tempFolder('work');
    service = BackupService(
      database: database,
      photosDirectory: () async => photos,
      workDirectory: () async => work,
    );
    customers = CustomerLocalDataSourceImpl(dbHelper: database);
    await customers.addCustomer(
      CustomerModel(
        id: 'faisal',
        name: 'Faisal Shah',
        imagePath: 'faisal.jpg',
        createdAt: DateTime(2026, 3, 1),
      ),
    );
    File(p.join(photos.path, 'faisal.jpg')).writeAsBytesSync([1, 2, 3]);
    await OrderLocalDataSourceImpl(dbHelper: database).addOrder(
      OrderModel(
        id: 'order',
        customerId: 'faisal',
        garmentType: 'Kurta',
        status: 'Received',
        deliveryDate: DateTime(2026, 11, 9),
        totalAmount: 3000,
        paidAmount: 1000,
        createdAt: DateTime(2026, 11, 1),
      ),
    );
  });

  test('a backup holds the records, the photos and a manifest', () async {
    final backup = await service.create(_now);
    expect(p.basename(backup.file.path), 'DarziKhata-backup-2026-11-01.zip');
    expect(
      backup.summary,
      BackupSummary(createdAt: _now, customers: 1, orders: 1),
    );

    final archive = ZipDecoder().decodeBytes(backup.file.readAsBytesSync());
    expect([for (final file in archive.files) file.name]..sort(), [
      'darzi-khata-backup.json',
      'photos/faisal.jpg',
      'records.db',
    ]);
    expect(archive.find('photos/faisal.jpg')!.readBytes(), [1, 2, 3]);
    // The records stay usable after the copy.
    expect(await customers.getCustomers(), hasLength(1));
  });

  test('restoring brings back the records and photos as backed up', () async {
    final backup = await service.create(_now);

    await customers.addCustomer(
      CustomerModel(id: 'nida', name: 'Nida Aslam', createdAt: _now),
    );
    await customers.deleteCustomer('faisal');
    File(p.join(photos.path, 'faisal.jpg')).deleteSync();

    final prepared = await service.prepare(backup.file.openRead());
    expect(
      prepared.summary,
      BackupSummary(createdAt: _now, customers: 1, orders: 1),
    );
    await service.restore(prepared);

    expect(
      [for (final c in await customers.getCustomers()) c.name],
      ['Faisal Shah'],
    );
    expect(
      await OrderLocalDataSourceImpl(dbHelper: database).getOrders(),
      hasLength(1),
    );
    expect(File(p.join(photos.path, 'faisal.jpg')).readAsBytesSync(), [
      1,
      2,
      3,
    ]);
  });

  group('a file that cannot be restored is refused', () {
    Future<String> refusal(Stream<List<int>> file) async {
      try {
        await service.prepare(file);
      } on BackupException catch (error) {
        return error.message;
      }
      fail('Expected the file to be refused');
    }

    test('any other file', () async {
      expect(
        await refusal(Stream.value(utf8.encode('hello'))),
        'This file is not a Darzi Khata backup.',
      );
    });

    test('a zip from somewhere else', () async {
      expect(
        await refusal(_zip({'notes.txt': utf8.encode('hello')})),
        'This file is not a Darzi Khata backup.',
      );
      expect(
        await refusal(
          _zip({
            'darzi-khata-backup.json': _manifest(app: 'other'),
            'records.db': await _bareDatabase(5),
          }),
        ),
        'This file is not a Darzi Khata backup.',
      );
    });

    test('a backup from a newer version of the app', () async {
      expect(
        await refusal(
          _zip({
            'darzi-khata-backup.json': _manifest(),
            'records.db': await _bareDatabase(99),
          }),
        ),
        contains('newer version'),
      );
    });
  });

  test('a backup that fails to open leaves the records untouched', () async {
    // Passes the checks, but cannot be upgraded: it has no measurements.
    final prepared = await service.prepare(
      _zip({
        'darzi-khata-backup.json': _manifest(),
        'records.db': await _bareDatabase(4),
      }),
    );
    await expectLater(
      service.restore(prepared),
      throwsA(
        isA<BackupException>().having(
          (error) => error.message,
          'message',
          contains('nothing on this device was changed'),
        ),
      ),
    );
    expect(
      [for (final c in await customers.getCustomers()) c.name],
      ['Faisal Shah'],
    );
    expect(
      File('${await database.filePath}.before-restore').existsSync(),
      isFalse,
    );
  });

  test('reads wait while the database file is closed', () async {
    final release = Completer<void>();
    final closed = database.whileClosed((_) => release.future);
    var read = false;
    final reading = database.database.then((_) => read = true);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(read, isFalse);
    release.complete();
    await closed;
    await reading;
    expect(read, isTrue);
  });
}
