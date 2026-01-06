import 'package:flutter/material.dart';
import 'package:juecho/common/constants/app_colors.dart';

class AdminFeedbackTextSection extends StatelessWidget {
  final String title;
  final String description;
  final String suggestion;

  const AdminFeedbackTextSection({
    super.key,
    required this.title,
    required this.description,
    required this.suggestion,
  });

  @override
  Widget build(BuildContext context) {
    InputDecoration _decoration() {
      return InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.primary),
        ),
        isDense: true,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Title',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: TextEditingController(text: title),
          readOnly: true,
          decoration: _decoration(),
        ),
        const SizedBox(height: 16),

        const Text(
          'Description',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: TextEditingController(text: description),
          readOnly: true,
          maxLines: 3,
          decoration: _decoration(),
        ),
        const SizedBox(height: 16),

        const Text(
          'Suggestion',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: TextEditingController(text: suggestion),
          readOnly: true,
          maxLines: 3,
          decoration: _decoration(),
        ),
      ],
    );
  }
}