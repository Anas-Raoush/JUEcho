import 'package:flutter/material.dart';
import 'package:juecho/common/constants/app_colors.dart';

/// Text editing section for a feedback submission.
///
/// Fields:
/// - Title
/// - Description
/// - Suggestion
///
/// Edit mode:
/// - When [canEdit] is false, fields are rendered read-only.
/// - When [canEdit] is true, controllers remain editable and changes are
///   consumed by the parent widget/provider on save.
class FeedbackTextSection extends StatelessWidget {
  /// Controller for the title field.
  final TextEditingController titleController;

  /// Controller for the description field.
  final TextEditingController descriptionController;

  /// Controller for the suggestion field.
  final TextEditingController suggestionController;

  /// Controls whether fields are editable.
  final bool canEdit;

  const FeedbackTextSection({
    super.key,
    required this.titleController,
    required this.descriptionController,
    required this.suggestionController,
    required this.canEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Title',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: titleController,
          readOnly: !canEdit,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
            isDense: true,
          ),
        ),
        const SizedBox(height: 16),

        const Text(
          'Description',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: descriptionController,
          readOnly: !canEdit,
          maxLines: 3,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
        ),
        const SizedBox(height: 16),

        const Text(
          'Suggestion',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: suggestionController,
          readOnly: !canEdit,
          maxLines: 3,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }
}