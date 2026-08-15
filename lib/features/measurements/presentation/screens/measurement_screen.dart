import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_3d_controller/flutter_3d_controller.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:tailor_khata/core/theme/app_colors.dart';
import 'package:tailor_khata/features/measurements/domain/entities/measurement.dart';
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
  late Flutter3DController _controller;
  String _activeGarment = 'Shalwar Kameez';
  String _fitType = 'Formal Fit';
  bool _isFrontView = true;

  final List<String> _garments = ['Shalwar Kameez', 'Kurta', 'Pant-Coat', 'Sherwani', 'Waistcoat'];

  @override
  void initState() {
    super.initState();
    _controller = Flutter3DController();
  }

  void _toggleView() {
    setState(() {
      _isFrontView = !_isFrontView;
    });
    // Set camera orbit (theta phi radius)
    if (_isFrontView) {
      _controller.setCameraOrbit(0, 90, 100);
    } else {
      _controller.setCameraOrbit(90, 90, 100);
    }
  }

  Measurement? _getMeasurement(List<Measurement> measurements) {
    try {
      return measurements.firstWhere(
        (m) => m.customerId == widget.customerId && m.garmentType == _activeGarment
      );
    } catch (_) {
      return null;
    }
  }

  void _openBottomEditor(String key, String labelEn, String labelUr, String? currentValue) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _MeasurementEditorSheet(
        labelEn: labelEn,
        labelUr: labelUr,
        initialValue: currentValue,
        onSave: (val) {
          _saveMeasurement(key, val);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _saveMeasurement(String key, String value) {
    final measurementsAsync = ref.read(measurementsNotifierProvider);
    final measurements = measurementsAsync.value ?? [];
    Measurement? current = _getMeasurement(measurements);

    Map<String, dynamic> data = current != null ? Map.from(current.measurementData) : {};
    data[key] = value;

    final newMeasurement = Measurement(
      id: current?.id ?? const Uuid().v4(),
      customerId: widget.customerId,
      garmentType: _activeGarment,
      measurementData: data,
      createdAt: current?.createdAt ?? DateTime.now(),
    );

    ref.read(measurementsNotifierProvider.notifier).saveMeasurement(newMeasurement);
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customersNotifierProvider);
    final measurementsAsync = ref.watch(measurementsNotifierProvider);

    final customerName = customersAsync.value?.firstWhere((c) => c.id == widget.customerId).name ?? 'Customer';
    final measurement = measurementsAsync.value != null ? _getMeasurement(measurementsAsync.value!) : null;
    final data = measurement?.measurementData ?? {};

    return Scaffold(
      backgroundColor: AppColors.tailorChalk,
      appBar: AppBar(
        backgroundColor: AppColors.charcoalThread,
        elevation: 0,
        leading: IconButton(
          icon: const Row(children: [Icon(Icons.chevron_left, color: AppColors.brassTape)]),
          onPressed: () => context.pop(),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Measurements', style: TextStyle(fontFamily: 'Noto Sans', fontSize: 12, color: AppColors.inkMuted)),
                Text(customerName, style: const TextStyle(fontFamily: 'Zilla Slab', fontSize: 20, color: AppColors.tailorChalk)),
              ],
            ),
            const Text('ناپ', style: TextStyle(fontFamily: 'Noto Nastaliq Urdu', fontSize: 22, color: AppColors.brassTape)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Segmented Control (Fit Type)
          Container(
            color: AppColors.charcoalThread,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _fitType = 'Formal Fit'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _fitType == 'Formal Fit' ? AppColors.brassTape : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Formal Fit',
                        style: TextStyle(
                          color: _fitType == 'Formal Fit' ? Colors.white : AppColors.inkMuted,
                          fontFamily: 'Noto Sans',
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _fitType = 'Casual Fit'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _fitType == 'Casual Fit' ? AppColors.brassTape : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Casual Fit',
                        style: TextStyle(
                          color: _fitType == 'Casual Fit' ? Colors.white : AppColors.inkMuted,
                          fontFamily: 'Noto Sans',
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Garment Chips
          Container(
            height: 60,
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: AppColors.fabricGrey)),
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
                      color: isActive ? AppColors.charcoalThread : AppColors.tailorChalk,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isActive ? AppColors.charcoalThread : AppColors.fabricGrey),
                    ),
                    child: Text(
                      garment,
                      style: TextStyle(
                        color: isActive ? Colors.white : AppColors.charcoalThread,
                        fontFamily: 'Noto Sans',
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
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
            child: Stack(
              children: [
                // 3D Viewer
                Flutter3DViewer(
                  controller: _controller,
                  src: 'assets/human_model/basic_human_male.glb',
                  progressBarColor: AppColors.brassTape,
                ),

                // Floating Chips Overlay (Front View Layout)
                if (_isFrontView) ...[
                  Positioned(
                    top: 60,
                    left: 20,
                    child: MeasurementChip(
                      labelEn: 'Neck',
                      labelUr: 'گلا',
                      value: data['neck'],
                      onTap: () => _openBottomEditor('neck', 'Neck', 'گلا', data['neck']),
                    ),
                  ),
                  Positioned(
                    top: 140,
                    right: 20,
                    child: MeasurementChip(
                      labelEn: 'Chest',
                      labelUr: 'چھاتی',
                      value: data['chest'],
                      onTap: () => _openBottomEditor('chest', 'Chest', 'چھاتی', data['chest']),
                    ),
                  ),
                  Positioned(
                    top: 220,
                    left: 20,
                    child: MeasurementChip(
                      labelEn: 'Waist',
                      labelUr: 'کمر',
                      value: data['waist'],
                      onTap: () => _openBottomEditor('waist', 'Waist', 'کمر', data['waist']),
                    ),
                  ),
                  Positioned(
                    top: 300,
                    right: 20,
                    child: MeasurementChip(
                      labelEn: 'Hip',
                      labelUr: 'ہپ',
                      value: data['hip'],
                      onTap: () => _openBottomEditor('hip', 'Hip', 'ہپ', data['hip']),
                    ),
                  ),
                  Positioned(
                    top: 380,
                    left: 20,
                    child: MeasurementChip(
                      labelEn: 'Length',
                      labelUr: 'لمبائی',
                      value: data['length'],
                      onTap: () => _openBottomEditor('length', 'Length', 'لمبائی', data['length']),
                    ),
                  ),
                ],

                // View Toggle Button
                Positioned(
                  bottom: 24,
                  right: 24,
                  child: FloatingActionButton.extended(
                    onPressed: _toggleView,
                    backgroundColor: Colors.white,
                    icon: Icon(_isFrontView ? Icons.turn_right : Icons.turn_left, color: AppColors.charcoalThread),
                    label: Text(
                      _isFrontView ? 'Side View' : 'Front View',
                      style: const TextStyle(color: AppColors.charcoalThread, fontFamily: 'Noto Sans', fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MeasurementEditorSheet extends StatefulWidget {
  final String labelEn;
  final String labelUr;
  final String? initialValue;
  final Function(String) onSave;

  const _MeasurementEditorSheet({
    required this.labelEn,
    required this.labelUr,
    this.initialValue,
    required this.onSave,
  });

  @override
  State<_MeasurementEditorSheet> createState() => _MeasurementEditorSheetState();
}

class _MeasurementEditorSheetState extends State<_MeasurementEditorSheet> {
  late double _value;

  @override
  void initState() {
    super.initState();
    _value = double.tryParse(widget.initialValue?.replaceAll('"', '') ?? '30') ?? 30.0;
  }

  void _increment() => setState(() => _value += 0.5);
  void _decrement() => setState(() => _value -= 0.5);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
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
                style: const TextStyle(fontFamily: 'Zilla Slab', fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.charcoalThread),
              ),
              Text(
                widget.labelUr,
                style: const TextStyle(fontFamily: 'Noto Nastaliq Urdu', fontSize: 24, color: AppColors.brassTape),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: _decrement,
                icon: const Icon(Icons.remove_circle_outline, size: 48, color: AppColors.inkMuted),
              ),
              const SizedBox(width: 24),
              Text(
                '$_value"',
                style: const TextStyle(fontFamily: 'Roboto Mono', fontSize: 48, fontWeight: FontWeight.bold, color: AppColors.charcoalThread),
              ),
              const SizedBox(width: 24),
              IconButton(
                onPressed: _increment,
                icon: const Icon(Icons.add_circle_outline, size: 48, color: AppColors.brassTape),
              ),
            ],
          ),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brassTape,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              onPressed: () {
                widget.onSave('$_value"');
              },
              child: const Text(
                'Done',
                style: TextStyle(fontFamily: 'Noto Sans', fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
