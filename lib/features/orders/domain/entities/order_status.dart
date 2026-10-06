/// Order stages, in the order work moves through them.
abstract final class OrderStatus {
  static const received = 'Received';
  static const cutting = 'Cutting';
  static const stitching = 'Stitching';
  static const ready = 'Ready';
  static const delivered = 'Delivered';

  /// Stages set while the order is in the shop. Delivery is recorded
  /// separately and ends the order.
  static const production = [received, cutting, stitching, ready];
}
