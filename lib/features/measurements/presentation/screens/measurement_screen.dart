import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_cube/flutter_cube.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:tailor_khata/core/theme/design_tokens.dart';
import 'package:tailor_khata/core/widgets/app_widgets.dart';
import 'package:tailor_khata/features/measurements/domain/entities/fit_profile.dart';
import 'package:tailor_khata/features/measurements/domain/entities/measurement.dart';
import 'package:tailor_khata/features/measurements/domain/entities/measurement_unit.dart';
import 'package:tailor_khata/features/measurements/presentation/providers/measurements_notifier.dart';
import 'package:tailor_khata/features/measurements/presentation/widgets/measurement_chip.dart';
import 'package:tailor_khata/features/customers/presentation/providers/customers_notifier.dart';

class MeasurementScreen extends ConsumerStatefulWidget {
  final String customerId;

  const MeasurementScreen({super.key, required this.customerId});

  @override
  ConsumerState<MeasurementScreen> createState() => _MeasurementScreenState();
}

class _MeasurementScreenState extends ConsumerState<MeasurementScreen> {
  Object? _model;
  String _activeGarment = 'Shalwar Kameez';
  String _fitType = FitProfile.formal;

  final List<String> _garments = [
    'Shalwar Kameez',
    'Kurta',
    'Pant-Coat',
    'Sherwani',
    'Waistcoat',
  ];

  @override
  void initState() {
    super.initState();
  }

  void _onSceneCreated(Scene scene) {
    scene.camera.position.z = 15;
    _model = Object(
      fileName: 'assets/human_model/basic_human_male.obj',
      scale: Vector3(21.0, 21.0, 21.0),
      position: Vector3(0, -6.0, 0),
    );
    scene.world.add(_model!);
  }

  Measurement? _getMeasurement(List<Measurement> measurements) {
    try {
      return measurements.firstWhere(
        (m) =>
            m.customerId == widget.customerId &&
            m.garmentType == _activeGarment &&
            m.fitProfile == _fitType,
      );
    } catch (_) {
      return null;
    }
  }

  String? _display(double? inches) => inches == null ? null : '$inches"';

  void _openBottomEditor(String key, String labelEn, double? currentValue) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _MeasurementEditorSheet(
        labelEn: labelEn,
        initialValue: currentValue,
        onSave: (val) {
          _saveMeasurement(key, val);
          Navigator.pop(context);
        },
      ),
    );
  }

  /// Saves [inches] for [key] in the active profile; null clears the field.
  void _saveMeasurement(String key, double? inches) {
    final measurementsAsync = ref.read(measurementsNotifierProvider);
    final measurements = measurementsAsync.value ?? [];
    Measurement? current = _getMeasurement(measurements);

    final data = <String, double>{...?current?.measurementData};
    if (inches == null) {
      data.remove(key);
    } else {
      data[key] = inches;
    }

    final now = DateTime.now();
    final newMeasurement = Measurement(
      id: current?.id ?? const Uuid().v4(),
      customerId: widget.customerId,
      garmentType: _activeGarment,
      fitProfile: _fitType,
      measurementData: data,
      unit: current?.unit ?? MeasurementUnit.inches,
      note: current?.note,
      createdAt: current?.createdAt ?? now,
      updatedAt: now,
    );

    ref
        .read(measurementsNotifierProvider.notifier)
        .saveMeasurement(newMeasurement);
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customersNotifierProvider);
    final measurementsAsync = ref.watch(measurementsNotifierProvider);

    final customerName =
        customersAsync.value
            ?.firstWhere((c) => c.id == widget.customerId)
            .name ??
        'Customer';
    final measurement = measurementsAsync.value != null
        ? _getMeasurement(measurementsAsync.value!)
        : null;
    final data = measurement?.measurementData ?? const <String, double>{};

    return Scaffold(
      backgroundColor: AppPalette.white,
      appBar: AppBar(
        backgroundColor: AppPalette.carbon,
        elevation: 0,
        leading: IconButton(
          icon: const Row(
            children: [Icon(Icons.chevron_left, color: AppPalette.white)],
          ),
          onPressed: () => context.pop(),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Measurements',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 12,
                    color: AppPalette.onCarbonMuted,
                  ),
                ),
                Text(
                  customerName,
                  style: const TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 20,
                    color: AppPalette.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPadding,
              vertical: AppSpacing.md,
            ),
            child: AppSegmentedControl<String>(
              selected: _fitType,
              onChanged: (fit) => setState(() => _fitType = fit),
              options: const [
                AppSelectionOption(
                  value: FitProfile.formal,
                  label: 'Formal fit',
                ),
                AppSelectionOption(
                  value: FitProfile.casual,
                  label: 'Casual fit',
                ),
              ],
            ),
          ),
          // Garment Chips
          Container(
            height: 60,
            decoration: const BoxDecoration(
              color: AppPalette.white,
              border: Border(bottom: BorderSide(color: AppPalette.lineStrong)),
            ),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _garments.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final garment = _garments[index];
                final isActive = garment == _activeGarment;
                return GestureDetector(
                  onTap: () => setState(() => _activeGarment = garment),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isActive ? AppPalette.carbon : AppPalette.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isActive
                            ? AppPalette.carbon
                            : AppPalette.lineStrong,
                      ),
                    ),
                    child: Text(
                      garment,
                      style: TextStyle(
                        color: isActive ? AppPalette.white : AppPalette.carbon,
                        fontFamily: AppTypography.fontFamily,
                        fontWeight: isActive
                            ? FontWeight.w600
                            : FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // 3D Canvas
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final height = constraints.maxHeight;
                final width = constraints.maxWidth;
                return Stack(
                  children: [
                    // 3D Viewer
                    Cube(interactive: false, onSceneCreated: _onSceneCreated),

                    // Floating Chips Overlay (Front View Layout)
                    Positioned(
                      top: height * 0.15,
                      left: width * 0.2,
                      child: MeasurementChip(
                        labelEn: 'Neck',
                        value: _display(data['neck']),
                        onTap: () =>
                            _openBottomEditor('neck', 'Neck', data['neck']),
                      ),
                    ),
                    Positioned(
                      top: height * 0.32,
                      right: width * 0.12,
                      child: MeasurementChip(
                        labelEn: 'Chest',
                        value: _display(data['chest']),
                        onTap: () =>
                            _openBottomEditor('chest', 'Chest', data['chest']),
                      ),
                    ),
                    Positioned(
                      top: height * 0.40,
                      left: width * 0.12,
                      child: MeasurementChip(
                        labelEn: 'Waist',
                        value: _display(data['waist']),
                        onTap: () =>
                            _openBottomEditor('waist', 'Waist', data['waist']),
                      ),
                    ),
                    Positioned(
                      top: height * 0.55,
                      right: width * 0.12,
                      child: MeasurementChip(
                        labelEn: 'Hip',
                        value: _display(data['hip']),
                        onTap: () =>
                            _openBottomEditor('hip', 'Hip', data['hip']),
                      ),
                    ),
                    Positioned(
                      top: height * 0.70,
                      left: width * 0.1,
                      child: MeasurementChip(
                        labelEn: 'Length',
                        value: _display(data['length']),
                        onTap: () => _openBottomEditor(
                          'length',
                          'Length',
                          data['length'],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MeasurementEditorSheet extends StatefulWidget {
  final String labelEn;
  final double? initialValue;
  final ValueChanged<double?> onSave;

  const _MeasurementEditorSheet({
    required this.labelEn,
    this.initialValue,
    required this.onSave,
  });

  @override
  State<_MeasurementEditorSheet> createState() =>
      _MeasurementEditorSheetState();
}

class _MeasurementEditorSheetState extends State<_MeasurementEditorSheet> {
  late double _value;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue ?? 30.0;
    _controller = TextEditingController(text: _value.toStringAsFixed(1));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _increment() {
    setState(() {
      _value = double.parse((_value + 0.1).toStringAsFixed(1));
      _controller.text = _value.toStringAsFixed(1);
    });
  }

  void _decrement() {
    setState(() {
      _value = double.parse((_value - 0.1).toStringAsFixed(1));
      _controller.text = _value.toStringAsFixed(1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppPalette.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.labelEn,
                style: const TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppPalette.carbon,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: _decrement,
                icon: const Icon(
                  Icons.remove_circle_outline,
                  size: 48,
                  color: AppPalette.ink70,
                ),
              ),
              const SizedBox(width: 24),
              SizedBox(
                width: 140,
                child: TextField(
                  controller: _controller,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d{0,2}(\.\d{0,1})?$'),
                    ),
                  ],
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontFeatures: AppTypography.tabularFigures,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: AppPalette.carbon,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    suffixText: '"',
                    suffixStyle: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontFeatures: AppTypography.tabularFigures,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: AppPalette.carbon,
                    ),
                  ),
                  onChanged: (val) {
                    final parsed = double.tryParse(val);
                    if (parsed != null) {
                      setState(() {
                        _value = parsed;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 24),
              IconButton(
                onPressed: _increment,
                icon: const Icon(
                  Icons.add_circle_outline,
                  size: 48,
                  color: AppPalette.carbon,
                ),
              ),
            ],
          ),
          const SizedBox(height: 48),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: AppPalette.lineStrong),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    widget.onSave(null); // Clear the value
                  },
                  child: const Text(
                    'Clear',
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppPalette.carbon,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppPalette.carbon,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    widget.onSave(_value);
                  },
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppPalette.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
