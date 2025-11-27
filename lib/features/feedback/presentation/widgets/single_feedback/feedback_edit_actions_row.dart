import 'package:flutter/material.dart';
import 'package:juecho/common/constants/app_colors.dart';

class FeedbackEditActionsRow extends StatelessWidget {
  final bool isSaving;
  final bool isDeleting;
  final VoidCallback onSave;
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
