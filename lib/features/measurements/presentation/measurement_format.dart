import 'package:tailor_khata/features/measurements/domain/entities/measurement_unit.dart';

/// A stored value in inches, shown in [unit]. Inches keep quarter steps
/// (`40.25`) and otherwise one decimal (`40.5`, `36.0`); centimeters always
/// show one decimal (`91.4`).
String formatMeasurement(double inches, MeasurementUnit unit) {
  final value = unit.fromInches(inches);
  if (unit == MeasurementUnit.centimeters) return value.toStringAsFixed(1);
  final hundredths = (value * 100).round();
  return (hundredths / 100).toStringAsFixed(hundredths % 10 == 0 ? 1 : 2);
}
