import 'package:flutter/material.dart';

class ImagePreviewDialog extends StatelessWidget {
  final String title;
  final Widget image;
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
