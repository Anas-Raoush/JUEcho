import 'package:flutter/material.dart';

import 'package:juecho/common/constants/app_colors.dart';

/// Small reusable form field wrapper used in the Profile page.
///
/// Displays:
/// - a label above the input
/// - a TextFormField with consistent padding/borders
///
/// Parameters:
/// - [label]      : visible label text
/// - [controller] : field controller
/// - [validator]  : optional validator (Form validation)
/// - [enabled]    : allow disabling for read-only fields (e.g., Email)
class LabeledField extends StatelessWidget {
  const LabeledField({
    super.key,
    required this.label,
    required this.controller,
    this.validator,
    this.enabled = true,
  });

  final String label;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          enabled: enabled,
          validator: validator,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.7,
              ),
            ),
          ),
        ),
      ],
    );
  }
}