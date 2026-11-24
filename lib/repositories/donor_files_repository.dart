import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/donor_file.dart';

abstract class DonorFilesRepository {
  Future<List<DonorFile>> listForDonor(String donorId);
  Future<DonorFile> add({
    required String donorId,
    required String fileName,
    required String mimeType,
    required Uint8List bytes,
  });
  Future<void> delete(String fileId);
}

/// Stores compressed images in Firestore (collection `donorFiles`).
/// Access is limited to the admin accounts by `firestore.rules`.
class FirestoreDonorFilesRepository implements DonorFilesRepository {
  static const String collection = 'donorFiles';
  final FirebaseFirestore _db;

  FirestoreDonorFilesRepository([FirebaseFirestore? db])
      : _db = db ?? FirebaseFirestore.instance;

  @override
  Future<List<DonorFile>> listForDonor(String donorId) async {
    final snap = await _db
        .collection(collection)
        .where('donorId', isEqualTo: donorId)
        .get();
    final files = snap.docs.map((d) {
      final data = d.data();
      return DonorFile(
        id: d.id,
        donorId: donorId,
        fileName: data['fileName'] as String? ?? 'result.jpg',
        mimeType: data['mimeType'] as String? ?? 'image/jpeg',
        bytes: (data['bytes'] as Blob).bytes,
        createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
    }).toList();
    files.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return files;
  }

  @override
  Future<DonorFile> add({
    required String donorId,
    required String fileName,
    required String mimeType,
    required Uint8List bytes,
  }) async {
    final now = DateTime.now();
    final ref = await _db.collection(collection).add({
      'donorId': donorId,
      'fileName': fileName,
      'mimeType': mimeType,
      'bytes': Blob(bytes),
      'size': bytes.length,
      'createdAt': Timestamp.fromDate(now),
    });
    return DonorFile(
      id: ref.id,
      donorId: donorId,
      fileName: fileName,
      mimeType: mimeType,
      bytes: bytes,
      createdAt: now,
    );
  }

  @override
  Future<void> delete(String fileId) =>
      _db.collection(collection).doc(fileId).delete();
}

/// Used only by preview builds (--dart-define=PREVIEW=true). Nothing is saved.
class InMemoryDonorFilesRepository implements DonorFilesRepository {
  final List<DonorFile> _files = [];
  int _n = 0;

  @override
  Future<List<DonorFile>> listForDonor(String donorId) async =>
      _files.where((f) => f.donorId == donorId).toList().reversed.toList();

  @override
  Future<DonorFile> add({
    required String donorId,
    required String fileName,
    required String mimeType,
    required Uint8List bytes,
  }) async {
    final f = DonorFile(
      id: 'mem${_n++}',
      donorId: donorId,
      fileName: fileName,
      mimeType: mimeType,
      bytes: bytes,
      createdAt: DateTime.now(),
    );
    _files.add(f);
    return f;
  }

  @override
  Future<void> delete(String fileId) async =>
      _files.removeWhere((f) => f.id == fileId);
}
