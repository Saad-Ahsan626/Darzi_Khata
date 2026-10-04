import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:tailor_khata/core/theme/design_tokens.dart';
import 'package:tailor_khata/features/orders/domain/entities/order.dart'
    as order_entity;
import 'package:tailor_khata/features/orders/presentation/providers/orders_notifier.dart';
import 'package:tailor_khata/features/customers/presentation/providers/customers_notifier.dart';
import 'package:tailor_khata/features/orders/presentation/widgets/garment_type_selector.dart';

class NewEditOrderScreen extends ConsumerStatefulWidget {
  const NewEditOrderScreen({super.key});

  @override
  ConsumerState<NewEditOrderScreen> createState() => _NewEditOrderScreenState();
}

class _NewEditOrderScreenState extends ConsumerState<NewEditOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedCustomerId;
  String _selectedGarment = 'Shalwar Kameez';
  final TextEditingController _fabricController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _advanceController = TextEditingController();
  DateTime _deliveryDate = DateTime.now().add(const Duration(days: 7));
  final String _selectedStatus = 'Received';

  @override
  void initState() {
    super.initState();
    _priceController.addListener(() => setState(() {}));
    _advanceController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _fabricController.dispose();
    _priceController.dispose();
    _advanceController.dispose();
    super.dispose();
  }

  double get _balance {
    final price = double.tryParse(_priceController.text) ?? 0;
    final advance = double.tryParse(_advanceController.text) ?? 0;
    return price - advance;
  }

  void _saveOrder({required bool sendWhatsApp}) {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCustomerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a customer'),
          backgroundColor: AppPalette.carbon,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final newOrder = order_entity.Order(
      id: const Uuid().v4(),
      customerId: _selectedCustomerId!,
      garmentType: _selectedGarment,
      status: _selectedStatus,
      deliveryDate: _deliveryDate,
      totalAmount: double.parse(_priceController.text),
      advancePaid: double.tryParse(_advanceController.text) ?? 0.0,
      notes: _fabricController.text,
      createdAt: DateTime.now(),
    );

    ref.read(ordersNotifierProvider.notifier).addOrder(newOrder);

    final toastMsg = sendWhatsApp
        ? 'Order saved · WhatsApp confirmation sent'
        : 'Order saved';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(toastMsg),
        backgroundColor: AppPalette.carbon,
        behavior: SnackBarBehavior.floating,
      ),
    );

    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customersNotifierProvider);

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
        title: const Text(
          'New Order',
          style: TextStyle(
            color: AppPalette.white,
            fontFamily: AppTypography.fontFamily,
            fontSize: 21,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: const [],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Customer Picker
              _buildLabel('CUSTOMER'),
              customersAsync.when(
                data: (customers) {
                  if (customers.isEmpty) {
                    return const Text(
                      'No customers available. Please add one first.',
                    );
                  }
                  // Default selection
                  if (_selectedCustomerId == null && customers.isNotEmpty) {
                    _selectedCustomerId = customers.first.id;
                  }
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppPalette.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppPalette.lineStrong),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCustomerId,
                        isExpanded: true,
                        items: customers.map((c) {
                          return DropdownMenuItem(
                            value: c.id,
                            child: Text(
                              c.name,
                              style: const TextStyle(
                                fontFamily: AppTypography.fontFamily,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedCustomerId = val;
                          });
                        },
                      ),
                    ),
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppPalette.carbon),
                ),
                error: (err, stack) => Text(
                  'Error loading customers: $err',
                  style: const TextStyle(color: AppPalette.carbon),
                ),
              ),
              const SizedBox(height: 16),

              _buildLabel('GARMENT TYPE'),
              GarmentTypeSelector(
                selectedGarment: _selectedGarment,
                onChanged: (val) => setState(() => _selectedGarment = val),
              ),
              const SizedBox(height: 16),

              _buildLabel('FABRIC'),
              TextField(
                controller: _fabricController,
                decoration: InputDecoration(
                  hintText: 'e.g. Navy wash & wear',
                  hintStyle: const TextStyle(
                    color: AppPalette.ink70,
                    fontFamily: AppTypography.fontFamily,
                  ),
                  filled: true,
                  fillColor: AppPalette.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppPalette.lineStrong),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppPalette.lineStrong),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppPalette.carbon),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('PRICE (RS)'),
                        TextFormField(
                          controller: _priceController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontFeatures: AppTypography.tabularFigures,
                            fontSize: 16,
                          ),
                          decoration: _inputDecoration(),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Required';
                            }
                            final p = double.tryParse(val);
                            if (p == null) return 'Invalid';
                            if (p < 0) return 'Cannot be negative';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('ADVANCE (RS)'),
                        TextFormField(
                          controller: _advanceController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontFeatures: AppTypography.tabularFigures,
                            fontSize: 16,
                          ),
                          decoration: _inputDecoration(),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return null;
                            final a = double.tryParse(val);
                            if (a == null) return 'Invalid';
                            if (a < 0) return 'Cannot be negative';
                            final p =
                                double.tryParse(_priceController.text) ?? 0;
                            if (a > p) return 'Exceeds price';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Tape Divider
              Container(
                height: 7,
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: AppPalette.oliveBorder,
                      width: 1.5,
                    ),
                  ),
                ),
                child: CustomPaint(painter: _TapeDividerPainter()),
              ),
              const SizedBox(height: 16),

              // Balance Due
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'BALANCE DUE',
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppPalette.carbon,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    _balance <= 0 ? 'Paid' : 'Rs $_balance',
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontFeatures: AppTypography.tabularFigures,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: _balance <= 0
                          ? AppPalette.oliveInk
                          : AppPalette.carbon,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              _buildLabel('DELIVERY DATE'),
              GestureDetector(
                onTap: () async {
                  final now = DateTime.now();
                  final today = DateTime(now.year, now.month, now.day);
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _deliveryDate.isBefore(today)
                        ? today
                        : _deliveryDate,
                    firstDate: today,
                    lastDate: today.add(const Duration(days: 365)),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: AppPalette.carbon,
                            onPrimary: AppPalette.white,
                            onSurface: AppPalette.carbon,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (date != null) {
                    setState(() => _deliveryDate = date);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: AppPalette.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppPalette.lineStrong),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('EEE, MMM d, yyyy').format(_deliveryDate),
                        style: const TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontFeatures: AppTypography.tabularFigures,
                          fontSize: 15,
                        ),
                      ),
                      const Icon(
                        Icons.calendar_today,
                        size: 18,
                        color: AppPalette.carbon,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Status is auto-set to Received for new orders.
              const SizedBox(height: 32),

              // Actions
              ElevatedButton(
                onPressed: () => _saveOrder(sendWhatsApp: false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppPalette.carbon,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Save Order',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppPalette.white,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => _saveOrder(sendWhatsApp: true),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(
                    color: AppPalette.oliveInk,
                    width: 1.5,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      color: AppPalette.oliveInk,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Save & Send WhatsApp Confirmation',
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppPalette.oliveInk,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppPalette.ink70,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: AppPalette.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppPalette.lineStrong),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppPalette.lineStrong),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppPalette.carbon),
      ),
    );
  }
}

class _TapeDividerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppPalette.oliveBorder
      ..strokeWidth = 1.5;

    for (double i = 0; i < size.width; i += 9) {
      canvas.drawLine(
        Offset(i, size.height - 3),
        Offset(i, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
