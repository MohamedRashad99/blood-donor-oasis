import 'dart:typed_data';
import 'package:image/image.dart' as img;

class CompressedImage {
  final Uint8List bytes;
  final String mimeType;
  const CompressedImage(this.bytes, this.mimeType);
}

/// Shrinks a picked image so it fits in one Firestore document (1 MiB limit).
/// Returns null when the file is not a readable image.
class ImageCompress {
  static const int maxBytes = 700 * 1024;

  static CompressedImage? compress(Uint8List input) {
    final decoded = img.decodeImage(input);
    if (decoded == null) return null;

    var working = decoded;
    var maxSide = 1600;
    while (maxSide >= 600) {
      if (working.width > maxSide || working.height > maxSide) {
        working = img.copyResize(
          decoded,
          width: decoded.width >= decoded.height ? maxSide : null,
          height: decoded.height > decoded.width ? maxSide : null,
          interpolation: img.Interpolation.average,
        );
      }
      for (final quality in const [85, 75, 65, 55, 45]) {
        final out = Uint8List.fromList(img.encodeJpg(working, quality: quality));
        if (out.length <= maxBytes) {
          return CompressedImage(out, 'image/jpeg');
        }
      }
      maxSide -= 300;
    }
    return null;
  }
}
