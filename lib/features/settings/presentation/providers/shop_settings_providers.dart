import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tailor_khata/core/providers/database_provider.dart';
import 'package:tailor_khata/core/usecase/usecase.dart';

import 'package:tailor_khata/features/settings/data/datasources/shop_settings_local_data_source.dart';
import 'package:tailor_khata/features/settings/data/repositories/shop_settings_repository_impl.dart';
import 'package:tailor_khata/features/settings/domain/entities/shop_settings.dart';
import 'package:tailor_khata/features/settings/domain/repositories/shop_settings_repository.dart';
import 'package:tailor_khata/features/settings/domain/usecases/get_shop_settings.dart';
import 'package:tailor_khata/features/settings/domain/usecases/update_shop_settings.dart';

final shopSettingsLocalDataSourceProvider =
    Provider<ShopSettingsLocalDataSource>((ref) {
      final dbHelper = ref.watch(databaseProvider);
      return ShopSettingsLocalDataSourceImpl(dbHelper: dbHelper);
    });

final shopSettingsRepositoryProvider = Provider<ShopSettingsRepository>((ref) {
  final localDataSource = ref.watch(shopSettingsLocalDataSourceProvider);
  return ShopSettingsRepositoryImpl(localDataSource: localDataSource);
});

final getShopSettingsUsecaseProvider = Provider<GetShopSettings>((ref) {
  return GetShopSettings(ref.watch(shopSettingsRepositoryProvider));
});

final updateShopSettingsUsecaseProvider = Provider<UpdateShopSettings>((ref) {
  return UpdateShopSettings(ref.watch(shopSettingsRepositoryProvider));
});

/// The shop's saved settings.
final shopSettingsProvider = FutureProvider<ShopSettings>((ref) async {
  final result = await ref.watch(getShopSettingsUsecaseProvider)(
    const NoParams(),
  );
  return result.fold(
    (failure) => throw Exception(failure.message),
    (settings) => settings,
  );
});
