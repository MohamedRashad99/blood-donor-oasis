import 'dart:typed_data';

/// A small compressed image (for example a post-donation test result)
/// attached to a donor profile.
class DonorFile {
  final String id;
  final String donorId;
  final String fileName;
  final String mimeType;
  final Uint8List bytes;
  final DateTime createdAt;

  const DonorFile({
    required this.id,
    required this.donorId,
    required this.fileName,
    required this.mimeType,
    required this.bytes,
    required this.createdAt,
  });
}
