import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:tailor_khata/core/theme/design_tokens.dart';
import 'package:tailor_khata/features/customers/domain/entities/customer.dart';
import 'package:tailor_khata/features/customers/presentation/providers/customers_notifier.dart';

class AddEditCustomerScreen extends ConsumerStatefulWidget {
  final Customer? existingCustomer;

  const AddEditCustomerScreen({super.key, this.existingCustomer});

  @override
  ConsumerState<AddEditCustomerScreen> createState() =>
      _AddEditCustomerScreenState();
}

class _AddEditCustomerScreenState extends ConsumerState<AddEditCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _urduNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  File? _selectedImage;
  String? _savedImagePath;

  @override
  void initState() {
    super.initState();

    // Add listeners to rebuild UI and hide hints when typing
    _nameController.addListener(() => setState(() {}));
    _urduNameController.addListener(() => setState(() {}));
    _phoneController.addListener(() => setState(() {}));
    _addressController.addListener(() => setState(() {}));

    if (widget.existingCustomer != null) {
      _nameController.text = widget.existingCustomer!.name;
      _urduNameController.text = widget.existingCustomer!.urduName ?? '';
      _phoneController.text = widget.existingCustomer!.phone ?? '';
      _addressController.text = widget.existingCustomer!.address ?? '';
      _savedImagePath = widget.existingCustomer!.imagePath;
      if (_savedImagePath != null && _savedImagePath!.isNotEmpty) {
        _loadExistingImage();
      }
    }
  }

  Future<void> _loadExistingImage() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$_savedImagePath');
    if (await file.exists()) {
      setState(() {
        _selectedImage = file;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _urduNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<String?> _saveImageLocally() async {
    if (_selectedImage == null) return _savedImagePath;

    final dir = await getApplicationDocumentsDirectory();
    if (_selectedImage!.path.startsWith(dir.path)) {
      return _savedImagePath;
    }

    final ext = _selectedImage!.path.split('.').last;
    final fileName = 'customer_${const Uuid().v4()}.$ext';
    await _selectedImage!.copy('${dir.path}/$fileName');
    return fileName;
  }

  InputDecoration _inputDecoration(
    String hintText,
    TextEditingController controller, {
    bool? hideHintOverride,
  }) {
    final bool hideHint = hideHintOverride ?? controller.text.isNotEmpty;
    return InputDecoration(
      hintText: hideHint ? '' : hintText,
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
        borderSide: const BorderSide(color: AppPalette.carbon, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: AppPalette.ink70,
          fontSize: 11,
          fontFamily: AppTypography.fontFamily,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingCustomer != null;

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
            Text(
              isEditing ? 'Edit Customer' : 'New Customer',
              style: const TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 22,
                color: AppPalette.white,
              ),
            ),
            Text(
              isEditing ? 'ترمیم' : 'نیا گاہک',
              style: const TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 18,
                color: AppPalette.white,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo Picker
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: AppPalette.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: AppPalette.lineStrong,
                        width: 1.5,
                      ),
                      image: _selectedImage != null
                          ? DecorationImage(
                              image: FileImage(_selectedImage!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: _selectedImage == null
                        ? const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_a_photo,
                                color: AppPalette.ink70,
                                size: 28,
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Add Photo',
                                style: TextStyle(
                                  color: AppPalette.ink70,
                                  fontSize: 10,
                                  fontFamily: AppTypography.fontFamily,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              _buildLabel('ENGLISH NAME'),
              TextFormField(
                controller: _nameController,
                style: const TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 16,
                ),
                decoration: _inputDecoration(
                  'e.g. Ali Khan',
                  _nameController,
                  hideHintOverride:
                      _nameController.text.isNotEmpty ||
                      _urduNameController.text.isNotEmpty,
                ),
                textCapitalization: TextCapitalization.words,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Name is required';
                  }
                  if (val.length > 50) return 'Name is too long';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              _buildLabel('URDU NAME / اردو نام'),
              TextFormField(
                controller: _urduNameController,
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
                style: const TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 16,
                ),
                decoration: _inputDecoration(
                  'علی خان',
                  _urduNameController,
                  hideHintOverride:
                      _nameController.text.isNotEmpty ||
                      _urduNameController.text.isNotEmpty,
                ),
              ),
              const SizedBox(height: 16),

              _buildLabel('PHONE NUMBER'),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontFeatures: AppTypography.tabularFigures,
                  fontSize: 16,
                ),
                decoration: _inputDecoration(
                  'e.g. 0300 1234567',
                  _phoneController,
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return null;
                  final clean = val.replaceAll(RegExp(r'[-\s]'), '');
                  if (!RegExp(r'^(?:\+92|0)[0-9]{9,10}$').hasMatch(clean)) {
                    return 'Invalid Pakistani phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              _buildLabel('ADDRESS (OPTIONAL)'),
              TextFormField(
                controller: _addressController,
                style: const TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 16,
                ),
                decoration: _inputDecoration(
                  'e.g. Shop 12, Main Market',
                  _addressController,
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppPalette.carbon,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    if (!_formKey.currentState!.validate()) return;

                    final name = _nameController.text.trim();

                    final imagePath = await _saveImageLocally();

                    final customer = Customer(
                      id: isEditing
                          ? widget.existingCustomer!.id
                          : const Uuid().v4(),
                      name: name,
                      urduName: _urduNameController.text.trim(),
                      phone: _phoneController.text.trim(),
                      address: _addressController.text.trim(),
                      imagePath: imagePath,
                      createdAt: isEditing
                          ? widget.existingCustomer!.createdAt
                          : DateTime.now(),
                    );

                    if (isEditing) {
                      ref
                          .read(customersNotifierProvider.notifier)
                          .updateCustomer(customer);
                    } else {
                      ref
                          .read(customersNotifierProvider.notifier)
                          .addCustomer(customer);
                    }

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isEditing ? 'Customer updated' : 'Customer saved',
                          ),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: AppPalette.carbon,
                        ),
                      );
                      context.pop();
                    }
                  },
                  child: Text(
                    isEditing ? 'Save Changes' : 'Save Customer',
                    style: const TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppPalette.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
