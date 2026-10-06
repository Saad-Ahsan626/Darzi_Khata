import 'package:tailor_khata/core/database/database_helper.dart';
import 'package:tailor_khata/core/database/database_schema.dart';
import 'package:tailor_khata/core/error/exceptions.dart';
import 'package:tailor_khata/features/settings/data/models/shop_settings_model.dart';

abstract class ShopSettingsLocalDataSource {
  Future<ShopSettingsModel> getSettings();
  Future<void> updateSettings(ShopSettingsModel settings);
}

class ShopSettingsLocalDataSourceImpl implements ShopSettingsLocalDataSource {
  final DatabaseHelper dbHelper;

  ShopSettingsLocalDataSourceImpl({required this.dbHelper});

  @override
  Future<ShopSettingsModel> getSettings() async {
    try {
      final db = await dbHelper.database;
      final result = await db.query(DatabaseSchema.shopSettingsTable);
      return ShopSettingsModel.fromJson(result.first);
    } catch (e) {
      throw LocalDatabaseException('Failed to fetch shop settings: $e');
    }
  }

  @override
  Future<void> updateSettings(ShopSettingsModel settings) async {
    try {
      final db = await dbHelper.database;
      await db.update(DatabaseSchema.shopSettingsTable, settings.toJson());
    } catch (e) {
      throw LocalDatabaseException('Failed to update shop settings: $e');
    }
  }
}
