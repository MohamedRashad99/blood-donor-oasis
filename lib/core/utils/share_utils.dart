import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/donor_file.dart';

class ShareUtils {
  /// Opens the device share sheet with the message text and the result image,
  /// so the admin can send both to the donor on WhatsApp by hand.
  /// Returns false when the browser or device cannot share files.
  static Future<bool> shareResult({
    required DonorFile file,
    required String message,
  }) async {
    try {
      await SharePlus.instance.share(
        ShareParams(
          text: message,
          files: [
            XFile.fromData(file.bytes, mimeType: file.mimeType, name: file.fileName),
          ],
          fileNameOverrides: [file.fileName],
        ),
      );
      return true;
    } catch (e) {
      debugPrint('share failed: $e');
      return false;
    }
  }
}
