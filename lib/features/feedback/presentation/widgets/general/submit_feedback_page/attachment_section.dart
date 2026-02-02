import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import 'package:juecho/common/constants/app_colors.dart';

/// Attachment picker UI for the submit feedback form.
///
/// Responsibilities
/// - Provides an action button for attaching/changing an image.
/// - Shows upload progress state while an image is being uploaded.
/// - When an image is selected, exposes:
///   - preview action
///   - remove action
///
/// This widget is intentionally UI-only.
/// Uploading, storage keys, and file IO are handled by the parent.
class AttachmentSection extends StatelessWidget {
  /// True while an upload is running.
  /// Used to disable the attach/change action and render a spinner.
  final bool isUploadingImage;

  /// Selected image file (nullable if none selected).
  final PlatformFile? attachedImageFile;

  /// Invoked to open the file picker.
  final VoidCallback onAttachImagePressed;

  /// Invoked to preview the selected image.
  final VoidCallback onPreviewImagePressed;

  /// Invoked to clear the selected image.
  final VoidCallback onRemoveImagePressed;

  const AttachmentSection({
    super.key,
    required this.isUploadingImage,
    required this.attachedImageFile,
    required this.onAttachImagePressed,
    required this.onPreviewImagePressed,
    required this.onRemoveImagePressed,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = attachedImageFile != null;

    return Column(
      children: [
        ElevatedButton(
          onPressed: isUploadingImage ? null : onAttachImagePressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: isUploadingImage
              ? const SizedBox(
            height: 16,
            width: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.white,
            ),
          )
              : Text(
            hasImage ? 'Change Image' : 'Attach Image',
          ),
        ),
        const SizedBox(width: 8),
        if (hasImage) ...[
          TextButton(
            onPressed: onPreviewImagePressed,
            child: const Text('Preview'),
          ),
          IconButton(
            onPressed: onRemoveImagePressed,
            tooltip: 'Remove image',
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ],
    );
  }
}