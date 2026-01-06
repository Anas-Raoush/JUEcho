import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:juecho/common/constants/app_colors.dart';

class AttachmentSection extends StatelessWidget {
  final bool isUploadingImage;
  final PlatformFile? attachedImageFile;
  final VoidCallback onAttachImagePressed;
  final VoidCallback onPreviewImagePressed;
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
            attachedImageFile == null ? 'Attach Image' : 'Change Image',
          ),
        ),
        const SizedBox(width: 8),
        if (attachedImageFile != null) ...[
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
