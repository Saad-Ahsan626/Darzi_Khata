import 'package:fpdart/fpdart.dart';
import 'package:tailor_khata/core/error/failures.dart';
import 'package:tailor_khata/core/usecase/usecase.dart';
import 'package:tailor_khata/features/settings/domain/entities/shop_settings.dart';
import 'package:tailor_khata/features/settings/domain/repositories/shop_settings_repository.dart';

class UpdateShopSettings implements UseCase<void, ShopSettings> {
  final ShopSettingsRepository repository;

  UpdateShopSettings(this.repository);

  @override
  Future<Either<Failure, void>> call(ShopSettings params) async {
    return await repository.updateSettings(params);
  }
}
