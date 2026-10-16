import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:tailor_khata/core/providers/clock_provider.dart';
import 'package:tailor_khata/core/theme/design_tokens.dart';
import 'package:tailor_khata/core/widgets/app_widgets.dart';
import 'package:tailor_khata/features/customers/presentation/providers/customers_notifier.dart';
import 'package:tailor_khata/features/measurements/domain/entities/fit_profile.dart';
import 'package:tailor_khata/features/measurements/domain/entities/garment_template.dart';
import 'package:tailor_khata/features/measurements/domain/entities/measurement.dart';
import 'package:tailor_khata/features/measurements/domain/entities/measurement_unit.dart';
import 'package:tailor_khata/features/measurements/presentation/measurement_format.dart';
import 'package:tailor_khata/features/measurements/presentation/providers/measurements_notifier.dart';
import 'package:tailor_khata/features/measurements/presentation/widgets/measurement_editor_sheet.dart';
import 'package:tailor_khata/features/measurements/presentation/widgets/measurement_field_card.dart';
import 'package:tailor_khata/features/settings/presentation/providers/shop_settings_providers.dart';

/// A customer's measurements: one profile per garment and fit. Changes are
/// kept as a draft until "Save Profile".
class MeasurementScreen extends ConsumerStatefulWidget {
  final String customerId;

  /// The profile to open; defaults to the first garment's Formal Fit.
  final String? initialGarment;
  final String? initialFit;

  const MeasurementScreen({
    super.key,
    required this.customerId,
    this.initialGarment,
    this.initialFit,
  });

  @override
  ConsumerState<MeasurementScreen> createState() => _MeasurementScreenState();
}

enum _Unsaved { save, discard }

class _MeasurementScreenState extends ConsumerState<MeasurementScreen> {
  static const _fits = [FitProfile.formal, FitProfile.casual];

  late String _garment =
      widget.initialGarment ?? GarmentTemplates.all.first.name;
  late String _fit = _fits.contains(widget.initialFit)
      ? widget.initialFit!
      : FitProfile.formal;

  /// Draft values in inches by field; null marks a cleared field.
  final Map<String, double?> _edits = {};

  /// Draft stitching note; null while unchanged.
  String? _noteEdit;

  /// Unit picked for a profile that has not been saved yet.
  MeasurementUnit? _unitForNew;
  bool _saving = false;

  List<Measurement> get _customerProfiles => [
    for (final measurement
        in ref.watch(measurementsNotifierProvider).valueOrNull ??
            const <Measurement>[])
      if (measurement.customerId == widget.customerId) measurement,
  ];

  Measurement? _stored(List<Measurement> profiles) {
    for (final profile in profiles) {
      if (profile.garmentType == _garment && profile.fitProfile == _fit) {
        return profile;
      }
    }
    return null;
  }

  static bool _same(double? a, double? b) =>
      a == null || b == null ? a == b : (a - b).abs() < 0.0005;

  /// Fields whose draft value differs from the saved one.
  Set<String> _editedKeys(Measurement? stored) => {
    for (final entry in _edits.entries)
      if (!_same(entry.value, stored?.measurementData[entry.key])) entry.key,
  };

  bool _noteChanged(Measurement? stored) =>
      _noteEdit != null && _noteEdit != (stored?.note ?? '');

  bool _dirty(Measurement? stored) =>
      _editedKeys(stored).isNotEmpty || _noteChanged(stored);

  double? _valueOf(String key, Measurement? stored) =>
      _edits.containsKey(key) ? _edits[key] : stored?.measurementData[key];

  void _clearDraft() {
    _edits.clear();
    _noteEdit = null;
  }

  Future<bool> _save(Measurement? stored, MeasurementUnit unit) async {
    final values = {...?stored?.measurementData};
    _edits.forEach((key, inches) {
      if (inches == null) {
        values.remove(key);
      } else {
        values[key] = inches;
      }
    });
    final note = _noteEdit ?? stored?.note ?? '';
    final now = ref.read(clockProvider)();
    final profile =
        stored?.revise(values: values, note: note, at: now) ??
        Measurement(
          id: const Uuid().v4(),
          customerId: widget.customerId,
          garmentType: _garment,
          fitProfile: _fit,
          measurementData: values,
          unit: unit,
          note: note,
          createdAt: now,
          updatedAt: now,
        );

    setState(() => _saving = true);
    final saved = await ref
        .read(measurementsNotifierProvider.notifier)
        .saveMeasurement(profile);
    if (!mounted) return saved;
    setState(() {
      _saving = false;
      if (saved) _clearDraft();
    });
    if (!saved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Couldn't save the measurements. Please try again."),
        ),
      );
    }
    return saved;
  }

  /// Settles unsaved changes before moving to another profile or screen.
  /// Returns false when the user chose to stay.
  Future<bool> _settleDraft(Measurement? stored, MeasurementUnit unit) async {
    if (!_dirty(stored)) {
      _clearDraft();
      return true;
    }
    final choice = await showDialog<_Unsaved>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save your changes?'),
        content: Text(
          'The changes to $_garment, $_fit have not been saved yet.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep editing'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, _Unsaved.discard),
            child: const Text('Discard'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, _Unsaved.save),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    switch (choice) {
      case _Unsaved.save:
        return _save(stored, unit);
      case _Unsaved.discard:
        setState(_clearDraft);
        return true;
      case null:
        return false;
    }
  }

  Future<void> _switchTo({String? garment, String? fit}) async {
    final profiles = ref.read(measurementsNotifierProvider).valueOrNull ?? [];
    final stored = _stored([
      for (final profile in profiles)
        if (profile.customerId == widget.customerId) profile,
    ]);
    if (!await _settleDraft(stored, _unitOf(stored))) return;
    if (!mounted) return;
    setState(() {
      _garment = garment ?? _garment;
      _fit = fit ?? _fit;
      _unitForNew = null;
    });
  }

  MeasurementUnit _unitOf(Measurement? stored) =>
      stored?.unit ??
      _unitForNew ??
      ref.read(shopSettingsProvider).valueOrNull?.defaultUnit ??
      MeasurementUnit.inches;

  Future<void> _changeUnit(Measurement? stored, MeasurementUnit unit) async {
    if (stored == null) {
      setState(() => _unitForNew = unit);
      return;
    }
    // The unit only changes how values are shown, so it is saved at once
    // without touching the values or the draft.
    await ref
        .read(measurementsNotifierProvider.notifier)
        .saveMeasurement(stored.copyWith(unit: unit));
  }

  Future<void> _editField(
    MeasurementField field,
    Measurement? stored,
    MeasurementUnit unit,
  ) async {
    final current = _valueOf(field.key, stored);
    final saved = stored?.measurementData[field.key];
    // A value edited in this draft can go back to the saved one; otherwise
    // offer what the field held before it was last saved.
    final previous = _edits.containsKey(field.key) && saved != null
        ? PreviousMeasurement(saved, stored!.updatedAt)
        : stored?.previousValues[field.key];
    final edit = await showMeasurementEditor(
      context,
      field: field,
      profileName: '$_garment · $_fit',
      unit: unit,
      inches: current,
      previous: previous,
    );
    if (edit == null || !mounted) return;
    setState(() => _edits[field.key] = edit.inches);
  }

  Future<void> _editNote(Measurement? stored) async {
    final controller = TextEditingController(
      text: _noteEdit ?? stored?.note ?? '',
    );
    final note = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Stitching note'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 4,
          minLines: 2,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText: 'Collar 1 inch wider than standard',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Done'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (note != null && mounted) setState(() => _noteEdit = note);
  }

  @override
  Widget build(BuildContext context) {
    final customer = ref
        .watch(customersNotifierProvider)
        .valueOrNull
        ?.where((c) => c.id == widget.customerId)
        .firstOrNull;
    ref.watch(shopSettingsProvider);
    final profiles = _customerProfiles;
    final stored = _stored(profiles);
    final unit = _unitOf(stored);
    final dirty = _dirty(stored);
    final edited = _editedKeys(stored);
    final template = GarmentTemplates.named(
      _garment,
    ).including({...?stored?.measurementData.keys, ..._edits.keys});
    final garments = <String>{
      for (final template in GarmentTemplates.all) template.name,
      for (final profile in profiles) profile.garmentType,
    }.toList();
    final missingOptional = [
      for (final field in template.fields)
        if (field.optional && _valueOf(field.key, stored) == null) field.label,
    ];

    return PopScope(
      canPop: !dirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (await _settleDraft(stored, unit) && context.mounted) {
          context.pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppPalette.white,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.xs,
                  AppSpacing.screenPadding,
                  0,
                ),
                child: Row(
                  children: [
                    AppBoxedIconButton(
                      icon: Icons.chevron_left,
                      label: 'Back',
                      onPressed: () => Navigator.maybePop(context),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Measurements',
                            style: AppTypography.title.copyWith(
                              fontSize: 18,
                              letterSpacing: 18 * -0.02,
                              color: AppPalette.carbon,
                            ),
                          ),
                          if (customer != null)
                            Text(
                              customer.name,
                              style: AppTypography.support.copyWith(
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                    _UnitToggle(
                      unit: unit,
                      onChanged: (unit) => _changeUnit(stored, unit),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: AppSizing.minHitTarget,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenPadding,
                  ),
                  itemCount: garments.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: AppSpacing.sm),
                  itemBuilder: (context, index) => _GarmentChip(
                    label: garments[index],
                    selected: garments[index] == _garment,
                    onTap: () => _switchTo(garment: garments[index]),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPadding,
                  14,
                  AppSpacing.screenPadding,
                  0,
                ),
                child: _FitToggle(
                  fits: _fits,
                  selected: _fit,
                  onChanged: (fit) => _switchTo(fit: fit),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenPadding,
                    14,
                    AppSpacing.screenPadding,
                    AppSpacing.xl,
                  ),
                  children: [
                    _StatusBanner(
                      stored: stored,
                      fit: _fit,
                      editedCount: edited.length,
                      noteChanged: _noteChanged(stored),
                    ),
                    for (final group in template.groups) ...[
                      const SizedBox(height: 22),
                      _GroupHeader(group.label),
                      const SizedBox(height: 10),
                      _FieldGrid(
                        children: [
                          for (final field in group.fields)
                            MeasurementFieldCard(
                              label: field.label,
                              value: switch (_valueOf(field.key, stored)) {
                                null => null,
                                final inches => formatMeasurement(inches, unit),
                              },
                              unit: unit.code,
                              edited: edited.contains(field.key),
                              onTap: () => _editField(field, stored, unit),
                            ),
                        ],
                      ),
                    ],
                    if (missingOptional.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.lg),
                      _InfoNote(
                        '${_listOf(missingOptional)} '
                        '${missingOptional.length == 1 ? 'is' : 'are'} '
                        'optional — the order can still be saved.',
                      ),
                    ],
                    const SizedBox(height: 18),
                    _NoteCard(
                      note: _noteEdit ?? stored?.note ?? '',
                      edited: _noteChanged(stored),
                      onTap: () => _editNote(stored),
                    ),
                  ],
                ),
              ),
              if (dirty)
                DecoratedBox(
                  decoration: const BoxDecoration(
                    color: AppPalette.white,
                    border: Border(top: BorderSide(color: AppPalette.line)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screenPadding,
                      14,
                      AppSpacing.screenPadding,
                      14,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: AppButton(
                            label: 'Discard',
                            variant: AppButtonVariant.outlined,
                            onPressed: _saving
                                ? null
                                : () => setState(_clearDraft),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 3,
                          child: AppButton(
                            label: _saving ? 'Saving' : 'Save Profile',
                            isLoading: _saving,
                            onPressed: () => _save(stored, unit),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  static String _listOf(List<String> items) => items.length == 1
      ? items.single
      : '${items.sublist(0, items.length - 1).join(', ')} and ${items.last}';
}

class _UnitToggle extends StatelessWidget {
  const _UnitToggle({required this.unit, required this.onChanged});
  final MeasurementUnit unit;
  final ValueChanged<MeasurementUnit> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(3),
    decoration: BoxDecoration(
      color: AppPalette.surfaceControl,
      borderRadius: BorderRadius.circular(11),
      border: Border.all(color: AppPalette.line),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final option in MeasurementUnit.values)
          Semantics(
            selected: option == unit,
            button: true,
            label: option == MeasurementUnit.inches ? 'Inches' : 'Centimeters',
            excludeSemantics: true,
            child: Material(
              color: option == unit ? AppPalette.carbon : Colors.transparent,
              borderRadius: BorderRadius.circular(9),
              child: InkWell(
                borderRadius: BorderRadius.circular(9),
                onTap: () => onChanged(option),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                  child: Center(
                    child: Text(
                      option.code,
                      style: AppTypography.support.copyWith(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: option == unit
                            ? AppPalette.white
                            : AppPalette.ink55,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

class _GarmentChip extends StatelessWidget {
  const _GarmentChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadii.control),
      side: selected
          ? BorderSide.none
          : const BorderSide(color: AppPalette.lineStrong),
    );
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? AppPalette.carbon : AppPalette.white,
        shape: shape,
        child: InkWell(
          onTap: onTap,
          customBorder: shape,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Center(
              widthFactor: 1,
              child: Text(
                label,
                style: AppTypography.support.copyWith(
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected ? AppPalette.white : AppPalette.carbon,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FitToggle extends StatelessWidget {
  const _FitToggle({
    required this.fits,
    required this.selected,
    required this.onChanged,
  });

  final List<String> fits;
  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.xs),
    decoration: BoxDecoration(
      color: AppPalette.surfaceControl,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppPalette.line),
    ),
    child: Row(
      children: [
        for (final fit in fits)
          Expanded(
            child: Semantics(
              selected: fit == selected,
              button: true,
              // The shadow sits behind the segment so it cannot tint it.
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: fit == selected ? AppShadows.selection : null,
                ),
                child: Material(
                  color: fit == selected
                      ? AppPalette.white
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(11),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(11),
                    onTap: () => onChanged(fit),
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 44),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (fit == selected) ...[
                            const Icon(
                              Icons.circle,
                              size: 7,
                              color: AppPalette.greyOlive,
                            ),
                            const SizedBox(width: 7),
                          ],
                          Flexible(
                            child: Text(
                              fit,
                              style: AppTypography.body.copyWith(
                                fontSize: 13.5,
                                fontWeight: fit == selected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: fit == selected
                                    ? AppPalette.carbon
                                    : AppPalette.ink55,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.stored,
    required this.fit,
    required this.editedCount,
    required this.noteChanged,
  });

  final Measurement? stored;
  final String fit;
  final int editedCount;
  final bool noteChanged;

  @override
  Widget build(BuildContext context) {
    final dirty = editedCount > 0 || noteChanged;
    final IconData icon;
    final String title;
    final String? detail;
    if (dirty) {
      icon = Icons.schedule;
      title = 'Unsaved changes';
      detail = [
        if (editedCount > 0)
          '$editedCount ${editedCount == 1 ? 'field' : 'fields'} edited',
        if (noteChanged) 'note edited',
      ].join(' · ');
    } else if (stored != null) {
      icon = Icons.check;
      title = 'Saved';
      detail =
          'Updated ${DateFormat('d MMM, h:mm a').format(stored!.updatedAt)}';
    } else {
      icon = Icons.info_outline;
      title = 'Nothing saved for $fit yet';
      detail = null;
    }
    final ink = dirty ? AppPalette.carbon : AppPalette.oliveInk;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: dirty
            ? AppPalette.white
            : stored != null
            ? AppPalette.oliveFill14
            : AppPalette.surfaceSunken,
        borderRadius: BorderRadius.circular(AppRadii.control),
        border: Border.all(
          color: dirty
              ? AppPalette.carbon
              : stored != null
              ? AppPalette.oliveBorder
              : AppPalette.line,
          width: dirty ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: ink),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  if (detail != null)
                    TextSpan(
                      text: ' · $detail',
                      style: TextStyle(
                        color: dirty ? AppPalette.ink70 : AppPalette.oliveInk,
                      ),
                    ),
                ],
              ),
              style: AppTypography.support.copyWith(
                fontSize: 12.5,
                fontFeatures: AppTypography.tabularFigures,
                color: ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(
        label.toUpperCase(),
        style: AppTypography.sectionLabel.copyWith(
          fontSize: 10.5,
          letterSpacing: 10.5 * 0.11,
          color: AppPalette.ink55,
        ),
      ),
      const SizedBox(width: 10),
      const Expanded(
        child: SizedBox(
          height: 7,
          child: AppTickPattern(color: AppPalette.lineStrong, spacing: 7),
        ),
      ),
    ],
  );
}

/// Two cards per row; a card's height follows its text.
class _FieldGrid extends StatelessWidget {
  const _FieldGrid({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      const gap = 10.0;
      final width = (constraints.maxWidth - gap) / 2;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final child in children) SizedBox(width: width, child: child),
        ],
      );
    },
  );
}

class _InfoNote extends StatelessWidget {
  const _InfoNote(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
    decoration: BoxDecoration(
      color: AppPalette.surfaceSunken,
      borderRadius: BorderRadius.circular(AppRadii.control),
      border: Border.all(color: AppPalette.line),
    ),
    child: Row(
      children: [
        const Icon(Icons.info_outline, size: 16, color: AppPalette.ink55),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            text,
            style: AppTypography.support.copyWith(fontSize: 12, height: 1.4),
          ),
        ),
      ],
    ),
  );
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({
    required this.note,
    required this.edited,
    required this.onTap,
  });

  final String note;
  final bool edited;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadii.control),
      side: edited
          ? const BorderSide(color: AppPalette.carbon, width: 1.5)
          : const BorderSide(color: AppPalette.line),
    );
    return Material(
      color: AppPalette.surfaceSunken,
      shape: shape,
      child: InkWell(
        onTap: onTap,
        customBorder: shape,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'STITCHING NOTE',
                style: AppTypography.micro.copyWith(
                  fontSize: 10.5,
                  letterSpacing: 10.5 * 0.07,
                  color: AppPalette.ink55,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                note.isEmpty ? 'Add a note for the cutter' : note,
                style: AppTypography.support.copyWith(
                  height: 1.45,
                  color: note.isEmpty ? AppPalette.ink45 : AppPalette.carbon,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
