import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:tailor_khata/core/theme/design_tokens.dart';
import 'package:tailor_khata/core/widgets/app_widgets.dart';
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
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  File? _selectedImage;
  String? _savedImagePath;

  @override
  void initState() {
    super.initState();

    if (widget.existingCustomer != null) {
      _nameController.text = widget.existingCustomer!.name;
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
        title: Text(
          isEditing ? 'Edit Customer' : 'New Customer',
          style: const TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 22,
            color: AppPalette.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
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

              AppTextField(
                label: 'Full name',
                controller: _nameController,
                hint: 'e.g. Ali Khan',
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Name is required';
                  }
                  if (value.length > 50) return 'Name is too long';
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: 'Phone number',
                controller: _phoneController,
                hint: 'e.g. 0300 1234567',
                kind: AppFieldKind.phone,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return null;
                  final clean = value.replaceAll(RegExp(r'[-\s]'), '');
                  if (!RegExp(r'^(?:\+92|0)[0-9]{9,10}$').hasMatch(clean)) {
                    return 'Invalid Pakistani phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: 'Address (optional)',
                controller: _addressController,
                hint: 'e.g. Shop 12, Main Market',
                maxLines: 2,
              ),
              const SizedBox(height: 32),

              AppButton(
                label: isEditing ? 'Save changes' : 'Save customer',
                onPressed: () async {
                  if (!_formKey.currentState!.validate()) return;

                  final name = _nameController.text.trim();

                  final imagePath = await _saveImageLocally();

                  final customer = Customer(
                    id: isEditing
                        ? widget.existingCustomer!.id
                        : const Uuid().v4(),
                    name: name,
                    urduName: widget.existingCustomer?.urduName,
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
