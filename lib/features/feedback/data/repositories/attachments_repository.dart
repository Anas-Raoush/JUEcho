import 'dart:typed_data';

import 'package:amplify_flutter/amplify_flutter.dart';

/// Small repository for downloading attachments from Amplify Storage.
class AttachmentsRepository {
  static Future<Uint8List?> downloadAttachmentBytes(String key) async {
    try {
      final result = await Amplify.Storage.downloadData(
        path: StoragePath.fromString(key),
      ).result;

      return Uint8List.fromList(result.bytes);
    } catch (e) {
      safePrint('downloadAttachmentBytes error for $key: $e');
      return null;
    }
  }
}