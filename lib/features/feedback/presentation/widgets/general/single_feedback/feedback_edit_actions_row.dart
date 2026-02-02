import 'package:flutter/material.dart';
import 'package:juecho/common/constants/app_colors.dart';

/// Action row used by general users when editing a submission.
///
/// Contains:
/// - Save changes button (outlined style)
/// - Delete button (outlined style)
///
/// Button states:
/// - Save is disabled when [isSaving] is true.
/// - Delete is disabled when [isDeleting] is true.
/// - Each button shows a compact spinner during its active operation.
class FeedbackEditActionsRow extends StatelessWidget {
  /// Indicates a save operation is in progress.
  final bool isSaving;

  /// Indicates a delete operation is in progress.
  final bool isDeleting;

  /// Invoked when the user saves changes to the submission.
  final VoidCallback onSave;

  /// Invoked when the user deletes the submission.
  final VoidCallback onDelete;

  const FeedbackEditActionsRow({
    super.key,
    required this.isSaving,
    required this.isDeleting,
    required this.onSave,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: isSaving ? null : onSave,
            style: ElevatedButton.styleFrom(
              foregroundColor: AppColors.primary,
              backgroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
            ),
            child: isSaving
                ? const SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            )
                : const Text('Save changes'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: isDeleting ? null : onDelete,
            style: ElevatedButton.styleFrom(
              foregroundColor: AppColors.red,
              backgroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(
                  color: AppColors.red,
                  width: 2,
                ),
              ),
            ),
            child: isDeleting
                ? const SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.red,
              ),
            )
                : const Text('Delete'),
          ),
        ),
      ],
    );
  }
}