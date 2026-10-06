import 'package:tailor_khata/features/measurements/domain/entities/measurement_unit.dart';
import 'package:tailor_khata/features/settings/domain/entities/shop_settings.dart';

class ShopSettingsModel extends ShopSettings {
  const ShopSettingsModel({
    super.shopName,
    super.ownerName,
    super.phone,
    super.address,
    super.openingTime,
    super.closingTime,
    super.orderPrefix,
    super.nextOrderNumber,
    super.defaultUnit,
  });

  factory ShopSettingsModel.fromEntity(ShopSettings entity) {
    return ShopSettingsModel(
      shopName: entity.shopName,
      ownerName: entity.ownerName,
      phone: entity.phone,
      address: entity.address,
      openingTime: entity.openingTime,
      closingTime: entity.closingTime,
      orderPrefix: entity.orderPrefix,
      nextOrderNumber: entity.nextOrderNumber,
      defaultUnit: entity.defaultUnit,
    );
  }

  factory ShopSettingsModel.fromJson(Map<String, dynamic> json) {
    return ShopSettingsModel(
      shopName: json['shopName'] as String,
      ownerName: json['ownerName'] as String,
      phone: json['phone'] as String,
      address: json['address'] as String,
      openingTime: json['openingTime'] as String?,
      closingTime: json['closingTime'] as String?,
      orderPrefix: json['orderPrefix'] as String,
      nextOrderNumber: json['nextOrderNumber'] as int,
      defaultUnit: MeasurementUnit.fromCode(json['defaultUnit'] as String),
    );
  }

  /// The editable columns. The order-number counter is written only when an
  /// order is saved.
  Map<String, dynamic> toJson() {
    return {
      'shopName': shopName,
      'ownerName': ownerName,
      'phone': phone,
      'address': address,
      'openingTime': openingTime,
      'closingTime': closingTime,
      'orderPrefix': orderPrefix,
      'defaultUnit': defaultUnit.code,
    };
  }
}
