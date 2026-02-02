import 'package:flutter/material.dart';

/// Generic dialog for previewing an image widget.
///
/// Usage
/// - Provide [title] and an [image] widget.
/// - The [image] is clipped with rounded corners and displayed in a dialog.
/// - Close action is provided via a single button.
///
/// Notes
/// - The dialog is intentionally widget-based to support:
///   - Image.file
///   - Image.memory
///   - Any custom image widget
class ImagePreviewDialog extends StatelessWidget {
  /// Dialog title displayed above the image.
  final String title;

  /// Image widget to render in the dialog body.
  final Widget image;

  /// Label for the close button.
  final String closeText;

  const ImagePreviewDialog({
    super.key,
    required this.title,
    required this.image,
    this.closeText = 'Close',
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: image,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(closeText),
            ),
          ],
        ),
      ),
    );
  }
}