import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:tailor_khata/core/database/database_helper.dart';
import 'package:tailor_khata/core/database/database_schema.dart';
import 'package:tailor_khata/features/backup/domain/backup_summary.dart';

/// A backup unpacked into a scratch folder and checked, ready to restore.
class PreparedRestore {
  final BackupSummary summary;
  final String databasePath;

  /// Photo file names with where each was unpacked.
  final Map<String, String> photos;

  const PreparedRestore({
    required this.summary,
    required this.databasePath,
    required this.photos,
  });
}

/// Makes and restores backups: one zip with the database, the customers'
/// photos and a manifest describing them.
class BackupService {
  BackupService({
    required this.database,
    required this.photosDirectory,
    required this.workDirectory,
  });

  final DatabaseHelper database;

  /// Where customer photos are kept.
  final Future<Directory> Function() photosDirectory;

  /// A place for scratch files, such as the app's cache.
  final Future<Directory> Function() workDirectory;

  /// The manifest's format; raised if the backup's layout ever changes.
  static const format = 1;
  static const _app = 'darzi-khata';
  static const _manifestName = 'darzi-khata-backup.json';
  static const _databaseName = 'records.db';
  static const _photosFolder = 'photos/';
  static const _notABackup = 'This file is not a Darzi Khata backup.';

  /// Copies everything into a zip in the scratch folder, named for [now].
  Future<({File file, BackupSummary summary})> create(DateTime now) async {
    final db = await database.database;
    final summary = BackupSummary(
      createdAt: now,
      customers: await _count(db, DatabaseSchema.customersTable),
      orders: await _count(db, DatabaseSchema.ordersTable),
    );
    final photoNames = [
      for (final row in await db.query(
        DatabaseSchema.customersTable,
        columns: ['imagePath'],
        where: "imagePath IS NOT NULL AND imagePath != ''",
      ))
        row['imagePath'] as String,
    ];

    final work = await _freshFolder('backup');
    final copy = p.join(work.path, _databaseName);
    // Closed for the copy, so nothing is half-written into it.
    await database.whileClosed((path) => File(path).copy(copy));

    final date = now.toIso8601String().substring(0, 10);
    final zipPath = p.join(work.path, 'DarziKhata-backup-$date.zip');
    final manifest = jsonEncode({
      'app': _app,
      'format': format,
      'schemaVersion': DatabaseSchema.version,
      'createdAt': now.toIso8601String(),
      'customers': summary.customers,
      'orders': summary.orders,
    });
    final photos = (await photosDirectory()).path;
    await _zipInBackground(zipPath, manifest, copy, photos, photoNames);
    await File(copy).delete();
    return (file: File(zipPath), summary: summary);
  }

  /// Takes in a backup the shop picked, checks it and unpacks it. Throws a
  /// [BackupException] saying why when it cannot be used.
  Future<PreparedRestore> prepare(Stream<List<int>> backup) async {
    final work = await _freshFolder('restore');
    final zipPath = p.join(work.path, 'picked.zip');
    await backup.pipe(File(zipPath).openWrite());

    final unpacked = p.join(work.path, 'unpacked');
    final manifestText = await _unpackInBackground(zipPath, unpacked);
    final manifest = _decodeManifest(manifestText);

    final databasePath = p.join(unpacked, _databaseName);
    if (!await _isSqlite(databasePath)) {
      throw const BackupException(_notABackup);
    }
    final Database db;
    try {
      db = await openDatabase(
        databasePath,
        readOnly: true,
        singleInstance: false,
      );
    } on Exception {
      throw const BackupException(_notABackup);
    }
    try {
      final version = await db.getVersion();
      if (version > DatabaseSchema.version) {
        throw const BackupException(
          'This backup was made by a newer version of Darzi Khata. Update '
          'the app, then restore it.',
        );
      }
      final tables = {
        for (final row in await db.query(
          'sqlite_master',
          columns: ['name'],
          where: "type = 'table'",
        ))
          row['name'],
      };
      if (version < 1 ||
          !tables.contains(DatabaseSchema.customersTable) ||
          !tables.contains(DatabaseSchema.ordersTable)) {
        throw const BackupException(_notABackup);
      }
      final photos = <String, String>{};
      final photosFolder = Directory(p.join(unpacked, 'photos'));
      if (await photosFolder.exists()) {
        await for (final file in photosFolder.list()) {
          if (file is File) photos[p.basename(file.path)] = file.path;
        }
      }
      return PreparedRestore(
        summary: BackupSummary(
          createdAt: manifest.createdAt,
          customers: await _count(db, DatabaseSchema.customersTable),
          orders: await _count(db, DatabaseSchema.ordersTable),
        ),
        databasePath: databasePath,
        photos: photos,
      );
    } finally {
      await db.close();
    }
  }

  /// Replaces everything on this device with [backup]. Should the backup
  /// fail to open, the records as they were are put back and a
  /// [BackupException] is thrown.
  Future<void> restore(PreparedRestore backup) async {
    String? safetyCopy;
    try {
      await database.whileClosed((path) async {
        safetyCopy = '$path.before-restore';
        await File(path).copy(safetyCopy!);
        await _deleteSidecars(path);
        await File(backup.databasePath).copy(path);
      });
    } on Exception {
      final kept = safetyCopy;
      if (kept != null && await File(kept).exists()) {
        await database.whileClosed((path) async {
          await _deleteSidecars(path);
          await File(kept).copy(path);
        });
        await File(kept).delete();
      }
      throw const BackupException(
        "The backup couldn't be opened, so nothing on this device was "
        'changed.',
      );
    }
    if (safetyCopy case final kept?) await File(kept).delete();

    final photos = await photosDirectory();
    for (final MapEntry(key: name, value: from) in backup.photos.entries) {
      await File(from).copy(p.join(photos.path, name));
    }
    await _clearWork();
  }

  Future<int> _count(Database db, String table) async =>
      Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM $table')) ??
      0;

  ({DateTime createdAt}) _decodeManifest(String? text) {
    try {
      final manifest = jsonDecode(text!) as Map<String, dynamic>;
      if (manifest['app'] != _app) throw const BackupException(_notABackup);
      if ((manifest['format'] as int) > format) {
        throw const BackupException(
          'This backup was made by a newer version of Darzi Khata. Update '
          'the app, then restore it.',
        );
      }
      return (createdAt: DateTime.parse(manifest['createdAt'] as String));
    } on BackupException {
      rethrow;
    } catch (_) {
      throw const BackupException(_notABackup);
    }
  }

  Future<bool> _isSqlite(String path) async {
    final file = File(path);
    if (!await file.exists()) return false;
    final header = await file.openRead(0, 16).expand((bytes) => bytes).toList();
    return utf8.decode(header, allowMalformed: true) == 'SQLite format 3\u0000';
  }

  Future<void> _deleteSidecars(String path) async {
    for (final suffix in ['-wal', '-shm', '-journal']) {
      final file = File('$path$suffix');
      if (await file.exists()) await file.delete();
    }
  }

  Future<Directory> _freshFolder(String name) async {
    final folder = Directory(
      p.join((await workDirectory()).path, 'darzi-khata-$name'),
    );
    if (await folder.exists()) await folder.delete(recursive: true);
    return folder.create(recursive: true);
  }

  Future<void> _clearWork() async {
    final folder = Directory(
      p.join((await workDirectory()).path, 'darzi-khata-restore'),
    );
    if (await folder.exists()) await folder.delete(recursive: true);
  }
}

// The isolate helpers are top-level so their closures carry only the paths
// passed in, never the service and its open database.

Future<void> _zipInBackground(
  String zipPath,
  String manifest,
  String databaseCopy,
  String photosFolder,
  List<String> photoNames,
) => Isolate.run(
  () => _writeZip(zipPath, manifest, databaseCopy, photosFolder, photoNames),
);

Future<String?> _unpackInBackground(String zipPath, String folder) =>
    Isolate.run(() => _unpackZip(zipPath, folder));

/// Runs on a background isolate: zips the database copy, the photos that
/// still exist and the manifest.
void _writeZip(
  String zipPath,
  String manifest,
  String databaseCopy,
  String photosFolder,
  List<String> photoNames,
) {
  final archive = Archive()
    ..addFile(ArchiveFile.string(BackupService._manifestName, manifest))
    ..addFile(
      ArchiveFile.bytes(
        BackupService._databaseName,
        File(databaseCopy).readAsBytesSync(),
      ),
    );
  for (final name in photoNames.toSet()) {
    final photo = File(p.join(photosFolder, p.basename(name)));
    if (!photo.existsSync()) continue;
    final bytes = photo.readAsBytesSync();
    // Photos are compressed already.
    archive.addFile(
      ArchiveFile.noCompress(
        '${BackupService._photosFolder}${p.basename(name)}',
        bytes.length,
        bytes,
      ),
    );
  }
  File(zipPath).writeAsBytesSync(ZipEncoder().encodeBytes(archive));
}

/// Runs on a background isolate: unpacks the database and photos into
/// [folder] and returns the manifest's text, or null when the file is not a
/// zip or has no manifest.
String? _unpackZip(String zipPath, String folder) {
  final Archive archive;
  try {
    archive = ZipDecoder().decodeBytes(
      File(zipPath).readAsBytesSync(),
      verify: true,
    );
  } catch (_) {
    return null;
  }
  final manifest = archive.find(BackupService._manifestName)?.readBytes();
  final database = archive.find(BackupService._databaseName)?.readBytes();
  if (manifest == null || database == null) return null;

  Directory(p.join(folder, 'photos')).createSync(recursive: true);
  File(p.join(folder, BackupService._databaseName)).writeAsBytesSync(database);
  for (final file in archive.files) {
    if (!file.isFile || !file.name.startsWith(BackupService._photosFolder)) {
      continue;
    }
    // Only a plain file name is used, so an entry cannot write elsewhere.
    final name = p.basename(file.name);
    final bytes = file.readBytes();
    if (name.isEmpty || name.startsWith('.') || bytes == null) continue;
    File(p.join(folder, 'photos', name)).writeAsBytesSync(bytes);
  }
  return utf8.decode(manifest);
}
