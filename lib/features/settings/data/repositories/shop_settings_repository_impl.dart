import 'package:fpdart/fpdart.dart';
import 'package:tailor_khata/core/error/exceptions.dart';
import 'package:tailor_khata/core/error/failures.dart';
import 'package:tailor_khata/features/settings/data/datasources/shop_settings_local_data_source.dart';
import 'package:tailor_khata/features/settings/data/models/shop_settings_model.dart';
import 'package:tailor_khata/features/settings/domain/entities/shop_settings.dart';
import 'package:tailor_khata/features/settings/domain/repositories/shop_settings_repository.dart';

class ShopSettingsRepositoryImpl implements ShopSettingsRepository {
  final ShopSettingsLocalDataSource localDataSource;

  ShopSettingsRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, ShopSettings>> getSettings() async {
    try {
      final model = await localDataSource.getSettings();
      return Right(model);
    } on LocalDatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> updateSettings(ShopSettings settings) async {
    try {
      final model = ShopSettingsModel.fromEntity(settings);
      await localDataSource.updateSettings(model);
      return const Right(null);
    } on LocalDatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    }
  }
}
