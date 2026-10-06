import 'package:flutter_test/flutter_test.dart';
import 'package:tailor_khata/core/database/database_helper.dart';
import 'package:tailor_khata/features/measurements/domain/entities/measurement_unit.dart';
import 'package:tailor_khata/features/settings/data/datasources/shop_settings_local_data_source.dart';
import 'package:tailor_khata/features/settings/data/repositories/shop_settings_repository_impl.dart';
import 'package:tailor_khata/features/settings/domain/entities/shop_settings.dart';
import 'package:tailor_khata/features/settings/domain/repositories/shop_settings_repository.dart';

import 'support/database_test_support.dart';

void main() {
  late DatabaseHelper database;
  late ShopSettingsRepository repository;

  setUpAll(useDesktopDatabases);

  setUp(() async {
    database = await openTestDatabase();
    repository = ShopSettingsRepositoryImpl(
      localDataSource: ShopSettingsLocalDataSourceImpl(dbHelper: database),
    );
  });

  test('a new shop has default settings', () async {
    final settings = valueOf(await repository.getSettings());
    expect(settings.props, const ShopSettings().props);
  });

  test('the shop profile and preferences are saved', () async {
    const edited = ShopSettings(
      shopName: 'Hassan Tailors',
      ownerName: 'Imran Hassan',
      phone: '03008841120',
      address: 'Anarkali, Lahore',
      openingTime: '11:00',
      closingTime: '21:00',
      orderPrefix: 'HT-',
      defaultUnit: MeasurementUnit.centimeters,
    );
    valueOf(await repository.updateSettings(edited));
    final saved = valueOf(await repository.getSettings());
    expect(saved.props, edited.props);
  });

  test('saving settings does not move the order-number counter', () async {
    final db = await database.database;
    await db.update('shop_settings', {'nextOrderNumber': 43});

    // A copy read before the counter advanced.
    valueOf(
      await repository.updateSettings(
        const ShopSettings(shopName: 'Hassan Tailors', nextOrderNumber: 1),
      ),
    );

    final saved = valueOf(await repository.getSettings());
    expect(saved.shopName, 'Hassan Tailors');
    expect(saved.nextOrderNumber, 43);
  });

  test('order numbers are shown with the prefix and four digits', () {
    const settings = ShopSettings();
    expect(settings.orderLabel(42), 'TK-0042');
    expect(settings.orderLabel(1042), 'TK-1042');
    expect(settings.orderLabel(12345), 'TK-12345');
    expect(const ShopSettings(orderPrefix: 'HT-').orderLabel(7), 'HT-0007');
  });
}
