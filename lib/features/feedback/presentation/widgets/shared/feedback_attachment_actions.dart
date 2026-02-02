import 'package:flutter/material.dart';

import 'package:juecho/common/constants/app_colors.dart';

/// Action row for attachment operations on a feedback submission.
///
/// Provides:
/// - "View attachment" (primary outlined button)
/// - "Download" (text button)
///
/// The parent controls the actual behaviors via [onPreview] and [onDownload].
class FeedbackAttachmentActions extends StatelessWidget {
  /// Opens a preview UI for the attachment.
  final VoidCallback onPreview;

  /// Downloads the attachment to the device.
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
                side: const BorderSide(
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