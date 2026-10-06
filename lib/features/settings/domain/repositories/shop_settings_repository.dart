import 'package:fpdart/fpdart.dart';
import 'package:tailor_khata/core/error/failures.dart';
import 'package:tailor_khata/features/settings/domain/entities/shop_settings.dart';

abstract class ShopSettingsRepository {
  Future<Either<Failure, ShopSettings>> getSettings();

  /// Saves the profile and preferences; the order-number counter is kept.
  Future<Either<Failure, void>> updateSettings(ShopSettings settings);
}
