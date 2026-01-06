import 'package:flutter/material.dart';
import 'package:juecho/common/constants/app_colors.dart';

class FeedbackAttachmentActions extends StatelessWidget {
  final VoidCallback onPreview;
  final VoidCallback onDownload;

  const FeedbackAttachmentActions({
    super.key,
    required this.onPreview,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: onPreview,
            style: ElevatedButton.styleFrom(
              foregroundColor: AppColors.primary,
              backgroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
            ),
            child: const Text('View attachment'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextButton(
            onPressed: onDownload,
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Download'),
          ),
        ),
      ],
    );
  }
}
