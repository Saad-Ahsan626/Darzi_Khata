/// Units a measurement can be shown and entered in. Values are always stored
/// in inches.
enum MeasurementUnit {
  inches('in'),
  centimeters('cm');

  const MeasurementUnit(this.code);

  /// Short label, also the stored value.
  final String code;

  static const _centimetersPerInch = 2.54;

  static MeasurementUnit fromCode(String code) =>
      values.firstWhere((unit) => unit.code == code);

  /// Converts a stored value in inches to this unit.
  double fromInches(double value) =>
      this == centimeters ? value * _centimetersPerInch : value;

  /// Converts a value entered in this unit to inches for storage.
  double toInches(double value) =>
      this == centimeters ? value / _centimetersPerInch : value;
}
