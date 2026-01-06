import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:juecho/features/feedback/data/feedback_repository.dart';
import 'package:juecho/features/feedback/presentation/widgets/shared/image_preview_dialog.dart';

class AttachmentActions {
  /// Preview an attachment (image) by its storage key.
  static Future<void> previewAttachment({
    required BuildContext context,
    required String attachmentKey,
  }) async {
    try {
      final Uint8List? bytes =
      await FeedbackRepository.downloadAttachmentBytes(attachmentKey);

      if (bytes == null) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not preview attachment.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      if (!context.mounted) return;

      await showDialog(
        context: context,
        builder: (_) => ImagePreviewDialog(
          title: 'Attachment preview',
          image: Image.memory(bytes, fit: BoxFit.contain),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not preview attachment.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Download an attachment to app documents directory and show the local path.
  static Future<void> downloadAttachment({
    required BuildContext context,
    required String attachmentKey,
  }) async {
    try {
      final Uint8List? bytes =
      await FeedbackRepository.downloadAttachmentBytes(attachmentKey);

      if (bytes == null) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not download attachment.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final dir = await getApplicationDocumentsDirectory();
      final fileName = attachmentKey.split('/').last;
      final file = File('${dir.path}/$fileName');

      await file.writeAsBytes(bytes);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Downloaded to: ${file.path}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not download attachment.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}