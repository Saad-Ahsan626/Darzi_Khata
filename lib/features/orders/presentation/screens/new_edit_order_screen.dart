import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:tailor_khata/core/theme/app_colors.dart';
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
  String _selectedStatus = 'Received';

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
          backgroundColor: AppColors.charcoalThread,
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
        backgroundColor: AppColors.charcoalThread,
        behavior: SnackBarBehavior.floating,
      ),
    );

    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customersNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.tailorChalk,
      appBar: AppBar(
        backgroundColor: AppColors.charcoalThread,
        elevation: 0,
        leading: IconButton(
          icon: const Row(
            children: [Icon(Icons.chevron_left, color: AppColors.brassTape)],
          ),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'New Order',
          style: TextStyle(
            color: AppColors.tailorChalk,
            fontFamily: 'Zilla Slab',
            fontSize: 21,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 18.0),
            child: Center(
              child: Text(
                'نیا آرڈر',
                style: TextStyle(
                  color: AppColors.brassTape,
                  fontFamily: 'Noto Nastaliq Urdu',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
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
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.fabricGrey),
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
                            style: const TextStyle(fontFamily: 'Noto Sans'),
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
                child: CircularProgressIndicator(color: AppColors.brassTape),
              ),
              error: (err, stack) => Text(
                'Error loading customers: $err',
                style: const TextStyle(color: AppColors.seamRed),
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
                  color: AppColors.inkMuted,
                  fontFamily: 'Noto Sans',
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.fabricGrey),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.fabricGrey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.brassTape),
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
                          fontFamily: 'Roboto Mono',
                          fontSize: 16,
                        ),
                        decoration: _inputDecoration(),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Required';
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
                          fontFamily: 'Roboto Mono',
                          fontSize: 16,
                        ),
                        decoration: _inputDecoration(),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return null;
                          final a = double.tryParse(val);
                          if (a == null) return 'Invalid';
                          if (a < 0) return 'Cannot be negative';
                          final p = double.tryParse(_priceController.text) ?? 0;
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
                  bottom: BorderSide(color: Color(0x80B8863B), width: 1.5),
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
                    fontFamily: 'Noto Sans',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.charcoalThread,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  _balance <= 0 ? 'Paid' : 'Rs $_balance',
                  style: TextStyle(
                    fontFamily: 'Roboto Mono',
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: _balance <= 0
                        ? AppColors.greenOk
                        : AppColors.seamRed,
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
                  initialDate: _deliveryDate.isBefore(today) ? today : _deliveryDate,
                  firstDate: today,
                  lastDate: today.add(const Duration(days: 365)),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.light(
                          primary: AppColors.charcoalThread,
                          onPrimary: AppColors.tailorChalk,
                          onSurface: AppColors.charcoalThread,
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.fabricGrey),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('EEE, MMM d, yyyy').format(_deliveryDate),
                      style: const TextStyle(
                        fontFamily: 'Roboto Mono',
                        fontSize: 15,
                      ),
                    ),
                    const Icon(
                      Icons.calendar_today,
                      size: 18,
                      color: AppColors.charcoalThread,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            _buildLabel('STATUS'),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children:
                  [
                    'Received',
                    'Cutting',
                    'Stitching',
                    'Ready',
                    'Delivered',
                  ].map((status) {
                    final isSelected = status == _selectedStatus;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedStatus = status),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.stitchNavy
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.stitchNavy
                                : AppColors.fabricGrey,
                          ),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            fontFamily: 'Noto Sans',
                            fontSize: 14,
                            color: isSelected
                                ? Colors.white
                                : AppColors.charcoalThread,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
            ),
            const SizedBox(height: 32),

            // Actions
            ElevatedButton(
              onPressed: () => _saveOrder(sendWhatsApp: false),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brassTape,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Save Order',
                style: TextStyle(
                  fontFamily: 'Noto Sans',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => _saveOrder(sendWhatsApp: true),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.greenOk, width: 1.5),
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
                    color: AppColors.greenOk,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Save & Send WhatsApp Confirmation',
                    style: TextStyle(
                      fontFamily: 'Noto Sans',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.greenOk,
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
          fontFamily: 'Noto Sans',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.inkMuted,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.fabricGrey),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.fabricGrey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.brassTape),
      ),
    );
  }
}

class _TapeDividerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x80B8863B)
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
