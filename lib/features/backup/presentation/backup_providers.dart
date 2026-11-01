import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tailor_khata/core/providers/database_provider.dart';
import 'package:tailor_khata/features/backup/data/backup_service.dart';

final backupServiceProvider = Provider<BackupService>(
  (ref) => BackupService(
    database: ref.watch(databaseProvider),
    photosDirectory: getApplicationDocumentsDirectory,
    workDirectory: getTemporaryDirectory,
  ),
);

/// Remembers on this device when a backup was last shared.
class BackupPreferences {
  static const _lastBackup = 'lastBackupAt';

  Future<DateTime?> lastBackup() async {
    final millis = (await SharedPreferences.getInstance()).getInt(_lastBackup);
    return millis == null ? null : DateTime.fromMillisecondsSinceEpoch(millis);
  }

  Future<void> markBackedUp(DateTime at) async =>
      (await SharedPreferences.getInstance()).setInt(
        _lastBackup,
        at.millisecondsSinceEpoch,
      );
}

final backupPreferencesProvider = Provider<BackupPreferences>(
  (ref) => BackupPreferences(),
);

/// When a backup was last shared from this device, or null if never.
final lastBackupProvider = FutureProvider<DateTime?>(
  (ref) => ref.watch(backupPreferencesProvider).lastBackup(),
);

/// Hands a backup file to the phone's share sheet, with [caption] for apps
/// that show one. Resolves to false when the sheet was closed without
/// choosing anywhere.
final shareBackupProvider = Provider<Future<bool> Function(File, String)>(
  (ref) => (file, caption) async {
    final result = await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/zip')],
        subject: caption,
        text: caption,
      ),
    );
    return result.status != ShareResultStatus.dismissed;
  },
);

/// Lets the shop choose a backup file. Resolves to its bytes, or null when
/// nothing was chosen.
final pickBackupProvider = Provider<Future<Stream<List<int>>?> Function()>(
  (ref) => () async {
    final file = await FilePicker.pickFile(
      dialogTitle: 'Choose a Darzi Khata backup',
    );
    return file?.readAsByteStream();
  },
);
