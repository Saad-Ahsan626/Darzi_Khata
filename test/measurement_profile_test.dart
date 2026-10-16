import 'package:flutter_test/flutter_test.dart';
import 'package:tailor_khata/features/measurements/domain/entities/garment_template.dart';
import 'package:tailor_khata/features/measurements/domain/entities/measurement.dart';
import 'package:tailor_khata/features/measurements/domain/entities/measurement_unit.dart';
import 'package:tailor_khata/features/measurements/presentation/measurement_format.dart';

final _august = DateTime(2026, 8, 2);
final _september = DateTime(2026, 9, 18);
final _october = DateTime(2026, 10, 4);

Measurement _profile({
  Map<String, double> values = const {'chest': 40.5, 'waist': 36},
  Map<String, PreviousMeasurement> previous = const {},
}) => Measurement(
  id: 'formal',
  customerId: 'faisal',
  garmentType: 'Shalwar Kameez',
  measurementData: values,
  previousValues: previous,
  note: 'Collar 1 inch wider',
  createdAt: _august,
  updatedAt: _september,
);

void main() {
  group('saving a revised profile', () {
    test('a changed field keeps its old value and when it was saved', () {
      final revised = _profile().revise(
        values: const {'chest': 41, 'waist': 36},
        note: 'Collar 1 inch wider',
        at: _october,
      );
      expect(revised.measurementData, {'chest': 41.0, 'waist': 36.0});
      expect(revised.previousValues, {
        'chest': PreviousMeasurement(40.5, _september),
      });
      expect(revised.updatedAt, _october);
      expect(revised.createdAt, _august);
    });

    test('a cleared field keeps its old value too', () {
      final revised = _profile().revise(
        values: const {'chest': 40.5},
        note: '',
        at: _october,
      );
      expect(revised.measurementData, {'chest': 40.5});
      expect(revised.previousValues['waist'], PreviousMeasurement(36, _september));
      expect(revised.note, '');
    });

    test('earlier previous values stay until their field changes again', () {
      final profile = _profile(
        previous: {
          'chest': PreviousMeasurement(39.5, _august),
          'waist': PreviousMeasurement(35, _august),
        },
      );
      final revised = profile.revise(
        values: const {'chest': 41, 'waist': 36},
        note: null,
        at: _october,
      );
      expect(revised.previousValues, {
        'chest': PreviousMeasurement(40.5, _september),
        'waist': PreviousMeasurement(35, _august),
      });
      // A null note leaves the saved note as it was.
      expect(revised.note, 'Collar 1 inch wider');
    });

    test('new fields have no previous value', () {
      final revised = _profile().revise(
        values: const {'chest': 40.5, 'waist': 36, 'neck': 15.5},
        note: null,
        at: _october,
      );
      expect(revised.previousValues, isEmpty);
    });
  });

  group('garment field sets', () {
    test('seven garments are offered, in order', () {
      expect([for (final garment in GarmentTemplates.all) garment.name], [
        'Shalwar Kameez',
        'Kurta',
        'Waistcoat',
        'Suit',
        'Trousers',
        'Shalwar',
        'Sherwani',
      ]);
    });

    test('no garment uses the same field twice', () {
      for (final garment in GarmentTemplates.all) {
        final keys = [for (final field in garment.fields) field.key];
        expect(keys.toSet(), hasLength(keys.length), reason: garment.name);
      }
    });

    test('values saved by earlier versions keep their fields', () {
      for (final garment in ['Shalwar Kameez', 'Kurta', 'Sherwani']) {
        final template = GarmentTemplates.named(garment);
        for (final key in ['neck', 'chest', 'waist', 'hip', 'length']) {
          expect(template.field(key), isNotNull, reason: '$garment $key');
        }
      }
    });

    test('stored values outside the field set appear under Other', () {
      final template = GarmentTemplates.named(
        'Waistcoat',
      ).including(['chest', 'neck', 'shalwarLength']);
      final other = template.groups.last;
      expect(other.label, 'Other');
      expect([for (final field in other.fields) field.label], [
        'Neck',
        'Shalwar length',
      ]);
    });

    test('an unknown garment shows all its values under Other', () {
      final template = GarmentTemplates.named('Achkan').including(['chest']);
      expect(template.name, 'Achkan');
      expect(template.groups.single.label, 'Other');
    });
  });

  test('values are shown in quarter inches or tenths of a centimeter', () {
    expect(formatMeasurement(40.5, MeasurementUnit.inches), '40.5');
    expect(formatMeasurement(36, MeasurementUnit.inches), '36.0');
    expect(formatMeasurement(40.25, MeasurementUnit.inches), '40.25');
    expect(formatMeasurement(40.75, MeasurementUnit.inches), '40.75');
    expect(formatMeasurement(36, MeasurementUnit.centimeters), '91.4');
    expect(formatMeasurement(92 / 2.54, MeasurementUnit.centimeters), '92.0');
  });
}
