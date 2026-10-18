import 'package:equatable/equatable.dart';
import 'package:tailor_khata/features/measurements/domain/entities/measurement_unit.dart';

/// The shop's profile and preferences. Empty text means not set yet.
class ShopSettings extends Equatable {
  final String shopName;
  final String ownerName;
  final String phone;
  final String address;

  /// Shop hours as 24-hour `HH:mm`.
  final String? openingTime;
  final String? closingTime;
  final String orderPrefix;

  /// The number the next new order receives. It advances when an order is
  /// saved and is not changed by editing settings.
  final int nextOrderNumber;

  /// Unit used for new measurement profiles.
  final MeasurementUnit defaultUnit;

  const ShopSettings({
    this.shopName = '',
    this.ownerName = '',
    this.phone = '',
    this.address = '',
    this.openingTime,
    this.closingTime,
    this.orderPrefix = 'DK-',
    this.nextOrderNumber = 1,
    this.defaultUnit = MeasurementUnit.inches,
  });

  /// The order number as shown to the shop, such as `DK-0042`.
  String orderLabel(int orderNumber) =>
      '$orderPrefix${orderNumber.toString().padLeft(4, '0')}';

  /// Whether the shop has said when it opens and closes.
  bool get hasHours => openingTime != null && closingTime != null;

  /// A copy with the given values. Hours are replaced together by passing
  /// [hours]; a null record clears them.
  ShopSettings copyWith({
    String? shopName,
    String? ownerName,
    String? phone,
    String? address,
    ({String opens, String closes})? Function()? hours,
    String? orderPrefix,
    MeasurementUnit? defaultUnit,
  }) {
    final newHours = hours?.call();
    return ShopSettings(
      shopName: shopName ?? this.shopName,
      ownerName: ownerName ?? this.ownerName,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      openingTime: hours == null ? openingTime : newHours?.opens,
      closingTime: hours == null ? closingTime : newHours?.closes,
      orderPrefix: orderPrefix ?? this.orderPrefix,
      nextOrderNumber: nextOrderNumber,
      defaultUnit: defaultUnit ?? this.defaultUnit,
    );
  }

  @override
  List<Object?> get props => [
        shopName,
        ownerName,
        phone,
        address,
        openingTime,
        closingTime,
        orderPrefix,
        nextOrderNumber,
        defaultUnit,
      ];
}
