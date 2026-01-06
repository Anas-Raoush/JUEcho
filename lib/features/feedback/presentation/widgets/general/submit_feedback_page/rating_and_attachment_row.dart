import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:juecho/features/feedback/presentation/widgets/general/submit_feedback_page/attachment_section.dart';
import 'package:juecho/features/feedback/presentation/widgets/general/submit_feedback_page/rating_section.dart';

class RatingAndAttachmentRow extends StatelessWidget {
  final int rating;
  final ValueChanged<int> onRatingChanged;
  final bool isUploadingImage;
  final PlatformFile? attachedImageFile;
  final VoidCallback onAttachImagePressed;
  final VoidCallback onPreviewImagePressed;
  final VoidCallback onRemoveImagePressed;

  const RatingAndAttachmentRow({
    super.key,
    required this.rating,
    required this.onRatingChanged,
    required this.isUploadingImage,
    required this.attachedImageFile,
    required this.onAttachImagePressed,
    required this.onPreviewImagePressed,
    required this.onRemoveImagePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      children: [
        RatingSection(
          rating: rating,
          onRatingChanged: onRatingChanged,
        ),
        const SizedBox(width: 25),
        AttachmentSection(
          isUploadingImage: isUploadingImage,
          attachedImageFile: attachedImageFile,
          onAttachImagePressed: onAttachImagePressed,
          onPreviewImagePressed: onPreviewImagePressed,
          onRemoveImagePressed: onRemoveImagePressed,
        ),
      ],
    );
  }
}
