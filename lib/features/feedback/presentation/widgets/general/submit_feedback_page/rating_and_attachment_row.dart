import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import 'package:juecho/features/feedback/presentation/widgets/general/submit_feedback_page/attachment_section.dart';
import 'package:juecho/features/feedback/presentation/widgets/general/submit_feedback_page/rating_section.dart';

/// Layout wrapper combining rating selection and attachment controls.
///
/// Layout
/// - Uses [Wrap] to adapt to narrow widths.
/// - Rating and attachment sections are rendered side-by-side when space allows,
///   and wrap vertically when not.
///
/// This widget is a composition layer and does not manage state.
class RatingAndAttachmentRow extends StatelessWidget {
  /// Current rating value (1-5).
  final int rating;

  /// Called when rating changes.
  final ValueChanged<int> onRatingChanged;

  /// True while attachment upload is in progress.
  final bool isUploadingImage;

  /// Selected image file (nullable).
  final PlatformFile? attachedImageFile;

  /// Called to attach or change the image.
  final VoidCallback onAttachImagePressed;

  /// Called to preview the selected image.
  final VoidCallback onPreviewImagePressed;

  /// Called to remove the selected image.
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