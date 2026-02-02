import 'package:flutter/material.dart';

import 'package:juecho/common/constants/app_colors.dart';

/// Read-only text section used on admin single submission view.
///
/// Displays:
/// - Title
/// - Description
/// - Suggestion
///
/// This widget intentionally renders read-only TextFields to:
/// - keep visual consistency with editable fields elsewhere
/// - provide multi-line layout for description and suggestion
class AdminFeedbackTextSection extends StatelessWidget {
  /// Feedback title (read-only).
  final String title;

  /// Feedback description (read-only).
  final String description;

  /// Feedback suggestion (read-only).
  final String suggestion;

  const AdminFeedbackTextSection({
    super.key,
    required this.title,
    required this.description,
    required this.suggestion,
  });

  @override
  Widget build(BuildContext context) {
    InputDecoration decoration() {
      return InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary),
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
          decoration: decoration(),
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
          decoration: decoration(),
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
          decoration: decoration(),
        ),
      ],
    );
  }
}