import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:tailor_khata/core/error/failures.dart';
import 'package:tailor_khata/core/formatting/app_formats.dart';
import 'package:tailor_khata/core/theme/design_tokens.dart';
import 'package:tailor_khata/core/widgets/app_widgets.dart';
import 'package:tailor_khata/features/customers/domain/entities/customer.dart';
import 'package:tailor_khata/features/customers/presentation/providers/customers_notifier.dart';
import 'package:tailor_khata/features/customers/presentation/widgets/customer_dialogs.dart';

class AddEditCustomerScreen extends ConsumerStatefulWidget {
  final Customer? existingCustomer;

  /// Name or phone to start a new customer with, carried over from a search.
  final String? initialName;
  final String? initialPhone;

  const AddEditCustomerScreen({
    super.key,
    this.existingCustomer,
    this.initialName,
    this.initialPhone,
  });

  @override
  ConsumerState<AddEditCustomerScreen> createState() =>
      _AddEditCustomerScreenState();
}

class _AddEditCustomerScreenState extends ConsumerState<AddEditCustomerScreen> {
  static const _phoneLength = 11;
  static const _maxNameLength = 50;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _noteController = TextEditingController();
  final _phoneFocus = FocusNode();

  // Kept for the life of the form so a retried save writes the same customer.
  late final String _customerId =
      widget.existingCustomer?.id ?? const Uuid().v4();

  File? _selectedImage;
  String? _savedImagePath;

  /// The phone field is checked once the user has left it, not while typing.
  bool _phoneChecked = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();

    final existing = widget.existingCustomer;
    _nameController.text = existing?.name ?? widget.initialName ?? '';
    _phoneController.text = formatPhone(
      existing?.phone ?? widget.initialPhone,
    );
    _addressController.text = existing?.address ?? '';
    _noteController.text = existing?.note ?? '';
    _savedImagePath = existing?.imagePath;
    if (_savedImagePath != null && _savedImagePath!.isNotEmpty) {
      _loadExistingImage();
    }

    _nameController.addListener(_refresh);
    _phoneController.addListener(_refresh);
    _phoneFocus.addListener(() {
      if (!_phoneFocus.hasFocus && !_phoneChecked) {
        setState(() => _phoneChecked = true);
      }
    });
  }

  void _refresh() => setState(() {});

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
    _noteController.dispose();
    _phoneFocus.dispose();
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

  String get _name => _nameController.text.trim();
  String get _phone => phoneDigits(_phoneController.text);

  bool get _nameValid => _name.isNotEmpty && _name.length <= _maxNameLength;
  bool get _phoneValid =>
      _phone.length == _phoneLength && _phone.startsWith('0');

  String? get _phoneProblem {
    if (_phoneValid) return null;
    if (_phone.isEmpty) return 'Phone number is required';
    if (!_phone.startsWith('0')) return 'Start the number with 0';
    return 'Needs $_phoneLength digits — '
        '${_phoneLength - _phone.length} remaining';
  }

  /// What still stops the form from being saved, shown under the button.
  String? get _missing {
    if (_name.isEmpty) return "Enter the customer's name to save";
    if (!_nameValid) return 'Shorten the name to save';
    if (!_phoneValid) return 'Complete the phone number to save';
    return null;
  }

  Future<Failure?> _store() async {
    final existing = widget.existingCustomer;
    final String? imagePath;
    try {
      imagePath = await _saveImageLocally();
    } on Exception catch (error) {
      return DatabaseFailure('Photo could not be stored: $error');
    }

    final customer = Customer(
      id: _customerId,
      name: _name,
      urduName: existing?.urduName,
      phone: _phone,
      address: _addressController.text.trim(),
      imagePath: imagePath,
      note: _noteController.text.trim(),
      createdAt: existing?.createdAt ?? DateTime.now(),
      ownerId: existing?.ownerId ?? 'guest',
      syncStatus: existing?.syncStatus ?? 0,
    );
    final customers = ref.read(customersNotifierProvider.notifier);
    return existing == null
        ? customers.addCustomer(customer)
        : customers.updateCustomer(customer);
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    final failure = await _store();
    if (!mounted) return;
    setState(() => _saving = false);

    if (failure == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.existingCustomer == null
                ? 'Customer saved'
                : 'Customer updated',
          ),
        ),
      );
      context.pop();
      return;
    }
    final retry = await showSaveFailureSheet(
      context,
      failure: failure,
      at: DateTime.now(),
    );
    if (retry && mounted) await _save();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingCustomer != null;
    final missing = _missing;

    return Scaffold(
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
                    onPressed: () => context.pop(),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isEditing ? 'Edit Customer' : 'New Customer',
                      style: AppTypography.title.copyWith(
                        fontSize: 19,
                        letterSpacing: 19 * -0.02,
                        color: AppPalette.carbon,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPadding,
                  22,
                  AppSpacing.screenPadding,
                  AppSpacing.xl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _PhotoPicker(image: _selectedImage, onTap: _pickImage),
                    const SizedBox(height: AppSpacing.xl),
                    AppTextField(
                      label: 'Full name',
                      controller: _nameController,
                      hint: 'Enter customer name',
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.words,
                      errorText: _name.length > _maxNameLength
                          ? 'Name is too long'
                          : null,
                    ),
                    const SizedBox(height: 18),
                    AppTextField(
                      label: 'Phone number',
                      controller: _phoneController,
                      focusNode: _phoneFocus,
                      hint: '0300 123 4567',
                      kind: AppFieldKind.phone,
                      textInputAction: TextInputAction.next,
                      inputFormatters: [_PhoneInputFormatter()],
                      errorText: _phoneChecked ? _phoneProblem : null,
                    ),
                    const SizedBox(height: 18),
                    AppTextField(
                      label: 'Address (optional)',
                      controller: _addressController,
                      hint: 'Street, area, city',
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 18),
                    AppTextField(
                      label: 'Note (optional)',
                      controller: _noteController,
                      hint: 'Prefers loose fit, collar 1 inch wider',
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ],
                ),
              ),
            ),
            // In the body rather than a bottom bar so it rides above the
            // keyboard.
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppButton(
                      label: _saving
                          ? 'Saving'
                          : isEditing
                          ? 'Save changes'
                          : 'Save customer',
                      isLoading: _saving,
                      onPressed: missing == null ? _save : null,
                    ),
                    if (missing != null) ...[
                      const SizedBox(height: 9),
                      Text(
                        missing,
                        textAlign: TextAlign.center,
                        style: AppTypography.support.copyWith(fontSize: 11.5),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoPicker extends StatelessWidget {
  const _PhotoPicker({required this.image, required this.onTap});
  final File? image;
  final VoidCallback onTap;

  static const _size = 68.0;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(AppRadii.card),
    child: Row(
      children: [
        if (image == null)
          const AppDashedBox(
            radius: _size / 2,
            child: SizedBox.square(
              dimension: _size,
              child: Icon(
                Icons.photo_camera_outlined,
                size: 24,
                color: AppPalette.ink45,
              ),
            ),
          )
        else
          Container(
            width: _size,
            height: _size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppPalette.line),
              image: DecorationImage(
                image: FileImage(image!),
                fit: BoxFit.cover,
              ),
            ),
          ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                image == null ? 'Add photo' : 'Change photo',
                style: AppTypography.support.copyWith(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: AppPalette.carbon,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Optional — initials used otherwise',
                style: AppTypography.support.copyWith(fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// Keeps the phone field to 11 digits, grouped as `0300 412 8876`.
class _PhoneInputFormatter extends TextInputFormatter {
  static final _digit = RegExp(r'\d');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = phoneDigits(newValue.text);
    if (digits.length > 11) digits = digits.substring(0, 11);
    final text = formatPhone(digits);

    // Keep the cursor after the same number of digits it was after.
    final cursor = newValue.selection.end.clamp(0, newValue.text.length);
    final digitsBefore = _digit
        .allMatches(newValue.text.substring(0, cursor))
        .length;
    var offset = 0;
    for (var seen = 0; offset < text.length && seen < digitsBefore; offset++) {
      if (_digit.hasMatch(text[offset])) seen++;
    }
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: offset),
    );
  }
}
