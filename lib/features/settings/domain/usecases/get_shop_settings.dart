import 'package:fpdart/fpdart.dart';
import 'package:tailor_khata/core/error/failures.dart';
import 'package:tailor_khata/core/usecase/usecase.dart';
import 'package:tailor_khata/features/settings/domain/entities/shop_settings.dart';
import 'package:tailor_khata/features/settings/domain/repositories/shop_settings_repository.dart';

class GetShopSettings implements UseCase<ShopSettings, NoParams> {
  final ShopSettingsRepository repository;

  GetShopSettings(this.repository);

  @override
  Future<Either<Failure, ShopSettings>> call(NoParams params) async {
    return await repository.getSettings();
  }
}
