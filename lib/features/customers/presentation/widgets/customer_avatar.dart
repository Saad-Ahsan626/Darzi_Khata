import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tailor_khata/core/theme/design_tokens.dart';
import 'package:tailor_khata/features/customers/domain/entities/customer.dart';

class CustomerAvatar extends StatelessWidget {
  final Customer customer;
  final double size;
  final double radius;
  final double fontSize;

  const CustomerAvatar({
    super.key,
    required this.customer,
    this.size = 48,
    this.radius = 12,
    this.fontSize = 20,
  });

  Color _getAvatarColor(String id) {
    // Generate a consistent color based on the customer ID
    final colors = [
      AppPalette.carbon,
      AppPalette.carbon,
      AppPalette.carbon,
      AppPalette.ink70,
    ];
    final int hash = id.hashCode;
    return colors[hash % colors.length];
  }

  String _getInitial() {
    if (customer.urduName != null && customer.urduName!.isNotEmpty) {
      return customer.urduName!.trim().substring(0, 1);
    }
    if (customer.name.isNotEmpty) {
      return customer.name.trim().substring(0, 1).toUpperCase();
    }
    return '?';
  }

  Future<File?> _getImageFile() async {
    if (customer.imagePath == null || customer.imagePath!.isEmpty) return null;
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/${customer.imagePath}');
    if (await file.exists()) {
      return file;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (customer.imagePath != null && customer.imagePath!.isNotEmpty) {
      return FutureBuilder<File?>(
        future: _getImageFile(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildFallback();
          }
          if (snapshot.hasData && snapshot.data != null) {
            return Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radius),
                image: DecorationImage(
                  image: FileImage(snapshot.data!),
                  fit: BoxFit.cover,
                ),
              ),
            );
          }
          return _buildFallback();
        },
      );
    }

    return _buildFallback();
  }

  Widget _buildFallback() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _getAvatarColor(customer.id),
        borderRadius: BorderRadius.circular(radius),
      ),
      alignment: Alignment.center,
      child: Text(
        _getInitial(),
        style: TextStyle(
          color: AppPalette.white,
          fontFamily: AppTypography.fontFamily,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
