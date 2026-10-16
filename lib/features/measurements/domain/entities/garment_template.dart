/// One measurement a garment needs, stored under [key] in inches.
class MeasurementField {
  const MeasurementField(this.key, this.label, {this.optional = false});

  final String key;
  final String label;

  /// The profile is complete without it.
  final bool optional;
}

/// Fields shown together under one heading, such as "Upper body".
class MeasurementGroup {
  const MeasurementGroup(this.label, this.fields);

  final String label;
  final List<MeasurementField> fields;
}

/// The fields a garment is measured by.
class GarmentTemplate {
  const GarmentTemplate(this.name, this.groups);

  final String name;
  final List<MeasurementGroup> groups;

  Iterable<MeasurementField> get fields =>
      groups.expand((group) => group.fields);

  MeasurementField? field(String key) {
    for (final field in fields) {
      if (field.key == key) return field;
    }
    return null;
  }

  /// This template plus an "Other" group for stored [keys] it does not know,
  /// so values saved under an older or different field set stay visible.
  GarmentTemplate including(Iterable<String> keys) {
    final known = {for (final field in fields) field.key};
    final unknown = [
      for (final key in keys)
        if (!known.contains(key)) MeasurementField(key, _labelFor(key)),
    ];
    if (unknown.isEmpty) return this;
    return GarmentTemplate(name, [
      ...groups,
      MeasurementGroup('Other', unknown),
    ]);
  }

  /// `shalwarLength` reads as "Shalwar length".
  static String _labelFor(String key) {
    final words = key.replaceAllMapped(
      RegExp(r'[A-Z]'),
      (match) => ' ${match[0]!.toLowerCase()}',
    );
    return words.isEmpty ? key : words[0].toUpperCase() + words.substring(1);
  }
}

/// The garments a shop measures for, in the order they are offered.
///
/// Keys are shared across garments where the measurement is the same, and
/// the keys `neck`, `chest`, `waist`, `hip` and `length` match values saved
/// by earlier versions of the app.
abstract final class GarmentTemplates {
  static const _neck = MeasurementField('neck', 'Neck');
  static const _shoulder = MeasurementField('shoulder', 'Shoulder');
  static const _chest = MeasurementField('chest', 'Chest');
  static const _waist = MeasurementField('waist', 'Waist');
  static const _hip = MeasurementField('hip', 'Hip');
  static const _sleeve = MeasurementField('sleeve', 'Sleeve');
  static const _armhole = MeasurementField('armhole', 'Armhole');
  static const _cuff = MeasurementField('cuff', 'Cuff');
  static const _rise = MeasurementField('rise', 'Rise');
  static const _inseam = MeasurementField('inseam', 'Inseam');
  static const _bottom = MeasurementField(
    'bottom',
    'Bottom opening',
    optional: true,
  );

  static const _upperBody = MeasurementGroup('Upper body', [
    _neck,
    _shoulder,
    _chest,
    _waist,
    _hip,
  ]);

  static const shalwarKameez = GarmentTemplate('Shalwar Kameez', [
    _upperBody,
    MeasurementGroup('Sleeve & length', [
      _sleeve,
      _armhole,
      _cuff,
      MeasurementField('length', 'Kameez length'),
    ]),
    MeasurementGroup('Shalwar', [
      MeasurementField('shalwarLength', 'Shalwar length'),
      _bottom,
    ]),
  ]);

  static const kurta = GarmentTemplate('Kurta', [
    _upperBody,
    MeasurementGroup('Sleeve & length', [
      _sleeve,
      _armhole,
      _cuff,
      MeasurementField('length', 'Kurta length'),
    ]),
  ]);

  static const waistcoat = GarmentTemplate('Waistcoat', [
    MeasurementGroup('Waistcoat', [
      _shoulder,
      _chest,
      _waist,
      _hip,
      MeasurementField('length', 'Length'),
    ]),
  ]);

  static const suit = GarmentTemplate('Suit', [
    MeasurementGroup('Coat', [
      _shoulder,
      _chest,
      _waist,
      _hip,
      _sleeve,
      MeasurementField('length', 'Coat length'),
    ]),
    MeasurementGroup('Trouser', [
      MeasurementField('trouserWaist', 'Waist'),
      MeasurementField('trouserHip', 'Hip'),
      _rise,
      _inseam,
      _bottom,
    ]),
  ]);

  static const trousers = GarmentTemplate('Trousers', [
    MeasurementGroup('Trouser', [_waist, _hip, _rise, _inseam, _bottom]),
  ]);

  static const shalwar = GarmentTemplate('Shalwar', [
    MeasurementGroup('Shalwar', [
      MeasurementField('length', 'Length'),
      _hip,
      _bottom,
    ]),
  ]);

  static const sherwani = GarmentTemplate('Sherwani', [
    _upperBody,
    MeasurementGroup('Sleeve & length', [
      _sleeve,
      _armhole,
      MeasurementField('length', 'Sherwani length'),
    ]),
  ]);

  static const all = [
    shalwarKameez,
    kurta,
    waistcoat,
    suit,
    trousers,
    shalwar,
    sherwani,
  ];

  /// The template for [garment]. A garment the catalogue does not know gets
  /// an empty template, so its stored values all appear under "Other".
  static GarmentTemplate named(String garment) {
    for (final template in all) {
      if (template.name == garment) return template;
    }
    return GarmentTemplate(garment, const []);
  }
}
