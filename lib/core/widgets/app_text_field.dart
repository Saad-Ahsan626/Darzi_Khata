import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../theme/design_tokens.dart';

enum AppFieldKind { text, phone, amount, search }

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.controller,
    this.focusNode,
    this.hint,
    this.helper,
    this.errorText,
    this.validator,
    this.onChanged,
    this.kind = AppFieldKind.text,
    this.keyboardType,
    this.inputFormatters,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.maxLines = 1,
    this.enabled = true,
    this.autovalidateMode = AutovalidateMode.disabled,
  });

  final String label;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? hint;
  final String? helper;
  final String? errorText;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final AppFieldKind kind;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final int maxLines;
  final bool enabled;
  final AutovalidateMode autovalidateMode;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      ExcludeSemantics(child: Text(label, style: AppTypography.support)),
      const SizedBox(height: AppSpacing.sm),
      Semantics(
        label: label,
        child: TextFormField(
          controller: controller,
          focusNode: focusNode,
          enabled: enabled,
          maxLines: maxLines,
          validator: validator,
          errorBuilder: (_, message) => _FieldError(message),
          onChanged: onChanged,
          autovalidateMode: autovalidateMode,
          textInputAction: textInputAction,
          textCapitalization: textCapitalization,
          inputFormatters: inputFormatters,
          keyboardType:
              keyboardType ??
              switch (kind) {
                AppFieldKind.phone => TextInputType.phone,
                AppFieldKind.amount => const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                _ =>
                  maxLines > 1 ? TextInputType.multiline : TextInputType.text,
              },
          style: AppTypography.body.copyWith(
            fontFeatures:
                kind == AppFieldKind.amount || kind == AppFieldKind.phone
                ? AppTypography.tabularFigures
                : null,
          ),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.all(AppSpacing.lg),
            hintText: hint,
            helperText: helper,
            helperMaxLines: 3,
            error: errorText == null ? null : _FieldError(errorText!),
            prefixIcon: kind == AppFieldKind.search
                ? const Icon(Icons.search)
                : kind == AppFieldKind.amount
                ? const Center(
                    widthFactor: 1,
                    heightFactor: 1,
                    child: Text('Rs', style: AppTypography.body),
                  )
                : null,
          ),
        ),
      ),
    ],
  );
}

class _FieldError extends StatelessWidget {
  const _FieldError(this.message);
  final String message;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ExcludeSemantics(
          child: Icon(Icons.error_outline, size: 16, color: AppPalette.carbon),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            message,
            style: AppTypography.support.copyWith(color: AppPalette.carbon),
          ),
        ),
      ],
    ),
  );
}

class AppDateField extends StatelessWidget {
  const AppDateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime>? onChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(label, style: AppTypography.support),
      const SizedBox(height: AppSpacing.sm),
      OutlinedButton.icon(
        style: OutlinedButton.styleFrom(alignment: Alignment.centerLeft),
        icon: const Icon(Icons.calendar_today_outlined, size: 20),
        label: Text(
          value == null
              ? 'Choose a date'
              : DateFormat('d MMM yyyy', 'en').format(value!),
        ),
        onPressed: onChanged == null
            ? null
            : () async {
                final selected = await showDatePicker(
                  context: context,
                  initialDate: value ?? DateTime.now(),
                  firstDate: DateTime(1900),
                  lastDate: DateTime(2200),
                );
                if (selected != null && context.mounted) onChanged!(selected);
              },
      ),
    ],
  );
}
