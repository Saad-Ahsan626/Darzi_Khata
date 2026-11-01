import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tailor_khata/core/database/database_helper.dart';
import 'package:tailor_khata/core/providers/clock_provider.dart';
import 'package:tailor_khata/core/routing/app_router.dart';
import 'package:tailor_khata/core/theme/app_theme.dart';
import 'package:tailor_khata/core/theme/design_tokens.dart';
import 'package:tailor_khata/features/backup/data/backup_service.dart';
import 'package:tailor_khata/features/backup/domain/backup_summary.dart';
import 'package:tailor_khata/features/backup/presentation/backup_providers.dart';
import 'package:tailor_khata/features/customers/domain/entities/customer.dart';
import 'package:tailor_khata/features/customers/presentation/providers/customers_notifier.dart';
import 'package:tailor_khata/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:tailor_khata/features/measurements/domain/entities/measurement.dart';
import 'package:tailor_khata/features/measurements/presentation/providers/measurements_notifier.dart';
import 'package:tailor_khata/features/orders/domain/entities/order.dart';
import 'package:tailor_khata/features/orders/domain/entities/payment.dart';
import 'package:tailor_khata/features/orders/presentation/providers/orders_notifier.dart';
import 'package:tailor_khata/features/settings/domain/entities/shop_settings.dart';
import 'package:tailor_khata/features/settings/presentation/providers/shop_settings_providers.dart';

final _now = DateTime(2026, 11, 1, 10, 30);
final _backupSummary = BackupSummary(
  createdAt: DateTime(2026, 10, 28, 18, 5),
  customers: 5,
  orders: 9,
);

/// Backups without files: records what the screen asked for.
class _Backups extends BackupService {
  _Backups()
    : super(
        database: DatabaseHelper.atPath('unused.db'),
        photosDirectory: () async => Directory.systemTemp,
        workDirectory: () async => Directory.systemTemp,
      );

  final calls = <String>[];
  BackupException? refusal;

  @override
  Future<({File file, BackupSummary summary})> create(DateTime now) async {
    calls.add('create');
    return (
      file: File('DarziKhata-backup-2026-11-01.zip'),
      summary: BackupSummary(createdAt: now, customers: 2, orders: 3),
    );
  }

  @override
  Future<PreparedRestore> prepare(Stream<List<int>> backup) async {
    calls.add('prepare');
    if (refusal case final refusal?) throw refusal;
    return PreparedRestore(
      summary: _backupSummary,
      databasePath: 'records.db',
      photos: const {},
    );
  }

  @override
  Future<void> restore(PreparedRestore backup) async => calls.add('restore');
}

class _Preferences extends BackupPreferences {
  DateTime? last;

  @override
  Future<DateTime?> lastBackup() async => last;

  @override
  Future<void> markBackedUp(DateTime at) async => last = at;
}

/// Counts how often the customers were read, to see the reload.
int _customerReads = 0;

class _Customers extends CustomersNotifier {
  @override
  Future<List<Customer>> build() async {
    _customerReads++;
    return [
      for (final name in ['Faisal Shah', 'Nida Aslam'])
        Customer(id: name, name: name, createdAt: DateTime(2026)),
    ];
  }
}

class _Orders extends OrdersNotifier {
  @override
  Future<List<Order>> build() async => const [];
}

class _Measurements extends MeasurementsNotifier {
  @override
  Future<List<Measurement>> build() async => const [];
}

class _Fixture {
  final backups = _Backups();
  final preferences = _Preferences();
  final shared = <(String, String)>[];
  bool shareCompletes = true;
  Stream<List<int>>? picked = Stream.value([1, 2, 3]);
}

Future<_Fixture> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  _customerReads = 0;
  final fixture = _Fixture();
  final router = createAppRouter(initialLocation: '/settings');
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        backupServiceProvider.overrideWithValue(fixture.backups),
        backupPreferencesProvider.overrideWithValue(fixture.preferences),
        shareBackupProvider.overrideWithValue((file, caption) async {
          fixture.shared.add((file.path, caption));
          return fixture.shareCompletes;
        }),
        pickBackupProvider.overrideWithValue(() async => fixture.picked),
        customersNotifierProvider.overrideWith(_Customers.new),
        ordersNotifierProvider.overrideWith(_Orders.new),
        measurementsNotifierProvider.overrideWith(_Measurements.new),
        paymentsProvider.overrideWith((ref) async => const <Payment>[]),
        shopSettingsProvider.overrideWith((ref) => const ShopSettings()),
        clockProvider.overrideWithValue(() => _now),
      ],
      child: MaterialApp.router(
        theme: AppTheme.lightTheme,
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return fixture;
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final font = FontLoader(AppTypography.fontFamily);
    for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      font.addFont(rootBundle.load('assets/fonts/inter/Inter-$weight.ttf'));
    }
    await font.load();
    final icons = FontLoader('MaterialIcons');
    icons.addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });

  testWidgets('a backup is shared and remembered', (tester) async {
    final fixture = await _pump(tester);
    expect(find.text('Not backed up yet · 2 customers'), findsOneWidget);

    await _tap(tester, find.text('Backup & export'));
    expect(fixture.shared, [
      ('DarziKhata-backup-2026-11-01.zip', 'Darzi Khata backup · 1 Nov 2026'),
    ]);
    expect(fixture.preferences.last, _now);
    expect(find.text('Last backup 1 Nov · 2 customers'), findsOneWidget);
    expect(find.text('Backup shared'), findsOneWidget);
    expect(find.text('2 customers · 3 orders'), findsOneWidget);
  });

  testWidgets('closing the share sheet is not counted as a backup', (
    tester,
  ) async {
    final fixture = await _pump(tester);
    fixture.shareCompletes = false;
    await _tap(tester, find.text('Backup & export'));
    expect(fixture.shared, hasLength(1));
    expect(fixture.preferences.last, isNull);
    expect(find.text('Not backed up yet · 2 customers'), findsOneWidget);
  });

  testWidgets('restoring asks first, then reloads everything and opens Home', (
    tester,
  ) async {
    final fixture = await _pump(tester);
    final readsBefore = _customerReads;
    await _tap(tester, find.text('Restore from file'));

    expect(find.text('Replace everything with this backup?'), findsOneWidget);
    expect(
      find.text(
        'The backup from 28 Oct 2026, 6:05 PM has 5 customers and 9 orders. '
        'It replaces the 2 customers and 0 orders on this device. This '
        'cannot be undone.',
      ),
      findsOneWidget,
    );
    await _tap(tester, find.text('Replace with backup'));

    expect(fixture.backups.calls, ['prepare', 'restore']);
    expect(_customerReads, greaterThan(readsBefore));
    expect(find.byType(DashboardScreen), findsOneWidget);
    expect(find.text('Backup restored'), findsOneWidget);
    expect(find.text('5 customers · 9 orders'), findsOneWidget);
  });

  testWidgets('keeping the current records restores nothing', (tester) async {
    final fixture = await _pump(tester);
    await _tap(tester, find.text('Restore from file'));
    await _tap(tester, find.text('Keep current records'));
    expect(fixture.backups.calls, ['prepare']);
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('a file that is not a backup is explained', (tester) async {
    final fixture = await _pump(tester);
    fixture.backups.refusal = const BackupException(
      'This file is not a Darzi Khata backup.',
    );
    await _tap(tester, find.text('Restore from file'));
    expect(find.text('This file is not a Darzi Khata backup.'), findsOneWidget);
    expect(find.text('Replace everything with this backup?'), findsNothing);
    expect(fixture.backups.calls, ['prepare']);
  });

  testWidgets('choosing no file does nothing', (tester) async {
    final fixture = await _pump(tester);
    fixture.picked = null;
    await _tap(tester, find.text('Restore from file'));
    expect(fixture.backups.calls, isEmpty);
  });
}
