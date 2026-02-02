import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'package:juecho/features/feedback/data/repositories/attachments_repository.dart';
import 'package:juecho/features/feedback/presentation/widgets/shared/image_preview_dialog.dart';

/// UI-facing helper for attachment preview and download.
///
/// Preview
/// - Downloads bytes via [AttachmentsRepository].
/// - Renders an image dialog using [ImagePreviewDialog].
///
/// Download
/// - Downloads bytes via [AttachmentsRepository].
/// - Writes them to the app documents directory.
/// - Displays the local file path in a SnackBar.
///
/// Notes
/// - This class intentionally remains UI-oriented and does not expose
///   storage-specific details beyond the [attachmentKey].
class AttachmentActions {
  /// Previews an image attachment by storage key.
  ///
  /// Steps:
  /// - Downloads bytes from storage.
  /// - If bytes are missing, shows an error SnackBar.
  /// - Otherwise, shows [ImagePreviewDialog] with [Image.memory].
  static Future<void> previewAttachment({
    required BuildContext context,
    required String attachmentKey,
  }) async {
    try {
      final Uint8List? bytes =
      await AttachmentsRepository.downloadAttachmentBytes(attachmentKey);

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

  /// Downloads an attachment to the app documents directory.
  ///
  /// Steps:
  /// - Downloads bytes from storage.
  /// - If bytes are missing, shows an error SnackBar.
  /// - Writes bytes to a file under the documents directory.
  /// - Shows a SnackBar containing the saved file path.
  static Future<void> downloadAttachment({
    required BuildContext context,
    required String attachmentKey,
  }) async {
    try {
      final Uint8List? bytes =
      await AttachmentsRepository.downloadAttachmentBytes(attachmentKey);

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