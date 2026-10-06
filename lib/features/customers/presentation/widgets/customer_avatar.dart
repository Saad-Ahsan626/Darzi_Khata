import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tailor_khata/core/theme/design_tokens.dart';
import 'package:tailor_khata/features/customers/domain/entities/customer.dart';

/// Customer photos are files in the app's documents directory, stored on the
/// customer by file name.
Future<File> customerPhotoFile(String fileName) async {
  final directory = await getApplicationDocumentsDirectory();
  return File('${directory.path}/$fileName');
}

/// Up to two initials: the first letters of the first and last words.
String customerInitials(String name) {
  final words = name.trim().split(RegExp(r'\s+'))
    ..removeWhere((word) => word.isEmpty);
  if (words.isEmpty) return '?';
  final first = words.first.characters.first;
  final last = words.length > 1 ? words.last.characters.first : '';
  return '$first$last'.toUpperCase();
}

enum CustomerAvatarTone {
  /// No open work or balance.
  quiet,

  /// Has open orders or money owed.
  active,

  /// Shown on a carbon header.
  onCarbon,
}

/// A round avatar showing the customer's photo, or their initials.
class CustomerAvatar extends StatefulWidget {
  final Customer customer;
  final double size;
  final CustomerAvatarTone tone;

  const CustomerAvatar({
    super.key,
    required this.customer,
    this.size = 46,
    this.tone = CustomerAvatarTone.quiet,
  });

  @override
  State<CustomerAvatar> createState() => _CustomerAvatarState();
}

class _CustomerAvatarState extends State<CustomerAvatar> {
  late Future<File?> _photo = _findPhoto();

  @override
  void didUpdateWidget(CustomerAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.customer.imagePath != widget.customer.imagePath) {
      _photo = _findPhoto();
    }
  }

  Future<File?> _findPhoto() async {
    final fileName = widget.customer.imagePath;
    if (fileName == null || fileName.isEmpty) return null;
    final file = await customerPhotoFile(fileName);
    return await file.exists() ? file : null;
  }

  @override
  Widget build(BuildContext context) {
    final (fill, border, ink) = switch (widget.tone) {
      CustomerAvatarTone.quiet => (
        AppPalette.surfaceControl,
        AppPalette.line,
        AppPalette.ink70,
      ),
      CustomerAvatarTone.active => (
        AppPalette.oliveFill14,
        AppPalette.oliveBorder,
        AppPalette.oliveInk,
      ),
      CustomerAvatarTone.onCarbon => (
        AppPalette.glassOnCarbon,
        AppPalette.glassBorder,
        AppPalette.white,
      ),
    };
    return FutureBuilder<File?>(
      future: _photo,
      builder: (context, snapshot) {
        final photo = snapshot.data;
        return Container(
          width: widget.size,
          height: widget.size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: fill,
            border: Border.all(color: border),
            image: photo == null
                ? null
                : DecorationImage(image: FileImage(photo), fit: BoxFit.cover),
          ),
          child: photo == null
              ? ExcludeSemantics(
                  child: Text(
                    customerInitials(widget.customer.name),
                    textScaler: TextScaler.noScaling,
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: widget.size * 0.32,
                      fontWeight: FontWeight.w600,
                      color: ink,
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }
}
