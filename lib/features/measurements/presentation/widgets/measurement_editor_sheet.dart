import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tailor_khata/core/theme/design_tokens.dart';
import 'package:tailor_khata/core/widgets/app_widgets.dart';
import 'package:tailor_khata/features/measurements/domain/entities/garment_template.dart';
import 'package:tailor_khata/features/measurements/domain/entities/measurement.dart';
import 'package:tailor_khata/features/measurements/domain/entities/measurement_unit.dart';
import 'package:tailor_khata/features/measurements/presentation/measurement_format.dart';

/// The outcome of editing one field: its new value in inches, or null when
/// the field was cleared.
typedef MeasurementEdit = ({double? inches});

/// Opens the editor for [field]. Resolves to the edit, or to null when the
/// sheet is closed or the value was left as it was.
Future<MeasurementEdit?> showMeasurementEditor(
  BuildContext context, {
  required MeasurementField field,
  required String profileName,
  required MeasurementUnit unit,
  required double? inches,
  required PreviousMeasurement? previous,
}) {
  return showModalBottomSheet<MeasurementEdit>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    sheetAnimationStyle: AnimationStyle(
      duration: AppMotion.sheet,
      curve: AppMotion.curve,
    ),
    builder: (context) => MeasurementEditorSheet(
      field: field,
      profileName: profileName,
      unit: unit,
      inches: inches,
      previous: previous,
    ),
  );
}

class MeasurementEditorSheet extends StatefulWidget {
  const MeasurementEditorSheet({
    super.key,
    required this.field,
    required this.profileName,
    required this.unit,
    required this.inches,
    required this.previous,
  });

  final MeasurementField field;

  /// Garment and fit, such as "Shalwar Kameez · Formal Fit".
  final String profileName;
  final MeasurementUnit unit;
  final double? inches;
  final PreviousMeasurement? previous;

  @override
  State<MeasurementEditorSheet> createState() => _MeasurementEditorSheetState();
}

class _MeasurementEditorSheetState extends State<MeasurementEditorSheet> {
  /// Largest value accepted, well above any garment measurement.
  static const _maxInches = 150.0;
  static const _maxWholeDigits = 3;

  late final String _initial = widget.inches == null
      ? ''
      : formatMeasurement(widget.inches!, widget.unit);
  late String _text = _initial;
  Timer? _repeat;

  bool get _metric => widget.unit == MeasurementUnit.centimeters;

  /// Stepper increment in the shown unit: a quarter inch or half a centimeter.
  double get _step => _metric ? 0.5 : 0.25;

  /// Inches allow quarter values; centimeters one decimal.
  int get _maxDecimals => _metric ? 1 : 2;

  List<(double, String)> get _shortcuts => _metric
      ? const [(-1, '− 1'), (-0.5, '− 0.5'), (0.5, '+ 0.5'), (1, '+ 1')]
      : const [
          (-0.5, '− 1/2'),
          (-0.25, '− 1/4'),
          (0.25, '+ 1/4'),
          (0.5, '+ 1/2'),
        ];

  double? get _value => double.tryParse(_text);

  bool get _valid {
    if (_text.isEmpty) return true;
    final value = _value;
    return value != null &&
        value > 0 &&
        widget.unit.toInches(value) <= _maxInches;
  }

  @override
  void dispose() {
    _repeat?.cancel();
    super.dispose();
  }

  void _show(double value) {
    setState(
      () => _text = formatMeasurement(widget.unit.toInches(value), widget.unit),
    );
  }

  void _add(double delta) {
    final next = math.max(0.0, (_value ?? 0) + delta);
    // Snap to the step so repeated presses stay on round values.
    _show((next / _step).round() * _step);
  }

  void _startRepeat(double delta) {
    _repeat?.cancel();
    _repeat = Timer.periodic(
      const Duration(milliseconds: 110),
      (_) => _add(delta),
    );
  }

  void _stopRepeat() {
    _repeat?.cancel();
    _repeat = null;
  }

  void _type(String key) {
    final next = key == '⌫'
        ? (_text.isEmpty ? '' : _text.substring(0, _text.length - 1))
        : _text + key;
    final parts = next.split('.');
    final acceptable =
        parts.length <= 2 &&
        parts.first.length <= _maxWholeDigits &&
        (parts.length == 1 || parts[1].length <= _maxDecimals);
    if (acceptable) setState(() => _text = next);
  }

  void _done() {
    if (_text == _initial) {
      Navigator.pop(context);
      return;
    }
    final value = _value;
    Navigator.pop<MeasurementEdit>(context, (
      inches: value == null ? null : widget.unit.toInches(value),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final previous = widget.previous;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenPadding,
          0,
          AppSpacing.screenPadding,
          AppSpacing.xl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.field.label,
                        style: AppTypography.title.copyWith(
                          fontSize: 17,
                          letterSpacing: 17 * -0.015,
                          color: AppPalette.carbon,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.profileName,
                        style: AppTypography.support.copyWith(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.pop(context),
                  style: IconButton.styleFrom(
                    backgroundColor: AppPalette.surfaceControl,
                  ),
                  icon: const Icon(Icons.close, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _StepButton(
                  icon: Icons.remove,
                  label: 'Decrease',
                  filled: false,
                  onTap: () => _add(-_step),
                  onHoldStart: () => _startRepeat(-_step),
                  onHoldEnd: _stopRepeat,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _ValueBox(text: _text, unit: widget.unit),
                ),
                const SizedBox(width: AppSpacing.md),
                _StepButton(
                  icon: Icons.add,
                  label: 'Increase',
                  filled: true,
                  onTap: () => _add(_step),
                  onHoldStart: () => _startRepeat(_step),
                  onHoldEnd: _stopRepeat,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                for (final (index, (delta, label)) in _shortcuts.indexed) ...[
                  if (index > 0) const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _add(delta),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        textStyle: AppTypography.support.copyWith(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          fontFeatures: AppTypography.tabularFigures,
                        ),
                      ),
                      child: Text(label),
                    ),
                  ),
                ],
              ],
            ),
            if (previous != null) ...[
              const SizedBox(height: 14),
              _PreviousValue(
                previous: previous,
                unit: widget.unit,
                onUse: () => setState(
                  () => _text = formatMeasurement(previous.value, widget.unit),
                ),
              ),
            ],
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Cancel',
                    variant: AppButtonVariant.outlined,
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 3,
                  child: AppButton(
                    label: _text.isEmpty && _initial.isNotEmpty
                        ? 'Clear ${widget.field.label}'
                        : 'Update ${widget.field.label}',
                    onPressed: _valid ? _done : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _Keypad(onKey: _type),
          ],
        ),
      ),
    );
  }
}

class _ValueBox extends StatelessWidget {
  const _ValueBox({required this.text, required this.unit});
  final String text;
  final MeasurementUnit unit;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    label: text.isEmpty ? 'No value' : '$text ${unit.code}',
    excludeSemantics: true,
    child: Container(
      constraints: const BoxConstraints(minHeight: 72),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppPalette.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppPalette.carbon, width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              text.isEmpty ? '—' : text,
              maxLines: 1,
              overflow: TextOverflow.fade,
              softWrap: false,
              style: AppTypography.numberLg.copyWith(
                fontSize: 34,
                letterSpacing: 34 * -0.03,
                color: text.isEmpty ? AppPalette.ink45 : AppPalette.carbon,
              ),
            ),
          ),
          Container(
            width: 2,
            height: 30,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            color: AppPalette.carbon,
          ),
          Text(
            unit.code,
            style: AppTypography.body.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppPalette.ink55,
            ),
          ),
        ],
      ),
    ),
  );
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.label,
    required this.filled,
    required this.onTap,
    required this.onHoldStart,
    required this.onHoldEnd,
  });

  final IconData icon;
  final String label;
  final bool filled;
  final VoidCallback onTap;
  final VoidCallback onHoldStart;
  final VoidCallback onHoldEnd;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: filled
          ? BorderSide.none
          : const BorderSide(color: AppPalette.lineStrong, width: 1.5),
    );
    // Holding repeats the step until released.
    return GestureDetector(
      onLongPressStart: (_) => onHoldStart(),
      onLongPressEnd: (_) => onHoldEnd(),
      onLongPressCancel: onHoldEnd,
      child: Material(
        color: filled ? AppPalette.carbon : AppPalette.white,
        shape: shape,
        child: InkWell(
          onTap: onTap,
          customBorder: shape,
          child: Tooltip(
            message: label,
            child: SizedBox.square(
              dimension: 56,
              child: Icon(
                icon,
                color: filled ? AppPalette.white : AppPalette.carbon,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PreviousValue extends StatelessWidget {
  const _PreviousValue({
    required this.previous,
    required this.unit,
    required this.onUse,
  });

  final PreviousMeasurement previous;
  final MeasurementUnit unit;
  final VoidCallback onUse;

  @override
  Widget build(BuildContext context) {
    final ink = AppTypography.support.copyWith(
      fontSize: 12.5,
      fontWeight: FontWeight.w600,
      fontFeatures: AppTypography.tabularFigures,
      color: AppPalette.oliveInk,
    );
    return Container(
      padding: const EdgeInsets.only(left: 13),
      decoration: BoxDecoration(
        color: AppPalette.oliveFill14,
        borderRadius: BorderRadius.circular(AppRadii.control),
        border: Border.all(color: AppPalette.oliveBorder),
      ),
      child: Row(
        children: [
          Text(
            'PREVIOUS',
            style: AppTypography.micro.copyWith(
              letterSpacing: 11 * 0.06,
              color: AppPalette.oliveInk,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              '${formatMeasurement(previous.value, unit)} ${unit.code} · '
              '${DateFormat('d MMM').format(previous.recordedAt)}',
              style: ink,
            ),
          ),
          TextButton(
            onPressed: onUse,
            style: TextButton.styleFrom(
              foregroundColor: AppPalette.oliveInk,
              textStyle: ink,
            ),
            child: const Text('Use'),
          ),
        ],
      ),
    );
  }
}

class _Keypad extends StatelessWidget {
  const _Keypad({required this.onKey});
  final ValueChanged<String> onKey;

  static const _keys = [
    '1', '2', '3', //
    '4', '5', '6',
    '7', '8', '9',
    '.', '0', '⌫',
  ];

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      const gap = AppSpacing.sm;
      final width = (constraints.maxWidth - 2 * gap) / 3;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final key in _keys)
            SizedBox(
              width: width,
              child: _Key(label: key, onTap: () => onKey(key)),
            ),
        ],
      );
    },
  );
}

class _Key extends StatelessWidget {
  const _Key({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final backspace = label == '⌫';
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
      side: backspace
          ? BorderSide.none
          : const BorderSide(color: AppPalette.line),
    );
    return Material(
      color: backspace ? AppPalette.surfaceControl : AppPalette.white,
      shape: shape,
      child: InkWell(
        onTap: onTap,
        customBorder: shape,
        child: SizedBox(
          height: 46,
          child: Center(
            child: backspace
                ? const Icon(
                    Icons.backspace_outlined,
                    size: 20,
                    semanticLabel: 'Delete',
                  )
                : Text(
                    label,
                    style: AppTypography.body.copyWith(
                      fontSize: 20,
                      fontFeatures: AppTypography.tabularFigures,
                      color: AppPalette.carbon,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
